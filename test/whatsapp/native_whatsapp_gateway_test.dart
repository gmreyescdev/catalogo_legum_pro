import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/whatsapp/native_whatsapp_gateway.dart';

Product item({
  String id = 'one',
  bool visible = true,
  String? name,
  String? presentation,
  bool sale = true,
  bool available = false,
  int normalClp = 2500,
  int saleClp = 1900,
  List<ProductImage> images = const [],
}) => Product(
  id: id,
  categoryId: 'cat',
  name: name ?? 'Piñón & café',
  description: 'DESCRIPCION_PRIVADA',
  sku: 'SKU_PRIVADO',
  presentation: presentation ?? '500 g — selección',
  normalClp: normalClp,
  saleClp: sale ? saleClp : null,
  available: available,
  visible: visible,
  images: images,
);

class TestMedia implements MediaManager {
  TestMedia(this.root);
  final Directory root;
  final paths = <String>[];
  @override
  String absolutePath(String path) {
    paths.add(path);
    return '${root.path}/$path';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Minimal independent reader of this PDF's standard font maps/content streams.
// Assertions inspect emitted bytes, rather than the service's layout inputs.
class PdfProbe {
  PdfProbe(List<int> bytes) {
    raw = latin1.decode(bytes);
    final objects = <int, String>{};
    for (final match in RegExp(
      r'(\d+) 0 obj\s*([\s\S]*?)endobj',
    ).allMatches(raw)) {
      objects[int.parse(match[1]!)] = match[2]!;
    }
    String stream(String body) {
      final start = RegExp(r'stream\r?\n').firstMatch(body);
      if (start == null) return '';
      final lengthMatch = RegExp(r'/Length\s+(\d+)').firstMatch(body);
      if (lengthMatch == null) return '';
      List<int> bytes = latin1.encode(
        body.substring(start.end, start.end + int.parse(lengthMatch[1]!)),
      );
      if (body.substring(0, start.start).contains('/FlateDecode')) {
        bytes = zlib.decode(bytes);
      }
      return latin1.decode(bytes);
    }

    final fonts = <int, Map<int, int>>{};
    for (final entry in objects.entries) {
      final cmapRef = RegExp(r'/ToUnicode\s+(\d+) 0 R').firstMatch(entry.value);
      if (cmapRef == null) continue;
      final cmap = stream(objects[int.parse(cmapRef[1]!)]!);
      fonts[entry.key] = {
        for (final m in RegExp(
          r'<([0-9A-Fa-f]{4})>\s+<([0-9A-Fa-f]{4})>',
        ).allMatches(cmap))
          int.parse(m[1]!, radix: 16): int.parse(m[2]!, radix: 16),
      };
    }
    final text = StringBuffer();
    final contentTexts = <int, String>{};
    final imageReferences = <String, int>{
      for (final body in objects.values)
        for (final reference in RegExp(r'/(I\w+)\s+(\d+) 0 R').allMatches(body))
          reference[1]!: int.parse(reference[2]!),
    };
    imageObjects = objects.entries
        .where((entry) => RegExp(r'/Subtype\s*/Image\b').hasMatch(entry.value))
        .map((e) => e.key)
        .toSet();
    logoObjects = objects.entries
        .where(
          (entry) =>
              imageObjects.contains(entry.key) &&
              entry.value.contains('/DCTDecode'),
        )
        .map((e) => e.key)
        .toSet();
    for (final entry in objects.entries) {
      final body = entry.value;
      final content = stream(body);
      for (final draw in RegExp(r'/(I\w+)\s+Do').allMatches(content)) {
        final id = imageReferences[draw[1]];
        if (id != null) {
          imageDraws.update(id, (count) => count + 1, ifAbsent: () => 1);
        }
      }
      if (!content.contains('BT')) continue;
      final currentText = StringBuffer();
      Map<int, int> font = {};
      for (final token in RegExp(
        r'/F(\d+)\s+[\d.]+\s+Tf|<([0-9a-fA-F]+)>',
      ).allMatches(content)) {
        if (token[1] != null) {
          font = fonts[int.parse(token[1]!)] ?? {};
          continue;
        }
        final hex = token[2]!;
        for (var i = 0; i + 4 <= hex.length; i += 4) {
          final code = font[int.parse(hex.substring(i, i + 4), radix: 16)];
          if (code != null) {
            text.writeCharCode(code);
            currentText.writeCharCode(code);
          }
        }
      }
      contentTexts[entry.key] = currentText.toString();
    }
    textContent = text.toString();
    pageTexts = [
      for (final body in objects.values)
        if (RegExp(r'/Type\s*/Page\b').hasMatch(body))
          [
            for (final reference in RegExp(r'(\d+) 0 R').allMatches(
              RegExp(r'/Contents\s*(\[[^\]]*\]|\d+ 0 R)')
                      .firstMatch(body)
                      ?.group(1) ??
                  '',
            ))
              contentTexts[int.parse(reference[1]!)] ?? '',
          ].join(),
    ];
  }
  late final String raw, textContent;
  late final Set<int> imageObjects, logoObjects;
  late final List<String> pageTexts;
  final imageDraws = <int, int>{};
  int get logoDrawCount =>
      logoObjects.fold(0, (sum, id) => sum + (imageDraws[id] ?? 0));
  // PDF may encode interword spacing as TJ numeric offsets instead of glyphs.
  // Compare every non-whitespace character; visual spacing is checked in the
  // independently rendered fixture, not inferred by this minimal reader.
  bool hasText(String value) => textContent
      .replaceAll(RegExp(r'\s+'), '')
      .contains(value.replaceAll(RegExp(r'\s+'), ''));
  int get pages => RegExp(r'/Type\s*/Page\b').allMatches(raw).length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root, exports;
  late TestMedia media;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('legum_pdf_test_');
    exports = Directory('${root.path}/exports');
    media = TestMedia(root);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  NativeWhatsAppGateway gateway({
    Future<ShareResult> Function(ShareParams)? sharer,
  }) => NativeWhatsAppGateway(
    media: media,
    workDirectory: exports,
    sharer: sharer,
  );
  Future<void> exportFixture(File file, String name) async {
    final path = Platform.environment['LEGUM_PDF_QA_DIR'];
    if (path == null || path.isEmpty) return;
    final directory = await Directory(path).create(recursive: true);
    await file.copy(p.join(directory.path, name));
  }

  test('legacy phone values stay compatible', () {
    expect(normalizeWhatsapp('+56 (9) 1234-5678'), '56912345678');
    expect(validWhatsapp('+56 (9) 1234-5678'), isTrue);
    for (final value in [
      '',
      '+0 12345678',
      '++56912345678',
      'abc56912345678',
      '1234',
    ]) {
      expect(validWhatsapp(value), isFalse);
    }
  });
  for (final scope in CatalogPdfScope.values) {
    for (final count in [1, 3, 4, 5, 8, 9]) {
      test('$scope assigns $count products to exact four-card pages', () async {
        final products = List.generate(
          count,
          (i) => item(
            id: 'grid$i',
            name: 'PRODUCT_${i.toString().padLeft(2, '0')}_END',
            presentation: 'Bolsa de 1 kg',
            sale: i.isOdd,
            available: i.isEven,
          ),
        );
        final file = await gateway().generateCatalog([
          ...products,
          products.first,
        ], scope: scope);
        final probe = PdfProbe(await file.readAsBytes());
        expect(probe.pages, (count + 3) ~/ 4);
        expect(probe.pageTexts, hasLength(probe.pages));
        expect(probe.logoDrawCount, probe.pages);
        for (var page = 0; page < probe.pages; page++) {
          final actual = RegExp(r'PRODUCT_\d{2}_END')
              .allMatches(probe.pageTexts[page])
              .map((match) => match[0])
              .toList();
          final expected = products
              .skip(page * 4)
              .take(4)
              .map((p) => p.name)
              .toList();
          expect(actual, expected);
        }
        expect(p.basename(file.path), scope.fileName);
        if (scope == CatalogPdfScope.complete &&
            [1, 3, 4, 5, 8, 9].contains(count)) {
          await exportFixture(file, 'grid-$count-products.pdf');
        }
      });
    }
  }
  test(
    'maximum supported prices remain fully readable without truncation',
    () async {
      final file = await gateway().generateCatalog([
        item(normalClp: 9007199254740991, saleClp: 9007199254740990),
      ]);
      final probe = PdfProbe(await file.readAsBytes());
      expect(probe.pages, 1);
      expect(
        probe.hasText('Precio normal: \$9.007.199.254.740.991 CLP x Kg'),
        isTrue,
      );
      expect(probe.hasText('Oferta: \$9.007.199.254.740.990 CLP x Kg'), isTrue);
      await exportFixture(file, 'maximum-prices.pdf');
    },
  );
  test('empty or hidden selection cannot create/share a PDF', () async {
    var calls = 0;
    final service = gateway(
      sharer: (_) async {
        calls++;
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    await expectLater(service.shareCatalog([]), throwsStateError);
    await expectLater(
      service.shareCatalog([item(visible: false)]),
      throwsStateError,
    );
    expect(calls, 0);
    expect(await exports.exists(), isFalse);
  });
  test('PDF contains selected fields, accents, sale and fallback but no private fields', () async {
    final file = await gateway().generateCatalog([item()]);
    final probe = PdfProbe(await file.readAsBytes());
    expect(probe.raw, startsWith('%PDF-'));
    expect(probe.raw, contains('%%EOF'));
    expect(probe.pages, 1);
    expect(probe.raw, contains('/FontFile2'));
    for (final text in [
      'Piñón & café',
      '500 g',
      'Presentación:',
      'Precio normal:',
      '2.500 CLP x Kg',
      'Oferta:',
      '1.900 CLP x Kg',
      'Agotado',
      'Imagen no disponible',
    ]) {
      expect(
        probe.hasText(text),
        isTrue,
        reason: '$text in ${probe.textContent}',
      );
    }
    expect(probe.textContent, isNot(contains('SKU_PRIVADO')));
    expect(probe.textContent, isNot(contains('DESCRIPCION_PRIVADA')));
    expect(probe.logoObjects, hasLength(1));
    expect(probe.logoDrawCount, probe.pages);
  });
  test(
    'exceptionally long names and presentations are summarized only in PDF',
    () async {
      final name = '${List.filled(800, 'Piñón especial ').join()}FIN_NOMBRE';
      final presentation =
          '${List.filled(1000, 'Caja de café ').join()}FIN_PRESENTACION';
      final file = await gateway().generateCatalog([
        item(name: name, presentation: presentation),
      ]);
      final probe = PdfProbe(await file.readAsBytes());
      await exportFixture(file, 'long-summarized.pdf');
      expect(probe.pages, 1);
      expect(probe.textContent, isNot(contains('FIN_NOMBRE')));
      expect(probe.textContent, isNot(contains('FIN_PRESENTACION')));
      expect(RegExp('…').allMatches(probe.textContent), hasLength(2));
      expect(probe.textContent, contains('Agotado'));
      expect(probe.hasText('Oferta: \$1.900 CLP x Kg'), isTrue);
      expect(name, endsWith('FIN_NOMBRE'));
      expect(presentation, endsWith('FIN_PRESENTACION'));
      expect(probe.logoObjects, hasLength(1));
      expect(probe.logoDrawCount, probe.pages);
    },
  );
  test('ordered cover decodes image; corrupt cover falls back without reading next image', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 8, 8),
      ui.Paint()..color = const ui.Color(0xff285343),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${root.path}/good.png').writeAsBytes(png!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
    await File('${root.path}/bad.png').writeAsString('corrupt');
    final product = item(
      images: const [
        ProductImage(id: 'bad', path: 'bad.png', sortOrder: 2),
        ProductImage(id: 'good', path: 'good.png', sortOrder: 0),
      ],
    );
    final photoFile = await gateway().generateCatalog([product]);
    var probe = PdfProbe(await photoFile.readAsBytes());
    await exportFixture(photoFile, 'valid-product-photo.pdf');
    expect(probe.imageObjects.difference(probe.logoObjects), isNotEmpty);
    expect(media.paths, ['good.png']);
    expect(probe.hasText('Imagen no disponible'), isFalse);
    media.paths.clear();
    probe = PdfProbe(
      await (await gateway().generateCatalog([
        product.copyWith(
          images: const [
            ProductImage(id: 'bad', path: 'bad.png'),
            ProductImage(id: 'good', path: 'good.png', sortOrder: 1),
          ],
        ),
      ])).readAsBytes(),
    );
    expect(probe.hasText('Imagen no disponible'), isTrue);
    expect(media.paths, ['bad.png']);
    expect(probe.imageObjects.difference(probe.logoObjects), isEmpty);
  });
  test('share uses real PDF and iPad origin, retaining file after handoff or unknown result', () async {
    for (final status in [
      ShareResultStatus.success,
      ShareResultStatus.unavailable,
    ]) {
      String? path;
      final service = gateway(
        sharer: (params) async {
          final file = params.files!.single;
          path = file.path;
          expect(file.mimeType, 'application/pdf');
          expect(await File(file.path).exists(), isTrue);
          expect(params.fileNameOverrides, [
            'LegumPro_Catalogo_Personalizado.pdf',
          ]);
          expect(p.basename(file.path), 'LegumPro_Catalogo_Personalizado.pdf');
          expect(
            params.sharePositionOrigin,
            const ui.Rect.fromLTWH(10, 20, 48, 48),
          );
          return ShareResult('', status);
        },
      );
      final selected = [item()];
      await service.shareCatalog(
        selected,
        sharePositionOrigin: const ui.Rect.fromLTWH(10, 20, 48, 48),
      );
      expect(await File(path!).exists(), isTrue);
      expect(selected.single.id, 'one');
    }
  });
  test('cancel/error clean temporary PDF and allow retry without modifying selection', () async {
    var calls = 0;
    final paths = <String>[];
    final service = gateway(
      sharer: (params) async {
        paths.add(params.files!.single.path);
        calls++;
        if (calls == 1) throw StateError('platform failure');
        return const ShareResult('', ShareResultStatus.dismissed);
      },
    );
    final selected = [item()];
    await expectLater(service.shareCatalog(selected), throwsStateError);
    await service.shareCatalog(selected);
    for (final path in paths) {
      expect(await File(path).exists(), isFalse);
      expect(await File(path).parent.exists(), isFalse);
    }
    expect(selected.single.id, 'one');
  });
  test(
    'cleanup expires only owned old files, retaining current and foreign files',
    () async {
      final fresh = await gateway().generateCatalog([item()]);
      final old = await gateway().generateCatalog([item()]);
      final foreign = await File('${exports.path}/other.pdf')
          .writeAsString('foreign');
      final legacy = await File('${exports.path}/catalogo_legum_abc123.pdf')
          .writeAsString('legacy');
      final foreignInside = await File('${old.parent.path}/customer.pdf')
          .writeAsString('foreign inside an export directory');
      final foreignDirectory = await Directory('${exports.path}/customer')
          .create();
      final foreignNamedCatalog = await File(
        '${foreignDirectory.path}/LegumPro_Catalogo.pdf',
      ).writeAsString('foreign directory');
      final expired = DateTime.now().subtract(const Duration(hours: 25));
      await old.setLastModified(expired);
      await foreign.setLastModified(expired);
      await legacy.setLastModified(expired);
      await foreignInside.setLastModified(expired);
      await foreignNamedCatalog.setLastModified(expired);
      await gateway().cleanupExpired();
      expect(await old.exists(), isFalse);
      expect(await fresh.exists(), isTrue);
      expect(await foreign.exists(), isTrue);
      expect(await legacy.exists(), isFalse);
      expect(await foreignInside.exists(), isTrue);
      expect(await foreignNamedCatalog.exists(), isTrue);
    },
  );
  test(
    'explicit modes use exact real attachment names and unique parents',
    () async {
      final paths = <String>[];
      final service = gateway(
        sharer: (params) async {
          final attachment = params.files!.single;
          paths.add(attachment.path);
          final expected = paths.length == 1
              ? 'LegumPro_Catalogo.pdf'
              : 'LegumPro_Catalogo_Personalizado.pdf';
          expect(p.basename(attachment.path), expected);
          expect(params.fileNameOverrides, [expected]);
          expect(await File(attachment.path).exists(), isTrue);
          return const ShareResult('', ShareResultStatus.success);
        },
      );
      // Identical inputs must still follow the explicit mode, even when a
      // personalized selection happens to contain every catalog product.
      final products = [item(), item(id: 'two', sale: false)];
      await service.shareCatalog(products, scope: CatalogPdfScope.complete);
      await service.shareCatalog(products, scope: CatalogPdfScope.personalized);
      await service.shareCatalog(products);
      expect(paths.map(p.dirname).toSet(), hasLength(3));
      for (final path in paths) {
        expect(await File(path).exists(), isTrue);
        final probe = PdfProbe(await File(path).readAsBytes());
        expect(RegExp('Piñón').allMatches(probe.textContent), hasLength(2));
        expect(probe.hasText('Precio normal: \$2.500 CLP x Kg'), isTrue);
        expect(probe.hasText('Oferta: \$1.900 CLP x Kg'), isTrue);
        expect(probe.hasText('Precio: \$2.500 CLP x Kg'), isTrue);
        expect(probe.logoObjects, hasLength(1));
        expect(probe.logoDrawCount, probe.pages);
        expect(probe.hasText('2 productos'), isTrue);
        expect(
          probe.hasText(
            path == paths[0] ? 'Catálogo completo' : 'Catálogo personalizado',
          ),
          isTrue,
        );
      }
      await exportFixture(File(paths[0]), 'LegumPro_Catalogo.pdf');
      await exportFixture(
        File(paths[1]),
        'LegumPro_Catalogo_Personalizado.pdf',
      );
      final fixtureDirectory = Platform.environment['LEGUM_PDF_QA_DIR'];
      if (fixtureDirectory != null && fixtureDirectory.isNotEmpty) {
        final first = File(p.join(fixtureDirectory, 'fixture-product-1.png'));
        final second = File(p.join(fixtureDirectory, 'fixture-product-2.png'));
        if (await first.exists() && await second.exists()) {
          await first.copy(p.join(root.path, 'lentils.png'));
          await second.copy(p.join(root.path, 'chickpeas.png'));
          final preview = await service.generateCatalog([
            item(
              name: 'Lentejas',
              presentation: 'Bolsa de 1 kg',
              sale: false,
              available: true,
              images: const [ProductImage(id: 'lentils', path: 'lentils.png')],
            ),
            item(
              id: 'chickpeas',
              name: 'Garbanzos',
              presentation: 'Bolsa de 1 kg',
              images: const [
                ProductImage(id: 'chickpeas', path: 'chickpeas.png'),
              ],
            ),
          ], scope: CatalogPdfScope.complete);
          await exportFixture(preview, 'LegumPro_Vista_Previa.pdf');
        }
      }
    },
  );
  test('expiration removes the empty owned parent for either mode', () async {
    for (final scope in CatalogPdfScope.values) {
      final file = await gateway().generateCatalog([item()], scope: scope);
      await file.setLastModified(
        DateTime.now().subtract(const Duration(hours: 25)),
      );
      await gateway().cleanupExpired();
      expect(await file.exists(), isFalse);
      expect(await file.parent.exists(), isFalse);
    }
  });
  test(
    'sharing either mode blocks concurrent exports until handoff finishes',
    () async {
      final entered = Completer<void>();
      final released = Completer<ShareResult>();
      var calls = 0;
      final service = gateway(
        sharer: (_) async {
          calls++;
          entered.complete();
          return released.future;
        },
      );
      final first = service.shareCatalog([
        item(),
      ], scope: CatalogPdfScope.complete);
      await entered.future;
      await expectLater(
        service.shareCatalog([item()], scope: CatalogPdfScope.personalized),
        throwsStateError,
      );
      expect(calls, 1);
      released.complete(const ShareResult('', ShareResultStatus.success));
      await first;
    },
  );
}
