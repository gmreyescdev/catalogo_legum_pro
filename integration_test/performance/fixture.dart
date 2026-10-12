import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cryptography/cryptography.dart';

import 'package:catalogo_legum_pro/contracts.dart';

/// Synthetic only: this directory is inside the isolated integration sandbox.
Future<CatalogSnapshot> prepareFixture(Directory root, int count) async {
  final manifest = File('${root.path}/fixture-$count-v1.json');
  if (await manifest.exists()) {
    final json =
        jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    return CatalogSnapshot.fromJson(json['catalog'] as Map<String, dynamic>);
  }
  final products = <Product>[];
  final photos = <Map<String, Object>>[];
  for (var i = 0; i < count; i++) {
    final images = <ProductImage>[];
    for (var j = 0; j < 3; j++) {
      final path = 'media/product_$i/photo_$j.png';
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(
        ui.Color(0xff203040 + i * 301 + j * 10007),
        ui.BlendMode.src,
      );
      for (var n = 0; n < 32; n++) {
        canvas.drawCircle(
          ui.Offset((n * 137 + i * 29) % 4000.0, (n * 199 + j * 300) % 3000.0),
          100.0 + n * 8,
          ui.Paint()..color = ui.Color(0xff00aa44 + n * 113 + i * 71 + j * 373),
        );
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(4000, 3000);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      final digest = await Sha256().hash(bytes);
      photos.add({
        'path': path,
        'width': 4000,
        'height': 3000,
        'bytes': bytes.length,
        'sha256': digest.bytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(),
      });
      image.dispose();
      picture.dispose();
      images.add(ProductImage(id: 'image_${i}_$j', path: path, sortOrder: j));
    }
    products.add(
      Product(
        id: 'product_$i',
        categoryId: 'category_${i % 5}',
        name: 'Legumbre ágil $i',
        description: 'Descripción sintética categoría ${i % 5}',
        sku: 'QA-$i',
        presentation: 'Bolsa 1 kg',
        normalClp: 2000 + i * 100,
        saleClp: i % 4 == 0 ? 1500 + i * 100 : null,
        visible: i % 10 != 9,
        available: i % 3 != 2,
        sortOrder: i,
        images: images,
      ),
    );
  }
  final snapshot = CatalogSnapshot(
    categories: List.generate(
      5,
      (i) => Category(id: 'category_$i', name: 'Categoría $i', sortOrder: i),
    ),
    products: products,
    settings: const AppSettings(themeMode: 'light'),
  );
  await manifest.writeAsString(
    jsonEncode({
      'version': 1,
      'seed': 007,
      'catalog': snapshot.toJson(),
      'images': photos,
      'expectedPublicCount': products.where((p) => p.visible).length,
    }),
    flush: true,
  );
  return snapshot;
}

class FixtureRepository extends CatalogRepository {
  FixtureRepository(this.value);
  CatalogSnapshot value;
  @override
  CatalogSnapshot get snapshot => value;
  @override
  Future<void> replaceCatalog(CatalogSnapshot snapshot) async {
    value = snapshot;
    notifyListeners();
  }

  @override
  Future<void> load() async {}
  @override
  Future<T> exclusive<T>(Future<T> Function() action) => action();
  @override
  Future<void> close() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Read-only performance fixture');
}

class FixtureAuth extends AdminAuth {
  @override
  bool get isAuthenticated => false;
  @override
  bool get isConfigured => true;
  @override
  Duration get remainingLockout => Duration.zero;
  @override
  void lock() {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No admin access in harness');
}

class FixtureBackup implements BackupManager {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No backup access in harness');
}

class FixtureShare implements WhatsAppGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No external sharing in harness');
}
