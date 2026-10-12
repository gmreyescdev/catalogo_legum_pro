# Diseño — Rendimiento sin cambiar la experiencia

Estado: política de decode implementada y medida; experiencia M3 conservada.
Aplicada la skill local `flutter-product-design` y conservado SPEC-006.

## Jerarquía, componentes y tokens

Mantener símbolo circular de 40 dp junto a «Catálogo LegumPro», acciones,
compartir completo, búsqueda, filtros y tarjetas. No añadir pantallas de diagnóstico,
animaciones, skeletons ni un nuevo indicador de carga. PERF-AC-05/07.

| Elemento M3 existente | Estado/elevación | Tokens conservados |
| --- | --- | --- |
| Cabecera con anatomía de barra superior | Elevación cero; logo no interactivo | `surface` / `onSurface`, `titleLarge` |
| `SearchBar` y `FilterChip` | Normal, foco y categoría seleccionada; tema actual | Tokens del componente M3 actual; texto de búsqueda y etiquetas del tema |
| `Card.outlined` | Sin sombra añadida; selección sigue en checkbox | `surfaceContainerLow`, `outlineVariant`, `titleMedium` para nombre/precio |
| Presentación y disponibilidad | Texto completo, sin truncar para ganar velocidad | `bodyMedium`, `onSurface` |
| Oferta | Mantener etiqueta y precio normal tachado | `tertiaryContainer` / `onTertiaryContainer` |
| Compartir/ver selección | Habilitado, deshabilitado y ocupado actuales | `primary` / `onPrimary`, `labelLarge` |
| Foto inválida y error | Mantener alternativa textual y mensaje actual | `surfaceContainerHighest`, `onSurface`; `error` para error de comando |

Se conserva la paleta forest/sage/cream actual, incluido Secondary. No sustituir
colores ni tipografía durante una optimización. La reserva 4:3 de la foto sigue
estable antes y después de decodificar; no introducir saltos de tarjetas al cargar.

## Adaptación y accesibilidad

- Compacta <600 dp: una columna, margen 16 dp.
- Mediana 600–839 dp: dos columnas, margen 24 dp; expandida ≥840 dp: dos columnas,
  margen 32 dp. Medianil 16 dp; ancho máximo existente 1200 dp para dos columnas.
- Con texto ampliado que haga `scale(16) >= 24`, conservar una columna y máximo
  720 dp. Mantener alturas flexibles, orden de lectura, etiquetas y foco.
- Controles interactivos ≥48 × 48 dp; el logo decorativo de 40 dp no es botón.
  Revisar controles y contraste en claro/oscuro; no se declara contraste numérico
  verificado en esta entrega documental.

## Imágenes y respuesta percibida

Las tarjetas conservan `BoxFit.cover`; detalle y edición conservan `contain`.
La resolución decodificada depende de los bounds reales del widget y DPR, no del
ancho de la pantalla completa. Conservar originales y lectura de detalle. Al usar
`ResizeImage`, evitar imponer ambos ejes en modo `exact` con proporción ajena al
original. Para cover, el objetivo debe cubrir ambos ejes con proporción original;
para contain, caber en ellos. Verificar fotos panorámicas y verticales: una política
fit de decodificación aplicada sin considerar cover podría producir desenfoque.
No precargar todo el catálogo ni resolver metadatos completos en cada build.

La selección responde en su control y contador; conservar actualización de precios,
visibilidad y fotos al volver de administración. Reducir reconstrucciones no debe
congelar contenido ni perder estado de búsqueda, desplazamiento o selección.

## Transiciones — PERF-AC-09

Mantener las transiciones de ruta Material existentes en catálogo↔detalle,
catálogo↔selección y acceso al panel, con navegación atrás consistente. Mejorar
continuidad del movimiento y respuesta al gesto sin añadir efectos, Hero ni una
duración distinta para ocultar pausas. Evitar trabajo pesado al iniciar la ruta.
Separar tiempo de carga de la medición de transición; conservar estado del panel
protegido y borradores si se pausa o bloquea. Respetar la preferencia de reducir
movimiento de la plataforma y comprobar navegación rápida/atrás sin rutas duplicadas.
Si se acotan tickers del panel fuera de pantalla, conservar su estado y el bloqueo
de seguridad; no cambiar el comportamiento de `Offstage` por eliminación del árbol.

## Pantallas de 120 Hz

La experiencia mantiene el mismo diseño y patrón Material a 60 y 120 Hz. La meta
de fluidez se evalúa con presupuestos distintos: 16,67 ms y 8,33 ms por etapa,
respectivamente. Respetar frecuencia, ahorro de energía y movimiento reducido
elegidos en Android; no forzar ajustes globales ni añadir un selector de frecuencia
a la app. Compatibilidad de pantalla no acredita 120 FPS sostenidos: verificar
trazas y registrar cualquier limitación de frecuencia efectiva. PERF-AC-01/02/09.

## Base Flutter orientativa

Se conserva la estructura actual. Este fragmento documenta el contrato visual,
no implementa el cálculo de resolución ni reemplaza el manejo actual de errores:

```dart
Widget photoFrame({
  required ImageProvider decodedProvider,
  required BoxFit fit,
  required Widget fallback,
}) => AspectRatio(
  aspectRatio: 4 / 3,
  child: Image(
    image: decodedProvider,
    fit: fit,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => fallback,
  ),
);
```

El codificador conserva además fondo, imagen ausente y semántica de galería de
`ProductPhoto`; `decodedProvider` representa la política de tamaño medida,
implementada mediante `lib/ui/layout_image_provider.dart`. Conserva proporción
para cover/contain y no amplía originales pequeños; resultados concretos en QA.

## Referencias oficiales

- [M3 barras superiores](https://m3.material.io/components/app-bars/overview) y
  [accesibilidad](https://m3.material.io/foundations/accessible-design/overview):
  requieren JavaScript en el lector; no se les atribuyen nuevas medidas verificadas.
- [ResizeImage](https://api.flutter.dev/flutter/painting/ResizeImage-class.html)
  permite controlar dimensiones decodificadas y memoria de ImageCache.
- [ResizeImagePolicy](https://api.flutter.dev/flutter/painting/ResizeImagePolicy.html)
  distingue exact, que puede cambiar proporción con dos dimensiones, de fit.
