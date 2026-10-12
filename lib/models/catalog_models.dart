import 'dart:math';

String newId() => List.generate(
  16,
  (_) => Random.secure().nextInt(256),
).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class Category {
  const Category({required this.id, required this.name, this.sortOrder = 0});
  final String id;
  final String name;
  final int sortOrder;
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
  };
  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    name: j['name'] as String,
    sortOrder: j['sortOrder'] as int,
  );
}

class ProductImage {
  const ProductImage({
    required this.id,
    required this.path,
    this.sortOrder = 0,
  });
  final String id;
  final String path;
  final int sortOrder;
  Map<String, Object?> toJson() => {
    'id': id,
    'path': path,
    'sortOrder': sortOrder,
  };
  factory ProductImage.fromJson(Map<String, dynamic> j) => ProductImage(
    id: j['id'] as String,
    path: j['path'] as String,
    sortOrder: j['sortOrder'] as int,
  );
}

class Product {
  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.sku,
    required this.presentation,
    required this.normalClp,
    this.saleClp,
    this.available = true,
    this.visible = true,
    this.sortOrder = 0,
    List<ProductImage> images = const [],
  }) : images = List.unmodifiable(images);
  final String id, categoryId, name, description, sku, presentation;
  final int normalClp, sortOrder;
  final int? saleClp;
  final bool available, visible;
  final List<ProductImage> images;
  int get currentClp => saleClp ?? normalClp;
  Product copyWith({
    bool? visible,
    bool? available,
    int? sortOrder,
    List<ProductImage>? images,
  }) => Product(
    id: id,
    categoryId: categoryId,
    name: name,
    description: description,
    sku: sku,
    presentation: presentation,
    normalClp: normalClp,
    saleClp: saleClp,
    available: available ?? this.available,
    visible: visible ?? this.visible,
    sortOrder: sortOrder ?? this.sortOrder,
    images: images ?? this.images,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
    'description': description,
    'sku': sku,
    'presentation': presentation,
    'normalClp': normalClp,
    'saleClp': saleClp,
    'available': available,
    'visible': visible,
    'sortOrder': sortOrder,
    'images': images.map((i) => i.toJson()).toList(),
  };
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    categoryId: j['categoryId'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    sku: j['sku'] as String,
    presentation: j['presentation'] as String,
    normalClp: j['normalClp'] as int,
    saleClp: j['saleClp'] as int?,
    available: j['available'] as bool,
    visible: j['visible'] as bool,
    sortOrder: j['sortOrder'] as int,
    images: (j['images'] as List)
        .map((v) => ProductImage.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList(),
  );
}

class AppSettings {
  const AppSettings({this.whatsapp = '', this.themeMode = 'system'});
  final String whatsapp, themeMode;
  AppSettings copyWith({String? whatsapp, String? themeMode}) => AppSettings(
    whatsapp: whatsapp ?? this.whatsapp,
    themeMode: themeMode ?? this.themeMode,
  );
  Map<String, Object?> toJson() => {
    'whatsapp': whatsapp,
    'themeMode': themeMode,
  };
  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    whatsapp: j['whatsapp'] as String,
    themeMode: j['themeMode'] as String,
  );
}

class CatalogSnapshot {
  CatalogSnapshot({
    List<Category> categories = const [],
    List<Product> products = const [],
    this.settings = const AppSettings(),
  }) : categories = List.unmodifiable(categories),
       products = List.unmodifiable(products);
  final List<Category> categories;
  final List<Product> products;
  final AppSettings settings;
  Map<String, Object?> toJson() => {
    'categories': categories.map((c) => c.toJson()).toList(),
    'products': products.map((p) => p.toJson()).toList(),
    'settings': settings.toJson(),
  };
  factory CatalogSnapshot.fromJson(Map<String, dynamic> j) => CatalogSnapshot(
    categories: (j['categories'] as List)
        .map((v) => Category.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList(),
    products: (j['products'] as List)
        .map((v) => Product.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList(),
    settings: AppSettings.fromJson(
      Map<String, dynamic>.from(j['settings'] as Map),
    ),
  );
}
