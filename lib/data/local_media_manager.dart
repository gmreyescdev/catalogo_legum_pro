import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../contracts.dart';
import 'catalog_validation.dart';

class LocalMediaManager implements MediaManager {
  LocalMediaManager({
    required this.root,
    ImagePicker? picker,
    Set<String> Function()? referencedPaths,
  }) : _picker = picker ?? ImagePicker(),
       _referencedPaths = referencedPaths ?? (() => <String>{});
  final Directory root;
  final ImagePicker _picker;
  final Set<String> Function() _referencedPaths;
  final Set<String> _draftPaths = {};

  /// Keep generations prepared by an import safe from asynchronous GC until SQL commits.
  void protectPaths(Iterable<String> paths) => _draftPaths.addAll(paths);
  void releasePaths(Iterable<String> paths) => _draftPaths.removeAll(paths);

  /// Call only at startup, before any draft or backup operation is created.
  Future<void> cleanupInterruptedStaging() async {
    if (!await root.exists()) {
      return;
    }
    final entries = await root.list(followLinks: false).toList();
    for (final entry in entries) {
      if (entry is Directory &&
          RegExp(r'^pending_[a-f0-9]{32}$').hasMatch(p.basename(entry.path))) {
        await entry.delete(recursive: true);
      }
    }
  }

  static const maxImageBytes = 20 * 1024 * 1024;
  static const maxPixels = 40000000;

  @override
  String absolutePath(String relativePath) {
    if (!isManagedPath(relativePath)) {
      throw const FormatException('Ruta de imagen inválida');
    }
    final path = p.normalize(
      p.join(root.absolute.path, p.joinAll(relativePath.split('/'))),
    );
    if (!p.isWithin(root.absolute.path, path)) {
      throw const FormatException('Ruta fuera del catálogo');
    }
    return path;
  }

  @override
  ImageProvider imageProvider(String relativePath) =>
      FileImage(File(absolutePath(relativePath)));

  /// Decode only supported portable formats; never copy arbitrary bytes as images.
  Future<Uint8List> normalizedPng(File source) async {
    final size = await source.length();
    if (size == 0 || size > maxImageBytes) {
      throw const FormatException('La imagen supera 20 MiB o está vacía');
    }
    final bytes = await source.readAsBytes();
    final png =
        bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (!png && !jpeg) {
      throw const FormatException(
        'Formato no compatible. Selecciona una imagen JPEG o PNG',
      );
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > maxPixels) {
        throw const FormatException('La imagen supera 40 megapíxeles');
      }
      codec = await descriptor.instantiateCodec();
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null || data.lengthInBytes > maxImageBytes) {
        throw const FormatException('La imagen normalizada supera 20 MiB');
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  Future<List<String>> _copySelections(List<XFile> files) async {
    final result = <String>[];
    try {
      for (final source in files) {
        final bytes = await normalizedPng(File(source.path));
        final path = 'media/${newId()}/${newId()}.png';
        final file = File(absolutePath(path));
        await file.parent.create(recursive: true);
        _draftPaths.add(path);
        result.add(path);
        await file.writeAsBytes(bytes, flush: true);
      }
      return result;
    } catch (_) {
      await discardPaths(result);
      rethrow;
    }
  }

  @override
  Future<List<String>> pickGallery() async =>
      _copySelections(await _picker.pickMultiImage());
  @override
  Future<List<String>> takePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    return _copySelections(file == null ? [] : [file]);
  }

  @override
  Future<List<String>> retrieveLost() async {
    if (!Platform.isAndroid) return [];
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    return _copySelections(response.files ?? []);
  }

  Future<void> _deleteManaged(String path) async {
    final file = File(absolutePath(path));
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FormatException('Enlace de imagen no permitido');
    }
    final parent = file.parent;
    if (await FileSystemEntity.type(parent.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FormatException('Enlace de directorio no permitido');
    }
    if (await file.exists() &&
        !_referencedPaths().contains(path) &&
        !_draftPaths.contains(path)) {
      await file.delete();
    }
    if (await parent.exists() && await parent.list().isEmpty) {
      await parent.delete();
    }
  }

  @override
  Future<void> discardPaths(Iterable<String> paths) async {
    final referenced = _referencedPaths();
    for (final path in paths.toSet()) {
      if (!isManagedPath(path) || referenced.contains(path)) continue;
      // Only pending media owned by this process can be discarded as a draft.
      if (_draftPaths.remove(path)) await _deleteManaged(path);
    }
  }

  @override
  Future<void> collectGarbage(Set<String> referencedPaths) async {
    _draftPaths.removeAll(referencedPaths);
    final media = Directory(p.join(root.path, 'media'));
    if (!await media.exists()) return;
    final entities = await media
        .list(recursive: true, followLinks: false)
        .toList();
    for (final entity in entities) {
      if (entity is! File) continue;
      final relative = p
          .relative(entity.path, from: root.path)
          .split(p.separator)
          .join('/');
      if (isManagedPath(relative) &&
          !referencedPaths.contains(relative) &&
          !_referencedPaths().contains(relative) &&
          !_draftPaths.contains(relative)) {
        await _deleteManaged(relative);
      }
    }
  }
}
