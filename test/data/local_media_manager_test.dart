import 'dart:io';

import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  late LocalMediaManager media;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('legum_media_test_');
    media = LocalMediaManager(root: dir);
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  test('managed paths stay inside media generation and reject traversal', () {
    expect(
      media.absolutePath('media/generation/image.png'),
      p.join(dir.path, 'media', 'generation', 'image.png'),
    );
    for (final path in [
      '../outside.png',
      '/outside.png',
      r'media\x\image.png',
      'media/generation/../../image.png',
      'media/generation/image.heic',
    ]) {
      expect(() => media.absolutePath(path), throwsFormatException);
    }
  });
  test(
    'garbage collection retains all referenced files and is idempotent',
    () async {
      for (final path in ['media/active/image.png', 'media/orphan/image.png']) {
        final file = File(media.absolutePath(path));
        await file.parent.create(recursive: true);
        await file.writeAsBytes([1, 2, 3]);
      }
      await media.collectGarbage({'media/active/image.png'});
      await media.collectGarbage({'media/active/image.png'});
      expect(
        await File(media.absolutePath('media/active/image.png')).exists(),
        isTrue,
      );
      expect(
        await File(media.absolutePath('media/orphan/image.png')).exists(),
        isFalse,
      );
      // discard is restricted to drafts owned by this process, not arbitrary media.
      await media.discardPaths(['media/active/image.png', '../outside.png']);
      expect(
        await File(media.absolutePath('media/active/image.png')).exists(),
        isTrue,
      );
    },
  );
  test(
    'nonportable and oversized input cannot be copied as an image',
    () async {
      final invalid = File(p.join(dir.path, 'input.heic'));
      await invalid.writeAsBytes([0, 0, 0, 20, 102, 116, 121, 112]);
      await expectLater(media.normalizedPng(invalid), throwsFormatException);
      final handle = await invalid.open(mode: FileMode.write);
      await handle.truncate(LocalMediaManager.maxImageBytes + 1);
      await handle.close();
      await expectLater(media.normalizedPng(invalid), throwsFormatException);
    },
  );
  test('prepared generation is protected until commit or discard', () async {
    const path = 'media/prepared/image.png';
    final file = File(media.absolutePath(path));
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    media.protectPaths([path]);
    await media.collectGarbage({});
    expect(await file.exists(), isTrue);
    media.releasePaths([path]);
    await media.collectGarbage({});
    expect(await file.exists(), isFalse);
  });
}
