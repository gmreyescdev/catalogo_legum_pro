import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/features/admin_views.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WaitingAuth extends AdminAuth {
  Duration wait = const Duration(seconds: 1);
  @override
  Duration get remainingLockout => wait;
  @override
  bool get isAuthenticated => false;
  @override
  bool get isConfigured => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'PIN entry becomes available when countdown reaches zero without another action',
    (tester) async {
      final auth = _WaitingAuth();
      final vm = AuthViewModel(auth);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        vm.dispose();
        auth.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: AuthPanel(vm: vm, onCancel: () {}),
        ),
      );
      final entry = find.widgetWithText(FilledButton, 'Entrar');
      expect(tester.widget<FilledButton>(entry).onPressed, isNull);
      expect(
        find.text('Espera 1 segundos antes de volver a intentar.'),
        findsOneWidget,
      );
      // The duration changes without a notifier, exactly as a clock-driven deadline does.
      auth.wait = Duration.zero;
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<FilledButton>(entry).onPressed, isNotNull);
      expect(
        find.text('Espera 1 segundos antes de volver a intentar.'),
        findsNothing,
      );
    },
  );
}
