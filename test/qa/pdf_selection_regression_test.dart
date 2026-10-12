import 'dart:async';
import 'dart:ui' show Rect;

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Catalog extends CatalogRepository {
  CatalogSnapshot value = CatalogSnapshot();
  void update(List<Product> products) {
    value = CatalogSnapshot(
      categories: const [Category(id: 'c', name: 'Categoría')],
      products: products,
    );
    notifyListeners();
  }

  @override
  CatalogSnapshot get snapshot => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Share implements WhatsAppGateway {
  final calls = <List<Product>>[];
  final scopes = <CatalogPdfScope>[];
  Completer<void>? pending;
  Object? failure;
  Rect? origin;
  @override
  Future<void> shareCatalog(
    List<Product> products, {
    CatalogPdfScope scope = CatalogPdfScope.personalized,
    Rect? sharePositionOrigin,
  }) async {
    calls.add(List.of(products));
    scopes.add(scope);
    origin = sharePositionOrigin;
    if (failure != null) throw failure!;
    await pending?.future;
  }
}

class _Auth extends AdminAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Media implements MediaManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Backup implements BackupManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Product _product(String id, int order, {bool available = true}) => Product(
  id: id,
  categoryId: 'c',
  name: 'Producto $id',
  description: 'Descripción privada del PDF',
  sku: 'SKU-$id',
  presentation: '1 kg',
  normalClp: 1234,
  available: available,
  sortOrder: order,
);

void main() {
  late _Catalog catalog;
  late _Share share;
  late _Auth auth;
  late CatalogViewModel vm;
  setUp(() {
    catalog = _Catalog();
    share = _Share();
    auth = _Auth();
    catalog.update([
      _product('later', 2),
      _product('sold', 0, available: false),
      _product('first', 1),
    ]);
    vm = CatalogViewModel(
      AppServices(
        catalog: catalog,
        auth: auth,
        media: _Media(),
        backup: _Backup(),
        whatsapp: share,
      ),
    );
  });
  tearDown(() {
    vm.dispose();
    catalog.dispose();
    auth.dispose();
  });

  test(
    'empty selection never offers the complete catalog to sharing',
    () async {
      expect(await vm.shareSelected(), isFalse);
      expect(share.calls, isEmpty);
      expect(vm.error, isNotNull);
    },
  );

  test('complete catalog ignores filters and selection while preserving visibility and order', () async {
    catalog.update([
      _product('later', 2),
      _product('hidden', -1).copyWith(visible: false),
      _product('sold', 0, available: false),
      _product('first', 1),
    ]);
    vm.toggle('first');
    vm.setQuery('does not match');
    vm.setCategory('other');
    expect(vm.products, isEmpty);
    final original = catalog.snapshot;
    const anchor = Rect.fromLTWH(8, 12, 48, 48);
    expect(await vm.shareAll(sharePositionOrigin: anchor), isTrue);
    expect(share.calls.single.map((p) => p.id), ['sold', 'first', 'later']);
    expect(share.calls.single.first.available, isFalse);
    expect(share.scopes.single, CatalogPdfScope.complete);
    expect(share.origin, anchor);
    expect(vm.selected.map((p) => p.id), ['first']);
    expect(catalog.snapshot, same(original));
  });

  test(
    'selecting every visible product still exports personalized scope',
    () async {
      for (final product in catalog.snapshot.products) {
        vm.toggle(product.id);
      }
      expect(await vm.shareSelected(), isTrue);
      expect(share.calls.single.map((p) => p.id), ['sold', 'first', 'later']);
      expect(share.scopes.single, CatalogPdfScope.personalized);
      expect(vm.selected, hasLength(3));
    },
  );

  test('complete empty or hidden-only catalog never invokes sharing', () async {
    catalog.update([]);
    expect(await vm.shareAll(), isFalse);
    expect(share.calls, isEmpty);
    expect(vm.error, isNotNull);
    catalog.update([_product('hidden', 0).copyWith(visible: false)]);
    expect(await vm.shareAll(), isFalse);
    expect(share.calls, isEmpty);
  });

  for (final fullFirst in [true, false]) {
    test(
      'shared command lock blocks the other scope (full first: $fullFirst)',
      () async {
        vm.toggle('first');
        share.pending = Completer<void>();
        final pending = fullFirst ? vm.shareAll() : vm.shareSelected();
        expect(vm.busy, isTrue);
        expect(await (fullFirst ? vm.shareSelected() : vm.shareAll()), isFalse);
        expect(share.calls, hasLength(1));
        expect(
          share.scopes.single,
          fullFirst ? CatalogPdfScope.complete : CatalogPdfScope.personalized,
        );
        share.pending!.complete();
        expect(await pending, isTrue);
        expect(vm.busy, isFalse);
        expect(vm.isSelected('first'), isTrue);
      },
    );
  }

  test(
    'complete sharing failure retains selection and permits personalized retry',
    () async {
      vm.toggle('first');
      final original = catalog.snapshot;
      share.failure = StateError('Compartidor no disponible');
      expect(await vm.shareAll(), isFalse);
      expect(vm.error, 'Compartidor no disponible');
      expect(vm.isSelected('first'), isTrue);
      expect(catalog.snapshot, same(original));
      share.failure = null;
      expect(await vm.shareSelected(), isTrue);
      expect(share.scopes, [
        CatalogPdfScope.complete,
        CatalogPdfScope.personalized,
      ]);
    },
  );

  test('selected sold-out products retain catalog order across filters with no configured phone', () async {
    vm.toggle('later');
    vm.toggle('sold');
    vm.setQuery('does not match');
    vm.setCategory('other');
    expect(vm.products, isEmpty);
    const anchor = Rect.fromLTWH(10, 20, 48, 48);
    expect(await vm.shareSelected(sharePositionOrigin: anchor), isTrue);
    expect(share.calls.single.map((p) => p.id), ['sold', 'later']);
    expect(share.calls.single.first.available, isFalse);
    expect(share.origin, anchor);
    expect(vm.selected.map((p) => p.id), ['sold', 'later']);
    expect(catalog.snapshot.settings.whatsapp, isEmpty);
  });

  test('repository changes remove hidden and deleted selection, using current product values', () async {
    for (final id in ['sold', 'first', 'later']) {
      vm.toggle(id);
    }
    catalog.update([
      _product('sold', 2).copyWith(visible: false),
      _product('first', 0, available: false),
    ]);
    expect(await vm.shareSelected(), isTrue);
    expect(share.calls.single.map((p) => p.id), ['first']);
    expect(share.calls.single.single.available, isFalse);
    expect(vm.isSelected('sold'), isFalse);
    expect(vm.isSelected('later'), isFalse);
  });

  test('sharing failure retains selection and allows retry without touching catalog', () async {
    final original = catalog.snapshot;
    vm.toggle('first');
    share.failure = StateError('Compartidor no disponible');
    expect(await vm.shareSelected(), isFalse);
    expect(vm.error, 'Compartidor no disponible');
    expect(vm.isSelected('first'), isTrue);
    expect(catalog.snapshot, same(original));
    share.failure = null;
    expect(await vm.shareSelected(), isTrue);
    expect(vm.error, isNull);
    expect(vm.isSelected('first'), isTrue);
  });

  test(
    'duplicate command is blocked while external sharing is pending',
    () async {
      vm.toggle('first');
      share.pending = Completer<void>();
      final first = vm.shareSelected();
      expect(vm.busy, isTrue);
      expect(await vm.shareSelected(), isFalse);
      expect(share.calls, hasLength(1));
      share.pending!.complete();
      expect(await first, isTrue);
      expect(vm.busy, isFalse);
      expect(vm.isSelected('first'), isTrue);
    },
  );
}
