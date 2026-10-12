# Preparación técnica — decodificación de fotos

Estado: implementación autorizada tras baseline host real y preservación del APK
baseline profile. Pendiente comparación física y validación QA independiente.
Baseline host: prueba original archivada en
`artifacts/performance/image_decode_baseline_test.dart.txt` y resultado en
`artifacts/performance/image_decode_baseline.json`, tarjeta 352×264 dp, DPR 3,
original 4000×3000; RenderImage confirmó 4000×3000 y 48 000 000 bytes RGBA/cache.
Esta evidencia demuestra resolución sobredimensionada, no tiempos nativos.

## Hallazgo comprobado en código

`ProductPhoto` entrega el `ImageProvider` original a `Image`. El layout reserva
4:3, pero no fija tamaño de decode. En Flutter local, `ResizeImagePolicy.fit`
conserva aspecto y cabe dentro de ambos límites; no proporciona una política
cover. `exact` con dos dimensiones puede deformar el original. El SDK permite
envolver `ImageDecoderCallback`: su `getTargetSize` recibe ancho y alto intrínsecos
antes de decodificar. No hacen falta lecturas adicionales de metadatos ni cambios
en `MediaManager`.

Fuentes inspeccionadas: `C:/src/flutter/packages/flutter/lib/src/painting/image_provider.dart`
(ImageDecoderCallback y ResizeImage.loadImage) y
`C:/src/flutter/bin/cache/pkg/sky_engine/lib/ui/painting.dart`
(instantiateImageCodecWithSize/TargetImageSize).

## Parche propuesto después de baseline

1. Añadir `lib/ui/layout_image_provider.dart`, envoltorio de ImageProvider.
   Clave inmutable: clave del proveedor base, ancho y alto físicos objetivo y fit.
   Delegar obtainKey y loadImage al proveedor base; solo envolver decode y su
   getTargetSize. Propagar excepciones al fallback actual; expulsar la clave
   envolvente de ImageCache mediante listener efímero ante error, siguiendo SDK.
2. En ProductPhoto colocar LayoutBuilder dentro de AspectRatio. Calcular ancho
   y alto físicos como ceil(bounds × MediaQuery.devicePixelRatioOf(context)).
   Utilizar proveedor base si bounds no son finitos/positivos; no utilizar ancho
   de pantalla ni resolver metadatos en build.
3. En callback, originales w,h y bounds físicos W,H:
   - contain: s = min(1, W/w, H/h).
   - cover: s = min(1, max(W/w, H/h)).
   - resultado: max(1, ceil(w*s)), max(1, ceil(h*s)), acotado al original.
   La pequeña diferencia de redondeo es menor que un píxel; no usar relación 4:3
   como proporción del original. No ampliar imágenes pequeñas.
4. Conservar Image.fit, fondo, alternativa textual, errorBuilder, etiqueta de
   galería y dimensiones 4:3. Detalle/edición siguen contain y se ajustan al layout
   real sin modificar archivos originales. No cambiar límites globales de caché.

La política cover puede conservar un eje grande en fotos muy panorámicas: es
necesario para cubrir una tarjeta sin perder detalle al recortar. Para la fixture
4000×3000 se reduce de manera predecible. No introducir un límite absoluto que
degrade fotos extremas sin evidencia; documentar esta limitación y medirla.

Ejemplo: original 4000×3000 y bounds físicos 1080×810 → ambos fits producen
1080×810 (~3.5 MB RGBA frente a 48 MB). Original vertical 3000×4000 en esos bounds:
cover 1080×1440 (~6.2 MB); contain 608×810 (~2 MB), con igual proporción visual.

## Verificación prevista

- Pruebas de cálculo: horizontal 4:3, vertical, panorama, original pequeño,
  bounds mínimos y DPR fraccional; cover cubre ambos ejes y contain cabe en ambos.
- Resolver MemoryImage PNG generado con dimensiones reales mediante el nuevo
  proveedor y comprobar ImageInfo.image.width/height. Probar cover y contain,
  no limitarse a inspeccionar los parámetros del wrapper.
- Comprobar que claves iguales reutilizan ImageCache y que tamaño/fit diferente
  producen claves distintas; expulsión correcta tras error y fallback audible.
- Widgets existentes con tema/texto ampliado deben conservar estructura visual.
- Coordinador compara resolución/bytes reales, ImageCache y memoria de proceso
  en profile físico; pruebas host no acreditan rendimiento nativo.

No tocar VM, rutas ni transiciones desde esta tarea; sus propietarios separados
deben coordinar cualquier cambio en widgets compartidos.
