# Diseño — Acceso administrativo y Categorías

Skill local `flutter-product-design` aplicada. Alcance solicitado: presentación del
acceso existente, progreso real de Entrar, separación de acciones y rediseño de
Categorías. Conservar autenticación, recuperación, configuración inicial y gestión
de categorías actuales. Este documento propone composición; no crea funciones.

## Jerarquía del acceso

Conservar PageFrame y retorno al catálogo. Usar ContentWidth(maxWidth: 480) con
lista desplazable: icono de seguridad en contenedor tonal, título contextual,
descripción breve, campos existentes, mensajes de error/bloqueo, acción principal y
acciones secundarias. Evitar panel de altura fija o centrado vertical que oculte el
formulario al aparecer teclado. Sin duplicar un título grande idéntico al de la
barra: título interior «Administra tu catálogo» para PIN; contextual en recuperación.

La pantalla conserva los tres estados actuales: PIN, recuperar acceso y guardar
código de recuperación/configuración. Nunca añadir acceso alternativo ni exponer PIN.
Símbolo decorativo excluido de semántica. El código SelectableText sigue seleccionable.

Entrar es FilledButton de ancho disponible, mínimo 48 dp de alto, altura natural
con texto ampliado. Cuando vm.busy: onPressed null, indicador circular indeterminado
de 20 dp y texto «Procesando…». Spinner y label separados 12 dp; label Flexible
multilínea evita overflow en 320 dp/texto 2×. La animación dura exclusivamente la
operación real; sin sleep ni mínimo artificial. Conservar protección ante doble envío
y reglas actuales de bloqueo/reintento. Semantics del indicador «Procesando acceso».
No poner spinner del color onPrimary sobre fondo deshabilitado: usar colorScheme.primary
para el estado deshabilitado/ocupado conservando el estilo de botón del tema.

## Regla de separación del proyecto

Desde esta entrega, todas las pantallas nuevas o modificadas aplican:

- 24 dp entre campos/contenido y bloque de acciones, y entre acción principal y lista de tarjetas.
- 16 dp entre grupos y tarjetas independientes; padding interior de tarjetas 16 dp.
- 12 dp mínimo entre contenido interno y fila de controles; botones en Wrap con spacing/runSpacing 12 dp.
- Mantener áreas interactivas mínimas de 48 × 48 dp y altura natural con texto ampliado.

Estas distancias son decisiones locales compatibles con M3, no medidas atribuidas
como regla universal oficial. Separar un bloque de controles del contenido no obliga
a espaciar 24 dp cada icono vecino. En esta spec se aplican a acceso, Categorías y sus
editores/diálogos modificados; no implica rediseñar todo el catálogo ahora.

## Categorías

Lista vertical de ancho máximo actual 720 dp. Cabecera textual «Organiza tus productos»
con resumen derivado de vm.categories.length y descripción breve del rol de categoría.
«Añadir categoría» FilledButton.icon, no FAB adicional. Separar la acción de primera
tarjeta por 24 dp explícitos, independientemente del margin de Card. En estado vacío,
mensaje existente dentro de contenedor tonal separado por 24 dp; acción sigue visible.

Cada Card.outlined (elevación 0) incluye icono category_outlined de 24 dp en fondo
tonal 48 dp, Expanded con nombre titleMedium completo y conteo bodyMedium, incluye
productos visibles y ocultos como antes. Padding16, gap16 icono/texto; separación16
antes de acciones. Mantener Editar, Eliminar con confirmación actual y subir/bajar
con tooltips y extremos deshabilitados. Wrap(spacing:12, runSpacing:12) permite pasar
controles a otra fila; no comprimir controles ni elidir nombre. Borrado ocupado mantiene
el error existente y la categoría; no convertir tarjetas en accesos nuevos.

Editor: campo nombre conserva validación y borrador actuales, guardar/cancelar en
bloque separado24; diálogo inline de producto mantiene ciclo de vida y selección.

## Tokens y componentes Material 3

Mantener ColorScheme actual forest/sage/cream y ambos temas. No añadir paleta fija.

| Elemento | Tokens / tipografía |
| --- | --- |
| Fondo de página | surface / onSurface |
| Símbolo de seguridad/categoría | secondaryContainer / onSecondaryContainer |
| Título interior | titleLarge, onSurface |
| Descripción y conteo | bodyMedium, onSurfaceVariant |
| Nombre de categoría | titleMedium, onSurface |
| Card outlined | surfaceContainerLow, outlineVariant; elevación 0 |
| Entrar / Añadir categoría | FilledButton del tema, primary/onPrimary; labelLarge |
| Secundarios | TextButton del tema, primary; labelLarge |
| Error | error + ErrorMessage liveRegion existente |

Conservar estados normales, foco, pulsación, disabled y busy. La elevación de botones
la define el tema M3; ninguna sombra decorativa personalizada.

## Ventanas y accesibilidad

Compacta <600 dp: una columna, margen16; panel acceso480 máximo incluido contenido.
Mediana600–839: una columna centrada, margen24, acceso480/categorías720 máximos.
Expandida≥840: margen32, mismos máximos; conservar NavigationRail administrativo.
No introducir segunda columna en Categorías que altere lectura o reordenamiento.
Texto2×, teclado y nombres largos crecen verticalmente con scroll. Orden lectura:
título, explicación, campo, error, acción principal, secundarias; categoría nombre,
conteo, editar/eliminar, reordenar. Mensajes de error preservan región viva.

Contraste numérico ejecutado mediante la prueba host `admin text role contrast
reaches 4.5 in light and dark themes`, con evidencia en
`artifacts/013-admin-access-categories/targeted-tests.log`. Los 14 pares medidos
alcanzaron entre 6.14:1 y 16.29:1, superando 4.5:1 para el texto activo evaluado.

| Par de roles | Claro | Oscuro |
| --- | --- | --- |
| primary / onPrimary | 6.48:1 | 7.72:1 |
| primaryContainer / onPrimaryContainer | 7.22:1 | 7.22:1 |
| surface / onSurface | 16.29:1 | 14.33:1 |
| surfaceContainerLow / onSurface | 15.56:1 | 13.25:1 |
| surfaceContainerLow / onSurfaceVariant | 8.50:1 | 10.04:1 |
| secondaryContainer / onSecondaryContainer | 7.22:1 | 7.22:1 |
| surface / error | 6.14:1 | 10.93:1 |

Esta evidencia acredita los pares concretos, no que todas las pruebas contenidas
en ese log hayan pasado. Los colores de controles deshabilitados no están sujetos
al requisito normativo de 4.5:1 de texto activo y no forman parte de esta medición.
El lector de pantalla físico continúa pendiente; el contraste host no acredita su
comportamiento ni reemplaza la revisión del dispositivo.

## Base Flutter de progreso

```dart
FilledButton(
  onPressed: vm.busy || wait > 0 ? null : unlock,
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (vm.busy) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
              semanticsLabel: 'Procesando acceso',
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(vm.busy ? 'Procesando…' : 'Entrar')),
      ],
    ),
  ),
)
```

Fragmento orientativo del estado PIN: al integrar conservar condición real de espera
solo en PIN normal y handler recuperación existente. ListenableBuilder actual aporta
rebuilds de busy; no inventar estado paralelo ni dependencias.

## Fuentes oficiales consultadas

- [Google M3 Buttons](https://m3.material.io/components/buttons/guidelines) y
  [Cards](https://m3.material.io/components/cards/guidelines): páginas requieren JS
  en lector disponible; no atribuir distancias normativas no recuperadas.
- [Flutter FilledButton](https://api.flutter.dev/flutter/material/FilledButton-class.html):
  acción principal, estados deshabilitados y FilledButton.icon.
- [Flutter CircularProgressIndicator](https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html):
  progreso indeterminado, color y etiqueta semántica.
- [Flutter Card.outlined](https://api.flutter.dev/flutter/material/Card/Card.outlined.html):
  delimitación mediante outlineVariant conservando anatomía M3.
