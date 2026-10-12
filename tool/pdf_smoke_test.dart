import 'dart:io';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/data/whatsapp/native_whatsapp_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('PDF fixture renders selected products with local cover images', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('legum_pdf_fixture_');
      try {
        final media = LocalMediaManager(root: root);
        final photos = ['lentils', 'chickpeas'];
        final products = <Product>[];
        for (var i = 0; i < photos.length; i++) {
          final path = 'media/fixture/${photos[i]}.png';
          final image = File(media.absolutePath(path));
          await image.parent.create(recursive: true);
          await File('assets/products/${photos[i]}.png').copy(image.path);
          products.add(
            Product(
              id: 'fixture_$i',
              categoryId: 'fixture',
              name: i == 0
                  ? 'Lentejas selección especial'
                  : 'Garbanzos premium',
              description: 'DESCRIPCION_NO_EXPORTAR',
              sku: 'SKU_NO_EXPORTAR_$i',
              presentation: i == 0 ? 'Bolsa de 1 kg' : 'Bolsa de 500 g',
              normalClp: i == 0 ? 2500 : 1900,
              saleClp: i == 0 ? null : 1500,
              available: i == 0,
              images: [ProductImage(id: 'image_$i', path: path)],
            ),
          );
        }
        final gateway = NativeWhatsAppGateway(
          media: media,
          workDirectory: Directory('${root.path}/pdf'),
        );
        final file = await gateway.generateCatalog(products);
        final output = Directory('artifacts/qa-pdf');
        await output.create(recursive: true);
        await file.copy('${output.path}/catalogo-ejemplo.pdf');
        await file.copy(
          '${output.path}/${CatalogPdfScope.personalized.fileName}',
        );
        final fullFile = await gateway.generateCatalog(
          products,
          scope: CatalogPdfScope.complete,
        );
        await fullFile.copy(
          '${output.path}/${CatalogPdfScope.complete.fileName}',
        );
        final bytes = await file.readAsBytes();
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(1000));
        final longProduct = Product(
          id: 'long',
          categoryId: 'fixture',
          name:
              '${List.filled(350, 'Nombre extenso áéíóú').join(' ')} FIN_NOMBRE',
          description: 'DESCRIPCION_NO_EXPORTAR',
          sku: 'SKU_NO_EXPORTAR',
          presentation:
              '${List.filled(1000, 'Presentación de producto').join(' ')} FIN_PRESENTACION',
          normalClp: 2500,
          images: products.first.images,
        );
        final longFile = await gateway.generateCatalog([longProduct]);
        await longFile.copy('${output.path}/catalogo-texto-largo.pdf');
      } finally {
        await root.delete(recursive: true);
      }
    });
  });
}
