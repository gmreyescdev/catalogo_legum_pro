# Diseño — SPEC-001 Catálogo simple

Estado: diseño M3 implementado. Contrastes y comportamiento automatizado verificados
en `qa.md`; validación visual y con lectores de pantalla en dispositivo pendiente.
Skill aplicada: `.agents/skills/flutter-product-design/SKILL.md`.

## Base y decisiones

El código actual contiene únicamente una pantalla «Hello World!» sin identidad
visual. Se diseña una única pantalla de lectura de productos para Android e iOS,
con componentes integrados de Flutter y Material 3. No hay navegación ni acciones
en las tarjetas. Las decisiones de datos locales y contenido de demostración
proceden del spec; no se necesitan estados de carga remota.

La paleta es una propuesta reemplazable, no una identidad Legum confirmada.
Generarla con `ColorScheme.fromSeed(seedColor: Color(0xFF315C38), brightness:
Brightness.light)`, sin sobrescribir colores con la paleta anterior. Es un esquema
tonal generado desde una semilla, no extracción dinámica del fondo de Android.
Usar `ThemeData(useMaterial3: true, colorScheme: scheme)` en ambas plataformas.
La generación y los roles siguen [ColorScheme.fromSeed](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html)
y [roles de color M3](https://m3.material.io/styles/color/roles).

| Rol | Aplicación |
| --- | --- |
| `surface` / `onSurface` | Fondo, encabezado, nombre y descripción |
| `surfaceContainerLow` / `onSurface` | Contenedor de tarjeta y texto principal |
| `surfaceContainerHighest` / `onSurfaceVariant` | Marco de imagen y placeholder |
| `onSurfaceVariant` | Aviso de demostración sobre `surface` |
| `outlineVariant` | Borde de tarjeta; no transmite información por sí solo |
| `primary` / `onPrimary` | Acento reservado del tema; sin botones en este incremento |
| `secondary` / `onSecondary`, `tertiary` / `onTertiary` | Roles disponibles del esquema; sin uso necesario en esta pantalla |
| `error` / `onError` | Reservados para errores; imagen ausente usa estado neutral, no alarma |

No asumir que la semilla será el hexadecimal final de `primary`. Los contrastes
concretos del esquema generado se deben medir antes de declarar validación.

## Pantalla y jerarquía

- `MaterialApp` con tema claro y `Scaffold`; encabezado «Catálogo» sin botones.
- Encabezado de anatomía top app bar pequeña M3, sin botones: título «Catálogo»
  alineado al inicio, `titleLarge`, fondo `surface`, elevación 0. En Flutter usar
  `Material` y altura intrínseca con mínimo 64 dp dentro de `SafeArea`, evitando
  un `AppBar` de altura fija que corte texto a escala 2. Esta adaptación de
  accesibilidad es decisión del proyecto. Padding vertical 16 y horizontal según
  ancho de ventana. Mantenerlo fuera del scroll.
- Cuerpo dentro de `SafeArea`, con `ListView.separated`, márgenes laterales de
  16, separación de 16 entre tarjetas y margen inferior de 24.
- Antes de los productos, mostrar «Contenido de demostración» como texto de
  14 unidades. No forma parte del nombre de ningún producto.
- Usar `Card.outlined` M3, `color: surfaceContainerLow`, borde `outlineVariant`,
  radio 12 y elevación 0. Sin sombras, estados de presión, hover ni acción de toque:
  es un contenedor de lectura. Su altura depende del contenido, nunca es fija.
- Orden de lectura: imagen, nombre y descripción. Bajo la imagen hay un bloque
  con padding de 16, nombre `titleLarge`, separación de 8 y descripción `bodyLarge`.
  El aviso usa `bodyMedium`; placeholder y estado vacío usan `bodyLarge`.

Usar `Theme.of(context).textTheme` sin pesos o tamaños arbitrarios: M3 por defecto
ofrece `titleLarge` 22/28, `bodyLarge` 16/24 y `bodyMedium` 14/20 (tamaño/altura de
línea en dp). Display y Headline no se requieren para este catálogo; Label se
reserva a controles, ausentes en el alcance. Fuentes: [tipografía M3](https://m3.material.io/styles/typography/applying-type)
y [TextTheme Flutter](https://api.flutter.dev/flutter/material/TextTheme-class.html).

## Layout adaptable

Clasificar por ancho de ventana disponible, no por modelo de dispositivo. El
encabezado y cuerpo se centran en un contenedor de ancho máximo **600 dp incluyendo
márgenes**; la lista mantiene una columna para lectura completa de descripciones.
El límite es una decisión del proyecto para evitar líneas e imágenes excesivamente
anchas, no una obligación de M3. El aviso y las tarjetas se desplazan juntos.

| Ventana | Margen horizontal dentro del contenedor | Columnas / medianil |
| --- | --- | --- |
| Compacta, <600 dp | 16 dp | Una / no aplica |
| Media, 600–839 dp | 24 dp | Una / no aplica |
| Expandida, >=840 dp | 32 dp y espacio exterior simétrico | Una / no aplica |

Aplicar el mismo comportamiento a ventanas grandes. Mantener 16 dp entre tarjetas
y 24 al final. Las clases y adaptación por espacio se fundamentan en
[breakpoints M3](https://m3.material.io/foundations/layout/breakpoints/overview)
y [guía oficial Google de clases de ventana](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes).

## Imágenes y texto

Usar recursos locales de demostración. La imagen ocupa el ancho de la tarjeta en
un marco de proporción 4:3, con `BoxFit.contain` sobre fondo `surfaceContainerHighest` para mostrar
el producto completo sin recortar. Recortar únicamente a los radios superiores de
la tarjeta mediante el clip de `Card` con radio 12. El padding interno de la foto puede provenir del
propio recurso; no deformar imágenes para llenar el marco.

Nombre y descripción admiten todas las líneas necesarias: sin `maxLines`, sin
elipsis y sin contenedores de altura fija. Respetar el `TextScaler` del sistema;
no limitar la escala ni reducir la fuente para encajar. El desplazamiento permite
leer el contenido largo y las tarjetas expandidas.

## Estados

| Estado | Presentación | Criterios |
| --- | --- | --- |
| Productos locales | Listado inmediato con nombre, imagen y descripción completos; aviso de demostración | AC-01, AC-02, AC-03, AC-06 |
| Imagen ausente, inexistente o no decodificable | Sustituir el marco de imagen por un icono decorativo de imagen y el texto «Imagen no disponible»; mantener proporción y contenido textual | AC-04 |
| Colección vacía | Mantener encabezado y mostrar «No hay productos disponibles» con padding de 24, centrado horizontalmente; permitir desplazamiento si el espacio vertical resulta insuficiente | AC-05, AC-07 |

No añadir spinner, reintento ni mensajes de conexión: el origen local no los
requiere. El error de una imagen se resuelve dentro de su tarjeta.

## Accesibilidad y plataformas

El título tiene semántica de encabezado. Cada tarjeta es un contenedor semántico
con nombre y descripción en ese orden, sin anunciarla como botón. Las imágenes
de demostración repiten la identificación ya expresada por el nombre y son
decorativas (`excludeFromSemantics: true`); tampoco anunciar el icono del
placeholder. El texto «Imagen no disponible» sí se anuncia cuando corresponda.
No duplicar los textos con una etiqueta semántica adicional que los repita.

Con texto a escala 2.0, encabezado, nombre, descripción y mensajes crecen y se
envuelven. No usar filas de texto con ancho intrínseco sin restricción. Respetar
insets del sistema en ambos extremos y no depender de gestos para descubrir
contenido obligatorio. La misma composición y datos se usan en Android e iOS;
la validación visual y con TalkBack/VoiceOver se registra por separado.

No hay controles interactivos en este spec; el mínimo táctil de 48 × 48 dp queda
como regla para futuros controles, sin añadir botones. Método de contraste:
calcular `(Lmax + 0.05) / (Lmin + 0.05)` con `Color.computeLuminance()` sobre los
colores reales generados y exigir al menos 4.5:1 para todas las parejas de texto
usadas: `onSurface/surface`, `onSurface/surfaceContainerLow`,
`onSurfaceVariant/surface` y `onSurfaceVariant/surfaceContainerHighest`.
Valores y resultados calculados por QA y registrados en `qa.md`; todas las parejas
de texto revisadas superan 4.5:1.
Ver [accesibilidad Flutter](https://docs.flutter.dev/ui/accessibility).

## Código base documental para el codificador

Este fragmento orienta la integración; no sustituye el modelo, recursos ni manejo
de imagen inválida del spec. `body` representa la lista o el estado vacío.

```dart
final scheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF315C38),
  brightness: Brightness.light,
);
final theme = ThemeData(useMaterial3: true, colorScheme: scheme);

Widget catalogFrame(BuildContext context, Widget body) {
  final width = MediaQuery.sizeOf(context).width;
  final margin = width < 600 ? 16.0 : (width < 840 ? 24.0 : 32.0);
  final theme = Theme.of(context);
  return Scaffold(
    backgroundColor: theme.colorScheme.surface,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: theme.colorScheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: margin, vertical: 16),
                    child: Semantics(
                      header: true,
                      child: Text('Catálogo', style: theme.textTheme.titleLarge),
                    ),
                  ),
                ),
              ),
              Expanded(child: body), // Lista con padding horizontal = margin.
            ],
          ),
        ),
      ),
    ),
  );
}

// Contenedor de cada producto; child incluye imagen, nombre y descripción.
Widget productCard(BuildContext context, Widget child) => Card.outlined(
  margin: EdgeInsets.zero,
  elevation: 0,
  color: Theme.of(context).colorScheme.surfaceContainerLow,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  ),
  child: child,
);
```

Referencias de componentes: [Cards M3](https://m3.material.io/components/cards/overview),
[App bars M3](https://m3.material.io/components/app-bars/overview) y
[Card Flutter](https://api.flutter.dev/flutter/material/Card-class.html).

## Checklist para implementación y QA

- AC-01: apertura directa; cada tarjeta contiene los tres elementos y se distingue
  que los ejemplos son de demostración.
- AC-02: el último producto y el final de su descripción son alcanzables mediante
  desplazamiento vertical.
- AC-03: una descripción extensa no desaparece, no muestra elipsis ni desborda.
- AC-04: probar ruta ausente y recurso inválido; ambos muestran el placeholder
  sin perder nombre ni descripción.
- AC-05: una lista vacía muestra exactamente «No hay productos disponibles».
- AC-06: recursos incluidos visibles sin conexión, sin dependencia de URL remota.
- AC-07: revisar anchos 320 y 390 con escalas 1.0 y 2.0, áreas seguras, ausencia
  de desbordamientos y orden semántico de nombre y descripción. Complementar con
  ventanas 600 y 840 para comprobar márgenes y ancho máximo; medir contrastes
  reales. Comprobaciones automatizadas aprobadas y contrastes medidos en `qa.md`;
  la verificación manual en dispositivo permanece pendiente.
- AC-08: verificar la misma experiencia en Android e iOS; documentar lo pendiente
  si no se dispone de dispositivo, simulador o Xcode. Este diseño no constituye
  evidencia de ejecución en ninguna plataforma.
