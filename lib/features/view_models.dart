import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:diacritic/diacritic.dart';

import '../contracts.dart';

String clp(int amount) =>
    '\$${NumberFormat.decimalPattern('es_CL').format(amount)} CLP';

String normalized(String value) => removeDiacritics(value).toLowerCase().trim();

abstract class CommandViewModel extends ChangeNotifier {
  bool busy = false;
  String? error;
  bool disposed = false;
  void changed() {
    if (!disposed) notifyListeners();
  }

  Future<bool> command(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    changed();
    try {
      await action();
      return true;
    } catch (e) {
      error = switch (e) {
        StateError() => e.message.toString(),
        FormatException() => e.message,
        _ => 'No se pudo completar la operación. Intenta nuevamente.',
      };
      return false;
    } finally {
      busy = false;
      changed();
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class CatalogViewModel extends CommandViewModel {
  CatalogViewModel(this.services) {
    services.catalog.addListener(_refresh);
  }
  final AppServices services;
  String query = '';
  String? categoryId;
  final Set<String> _selected = {};
  CatalogSnapshot get snapshot => services.catalog.snapshot;
  List<Category> get categories =>
      [...snapshot.categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  List<Product> get publicProducts =>
      snapshot.products.where((p) => p.visible).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  List<Product> get products {
    final needle = normalized(query);
    return publicProducts
        .where(
          (p) =>
              (categoryId == null || p.categoryId == categoryId) &&
              (needle.isEmpty ||
                  normalized('${p.name} ${p.description} ${p.sku}')
                      .contains(needle)),
        )
        .toList();
  }

  List<Product> get selected =>
      publicProducts.where((p) => _selected.contains(p.id)).toList();
  bool isSelected(String id) => _selected.contains(id);
  Product? product(String id) {
    for (final p in publicProducts) {
      if (p.id == id) return p;
    }
    return null;
  }

  String categoryName(String id) =>
      categories.where((c) => c.id == id).firstOrNull?.name ?? '';
  void setQuery(String value) {
    query = value;
    changed();
  }

  void setCategory(String? value) {
    categoryId = value;
    changed();
  }

  void clearFilters() {
    query = '';
    categoryId = null;
    changed();
  }

  void toggle(String id) {
    if (!_selected.remove(id) && product(id) != null) _selected.add(id);
    changed();
  }

  void clearSelection() {
    _selected.clear();
    changed();
  }

  void _refresh() {
    _selected.removeWhere((id) => product(id) == null);
    if (!categories.any((c) => c.id == categoryId)) categoryId = null;
    changed();
  }

  Future<bool> shareSelected({Rect? sharePositionOrigin}) => command(() async {
    final current = selected;
    if (current.isEmpty) {
      throw StateError('No hay productos seleccionados disponibles.');
    }
    await services.whatsapp.shareCatalog(
      current,
      scope: CatalogPdfScope.personalized,
      sharePositionOrigin: sharePositionOrigin,
    );
  });

  Future<bool> shareAll({Rect? sharePositionOrigin}) => command(() async {
    final current = publicProducts;
    if (current.isEmpty) {
      throw StateError('No hay productos disponibles para compartir.');
    }
    await services.whatsapp.shareCatalog(
      current,
      scope: CatalogPdfScope.complete,
      sharePositionOrigin: sharePositionOrigin,
    );
  });
  @override
  void dispose() {
    services.catalog.removeListener(_refresh);
    super.dispose();
  }
}

class AuthViewModel extends CommandViewModel {
  AuthViewModel(this.auth) {
    auth.addListener(_authChanged);
  }
  final AdminAuth auth;
  String? setupCode;
  String? recoveryCode;
  void _authChanged() {
    if (!auth.isAuthenticated) {
      setupCode = null;
      recoveryCode = null;
    }
    changed();
  }

  Future<bool> unlock(String pin) => command(() async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw StateError('Ingresa exactamente 4 dígitos.');
    }
    if (!await auth.unlock(pin)) throw StateError('PIN incorrecto.');
    if (!auth.isConfigured) setupCode = await auth.beginSetup();
  });
  Future<bool> confirmSetup() => command(() async {
    auth.requireAdmin();
    await auth.confirmSetup();
    setupCode = null;
  });
  void cancelSetup() {
    auth.cancelSetup();
    setupCode = null;
    changed();
  }

  Future<bool> recover(String code, String pin, String confirm) =>
      command(() async {
        if (!RegExp(r'^\d{4}$').hasMatch(pin) || pin != confirm) {
          throw StateError(
            'El PIN debe tener 4 dígitos y coincidir con su confirmación.',
          );
        }
        recoveryCode = await auth.prepareRecovery(code.trim(), pin);
      });
  Future<bool> confirmRecovery() => command(() async {
    await auth.confirmRecovery();
    recoveryCode = null;
  });
  void cancelRecovery() {
    auth.cancelRecovery();
    recoveryCode = null;
    changed();
  }

  Future<bool> changePin(String current, String pin, String confirm) =>
      command(() async {
        auth.requireAdmin();
        if (!RegExp(r'^\d{4}$').hasMatch(pin) || pin != confirm) {
          throw StateError(
            'El PIN debe tener 4 dígitos y coincidir con su confirmación.',
          );
        }
        await auth.changePin(current, pin);
      });
  @override
  void dispose() {
    auth.removeListener(_authChanged);
    super.dispose();
  }
}

class AdminViewModel extends CommandViewModel {
  AdminViewModel(this.services) {
    services.catalog.addListener(changed);
  }
  final AppServices services;
  BackupPreview? preview;
  CatalogSnapshot get snapshot => services.catalog.snapshot;
  List<Product> get products =>
      [...snapshot.products]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  List<Category> get categories =>
      [...snapshot.categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  Future<bool> protected(Future<void> Function() action) => command(() async {
    services.auth.requireAdmin();
    await action();
  });
  Future<bool> saveCategory(String? id, String name) => protected(() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('El nombre de la categoría es obligatorio.');
    }
    if (categories.any(
      (c) => c.id != id && normalized(c.name) == normalized(trimmed),
    )) {
      throw StateError('Ya existe una categoría con ese nombre.');
    }
    await services.catalog.saveCategory(
      Category(
        id: id ?? newId(),
        name: trimmed,
        sortOrder:
            categories.where((c) => c.id == id).firstOrNull?.sortOrder ??
            categories.length,
      ),
    );
  });
  Future<String?> createCategory(String name) async {
    final id = newId();
    return await saveCategory(id, name) ? id : null;
  }

  Future<bool> deleteCategory(String id) => protected(() async {
    if (products.any((p) => p.categoryId == id)) {
      throw StateError('Reasigna o elimina sus productos primero.');
    }
    await services.catalog.deleteCategory(id);
  });
  Future<bool> deleteProduct(String id) => protected(() async {
    await services.catalog.deleteProduct(id);
    // The catalog commit succeeded. Cleanup can be retried at startup; never
    // misreport a committed deletion as a failed operation.
    try {
      await services.media.collectGarbage({
        for (final p in snapshot.products)
          for (final i in p.images) i.path,
      });
    } catch (_) {}
  });
  Future<bool> toggleProduct(Product p, {bool visibility = false}) => protected(
    () => services.catalog.saveProduct(
      visibility
          ? p.copyWith(visible: !p.visible)
          : p.copyWith(available: !p.available),
    ),
  );
  Future<bool> moveProduct(int index, int delta) => protected(() async {
    final ids = products.map((p) => p.id).toList();
    if (index + delta < 0 || index + delta >= ids.length) return;
    final id = ids.removeAt(index);
    ids.insert(index + delta, id);
    await services.catalog.reorderProducts(ids);
  });
  Future<bool> moveCategory(int index, int delta) => protected(() async {
    final ids = categories.map((c) => c.id).toList();
    if (index + delta < 0 || index + delta >= ids.length) return;
    final id = ids.removeAt(index);
    ids.insert(index + delta, id);
    await services.catalog.reorderCategories(ids);
  });
  Future<bool> saveTheme(String mode) => protected(
    () => services.catalog.saveSettings(
      snapshot.settings.copyWith(themeMode: mode),
    ),
  );
  Future<bool> export() => protected(() async {
    await services.backup.exportBackup();
  });
  Future<bool> selectBackup() => protected(() async {
    if (preview != null) await services.backup.discardPreview(preview!);
    preview = await services.backup.selectBackup();
  });
  Future<bool> discardPreview() => protected(() async {
    if (preview != null) await services.backup.discardPreview(preview!);
    preview = null;
  });
  Future<bool> restore() => protected(() async {
    if (preview == null) {
      throw StateError('Selecciona y valida un respaldo primero.');
    }
    await services.backup.restoreBackup(preview!);
    preview = null;
  });
  @override
  void dispose() {
    services.catalog.removeListener(changed);
    super.dispose();
  }
}

class ProductEditorViewModel extends CommandViewModel {
  ProductEditorViewModel(this.services, this.original) {
    final p = original;
    name = p?.name ?? '';
    description = p?.description ?? '';
    sku = p?.sku ?? '';
    presentation = p?.presentation ?? '';
    normalPrice = p?.normalClp.toString() ?? '';
    salePrice = p?.saleClp?.toString() ?? '';
    onSale = p?.saleClp != null;
    categoryId = p?.categoryId;
    visible = p?.visible ?? true;
    available = p?.available ?? true;
    images = [...?p?.images];
  }
  final AppServices services;
  final Product? original;
  late String name, description, sku, presentation, normalPrice, salePrice;
  late bool onSale, visible, available;
  String? categoryId;
  late List<ProductImage> images;
  final Set<String> _newPaths = {};
  bool dirty = false;
  bool saved = false;
  Future<bool> initializeSku() => command(() async {
    if (original != null) return;
    services.auth.requireAdmin();
    final preview = await services.catalog.nextSkuPreview();
    services.auth.requireAdmin();
    if (!disposed) sku = preview;
  });
  Future<bool> createCategory(String categoryName) => command(() async {
    services.auth.requireAdmin();
    var sessionRevoked = false;
    void watchSession() {
      if (!services.auth.isAuthenticated) sessionRevoked = true;
    }

    services.auth.addListener(watchSession);
    final admin = AdminViewModel(services);
    try {
      final id = await admin.createCategory(categoryName);
      if (id == null) {
        throw StateError(admin.error ?? 'No se pudo crear la categoría.');
      }
      services.auth.requireAdmin();
      if (sessionRevoked) {
        throw StateError(
          'La sesión cambió. Selecciona la categoría después de autenticarte.',
        );
      }
      if (!disposed &&
          services.catalog.snapshot.categories.any((c) => c.id == id)) {
        categoryId = id;
        dirty = true;
      }
    } finally {
      services.auth.removeListener(watchSession);
      admin.dispose();
    }
  });
  void edit(void Function() action) {
    action();
    dirty = true;
    changed();
  }

  Future<bool> addImages({bool camera = false, bool recover = false}) =>
      command(() async {
        services.auth.requireAdmin();
        final paths = recover
            ? await services.media.retrieveLost()
            : camera
            ? await services.media.takePhoto()
            : await services.media.pickGallery();
        // Native pickers can lock the session. Retain media as a draft until reauth.
        for (final path in paths) {
          _newPaths.add(path);
          images.add(ProductImage(id: newId(), path: path));
        }
        if (paths.isNotEmpty) dirty = true;
      });
  void removeImage(int index) {
    services.auth.requireAdmin();
    edit(() => images.removeAt(index));
  }

  void moveImage(int index, int delta) {
    services.auth.requireAdmin();
    if (index + delta < 0 || index + delta >= images.length) return;
    edit(() {
      final image = images.removeAt(index);
      images.insert(index + delta, image);
    });
  }

  String? validate() {
    if ([
      name,
      description,
      presentation,
      if (original != null) sku,
    ].any((v) => v.trim().isEmpty)) {
      return 'Completa nombre, descripción y presentación.';
    }
    if (categoryId == null ||
        !services.catalog.snapshot.categories.any((c) => c.id == categoryId)) {
      return 'Selecciona una categoría existente.';
    }
    if (!RegExp(r'^\d+$').hasMatch(normalPrice)) {
      return 'Precio normal: ingresa un entero CLP no negativo.';
    }
    final normal = int.tryParse(normalPrice);
    if (normal == null || normal > 9007199254740991) {
      return 'Precio normal fuera de rango.';
    }
    if (onSale &&
        (!RegExp(r'^\d+$').hasMatch(salePrice) ||
            int.tryParse(salePrice) == null ||
            int.parse(salePrice) >= normal)) {
      return 'La oferta debe ser un entero no negativo menor que el precio normal.';
    }
    if (original != null &&
        services.catalog.snapshot.products.any(
          (p) =>
              p.id != original?.id &&
              p.sku.toLowerCase() == sku.trim().toLowerCase(),
        )) {
      return 'Ya existe un producto con ese SKU.';
    }
    if (images.isEmpty) return 'Agrega al menos una foto.';
    return null;
  }

  Future<bool> save() => command(() async {
    services.auth.requireAdmin();
    final message = validate();
    if (message != null) throw StateError(message);
    final orderedImages = [
      for (var i = 0; i < images.length; i++)
        ProductImage(id: images[i].id, path: images[i].path, sortOrder: i),
    ];
    final draft = Product(
      id: original?.id ?? newId(),
      categoryId: categoryId!,
      name: name.trim(),
      description: description.trim(),
      sku: original?.sku ?? sku.trim(),
      presentation: presentation.trim(),
      normalClp: int.parse(normalPrice),
      saleClp: onSale ? int.parse(salePrice) : null,
      visible: visible,
      available: available,
      sortOrder:
          original?.sortOrder ?? services.catalog.snapshot.products.length,
      images: orderedImages,
    );
    if (original == null) {
      final created = await services.catalog.createProductWithAutoSku(draft);
      sku = created.sku;
    } else {
      await services.catalog.saveProduct(draft);
    }
    saved = true;
    dirty = false;
    // Save is already committed. Retrying must not create a duplicate product
    // merely because optional orphan cleanup was interrupted.
    try {
      await services.media.discardPaths(
        _newPaths.where((p) => !images.any((i) => i.path == p)),
      );
      await services.media.collectGarbage({
        for (final p in services.catalog.snapshot.products)
          for (final i in p.images) i.path,
      });
    } catch (_) {
      /* The startup collector retries orphan cleanup. */
    }
    _newPaths.clear();
  });
  Future<bool> cancel() => command(() async {
    services.auth.requireAdmin();
    if (!saved) await services.media.discardPaths(_newPaths);
    _newPaths.clear();
    dirty = false;
  });
}
