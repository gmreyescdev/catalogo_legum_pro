import 'package:flutter/material.dart';

import 'app/bootstrap.dart';
import 'contracts.dart';
import 'features/catalog_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LegumBootstrap());
}

class LegumBootstrap extends StatefulWidget {
  const LegumBootstrap({super.key});
  @override
  State<LegumBootstrap> createState() => _LegumBootstrapState();
}

class _LegumBootstrapState extends State<LegumBootstrap> {
  late Future<AppServices> _services;
  @override
  void initState() {
    super.initState();
    _services = createAppServices();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _services,
      builder: (context, snapshot) {
        if (snapshot.hasData) return CatalogApp(services: snapshot.data!);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF315C38),
            ),
          ),
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No se pudo abrir el catálogo. Tus datos no se han borrado.',
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() {
                                _services = createAppServices();
                              }),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(
                        semanticsLabel: 'Abriendo catálogo',
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
