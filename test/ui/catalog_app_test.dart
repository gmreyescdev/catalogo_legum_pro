import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/features/catalog_app.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:catalogo_legum_pro/features/public_views.dart';
import 'package:catalogo_legum_pro/features/admin_views.dart';
import 'package:catalogo_legum_pro/ui/theme.dart';

class MemoryCatalog extends CatalogRepository {
  MemoryCatalog([CatalogSnapshot? value])
    : _snapshot = value ?? CatalogSnapshot();
  CatalogSnapshot _snapshot;
  @override
  CatalogSnapshot get snapshot => _snapshot;
  void update(CatalogSnapshot value) {
    _snapshot = value;
    notifyListeners();
  }

  @override
  Future<void> load() async {}
  @override
  Future<void> close() async {}
  @override
  Future<T> exclusive<T>(Future<T> Function() action) => action();
  @override
  Future<void> saveCategory(Category c) async => update(
    CatalogSnapshot(
      categories: [...snapshot.categories.where((v) => v.id != c.id), c],
      products: snapshot.products,
      settings: snapshot.settings,
    ),
  );
  @override
  Future<void> deleteCategory(String id) async => update(
    CatalogSnapshot(
      categories: snapshot.categories.where((c) => c.id != id).toList(),
      products: snapshot.products,
      settings: snapshot.settings,
    ),
  );
  @override
  Future<void> saveProduct(Product p) async => update(
    CatalogSnapshot(
      categories: snapshot.categories,
      products: [...snapshot.products.where((v) => v.id != p.id), p],
      settings: snapshot.settings,
    ),
  );
  @override
  Future<void> deleteProduct(String id) async => update(
    CatalogSnapshot(
      categories: snapshot.categories,
      products: snapshot.products.where((p) => p.id != id).toList(),
      settings: snapshot.settings,
    ),
  );
  @override
  Future<void> reorderProducts(List<String> ids) async => update(
    CatalogSnapshot(
      categories: snapshot.categories,
      products: [
        for (final p in snapshot.products)
          p.copyWith(sortOrder: ids.indexOf(p.id)),
      ],
      settings: snapshot.settings,
    ),
  );
  @override
  Future<void> reorderCategories(List<String> ids) async => update(
    CatalogSnapshot(
      categories: [
        for (final c in snapshot.categories)
          Category(id: c.id, name: c.name, sortOrder: ids.indexOf(c.id)),
      ],
      products: snapshot.products,
      settings: snapshot.settings,
    ),
  );
  @override
  Future<void> saveSettings(AppSettings settings) async => update(
    CatalogSnapshot(
      categories: snapshot.categories,
      products: snapshot.products,
      settings: settings,
    ),
  );
  @override
  Future<void> replaceCatalog(CatalogSnapshot snapshot) async =>
      update(snapshot);
}

class MemoryAuth extends AdminAuth {
  bool unlocked = false, configured = true;
  @override
  bool get isAuthenticated => unlocked;
  @override
  bool get isConfigured => configured;
  @override
  Duration get remainingLockout => Duration.zero;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> unlock(String pin) async {
    unlocked = pin == '1947';
    notifyListeners();
    return unlocked;
  }

  @override
  void requireAdmin() {
    if (!unlocked) throw StateError('Sesión cerrada.');
  }

  @override
  void lock() {
    unlocked = false;
    notifyListeners();
  }

  @override
  Future<String> beginSetup() async {
    requireAdmin();
    return 'TEST-RECOVERY-CODE';
  }

  @override
  Future<void> confirmSetup() async {
    requireAdmin();
    configured = true;
    notifyListeners();
  }

  @override
  void cancelSetup() {}
  @override
  Future<String> prepareRecovery(String code, String newPin) async =>
      'TEST-NEW-CODE';
  @override
  Future<void> confirmRecovery() async {
    lock();
  }

  @override
  void cancelRecovery() {}
  @override
  Future<void> changePin(String currentPin, String newPin) async {
    requireAdmin();
  }
}

class MemoryMedia implements MediaManager {
  List<String> picked = ['media/test/new.png'];
  final discarded = <String>{};
  Set<String> referenced = {};
  VoidCallback? afterPick;
  @override
  String absolutePath(String path) => path;
  @override
  ImageProvider imageProvider(String path) => MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=',
    ),
  );
  @override
  Future<List<String>> pickGallery() async {
    afterPick?.call();
    return picked;
  }

  @override
  Future<List<String>> takePhoto() => pickGallery();
  @override
  Future<List<String>> retrieveLost() async => [];
  @override
  Future<void> discardPaths(Iterable<String> paths) async {
    discarded.addAll(paths);
  }

  @override
  Future<void> collectGarbage(Set<String> paths) async {
    referenced = paths;
  }
}

class MemoryBackup implements BackupManager {
  @override
  Future<String> exportBackup({bool share = true}) async => 'backup.zip';
  @override
  Future<BackupPreview?> selectBackup() async => null;
  @override
  Future<void> restoreBackup(BackupPreview preview) async {}
  @override
  Future<void> discardPreview(BackupPreview preview) async {}
}

class MemoryWhatsApp implements WhatsAppGateway {
  List<Product> last = [];
  CatalogPdfScope? lastScope;
  bool fail = false;
  Rect? origin;
  Completer<void>? pending;
  @override
  Future<void> shareCatalog(
    List<Product> products, {
    CatalogPdfScope scope = CatalogPdfScope.personalized,
    Rect? sharePositionOrigin,
  }) async {
    lastScope = scope;
    origin = sharePositionOrigin;
    last = products;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('No se pudo compartir el PDF.');
  }
}

AppServices services({
  MemoryCatalog? catalog,
  MemoryAuth? auth,
  MemoryMedia? media,
  MemoryWhatsApp? whatsapp,
}) => AppServices(
  catalog: catalog ?? MemoryCatalog(),
  auth: auth ?? MemoryAuth(),
  media: media ?? MemoryMedia(),
  backup: MemoryBackup(),
  whatsapp: whatsapp ?? MemoryWhatsApp(),
);
Product sample({
  String id = 'p',
  String name = 'Té orgánico',
  bool visible = true,
  bool available = true,
}) => Product(
  id: id,
  categoryId: 'c',
  name: name,
  description: 'Descripción íntegra del producto.',
  sku: 'SKU-$id',
  presentation: 'Bolsa 500 g',
  normalClp: 12000,
  saleClp: 10000,
  visible: visible,
  available: available,
  images: const [ProductImage(id: 'photo', path: 'media/test/original.png')],
);
CatalogSnapshot data(List<Product> products) => CatalogSnapshot(
  categories: const [Category(id: 'c', name: 'Infusiones')],
  products: products,
  settings: const AppSettings(whatsapp: '+56912345678'),
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('logo accesible a 320 y escala 2 en $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = CatalogViewModel(services());
      await tester.pumpWidget(
        MaterialApp(
          theme: catalogTheme(brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: CatalogView(vm: vm, onAdmin: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final logo = find.bySemanticsLabel('Logo LegumPro');
      expect(logo, findsOneWidget);
      expect(tester.getSize(logo), const Size(40, 40));
      expect(
        tester.getSemantics(logo),
        matchesSemantics(label: 'Logo LegumPro', isImage: true),
      );
      final clip = find.ancestor(of: logo, matching: find.byType(ClipOval));
      expect(clip, findsOneWidget);
      final title = find.text('Catálogo LegumPro');
      expect(title, findsOneWidget);
      final logoRect = tester.getRect(logo);
      final titleRect = tester.getRect(title);
      expect(titleRect.left - logoRect.right, closeTo(12, .01));
      expect(titleRect.center.dy, closeTo(logoRect.center.dy, .01));
      expect(titleRect.right, lessThanOrEqualTo(304));
      final brandImage = tester.widget<Image>(
        find.descendant(of: clip, matching: find.byType(Image)),
      );
      expect(
        (brandImage.image as AssetImage).assetName,
        'assets/branding/legumpro-icon.png',
      );
      expect(brandImage.fit, BoxFit.contain);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/branding/legumpro-logo.jpg',
        ),
        findsNothing,
      );
      final admin = find.widgetWithText(TextButton, 'Administrar');
      expect(admin.hitTestable(), findsOneWidget);
      expect(tester.getSize(admin).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(SearchBar),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(SearchBar).hitTestable(), findsOneWidget);
      expect(
        tester.getSize(find.byType(SearchBar)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(SearchBar),
          matching: find.byType(TextField),
        ),
        'Lentejas',
      );
      await tester.pumpAndSettle();
      expect(vm.query, 'Lentejas');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    });
  }
  testWidgets('catálogo completo vacío deshabilitado aunque haya ocultos', (
    tester,
  ) async {
    final gateway = MemoryWhatsApp();
    final vm = CatalogViewModel(
      services(
        catalog: MemoryCatalog(data([sample(visible: false)])),
        whatsapp: gateway,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: catalogTheme(Brightness.light),
        home: CatalogView(vm: vm, onAdmin: () {}),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Compartir catálogo completo'),
    );
    expect(button.onPressed, isNull);
    expect(gateway.last, isEmpty);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
  testWidgets(
    'catálogo completo ignora filtros y muestra progreso/error sin perder selección',
    (tester) async {
      final gateway = MemoryWhatsApp()
        ..pending = Completer<void>()
        ..fail = true;
      final vm =
          CatalogViewModel(
              services(
                catalog: MemoryCatalog(
                  data([
                    sample(),
                    sample(id: 'sold', available: false),
                    sample(id: 'hidden', visible: false),
                  ]),
                ),
                whatsapp: gateway,
              ),
            )
            ..toggle('p')
            ..setQuery('sin coincidencias');
      await tester.pumpWidget(
        MaterialApp(
          theme: catalogTheme(Brightness.light),
          home: CatalogView(vm: vm, onAdmin: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('No se encontraron productos'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No se encontraron productos'), findsOneWidget);
      final action = find.widgetWithText(
        FilledButton,
        'Compartir catálogo completo',
      );
      await tester.scrollUntilVisible(
        action,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(action);
      await tester.pump();
      expect(gateway.last.map((p) => p.id), ['p', 'sold']);
      expect(gateway.lastScope, CatalogPdfScope.complete);
      expect(gateway.origin, isNotNull);
      expect(gateway.origin!.width, greaterThan(0));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      gateway.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('No se pudo compartir el PDF.'), findsOneWidget);
      expect(vm.selected.single.id, 'p');
      expect(vm.query, 'sin coincidencias');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets('selección vacía deshabilita compartir PDF', (tester) async {
    final gateway = MemoryWhatsApp();
    final vm = CatalogViewModel(services(whatsapp: gateway));
    await tester.pumpWidget(
      MaterialApp(
        theme: catalogTheme(Brightness.light),
        home: SelectionView(vm: vm),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay productos seleccionados.'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(gateway.last, isEmpty);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
  testWidgets(
    'PDF muestra progreso, ancla y error sin perder selección a escala 2',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = MemoryWhatsApp()
        ..pending = Completer<void>()
        ..fail = true;
      final repo = MemoryCatalog(
        CatalogSnapshot(
          categories: const [Category(id: 'c', name: 'Infusiones')],
          products: [sample(available: false)],
        ),
      );
      final vm = CatalogViewModel(services(catalog: repo, whatsapp: gateway))
        ..toggle('p');
      await tester.pumpWidget(
        MaterialApp(
          theme: catalogTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: SelectionView(vm: vm),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Compartir selección'), 300);
      await tester.tap(find.text('Compartir selección'));
      await tester.pump();
      expect(vm.busy, isTrue);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(gateway.origin, isNotNull);
      expect(gateway.origin!.width, greaterThan(0));
      expect(gateway.last.single.available, isFalse);
      expect(gateway.lastScope, CatalogPdfScope.personalized);
      // The progress section pushes the action below this compact viewport.
      // Materialize it again before inspecting the disabled button.
      await tester.scrollUntilVisible(find.byType(FilledButton), 100);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      gateway.pending!.complete();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('No se pudo compartir el PDF.'),
        -100,
      );
      expect(find.text('No se pudo compartir el PDF.'), findsOneWidget);
      expect(vm.selected.single.id, 'p');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  test('búsqueda normalizada combina categoría y omite ocultos; selección lee precio vigente', () async {
    final repo = MemoryCatalog(
      data([
        sample(),
        sample(id: 'hidden', visible: false),
        sample(id: 'sold', available: false),
      ]),
    );
    final gateway = MemoryWhatsApp();
    final vm = CatalogViewModel(services(catalog: repo, whatsapp: gateway));
    vm.setQuery('TE ORGANICO');
    vm.setCategory('c');
    expect(vm.products.length, 2);
    vm.toggle('p');
    final updated = Product(
      id: 'p',
      categoryId: 'c',
      name: 'Té actualizado',
      description: 'Otra',
      sku: 'SKU-p',
      presentation: 'Caja',
      normalClp: 1500,
      available: false,
      images: sample().images,
    );
    await repo.saveProduct(updated);
    expect(await vm.shareSelected(), isTrue);
    expect(gateway.last.single.currentClp, 1500);
    expect(gateway.last.single.available, isFalse);
    gateway.fail = true;
    expect(await vm.shareSelected(), isFalse);
    expect(vm.selected.length, 1);
    await repo.saveProduct(updated.copyWith(visible: false));
    expect(vm.selected, isEmpty);
    vm.dispose();
  });
  test('sesión revocada tras selector conserva borrador y prohíbe guardar hasta PIN', () async {
    final auth = MemoryAuth()..unlocked = true;
    final media = MemoryMedia()..afterPick = auth.lock;
    final repo = MemoryCatalog(data([]));
    final vm = ProductEditorViewModel(
      services(catalog: repo, auth: auth, media: media),
      null,
    );
    vm.name = 'Lentejas';
    vm.description = 'Descripción';
    vm.sku = 'L-1';
    vm.presentation = 'Bolsa';
    vm.normalPrice = '3000';
    vm.categoryId = 'c';
    expect(await vm.addImages(), isTrue);
    expect(auth.isAuthenticated, isFalse);
    expect(vm.images.length, 1);
    expect(await vm.save(), isFalse);
    expect(repo.snapshot.products, isEmpty);
    await auth.unlock('1947');
    expect(await vm.save(), isTrue);
    expect(
      repo.snapshot.products.single.images.single.path,
      'media/test/new.png',
    );
    vm.dispose();
  });
  test('cancelar borrador elimina solo fotos nuevas y cambio de estado exige sesión', () async {
    final auth = MemoryAuth()..unlocked = true;
    final media = MemoryMedia();
    final repo = MemoryCatalog(data([sample()]));
    final s = services(catalog: repo, auth: auth, media: media);
    final vm = ProductEditorViewModel(s, sample());
    await vm.addImages();
    vm.removeImage(0);
    expect(await vm.cancel(), isTrue);
    expect(media.discarded, {'media/test/new.png'});
    expect(
      repo.snapshot.products.single.images.single.path,
      'media/test/original.png',
    );
    final admin = AdminViewModel(s);
    auth.lock();
    expect(await admin.toggleProduct(sample(), visibility: true), isFalse);
    expect(repo.snapshot.products.single.visible, isTrue);
    vm.dispose();
    admin.dispose();
  });
  test('bloqueo elimina códigos pendientes del ViewModel', () async {
    final auth = MemoryAuth()..configured = false;
    final vm = AuthViewModel(auth);
    await vm.unlock('1947');
    expect(vm.setupCode, isNotNull);
    auth.lock();
    expect(vm.setupCode, isNull);
    await vm.recover('old', '4567', '4567');
    expect(vm.recoveryCode, isNotNull);
    auth.lock();
    expect(vm.recoveryCode, isNull);
    vm.dispose();
  });
  test('contraste de tokens usados en claro y oscuro', () {
    for (final brightness in Brightness.values) {
      final c = catalogScheme(brightness);
      final pairs = [
        (c.primary, c.onPrimary),
        (c.primaryContainer, c.onPrimaryContainer),
        (c.secondary, c.onSecondary),
        (c.secondaryContainer, c.onSecondaryContainer),
        (c.tertiary, c.onTertiary),
        (c.tertiaryContainer, c.onTertiaryContainer),
        (c.surface, c.onSurface),
        (c.surface, c.onSurfaceVariant),
        (c.surfaceContainerLow, c.onSurface),
        (c.surfaceContainerHighest, c.onSurfaceVariant),
        (c.error, c.onError),
        (c.errorContainer, c.onErrorContainer),
      ];
      for (final pair in pairs) {
        final a = pair.$1.computeLuminance(), b = pair.$2.computeLuminance();
        final ratio = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$brightness $pair ratio $ratio',
        );
      }
    }
  });
  testWidgets(
    'instalación limpia es pública, sin demo ni PIN hasta Administrar',
    (tester) async {
      await tester.pumpWidget(CatalogApp(services: services()));
      await tester.pumpAndSettle();
      expect(find.text('No hay productos disponibles'), findsOneWidget);
      expect(find.text('Contenido de demostración'), findsNothing);
      expect(find.text('PIN de 4 dígitos'), findsNothing);
      await tester.tap(find.text('Administrar'));
      await tester.pumpAndSettle();
      expect(find.text('PIN de 4 dígitos'), findsOneWidget);
      expect(find.text('No hay productos disponibles'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('catálogo a 320 y escala 2 sin overflow, detalle íntegro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final p = sample(
      name: 'Producto de nombre extenso para comprobar texto ampliado',
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: CatalogApp(
          services: services(catalog: MemoryCatalog(data([p]))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ver detalle'), findsNothing);
    final imageAction = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Abrir detalle de ${p.name}',
    );
    final selection = find.widgetWithText(CheckboxListTile, 'Incluir en PDF');
    await tester.scrollUntilVisible(
      selection.hitTestable(),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(selection.hitTestable());
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(selection).value, isTrue);
    await tester.scrollUntilVisible(
      imageAction.hitTestable(),
      -300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.widget<Semantics>(imageAction).properties.button, isTrue);
    expect(tester.widget<Semantics>(imageAction).properties.onTap, isNotNull);
    await tester.tap(imageAction.hitTestable());
    await tester.pumpAndSettle();
    expect(
      tester.widget<ProductDetailView>(find.byType(ProductDetailView)).id,
      p.id,
    );
    await tester.scrollUntilVisible(
      find.text(p.description),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(p.description), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      selection.hitTestable(),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.widget<CheckboxListTile>(selection).value, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('guard oculta editor al bloquear y retoma su borrador tras PIN', (
    tester,
  ) async {
    final auth = MemoryAuth();
    await tester.pumpWidget(
      CatalogApp(
        services: services(catalog: MemoryCatalog(data([])), auth: auth),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administrar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1947');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Añadir producto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Borrador conservado',
    );
    auth.lock();
    await tester.pumpAndSettle();
    expect(find.text('PIN de 4 dígitos'), findsOneWidget);
    expect(find.text('Borrador conservado'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '1947');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Borrador conservado'), findsOneWidget);
    expect(find.text('PIN de 4 dígitos'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('compact catalog has two cards and no price metadata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = CatalogViewModel(
      services(
        catalog: MemoryCatalog(
          data([
            sample(name: 'First long product name fully visible'),
            sample(id: 'second', name: 'Second product'),
          ]),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: catalogTheme(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CatalogView(vm: vm, onAdmin: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(ProductTile).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final first = tester.getRect(find.byType(ProductTile).at(0));
    final second = tester.getRect(find.byType(ProductTile).at(1));
    expect(first.top, second.top);
    expect(first.width, closeTo(142, .01));
    expect(second.left - first.right, closeTo(12, .01));
    expect(
      find.descendant(
        of: find.byType(ProductTile),
        matching: find.text('Disponible'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ProductTile),
        matching: find.text(sample().presentation),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ProductTile),
        matching: find.textContaining('CLP'),
      ),
      findsNothing,
    );
    expect(find.text('First long product name fully visible'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets('admin compact navigation separates FAB and grouped settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = MemoryAuth()..unlocked = true;
    final appServices = services(
      catalog: MemoryCatalog(data([sample()])),
      auth: auth,
    );
    final admin = AdminViewModel(appServices);
    final authVm = AuthViewModel(auth);
    final catalog = CatalogViewModel(appServices);
    await tester.pumpWidget(
      MaterialApp(
        theme: catalogTheme(Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AdminHome(
          vm: admin,
          auth: authVm,
          catalog: catalog,
          onExit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byTooltip('Añadir producto'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    final nav = tester.getRect(find.byType(NavigationBar));
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(fab.bottom, lessThan(nav.top));
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.scrollUntilVisible(
      find.text('1 producto'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('1 producto'), findsOneWidget);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Seguridad'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Seguridad'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    admin.dispose();
    authVm.dispose();
    catalog.dispose();
  });

  testWidgets(
    'inline category retains product draft and autoselects saved category',
    (tester) async {
      final auth = MemoryAuth()..unlocked = true;
      final repo = MemoryCatalog(data([]));
      final appServices = services(catalog: repo, auth: auth);
      await tester.pumpWidget(
        MaterialApp(
          theme: catalogTheme(Brightness.light),
          home: ProductEditorView(services: appServices),
        ),
      );
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextFormField, 'Nombre');
      await tester.enterText(name, 'Retained draft');
      final sku = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'SKU',
      );
      await tester.scrollUntilVisible(
        sku,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextField>(sku).readOnly, isTrue);
      expect(tester.widget<TextField>(sku).controller!.text, '1');
      final create = find.widgetWithText(TextButton, 'Nueva categoría');
      await tester.scrollUntilVisible(
        create,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(create);
      await tester.pumpAndSettle();
      final categoryName = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(categoryName, 'Infusiones');
      await tester.tap(find.text('Guardar categoría'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ya existe una categoría con ese nombre.'),
        findsOneWidget,
      );
      expect(repo.snapshot.categories.length, 1);
      await tester.enterText(categoryName, 'New category');
      await tester.tap(find.text('Guardar categoría'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      final added = repo.snapshot.categories.singleWhere(
        (c) => c.name == 'New category',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        added.id,
      );
      await tester.scrollUntilVisible(
        name,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Retained draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
