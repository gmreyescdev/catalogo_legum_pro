import 'dart:io';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/local_backup_manager.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/data/sql_catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory root;
  late Directory work;
  late SqlCatalogRepository catalog;
  late LocalMediaManager media;
  bool authenticated = true;
  void requireAdmin() {
    if (!authenticated) throw StateError('Session ended');
  }

  LocalBackupManager manager({
    Future<void> Function(String)? share,
    Future<void> Function()? beforeReplace,
  }) => LocalBackupManager(
    catalog: catalog,
    media: media,
    workDirectory: work,
    requireAdmin: requireAdmin,
    shareFile: share,
    beforeReplace: beforeReplace,
  );

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    authenticated = true;
    root = await Directory.systemTemp.createTemp('legum_qa_backup_');
    work = Directory(p.join(root.path, 'backups'));
    catalog = SqlCatalogRepository(
      databasePath: p.join(root.path, 'catalog.sqlite'),
      requireAdmin: requireAdmin,
      factory: databaseFactoryFfi,
    );
    await catalog.load();
    media = LocalMediaManager(root: root);
    await catalog.saveCategory(
      const Category(id: 'original', name: 'Original'),
    );
  });
  tearDown(() async {
    await catalog.close();
    await root.delete(recursive: true);
  });

  test(
    'failed external sharing cleans the temporary export but preserves catalog',
    () async {
      String? offered;
      final backup = manager(
        share: (path) async {
          offered = path;
          expect(await File(path).exists(), isTrue);
          throw StateError('External sharing unavailable');
        },
      );
      await expectLater(backup.exportBackup(), throwsStateError);
      expect(offered, isNotNull);
      expect(await File(offered!).exists(), isFalse);
      expect(catalog.snapshot.categories.single.id, 'original');
      expect(await work.list().toList(), isEmpty);
    },
  );

  test(
    'successful share retains private export for the external recipient',
    () async {
      String? offered;
      final backup = manager(
        share: (path) async {
          offered = path;
        },
      );
      await backup.exportBackup();
      expect(offered, isNotNull);
      expect(await File(offered!).exists(), isTrue);
      expect(catalog.snapshot.categories.single.id, 'original');
    },
  );

  test(
    'session lost after validation and media promotion aborts replacement',
    () async {
      final backup = manager(
        beforeReplace: () async {
          authenticated = false;
        },
      );
      final exported = await backup.exportBackup(share: false);
      final preview = await backup.prepareBackup(File(exported));
      await catalog.saveCategory(
        const Category(id: 'keep', name: 'Added after backup'),
      );
      await expectLater(backup.restoreBackup(preview), throwsStateError);
      await catalog.close();
      await catalog.load();
      expect(
        catalog.snapshot.categories.map((category) => category.id).toSet(),
        {'original', 'keep'},
      );
      await backup.discardPreview(preview);
      final mediaRoot = Directory(p.join(root.path, 'media'));
      final files = await mediaRoot.exists()
          ? await mediaRoot
                .list(recursive: true)
                .where((entity) => entity is File)
                .toList()
          : <FileSystemEntity>[];
      expect(files, isEmpty);
    },
  );
}
