import 'dart:async';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/features/admin_views.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:catalogo_legum_pro/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/catalog_app_test.dart' as fixtures;

class PendingAuth extends fixtures.MemoryAuth {
  Completer<bool> pending = Completer<bool>();
  int attempts = 0;

  @override
  Future<bool> unlock(String pin) async {
    attempts++;
    unlocked = await pending.future;
    notifyListeners();
    return unlocked;
  }
}

Widget categoryPage(AdminViewModel vm, {double scale = 1}) => MaterialApp(
  theme: catalogTheme(Brightness.dark),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: ListenableBuilder(
      listenable: vm,
      builder: (context, child) => AdminCategories(vm: vm),
    ),
  ),
);

void main() {
  testWidgets(
    'pending PIN shows real loading, prevents duplicates and retries',
    (tester) async {
      final auth = PendingAuth();
      final vm = AuthViewModel(auth);
      await tester.pumpWidget(
        MaterialApp(
          theme: catalogTheme(Brightness.light),
          home: AuthPanel(vm: vm, onCancel: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final pin = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'PIN de 4 dígitos',
      );
      final enter = find.byType(FilledButton);
      expect(
        tester.getRect(enter).top - tester.getRect(pin).bottom,
        greaterThanOrEqualTo(24),
      );
      await tester.enterText(pin, '1947');
      await tester.tap(enter);
      await tester.pump();
      expect(vm.busy, isTrue);
      expect(auth.attempts, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<FilledButton>(enter).onPressed, isNull);
      await tester.tap(enter);
      await tester.pump(const Duration(milliseconds: 50));
      expect(auth.attempts, 1);
      auth.pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('PIN incorrecto.'), findsOneWidget);
      expect(tester.widget<FilledButton>(enter).onPressed, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      auth.pending = Completer<bool>();
      await tester.enterText(pin, '1947');
      await tester.tap(enter);
      await tester.pump();
      expect(auth.attempts, 2);
      auth.pending.complete(true);
      await tester.pumpAndSettle();
      expect(auth.isAuthenticated, isTrue);
      expect(vm.error, isNull);
      expect(vm.busy, isFalse);
      expect(tester.takeException(), isNull);
      // Unmount cancels AuthPanel's lockout-refresh timer before vm disposal.
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      auth.dispose();
    },
  );

  testWidgets('category creation and cards have measured gaps at 320 and 2x', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const name = 'Legumbres y semillas seleccionadas de productores regionales';
    final repo = fixtures.MemoryCatalog(
      CatalogSnapshot(
        categories: const [
          Category(id: 'c', name: name),
          Category(id: 'd', name: 'Segunda categoría', sortOrder: 1),
        ],
        products: [fixtures.sample()],
      ),
    );
    final auth = fixtures.MemoryAuth()..unlocked = true;
    final vm = AdminViewModel(fixtures.services(catalog: repo, auth: auth));
    await tester.pumpWidget(categoryPage(vm, scale: 2));
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'Añadir categoría');
    final firstCard = find.widgetWithText(Card, name);
    final secondCard = find.widgetWithText(Card, 'Segunda categoría');
    await tester.scrollUntilVisible(firstCard, 150);
    // Card includes its margin; measure painted Material surfaces for gaps.
    final first = tester.getRect(
      find.descendant(of: firstCard, matching: find.byType(Material)).first,
    );
    expect(first.top - tester.getRect(create).bottom, greaterThanOrEqualTo(24));
    expect(find.text(name), findsOneWidget);
    expect(find.text('1 producto'), findsOneWidget);
    expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
    await tester.scrollUntilVisible(secondCard, 150);
    // Fresh global coordinates after scroll; both adjacent surfaces stay mounted.
    final firstAfterScroll = tester.getRect(
      find.descendant(of: firstCard, matching: find.byType(Material)).first,
    );
    final second = tester.getRect(
      find.descendant(of: secondCard, matching: find.byType(Material)).first,
    );
    expect(second.top - firstAfterScroll.bottom, greaterThanOrEqualTo(16));
    expect(find.text('0 productos'), findsOneWidget);
    for (final action in find.byType(IconButton).evaluate()) {
      final size = tester.getSize(find.byWidget(action.widget));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets(
    'category edit and reorder work; cancelling deletion preserves data',
    (tester) async {
      final repo = fixtures.MemoryCatalog(
        CatalogSnapshot(
          categories: const [
            Category(id: 'c', name: 'Primera'),
            Category(id: 'd', name: 'Segunda', sortOrder: 1),
          ],
        ),
      );
      final auth = fixtures.MemoryAuth()..unlocked = true;
      final vm = AdminViewModel(fixtures.services(catalog: repo, auth: auth));
      await tester.pumpWidget(categoryPage(vm));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Editar').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Primera editada');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar categoría'));
      await tester.pumpAndSettle();
      expect(
        repo.snapshot.categories.singleWhere((c) => c.id == 'c').name,
        'Primera editada',
      );
      await tester.tap(find.byTooltip('Bajar Primera editada'));
      await tester.pumpAndSettle();
      expect(vm.categories.map((c) => c.id), ['d', 'c']);
      await tester.tap(find.widgetWithText(TextButton, 'Eliminar').first);
      await tester.pumpAndSettle();
      expect(find.text('Eliminar categoría'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.snapshot.categories.length, 2);
      expect(vm.categories.map((c) => c.id), ['d', 'c']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );

  testWidgets('empty categories offer creation without category cards', (
    tester,
  ) async {
    final auth = fixtures.MemoryAuth()..unlocked = true;
    final vm = AdminViewModel(fixtures.services(auth: auth));
    await tester.pumpWidget(categoryPage(vm));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay categorías'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Editar'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Eliminar'), findsNothing);
    final create = find.widgetWithText(FilledButton, 'Añadir categoría');
    expect(tester.widget<FilledButton>(create).onPressed, isNotNull);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('Nueva categoría'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets('late unlock completion after leaving panel is disposal safe', (
    tester,
  ) async {
    final auth = PendingAuth();
    final vm = AuthViewModel(auth);
    await tester.pumpWidget(
      MaterialApp(
        theme: catalogTheme(Brightness.light),
        home: AuthPanel(vm: vm, onCancel: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1947');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    auth.pending.complete(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(vm.busy, isFalse);
    vm.dispose();
    auth.dispose();
  });

  testWidgets('compact access preserves recovery and setup acknowledgement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = fixtures.MemoryAuth();
    final vm = AuthViewModel(auth);
    Widget page(Key key) => MaterialApp(
      theme: catalogTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: AuthPanel(key: key, vm: vm, onCancel: () {}),
    );
    await tester.pumpWidget(page(const ValueKey('recovery')));
    await tester.pumpAndSettle();
    final recover = find.widgetWithText(TextButton, 'Recuperar acceso');
    await Scrollable.ensureVisible(tester.element(recover), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(recover);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'Código de recuperación'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, 'Nuevo PIN de 4 dígitos'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, 'Confirmar nuevo PIN'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.configured = false;
    await vm.unlock('1947');
    await tester.pumpWidget(page(const ValueKey('setup')));
    await tester.pumpAndSettle();
    expect(find.text('TEST-RECOVERY-CODE'), findsOneWidget);
    final confirm = find.widgetWithText(
      FilledButton,
      'Confirmar código guardado',
    );
    await tester.scrollUntilVisible(
      confirm,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(confirm), alignment: .5);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      -200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byType(CheckboxListTile)),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      confirm,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(confirm), alignment: .5);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
    auth.dispose();
  });

  test('admin text role contrast reaches 4.5 in light and dark themes', () {
    for (final brightness in Brightness.values) {
      final c = catalogScheme(brightness);
      final pairs = <String, (Color, Color)>{
        'primary/onPrimary': (c.primary, c.onPrimary),
        'primaryContainer/onPrimaryContainer': (
          c.primaryContainer,
          c.onPrimaryContainer,
        ),
        'surface/onSurface': (c.surface, c.onSurface),
        'surfaceContainerLow/onSurface': (c.surfaceContainerLow, c.onSurface),
        'surfaceContainerLow/onSurfaceVariant': (
          c.surfaceContainerLow,
          c.onSurfaceVariant,
        ),
        'secondaryContainer/onSecondaryContainer': (
          c.secondaryContainer,
          c.onSecondaryContainer,
        ),
        'surface/error': (c.surface, c.error),
      };
      for (final pair in pairs.entries) {
        final a = pair.value.$1.computeLuminance();
        final b = pair.value.$2.computeLuminance();
        final ratio = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
        // Numeric values in the host log distinguish measurement from inspection.
        // ignore: avoid_print
        print('$brightness ${pair.key}: ${ratio.toStringAsFixed(2)}:1');
        expect(ratio, greaterThanOrEqualTo(4.5), reason: pair.key);
      }
    }
  });
}
