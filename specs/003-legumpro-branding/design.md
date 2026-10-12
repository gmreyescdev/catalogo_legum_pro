# Diseño — SPEC-003

Se aplica la skill local `flutter-product-design` y se mantiene el sistema Material
Design 3 existente. Esta entrega ajusta la marca visible y la composición de las
fotografías; no agrega navegación ni acciones nuevas.

## Jerarquía y componentes

- BRAND-AC-01: la cabecera pública y el título de la aplicación dicen
  **Catálogo LegumPro**. Conservan `titleLarge` y los tokens `surface` / `onSurface`.
- BRAND-AC-02: las tarjetas delineadas conservan elevación cero, borde y fondo
  `surfaceContainerLow`. La imagen ocupa su área 4:3, seguida del nombre
  `titleMedium`, presentación, precio, disponibilidad y acciones existentes.
- Las tarjetas del catálogo y de la selección usan `BoxFit.cover`: mantienen la
  proporción original, llenan el área y recortan desde el centro cuando es necesario.
  Esta es una decisión de composición del producto, no una regla obligatoria M3.
- El detalle, la galería y los formularios mantienen `BoxFit.contain` para examinar
  la foto completa. El ajuste solo afecta la visualización, nunca el archivo local.
- Sin imagen o ante error se conserva el mensaje **Imagen no disponible** sobre
  `surfaceContainerHighest`. Se mantiene la semántica existente de portada/galería.

## Ventanas y accesibilidad

Se mantienen los márgenes compactos de 16 dp, medianos de 24 dp y expandidos de
32 dp. El catálogo conserva una columna compacta y dos cuando existe espacio
suficiente; con texto ampliado vuelve a una. Los medianiles permanecen en 16 dp.
La relación 4:3 se calcula a partir del ancho disponible.

No se alteran colores, escalas tipográficas, áreas de toque ni orden de lectura.
Los controles deben conservar el mínimo de 48 × 48 dp existente. La inspección
del cambio confirma que el fallback y las etiquetas siguen presentes; análisis,
regresiones de widgets y validación visual Android quedan a cargo de QA. Esta
entrega no aporta una nueva medición de contraste ni acredita iOS.

## Base Flutter integrada

```dart
// Reutilizable: detalle y formularios muestran la fotografía completa.
const ProductPhoto({this.fit = BoxFit.contain, /* ... */});

// Solo las portadas de catálogo y selección llenan el área 4:3.
ProductPhoto(media: media, image: cover, fit: BoxFit.cover);
```

La configuración del nombre PDF se incorporará cuando se resuelva BRAND-AC-03;
no se toma una decisión de interacción adicional en este documento.

## Fuentes

- [Cards — Material Design 3](https://m3.material.io/components/cards/overview):
  referencia del componente existente; su sitio requiere JavaScript.
- [BoxFit — Flutter](https://api.flutter.dev/flutter/painting/BoxFit.html):
  comportamiento documentado de `cover` y `contain`.
