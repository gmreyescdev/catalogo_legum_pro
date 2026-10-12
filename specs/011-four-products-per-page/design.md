# Diseño — Cuatro productos por página

Skill local `flutter-product-design` aplicada para preservar identidad. Es un
documento estático sin controles M3; la app mantiene su interfaz. El usuario
confirmó resumen con puntos suspensivos en las tarjetas, sin anexo completo.

## Página y grilla

A4 vertical 595,28 × 841,89 pt, margen 28 pt. Ancho útil 539,28 pt. Grilla fija
2 × 2, medianiles 14 pt, tarjeta aproximada 262,64 × 320 pt; grilla alta 654 pt.
Orden por filas: productos 1/2 arriba y 3/4 abajo. Agrupar selección final en
bloques de cuatro y generar una `pw.Page` por bloque. Última página tiene solo
1–3 tarjetas reales; conservar posiciones de grilla sin bordes/etiquetas ficticias.

Cabecera compacta forest `#285343`, altura 72 pt, padding 10 pt, logo completo
52 × 52 pt contain, gap 12 pt. Título blanco 18 pt bold; modalidad/cantidad 10 pt
blanco en líneas separadas. Gap inferior 12 pt. Footer de marca y paginación 9 pt,
altura 22 pt y separación superior 12 pt. Total reservado 772 pt, dentro de
785,89 pt útiles; margen adicional evita colisiones y no cambia cantidad por página.

## Tarjeta

Fondo blanco, borde fino `#D5DDD3`, padding 10 pt. Mantener NotoSans local,
forest, texto secundario `#526157`, imagen sobre `#F0F3E9`, precio sobre mint
`#E7F2E8`. Sin sombras ni apariencia de botón.

- Nombre 11,5 pt bold forest, área 49 pt, máximo tres líneas con puntos suspensivos.
  La altura se ajusta tras el render para no cortar la tercera línea NotoSans.
- Gap 6 pt y foto 100 pt de altura, ancho interior disponible, contain centrado,
  sin deformación/recorte; fallback textual de imagen ausente/corrupta.
- Gap 8 pt y presentación 10 pt secundaria, área 26 pt, máximo dos líneas con
  puntos suspensivos. Conservar etiqueta «Presentación».
- Gap 8 pt y bloque de precio 60 pt con fondo mint/padding 8 pt: normal tachado
  9,5 pt si oferta; vigente 14 pt bold forest. Todos los precios completos con
  `CLP x Kg`; permitir salto de línea, sin ellipsis ni ocultar dígitos. Comprobar
  importes extremos admitidos por el modelo y ajustar espacio sin recortar valores.
- Gap 8 pt y disponibilidad con texto 10 pt bold, área 20 pt: «Disponible» forest
  sobre fondo claro o «Agotado» `#8C2C26` sobre `#FBE9E7`. Estado textual explícito.

Presupuesto vertical: padding 20 + nombre 49 + foto 100 + presentación 26 + precio
60 + disponibilidad 20 + gaps (6 + 8 + 8 + 8) = 305 pt. Restan 15 pt libres
dentro de la tarjeta de 320 pt; no introducir otros márgenes que excedan ese espacio.
Si los importes extremos requieren el espacio adicional previsto por el codificador,
la foto puede bajar a 76 pt, conservando contain y dejando precios completos;
esta variante debe comprobarse en el render y no reduce el área del nombre.

No reducir toda la tarjeta por `FittedBox` para acomodar texto largo. El resumen
es visual y solo afecta nombre/presentación del PDF; datos originales y detalle
de app conservan contenido completo. No anexo, descripciones, SKU ni campos nuevos.

## Composición orientativa

```dart
for (var start = 0; start < selection.length; start += 4) {
  final chunk = selection.skip(start).take(4).toList();
  document.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (_) => pageWithHeaderGridAndFooter(chunk),
  ));
}
```

La grilla usa dimensiones conocidas y filas fijas, sin flujo de un producto a otra
página. Inspeccionar 1/3/4/5/8/9 productos, fotos verticales/panorámicas, ofertas y
nombres extensos. Mantener archivos completo/personalizado y comportamiento de
compartir. No se declara contraste ni render verificados en este documento.
