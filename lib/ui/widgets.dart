import 'package:flutter/material.dart';

import '../contracts.dart';
import '../features/view_models.dart';
import 'layout_image_provider.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onBack,
    this.bottom,
    this.titleLeading,
    this.navigation,
    this.floatingActionButton,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Widget? bottom;
  final Widget? titleLeading;
  final Widget? navigation;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: navigation,
    floatingActionButton: floatingActionButton,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          onPressed: onBack,
                          tooltip: 'Volver',
                          icon: const Icon(Icons.arrow_back),
                        ),
                      if (titleLeading != null) ...[
                        titleLeading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 4, children: actions),
                ],
              ),
            ),
          ),
          Expanded(child: child),
          if (bottom != null)
            Padding(padding: const EdgeInsets.all(12), child: bottom!),
        ],
      ),
    ),
  );
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
}

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    super.key,
    required this.media,
    this.image,
    this.label,
    this.fit = BoxFit.contain,
  });
  final MediaManager media;
  final ProductImage? image;
  final String? label;
  final BoxFit fit;
  Widget placeholder(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Imagen no disponible', textAlign: TextAlign.center),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final picture = AspectRatio(
      aspectRatio: 4 / 3,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (image == null) return placeholder(context);
            try {
              ImageProvider provider = media.imageProvider(image!.path);
              final dpr = MediaQuery.devicePixelRatioOf(context);
              final width = constraints.maxWidth * dpr;
              final height = constraints.maxHeight * dpr;
              if ((fit == BoxFit.cover || fit == BoxFit.contain) &&
                  width.isFinite &&
                  height.isFinite &&
                  width > 0 &&
                  height > 0) {
                provider = LayoutImageProvider(
                  provider,
                  width: width.ceil(),
                  height: height.ceil(),
                  fit: fit,
                );
              }
              return Image(
                image: provider,
                fit: fit,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => placeholder(context),
              );
            } catch (_) {
              return placeholder(context);
            }
          },
        ),
      ),
    );
    // Real photos are decorative unless a gallery label is supplied. A failed
    // photo's textual fallback remains audible in either context.
    return label == null
        ? picture
        : Semantics(image: true, label: label, child: picture);
  }
}

class Prices extends StatelessWidget {
  const Prices(this.product, {super.key, this.perKilogram = false});
  final Product product;
  final bool perKilogram;
  String get _unitSuffix => perKilogram ? ' x Kg' : '';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (product.saleClp != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Text(
            'Oferta',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
        ),
        Text(
          'Precio normal: ${clp(product.normalClp)}$_unitSuffix',
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
      ],
      Text(
        '${product.saleClp != null ? 'Precio oferta' : 'Precio'}: ${clp(product.currentClp)}$_unitSuffix',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ],
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String confirm = 'Confirmar',
}) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;

void showFeedback(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Widget moveButtons({
  required String name,
  required VoidCallback? up,
  required VoidCallback? down,
}) => Wrap(
  children: [
    IconButton(
      onPressed: up,
      tooltip: 'Subir $name',
      icon: const Icon(Icons.arrow_upward),
    ),
    IconButton(
      onPressed: down,
      tooltip: 'Bajar $name',
      icon: const Icon(Icons.arrow_downward),
    ),
  ],
);
