import 'package:catalogo_legum_pro/features/admin_views.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:catalogo_legum_pro/ui/theme.dart';
import 'package:catalogo_legum_pro/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/catalog_app_test.dart' as fixtures;

Finder field(String label) => find.widgetWithText(TextFormField, label);

Finder editorScroll() => find
    .descendant(
      of: find.byType(Form),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    )
    .first;

Future<void> finishEditing(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

String fieldValue(WidgetTester tester, String label) => tester
    .widget<EditableText>(
      find.descendant(of: field(label), matching: find.byType(EditableText)),
    )
    .controller
    .text;

void main() {
  testWidgets(
    'canceling inline category preserves existing draft fields and photo',
    (tester) async {
      final product = fixtures.sample();
      final repository = fixtures.MemoryCatalog(fixtures.data([product]));
      final auth = fixtures.MemoryAuth()..unlocked = true;
      final services = fixtures.services(catalog: repository, auth: auth);
      await tester.pumpWidget(
        MaterialApp(
          theme: catalogTheme(Brightness.light),
          home: ProductEditorView(services: services, product: product),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        field('Nombre'),
        'Borrador modificado sin guardar',
      );
      await finishEditing(tester);
      await tester.scrollUntilVisible(
        field('Presentación'),
        150,
        scrollable: editorScroll(),
      );
      await tester.enterText(field('Presentación'), 'Caja especial 2 kg');
      await finishEditing(tester);
      await tester.scrollUntilVisible(
        field('Precio normal CLP'),
        150,
        scrollable: editorScroll(),
      );
      await tester.enterText(field('Precio normal CLP'), '18500');
      await finishEditing(tester);
      final categoryButton = find.widgetWithText(TextButton, 'Nueva categoría');
      await tester.scrollUntilVisible(
        categoryButton,
        -150,
        scrollable: editorScroll(),
      );
      await tester.tap(categoryButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nombre de categoría'),
        'Categoría que no se guarda',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<String>),
        -150,
        scrollable: editorScroll(),
      );
      expect(
        tester
            .state<FormFieldState<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .value,
        product.categoryId,
      );
      expect(repository.snapshot.categories, hasLength(1));
      expect(repository.snapshot.products.single.name, product.name);
      for (final entry in {
        'Nombre': 'Borrador modificado sin guardar',
        'Presentación': 'Caja especial 2 kg',
        'Precio normal CLP': '18500',
      }.entries) {
        final scrollable = tester.state<ScrollableState>(editorScroll());
        scrollable.position.jumpTo(0);
        await tester.pump();
        await tester.scrollUntilVisible(
          field(entry.key),
          150,
          scrollable: editorScroll(),
        );
        expect(fieldValue(tester, entry.key), entry.value);
      }
      await tester.scrollUntilVisible(
        find.byType(ProductPhoto),
        300,
        scrollable: editorScroll(),
      );
      expect(
        tester
            .widget<ProductPhoto>(find.byType(ProductPhoto).first)
            .image!
            .path,
        product.images.first.path,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'last admin card clears FAB and menu actions remain usable at 320 dp and text 2x',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final products = List.generate(
        5,
        (i) => fixtures.sample(
          id: 'p$i',
          name: 'Producto administrativo extenso $i',
        ),
      );
      final repository = fixtures.MemoryCatalog(fixtures.data(products));
      final auth = fixtures.MemoryAuth()..unlocked = true;
      final appServices = fixtures.services(catalog: repository, auth: auth);
      final adminVm = AdminViewModel(appServices);
      final authVm = AuthViewModel(auth);
      final catalogVm = CatalogViewModel(appServices);
      await tester.pumpWidget(
        MaterialApp(
          theme: catalogTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AdminHome(
            vm: adminVm,
            auth: authVm,
            catalog: catalogVm,
            onExit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final admin = find.byType(AdminProducts);
      final scrollable = find.descendant(
        of: admin,
        matching: find.byType(Scrollable),
      );
      final last = products.last;
      final menu = find.byTooltip('Más acciones de ${last.name}');
      await tester.scrollUntilVisible(menu, 500, scrollable: scrollable);
      await tester.drag(scrollable, const Offset(0, -1500));
      await tester.pumpAndSettle();
      final card = find.ancestor(of: menu, matching: find.byType(Card)).first;
      final fab = find.byType(FloatingActionButton);
      expect(tester.getRect(card).bottom, lessThan(tester.getRect(fab).top));
      expect(tester.getRect(menu).width, greaterThanOrEqualTo(48));
      expect(tester.getRect(menu).height, greaterThanOrEqualTo(48));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ocultar'));
      await tester.pumpAndSettle();
      expect(
        repository.snapshot.products.firstWhere((p) => p.id == last.id).visible,
        isFalse,
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marcar agotado'));
      await tester.pumpAndSettle();
      expect(
        repository.snapshot.products
            .firstWhere((p) => p.id == last.id)
            .available,
        isFalse,
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(repository.snapshot.products, hasLength(5));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      adminVm.dispose();
      authVm.dispose();
      catalogVm.dispose();
    },
  );
}
