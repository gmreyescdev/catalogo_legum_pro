import 'package:flutter/material.dart';

import '../contracts.dart';
import '../ui/theme.dart';
import 'admin_views.dart';
import 'public_views.dart';
import 'view_models.dart';

class CatalogApp extends StatefulWidget {
  const CatalogApp({super.key, required this.services});
  final AppServices services;
  @override
  State<CatalogApp> createState() => _CatalogAppState();
}

class _CatalogAppState extends State<CatalogApp> with WidgetsBindingObserver {
  late final catalog = CatalogViewModel(widget.services);
  late final auth = AuthViewModel(widget.services.auth);
  late final admin = AdminViewModel(widget.services);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.services.auth.lock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    catalog.dispose();
    auth.dispose();
    admin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.services.catalog,
    builder: (context, _) {
      final mode = widget.services.catalog.snapshot.settings.themeMode;
      return MaterialApp(
        title: 'Catálogo LegumPro',
        debugShowCheckedModeBanner: false,
        theme: catalogTheme(Brightness.light),
        darkTheme: catalogTheme(Brightness.dark),
        themeMode: mode == 'light'
            ? ThemeMode.light
            : mode == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system,
        home: AppShell(catalog: catalog, admin: admin, auth: auth),
      );
    },
  );
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.catalog,
    required this.admin,
    required this.auth,
  });
  final CatalogViewModel catalog;
  final AdminViewModel admin;
  final AuthViewModel auth;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool adminActive = false;
  final adminNavigator = GlobalKey<NavigatorState>();
  void exit() {
    widget.auth.auth.lock();
    setState(() => adminActive = false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !adminActive,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        if (widget.auth.auth.isAuthenticated &&
            widget.auth.auth.isConfigured &&
            adminNavigator.currentState?.canPop() == true) {
          adminNavigator.currentState!.maybePop();
        } else {
          exit();
        }
      }
    },
    child: IndexedStack(
      index: adminActive ? 1 : 0,
      children: [
        CatalogView(
          vm: widget.catalog,
          onAdmin: () => setState(() => adminActive = true),
        ),
        ListenableBuilder(
          listenable: widget.auth,
          builder: (context, _) {
            final unlocked =
                widget.auth.auth.isAuthenticated &&
                widget.auth.auth.isConfigured;
            // Keep the nested route/form subtree alive but never render it while locked.
            return Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: !unlocked,
                  child: TickerMode(
                    enabled: unlocked,
                    child: Navigator(
                      key: adminNavigator,
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => AdminHome(
                          vm: widget.admin,
                          auth: widget.auth,
                          catalog: widget.catalog,
                          onExit: exit,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!unlocked) AuthPanel(vm: widget.auth, onCancel: exit),
              ],
            );
          },
        ),
      ],
    ),
  );
}
