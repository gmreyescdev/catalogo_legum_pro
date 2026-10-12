import 'package:diacritic/diacritic.dart';

import '../contracts.dart';
import 'whatsapp/native_whatsapp_gateway.dart' show validWhatsapp;

String normalizedText(String value) =>
    removeDiacritics(value)
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .toLowerCase()
        .trim();
String skuKey(String value) => value.toLowerCase().trim();
const maxClp = 9007199254740991;

void validateSettings(AppSettings settings) {
  if (!['system', 'light', 'dark'].contains(settings.themeMode)) {
    throw const FormatException('Tema inválido');
  }
  if (settings.whatsapp.isNotEmpty && !validWhatsapp(settings.whatsapp)) {
    throw const FormatException('Número WhatsApp internacional inválido');
  }
}

void validateCategory(Category category) {
  if (category.id.isEmpty ||
      category.name.trim().isEmpty ||
      category.sortOrder < 0) {
    throw const FormatException('Categoría inválida');
  }
}

void validateProduct(Product product, Set<String> categoryIds) {
  if ([
        product.id,
        product.name,
        product.description,
        product.sku,
        product.presentation,
      ].any((v) => v.trim().isEmpty) ||
      !categoryIds.contains(product.categoryId) ||
      product.sortOrder < 0 ||
      product.images.isEmpty ||
      product.normalClp < 0 ||
      product.normalClp > maxClp ||
      (product.saleClp != null &&
          (product.saleClp! < 0 || product.saleClp! >= product.normalClp))) {
    throw const FormatException('Producto incompleto o precio inválido');
  }
  final ids = <String>{};
  final paths = <String>{};
  final positions = <int>{};
  for (final image in product.images) {
    if (image.id.isEmpty ||
        !ids.add(image.id) ||
        !paths.add(image.path) ||
        !positions.add(image.sortOrder) ||
        image.sortOrder < 0 ||
        !isManagedPath(image.path)) {
      throw const FormatException('Referencia de imagen inválida');
    }
  }
}

bool isManagedPath(String path) =>
    RegExp(r'^media/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+\.(png|jpg|jpeg)$')
        .hasMatch(path);

void validateSnapshot(CatalogSnapshot snapshot) {
  validateSettings(snapshot.settings);
  final ids = <String>{};
  final names = <String>{};
  for (final category in snapshot.categories) {
    validateCategory(category);
    if (!ids.add(category.id) || !names.add(normalizedText(category.name))) {
      throw const FormatException('Categorías duplicadas');
    }
  }
  final products = <String>{};
  final skus = <String>{};
  final images = <String>{};
  final paths = <String>{};
  for (final product in snapshot.products) {
    validateProduct(product, ids);
    if (!products.add(product.id) || !skus.add(skuKey(product.sku))) {
      throw const FormatException('Producto o SKU duplicado');
    }
    for (final image in product.images) {
      if (!images.add(image.id) || !paths.add(image.path)) {
        throw const FormatException('Imagen duplicada');
      }
    }
  }
}
