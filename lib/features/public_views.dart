import 'package:flutter/material.dart';

import '../contracts.dart';
import '../ui/widgets.dart';
import 'view_models.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({super.key, required this.vm, required this.onAdmin});
  final CatalogViewModel vm;
  final VoidCallback onAdmin;
  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void clear() {
    search.clear();
    widget.vm.clearFilters();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.vm,
    builder: (context, _) {
      final vm = widget.vm;
      final products = vm.products;
      return PageFrame(
        title: 'Catálogo LegumPro',
        titleLeading: ClipOval(
          child: Image.asset(
            'assets/branding/legumpro-icon.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            semanticLabel: 'Logo LegumPro',
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: widget.onAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Administrar'),
          ),
        ],
        bottom: vm.selected.isEmpty
            ? null
            : FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SelectionView(vm: vm),
                  ),
                ),
                icon: const Icon(Icons.checklist),
                label: Text('Ver selección (${vm.selected.length})'),
              ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final margin = width < 600
                ? 12.0
                : width < 840
                ? 24.0
                : 32.0;
            const columns = 2;
            final rows = (products.length / columns).ceil();
            return ContentWidth(
              maxWidth: 1200,
              child: ListView.builder(
                padding: EdgeInsets.all(margin),
                itemCount: 2 + (products.isEmpty ? 1 : rows),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Builder(
                          builder: (buttonContext) => FilledButton.icon(
                            onPressed: vm.busy || vm.publicProducts.isEmpty
                                ? null
                                : () => vm.shareAll(
                                    sharePositionOrigin: _shareOrigin(
                                      buttonContext,
                                    ),
                                  ),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Compartir catálogo completo'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Incluye todos los productos visibles, aunque hayas aplicado filtros.',
                        ),
                        _ShareFeedback(vm: vm),
                        const SizedBox(height: 24),
                        SearchBar(
                          controller: search,
                          hintText: 'Nombre, descripción o SKU',
                          leading: const ExcludeSemantics(
                            child: Icon(Icons.search),
                          ),
                          onChanged: vm.setQuery,
                          trailing: [
                            if (search.text.isNotEmpty)
                              IconButton(
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  search.clear();
                                  vm.setQuery('');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                          ],
                        ),
                      ],
                    );
                  }
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Todas'),
                            selected: vm.categoryId == null,
                            onSelected: (_) => vm.setCategory(null),
                          ),
                          for (final c in vm.categories)
                            FilterChip(
                              label: Text(c.name),
                              selected: vm.categoryId == c.id,
                              onSelected: (_) => vm.setCategory(c.id),
                            ),
                        ],
                      ),
                    );
                  }
                  if (products.isEmpty) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            vm.publicProducts.isEmpty
                                ? 'No hay productos disponibles'
                                : 'No se encontraron productos',
                          ),
                        ),
                        if (vm.query.isNotEmpty || vm.categoryId != null)
                          TextButton(
                            onPressed: clear,
                            child: const Text('Limpiar filtros'),
                          ),
                      ],
                    );
                  }
                  final start = (index - 2) * columns;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var col = 0; col < columns; col++) ...[
                          if (col > 0) const SizedBox(width: 12),
                          Expanded(
                            child: start + col < products.length
                                ? ProductTile(
                                    product: products[start + col],
                                    vm: vm,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    },
  );
}

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.vm});
  final Product product;
  final CatalogViewModel vm;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailView(id: product.id, vm: vm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Abrir detalle de ${product.name}',
          onTap: () => _openDetail(context),
          child: Stack(
            children: [
              ProductPhoto(
                media: vm.services.media,
                image: product.images.firstOrNull,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    excludeFromSemantics: true,
                    onTap: () => _openDetail(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            product.name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Semantics(
          label: product.name,
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.only(right: 6),
            dense: false,
            value: vm.isSelected(product.id),
            onChanged: (_) => vm.toggle(product.id),
            title: Text(
              'Incluir en PDF',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    ),
  );
}

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({super.key, required this.id, required this.vm});
  final String id;
  final CatalogViewModel vm;
  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int photo = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.vm,
    builder: (context, _) {
      final vm = widget.vm;
      final p = vm.product(widget.id);
      if (p == null) {
        return PageFrame(
          title: 'Producto no disponible',
          onBack: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Este producto ya no está disponible en el catálogo.'),
          ),
        );
      }
      if (photo >= p.images.length) photo = 0;
      return PageFrame(
        title: 'Detalle',
        onBack: () => Navigator.pop(context),
        child: ContentWidth(
          maxWidth: 800,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ProductPhoto(
                media: vm.services.media,
                image: p.images.isEmpty ? null : p.images[photo],
                label: '${p.name}, foto ${photo + 1} de ${p.images.length}',
                fit: BoxFit.cover,
              ),
              if (p.images.length > 1)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Foto anterior',
                      onPressed: photo > 0
                          ? () => setState(() => photo--)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Foto ${photo + 1} de ${p.images.length}'),
                    IconButton(
                      tooltip: 'Foto siguiente',
                      onPressed: photo + 1 < p.images.length
                          ? () => setState(() => photo++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(p.presentation),
              Text(p.available ? 'Disponible' : 'Agotado'),
              const SizedBox(height: 12),
              Prices(p, perKilogram: true),
              const SizedBox(height: 12),
              Text('Categoría: ${vm.categoryName(p.categoryId)}'),
              Text('SKU: ${p.sku}'),
              const SizedBox(height: 16),
              Text(p.description, style: Theme.of(context).textTheme.bodyLarge),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: vm.isSelected(p.id),
                onChanged: (_) => vm.toggle(p.id),
                title: const Text('Incluir en selección'),
              ),
              const Text(
                'Revisa tu selección para compartir un catálogo PDF con tus clientes.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: vm.selected.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SelectionView(vm: vm),
                        ),
                      ),
                icon: const Icon(Icons.checklist),
                label: Text('Ver selección (${vm.selected.length})'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SelectionView extends StatelessWidget {
  const SelectionView({super.key, required this.vm});
  final CatalogViewModel vm;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => PageFrame(
      title: 'Catálogo PDF seleccionado',
      onBack: () => Navigator.pop(context),
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (vm.selected.isEmpty)
              const Text('No hay productos seleccionados.'),
            for (final p in vm.selected)
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ProductPhoto(
                        media: vm.services.media,
                        image: p.images.firstOrNull,
                        label: 'Portada de ${p.name}',
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 12),
                      Text(p.presentation),
                      Prices(p),
                      Text(p.available ? 'Disponible' : 'Agotado'),
                      TextButton.icon(
                        onPressed: vm.busy ? null : () => vm.toggle(p.id),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: Text('Quitar ${p.name}'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'El PDF incluye solo esta selección, con imagen, presentación, precio y disponibilidad. Elige WhatsApp y el cliente en el menú para compartir; confirma el envío allí.',
            ),
            _ShareFeedback(vm: vm),
            const SizedBox(height: 24),
            Builder(
              builder: (buttonContext) => FilledButton.icon(
                onPressed: vm.busy || vm.selected.isEmpty
                    ? null
                    : () async {
                        await vm.shareSelected(
                          sharePositionOrigin: _shareOrigin(buttonContext),
                        );
                      },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Compartir selección'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Rect? _shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box != null && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
}

class _ShareFeedback extends StatelessWidget {
  const _ShareFeedback({required this.vm});
  final CatalogViewModel vm;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ErrorMessage(vm.error),
      if (vm.busy) ...[
        const SizedBox(height: 16),
        const LinearProgressIndicator(
          semanticsLabel: 'Preparando catálogo PDF',
        ),
        const SizedBox(height: 8),
        const Text('Preparando catálogo para compartir…'),
      ],
    ],
  );
}
