import 'package:catalogo_legum_pro/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<GlobalKey<NavigatorState>> setup(WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        theme: catalogTheme(Brightness.light),
        home: const Scaffold(body: Text('Catalog route')),
      ),
    );
    return key;
  }

  MaterialPageRoute<void> detail() => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('Detail route')),
  );

  testWidgets(
    'ordinary Material navigation animates and supports rapid return',
    (tester) async {
      final navigator = await setup(tester);
      final route = detail();
      navigator.currentState!.push(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(route.animation!.status, AnimationStatus.forward);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Catalog route'), findsOneWidget);
      expect(find.text('Detail route'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('system reduced motion shortens Material push and pop', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final navigator = await setup(tester);
    final route = detail();
    navigator.currentState!.push(route);
    await tester.pump();
    expect(
      MediaQuery.of(
        tester.element(find.text('Detail route', skipOffstage: false)),
      ).disableAnimations,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(route.animation!.status, AnimationStatus.completed);
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('Detail route'), findsNothing);
    expect(find.text('Catalog route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
