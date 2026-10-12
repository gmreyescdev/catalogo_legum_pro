import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/sql_catalog_repository.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/data/local_backup_manager.dart';
import 'package:catalogo_legum_pro/data/auth/secure_admin_auth.dart';

class _TestCredentials implements CredentialStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native SQLite, protected storage and portable replacement', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const protected = FlutterSecureStorage();
      const probeKey = 'legum.qa.native.probe';
      await protected.write(key: probeKey, value: 'native-storage-probe');
      expect(await protected.read(key: probeKey), 'native-storage-probe');
      await protected.delete(key: probeKey);

      final credentials = _TestCredentials();
      final auth = SecureAdminAuth(initialPin: '7092', store: credentials);
      final timer = Stopwatch()..start();
      await auth.initialize();
      timer.stop();
      binding.reportData = {'initial_kdf_ms': timer.elapsedMilliseconds};
      expect(await auth.unlock('7092'), isTrue);
      final code = await auth.beginSetup();
      expect(code.replaceAll('-', '').length, 26);
      await auth.confirmSetup();

      final root = await Directory.systemTemp.createTemp('legum_native_');
      final dbPath = '${root.path}/catalog.sqlite';
      var repository = SqlCatalogRepository(
        databasePath: dbPath,
        requireAdmin: auth.requireAdmin,
      );
      final media = LocalMediaManager(
        root: root,
        referencedPaths: () => repository.snapshot.products
            .expand((p) => p.images)
            .map((i) => i.path)
            .toSet(),
      );
      try {
        await repository.load();
        expect(repository.snapshot.products, isEmpty);
        for (var i = 0; i < 5; i++) {
          await repository.saveCategory(
            Category(id: 'category_$i', name: 'Categoría $i', sortOrder: i),
          );
        }
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(Colors.green, BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(8, 8);
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        image.dispose();
        picture.dispose();
        for (var i = 0; i < 20; i++) {
          final path = 'media/native/image_$i.png';
          final file = File(media.absolutePath(path));
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
          await repository.saveProduct(
            Product(
              id: 'product_$i',
              categoryId: 'category_${i % 5}',
              name: 'Producto $i',
              description: 'Descripción nativa con acentos $i',
              sku: 'SKU-$i',
              presentation: 'Bolsa de 1 kg',
              normalClp: 2500,
              saleClp: i.isEven ? 2000 : null,
              visible: i != 19,
              available: i != 18,
              sortOrder: i,
              images: [ProductImage(id: 'photo_$i', path: path)],
            ),
          );
        }
        await repository.saveSettings(
          const AppSettings(whatsapp: '+56912345678', themeMode: 'dark'),
        );
        await repository.close();
        repository = SqlCatalogRepository(
          databasePath: dbPath,
          requireAdmin: auth.requireAdmin,
        );
        await repository.load();
        expect(repository.snapshot.categories.length, 5);
        expect(repository.snapshot.products.length, 20);
        expect(repository.snapshot.products.where((p) => p.visible).length, 19);
        expect(repository.snapshot.settings.themeMode, 'dark');
        await expectLater(
          repository.deleteCategory('category_0'),
          throwsA(anything),
        );
        expect(repository.snapshot.products.length, 20);

        final backup = LocalBackupManager(
          catalog: repository,
          media: media,
          workDirectory: Directory('${root.path}/backups'),
          requireAdmin: auth.requireAdmin,
        );
        final archive = await backup.exportBackup(share: false);
        final preview = await backup.prepareBackup(File(archive));
        expect(preview.productCount, 20);
        await repository.saveCategory(
          const Category(id: 'extra', name: 'Temporal', sortOrder: 5),
        );
        await backup.restoreBackup(preview);
        expect(repository.snapshot.categories.length, 5);
        expect(repository.snapshot.products.length, 20);
        expect(auth.isAuthenticated, isTrue);
        for (final product in repository.snapshot.products) {
          expect(
            await File(media.absolutePath(product.images.first.path)).exists(),
            isTrue,
          );
        }

        final failing = LocalBackupManager(
          catalog: repository,
          media: media,
          workDirectory: Directory('${root.path}/rollback'),
          requireAdmin: auth.requireAdmin,
          beforeReplace: () async {
            throw const FileSystemException('Injected precommit failure');
          },
        );
        final rollbackPreview = await failing.prepareBackup(File(archive));
        final oldPaths = repository.snapshot.products
            .expand((p) => p.images)
            .map((i) => i.path)
            .toList();
        await expectLater(
          failing.restoreBackup(rollbackPreview),
          throwsA(anything),
        );
        expect(
          repository.snapshot.products
              .expand((p) => p.images)
              .map((i) => i.path)
              .toList(),
          oldPaths,
        );
        for (final path in oldPaths) {
          expect(await File(media.absolutePath(path)).exists(), isTrue);
        }
        await failing.discardPreview(rollbackPreview);
        auth.lock();
        await expectLater(
          repository.saveCategory(
            const Category(id: 'blocked', name: 'Bloqueada'),
          ),
          throwsA(anything),
        );
        expect(repository.snapshot.categories.length, 5);
      } finally {
        await repository.close();
        auth.dispose();
        await root.delete(recursive: true);
      }
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
