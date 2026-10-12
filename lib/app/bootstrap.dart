import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../contracts.dart';
import '../data/auth/secure_admin_auth.dart';
import '../data/sql_catalog_repository.dart';
import '../data/local_media_manager.dart';
import '../data/local_backup_manager.dart';
import '../data/whatsapp/native_whatsapp_gateway.dart';

Future<AppServices> createAppServices() async {
  final support = await getApplicationSupportDirectory();
  final root = Directory(p.join(support.path, 'legum'));
  await root.create(recursive: true);
  final auth = SecureAdminAuth(
    initialPin: const String.fromEnvironment('INITIAL_ADMIN_PIN'),
  );
  // A protected-storage failure must not hide the public local catalog.
  try {
    await auth.initialize();
  } catch (_) {
    /* Auth stays fail-closed. */
  }
  var sessionEpoch = 0;
  var authenticated = auth.isAuthenticated;
  auth.addListener(() {
    if (authenticated != auth.isAuthenticated) {
      authenticated = auth.isAuthenticated;
      sessionEpoch++;
    }
  });
  void requireCatalogAdmin() {
    auth.requireAdmin();
    if (!auth.isConfigured) {
      throw StateError('Guarda y confirma tu código de recuperación primero.');
    }
  }

  final catalog = SqlCatalogRepository(
    databasePath: p.join(root.path, 'catalog.sqlite'),
    requireAdmin: requireCatalogAdmin,
    sessionToken: () => sessionEpoch,
  );
  final media = LocalMediaManager(
    root: root,
    referencedPaths: () => catalog.snapshot.products
        .expand((p) => p.images)
        .map((i) => i.path)
        .toSet(),
  );
  try {
    await catalog.load();
  } catch (_) {
    await catalog.close();
    rethrow;
  }
  // Retry cleanup after interrupted writes without preventing catalog access.
  try {
    await media.cleanupInterruptedStaging();
    await media.collectGarbage(
      catalog.snapshot.products
          .expand((product) => product.images)
          .map((image) => image.path)
          .toSet(),
    );
  } catch (_) {
    // Files still referenced by SQLite remain authoritative.
  }
  final backup = LocalBackupManager(
    catalog: catalog,
    media: media,
    workDirectory: Directory(p.join(root.path, 'backups')),
    requireAdmin: requireCatalogAdmin,
    sessionToken: () => sessionEpoch,
  );
  try {
    await backup.cleanupInterruptedStaging();
  } catch (_) {
    // A temporary-file cleanup failure does not invalidate committed data.
  }
  final whatsapp = NativeWhatsAppGateway(
    media: media,
    workDirectory: Directory(p.join(root.path, 'shared_catalogs')),
  );
  try {
    await whatsapp.cleanupExpired();
  } catch (_) {
    // Cleanup can be retried without preventing access to the catalog.
  }
  return AppServices(
    catalog: catalog,
    auth: auth,
    media: media,
    backup: backup,
    whatsapp: whatsapp,
  );
}
