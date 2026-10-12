import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../contracts.dart';

// Retained for legacy settings and backup compatibility.
String normalizeWhatsapp(String value) => value
    .trim()
    .replaceAll(RegExp(r'[\s()\-]'), '')
    .replaceFirst(RegExp(r'^\+'), '');
bool validWhatsapp(String value) =>
    RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(normalizeWhatsapp(value));

class NativeWhatsAppGateway implements WhatsAppGateway {
  NativeWhatsAppGateway({
    required this.media,
    required Directory workDirectory,
    Future<ShareResult> Function(ShareParams)? sharer,
  }) : _directory = workDirectory,
       _sharer = sharer ?? SharePlus.instance.share;
  final MediaManager media;
  final Directory _directory;
  final Future<ShareResult> Function(ShareParams) _sharer;
  static const retention = Duration(hours: 24);
  static const _maxImageBytes = 20 * 1024 * 1024;
  bool _sharing = false;
  static final _ownedDirectory = RegExp(r'^catalogo_legum_[a-f0-9]+$');
  static final _legacyFile = RegExp(r'^catalogo_legum_[a-f0-9]+\.pdf$');

  bool _isCatalogFile(String name) =>
      CatalogPdfScope.values.any((scope) => scope.fileName == name);

  Future<void> cleanupExpired() async {
    if (!await _directory.exists()) return;
    final cutoff = DateTime.now().subtract(retention);
    await for (final entry in _directory.list(followLinks: false)) {
      try {
        if (entry is File && _legacyFile.hasMatch(p.basename(entry.path))) {
          if ((await entry.stat()).modified.isBefore(cutoff)) {
            await entry.delete();
          }
        } else if (entry is Directory &&
            _ownedDirectory.hasMatch(p.basename(entry.path))) {
          await for (final child in entry.list(followLinks: false)) {
            if (child is File &&
                _isCatalogFile(p.basename(child.path)) &&
                (await child.stat()).modified.isBefore(cutoff)) {
              await child.delete();
            }
          }
          await _removeEmptyExportDirectory(entry);
        }
      } on FileSystemException {
        // Stale exports must not prevent opening the catalog.
      }
    }
  }

  @override
  Future<void> shareCatalog(
    List<Product> products, {
    CatalogPdfScope scope = CatalogPdfScope.personalized,
    ui.Rect? sharePositionOrigin,
  }) async {
    if (_sharing) throw StateError('Ya se está preparando el catálogo.');
    _sharing = true;
    File? file;
    try {
      file = await generateCatalog(products, scope: scope);
      final result = await _sharer(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          fileNameOverrides: [scope.fileName],
          subject: 'Catálogo LegumPro',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      if (result.status == ShareResultStatus.dismissed) {
        await _deleteQuietly(file);
      }
      // Destination selection is not delivery. Retain for receiver reads.
    } catch (_) {
      if (file != null) await _deleteQuietly(file);
      rethrow;
    } finally {
      _sharing = false;
    }
  }

  Future<File> generateCatalog(
    List<Product> products, {
    CatalogPdfScope scope = CatalogPdfScope.personalized,
  }) async {
    final selection = List<Product>.of(products);
    if (selection.isEmpty || selection.any((p) => !p.visible)) {
      throw StateError('Selecciona productos visibles para crear el PDF.');
    }
    final ids = <String>{};
    selection.removeWhere((p) => !ids.add(p.id));
    await _directory.create(recursive: true);
    await cleanupExpired();
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    final logoBytes = await rootBundle.load(
      'assets/branding/legumpro-logo.jpg',
    );
    final logo = pw.MemoryImage(
      logoBytes.buffer.asUint8List(
        logoBytes.offsetInBytes,
        logoBytes.lengthInBytes,
      ),
    );
    final document = pw.Document(
      title: 'Catálogo LegumPro',
      author: 'LegumPro',
    );
    final format = NumberFormat.decimalPattern('es_CL');
    const forest = PdfColor.fromInt(0xff285343);
    const secondary = PdfColor.fromInt(0xff526157);
    const light = PdfColor.fromInt(0xfff0f3e9);
    const separator = PdfColor.fromInt(0xffd5ddd3);
    final cardWidth = (PdfPageFormat.a4.width - 56 - 14) / 2;
    final innerWidth = cardWidth - 20;
    final totalPages = (selection.length + 3) ~/ 4;
    for (var start = 0; start < selection.length; start += 4) {
      final chunk = selection.skip(start).take(4).toList();
      final photos = <Uint8List?>[];
      for (final product in chunk) {
        photos.add(await _cover(product));
      }
      final pageNumber = start ~/ 4 + 1;
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
          build: (context) {
            pw.Widget card(int index) {
              final product = chunk[index];
              final photo = photos[index];
              final current =
                  '${product.saleClp != null ? 'Oferta' : 'Precio'}: \$${format.format(product.currentClp)} CLP x Kg';
              final normal =
                  'Precio normal: \$${format.format(product.normalClp)} CLP x Kg';
              // Reserve additional price space only when full large amounts wrap.
              final priceWidth = innerWidth - 16;
              final currentWidth =
                  bold.getFont(context).stringMetrics(current).advanceWidth *
                  14;
              final normalWidth =
                  regular.getFont(context).stringMetrics(normal).advanceWidth *
                  9.5;
              final largePrice =
                  currentWidth > priceWidth ||
                  (product.saleClp != null && normalWidth > priceWidth);
              final priceHeight = largePrice ? 84.0 : 60.0;
              final photoHeight = largePrice ? 76.0 : 100.0;
              return pw.Container(
                width: cardWidth,
                height: 320,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: separator, width: .6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.SizedBox(
                      height: 49,
                      child: pw.Text(
                        _summarize(
                          product.name,
                          bold.getFont(context),
                          11.5,
                          innerWidth,
                          3,
                        ),
                        maxLines: 3,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 11.5,
                          color: forest,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      height: photoHeight,
                      color: light,
                      padding: const pw.EdgeInsets.all(6),
                      alignment: pw.Alignment.center,
                      child: photo == null
                          ? pw.Text(
                              'Imagen no disponible',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: secondary,
                              ),
                            )
                          : pw.Image(
                              pw.MemoryImage(photo),
                              fit: pw.BoxFit.contain,
                            ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.SizedBox(
                      height: 26,
                      child: pw.Text(
                        _summarize(
                          'Presentación: ${product.presentation}',
                          regular.getFont(context),
                          10,
                          innerWidth,
                          2,
                        ),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: secondary,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      height: priceHeight,
                      padding: const pw.EdgeInsets.all(8),
                      color: const PdfColor.fromInt(0xffe7f2e8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          if (product.saleClp != null)
                            pw.Text(
                              normal,
                              style: const pw.TextStyle(
                                fontSize: 9.5,
                                color: secondary,
                                decoration: pw.TextDecoration.lineThrough,
                              ),
                            ),
                          pw.Text(
                            current,
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 14,
                              color: forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      height: 20,
                      alignment: pw.Alignment.centerLeft,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                      color: product.available
                          ? light
                          : const PdfColor.fromInt(0xfffbe9e7),
                      child: pw.Text(
                        product.available ? 'Disponible' : 'Agotado',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 10,
                          color: product.available
                              ? forest
                              : const PdfColor.fromInt(0xff8c2c26),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            pw.Widget row(int offset) => pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                card(offset),
                if (offset + 1 < chunk.length) ...[
                  pw.SizedBox(width: 14),
                  card(offset + 1),
                ],
              ],
            );
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  height: 72,
                  padding: const pw.EdgeInsets.all(10),
                  color: forest,
                  child: pw.Row(
                    children: [
                      pw.Image(
                        logo,
                        width: 52,
                        height: 52,
                        fit: pw.BoxFit.contain,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Catálogo LegumPro',
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 18,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            scope == CatalogPdfScope.complete
                                ? 'Catálogo completo'
                                : 'Catálogo personalizado',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            '${selection.length} ${selection.length == 1 ? 'producto' : 'productos'}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.SizedBox(
                  height: 654,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      row(0),
                      if (chunk.length > 2) ...[
                        pw.SizedBox(height: 14),
                        row(2),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.SizedBox(
                  height: 22,
                  child: pw.Column(
                    children: [
                      pw.Divider(color: separator, height: 1),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'LegumPro',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: secondary,
                            ),
                          ),
                          pw.Text(
                            '$pageNumber / $totalPages',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    // Native share providers may ignore overrides for existing files. Keep the
    // actual basename stable, and isolate exports so earlier handoffs stay valid.
    final parent = Directory(
      p.join(_directory.path, 'catalogo_legum_${newId()}'),
    );
    final file = File(p.join(parent.path, scope.fileName));
    try {
      await parent.create();
      await file.writeAsBytes(await document.save(), flush: true);
      return file;
    } catch (_) {
      await _deleteQuietly(file);
      rethrow;
    }
  }

  String _summarize(
    String text,
    PdfFont font,
    double fontSize,
    double width,
    int maxLines,
  ) {
    final chars = text.replaceAll(RegExp(r'\s+'), ' ').trim().runes.toList();
    final lines = <String>[];
    var offset = 0;
    while (offset < chars.length && lines.length < maxLines) {
      final line = <int>[];
      var used = 0.0;
      final lastLine = lines.length == maxLines - 1;
      final remainingWidth = chars
          .skip(offset)
          .fold<double>(
            0,
            (sum, rune) =>
                sum + font.glyphMetrics(rune).advanceWidth * fontSize,
          );
      final truncated = lastLine && remainingWidth > width;
      final limit =
          width -
          (truncated ? font.glyphMetrics(0x2026).advanceWidth * fontSize : 0);
      while (offset < chars.length) {
        final advance =
            font.glyphMetrics(chars[offset]).advanceWidth * fontSize;
        if (line.isNotEmpty && used + advance > limit) break;
        line.add(chars[offset++]);
        used += advance;
      }
      var value = String.fromCharCodes(line).trimRight();
      if (truncated && offset < chars.length) value += '…';
      lines.add(value);
      while (offset < chars.length && chars[offset] == 32) {
        offset++;
      }
    }
    return lines.join('\n');
  }

  Future<Uint8List?> _cover(Product product) async {
    if (product.images.isEmpty) return null;
    final images = List<ProductImage>.of(product.images)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      final file = File(media.absolutePath(images.first.path));
      if (await file.length() > _maxImageBytes) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.openRead(0, _maxImageBytes + 1)) {
        builder.add(chunk);
        if (builder.length > _maxImageBytes) return null;
      }
      buffer = await ui.ImmutableBuffer.fromUint8List(builder.takeBytes());
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > 40000000) return null;
      final scale = math.min(
        1.0,
        800 / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
      await _removeEmptyExportDirectory(file.parent);
    } on FileSystemException {
      /* Retry using retention cleanup next startup. */
    }
  }

  Future<void> _removeEmptyExportDirectory(Directory directory) async {
    if (!p.equals(directory.parent.path, _directory.path) ||
        !_ownedDirectory.hasMatch(p.basename(directory.path))) {
      return;
    }
    if (await directory.exists() && await directory.list().isEmpty) {
      await directory.delete();
    }
  }
}
