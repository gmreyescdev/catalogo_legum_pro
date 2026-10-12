import 'dart:async';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends AdminAuth {
  bool active = true;
  @override
  bool get isAuthenticated => active;
  @override
  void requireAdmin() {
    if (!active) throw StateError('Sin sesión');
  }

  @override
  void lock() {
    active = false;
    notifyListeners();
  }

  void unlockNow() {
    active = true;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Catalog extends CatalogRepository {
  CatalogSnapshot _snapshot = CatalogSnapshot(
    categories: [const Category(id: 'old', name: 'Existente')],
  );
  Completer<void>? saveStarted, continueSave;
  bool fail = false;
  @override
  CatalogSnapshot get snapshot => _snapshot;
  @override
  Future<void> saveCategory(Category category) async {
    saveStarted?.complete();
    await continueSave?.future;
    if (fail) throw StateError('Fallo SQL');
    _snapshot = CatalogSnapshot(
      categories: [...snapshot.categories, category],
      products: snapshot.products,
    );
    notifyListeners();
  }

  @override
  Future<void> saveProduct(Product product) async {
    _snapshot = CatalogSnapshot(
      categories: snapshot.categories,
      products: [
        ...snapshot.products.where((p) => p.id != product.id),
        product,
      ],
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Ports implements MediaManager, BackupManager, WhatsAppGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Catalog catalog;
  late _Auth auth;
  late ProductEditorViewModel vm;
  setUp(() {
    catalog = _Catalog();
    auth = _Auth();
    final ports = _Ports();
    vm = ProductEditorViewModel(
      AppServices(
        catalog: catalog,
        auth: auth,
        media: ports,
        backup: ports,
        whatsapp: ports,
      ),
      null,
    );
  });
  tearDown(() {
    vm.dispose();
    catalog.dispose();
    auth.dispose();
  });
  void fillDraft() {
    vm.edit(() {
      vm.name = 'Nombre';
      vm.description = 'Descripción';
      vm.presentation = '1 kg';
      vm.normalPrice = '2500';
      vm.salePrice = '1900';
      vm.onSale = true;
      vm.categoryId = 'old';
      vm.available = false;
      vm.visible = false;
      vm.images = [
        const ProductImage(id: 'photo', path: 'media/draft/photo.png'),
      ];
    });
  }

  test(
    'preview populates read-only SKU without marking a clean draft dirty',
    () async {
      expect(await vm.initializeSku(), isTrue);
      expect(vm.sku, '1');
      expect(vm.dirty, isFalse);
      expect(catalog.snapshot.products, isEmpty);
    },
  );
  test('inline category creation selects persisted ID and preserves all draft fields', () async {
    fillDraft();
    expect(await vm.createCategory(' Nueva categoría '), isTrue);
    final category = catalog.snapshot.categories.last;
    expect(category.name, 'Nueva categoría');
    expect(vm.categoryId, category.id);
    expect(vm.name, 'Nombre');
    expect(vm.description, 'Descripción');
    expect(vm.normalPrice, '2500');
    expect(vm.salePrice, '1900');
    expect(vm.onSale, isTrue);
    expect(vm.available, isFalse);
    expect(vm.visible, isFalse);
    expect(vm.images.single.path, 'media/draft/photo.png');
    expect(vm.dirty, isTrue);
  });
  test(
    'duplicate, failure or invalid session preserves category and draft',
    () async {
      fillDraft();
      expect(await vm.createCategory('EXISTENTE'), isFalse);
      expect(vm.categoryId, 'old');
      expect(catalog.snapshot.categories, hasLength(1));
      catalog.fail = true;
      expect(await vm.createCategory('Nueva'), isFalse);
      expect(vm.categoryId, 'old');
      expect(vm.images, hasLength(1));
      auth.lock();
      expect(await vm.createCategory('Otra'), isFalse);
      expect(vm.categoryId, 'old');
      expect(vm.name, 'Nombre');
    },
  );
  test('locking and reauth during category command does not mutate draft selection', () async {
    fillDraft();
    catalog.saveStarted = Completer<void>();
    catalog.continueSave = Completer<void>();
    final pending = vm.createCategory('En proceso');
    await catalog.saveStarted!.future;
    auth.lock();
    auth.unlockNow();
    catalog.continueSave!.complete();
    expect(await pending, isFalse);
    expect(vm.categoryId, 'old');
    expect(vm.name, 'Nombre');
  });
  test(
    'new product save assigns current number despite empty or stale preview',
    () async {
      fillDraft();
      vm.sku = '';
      expect(await vm.save(), isTrue);
      expect(catalog.snapshot.products.single.sku, '1');
      expect(vm.sku, '1');
    },
  );
  test(
    'editing preserves original SKU even if draft SKU was accidentally altered',
    () async {
      fillDraft();
      expect(await vm.save(), isTrue);
      final product = catalog.snapshot.products.single;
      final editor = ProductEditorViewModel(vm.services, product);
      addTearDown(editor.dispose);
      editor.sku = 'UNWANTED';
      editor.name = 'Modificado';
      expect(await editor.save(), isTrue);
      expect(catalog.snapshot.products.single.sku, '1');
      expect(catalog.snapshot.products.single.name, 'Modificado');
    },
  );
}
