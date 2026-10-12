import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/ui/layout_image_provider.dart';
import 'package:catalogo_legum_pro/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const Color(0xff008844), BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Size> decodedSize(ImageProvider provider) async {
  final result = Completer<ui.Size>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      result.complete(
        ui.Size(info.image.width.toDouble(), info.image.height.toDouble()),
      );
      info.dispose();
    },
    onError: (Object error, StackTrace? stack) =>
        result.completeError(error, stack),
  );
  stream.addListener(listener);
  try {
    return await result.future;
  } finally {
    stream.removeListener(listener);
  }
}

class PhotoMedia implements MediaManager {
  PhotoMedia(this.provider);
  final ImageProvider provider;
  @override
  ImageProvider imageProvider(String relativePath) => provider;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Test photo only');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test(
    'large 4:3 photo decodes at display size with real pixel reduction',
    () async {
      final bytes = await png(4000, 3000);
      final source = MemoryImage(bytes);
      expect(await decodedSize(source), const ui.Size(4000, 3000));
      final actual = await decodedSize(
        LayoutImageProvider(
          source,
          width: 1056,
          height: 792,
          fit: BoxFit.cover,
        ),
      );
      expect(actual, const ui.Size(1056, 792));
      expect(actual.width * actual.height * 4, lessThan(48000000 / 10));
      // Resolving the same original again still obtains full-detail pixels.
      expect(await decodedSize(source), const ui.Size(4000, 3000));
    },
  );

  test(
    'portrait and panorama preserve aspect with cover and contain',
    () async {
      for (final dimensions in [
        const ui.Size(1200, 1600),
        const ui.Size(2400, 600),
      ]) {
        final source = MemoryImage(
          await png(dimensions.width.toInt(), dimensions.height.toInt()),
        );
        for (final fit in [BoxFit.cover, BoxFit.contain]) {
          final actual = await decodedSize(
            LayoutImageProvider(source, width: 600, height: 450, fit: fit),
          );
          expect(
            actual.width / actual.height,
            closeTo(dimensions.width / dimensions.height, 0.01),
          );
          if (fit == BoxFit.cover) {
            expect(actual.width, greaterThanOrEqualTo(600));
            expect(actual.height, greaterThanOrEqualTo(450));
          } else {
            expect(actual.width, lessThanOrEqualTo(600));
            expect(actual.height, lessThanOrEqualTo(450));
          }
        }
      }
    },
  );

  test('small source is never enlarged at decode', () async {
    final source = MemoryImage(await png(80, 60));
    for (final fit in [BoxFit.cover, BoxFit.contain]) {
      expect(
        await decodedSize(
          LayoutImageProvider(source, width: 1056, height: 792, fit: fit),
        ),
        const ui.Size(80, 60),
      );
    }
  });

  test(
    'equivalent layouts reuse cache, a larger detail gets larger pixels',
    () async {
      final source = MemoryImage(await png(1600, 1200));
      final card = LayoutImageProvider(
        source,
        width: 300,
        height: 225,
        fit: BoxFit.cover,
      );
      await decodedSize(card);
      final count = PaintingBinding.instance.imageCache.currentSize;
      await decodedSize(
        LayoutImageProvider(source, width: 300, height: 225, fit: BoxFit.cover),
      );
      expect(PaintingBinding.instance.imageCache.currentSize, count);
      final detail = await decodedSize(
        LayoutImageProvider(
          source,
          width: 900,
          height: 675,
          fit: BoxFit.contain,
        ),
      );
      expect(detail, const ui.Size(900, 675));
      expect(await decodedSize(card), const ui.Size(300, 225));
    },
  );

  testWidgets(
    'ProductPhoto uses actual bounds and DPR, then adapts to detail',
    (tester) async {
      final bytes = await tester.runAsync(() => png(1600, 1200));
      final media = PhotoMedia(MemoryImage(bytes!));
      Future<void> display(double width, BoxFit fit) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(devicePixelRatio: 3),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: ProductPhoto(
                    media: media,
                    image: const ProductImage(id: 'photo', path: 'test.png'),
                    fit: fit,
                    label: 'Foto del producto',
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await display(100, BoxFit.cover);
      var image = tester.widget<Image>(find.byType(Image));
      expect(
        await tester.runAsync(() => decodedSize(image.image)),
        const ui.Size(300, 225),
      );
      expect(image.fit, BoxFit.cover);
      await display(300, BoxFit.contain);
      image = tester.widget<Image>(find.byType(Image));
      expect(
        await tester.runAsync(() => decodedSize(image.image)),
        const ui.Size(900, 675),
      );
      expect(image.fit, BoxFit.contain);
      expect(find.byType(AspectRatio), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('invalid photo keeps visible accessible fallback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          child: ProductPhoto(
            media: PhotoMedia(MemoryImage(Uint8List.fromList([0, 1, 2]))),
            image: const ProductImage(id: 'broken', path: 'broken.png'),
            label: 'Foto del producto',
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('Imagen no disponible'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Imagen no disponible')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
