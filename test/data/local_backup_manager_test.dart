import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/local_backup_manager.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/data/sql_catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;
  late SqlCatalogRepository catalog;
  late LocalMediaManager media;
  late LocalBackupManager backup;
  var authenticated = true;
  void requireAdmin() {
    if (!authenticated) throw StateError('Sin sesión');
  }

  Future<void> seed() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xff315c38), ui.BlendMode.src);
    // Keep a concrete canvas operation so this fixture is a genuinely decodable PNG.
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 2, 2),
      ui.Paint()..color = const ui.Color(0xff315c38),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 2);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File(media.absolutePath('media/original/photo.png'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    image.dispose();
    picture.dispose();
    await catalog.saveCategory(const Category(id: 'c', name: 'Legumbres'));
    await catalog.saveProduct(
      Product(
        id: 'p',
        categoryId: 'c',
        name: 'Porotos',
        description: 'Descripción',
        sku: 'SKU',
        presentation: '1 kg',
        normalClp: 1000,
        images: [const ProductImage(id: 'i', path: 'media/original/photo.png')],
      ),
    );
  }

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    authenticated = true;
    dir = await Directory.systemTemp.createTemp('legum_backup_test_');
    catalog = SqlCatalogRepository(
      databasePath: p.join(dir.path, 'catalog.sqlite'),
      factory: databaseFactoryFfi,
      requireAdmin: requireAdmin,
    );
    await catalog.load();
    media = LocalMediaManager(
      root: dir,
      referencedPaths: () => catalog.snapshot.products
          .expand((p) => p.images)
          .map((i) => i.path)
          .toSet(),
    );
    backup = LocalBackupManager(
      catalog: catalog,
      media: media,
      workDirectory: Directory(p.join(dir.path, 'backups')),
      requireAdmin: requireAdmin,
    );
  });
  tearDown(() async {
    await catalog.close();
    await dir.delete(recursive: true);
  });

  testWidgets(
    'portable roundtrip replaces records, preserves media and excludes credentials',
    (tester) async {
      await tester.runAsync(() async {
        await seed();
        final originalBytes = await File(
          media.absolutePath('media/original/photo.png'),
        ).readAsBytes();
        final exported = await backup.exportBackup(share: false);
        final input = InputFileStream(exported);
        final archive = ZipDecoder().decodeStream(input);
        final manifest = jsonDecode(
          utf8.decode(archive.find('manifest.json')!.readBytes()!),
        ) as Map;
        expect(manifest.keys.toSet(), {'format_version', 'catalog', 'media'});
        expect(jsonEncode(manifest), isNot(contains('pin')));
        expect(jsonEncode(manifest), isNot(contains('recovery')));
        await archive.clear();
        await input.close();
        final preview = await backup.prepareBackup(File(exported));
        await catalog.saveCategory(const Category(id: 'extra', name: 'Extra'));
        await backup.restoreBackup(preview);
        expect(catalog.snapshot.categories.map((c) => c.id), ['c']);
        final newPath = catalog.snapshot.products.single.images.single.path;
        expect(newPath, isNot('media/original/photo.png'));
        expect(await File(media.absolutePath(newPath)).exists(), isTrue);
        expect(
          await File(media.absolutePath(newPath)).readAsBytes(),
          originalBytes,
        );
        await catalog.close();
        await catalog.load();
        expect(catalog.snapshot.products.single.images.single.path, newPath);
      });
    },
  );
  testWidgets('failure before SQL commit retains old records and media', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seed();
      final exported = await backup.exportBackup(share: false);
      final failing = LocalBackupManager(
        catalog: catalog,
        media: media,
        workDirectory: Directory(p.join(dir.path, 'backups')),
        requireAdmin: requireAdmin,
        beforeReplace: () async {
          throw const FileSystemException('Espacio insuficiente');
        },
      );
      final preview = await failing.prepareBackup(File(exported));
      final before = jsonEncode(catalog.snapshot.toJson());
      await expectLater(
        failing.restoreBackup(preview),
        throwsA(isA<FileSystemException>()),
      );
      expect(jsonEncode(catalog.snapshot.toJson()), before);
      expect(
        await File(media.absolutePath('media/original/photo.png')).exists(),
        isTrue,
      );
      final files = await Directory(p.join(dir.path, 'media'))
          .list(recursive: true)
          .where((e) => e is File)
          .toList();
      expect(files.length, 1);
    });
  });
  testWidgets('expired session cannot restore a prepared import', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seed();
      final exported = await backup.exportBackup(share: false);
      final preview = await backup.prepareBackup(File(exported));
      authenticated = false;
      await expectLater(backup.restoreBackup(preview), throwsStateError);
      expect(
        catalog.snapshot.products.single.images.single.path,
        'media/original/photo.png',
      );
      await backup.discardPreview(preview);
    });
  });
  for (final name in [
    '../outside.png',
    '/outside.png',
    r'media\evil\photo.png',
  ]) {
    testWidgets('rejects unsafe archive path $name without mutation', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await seed();
        final archive = Archive()
          ..add(ArchiveFile.string('manifest.json', '{}'))
          ..add(ArchiveFile.bytes(name, [1, 2, 3]));
        final file = File(p.join(dir.path, 'bad.zip'));
        await file.writeAsBytes(ZipEncoder().encode(archive));
        await expectLater(backup.prepareBackup(file), throwsA(anything));
        expect(catalog.snapshot.products.single.id, 'p');
        expect(
          await File(media.absolutePath('media/original/photo.png')).exists(),
          isTrue,
        );
      });
    });
  }
  testWidgets('malformed and incompatible manifests never replace catalog', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seed();
      for (final content in [
        'not json',
        jsonEncode({'format_version': 99, 'catalog': {}, 'media': []}),
        jsonEncode({
          'format_version': 1,
          'catalog': CatalogSnapshot().toJson(),
          'media': [],
          'pin': 'synthetic',
        }),
      ]) {
        final file = File(p.join(dir.path, 'invalid.zip'));
        await file.writeAsBytes(
          ZipEncoder().encode(
            Archive()..add(ArchiveFile.string('manifest.json', content)),
          ),
        );
        await expectLater(backup.prepareBackup(file), throwsA(anything));
        expect(catalog.snapshot.products.single.id, 'p');
      }
    });
  });
  testWidgets('empty backup is valid and cancel leaves catalog unchanged', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final exported = await backup.exportBackup(share: false);
      final preview = await backup.prepareBackup(File(exported));
      expect(preview.productCount, 0);
      await backup.discardPreview(preview);
      await expectLater(backup.restoreBackup(preview), throwsStateError);
      expect(catalog.snapshot.products, isEmpty);
    });
  });
  testWidgets('failed native sharing removes the private export temporary', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final failing = LocalBackupManager(
        catalog: catalog,
        media: media,
        workDirectory: Directory(p.join(dir.path, 'backups')),
        requireAdmin: requireAdmin,
        shareFile: (path) async {
          throw StateError('Compartición rechazada');
        },
      );
      await expectLater(failing.exportBackup(), throwsStateError);
      final files = await Directory(p.join(dir.path, 'backups'))
          .list()
          .toList();
      expect(files, isEmpty);
      expect(catalog.snapshot.products, isEmpty);
    });
  });
  testWidgets(
    'successful share retains URI file for 24 hours then startup cleans it',
    (tester) async {
      await tester.runAsync(() async {
        final sharing = LocalBackupManager(
          catalog: catalog,
          media: media,
          workDirectory: Directory(p.join(dir.path, 'backups')),
          requireAdmin: requireAdmin,
          shareFile: (path) async {
            expect(await File(path).exists(), isTrue);
          },
        );
        final path = await sharing.exportBackup();
        expect(await File(path).exists(), isTrue);
        await sharing.cleanupInterruptedStaging();
        expect(await File(path).exists(), isTrue);
        await File(
          path,
        ).setLastModified(DateTime.now().subtract(const Duration(hours: 25)));
        await sharing.cleanupInterruptedStaging();
        expect(await File(path).exists(), isFalse);
      });
    },
  );
  testWidgets('new session during preparation cannot commit old restore', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seed();
      final exported = await backup.exportBackup(share: false);
      var epoch = 0;
      final guarded = LocalBackupManager(
        catalog: catalog,
        media: media,
        workDirectory: Directory(p.join(dir.path, 'backups')),
        requireAdmin: requireAdmin,
        sessionToken: () => epoch,
        beforeReplace: () async {
          epoch++;
        },
      );
      final preview = await guarded.prepareBackup(File(exported));
      await expectLater(guarded.restoreBackup(preview), throwsStateError);
      expect(
        catalog.snapshot.products.single.images.single.path,
        'media/original/photo.png',
      );
      expect(
        await File(media.absolutePath('media/original/photo.png')).exists(),
        isTrue,
      );
    });
  });
  testWidgets('modified media hash is rejected before replacing any data', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await seed();
      final exported = await backup.exportBackup(share: false);
      final input = InputFileStream(exported);
      final original = ZipDecoder().decodeStream(input);
      final archive = Archive();
      for (final entry in original) {
        if (entry.name == 'manifest.json') {
          final manifest = jsonDecode(
            utf8.decode(entry.readBytes()!),
          ) as Map<String, dynamic>;
          (manifest['media'] as List).first['sha256'] = List.filled(
            64,
            '0',
          ).join();
          archive.add(ArchiveFile.string(entry.name, jsonEncode(manifest)));
        } else {
          archive.add(ArchiveFile.bytes(entry.name, entry.readBytes()!));
        }
      }
      final corrupted = File(p.join(dir.path, 'hash_mismatch.zip'));
      await corrupted.writeAsBytes(ZipEncoder().encode(archive));
      await original.clear();
      await input.close();
      await expectLater(backup.prepareBackup(corrupted), throwsFormatException);
      expect(
        catalog.snapshot.products.single.images.single.path,
        'media/original/photo.png',
      );
      expect(
        await File(media.absolutePath('media/original/photo.png')).exists(),
        isTrue,
      );
    });
  });
}
