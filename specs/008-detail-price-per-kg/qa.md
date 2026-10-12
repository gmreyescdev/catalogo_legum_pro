# QA — SPEC-008: precio por kilogramo e imagen ajustada en detalle

Estado: precio e imagen implementados, verificados e instalados en Android
0.6.1+8. Casos físicos adicionales e iOS se distinguen abajo. La build que
contenía solo el cambio de precio no se instaló.

## Casos de verificación

| Caso | Criterios | Comprobación | Estado |
| --- | --- | --- | --- |
| KG-QA-01 — Precio normal | KG-AC-01 | Abrir detalle de producto sin oferta y comprobar `Precio: <importe CLP> x Kg`. | Conforme en Android físico: `Precio: $1.500 CLP x Kg`. |
| KG-QA-02 — Oferta | KG-AC-02 | Abrir detalle con oferta; ambos importes indican `x Kg`, normal tachado y distintivo Oferta conservados. | Inspección estática conforme; visual física pendiente. |
| KG-QA-03 — Alcance | KG-AC-03 | Revisar los otros usos de Prices y comprobar que catálogo, selección y panel mantienen texto previo; sin cambio en valores/presentación/PDF. | Inspección estática conforme; 14 regresiones existentes de interfaz aprobadas. |
| KG-QA-04 — Validación y entrega | KG-AC-04 | Formato, análisis y pruebas de interfaz pertinentes; build 0.6.1+8, verificar aplicación normal y actualizar Android físico con `adb install -r`. Confirmar resultado antes de abrir. | Ejecutado: formato/análisis, 20 pruebas, build e instalación Success. |
| KG-QA-05 — Imagen ajustada | KG-AC-05 | Abrir detalle con foto horizontal/vertical; comprobar marco 4:3 lleno mediante cover, recorte proporcional sin estiramiento. Cambiar fotos de galería y revisar fallback/etiqueta accesible; conservar decode por bounds/DPR y originales/PDF. | Cover implementado; 6 pruebas de fotos aprobadas; fotografía disponible llena marco en Android. Más orientaciones/galería físicas pendientes. |

## Revisión independiente ejecutada — 2026-10-08

- `Prices` incorpora `perKilogram`, con valor predeterminado `false` y sufijo
  literal ` x Kg` únicamente cuando está habilitado.
- Único uso habilitado encontrado: `ProductDetailView`.
- Producto sin oferta usa `clp(product.currentClp)` con sufijo; con oferta, normal
  usa `clp(product.normalClp)` y vigente usa `clp(product.currentClp)`, ambos con
  sufijo. El normal conserva `TextDecoration.lineThrough` y el distintivo Oferta.
- Los usos en tarjeta pública, selección y panel administrativo omiten la opción,
  por lo que mantienen el valor predeterminado sin sufijo.
- No se detectó modificación del modelo, importes ni datos persistidos dentro de
  este cambio. Es una modificación de presentación del componente.

Esta revisión de código no equivale a pruebas ejecutadas, inspección en teléfono
ni ejecución iOS. No se añadieron pruebas que reproduzcan literalmente el cambio
de texto; se ejecutaron las regresiones de interfaz existentes.

## Verificaciones host ejecutadas

Estos resultados corresponden al cambio de precio antes de incorporar cover
en la imagen del detalle; no acreditan todavía la ampliación KG-AC-05.

- Formato Dart de los dos archivos modificados: EXIT 0, sin cambios pendientes.
- `flutter analyze`: EXIT 0, sin incidencias.
- `flutter test test/ui/catalog_app_test.dart --reporter expanded`: EXIT 0,
  14 pruebas aprobadas, incluyendo detalle, catálogo ampliado, selección, bloqueo
  de sesión y navegación existentes. No se presentan como prueba física del sufijo.

## Protocolo adicional para imagen

- Verificar que `ProductPhoto` del detalle reciba `BoxFit.cover`; preservar
  AspectRatio 4:3, controles anterior/siguiente, foto seleccionada y etiqueta.
- Mantener las fotos originales: el ajuste visual admite recorte de bordes,
  conserva proporción y no estira la imagen ni cambia archivos/PDF.
- Tras el cambio, ejecutar análisis y las 14 pruebas de interfaz existentes,
  junto a las 6 pruebas de ProductPhoto que verifican decodificación proporcional,
  bounds/DPR, caché y fallback; registrar el resultado real, no extrapolarlo.
- Compilar la entrega que reúna precio e imagen. Verificar identidad normal y
  éxito de `adb install -r` antes de afirmar actualización o revisar el teléfono.
- Inspección física de precio y foto ajustada queda separada de las verificaciones
  host. Si los productos disponibles no cubren orientación/galería/oferta,
  registrar esos casos pendientes sin alterar el catálogo del usuario.

## Pendientes

Inspección física de producto con oferta, otras orientaciones y varias fotos de
galería. No se modificó el catálogo del usuario para generar esos escenarios.
iOS requiere un entorno con Xcode y dispositivo;
la ejecución Android no acredita esa plataforma.

## Verificaciones conjuntas posteriores a KG-AC-05

- Foto activa del detalle recibe `fit: BoxFit.cover`; galería y etiqueta conservan
  su implementación, y el decode sigue usando dimensiones/DPR con proporción.
- Formato Dart: EXIT 0, dos archivos sin cambios pendientes.
- `flutter analyze`: EXIT 0, sin incidencias.
- `flutter test test/ui/catalog_app_test.dart test/ui/product_photo_performance_test.dart --reporter expanded`:
  EXIT 0, 20 pruebas existentes aprobadas (14 interfaz, 6 fotos/decode).
- Primera compilación conjunta falló: el registro generado Java incluyó
  IntegrationTestPlugin sin su dependencia release. Ocurrió al compilar mientras
  corrían herramientas de pruebas Flutter; se repite la compilación de forma
  secuencial una vez finalizadas. No se instaló ese artefacto fallido.

## Entrega física conjunta — 2026-10-08

Recompilación secuencial: EXIT 0, APK release 23,1 MB. El registro generado quedó
correcto sin modificar manualmente plugins. AAPT confirmó paquete normal
`com.example.catalogo_legum_pro`, versión 0.6.1/code 8. `adb install -r`: Success;
dumpsys confirma versión instalada. Apertura nativa Status ok, sin desinstalar,
sembrar productos ni reemplazar datos.

Toque de detalle en Android físico: captura
`artifacts/008-detail-price-per-kg/android-detail-price-and-photo.png` muestra
`Precio: $1.500 CLP x Kg` y foto llenando el marco sin bandas laterales. Conserva
contenido, presentación y controles del detalle. Se dejó esa pantalla abierta.
Evidencia de build en `artifacts/008-detail-price-per-kg/legumpro-0.6.1-release.apk`.
