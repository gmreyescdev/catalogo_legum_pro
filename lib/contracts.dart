import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/painting.dart' show ImageProvider;

import 'models/catalog_models.dart';
export 'models/catalog_models.dart';

abstract class CatalogRepository extends ChangeNotifier {
  CatalogSnapshot get snapshot;
  Future<void> load();
  Future<void> saveCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<void> reorderCategories(List<String> ids);
  Future<void> saveProduct(Product product);

  /// Preview does not reserve a number. Persistent implementations allocate in SQL.
  Future<String> nextSkuPreview() async {
    final numbers = snapshot.products
        .map((p) => p.sku)
        .where((sku) => RegExp(r'^\d+$').hasMatch(sku))
        .map(BigInt.parse);
    return '${numbers.fold<BigInt>(BigInt.zero, (max, n) => n > max ? n : max) + BigInt.one}';
  }

  Future<Product> createProductWithAutoSku(Product draft) async {
    final product = Product(
      id: draft.id,
      categoryId: draft.categoryId,
      name: draft.name,
      description: draft.description,
      sku: await nextSkuPreview(),
      presentation: draft.presentation,
      normalClp: draft.normalClp,
      saleClp: draft.saleClp,
      available: draft.available,
      visible: draft.visible,
      sortOrder: draft.sortOrder,
      images: draft.images,
    );
    await saveProduct(product);
    return product;
  }

  Future<void> deleteProduct(String id);
  Future<void> reorderProducts(List<String> ids);
  Future<void> saveSettings(AppSettings settings);
  Future<void> replaceCatalog(CatalogSnapshot snapshot);
  Future<T> exclusive<T>(Future<T> Function() action);
  Future<void> close();
}

abstract class AdminAuth extends ChangeNotifier {
  bool get isAuthenticated;
  bool get isConfigured;
  Duration get remainingLockout;
  Future<void> initialize();
  Future<bool> unlock(String pin);
  Future<String> beginSetup();
  Future<void> confirmSetup();
  void cancelSetup();
  Future<String> prepareRecovery(String code, String newPin);
  Future<void> confirmRecovery();
  void cancelRecovery();
  Future<void> changePin(String currentPin, String newPin);
  void requireAdmin();
  void lock();
}

abstract class MediaManager {
  String absolutePath(String relativePath);
  ImageProvider imageProvider(String relativePath);
  Future<List<String>> pickGallery();
  Future<List<String>> takePhoto();
  Future<List<String>> retrieveLost();
  Future<void> discardPaths(Iterable<String> paths);
  Future<void> collectGarbage(Set<String> referencedPaths);
}

class BackupPreview {
  const BackupPreview({
    required this.token,
    required this.categoryCount,
    required this.productCount,
    required this.imageCount,
  });
  final String token;
  final int categoryCount, productCount, imageCount;
}

abstract class BackupManager {
  Future<String> exportBackup({bool share = true});
  Future<BackupPreview?> selectBackup();
  Future<void> restoreBackup(BackupPreview preview);
  Future<void> discardPreview(BackupPreview preview);
}

enum CatalogPdfScope {
  complete,
  personalized;

  String get fileName => switch (this) {
    complete => 'LegumPro_Catalogo.pdf',
    personalized => 'LegumPro_Catalogo_Personalizado.pdf',
  };
}

abstract class WhatsAppGateway {
  Future<void> shareCatalog(
    List<Product> products, {
    CatalogPdfScope scope = CatalogPdfScope.personalized,
    Rect? sharePositionOrigin,
  });
}

class AppServices {
  const AppServices({
    required this.catalog,
    required this.auth,
    required this.media,
    required this.backup,
    required this.whatsapp,
  });
  final CatalogRepository catalog;
  final AdminAuth auth;
  final MediaManager media;
  final BackupManager backup;
  final WhatsAppGateway whatsapp;
}
