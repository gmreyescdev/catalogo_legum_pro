import 'dart:io';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/sql_catalog_repository.dart';
import 'package:catalogo_legum_pro/data/catalog_validation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;
  late SqlCatalogRepository repository;
  var authenticated = true;
  var calls = 0;
  int? revokeOnCall;
  int? rotateOnCall;
  var epoch = 0;
  Product product({
    String id = 'p',
    String sku = 'SKU',
    String category = 'c',
    int normal = 100,
    int? sale,
    List<ProductImage>? images,
  }) => Product(
    id: id,
    categoryId: category,
    name: 'Nombre',
    description: 'Descripción completa',
    sku: sku,
    presentation: '1 kg',
    normalClp: normal,
    saleClp: sale,
    images: images ?? [ProductImage(id: 'image$id', path: 'media/gen/$id.png')],
  );
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('legum_sql_test_');
    authenticated = true;
    calls = 0;
    revokeOnCall = null;
    rotateOnCall = null;
    epoch = 0;
    repository = SqlCatalogRepository(
      databasePath: p.join(dir.path, 'catalog.sqlite'),
      factory: databaseFactoryFfi,
      sessionToken: () => epoch,
      requireAdmin: () {
        calls++;
        if (calls == rotateOnCall) {
          epoch++;
        }
        if (!authenticated || calls == revokeOnCall) {
          throw StateError('Sin sesión');
        }
      },
    );
    await repository.load();
  });
  tearDown(() async {
    await repository.close();
    await dir.delete(recursive: true);
  });

  test('clean database has no seeds, creates FK-enabled version two', () async {
    expect(repository.snapshot.products, isEmpty);
    expect(repository.snapshot.categories, isEmpty);
    final db = await databaseFactoryFfi.openDatabase(
      p.join(dir.path, 'catalog.sqlite'),
    );
    expect(await db.getVersion(), 2);
    expect((await db.rawQuery('PRAGMA foreign_keys')).single.values.single, 1);
  });
  test(
    'search/category normalization removes composed and combining accents',
    () {
      expect(normalizedText('LÉGUMBRES'), normalizedText('Le\u0301gumbres'));
      expect(normalizedText(' ÁRBOL '), 'arbol');
    },
  );
  test(
    'category uniqueness ignores case/accents and used deletion is restricted',
    () async {
      await repository.saveCategory(const Category(id: 'c', name: 'Légumbres'));
      await expectLater(
        repository.saveCategory(const Category(id: 'other', name: 'LEGUMBRES')),
        throwsA(anything),
      );
      await repository.saveProduct(product());
      await expectLater(repository.deleteCategory('c'), throwsA(anything));
      expect(repository.snapshot.categories.single.id, 'c');
      expect(repository.snapshot.products.single.categoryId, 'c');
    },
  );
  test('product editing, prices and order persist after reopening', () async {
    await repository.saveCategory(const Category(id: 'c', name: 'Legumbres'));
    await repository.saveProduct(product());
    await repository.saveProduct(
      product(id: 'second', sku: 'B', normal: 200, sale: 0),
    );
    await repository.reorderProducts(['second', 'p']);
    await repository.saveProduct(
      repository.snapshot.products.last.copyWith(
        visible: false,
        available: false,
      ),
    );
    await repository.close();
    await repository.load();
    expect(repository.snapshot.products.first.id, 'second');
    expect(repository.snapshot.products.first.currentClp, 0);
    expect(repository.snapshot.products.last.visible, isFalse);
    expect(repository.snapshot.products.last.available, isFalse);
  });
  test('duplicate SKU rollback preserves previous product and image', () async {
    await repository.saveCategory(const Category(id: 'c', name: 'Legumbres'));
    await repository.saveProduct(product());
    await repository.saveProduct(product(id: 'second', sku: 'second'));
    await expectLater(
      repository.saveProduct(product(id: 'second', sku: 'sKu')),
      throwsA(anything),
    );
    await repository.load();
    expect(
      repository.snapshot.products.map((p) => p.sku),
      containsAll(['SKU', 'second']),
    );
    expect(
      repository.snapshot.products.last.images.single.path,
      'media/gen/second.png',
    );
  });
  test(
    'shared validation rejects missing image, relation and invalid offers',
    () async {
      await repository.saveCategory(const Category(id: 'c', name: 'Legumbres'));
      for (final invalid in [
        product(images: []),
        product(category: 'missing'),
        product(normal: -1),
        product(normal: 100, sale: 100),
        product(normal: 0, sale: 0),
      ]) {
        await expectLater(
          repository.saveProduct(invalid),
          throwsFormatException,
        );
      }
      expect(repository.snapshot.products, isEmpty);
    },
  );
  test('authorization is checked at commit and rolls back writes', () async {
    revokeOnCall = calls + 4;
    await expectLater(
      repository.saveCategory(const Category(id: 'c', name: 'Revertida')),
      throwsStateError,
    );
    await repository.load();
    expect(repository.snapshot.categories, isEmpty);
    authenticated = false;
    await expectLater(
      repository.saveSettings(const AppSettings(themeMode: 'dark')),
      throwsStateError,
    );
  });
  test(
    'lock then reauthentication cannot authorize an old in-flight commit',
    () async {
      rotateOnCall = calls + 4;
      await expectLater(
        repository.saveCategory(
          const Category(id: 'c', name: 'Antigua sesión'),
        ),
        throwsStateError,
      );
      await repository.load();
      expect(repository.snapshot.categories, isEmpty);
      rotateOnCall = null;
      await repository.saveCategory(
        const Category(id: 'c', name: 'Sesión vigente'),
      );
      expect(repository.snapshot.categories.single.name, 'Sesión vigente');
    },
  );
  test('replace is atomic, rejects invalid snapshot and replaces instead of merging', () async {
    await repository.saveCategory(const Category(id: 'old', name: 'Anterior'));
    await expectLater(
      repository.replaceCatalog(
        CatalogSnapshot(
          categories: [const Category(id: 'c', name: 'Nueva')],
          products: [product(category: 'missing')],
        ),
      ),
      throwsFormatException,
    );
    expect(repository.snapshot.categories.single.id, 'old');
    await repository.replaceCatalog(
      CatalogSnapshot(
        categories: [const Category(id: 'c', name: 'Nueva')],
        products: [product()],
        settings: const AppSettings(themeMode: 'dark'),
      ),
    );
    expect(repository.snapshot.categories.map((c) => c.id), ['c']);
    expect(repository.snapshot.products.single.id, 'p');
    expect(repository.snapshot.settings.themeMode, 'dark');
  });
  test(
    'reentrant exclusivity permits snapshot and replacement under backup lock',
    () async {
      await repository.exclusive(() async {
        await repository.load();
        await repository.saveCategory(const Category(id: 'c', name: 'Una'));
      });
      expect(repository.snapshot.categories.single.name, 'Una');
      await expectLater(
        repository.reorderCategories(['unknown']),
        throwsFormatException,
      );
      expect(repository.snapshot.categories.single.id, 'c');
    },
  );
  test('preview does not reserve and atomic creates reconcile a concurrent preview', () async {
    await repository.saveCategory(const Category(id: 'c', name: 'Legumbres'));
    expect(await repository.nextSkuPreview(), '1');
    expect(await repository.nextSkuPreview(), '1');
    final created = await Future.wait([
      repository.createProductWithAutoSku(product(id: 'one', sku: '1')),
      repository.createProductWithAutoSku(product(id: 'two', sku: '1')),
    ]);
    expect(created.map((p) => p.sku).toSet(), {'1', '2'});
    expect(await repository.nextSkuPreview(), '3');
    await repository.deleteProduct(created.last.id);
    await repository.close();
    await repository.load();
    expect(await repository.nextSkuPreview(), '3');
  });
  test('failed creation consumes no correlativo and restored records never reduce high water', () async {
    await repository.saveCategory(const Category(id: 'c', name: 'Legumbres'));
    await expectLater(
      repository.createProductWithAutoSku(product(images: [])),
      throwsFormatException,
    );
    expect(await repository.nextSkuPreview(), '1');
    await repository.saveProduct(product(sku: '00020'));
    expect(await repository.nextSkuPreview(), '21');
    await repository.replaceCatalog(CatalogSnapshot());
    expect(await repository.nextSkuPreview(), '21');
    await repository.replaceCatalog(
      CatalogSnapshot(
        categories: [const Category(id: 'c', name: 'Legumbres')],
        products: [product(sku: '30')],
      ),
    );
    expect(await repository.nextSkuPreview(), '31');
    expect(repository.snapshot.products.single.sku, '30');
  });
  test(
    'version one migrates without changing arbitrary legacy SKU or catalog',
    () async {
      await repository.saveCategory(const Category(id: 'c', name: 'Legumbres'));
      await repository.saveProduct(product(sku: '0007'));
      await repository.saveProduct(
        product(id: 'legacy', sku: '99999999999999999999999999999'),
      );
      await repository.close();
      final legacy = await databaseFactoryFfi.openDatabase(
        p.join(dir.path, 'catalog.sqlite'),
      );
      await legacy.execute('DROP TABLE sku_sequence');
      await legacy.setVersion(1);
      await legacy.close();
      await repository.load();
      expect(
        repository.snapshot.products.map((p) => p.sku),
        containsAll(['0007', '99999999999999999999999999999']),
      );
      expect(
        await repository.nextSkuPreview(),
        '100000000000000000000000000000',
      );
      expect(repository.snapshot.categories.single.name, 'Legumbres');
    },
  );
}
