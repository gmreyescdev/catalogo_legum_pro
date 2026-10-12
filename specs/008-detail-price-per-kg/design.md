# Diseño — Precio por kilogramo e imagen ajustada en el detalle

Aplicada la skill local `flutter-product-design`. Esta modificación conserva
la interfaz Material Design 3 existente; no añade componentes ni cambia tokens.

## Jerarquía y componentes

En `ProductDetailView`, añadir ` x Kg` al texto de cada importe mostrado por
`Prices`: precio único o precio normal y de oferta. La etiqueta «Oferta» y el
tachado del precio normal se mantienen. KG-AC-01/02.

El precio vigente conserva `Text` con `textTheme.titleMedium`; el precio normal
conserva su estilo actual y tachado. La etiqueta usa `tertiaryContainer` y
`onTertiaryContainer`. El resto del texto mantiene los colores heredados del
tema. No cambiar elevación, espaciado, márgenes ni jerarquía de la pantalla.

La foto mantiene el marco 4:3 existente de `ProductPhoto`, con
`surfaceContainerHighest` como fondo. En el detalle, usar `BoxFit.cover` para
llenarlo manteniendo proporción; recortar bordes cuando sea necesario, sin
deformar. Esta petición sustituye explícitamente el `contain` anterior del
detalle. No crear otra `Card`, pantalla ni estructura. Aplicar a cada foto al
navegar la galería y conservar originales, alternativas y decode acotado.
Los demás usos y el PDF no cambian. KG-AC-05.

## Adaptación y accesibilidad

Mantener alineación inicial, ancho de detalle existente y salto de línea natural,
sin elipsis ni límite de líneas. El sufijo forma parte del mismo `Text` del importe
para conservar lectura conjunta. Revisar texto ampliado y temas claro/oscuro;
no se declara una nueva medición de contraste ejecutada en este documento.
No hay nuevos controles interactivos ni cambios en sus áreas táctiles.
La galería mantiene botones, orden de lectura y etiqueta de foto vigente;
el fallback textual para imagen ausente/inválida conserva su comportamiento.
Comprobar fotos verticales y panorámicas para verificar recorte proporcional
y ausencia de bandas vacías, además de no introducir saltos del marco al cargar.

## Base Flutter

Contrato propuesto del componente compartido:

```dart
const Prices(this.product, {super.key, this.perKilogram = false});
final bool perKilogram;
// Dentro de build:
final suffix = perKilogram ? ' x Kg' : '';
// Añadir suffix al texto normal y al texto del precio vigente.
```

Solo el detalle llama `Prices(p, perKilogram: true)`. Todos los otros usos conservan el
valor por defecto. No convertir importes ni inferir precios desde la presentación;
la unidad es el texto solicitado en SPEC-008. KG-AC-03.

En el `ProductPhoto` existente dentro de `ProductDetailView`, conservar los
argumentos de imagen, media y etiqueta, y añadir:

```dart
fit: BoxFit.cover,
```

El componente ya conoce este fit por las tarjetas; se reutiliza sin cambiar
fallback, reserva 4:3 ni política de tamaño decodificado. KG-AC-05.
