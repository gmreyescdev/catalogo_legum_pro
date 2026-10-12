import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:catalogo_legum_pro/data/auth/secure_admin_auth.dart';

class MemoryCredentials implements CredentialStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async {
    if (fail) throw StateError('unavailable');
    return value;
  }

  @override
  Future<void> write(String next) async {
    if (fail) throw StateError('unavailable');
    value = next;
  }
}

// Synthetic test-only values; no distribution credentials.
String get fixturePin => List.generate(4, (i) => i).join();
void main() {
  late MemoryCredentials store;
  late DateTime clock;
  late SecureAdminAuth auth;
  setUp(() async {
    store = MemoryCredentials();
    clock = DateTime.utc(2026);
    auth = SecureAdminAuth(
      initialPin: fixturePin,
      store: store,
      now: () => clock,
      iterations: 8,
    );
    await auth.initialize();
  });

  test('initial PIN preserves zeros, setup cancellation and verifier-only envelope', () async {
    expect(auth.isConfigured, isFalse);
    expect(await auth.unlock(fixturePin), isTrue);
    final abandoned = await auth.beginSetup();
    auth.cancelSetup();
    expect(auth.isConfigured, isFalse);
    expect(auth.confirmSetup(), throwsStateError);
    final code = await auth.beginSetup();
    expect(code, isNot(abandoned));
    await auth.confirmSetup();
    expect(auth.isConfigured, isTrue);
    final envelope = jsonDecode(store.value!) as Map;
    expect(envelope['pin'], isA<Map>());
    expect(envelope['recovery'], isA<Map>());
    expect(store.value, isNot(contains(code)));
    auth.lock();
    expect(auth.requireAdmin, throwsStateError);
  });

  test(
    'recovery cancellation preserves old PIN; confirm rotates code and locks',
    () async {
      await auth.unlock(fixturePin);
      final code = await auth.beginSetup();
      await auth.confirmSetup();
      auth.lock();
      final replacementPin = fixturePin.split('').reversed.join();
      await auth.prepareRecovery(
        code.toLowerCase().replaceAll('-', ' '),
        replacementPin,
      );
      auth.cancelRecovery();
      expect(await auth.unlock(fixturePin), isTrue);
      auth.lock();
      final replacement = await auth.prepareRecovery(code, replacementPin);
      await auth.confirmRecovery();
      expect(auth.isAuthenticated, isFalse);
      expect(await auth.unlock(fixturePin), isFalse);
      expect(await auth.unlock(replacementPin), isTrue);
      auth.lock();
      await expectLater(
        auth.prepareRecovery(code, fixturePin),
        throwsStateError,
      );
      await auth.prepareRecovery(replacement, fixturePin);
      await auth.confirmRecovery();
      expect(await auth.unlock(fixturePin), isTrue);
    },
  );

  test('five failures throttle, persist restart, resist backward clock and double wait', () async {
    for (var i = 0; i < 5; i++) {
      expect(await auth.unlock('bad'), isFalse);
    }
    expect(auth.remainingLockout, const Duration(seconds: 30));
    final restarted = SecureAdminAuth(
      initialPin: '',
      store: store,
      now: () => clock,
      iterations: 8,
    );
    await restarted.initialize();
    clock = clock.subtract(const Duration(hours: 1));
    expect(restarted.remainingLockout, const Duration(seconds: 30));
    await expectLater(restarted.unlock(fixturePin), throwsStateError);
    clock = DateTime.utc(2026).add(const Duration(seconds: 31));
    expect(await restarted.unlock('bad'), isFalse);
    expect(restarted.remainingLockout, const Duration(seconds: 60));
    clock = clock.add(const Duration(seconds: 61));
    expect(await restarted.unlock(fixturePin), isTrue);
    expect(restarted.remainingLockout, Duration.zero);
  });

  test('lock invalidates prepared setup and recovery; PIN change validates current', () async {
    await auth.unlock(fixturePin);
    await auth.beginSetup();
    auth.lock();
    await expectLater(auth.confirmSetup(), throwsStateError);
    await auth.unlock(fixturePin);
    final code = await auth.beginSetup();
    await auth.confirmSetup();
    await expectLater(auth.changePin('bad', 'bad'), throwsStateError);
    final replacementPin = fixturePin.split('').reversed.join();
    await auth.changePin(fixturePin, replacementPin);
    auth.lock();
    expect(await auth.unlock(replacementPin), isTrue);
    await auth.prepareRecovery(code, fixturePin);
    auth.lock();
    await expectLater(auth.confirmRecovery(), throwsStateError);
  });

  test(
    'secure storage failure closes admin without overwriting prior envelope',
    () async {
      await auth.unlock(fixturePin);
      final original = store.value;
      final code = await auth.beginSetup();
      expect(code, isNotEmpty);
      store.fail = true;
      await expectLater(auth.confirmSetup(), throwsStateError);
      expect(auth.isAuthenticated, isFalse);
      expect(store.value, original);
      expect(auth.requireAdmin, throwsStateError);
    },
  );

  test('corrupt or inaccessible credential storage fails closed', () async {
    store.value = '{"version":99}';
    await expectLater(auth.initialize(), throwsStateError);
    expect(auth.isAuthenticated, isFalse);
    await expectLater(auth.unlock(fixturePin), throwsStateError);
  });

  test(
    'recovery verifier and changed PIN survive restart without initial PIN',
    () async {
      await auth.unlock(fixturePin);
      final code = await auth.beginSetup();
      await auth.confirmSetup();
      final newPin = fixturePin.split('').reversed.join();
      await auth.changePin(fixturePin, newPin);
      final restarted = SecureAdminAuth(
        initialPin: '',
        store: store,
        iterations: 8,
      );
      await restarted.initialize();
      expect(restarted.isConfigured, isTrue);
      expect(restarted.isAuthenticated, isFalse);
      expect(await restarted.unlock(newPin), isTrue);
      restarted.lock();
      await restarted.prepareRecovery(code, fixturePin);
      await restarted.confirmRecovery();
      expect(await restarted.unlock(fixturePin), isTrue);
    },
  );

  test(
    'repeated failures reach but never exceed fifteen-minute wait',
    () async {
      for (var failure = 1; failure <= 12; failure++) {
        expect(await auth.unlock('bad'), isFalse);
        final wait = auth.remainingLockout;
        expect(wait <= const Duration(minutes: 15), isTrue);
        if (failure >= 10) expect(wait, const Duration(minutes: 15));
        clock = clock.add(wait + const Duration(seconds: 1));
      }
    },
  );
}
