import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synchronized/synchronized.dart';

import '../../contracts.dart';

abstract class CredentialStore {
  Future<String?> read();
  Future<void> write(String value);
}

class FlutterCredentialStore implements CredentialStore {
  FlutterCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'legum.auth.envelope.v1';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class SecureAdminAuth extends AdminAuth {
  SecureAdminAuth({
    required String initialPin,
    CredentialStore? store,
    DateTime Function()? now,
    int iterations = 600000,
    // Public input is non-null; the retained field is cleared after initialization.
    // ignore: prefer_initializing_formals
  }) : _initialPin = initialPin,
       _store = store ?? FlutterCredentialStore(),
       _now = now ?? DateTime.now,
       _iterations = iterations {
    if (iterations < 1) throw ArgumentError.value(iterations);
  }
  String? _initialPin;
  final CredentialStore _store;
  final DateTime Function() _now;
  final int _iterations;
  final _mutex = Lock();
  Map<String, dynamic>? _state;
  Map<String, dynamic>? _pendingSetup, _pendingRecovery;
  bool _authenticated = false, _ready = false;
  int _epoch = 0;
  int _setupRevision = 0, _recoveryRevision = 0;

  @override
  bool get isAuthenticated => _ready && _authenticated;
  @override
  bool get isConfigured => _ready && _state?['recovery'] != null;
  int get _time =>
      max(_now().millisecondsSinceEpoch, (_state?['observed'] as int?) ?? 0);
  @override
  Duration get remainingLockout => Duration(
    milliseconds: max(0, ((_state?['deadline'] as int?) ?? 0) - _time),
  );

  @override
  Future<void> initialize() => _mutex.synchronized(() async {
    lock();
    _ready = false;
    try {
      final raw = await _store.read();
      if (raw == null) {
        final pin = _initialPin;
        if (pin == null || !_validPin(pin)) {
          throw StateError('PIN inicial sin configurar.');
        }
        final initial = <String, dynamic>{
          'version': 1,
          'pin': await _verifier(pin),
          'recovery': null,
          'failures': 0,
          'deadline': 0,
          'observed': _now().millisecondsSinceEpoch,
        };
        await _store.write(jsonEncode(initial));
        _state = initial;
      } else {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _validateEnvelope(decoded);
        _state = decoded;
      }
      _initialPin = null;
      _ready = true;
      notifyListeners();
    } catch (_) {
      _state = null;
      _initialPin = null;
      throw StateError(
        'No se pudo acceder a las credenciales protegidas. '
        'El catálogo público sigue disponible.',
      );
    }
  });

  static bool _validPin(String value) => RegExp(r'^\d{4}$').hasMatch(value);
  void _available() {
    if (!_ready) {
      throw StateError(
        'Administración no disponible: almacenamiento protegido.',
      );
    }
    if (remainingLockout > Duration.zero) {
      throw StateError(
        'Espera ${remainingLockout.inSeconds + 1} segundos para reintentar.',
      );
    }
  }

  @override
  void requireAdmin() {
    if (!isAuthenticated) throw StateError('Ingresa el PIN para continuar.');
  }

  void _session(int epoch) {
    requireAdmin();
    if (epoch != _epoch) {
      throw StateError('La sesión terminó; vuelve a ingresar el PIN.');
    }
  }

  Future<Map<String, dynamic>> _verifier(String value) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _derive(value, salt, _iterations);
    return {
      'salt': base64Encode(salt),
      'hash': base64Encode(hash),
      'iterations': _iterations,
    };
  }

  Future<List<int>> _derive(
    String value,
    List<int> salt,
    int iterations,
  ) async =>
      (await Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: iterations,
            bits: 256,
          ).deriveKey(secretKey: SecretKey(utf8.encode(value)), nonce: salt))
          .extractBytes();
  Future<bool> _matches(String value, Map<String, dynamic> verifier) async {
    final expected = base64Decode(verifier['hash'] as String);
    final actual = await _derive(
      value,
      base64Decode(verifier['salt'] as String),
      verifier['iterations'] as int,
    );
    var difference = expected.length ^ actual.length;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i % expected.length];
    }
    return difference == 0;
  }

  void _validateEnvelope(Map<String, dynamic> state) {
    if (state['version'] != 1) throw const FormatException();
    for (final field in ['failures', 'deadline', 'observed']) {
      if (state[field] is! int || (state[field] as int) < 0) {
        throw const FormatException();
      }
    }
    for (final name in ['pin', 'recovery']) {
      final raw = state[name];
      if (name == 'recovery' && raw == null) continue;
      final value = raw as Map<String, dynamic>;
      final count = value['iterations'] as int;
      if (count < 1 ||
          count > 10000000 ||
          base64Decode(value['salt'] as String).length != 16 ||
          base64Decode(value['hash'] as String).length != 32) {
        throw const FormatException();
      }
    }
  }

  Future<void> _persist(Map<String, dynamic> next) async {
    try {
      await _store.write(jsonEncode(next));
      _state = next;
      notifyListeners();
    } catch (_) {
      _ready = false;
      lock();
      throw StateError(
        'No se pudieron guardar las credenciales de forma segura.',
      );
    }
  }

  Map<String, dynamic> _reset() => {
    ..._state!,
    'failures': 0,
    'deadline': 0,
    'observed': _time,
  };
  Future<void> _failure() async {
    final failures = (_state!['failures'] as int) + 1;
    final seconds = failures < 5
        ? 0
        : min(900, 30 * (1 << min(5, failures - 5)));
    await _persist({
      ..._state!,
      'failures': failures,
      'deadline': seconds == 0 ? 0 : _time + seconds * 1000,
      'observed': _time,
    });
  }

  @override
  Future<bool> unlock(String pin) => _mutex.synchronized(() async {
    _available();
    final epoch = _epoch;
    final valid =
        _validPin(pin) &&
        await _matches(pin, _state!['pin'] as Map<String, dynamic>);
    if (!valid) {
      await _failure();
      return false;
    }
    if (epoch != _epoch) {
      throw StateError('La app se bloqueó durante el acceso.');
    }
    await _persist(_reset());
    if (epoch != _epoch) {
      throw StateError('La app se bloqueó durante el acceso.');
    }
    _authenticated = true;
    notifyListeners();
    return true;
  });

  String _newCode() {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    var buffer = 0, bits = 0;
    final out = StringBuffer();
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(alphabet[(buffer >> bits) & 31]);
      }
      buffer &= (1 << bits) - 1;
    }
    if (bits > 0) out.write(alphabet[(buffer << (5 - bits)) & 31]);
    final raw = out.toString();
    return [
      for (var i = 0; i < raw.length; i += 4)
        raw.substring(i, min(i + 4, raw.length)),
    ].join('-');
  }

  String _normalizeCode(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  @override
  Future<String> beginSetup() => _mutex.synchronized(() async {
    requireAdmin();
    if (isConfigured) throw StateError('La recuperación ya está configurada.');
    final revision = ++_setupRevision;
    _pendingSetup = null;
    final epoch = _epoch, code = _newCode();
    final verifier = await _verifier(_normalizeCode(code));
    _session(epoch);
    if (revision != _setupRevision) {
      throw StateError('La configuración fue cancelada.');
    }
    _pendingSetup = {'epoch': epoch, 'verifier': verifier};
    return code;
  });
  @override
  Future<void> confirmSetup() => _mutex.synchronized(() async {
    final pending = _pendingSetup;
    if (pending == null || isConfigured) {
      throw StateError('Inicia la configuración nuevamente.');
    }
    _session(pending['epoch'] as int);
    await _persist({..._reset(), 'recovery': pending['verifier']});
    _pendingSetup = null;
  });
  @override
  void cancelSetup() {
    _setupRevision++;
    _pendingSetup = null;
  }

  @override
  Future<String> prepareRecovery(String code, String newPin) =>
      _mutex.synchronized(() async {
        _available();
        final epoch = _epoch, revision = ++_recoveryRevision;
        _pendingRecovery = null;
        if (!_validPin(newPin)) {
          throw StateError('El PIN debe contener cuatro dígitos.');
        }
        final normalizedCode = _normalizeCode(code);
        final verifier = _state!['recovery'];
        if (verifier == null ||
            !RegExp(r'^[A-Z2-7]{26}$').hasMatch(normalizedCode) ||
            !await _matches(normalizedCode, verifier as Map<String, dynamic>)) {
          await _failure();
          throw StateError('Código de recuperación incorrecto.');
        }
        final replacement = _newCode();
        final pinVerifier = await _verifier(newPin);
        final recoveryVerifier = await _verifier(_normalizeCode(replacement));
        if (epoch != _epoch || revision != _recoveryRevision) {
          throw StateError('Retoma la recuperación al volver a la app.');
        }
        _pendingRecovery = {
          'epoch': epoch,
          'pin': pinVerifier,
          'recovery': recoveryVerifier,
        };
        return replacement;
      });
  @override
  Future<void> confirmRecovery() => _mutex.synchronized(() async {
    _available();
    final pending = _pendingRecovery;
    if (pending == null || pending['epoch'] != _epoch) {
      throw StateError('Inicia recuperación nuevamente.');
    }
    await _persist({
      ..._reset(),
      'pin': pending['pin'],
      'recovery': pending['recovery'],
    });
    lock();
  });
  @override
  void cancelRecovery() {
    _recoveryRevision++;
    _pendingRecovery = null;
  }

  @override
  Future<void> changePin(String currentPin, String newPin) =>
      _mutex.synchronized(() async {
        _available();
        requireAdmin();
        if (!_validPin(newPin)) {
          throw StateError('El PIN debe contener cuatro dígitos.');
        }
        final epoch = _epoch;
        if (!await _matches(
          currentPin,
          _state!['pin'] as Map<String, dynamic>,
        )) {
          await _failure();
          throw StateError('PIN actual incorrecto.');
        }
        final verifier = await _verifier(newPin);
        _session(epoch);
        await _persist({..._reset(), 'pin': verifier});
        cancelSetup();
        cancelRecovery();
      });
  @override
  void lock() {
    _epoch++;
    _setupRevision++;
    _recoveryRevision++;
    _authenticated = false;
    _pendingSetup = null;
    _pendingRecovery = null;
    notifyListeners();
  }
}
