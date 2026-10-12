import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../contracts.dart';
import 'catalog_validation.dart';

class SqlCatalogRepository extends CatalogRepository {
  SqlCatalogRepository({
    required this.databasePath,
    required this.requireAdmin,
    DatabaseFactory? factory,
    this.sessionToken,
  }) : _factory = factory ?? databaseFactory;
  final String databasePath;
  final void Function() requireAdmin;
  final Object? Function()? sessionToken;
  final DatabaseFactory _factory;
  final Lock _lock = Lock(reentrant: true);
  Database? _database;
  CatalogSnapshot _snapshot = CatalogSnapshot();
  @override
  CatalogSnapshot get snapshot => _snapshot;

  Future<Database> _open() async => _database ??= await _factory.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys=ON');
        await db.execute('PRAGMA synchronous=FULL');
      },
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE categories(id TEXT PRIMARY KEY, name TEXT NOT NULL, name_key TEXT NOT NULL UNIQUE, sort_order INTEGER NOT NULL CHECK(sort_order>=0))',
        );
        await db.execute(
          'CREATE TABLE products(id TEXT PRIMARY KEY, category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT, name TEXT NOT NULL, description TEXT NOT NULL, sku TEXT NOT NULL, sku_key TEXT NOT NULL UNIQUE, presentation TEXT NOT NULL, search_key TEXT NOT NULL, normal_clp INTEGER NOT NULL CHECK(normal_clp>=0), sale_clp INTEGER CHECK(sale_clp>=0 AND sale_clp<normal_clp), available INTEGER NOT NULL CHECK(available IN(0,1)), visible INTEGER NOT NULL CHECK(visible IN(0,1)), sort_order INTEGER NOT NULL CHECK(sort_order>=0))',
        );
        await db.execute(
          'CREATE TABLE product_images(id TEXT PRIMARY KEY, product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE, relative_path TEXT NOT NULL UNIQUE, sort_order INTEGER NOT NULL CHECK(sort_order>=0), UNIQUE(product_id,sort_order))',
        );
        await db.execute(
          "CREATE TABLE settings(singleton INTEGER PRIMARY KEY CHECK(singleton=1), whatsapp TEXT NOT NULL, theme_mode TEXT NOT NULL CHECK(theme_mode IN('system','light','dark')))",
        );
        await db.execute("INSERT INTO settings VALUES(1,'','system')");
        await db.execute(
          'CREATE INDEX product_category_order ON products(category_id,visible,sort_order)',
        );
        await _initializeSkuSequence(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1 && newVersion == 2) {
          await _initializeSkuSequence(db);
        } else {
          throw StateError('No existe migración para esta versión');
        }
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        throw StateError('Base de datos de una versión más reciente');
      },
    ),
  );

  Future<void> _initializeSkuSequence(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE sku_sequence(singleton INTEGER PRIMARY KEY CHECK(singleton=1), high_water TEXT NOT NULL)',
    );
    await db.insert('sku_sequence', {'singleton': 1, 'high_water': '0'});
    await _reconcileSkuSequence(db);
  }

  Future<BigInt> _reconcileSkuSequence(DatabaseExecutor db) async {
    var maximum = BigInt.parse(
      (await db.query('sku_sequence')).single['high_water'] as String,
    );
    for (final row in await db.query('products', columns: ['sku'])) {
      final sku = row['sku'] as String;
      if (RegExp(r'^\d+$').hasMatch(sku)) {
        final number = BigInt.parse(sku);
        if (number > maximum) maximum = number;
      }
    }
    await db.update('sku_sequence', {
      'high_water': maximum.toString(),
    }, where: 'singleton=1');
    return maximum;
  }

  Future<BigInt> _nextSku(DatabaseExecutor db) async {
    final high = BigInt.parse(
      (await db.query('sku_sequence')).single['high_water'] as String,
    );
    return high + BigInt.one;
  }

  @override
  Future<String> nextSkuPreview() async {
    requireAdmin();
    return exclusive(() async {
      requireAdmin();
      return '${await _nextSku(await _open())}';
    });
  }

  @override
  Future<T> exclusive<T>(Future<T> Function() action) =>
      _lock.synchronized(action);

  @override
  Future<void> load() => exclusive(() async {
    _snapshot = await _read(await _open());
    notifyListeners();
  });

  Future<CatalogSnapshot> _read(DatabaseExecutor db) async {
    final categories = (await db.query('categories', orderBy: 'sort_order,id'))
        .map(
          (r) => Category(
            id: r['id'] as String,
            name: r['name'] as String,
            sortOrder: r['sort_order'] as int,
          ),
        )
        .toList();
    final imageRows = await db.query(
      'product_images',
      orderBy: 'sort_order,id',
    );
    final products = (await db.query('products', orderBy: 'sort_order,id'))
        .map(
          (r) => Product(
            id: r['id'] as String,
            categoryId: r['category_id'] as String,
            name: r['name'] as String,
            description: r['description'] as String,
            sku: r['sku'] as String,
            presentation: r['presentation'] as String,
            normalClp: r['normal_clp'] as int,
            saleClp: r['sale_clp'] as int?,
            available: r['available'] == 1,
            visible: r['visible'] == 1,
            sortOrder: r['sort_order'] as int,
            images: imageRows
                .where((i) => i['product_id'] == r['id'])
                .map(
                  (i) => ProductImage(
                    id: i['id'] as String,
                    path: i['relative_path'] as String,
                    sortOrder: i['sort_order'] as int,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    final settings = (await db.query('settings')).single;
    return CatalogSnapshot(
      categories: categories,
      products: products,
      settings: AppSettings(
        whatsapp: settings['whatsapp'] as String,
        themeMode: settings['theme_mode'] as String,
      ),
    );
  }

  Future<void> _mutate(Future<void> Function(Transaction tx) action) async {
    requireAdmin();
    final token = sessionToken?.call();
    void guard() {
      requireAdmin();
      if (sessionToken != null && sessionToken!() != token) {
        throw StateError(
          'La sesión cambió. Repite la operación después de autenticarte',
        );
      }
    }

    await exclusive(() async {
      guard();
      final db = await _open();
      await db.transaction((tx) async {
        guard();
        await action(tx);
        guard();
      });
      _snapshot = await _read(db);
      notifyListeners();
    });
  }

  Map<String, Object?> _categoryRow(Category c) => {
    'id': c.id,
    'name': c.name.trim(),
    'name_key': normalizedText(c.name),
    'sort_order': c.sortOrder,
  };
  Future<void> _insertProduct(DatabaseExecutor tx, Product p) async {
    await tx.insert('products', {
      'id': p.id,
      'category_id': p.categoryId,
      'name': p.name.trim(),
      'description': p.description.trim(),
      'sku': p.sku.trim(),
      'sku_key': skuKey(p.sku),
      'presentation': p.presentation.trim(),
      'search_key': normalizedText('${p.name} ${p.description} ${p.sku}'),
      'normal_clp': p.normalClp,
      'sale_clp': p.saleClp,
      'available': p.available ? 1 : 0,
      'visible': p.visible ? 1 : 0,
      'sort_order': p.sortOrder,
    });
    for (final image in p.images) {
      await tx.insert('product_images', {
        'id': image.id,
        'product_id': p.id,
        'relative_path': image.path,
        'sort_order': image.sortOrder,
      });
    }
  }

  @override
  Future<void> saveCategory(Category category) => _mutate((tx) async {
    validateCategory(category);
    final exists = await tx.query(
      'categories',
      where: 'id=?',
      whereArgs: [category.id],
    );
    if (exists.isEmpty) {
      await tx.insert('categories', _categoryRow(category));
    } else {
      await tx.update(
        'categories',
        _categoryRow(category),
        where: 'id=?',
        whereArgs: [category.id],
      );
    }
  });
  @override
  Future<void> deleteCategory(String id) => _mutate((tx) async {
    await tx.delete('categories', where: 'id=?', whereArgs: [id]);
  });
  @override
  Future<void> saveProduct(Product product) => _mutate((tx) async {
    final categories = await tx.query('categories', columns: ['id']);
    validateProduct(product, categories.map((c) => c['id'] as String).toSet());
    await tx.delete('products', where: 'id=?', whereArgs: [product.id]);
    await _insertProduct(tx, product);
    await _reconcileSkuSequence(tx);
  });
  @override
  Future<Product> createProductWithAutoSku(Product draft) async {
    late Product product;
    await _mutate((tx) async {
      if ((await tx.query(
        'products',
        where: 'id=?',
        whereArgs: [draft.id],
      )).isNotEmpty) {
        throw StateError('El producto ya existe.');
      }
      final sku = '${await _nextSku(tx)}';
      product = Product(
        id: draft.id,
        categoryId: draft.categoryId,
        name: draft.name,
        description: draft.description,
        sku: sku,
        presentation: draft.presentation,
        normalClp: draft.normalClp,
        saleClp: draft.saleClp,
        available: draft.available,
        visible: draft.visible,
        sortOrder: draft.sortOrder,
        images: draft.images,
      );
      final categories = await tx.query('categories', columns: ['id']);
      validateProduct(
        product,
        categories.map((c) => c['id'] as String).toSet(),
      );
      await _insertProduct(tx, product);
      await tx.update('sku_sequence', {
        'high_water': sku,
      }, where: 'singleton=1');
    });
    return product;
  }

  @override
  Future<void> deleteProduct(String id) => _mutate((tx) async {
    await tx.delete('products', where: 'id=?', whereArgs: [id]);
  });
  Future<void> _reorder(String table, List<String> ids) => _mutate((tx) async {
    final existing = (await tx.query(
      table,
      columns: ['id'],
    )).map((r) => r['id'] as String).toSet();
    if (ids.length != existing.length ||
        ids.toSet().length != ids.length ||
        !existing.containsAll(ids)) {
      throw const FormatException('Orden incompleto');
    }
    for (var i = 0; i < ids.length; i++) {
      await tx.update(
        table,
        {'sort_order': i},
        where: 'id=?',
        whereArgs: [ids[i]],
      );
    }
  });
  @override
  Future<void> reorderCategories(List<String> ids) =>
      _reorder('categories', ids);
  @override
  Future<void> reorderProducts(List<String> ids) => _reorder('products', ids);
  @override
  Future<void> saveSettings(AppSettings settings) => _mutate((tx) async {
    validateSettings(settings);
    await tx.update('settings', {
      'whatsapp': settings.whatsapp,
      'theme_mode': settings.themeMode,
    }, where: 'singleton=1');
  });
  @override
  Future<void> replaceCatalog(CatalogSnapshot snapshot) => _mutate((tx) async {
    validateSnapshot(snapshot);
    await tx.delete('product_images');
    await tx.delete('products');
    await tx.delete('categories');
    for (final category in snapshot.categories) {
      await tx.insert('categories', _categoryRow(category));
    }
    for (final product in snapshot.products) {
      await _insertProduct(tx, product);
    }
    await _reconcileSkuSequence(tx);
    await tx.update('settings', {
      'whatsapp': snapshot.settings.whatsapp,
      'theme_mode': snapshot.settings.themeMode,
    }, where: 'singleton=1');
  });
  @override
  Future<void> close() => exclusive(() async {
    await _database?.close();
    _database = null;
  });
}
