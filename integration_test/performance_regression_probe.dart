// Complementary functional/resource checks; not the comparable frame benchmark.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/features/admin_views.dart';
import 'package:catalogo_legum_pro/features/catalog_app.dart';
import 'package:catalogo_legum_pro/features/public_views.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'performance/fixture.dart';

const _variant = String.fromEnvironment('PERF_RUN', defaultValue: 'candidate');
const _fixtureCount = int.fromEnvironment(
  'PERF_FIXTURE_COUNT',
  defaultValue: 100,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kProfileMode || !Platform.isAndroid) {
    throw StateError('Physical Android profile required');
  }
  final support = await getApplicationSupportDirectory();
  if (!support.path.contains('/com.example.catalogo_legum_pro.integration/')) {
    throw StateError('Integration sandbox required before fixture access');
  }
  final docs = await getApplicationDocumentsDirectory();
  final root = Directory('${docs.path}/performance-fixture-v1');
  if (_fixtureCount != 20 && _fixtureCount != 100) {
    throw StateError('Only deterministic F20/F100 fixtures are supported');
  }
  final manifest = File('${root.path}/fixture-$_fixtureCount-v1.json');
  final json =
      jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
  final snapshot = CatalogSnapshot.fromJson(
    json['catalog'] as Map<String, dynamic>,
  );
  if (snapshot.products.length != _fixtureCount) {
    throw StateError('Unexpected fixture count');
  }
  final auth = ProbeAuth();
  final services = AppServices(
    catalog: FixtureRepository(snapshot),
    auth: auth,
    media: LocalMediaManager(root: root),
    backup: FixtureBackup(),
    whatsapp: FixtureShare(),
  );
  runApp(RegressionProbe(services: services, auth: auth, output: support));
}

/// Deliberately synthetic: no PIN/secure-storage/backend is used by this probe.
class ProbeAuth extends AdminAuth {
  bool unlocked = false;
  @override
  bool get isAuthenticated => unlocked;
  @override
  bool get isConfigured => true;
  @override
  Duration get remainingLockout => Duration.zero;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> unlock(String pin) async {
    unlocked = true;
    notifyListeners();
    return true;
  }

  @override
  void lock() {
    unlocked = false;
    notifyListeners();
  }

  @override
  void requireAdmin() {
    if (!unlocked) throw StateError('Locked synthetic session');
  }

  @override
  void cancelRecovery() {}
  @override
  void cancelSetup() {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No credential writes');
}

class RegressionProbe extends StatefulWidget {
  const RegressionProbe({
    super.key,
    required this.services,
    required this.auth,
    required this.output,
  });
  final AppServices services;
  final ProbeAuth auth;
  final Directory output;
  @override
  State<RegressionProbe> createState() => _RegressionProbeState();
}

class _RegressionProbeState extends State<RegressionProbe> {
  final results = <Map<String, Object?>>[];
  final errors = <String>[];
  final appKey = GlobalKey();
  double scale = 1;
  bool reducedMotion = false;
  FlutterExceptionHandler? previousErrorHandler;

  @override
  void initState() {
    super.initState();
    previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
      previousErrorHandler?.call(details);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(run()));
  }

  Future<void> frame() {
    final done = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => done.complete());
    WidgetsBinding.instance.scheduleFrame();
    return done.future;
  }

  List<Element> elements() {
    final list = <Element>[];
    void visit(Element e) {
      list.add(e);
      e.visitChildren(visit);
    }

    final root = appKey.currentContext as Element?;
    if (root != null) visit(root);
    return list;
  }

  bool rendered(Element element) {
    var visible = true;
    element.visitAncestorElements((ancestor) {
      final w = ancestor.widget;
      if (w is Offstage && w.offstage) visible = false;
      return true;
    });
    return visible;
  }

  T widgetOf<T extends Widget>() =>
      elements().map((e) => e.widget).whereType<T>().first;
  bool get adminProtected =>
      elements().where((e) => e.widget is AdminHome).every((e) => !rendered(e));

  void emit(Map<String, Object?> result) {
    result['variant'] = _variant;
    results.add(result);
    debugPrint('PERF_JSON: ${jsonEncode(result)}');
  }

  Future<void> adminCycles() async {
    for (var i = 0; i < 10; i++) {
      final timer = Stopwatch()..start();
      widgetOf<CatalogView>().onAdmin();
      await frame();
      if (!adminProtected) throw StateError('Locked admin rendered on entry');
      await widget.auth.unlock('synthetic');
      await frame();
      final home = widgetOf<AdminHome>();
      if (adminProtected) {
        throw StateError('Synthetic unlocked admin not rendered');
      }
      widget.auth.lock();
      await frame();
      if (!adminProtected) throw StateError('Admin rendered after lock');
      home.onExit();
      await frame();
      emit({
        'kind': 'admin-cycle',
        'iteration': i,
        'elapsedMs': timer.elapsedMicroseconds / 1000,
        'lockedProtected': true,
        'animatedFrameBudget': 'N/A: IndexedStack switch, no route animation',
      });
    }
    // Immediate enter/exit and lock before another frame must not expose admin.
    final catalog = widgetOf<CatalogView>();
    catalog.onAdmin();
    widget.auth.lock();
    widgetOf<AdminHome>().onExit();
    await frame();
    if (!adminProtected) throw StateError('Rapid entry/exit exposed admin');
  }

  Future<void> traverse(String label) async {
    final seen = <String>{};
    final catalogElement = elements().firstWhere(
      (e) => e.widget is CatalogView,
    );
    final catalogElements = <Element>[];
    void collectCatalog(Element element) {
      catalogElements.add(element);
      element.visitChildren(collectCatalog);
    }

    collectCatalog(catalogElement);
    final scrollable = catalogElements
        .whereType<StatefulElement>()
        .where(rendered)
        .map((e) => e.state)
        .whereType<ScrollableState>()
        .firstWhere(
          (s) =>
              axisDirectionToAxis(s.axisDirection) == Axis.vertical &&
              s.position.hasContentDimensions &&
              s.position.viewportDimension > 200 &&
              s.position.maxScrollExtent > 100,
        );
    var position = scrollable.position;
    emit({
      'kind': 'traversal-scroll-target',
      'label': label,
      'axis': axisDirectionToAxis(scrollable.axisDirection).name,
      'viewportDimension': position.viewportDimension,
      'maxScrollExtent': position.maxScrollExtent,
    });
    position.jumpTo(0);
    await frame();
    for (var step = 0; step < 1000; step++) {
      // Theme/accessibility dependency changes can replace ScrollPosition.
      // Resource traversal uses stepped jumps, independently of frame benchmarks.
      position = scrollable.position;
      for (final tile
          in elements().map((e) => e.widget).whereType<ProductTile>()) {
        seen.add(tile.product.id);
      }
      if (position.pixels >= position.maxScrollExtent - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (position.pixels >= position.maxScrollExtent - 1) break;
      }
      final target = (position.pixels + 500).clamp(
        0.0,
        position.maxScrollExtent,
      );
      position.jumpTo(target);
      await frame();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    for (final tile
        in elements().map((e) => e.widget).whereType<ProductTile>()) {
      seen.add(tile.product.id);
    }
    final expected = widget.services.catalog.snapshot.products
        .where((p) => p.visible)
        .map((p) => p.id)
        .toSet();
    final missing = expected.difference(seen);
    final view = widgetOf<CatalogView>();
    final context = elements().firstWhere((e) => e.widget is CatalogView);
    final cache = PaintingBinding.instance.imageCache;
    emit({
      'kind': 'full-F$_fixtureCount-traversal',
      'label': label,
      'seenCount': seen.length,
      'expectedCount': expected.length,
      'missing': missing.toList(),
      'query': view.vm.query,
      'textScale16': MediaQuery.textScalerOf(context).scale(16),
      'brightness': Theme.of(context).brightness.name,
      'disableAnimations': MediaQuery.of(context).disableAnimations,
      'rssBytes': ProcessInfo.currentRss,
      'imageCacheBytes': cache.currentSizeBytes,
      'liveImages': cache.liveImageCount,
      'errorsSoFar': errors.length,
    });
    if (missing.isNotEmpty) {
      throw StateError(
        'Full traversal did not visit ${missing.length} products',
      );
    }
    position.jumpTo(0);
    await frame();
  }

  Future<void> detailCycles(String label) async {
    for (var i = 0; i < 10; i++) {
      final catalogElement = elements().firstWhere(
        (e) => e.widget is CatalogView,
      );
      final catalog = catalogElement.widget as CatalogView;
      final vm = catalog.vm;
      final navigator = Navigator.of(catalogElement);
      final id = vm.publicProducts[i].id;
      final route = MaterialPageRoute<void>(
        builder: (_) => ProductDetailView(id: id, vm: vm),
      );
      final timer = Stopwatch()..start();
      navigator.push(route);
      await frame();
      final openMs = timer.elapsedMicroseconds / 1000;
      if (vm.product(id) == null) {
        throw StateError('Detail lacks current fixture data');
      }
      final detailElement = elements().firstWhere(
        (e) => e.widget is ProductDetailView,
      );
      final motion = MediaQuery.of(detailElement).disableAnimations;
      // First usable frame permits placeholders; keep normal and reduced separate.
      emit({
        'kind': 'detail-usable',
        'label': label,
        'iteration': i,
        'productId': id,
        'openPostFrameMs': openMs,
        'disableAnimations': motion,
        'marker': 'Navigator.push to first Flutter post-frame with production detail data; raster/display completion excluded',
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      timer.reset();
      navigator.pop();
      await route.completed;
      await frame();
      emit({
        'kind': 'detail-return-usable',
        'label': label,
        'iteration': i,
        'returnPostFrameMs': timer.elapsedMicroseconds / 1000,
        'disableAnimations': motion,
      });
    }
    final context = elements().firstWhere((e) => e.widget is CatalogView);
    final catalog = context.widget as CatalogView;
    final navigator = Navigator.of(context);
    for (var i = 0; i < 3; i++) {
      final route = MaterialPageRoute<void>(
        builder: (_) => ProductDetailView(
          id: catalog.vm.publicProducts.first.id,
          vm: catalog.vm,
        ),
      );
      navigator.push(route);
      await frame();
      navigator.pop();
      await route.completed;
      await frame();
    }
    emit({
      'kind': 'rapid-detail-pop',
      'label': label,
      'cycles': 3,
      'errorsSoFar': errors.length,
    });
  }

  Future<void> run() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      await traverse('light-normal');
      await detailCycles('normal');
      await adminCycles();
      final old = widget.services.catalog.snapshot;
      await widget.services.catalog.replaceCatalog(
        CatalogSnapshot(
          categories: old.categories,
          products: old.products,
          settings: old.settings.copyWith(themeMode: 'dark'),
        ),
      );
      setState(() {
        scale = 1.6;
        reducedMotion = true;
      });
      await frame();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await frame();
      await traverse('dark-text1.6-reducedMotion');
      await detailCycles('reduced-motion');
      await adminCycles();
      emit({
        'kind': 'functional-summary',
        'errors': errors,
        'limits': [
          'Synthetic auth verifies UI protection, not secure storage/PIN security',
          'Programmatic callback navigation, not physical hit testing or system-back gestures',
          'Reduced movement inherited MediaQuery only; system setting and route-frame comparison separate',
          'Full traversal widget visitation includes lazy cache extent, not screenshot proof of every product',
          'Complementary resource checks, no before/after performance claims',
        ],
      });
    } catch (e, stack) {
      emit({
        'kind': 'failure',
        'error': '$e',
        'stack': '$stack',
        'errors': errors,
      });
    }
    final external = await getExternalStorageDirectory();
    final output = Directory(
      '${external?.path ?? widget.output.path}/performance',
    );
    await output.create(recursive: true);
    final file = File(
      '${output.path}/regression-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(
      jsonEncode({'variant': _variant, 'results': results}),
      flush: true,
    );
    debugPrint('PERF_SAVED: ${file.path}');
    final internal = await file.copy(
      '${widget.output.path}/${file.uri.pathSegments.last}',
    );
    debugPrint('PERF_INTERNAL_SAVED: ${internal.path}');
    debugPrint('PERF_DONE: regression');
  }

  @override
  void dispose() {
    FlutterError.onError = previousErrorHandler;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData.fromView(View.of(context)).copyWith(
      textScaler: TextScaler.linear(scale),
      disableAnimations: reducedMotion,
    ),
    child: CatalogApp(key: appKey, services: widget.services),
  );
}
