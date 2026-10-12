# Diseño — Catálogo PDF con presentación editorial

Estado: rediseño e implementación autorizados por el usuario. No requiere otra
aprobación. Sustituye la composición básica anterior; conserva datos del catálogo.
Skill local `flutter-product-design` aplicada para conservar identidad de marca.
PDF estático, sin simular controles táctiles M3 ni cambiar UI de app.

## Formato y paleta

A4 vertical blanco, márgenes 36 pt. Forest `#285343` para títulos/precio, texto
principal `#26352D`, secundario `#526157`, fondo claro `#F0F3E9`, mint `#E7F2E8`
y separador `#D5DDD3`. NotoSans regular/bold local. Decisiones editoriales, no
tokens nuevos de app. Revisar contraste/legibilidad al renderizar; sin declarar
validación numérica antes de comprobarla.

## Cabecera

Banda forest padding 12 pt; logo completo `assets/branding/legumpro-logo.jpg`
70 × 70 pt contain sin editar, gap 14 pt, columna blanca: «Catálogo LegumPro»
22 pt bold, «Catálogo completo» o «Catálogo personalizado» 13 pt según scope,
y `<N> productos` 13 pt. N deriva de selección visible final deduplicada, singular
si N=1. Separación inferior 18 pt. Repetir por página sin portada. PDF-AC-02/03.

## Producto

Una columna con widgets independientes directos de `MultiPage.build`; nunca
envolver producto entero en tarjeta/Container/fila de tabla indivisible:

1. Nombre 20 pt bold forest completo `TextOverflow.span`, gap 12 pt.
2. Foto centrada en ancho disponible, marco 190 pt, fondo claro, padding 10 pt,
   contain sin recortar. Fallback «Imagen no disponible» en mismo marco. Gap 14 pt.
3. `Presentación: ...` 11 pt secundario, completo span sin altura fija, gap 10 pt.
4. Bloque atómico de precio fondo mint padding 12 pt: normal tachado 10 pt
   secundario si oferta y vigente `Oferta: ...` o `Precio: ...` 20 pt bold forest.
   Todos `CLP x Kg`; conservar importes/formato. Agrupar solo estos textos acotados,
   nunca nombre/presentación. Gap 10 pt.
5. Distintivo textual no interactivo, padding horizontal 10/vertical 6, 10 pt bold:
   «Disponibilidad: Disponible» forest/fondo claro; «Disponibilidad: Agotado»
   `#8C2C26` sobre `#FBE9E7`. Estado explícito no depende del color.
6. Gap 20 pt, línea fina `#D5DDD3`, gap 20 pt al siguiente.

`NewPage(freeSpace: 450)` antes del producto posterior reserva espacio suficiente
para el bloque habitual de unos 400 pt y evita iniciar un producto con solo parte
de sus campos en el resto de página; sujeto a inspección de huérfanos.
Densidad natural 1–2 productos/página según
contenido, sin forzar cantidad. Textos extensos continúan entre páginas; no
encerrarlos en fondos indivisibles. PDF-AC-01/04.

## Footer y conservación

Línea superior y gap 8 pt, «LegumPro» izquierda y `<página> / <total>` derecha,
9 pt secundario. Texto extraíble; logo no sustituye título. No afirmar PDF
etiquetado accesible sin verificar. Conservar archivos, selección, orden, retención
y compartir. Sin descripción, SKU, categoría, contactos ni campos nuevos.
Precio Kg no convierte datos. Fotos PDF mantienen contain. PDF-AC-03/05.

## Base de composición

```dart
widgets.addAll([
  if (index > 0) pw.NewPage(freeSpace: 450),
  pw.Text(product.name, overflow: pw.TextOverflow.span, style: nameStyle),
  pw.SizedBox(height: 12),
  imageFrame, // Marco 190 pt contain o fallback.
  pw.SizedBox(height: 14),
  pw.Text('Presentación: ${product.presentation}',
      overflow: pw.TextOverflow.span, style: presentationStyle),
  // Precio atómico, distintivo y separador independientes.
]);
```

Logo cargado una vez/generación. Inspeccionar páginas intermedias/finales del
texto extenso además de primera.

## Referencia primaria

[MultiPage de pdf](https://pub.dev/documentation/pdf/latest/widgets/MultiPage-class.html)
explica flujo y restricciones de widgets interiores indivisibles. Código instalado
mantiene continuación para `TextOverflow.span`; conservar textos directos del build.
