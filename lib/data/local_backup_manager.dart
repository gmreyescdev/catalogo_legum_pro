import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../contracts.dart';
import 'catalog_validation.dart';
import 'local_media_manager.dart';

/// Disk-backed extraction with a hard bound on actual inflated bytes.
class _BoundedOutput extends OutputStream {
  _BoundedOutput(String path, this.limit)
    : _output = OutputFileStream(path),
      super(byteOrder: ByteOrder.littleEndian);
  final OutputFileStream _output;
  final int limit;
  @override
  int get length => _output.length;
  @override
  bool get isOpen => _output.isOpen;
  @override
  Future<void> close() => _output.close();
  @override
  void closeSync() => _output.closeSync();
  @override
  void clear() => _output.closeSync();
  @override
  void flush() => _output.flush();
  @override
  Uint8List subset(int start, [int? end]) => _output.subset(start, end);
  void _check(int count) {
    if (length + count > limit) {
      throw const FormatException('Contenido expandido excesivo');
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    _output.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    _output.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    while (!stream.isEOS) {
      final chunk = stream
          .readBytes(stream.length > 65536 ? 65536 : stream.length)
          .toUint8List();
      writeBytes(chunk);
    }
  }
}

class _PreparedBackup {
  _PreparedBackup(this.directory, this.snapshot, this.mediaFiles);
  final Directory directory;
  final CatalogSnapshot snapshot;
  final Map<String, File> mediaFiles;
}

class LocalBackupManager implements BackupManager {
  LocalBackupManager({
    required this.catalog,
    required this.media,
    required this.workDirectory,
    required this.requireAdmin,
    Future<String?> Function()? selectFile,
    Future<void> Function(String path)? shareFile,
    this.beforeReplace,
    this.sessionToken,
  }) : _selectFile = selectFile ?? _nativeSelect,
       _shareFile = shareFile ?? _nativeShare;
  final CatalogRepository catalog;
  final LocalMediaManager media;
  final Directory workDirectory;
  final void Function() requireAdmin;
  final Object? Function()? sessionToken;
  final Future<String?> Function() _selectFile;
  final Future<void> Function(String path) _shareFile;

  /// Failure injection seam for filesystem/authorization rollback tests.
  final Future<void> Function()? beforeReplace;
  final Map<String, _PreparedBackup> _previews = {};
  static const maxArchive = 500 * 1024 * 1024;
  static const maxExpanded = 1024 * 1024 * 1024;
  static const maxManifest = 5 * 1024 * 1024;

  static Future<String?> _nativeSelect() async =>
      (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: false,
      ))?.files.single.path;
  static Future<void> _nativeShare(String path) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text:
            'Respaldo del catálogo. No incluye PIN ni código de recuperación.',
      ),
    );
    if (result.status == ShareResultStatus.dismissed) {
      throw StateError('Compartición cancelada');
    }
  }

  void _guard(Object? token) {
    requireAdmin();
    if (sessionToken != null && sessionToken!() != token) {
      throw StateError('La sesión cambió. Confirma de nuevo la operación');
    }
  }

  /// Startup only: no active preview/export must exist yet.
  Future<void> cleanupInterruptedStaging() async {
    if (!await workDirectory.exists()) {
      return;
    }
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final entries = await workDirectory.list(followLinks: false).toList();
    for (final entry in entries) {
      final name = p.basename(entry.path);
      if (entry is Directory &&
          RegExp(r'^(import|export)_[a-f0-9]{32}$').hasMatch(name)) {
        await entry.delete(recursive: true);
      } else if (entry is File &&
          RegExp(r'^catalog_[a-f0-9]{32}\.zip$').hasMatch(name) &&
          (await entry.lastModified()).isBefore(cutoff)) {
        await entry.delete();
      }
    }
  }

  Future<String> _hash(File file) async {
    final sink = Sha256().newHashSink();
    await for (final chunk in file.openRead()) {
      sink.add(chunk);
    }
    sink.close();
    return (await sink.hash()).bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Set<String> _paths(CatalogSnapshot snapshot) => snapshot.products
      .expand((product) => product.images)
      .map((image) => image.path)
      .toSet();

  @override
  Future<String> exportBackup({bool share = true}) async {
    requireAdmin();
    final token = sessionToken?.call();
    final path = await catalog.exclusive(() async {
      _guard(token);
      await catalog.load();
      final snapshot = catalog.snapshot;
      validateSnapshot(snapshot);
      _checkCounts(snapshot);
      await workDirectory.create(recursive: true);
      final exportToken = newId();
      final stage = await Directory(
        p.join(workDirectory.path, 'export_$exportToken'),
      ).create();
      final output = File(
        p.join(workDirectory.path, 'catalog_$exportToken.zip'),
      );
      final encoder = ZipFileEncoder();
      var opened = false;
      try {
        final inventory = <Map<String, Object?>>[];
        var total = 0;
        for (final relative in _paths(snapshot)) {
          final source = File(media.absolutePath(relative));
          final size = await source.length();
          if (size > LocalMediaManager.maxImageBytes) {
            throw const FormatException('Imagen demasiado grande');
          }
          total += size;
          if (total > maxExpanded) {
            throw const FormatException('Respaldo demasiado grande');
          }
          // Validate before publishing a backup containing unusable media.
          await media.normalizedPng(source);
          final copy = File(p.join(stage.path, p.joinAll(relative.split('/'))));
          await copy.parent.create(recursive: true);
          await source.copy(copy.path);
          inventory.add({
            'path': relative,
            'size': size,
            'sha256': await _hash(copy),
          });
        }
        final manifest = utf8.encode(
          jsonEncode({
            'format_version': 1,
            'catalog': snapshot.toJson(),
            'media': inventory,
          }),
        );
        if (manifest.length > maxManifest ||
            total + manifest.length > maxExpanded) {
          throw const FormatException('Respaldo demasiado grande');
        }
        _guard(token);
        encoder.create(output.path, level: 0);
        opened = true;
        encoder.addArchiveFile(ArchiveFile.bytes('manifest.json', manifest));
        for (final entry in inventory) {
          final relative = entry['path']! as String;
          await encoder.addFile(
            File(p.join(stage.path, p.joinAll(relative.split('/')))),
            relative,
          );
          if (await output.length() > maxArchive) {
            throw const FormatException('Respaldo supera 500 MiB');
          }
        }
        await encoder.close();
        opened = false;
        if (await output.length() > maxArchive) {
          throw const FormatException('Respaldo supera 500 MiB');
        }
        _guard(token);
        return output.path;
      } catch (_) {
        if (opened) {
          await encoder.close();
          opened = false;
        }
        if (await output.exists()) await output.delete();
        rethrow;
      } finally {
        if (await stage.exists()) await stage.delete(recursive: true);
      }
    });
    if (share) {
      try {
        _guard(token);
        await _shareFile(path);
      } catch (_) {
        final temporary = File(path);
        if (await temporary.exists()) {
          await temporary.delete();
        }
        rethrow;
      }
    }
    return path;
  }

  void _checkCounts(CatalogSnapshot snapshot) {
    if (snapshot.categories.length > 1000 ||
        snapshot.products.length > 5000 ||
        _paths(snapshot).length > 9000) {
      throw const FormatException('Respaldo supera límites de registros');
    }
  }

  @override
  Future<BackupPreview?> selectBackup() async {
    requireAdmin();
    final path = await _selectFile();
    if (path == null) return null;
    // The native picker may have paused the app. Preparation is non-mutating;
    // restoring requires a newly valid session, even with an existing preview.
    return prepareBackup(File(path));
  }

  Future<BackupPreview> prepareBackup(File source) async {
    if (await source.length() > maxArchive) {
      throw const FormatException('Respaldo supera 500 MiB');
    }
    await workDirectory.create(recursive: true);
    final token = newId();
    final stage = await Directory(p.join(workDirectory.path, 'import_$token'))
        .create();
    InputFileStream? stream;
    Archive? archive;
    try {
      final copied = await source.copy(p.join(stage.path, 'source.zip'));
      if (await copied.length() > maxArchive) {
        throw const FormatException('Respaldo supera 500 MiB');
      }
      await _preflightZip(copied);
      stream = InputFileStream(copied.path);
      final directory = ZipDirectory()..read(stream);
      if (directory.fileHeaders.isEmpty ||
          directory.fileHeaders.length > 10000) {
        throw const FormatException('ZIP inválido o demasiadas entradas');
      }
      final names = <String>{};
      var expanded = 0;
      for (final header in directory.fileHeaders) {
        final name = header.filename;
        final mode = header.externalFileAttributes >> 16;
        final type = mode & 0xf000;
        if (!names.add(name) ||
            (name != 'manifest.json' && !isManagedPath(name)) ||
            (type != 0 && type != 0x8000) ||
            (header.generalPurposeBitFlag & 1) != 0 ||
            (header.compressionMethod != 0 && header.compressionMethod != 8)) {
          throw const FormatException('Entradas ZIP no permitidas');
        }
        final limit = name == 'manifest.json'
            ? maxManifest
            : LocalMediaManager.maxImageBytes;
        if (header.uncompressedSize <= 0 ||
            header.uncompressedSize > limit ||
            header.uncompressedSize >
                (header.compressedSize == 0 ? 1 : header.compressedSize) *
                    100) {
          throw const FormatException('Expansión ZIP excesiva');
        }
        expanded += header.uncompressedSize;
        if (expanded > maxExpanded) {
          throw const FormatException('Expansión ZIP excesiva');
        }
      }
      stream.setPosition(0);
      archive = ZipDecoder().decodeStream(stream);
      if (archive.length != names.length) {
        throw const FormatException('ZIP inconsistente');
      }
      final extracted = <String, File>{};
      for (final entry in archive) {
        if (!entry.isFile ||
            entry.isSymbolicLink ||
            !names.contains(entry.name)) {
          throw const FormatException('Archivo no permitido');
        }
        final target = File(
          p.join(stage.path, 'files', p.joinAll(entry.name.split('/'))),
        );
        await target.parent.create(recursive: true);
        final sink = _BoundedOutput(
          target.path,
          entry.name == 'manifest.json'
              ? maxManifest
              : LocalMediaManager.maxImageBytes,
        );
        try {
          entry.writeContent(sink);
        } finally {
          sink.closeSync();
        }
        if (await target.length() != entry.size) {
          throw const FormatException('Tamaño ZIP inconsistente');
        }
        final durable = await target.open(mode: FileMode.append);
        await durable.flush();
        await durable.close();
        extracted[entry.name] = target;
      }
      final manifestFile = extracted.remove('manifest.json');
      if (manifestFile == null) {
        throw const FormatException('Falta manifest.json');
      }
      final raw = jsonDecode(await manifestFile.readAsString());
      if (raw is! Map<String, dynamic> ||
          raw.keys.toSet().difference({
            'format_version',
            'catalog',
            'media',
          }).isNotEmpty ||
          raw['format_version'] != 1) {
        throw const FormatException('Versión o estructura no compatible');
      }
      final logical = Map<String, dynamic>.from(raw['catalog'] as Map);
      if (logical.keys.toSet().difference({
        'categories',
        'products',
        'settings',
      }).isNotEmpty) {
        throw const FormatException('Campos de catálogo no permitidos');
      }
      void onlyKeys(Map value, Set<String> keys) {
        if (value.keys.any((key) => key is! String || !keys.contains(key))) {
          throw const FormatException('Campos de respaldo no permitidos');
        }
      }

      onlyKeys(logical['settings'] as Map, {'whatsapp', 'themeMode'});
      for (final category in logical['categories'] as List) {
        onlyKeys(category as Map, {'id', 'name', 'sortOrder'});
      }
      for (final product in logical['products'] as List) {
        onlyKeys(product as Map, {
          'id',
          'categoryId',
          'name',
          'description',
          'sku',
          'presentation',
          'normalClp',
          'saleClp',
          'available',
          'visible',
          'sortOrder',
          'images',
        });
        for (final image in product['images'] as List) {
          onlyKeys(image as Map, {'id', 'path', 'sortOrder'});
        }
      }
      final snapshot = CatalogSnapshot.fromJson(logical);
      validateSnapshot(snapshot);
      _checkCounts(snapshot);
      final declared = <String>{};
      for (final item in raw['media'] as List) {
        final info = Map<String, dynamic>.from(item as Map);
        onlyKeys(info, {'path', 'size', 'sha256'});
        final path = info['path'] as String;
        if (!declared.add(path) ||
            !extracted.containsKey(path) ||
            info['size'] != await extracted[path]!.length() ||
            info['sha256'] != await _hash(extracted[path]!)) {
          throw const FormatException('Inventario o hash de medios inválido');
        }
        await media.normalizedPng(extracted[path]!);
      }
      if (declared.length != extracted.length ||
          declared.length != _paths(snapshot).length ||
          !declared.containsAll(_paths(snapshot))) {
        throw const FormatException('Medios faltantes o no declarados');
      }
      _previews[token] = _PreparedBackup(stage, snapshot, extracted);
      return BackupPreview(
        token: token,
        categoryCount: snapshot.categories.length,
        productCount: snapshot.products.length,
        imageCount: declared.length,
      );
    } catch (_) {
      await archive?.clear();
      await stream?.close();
      stream = null;
      archive = null;
      if (await stage.exists()) await stage.delete(recursive: true);
      rethrow;
    } finally {
      await archive?.clear();
      await stream?.close();
    }
  }

  /// Bound metadata allocation before the ZIP decoder builds its central index.
  Future<void> _preflightZip(File file) async {
    final handle = await file.open();
    try {
      final size = await handle.length();
      final tailSize = size < 65557 ? size : 65557;
      await handle.setPosition(size - tailSize);
      final tail = await handle.read(tailSize);
      final data = ByteData.sublistView(tail);
      var offset = -1;
      for (var i = tail.length - 22; i >= 0; i--) {
        if (data.getUint32(i, Endian.little) == 0x06054b50 &&
            i + 22 + data.getUint16(i + 20, Endian.little) == tail.length) {
          offset = i;
          break;
        }
      }
      if (offset < 0 ||
          data.getUint16(offset + 4, Endian.little) != 0 ||
          data.getUint16(offset + 6, Endian.little) != 0) {
        throw const FormatException('ZIP truncado o multipartes no compatible');
      }
      final count = data.getUint16(offset + 10, Endian.little);
      final directorySize = data.getUint32(offset + 12, Endian.little);
      final directoryOffset = data.getUint32(offset + 16, Endian.little);
      if (count == 0 ||
          count > 10000 ||
          directorySize > 10 * 1024 * 1024 ||
          directoryOffset + directorySize > size - tailSize + offset) {
        throw const FormatException('Índice ZIP excede límites');
      }
    } finally {
      await handle.close();
    }
  }

  @override
  Future<void> restoreBackup(BackupPreview preview) async {
    requireAdmin();
    final token = sessionToken?.call();
    await catalog.exclusive(() async {
      _guard(token);
      final prepared = _previews[preview.token];
      if (prepared == null) throw StateError('Vista previa vencida');
      final generation = newId();
      final staged = await Directory(
        p.join(media.root.path, 'pending_$generation'),
      ).create(recursive: true);
      final promoted = Directory(p.join(media.root.path, 'media', generation));
      final remapped = <String, String>{};
      var committed = false;
      try {
        for (final entry in prepared.mediaFiles.entries) {
          final name = '${newId()}.png';
          final normalized = await media.normalizedPng(entry.value);
          await File(p.join(staged.path, name))
              .writeAsBytes(normalized, flush: true);
          remapped[entry.key] = 'media/$generation/$name';
        }
        _guard(token);
        media.protectPaths(remapped.values);
        await promoted.parent.create(recursive: true);
        await staged.rename(promoted.path);
        final replacement = CatalogSnapshot(
          categories: prepared.snapshot.categories,
          settings: prepared.snapshot.settings,
          products: prepared.snapshot.products
              .map(
                (product) => product.copyWith(
                  images: product.images
                      .map(
                        (image) => ProductImage(
                          id: image.id,
                          path: remapped[image.path]!,
                          sortOrder: image.sortOrder,
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        );
        await beforeReplace?.call();
        _guard(token);
        await catalog.replaceCatalog(replacement);
        committed = true;
        _previews.remove(preview.token);
        // Cleanup failure after commit never claims that the import rolled back.
        try {
          await media.collectGarbage(_paths(catalog.snapshot));
        } catch (_) {
          /* retry next startup */
        }
        try {
          await prepared.directory.delete(recursive: true);
        } catch (_) {
          /* orphan staging only */
        }
      } catch (_) {
        if (!committed) {
          // A repository may have committed then failed to refresh. Read durable SQL
          // before deleting generation files, preserving data on an ambiguous result.
          try {
            await catalog.load();
            committed = _paths(catalog.snapshot)
                .any((path) => path.startsWith('media/$generation/'));
          } catch (_) {
            committed = true;
          }
          if (!committed && await promoted.exists()) {
            await promoted.delete(recursive: true);
          }
        }
        rethrow;
      } finally {
        media.releasePaths(remapped.values);
        if (await staged.exists()) await staged.delete(recursive: true);
      }
    });
  }

  @override
  Future<void> discardPreview(BackupPreview preview) async {
    final prepared = _previews.remove(preview.token);
    if (prepared != null && await prepared.directory.exists()) {
      await prepared.directory.delete(recursive: true);
    }
  }
}
