# Diseño — Catálogo compacto y administración Material 3

Skill local `flutter-product-design` aplicada. Mantener paleta forest/sage/cream,
tema claro/oscuro, seguridad y funciones actuales. Estas medidas de composición
son decisiones del proyecto, no todas reglas normativas de M3.

## Catálogo público

Exactamente dos tarjetas por fila, también a 320 dp y texto ampliado. Mantener
cabecera circular de marca, búsqueda, filtros y compartir existentes. En cada
`Card.outlined` quedan solo foto, nombre y selección PDF; presentación/precio/
disponibilidad siguen accesibles al tocar imagen y abrir detalle.

En compacto: margen 12 dp y medianil 12 dp; a 320 dp cada tarjeta mide 142 dp.
Foto 4:3 cover con decode acotado, `InkWell` superpuesto y acción semántica
«Abrir detalle de <nombre>». Nombre `titleSmall`, padding 10 dp, completo y
multilínea. Selección: fila con `Checkbox` de área mínima 48 × 48 dp y etiqueta
flexible «Incluir en PDF» `labelMedium`. Conservar semántica de producto y valor.
No usar altura fija, elipsis ni shrink del texto para acomodar dos columnas.

Renderizar filas lazy mediante `ListView.builder`, `Row` con dos `Expanded` y
alineación superior; alto de fila determinado por mayor contenido. La última
fila puede contener un producto y espacio libre sin tarjeta ficticia. Con texto
2×, nombre y etiqueta crecen verticalmente: no regresar a una columna. Mediana
600–839 dp conserva dos columnas y márgenes 24 dp; expandida ≥840 dp dos columnas,
márgenes 32 dp y ancho máximo 1200 dp. No precargar todo el catálogo.

## Administración

Tres destinos: Productos, Categorías y Ajustes. En compacto usar `NavigationBar`
inferior, labels visibles, selección persistente. A partir de 600 dp usar
`NavigationRail` lateral con los mismos destinos, sin duplicar navegación ni
acciones. No mostrar navegación del panel ni contenido cuando sesión esté bloqueada.

Productos: lista lazy de tarjetas outlined, margen 16 dp/24 dp/32 dp por ventana,
gap 12 dp y contenido padding 16 dp. Miniatura 64 dp, nombre `titleMedium`
multilínea, SKU `bodySmall`, estados visibles en `Wrap` con texto y fondo tonal.
Foto/SKU no desplazan acciones fuera de pantalla. `IconButton` Editar con tooltip;
menú Más acciones para disponibilidad, visibilidad y eliminar con confirmación;
acciones subir/bajar preservadas y deshabilitadas en extremos. Usar `Wrap` para
que controles de 48 dp crezcan a otra fila en compacto/texto ampliado.

Un FAB extended «Nuevo producto» abajo a la derecha, sobre NavigationBar; icono +
y etiqueta, tokens `primaryContainer`/`onPrimaryContainer`, elevación del tema M3.
En ventanas estrechas con texto ampliado usar FAB de icono + con tooltip y etiqueta
semántica «Nuevo producto», evitando desbordar su texto sin reducir tamaño de fuente.
Reservar padding inferior de lista al menos 96 dp y separación visible 16 dp al
FAB para que la última tarjeta quede accesible sin superposición. Al cambiar
destino no dejar el FAB de productos sobre Ajustes. Categorías mantiene su acción
de crear disponible, sin dos FAB simultáneos en la misma pantalla.

Categorías: tarjetas outlined con nombre `titleMedium`, conteo de productos
`bodyMedium` derivado del snapshot vigente (incluye visibles y ocultos), acciones
editar/eliminar/reordenar conservadas y confirmaciones actuales. Conteos no son
botones; no añadir filtros nuevos.

Ajustes: tres tarjetas agrupadas — Apariencia (tema actual), Seguridad (PIN y
acciones existentes), Respaldos (exportar/importar existentes). Títulos
`titleMedium`, descripción `bodyMedium`; acciones flexibles con mínimo 48 dp.
Separación entre campos/grupos y acciones 24 dp; botones apilados separados 8 dp.
Mantener vista previa, confirmación y reemplazo de respaldo sin nuevos ajustes.

## Formulario de producto

Conservar campos, orden funcional, validaciones, galería, cámara y guardado actuales.
Bajo selector de categoría añadir `TextButton.icon` «Nueva categoría», independiente
de 48 dp. Abrir diálogo M3 con campo nombre, Cancelar y Guardar; errores actuales
por nombre vacío/duplicado. Al éxito retornar ID guardado y seleccionarlo sin perder
ningún otro campo/foto del borrador. Cancelación no cambia selección.

SKU solo lectura, automático y correlativo numérico `1`, `2`, `3`… confirmado
por el usuario. Mostrar previsión del código, con
asignación definitiva atómica al guardar; abrir/cancelar no consume correlativos.
No generar valor en cada rebuild, reutilizar números emitidos tras borrar ni alterar
SKU existentes. Conservar contador y reconciliación de respaldos según ADM-AC-05.

## Tokens, estados y accesibilidad

| Elemento | Tokens conservados/propuestos del tema |
| --- | --- |
| Fondo y cabecera | `surface` / `onSurface`, `titleLarge` |
| Tarjetas outlined | `surfaceContainerLow`, `outlineVariant`, elevación 0 |
| Imagen fallback | `surfaceContainerHighest` / `onSurface` |
| Nombre | `titleSmall` público, `titleMedium` admin, `onSurface` |
| Contenido auxiliar | `bodySmall`/`bodyMedium`, `onSurfaceVariant` |
| Selección y navegación activa | tema M3 Primary/Secondary y roles de contenido |
| FAB | `primaryContainer` / `onPrimaryContainer` |
| Errores | `error`, región viva actual |

Conservar respuesta de foco/pulsación, ocupado/deshabilitado y semántica. Probar
320 dp, texto 2×, claro/oscuro, teclado y orden de lectura. No se declara contraste
numérico validado sin comprobar pares concretos. `NavigationBar` no escala tamaño
con textScaler según Flutter: comprobar labels y tooltips, sin forzar tamaños
reducidos para acomodarlos.

## Base Flutter orientativa

```dart
NavigationBar(
  selectedIndex: selectedIndex,
  onDestinationSelected: selectDestination,
  destinations: const [
    NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Productos'),
    NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categorías'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
  ],
)
```

Integrar preservando Navigator protegido y estado de borradores; el fragmento no
implica modificar seguridad ni crear nuevas rutas funcionales.

## Fuentes oficiales consultadas

- [M3 Navigation bar](https://m3.material.io/components/navigation-bar/overview):
  lector requiere JavaScript; no atribuir medidas nuevas a contenido inaccesible.
- [Flutter NavigationBar](https://api.flutter.dev/flutter/material/NavigationBar-class.html):
  componente M3 y destinos persistentes; comportamiento de textScaler.
- [Flutter FAB](https://api.flutter.dev/flutter/material/FloatingActionButton-class.html):
  acción principal positiva y uso dentro de Scaffold.
