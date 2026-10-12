import 'dart:async';
import 'dart:io';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/auth/secure_admin_auth.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Credentials implements CredentialStore {
  String? value;
  Completer<void>? writeStarted;
  Completer<void>? releaseWrite;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    writeStarted?.complete();
    await releaseWrite?.future;
    value = next;
  }
}

class _Catalog extends CatalogRepository {
  _Catalog(this._snapshot);
  CatalogSnapshot _snapshot;
  bool failDelete = false;
  @override
  CatalogSnapshot get snapshot => _snapshot;
  @override
  Future<void> deleteProduct(String id) async {
    if (failDelete) throw StateError('Simulated database failure');
    _snapshot = CatalogSnapshot(
      categories: snapshot.categories,
      products: snapshot.products.where((product) => product.id != id).toList(),
      settings: snapshot.settings,
    );
    notifyListeners();
  }

  @override
  Future<void> saveProduct(Product product) async {
    _snapshot = CatalogSnapshot(
      categories: snapshot.categories,
      products: [
        for (final existing in snapshot.products)
          existing.id == product.id ? product : existing,
      ],
      settings: snapshot.settings,
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Backup implements BackupManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WhatsApp implements WhatsAppGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Synthetic credentials and private temporary files, never production data.
void main() {
  late SecureAdminAuth auth;
  setUp(() async {
    auth = SecureAdminAuth(
      initialPin: '0042',
      store: _Credentials(),
      iterations: 8,
    );
    await auth.initialize();
  });
  tearDown(() {
    auth.dispose();
  });

  test(
    'locking removes a displayed setup code and requires a fresh setup',
    () async {
      final vm = AuthViewModel(auth);
      addTearDown(vm.dispose);
      expect(await vm.unlock('0042'), isTrue);
      expect(vm.setupCode, isNotNull);
      auth.lock();
      expect(vm.setupCode, isNull);
      expect(await vm.confirmSetup(), isFalse);
      expect(auth.isConfigured, isFalse);
      expect(await vm.unlock('0042'), isTrue);
      expect(vm.setupCode, isNotNull);
    },
  );

  test(
    'locking removes a pending recovery replacement from view state',
    () async {
      await auth.unlock('0042');
      final original = await auth.beginSetup();
      await auth.confirmSetup();
      auth.lock();
      final vm = AuthViewModel(auth);
      addTearDown(vm.dispose);
      expect(await vm.recover(original, '0056', '0056'), isTrue);
      expect(vm.recoveryCode, isNotNull);
      auth.lock();
      expect(vm.recoveryCode, isNull);
      expect(await vm.confirmRecovery(), isFalse);
      expect(await auth.unlock('0042'), isTrue);
    },
  );

  test('lock during an already dispatched credential write never reopens administration', () async {
    final store = _Credentials();
    final isolated = SecureAdminAuth(
      initialPin: '0042',
      store: store,
      iterations: 8,
    );
    addTearDown(isolated.dispose);
    await isolated.initialize();
    store.writeStarted = Completer<void>();
    store.releaseWrite = Completer<void>();
    final pending = isolated.unlock('0042');
    final rejected = expectLater(pending, throwsStateError);
    await store.writeStarted!.future;
    isolated.lock();
    store.releaseWrite!.complete();
    await rejected;
    expect(isolated.isAuthenticated, isFalse);
    expect(isolated.requireAdmin, throwsStateError);
    // An already dispatched atomic write may complete; no rollback is assumed.
    expect(store.value, isNotNull);
  });
  group('committed media removal', () {
    late Directory root;
    late _Catalog catalog;
    late LocalMediaManager media;
    late AppServices services;
    const oldPhoto = 'media/original/removed.png';
    const keptPhoto = 'media/original/kept.png';
    const otherPhoto = 'media/other/kept.png';
    Product fixture(String id, List<String> paths) => Product(
      id: id,
      categoryId: 'c',
      name: id,
      description: 'Description',
      sku: id,
      presentation: '1 kg',
      normalClp: 100,
      images: [
        for (var i = 0; i < paths.length; i++)
          ProductImage(id: '$id-$i', path: paths[i], sortOrder: i),
      ],
    );
    setUp(() async {
      await auth.unlock('0042');
      root = await Directory.systemTemp.createTemp('legum_qa_media_');
      catalog = _Catalog(
        CatalogSnapshot(
          categories: [const Category(id: 'c', name: 'Category')],
          products: [
            fixture('edited', [oldPhoto, keptPhoto]),
            fixture('other', [otherPhoto]),
          ],
        ),
      );
      media = LocalMediaManager(
        root: root,
        referencedPaths: () => catalog.snapshot.products
            .expand((product) => product.images)
            .map((image) => image.path)
            .toSet(),
      );
      for (final relative in [oldPhoto, keptPhoto, otherPhoto]) {
        final file = File(media.absolutePath(relative));
        await file.parent.create(recursive: true);
        await file.writeAsBytes([
          1,
          2,
          3,
        ]); // Bytes only; these tests verify cleanup, not decoding.
      }
      services = AppServices(
        catalog: catalog,
        auth: auth,
        media: media,
        backup: _Backup(),
        whatsapp: _WhatsApp(),
      );
    });
    tearDown(() async {
      catalog.dispose();
      await root.delete(recursive: true);
    });

    test(
      'delete cleans only unreferenced product photos after successful save',
      () async {
        final vm = AdminViewModel(services);
        addTearDown(vm.dispose);
        expect(await vm.deleteProduct('edited'), isTrue);
        expect(await File(media.absolutePath(oldPhoto)).exists(), isFalse);
        expect(await File(media.absolutePath(keptPhoto)).exists(), isFalse);
        expect(await File(media.absolutePath(otherPhoto)).exists(), isTrue);
      },
    );

    test('editing removes old original photo without deleting retained or other photos', () async {
      final vm = ProductEditorViewModel(
        services,
        catalog.snapshot.products.first,
      );
      addTearDown(vm.dispose);
      vm.removeImage(0);
      expect(await vm.save(), isTrue);
      expect(await File(media.absolutePath(oldPhoto)).exists(), isFalse);
      expect(await File(media.absolutePath(keptPhoto)).exists(), isTrue);
      expect(await File(media.absolutePath(otherPhoto)).exists(), isTrue);
    });

    test('failed deletion preserves all original files and records', () async {
      catalog.failDelete = true;
      final vm = AdminViewModel(services);
      addTearDown(vm.dispose);
      expect(await vm.deleteProduct('edited'), isFalse);
      expect(catalog.snapshot.products.length, 2);
      for (final relative in [oldPhoto, keptPhoto, otherPhoto]) {
        expect(await File(media.absolutePath(relative)).exists(), isTrue);
      }
    });
  });
}
