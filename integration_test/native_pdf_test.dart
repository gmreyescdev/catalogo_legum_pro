import 'dart:io';
import 'dart:ui' as ui;

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/data/whatsapp/native_whatsapp_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native PDF generation and share chooser cancellation', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('legum_pdf_native_');
      try {
        final media = LocalMediaManager(root: root);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawColor(const ui.Color(0xff315c38), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(64, 64);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final cover = File(media.absolutePath('media/native/cover.png'));
        await cover.parent.create(recursive: true);
        await cover.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        image.dispose();
        picture.dispose();
        final products = [
          Product(
            id: 'native',
            categoryId: 'native',
            name: 'Selección de café',
            description: 'No exportar',
            sku: 'No exportar',
            presentation: 'Bolsa de 1 kg',
            normalClp: 2500,
            saleClp: 2000,
            available: false,
            images: [
              const ProductImage(id: 'cover', path: 'media/native/cover.png'),
            ],
          ),
        ];
        ShareResult? result;
        var activeScope = CatalogPdfScope.personalized;
        final gateway = NativeWhatsAppGateway(
          media: media,
          workDirectory: Directory('${root.path}/pdf'),
          sharer: (params) async {
            expect(params.files!.single.mimeType, 'application/pdf');
            expect(
              File(params.files!.single.path).uri.pathSegments.last,
              activeScope.fileName,
            );
            expect(params.fileNameOverrides, [activeScope.fileName]);
            expect(await File(params.files!.single.path).exists(), isTrue);
            debugPrint(
              'NATIVE_PDF_CHOOSER_OPENING: ${activeScope.fileName}; cancel without choosing a recipient',
            );
            result = await SharePlus.instance.share(params);
            return result!;
          },
        );
        final generated = await gateway.generateCatalog(products);
        final pdf = await generated.readAsBytes();
        expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
        expect(pdf.length, greaterThan(1000));
        final statuses = <String, String>{};
        for (final scope in CatalogPdfScope.values) {
          activeScope = scope;
          result = null;
          await gateway.shareCatalog(
            products,
            scope: scope,
            sharePositionOrigin: const ui.Rect.fromLTWH(0, 0, 100, 48),
          );
          expect(result, isNotNull);
          expect(
            result!.status,
            isIn([ShareResultStatus.dismissed, ShareResultStatus.unavailable]),
          );
          statuses[scope.name] = result!.status.name;
          debugPrint(
            'NATIVE_PDF_CHOOSER_CLOSED: ${scope.name} ${result!.status.name}',
          );
        }
        expect(products.length, 1);
        expect(products.single.available, isFalse);
        binding.reportData = {
          'share_status': statuses,
          'pdf_bytes': pdf.length,
        };
      } finally {
        await root.delete(recursive: true);
      }
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
