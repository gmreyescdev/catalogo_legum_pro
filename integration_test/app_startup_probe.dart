// Profile-only ordinary entrypoint. Never use the production applicationId.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:catalogo_legum_pro/app/bootstrap.dart';
import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/sql_catalog_repository.dart';
import 'package:catalogo_legum_pro/features/catalog_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

const _seed = bool.fromEnvironment('PERF_SEED');
const _variant = String.fromEnvironment('PERF_RUN', defaultValue: 'baseline');
const _integrationId = 'com.example.catalogo_legum_pro.integration';

Future<void> main() async {
  final mainClock = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  if (!kProfileMode || !Platform.isAndroid) {
    throw StateError('Startup probe requires physical Android profile build');
  }
  final support = await getApplicationSupportDirectory();
  // Fail BEFORE any seeding/bootstrap if this entrypoint was mispackaged.
  if (!support.path.replaceAll('\\', '/').contains('/$_integrationId/')) {
    throw StateError('Startup probe refuses a non-integration sandbox');
  }
  final root = Directory('${support.path}/legum');
  final database = File('${root.path}/catalog.sqlite');
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
  final firstFrameMs = mainClock.elapsedMicroseconds / 1000;
  var seeded = false;
  if (_seed && !await database.exists()) {
    final docs = await getApplicationDocumentsDirectory();
    final fixtureRoot = Directory('${docs.path}/performance-fixture-v1');
    final manifest = File('${fixtureRoot.path}/fixture-20-v1.json');
    if (!await manifest.exists()) {
      throw StateError(
        'Prepare the deterministic F20 fixture before seeding startup probe',
      );
    }
    final json =
        jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    final snapshot = CatalogSnapshot.fromJson(
      json['catalog'] as Map<String, dynamic>,
    );
    if (snapshot.products.length != 20 || snapshot.categories.length != 5) {
      throw StateError('Unexpected startup fixture');
    }
    await root.create(recursive: true);
    for (final photo in snapshot.products.expand((p) => p.images)) {
      // Local fixture paths are validated again by SQL replaceCatalog.
      if (!RegExp(r'^media/product_\d+/photo_[0-2]\.png$')
          .hasMatch(photo.path)) {
        throw StateError('Unexpected fixture media path');
      }
      final source = File('${fixtureRoot.path}/${photo.path}');
      final destination = File('${root.path}/${photo.path}');
      await destination.parent.create(recursive: true);
      if (!await destination.exists()) await source.copy(destination.path);
    }
    final repo = SqlCatalogRepository(
      databasePath: database.path,
      requireAdmin: () {},
    );
    try {
      await repo.load();
      await repo.replaceCatalog(snapshot);
    } finally {
      await repo.close();
    }
    seeded = true;
  }
  if (!await database.exists()) {
    throw StateError('No seeded startup database; use PERF_SEED=true once');
  }
  final bootstrapClock = Stopwatch()..start();
  final services = await createAppServices();
  final bootstrapMs = bootstrapClock.elapsedMicroseconds / 1000;
  if (services.catalog.snapshot.products.length != 20) {
    throw StateError(
      'Startup database is not F20; refusing invalid measurement',
    );
  }
  runApp(CatalogApp(services: services));
  await WidgetsBinding.instance.endOfFrame;
  final result = <String, Object?>{
    'kind': 'production-startup',
    'variant': _variant,
    'applicationIdGuard': _integrationId,
    'profile': kProfileMode,
    'seededThisRun': seeded,
    'excludeFromStartupComparison': seeded,
    'dartMainToLoadingFrameMs': firstFrameMs,
    'realBootstrapMs': bootstrapMs,
    'dartMainToCatalogUsableMs': mainClock.elapsedMicroseconds / 1000,
    'productCount': services.catalog.snapshot.products.length,
    'publicProductCount': services.catalog.snapshot.products
        .where((p) => p.visible)
        .length,
    'marker': 'Dart main to post-frame of real CatalogApp, SQL/media/auth bootstrap included; native engine startup excluded',
    'imagesMayStillBeLoading': true,
    'authInitialPinConfigured': const String.fromEnvironment(
      'INITIAL_ADMIN_PIN',
    ).isNotEmpty,
  };
  debugPrint('PERF_JSON: ${jsonEncode(result)}');
  final external = await getExternalStorageDirectory();
  final output = Directory('${external?.path ?? support.path}/performance');
  await output.create(recursive: true);
  final file = File(
    '${output.path}/startup-$_variant-${DateTime.now().millisecondsSinceEpoch}.json',
  );
  await file.writeAsString(jsonEncode(result), flush: true);
  debugPrint('PERF_SAVED: ${file.path}');
  final privateOutput = Directory('${support.path}/performance-results');
  await privateOutput.create(recursive: true);
  await file.copy('${privateOutput.path}/${file.uri.pathSegments.last}');
  debugPrint('PERF_DONE: startup-$_variant');
}
