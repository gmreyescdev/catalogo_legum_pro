// Ordinary application entrypoint, intentionally NOT an integration_test runner.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

import 'package:catalogo_legum_pro/contracts.dart';
import 'package:catalogo_legum_pro/data/local_media_manager.dart';
import 'package:catalogo_legum_pro/features/public_views.dart';
import 'package:catalogo_legum_pro/features/view_models.dart';
import 'package:catalogo_legum_pro/ui/theme.dart';

import 'performance/fixture.dart';

final _mainClock = Stopwatch()..start();
const _variant = String.fromEnvironment('PERF_RUN', defaultValue: 'baseline');
const _startupOnly = bool.fromEnvironment('PERF_STARTUP_ONLY');

Future<void> main() async {
  _mainClock.reset(); // Force lazy initialization at Dart main entry, not first frame.
  WidgetsFlutterBinding.ensureInitialized();
  if (!kProfileMode) {
    throw StateError('Performance entrypoint requires --profile');
  }
  // Establish the native rendering surface before generating raster fixtures.
  // Preparation is outside all measured windows and is identical in both builds.
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Preparando prueba de rendimiento…')),
      ),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
  final documents = await getApplicationDocumentsDirectory();
  final root = Directory('${documents.path}/performance-fixture-v1');
  await root.create(recursive: true);
  debugPrint('PERF_PREPARING: $_variant');
  final fixture = await prepareFixture(root, 20);
  final repo = FixtureRepository(fixture);
  final services = AppServices(
    catalog: repo,
    auth: FixtureAuth(),
    media: LocalMediaManager(root: root),
    backup: FixtureBackup(),
    whatsapp: FixtureShare(),
  );
  runApp(PerformanceApp(services: services, root: root));
}

class PerformanceApp extends StatefulWidget {
  const PerformanceApp({super.key, required this.services, required this.root});
  final AppServices services;
  final Directory root;
  @override
  State<PerformanceApp> createState() => _PerformanceAppState();
}

class _PerformanceAppState extends State<PerformanceApp> {
  final navigator = GlobalKey<NavigatorState>();
  late final vm = CatalogViewModel(widget.services);
  final frames = <Map<String, Object>>[];
  final windows = <Map<String, Object>>[];
  final results = <Map<String, Object?>>[];
  final clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(recordFrames);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      emit({
        'kind': 'startup',
        'dartMainToUsableMs': _mainClock.elapsedMicroseconds / 1000,
        'marker': 'Dart main to first production catalog post-frame; excludes native process startup',
        'publicProducts': vm.publicProducts.length,
        'fixturePreparationIncluded': true,
      });
      unawaited(runProtocol());
    });
  }

  void recordFrames(List<ui.FrameTiming> timings) {
    for (final t in timings) {
      frames.add({
        'startUs': t.timestampInMicroseconds(ui.FramePhase.buildStart),
        'buildUs': t.buildDuration.inMicroseconds,
        'rasterUs': t.rasterDuration.inMicroseconds,
        'totalUs': t.totalSpan.inMicroseconds,
        'observedHzAtCallback':
            ui.PlatformDispatcher.instance.views.first.display.refreshRate,
      });
    }
  }

  void emit(Map<String, Object?> result) {
    results.add(result);
    debugPrint('PERF_JSON: ${jsonEncode(result)}');
  }

  Future<void> visibleFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    WidgetsBinding.instance.scheduleFrame();
    return completer.future;
  }

  int engineNow() => developer.Timeline.now;

  Future<void> window(String name, Future<void> Function() action) async {
    final start = engineNow();
    await action();
    final end = engineNow();
    windows.add({'name': name, 'startUs': start, 'endUs': end});
    emit({
      'kind': 'window',
      'name': name,
      'startUs': start,
      'endUs': end,
      'durationMs': (end - start) / 1000,
    });
  }

  Iterable<Element> elements() sync* {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    final all = <Element>[];
    void visit(Element e) {
      all.add(e);
      e.visitChildren(visit);
    }

    visit(root);
    yield* all;
  }

  ScrollPosition get catalogPosition {
    for (final element in elements()) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final state = element.state as ScrollableState;
        if (state.position.hasContentDimensions &&
            state.position.maxScrollExtent > 100) {
          return state.position;
        }
      }
    }
    throw StateError('No production catalog ScrollPosition found');
  }

  Future<void> scroll(
    String name, {
    int seconds = 30,
  }) => window(name, () async {
    final position = catalogPosition;
    position.jumpTo(0);
    await visibleFrame();
    // Fixed 900 logical px/s segments; reverse at edges and preserve wall time.
    var down = true;
    for (var i = 0; i < seconds; i++) {
      final segment = Stopwatch()..start();
      if (position.pixels >= position.maxScrollExtent - 1) down = false;
      if (position.pixels <= 1) down = true;
      final target = down
          ? (position.pixels + 900).clamp(0.0, position.maxScrollExtent)
          : (position.pixels - 900).clamp(0.0, position.maxScrollExtent);
      await position.animateTo(
        target,
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
      );
      final remaining = 1000000 - segment.elapsedMicroseconds;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(microseconds: remaining));
      }
    }
    position.jumpTo(0);
    await visibleFrame();
  });

  Future<void> latency(String kind, int iteration, VoidCallback action) async {
    final timer = Stopwatch()..start();
    action();
    await visibleFrame();
    emit({
      'kind': kind,
      'iteration': iteration,
      'latencyMs': timer.elapsedMicroseconds / 1000,
      'ids': vm.products.map((p) => p.id).toList(),
      'selected': vm.selected.map((p) => p.id).toList(),
      'query': vm.query,
      'categoryId': vm.categoryId,
    });
  }

  Future<void> transition(String name, Widget page) async {
    final route = MaterialPageRoute<void>(builder: (_) => page);
    await window('$name.push', () async {
      navigator.currentState!.push(route);
      await visibleFrame();
      final animation = route.animation!;
      if (animation.status != AnimationStatus.completed) {
        final done = Completer<void>();
        void listener(AnimationStatus s) {
          if (s == AnimationStatus.completed && !done.isCompleted) {
            done.complete();
          }
        }

        animation.addStatusListener(listener);
        await done.future;
        animation.removeStatusListener(listener);
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await window('$name.pop', () async {
      navigator.currentState!.pop();
      await route.completed;
    });
    await visibleFrame();
  }

  void memory(String label) {
    final cache = PaintingBinding.instance.imageCache;
    emit({
      'kind': 'memory',
      'label': label,
      'rssBytes': ProcessInfo.currentRss,
      'maxRssBytes': ProcessInfo.maxRss,
      'imageCacheBytes': cache.currentSizeBytes,
      'imageCacheCount': cache.currentSize,
      'liveImages': cache.liveImageCount,
      'pendingImages': cache.pendingImageCount,
    });
  }

  Future<void> decodedProbe() async {
    // Run after primary F20 timings, so resolving a stream cannot warm baseline.
    for (final element in elements()) {
      final imageWidget = element.widget;
      if (imageWidget is! Image || imageWidget.image is AssetImage) continue;
      final render = element.findRenderObject();
      final size = render is RenderBox && render.hasSize ? render.size : null;
      final stream = imageWidget.image.resolve(
        createLocalImageConfiguration(element),
      );
      final completer = Completer<void>();
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, synchronous) {
          emit({
            'kind': 'decode-probe',
            'provider': '${imageWidget.image.runtimeType}',
            'width': info.image.width,
            'height': info.image.height,
            'rgbaBytes': info.image.width * info.image.height * 4,
            'logicalWidth': size?.width,
            'logicalHeight': size?.height,
            'dpr': MediaQuery.devicePixelRatioOf(element),
          });
          info.dispose();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object error, StackTrace? stack) {
          emit({'kind': 'decode-probe-error', 'error': '$error'});
          if (!completer.isCompleted) completer.complete();
        },
      );
      stream.addListener(listener);
      await completer.future.timeout(const Duration(seconds: 15));
      stream.removeListener(listener);
      return;
    }
    emit({
      'kind': 'decode-probe-error',
      'error': 'No mounted product Image found',
    });
  }

  Future<void> runProtocol() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_startupOnly) {
        await save();
        return;
      }
      final view = ui.PlatformDispatcher.instance.views.first;
      emit({
        'kind': 'configuration',
        'variant': _variant,
        'profile': kProfileMode,
        'dpr': view.devicePixelRatio,
        'physicalWidth': view.physicalSize.width,
        'physicalHeight': view.physicalSize.height,
        'fixtureVersion': 1,
        'sqlBootstrapMeasured': false,
        'adminTransitionMeasured': false,
        'disableAnimations': MediaQuery.of(navigator.currentContext!)
            .disableAnimations,
      });
      memory('initial');
      await scroll('first-pass');
      for (var i = 0; i < 3; i++) {
        await scroll('warm-scroll-$i');
      }
      const queries = ['', 'ágil', 'QA-1', 'sin coincidencias', 'Legumbre'];
      for (var i = 0; i < 20; i++) {
        final bar = elements()
            .map((e) => e.widget)
            .whereType<SearchBar>()
            .firstOrNull;
        await latency('search', i, () {
          vm.setCategory(i % 2 == 0 ? null : 'category_${i % 5}');
          bar?.controller?.text = queries[i % queries.length];
          if (bar?.onChanged != null) {
            bar!.onChanged!(queries[i % queries.length]);
          } else {
            vm.setQuery(queries[i % queries.length]);
          }
        });
      }
      vm.clearFilters();
      await visibleFrame();
      for (var i = 0; i < 20; i++) {
        await latency(
          'selection',
          i,
          () => vm.toggle(vm.publicProducts[i % 10].id),
        );
      }
      vm.toggle(vm.publicProducts.first.id);
      await visibleFrame();
      for (var i = 0; i < 10; i++) {
        await transition(
          'detail-$i',
          ProductDetailView(
            id: vm.publicProducts[i % vm.publicProducts.length].id,
            vm: vm,
          ),
        );
        await transition('selection-$i', SelectionView(vm: vm));
      }
      for (var i = 0; i < 5; i++) {
        await scroll('retention-$i', seconds: 4);
        await transition(
          'retention-detail-$i',
          ProductDetailView(id: vm.publicProducts.first.id, vm: vm),
        );
        await Future<void>.delayed(const Duration(seconds: 2));
        memory('retention-$i');
      }
      await decodedProbe();
      final stress = await prepareFixture(widget.root, 100);
      await widget.services.catalog.replaceCatalog(stress);
      vm.clearFilters();
      await visibleFrame();
      await scroll('stress-100', seconds: 10);
      await transition(
        'stress-detail',
        ProductDetailView(id: vm.publicProducts.last.id, vm: vm),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      memory('stress-100');
      await save();
      debugPrint('PERF_DONE: $_variant');
    } catch (e, stack) {
      emit({'kind': 'failure', 'error': '$e', 'stack': '$stack'});
      await save();
    }
  }

  Future<void> save() async {
    // FrameTiming callbacks are batched; classify by engine timestamps after delivery.
    await Future<void>.delayed(const Duration(seconds: 2));
    final external = await getExternalStorageDirectory();
    final output = Directory(
      '${external?.path ?? widget.root.path}/performance',
    );
    await output.create(recursive: true);
    for (final count in [20, 100]) {
      final manifest = File('${widget.root.path}/fixture-$count-v1.json');
      if (await manifest.exists()) {
        await manifest.copy('${output.path}/fixture-$count-v1.json');
      }
    }
    final file = File(
      '${output.path}/results-$_variant-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(
      jsonEncode({
        'variant': _variant,
        'results': results,
        'windows': windows,
        'frames': frames,
        'limitations': [
          'In-memory repository; SQL/bootstrap/native process startup not measured',
          'Harness invokes production route widgets with identical MaterialPageRoute, not gesture hit-testing',
          'Admin authentication transitions and reduced-motion comparison require separate validation',
          'Input latency ends at post-frame, before physical display presentation',
          'Stress scroll traverses a subset of 100 products plus opens the last detail; not full traversal',
          'Fixtures use landscape 4:3 only; portrait/panorama/fallback require separate regression checks',
          'RSS from ProcessInfo; PSS must be collected separately via dumpsys meminfo',
        ],
      }),
      flush: true,
    );
    debugPrint('PERF_SAVED: ${file.path}');
    // Android's scoped external storage can deny shell/run-as reads. Keep an
    // identical private copy after all measured windows for reliable collection.
    final internal = await file.copy(
      '${widget.root.path}/${file.uri.pathSegments.last}',
    );
    debugPrint('PERF_INTERNAL_SAVED: ${internal.path}');
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(recordFrames);
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    debugShowCheckedModeBanner: false,
    theme: catalogTheme(Brightness.light),
    home: CatalogView(vm: vm, onAdmin: () {}),
  );
}
