import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../contracts.dart';
import '../ui/widgets.dart';
import 'view_models.dart';

class AuthPanel extends StatefulWidget {
  const AuthPanel({super.key, required this.vm, required this.onCancel});
  final AuthViewModel vm;
  final VoidCallback onCancel;
  @override
  State<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<AuthPanel> {
  final pin = TextEditingController(),
      code = TextEditingController(),
      confirmation = TextEditingController();
  bool recovering = false, acknowledged = false;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pin.dispose();
    code.dispose();
    confirmation.dispose();
    super.dispose();
  }

  void cancel() {
    widget.vm.cancelRecovery();
    widget.vm.cancelSetup();
    pin.clear();
    code.clear();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.vm,
    builder: (context, _) {
      final vm = widget.vm;
      final recovery = vm.recoveryCode;
      final setup = vm.setupCode;
      final shownCode = recovery ?? setup;
      final wait = (vm.auth.remainingLockout.inMilliseconds + 999) ~/ 1000;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) cancel();
        },
        child: PageFrame(
          title: shownCode != null
              ? 'Guarda tu código de recuperación'
              : recovering
              ? 'Recuperar acceso'
              : 'Acceso a administración',
          onBack: cancel,
          child: ContentWidth(
            maxWidth: 480,
            child: ListView(
              padding: EdgeInsets.all(_adminPageMargin(context)),
              children: [
                _AdminSectionHeader(
                  icon: shownCode != null
                      ? Icons.key_outlined
                      : recovering
                      ? Icons.lock_reset_outlined
                      : Icons.admin_panel_settings_outlined,
                  title: shownCode != null
                      ? 'Protege tu acceso'
                      : recovering
                      ? 'Recupera tu acceso'
                      : 'Administra tu catálogo',
                  description: shownCode != null
                      ? 'Conserva tu código de recuperación en un lugar seguro.'
                      : recovering
                      ? 'Verifica tu identidad para crear un nuevo PIN.'
                      : 'Ingresa tu PIN para gestionar productos, categorías y ajustes.',
                ),
                const SizedBox(height: 24),
                if (shownCode != null) ...[
                  const Text(
                    'Guarda este código fuera de la app. Lo necesitarás si olvidas tu PIN. El catálogo se conservará.',
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    shownCode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  CheckboxListTile(
                    value: acknowledged,
                    onChanged: vm.busy
                        ? null
                        : (value) =>
                              setState(() => acknowledged = value ?? false),
                    title: const Text('He guardado el código'),
                  ),
                  const SizedBox(height: 24),
                  ErrorMessage(vm.error),
                  FilledButton(
                    style: _adminActionStyle,
                    onPressed: !acknowledged || vm.busy
                        ? null
                        : () async {
                            final ok = recovery != null
                                ? await vm.confirmRecovery()
                                : await vm.confirmSetup();
                            if (ok && mounted) {
                              pin.clear();
                              code.clear();
                              confirmation.clear();
                              setState(() {
                                recovering = false;
                                acknowledged = false;
                              });
                            }
                          },
                    child: const Text('Confirmar código guardado'),
                  ),
                ] else ...[
                  Text(
                    recovering
                        ? 'Ingresa tu código de recuperación y define un nuevo PIN.'
                        : 'El catálogo es público. Este PIN protege los cambios locales.',
                  ),
                  if (recovering)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextField(
                        controller: code,
                        decoration: const InputDecoration(
                          labelText: 'Código de recuperación',
                        ),
                        autocorrect: false,
                      ),
                    ),
                  const SizedBox(height: 16),
                  pinField(
                    pin,
                    recovering ? 'Nuevo PIN de 4 dígitos' : 'PIN de 4 dígitos',
                  ),
                  if (recovering)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: pinField(confirmation, 'Confirmar nuevo PIN'),
                    ),
                  if (wait > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Espera $wait segundos antes de volver a intentar.',
                      ),
                    ),
                  const SizedBox(height: 24),
                  ErrorMessage(vm.error),
                  FilledButton(
                    style: _adminActionStyle,
                    onPressed: vm.busy || (!recovering && wait > 0)
                        ? null
                        : () async {
                            if (recovering) {
                              await vm.recover(
                                code.text,
                                pin.text,
                                confirmation.text,
                              );
                            } else {
                              await vm.unlock(pin.text);
                            }
                            if (!mounted) return;
                            pin.clear();
                            confirmation.clear();
                          },
                    child: vm.busy
                        ? const _AdminLoadingLabel()
                        : Text(recovering ? 'Generar nuevo acceso' : 'Entrar'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    style: _adminActionStyle,
                    onPressed: vm.busy
                        ? null
                        : () {
                            pin.clear();
                            setState(() => recovering = !recovering);
                          },
                    child: Text(
                      recovering ? 'Volver al PIN' : 'Recuperar acceso',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  style: _adminActionStyle,
                  onPressed: vm.busy ? null : cancel,
                  child: const Text('Volver al catálogo'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

final _adminActionStyle = ButtonStyle(
  minimumSize: WidgetStateProperty.all(const Size(48, 48)),
  padding: WidgetStateProperty.all(
    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);

class _AdminLoadingLabel extends StatelessWidget {
  const _AdminLoadingLabel();
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
          semanticsLabel: 'Procesando acceso',
        ),
      ),
      const Text('Procesando…'),
    ],
  );
}

class _AdminSectionHeader extends StatelessWidget {
  const _AdminSectionHeader({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

double _adminPageMargin(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width >= 840
      ? 32
      : width >= 600
      ? 24
      : 16;
}

Widget pinField(TextEditingController controller, String label) => TextField(
  controller: controller,
  obscureText: true,
  enableSuggestions: false,
  autocorrect: false,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(4),
  ],
  decoration: InputDecoration(labelText: label),
);

class AdminHome extends StatefulWidget {
  const AdminHome({
    super.key,
    required this.vm,
    required this.auth,
    required this.catalog,
    required this.onExit,
  });
  final AdminViewModel vm;
  final AuthViewModel auth;
  final CatalogViewModel catalog;
  final VoidCallback onExit;
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int tab = 0;

  void addProduct() {
    widget.vm.services.auth.requireAdmin();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductEditorView(services: widget.vm.services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.vm,
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 600;
      final compactFab =
          MediaQuery.sizeOf(context).width < 360 ||
          MediaQuery.textScalerOf(context).scale(16) >= 24;
      final body = Column(
        children: [
          if (widget.vm.busy)
            const LinearProgressIndicator(
              semanticsLabel: 'Procesando operación local',
            ),
          if (widget.vm.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ErrorMessage(widget.vm.error),
            ),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: [
                AdminProducts(vm: widget.vm),
                AdminCategories(vm: widget.vm),
                AdminSettings(
                  vm: widget.vm,
                  auth: widget.auth,
                  catalog: widget.catalog,
                ),
              ],
            ),
          ),
        ],
      );
      return PageFrame(
        title: 'Administración',
        onBack: widget.onExit,
        navigation: wide
            ? null
            : NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (value) => setState(() => tab = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: 'Productos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.category_outlined),
                    selectedIcon: Icon(Icons.category),
                    label: 'Categorías',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Ajustes',
                  ),
                ],
              ),
        floatingActionButton: tab != 0 || widget.vm.busy
            ? null
            : compactFab
            ? FloatingActionButton(
                tooltip: 'Añadir producto',
                onPressed: addProduct,
                child: const Icon(Icons.add),
              )
            : FloatingActionButton.extended(
                tooltip: 'Añadir producto',
                onPressed: addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
              ),
        child: !wide
            ? body
            : Row(
                children: [
                  NavigationRail(
                    selectedIndex: tab,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (value) =>
                        setState(() => tab = value),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2),
                        label: Text('Productos'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.category_outlined),
                        selectedIcon: Icon(Icons.category),
                        label: Text('Categorías'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text('Ajustes'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
      );
    },
  );
}

class AdminProducts extends StatelessWidget {
  const AdminProducts({super.key, required this.vm});
  final AdminViewModel vm;
  void edit(BuildContext context, Product? p) {
    vm.services.auth.requireAdmin();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductEditorView(services: vm.services, product: p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ContentWidth(
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      itemCount: vm.products.isEmpty ? 1 : vm.products.length,
      itemBuilder: (context, index) => vm.products.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Todavía no hay productos. Usa + para crear el primero.',
              ),
            )
          : _product(context, vm.products[index], index),
    ),
  );
  Widget _product(BuildContext context, Product p, int index) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 12),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductPhoto(
                    media: vm.services.media,
                    image: p.images.firstOrNull,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${p.sku}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Prices(p),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AdminStatus(p.visible ? 'Público' : 'Oculto'),
              _AdminStatus(p.available ? 'Disponible' : 'Agotado'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'Editar ${p.name}',
                onPressed: vm.busy ? null : () => edit(context, p),
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones de ${p.name}',
                enabled: !vm.busy,
                onSelected: (action) async {
                  if (action == 'visibility') {
                    await vm.toggleProduct(p, visibility: true);
                  } else if (action == 'availability') {
                    await vm.toggleProduct(p);
                  } else if (action == 'delete' &&
                      context.mounted &&
                      await confirmAction(
                        context,
                        'Eliminar producto',
                        '¿Eliminar ${p.name}? Esta acción no se puede deshacer.',
                        confirm: 'Eliminar',
                      )) {
                    await vm.deleteProduct(p.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'visibility',
                    child: Text(p.visible ? 'Ocultar' : 'Mostrar'),
                  ),
                  PopupMenuItem(
                    value: 'availability',
                    child: Text(
                      p.available ? 'Marcar agotado' : 'Marcar disponible',
                    ),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
              moveButtons(
                name: p.name,
                up: vm.busy || index == 0
                    ? null
                    : () => vm.moveProduct(index, -1),
                down: vm.busy || index == vm.products.length - 1
                    ? null
                    : () => vm.moveProduct(index, 1),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AdminStatus extends StatelessWidget {
  const _AdminStatus(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
    ),
  );
}

class AdminCategories extends StatelessWidget {
  const AdminCategories({super.key, required this.vm});
  final AdminViewModel vm;
  String productCount(String categoryId) {
    final count = vm.products.where((p) => p.categoryId == categoryId).length;
    return '$count ${count == 1 ? 'producto' : 'productos'}';
  }

  Future<void> edit(BuildContext context, Category? category) async {
    vm.services.auth.requireAdmin();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryEditor(vm: vm, category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ContentWidth(
    child: ListView(
      padding: EdgeInsets.all(_adminPageMargin(context)),
      children: [
        _AdminSectionHeader(
          icon: Icons.category_outlined,
          title: 'Organiza tus productos',
          description:
              '${vm.categories.length} ${vm.categories.length == 1 ? 'categoría' : 'categorías'} · ${vm.products.length} ${vm.products.length == 1 ? 'producto' : 'productos'}',
        ),
        const SizedBox(height: 16),
        const Text(
          'Agrupa tus productos y ajusta el orden en que aparecen las categorías.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: _adminActionStyle,
          onPressed: vm.busy ? null : () => edit(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Añadir categoría'),
        ),
        const SizedBox(height: 24),
        if (vm.categories.isEmpty)
          Card.outlined(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: _AdminSectionHeader(
                icon: Icons.create_new_folder_outlined,
                title: 'Todavía no hay categorías',
                description:
                    'Añade tu primera categoría para organizar los productos.',
              ),
            ),
          ),
        for (var i = 0; i < vm.categories.length; i++)
          Card.outlined(
            margin: const EdgeInsets.only(bottom: 16),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.categories[i].name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              productCount(vm.categories[i].id),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      TextButton(
                        style: _adminActionStyle,
                        onPressed: vm.busy
                            ? null
                            : () => edit(context, vm.categories[i]),
                        child: const Text('Editar'),
                      ),
                      TextButton(
                        style: _adminActionStyle,
                        onPressed: vm.busy
                            ? null
                            : () async {
                                final c = vm.categories[i];
                                if (await confirmAction(
                                  context,
                                  'Eliminar categoría',
                                  '¿Eliminar ${c.name}? Si tiene productos, debes reasignarlos o eliminarlos primero.',
                                  confirm: 'Eliminar',
                                )) {
                                  await vm.deleteCategory(c.id);
                                }
                              },
                        child: const Text('Eliminar'),
                      ),
                      IconButton(
                        tooltip: 'Subir ${vm.categories[i].name}',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: vm.busy || i == 0
                            ? null
                            : () => vm.moveCategory(i, -1),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Bajar ${vm.categories[i].name}',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: vm.busy || i == vm.categories.length - 1
                            ? null
                            : () => vm.moveCategory(i, 1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({super.key, required this.vm, this.category});
  final AdminViewModel vm;
  final Category? category;
  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  late final name = TextEditingController(text: widget.category?.name ?? '');
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.vm,
    builder: (context, _) => PageFrame(
      title: widget.category == null ? 'Nueva categoría' : 'Editar categoría',
      onBack: () => Navigator.pop(context),
      child: ContentWidth(
        maxWidth: 480,
        child: ListView(
          padding: EdgeInsets.all(_adminPageMargin(context)),
          children: [
            _AdminSectionHeader(
              icon: Icons.category_outlined,
              title: widget.category == null
                  ? 'Crea una categoría'
                  : 'Actualiza la categoría',
              description: 'Usa un nombre claro para agrupar tus productos.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: name,
              enabled: !widget.vm.busy,
              decoration: const InputDecoration(
                labelText: 'Nombre de categoría',
              ),
            ),
            ErrorMessage(widget.vm.error),
            const SizedBox(height: 24),
            FilledButton(
              style: _adminActionStyle,
              onPressed: widget.vm.busy
                  ? null
                  : () async {
                      if (await widget.vm.saveCategory(
                            widget.category?.id,
                            name.text,
                          ) &&
                          context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: const Text('Guardar categoría'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProductEditorView extends StatefulWidget {
  const ProductEditorView({super.key, required this.services, this.product});
  final AppServices services;
  final Product? product;
  @override
  State<ProductEditorView> createState() => _ProductEditorViewState();
}

class _ProductEditorViewState extends State<ProductEditorView> {
  late final vm = ProductEditorViewModel(widget.services, widget.product);
  final form = GlobalKey<FormState>();
  final sku = TextEditingController();
  bool leaving = false,
      initializing = false,
      skuInitialized = false,
      recovered = false;

  void syncSku() {
    if (sku.text != vm.sku) sku.text = vm.sku;
  }

  void authChanged() {
    if (mounted &&
        widget.services.auth.isAuthenticated &&
        widget.services.auth.isConfigured) {
      initializeEditor();
    }
  }

  Future<void> initializeEditor() async {
    if (initializing ||
        !mounted ||
        !widget.services.auth.isAuthenticated ||
        !widget.services.auth.isConfigured) {
      return;
    }
    initializing = true;
    try {
      if (!skuInitialized) skuInitialized = await vm.initializeSku();
      if (mounted &&
          !recovered &&
          widget.services.auth.isAuthenticated &&
          widget.services.auth.isConfigured) {
        recovered = true;
        await vm.addImages(recover: true);
      }
    } finally {
      initializing = false;
    }
  }

  @override
  void initState() {
    super.initState();
    syncSku();
    vm.addListener(syncSku);
    widget.services.auth.addListener(authChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => initializeEditor());
  }

  @override
  void dispose() {
    widget.services.auth.removeListener(authChanged);
    vm.removeListener(syncSku);
    sku.dispose();
    vm.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (leaving || vm.busy) return;
    if (vm.dirty &&
        !await confirmAction(
          context,
          'Descartar cambios',
          'Los cambios y las fotos nuevas sin guardar se descartarán.',
          confirm: 'Descartar',
        )) {
      return;
    }
    if (await vm.cancel() && mounted) {
      leaving = true;
      Navigator.pop(context);
    }
  }

  Future<void> pick() async {
    widget.services.auth.requireAdmin();
    final camera = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              minVerticalPadding: 16,
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              minVerticalPadding: 16,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (camera != null) await vm.addImages(camera: camera);
  }

  Future<void> createCategory() async {
    widget.services.auth.requireAdmin();
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => _InlineCategoryDialog(vm: vm),
    );
  }

  Widget field(
    String label,
    String initial,
    void Function(String) set, {
    bool multiline = false,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      initialValue: initial,
      enabled: !vm.busy,
      decoration: InputDecoration(labelText: label),
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? null : 1,
      keyboardType: numeric
          ? TextInputType.number
          : multiline
          ? TextInputType.multiline
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
      onChanged: (v) => vm.edit(() => set(v)),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: PageFrame(
        title: widget.product == null ? 'Nuevo producto' : 'Editar producto',
        onBack: leave,
        child: ContentWidth(
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                field('Nombre', vm.name, (v) => vm.name = v),
                field(
                  'Descripción',
                  vm.description,
                  (v) => vm.description = v,
                  multiline: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: sku,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      helperText: 'Se asigna automáticamente al guardar.',
                    ),
                  ),
                ),
                field(
                  'Presentación',
                  vm.presentation,
                  (v) => vm.presentation = v,
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(vm.categoryId),
                  initialValue: vm.categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  isExpanded: true,
                  items: widget.services.catalog.snapshot.categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: vm.busy
                      ? null
                      : (v) => vm.edit(() => vm.categoryId = v),
                  validator: (v) =>
                      v == null ? 'Selecciona una categoría' : null,
                ),
                TextButton.icon(
                  onPressed: vm.busy ? null : createCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva categoría'),
                ),
                const SizedBox(height: 16),
                field(
                  'Precio normal CLP',
                  vm.normalPrice,
                  (v) => vm.normalPrice = v,
                  numeric: true,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('En oferta'),
                  value: vm.onSale,
                  onChanged: vm.busy
                      ? null
                      : (v) => vm.edit(() => vm.onSale = v),
                ),
                if (vm.onSale)
                  field(
                    'Precio oferta CLP',
                    vm.salePrice,
                    (v) => vm.salePrice = v,
                    numeric: true,
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Disponible'),
                  subtitle: Text(
                    vm.available
                        ? 'Disponible'
                        : 'Agotado: seguirá visible en el catálogo',
                  ),
                  value: vm.available,
                  onChanged: vm.busy
                      ? null
                      : (v) => vm.edit(() => vm.available = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mostrar en catálogo'),
                  subtitle: Text(
                    vm.visible
                        ? 'Público'
                        : 'Oculto: solo visible en administración',
                  ),
                  value: vm.visible,
                  onChanged: vm.busy
                      ? null
                      : (v) => vm.edit(() => vm.visible = v),
                ),
                const SizedBox(height: 16),
                Text('Fotos', style: Theme.of(context).textTheme.titleMedium),
                const Text(
                  'La primera foto es la portada. Agrega al menos una.',
                ),
                for (var i = 0; i < vm.images.length; i++)
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ProductPhoto(
                            media: widget.services.media,
                            image: vm.images[i],
                            label: 'Foto ${i + 1}',
                          ),
                          Text(i == 0 ? 'Portada' : 'Foto ${i + 1}'),
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              moveButtons(
                                name: 'foto ${i + 1}',
                                up: vm.busy || i == 0
                                    ? null
                                    : () => vm.moveImage(i, -1),
                                down: vm.busy || i == vm.images.length - 1
                                    ? null
                                    : () => vm.moveImage(i, 1),
                              ),
                              TextButton(
                                onPressed: vm.busy
                                    ? null
                                    : () => vm.removeImage(i),
                                child: Text('Quitar foto ${i + 1}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: vm.busy ? null : pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Añadir fotos'),
                ),
                ErrorMessage(vm.error),
                if (vm.busy)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Procesando producto',
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: vm.busy
                      ? null
                      : () async {
                          if (!(form.currentState?.validate() ?? false)) return;
                          if (await vm.save() && context.mounted) {
                            leaving = true;
                            Navigator.pop(context);
                          }
                        },
                  child: const Text('Guardar producto'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: vm.busy ? null : leave,
                  child: const Text('Cancelar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminSettings extends StatefulWidget {
  const AdminSettings({
    super.key,
    required this.vm,
    required this.auth,
    required this.catalog,
  });
  final AdminViewModel vm;
  final AuthViewModel auth;
  final CatalogViewModel catalog;
  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final current = TextEditingController(),
      pin = TextEditingController(),
      confirm = TextEditingController();
  @override
  void dispose() {
    current.dispose();
    pin.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.auth,
    builder: (context, _) => ContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsGroup(
            children: [
              Text(
                'Apariencia',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              RadioGroup<String>(
                groupValue: widget.vm.snapshot.settings.themeMode,
                onChanged: (v) {
                  if (v != null && !widget.vm.busy) widget.vm.saveTheme(v);
                },
                child: Column(
                  children: [
                    for (final entry in {
                      'system': 'Sistema',
                      'light': 'Claro',
                      'dark': 'Oscuro',
                    }.entries)
                      RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        enabled: !widget.vm.busy,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              Text('Seguridad', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Text(
                'Cambiar PIN',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              pinField(current, 'PIN actual'),
              const SizedBox(height: 16),
              pinField(pin, 'Nuevo PIN de 4 dígitos'),
              const SizedBox(height: 16),
              pinField(confirm, 'Confirmar nuevo PIN'),
              const SizedBox(height: 24),
              ErrorMessage(widget.auth.error),
              FilledButton(
                onPressed: widget.auth.busy
                    ? null
                    : () async {
                        if (await widget.auth.changePin(
                              current.text,
                              pin.text,
                              confirm.text,
                            ) &&
                            context.mounted) {
                          current.clear();
                          pin.clear();
                          confirm.clear();
                          showFeedback(context, 'PIN actualizado.');
                        }
                      },
                child: const Text('Cambiar PIN'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              Text(
                'Respaldo local',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Incluye productos, categorías, orden, fotos y ajustes compatibles. No incluye PIN, código de recuperación ni sesión.',
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: widget.vm.busy
                    ? null
                    : () async {
                        if (await widget.vm.export() && context.mounted) {
                          showFeedback(
                            context,
                            'Respaldo creado. Se abrió el diálogo para compartirlo.',
                          );
                        }
                      },
                child: const Text('Exportar respaldo'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.vm.busy
                    ? null
                    : () async {
                        await widget.vm.selectBackup();
                      },
                child: const Text('Seleccionar respaldo para importar'),
              ),
              if (widget.vm.preview case final preview?) ...[
                const SizedBox(height: 16),
                Text(
                  'Respaldo validado: ${preview.categoryCount} categorías, ${preview.productCount} productos, ${preview.imageCount} fotos.',
                ),
                const Text(
                  'Reemplazará todo el catálogo de este dispositivo. No combinará datos. El PIN y código de recuperación se conservan.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: widget.vm.busy
                      ? null
                      : () async {
                          if (await confirmAction(
                            context,
                            'Reemplazar catálogo',
                            'El catálogo actual será reemplazado por el respaldo validado. No se combinarán datos.',
                            confirm: 'Reemplazar catálogo',
                          )) {
                            if (await widget.vm.restore() && context.mounted) {
                              widget.catalog.clearSelection();
                              showFeedback(context, 'Catálogo reemplazado.');
                            }
                          }
                        },
                  child: const Text('Reemplazar catálogo'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.vm.busy
                      ? null
                      : () => widget.vm.discardPreview(),
                  child: const Text('Cancelar importación'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class _InlineCategoryDialog extends StatefulWidget {
  const _InlineCategoryDialog({required this.vm});
  final ProductEditorViewModel vm;
  @override
  State<_InlineCategoryDialog> createState() => _InlineCategoryDialogState();
}

class _InlineCategoryDialogState extends State<_InlineCategoryDialog> {
  final name = TextEditingController();
  ProductEditorViewModel get vm => widget.vm;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => PopScope(
      canPop: !vm.busy,
      child: AlertDialog(
        title: const Text('Nueva categoría'),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        buttonPadding: const EdgeInsets.symmetric(horizontal: 6),
        actionsOverflowButtonSpacing: 12,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                enabled: !vm.busy,
                decoration: const InputDecoration(
                  labelText: 'Nombre de categoría',
                ),
              ),
              ErrorMessage(vm.error),
              if (vm.busy) const LinearProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: _adminActionStyle,
            onPressed: vm.busy ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: _adminActionStyle,
            onPressed: vm.busy
                ? null
                : () async {
                    if (await vm.createCategory(name.text) && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            child: const Text('Guardar categoría'),
          ),
        ],
      ),
    ),
  );
}
