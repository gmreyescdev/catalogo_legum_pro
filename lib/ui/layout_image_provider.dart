import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// Cache identity includes the actual source and the physical display bounds.
@immutable
class LayoutImageKey {
  const LayoutImageKey(this.sourceKey, this.width, this.height, this.fit);

  final Object sourceKey;
  final int width;
  final int height;
  final BoxFit fit;

  @override
  bool operator ==(Object other) =>
      other is LayoutImageKey &&
      sourceKey == other.sourceKey &&
      width == other.width &&
      height == other.height &&
      fit == other.fit;

  @override
  int get hashCode => Object.hash(sourceKey, width, height, fit);
}

/// Decodes proportionally for a contain/cover layout, without a metadata read.
/// Originals and small images are never enlarged or modified.
class LayoutImageProvider extends ImageProvider<LayoutImageKey> {
  const LayoutImageProvider(
    this.imageProvider, {
    required this.width,
    required this.height,
    required this.fit,
  }) : assert(width > 0 && height > 0),
       assert(fit == BoxFit.cover || fit == BoxFit.contain);

  final ImageProvider imageProvider;
  final int width;
  final int height;
  final BoxFit fit;

  @override
  Future<LayoutImageKey> obtainKey(ImageConfiguration configuration) =>
      imageProvider
          .obtainKey(configuration)
          .then<LayoutImageKey>(
            (Object sourceKey) => LayoutImageKey(sourceKey, width, height, fit),
          );

  @override
  ImageStreamCompleter loadImage(
    LayoutImageKey key,
    ImageDecoderCallback decode,
  ) {
    final completer = imageProvider.loadImage(key.sourceKey, (
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      if (getTargetSize != null) {
        throw StateError('LayoutImageProvider requires an unresized source.');
      }
      return decode(
        buffer,
        getTargetSize: (int intrinsicWidth, int intrinsicHeight) {
          final horizontalScale = key.width / intrinsicWidth;
          final verticalScale = key.height / intrinsicHeight;
          final layoutScale = key.fit == BoxFit.cover
              ? math.max(horizontalScale, verticalScale)
              : math.min(horizontalScale, verticalScale);
          final scale = math.min(1.0, layoutScale);
          return ui.TargetImageSize(
            width: (intrinsicWidth * scale).ceil().clamp(1, intrinsicWidth),
            height: (intrinsicHeight * scale).ceil().clamp(1, intrinsicHeight),
          );
        },
      );
    });
    // Match ResizeImage's eviction: failed wrapped keys must be retryable too.
    completer.addEphemeralErrorListener((Object error, StackTrace? stack) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    });
    return completer;
  }
}
