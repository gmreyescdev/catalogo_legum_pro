# QA — SPEC-009: abrir detalle desde la imagen

Estado: revisión estática, verificaciones host y entrega Android completadas.
Resultados finales y límites en las secciones de ejecución siguientes; los
estados de la tabla inicial corresponden al protocolo previo a la ejecución.

## Casos de aceptación

| Caso | Criterios | Procedimiento | Estado |
| --- | --- | --- | --- |
| IMG-QA-01 — Destino | IMG-AC-01 | Tocar la imagen de una tarjeta y comprobar que el detalle corresponde a su ID/nombre. Regresar al catálogo. | Inspección estática conforme; ejecución pendiente. |
| IMG-QA-02 — Selección independiente | IMG-AC-02 | Confirmar ausencia de «Ver detalle» en tarjetas; seleccionar/deseleccionar con checkbox actualiza selección sin abrir una ruta. | Inspección estática conforme; ejecución pendiente. |
| IMG-QA-03 — Accesibilidad y alternativa | IMG-AC-03 | Revisar acción de botón «Abrir detalle de <nombre>», área táctil mínima y foco/activación por teclado. Foto ausente/inválida mantiene alternativa y navegación. | Inspección estática conforme; verificación de foco/activación y física pendiente. |
| IMG-QA-04 — Presentación y regreso | IMG-AC-04 | Preservar cover, proporción 4:3, decode por bounds/DPR, precios x Kg del detalle y navegación Material. Comprobar regreso por botón; gesto nativo separado. | Inspección estática conforme; ejecución pendiente. |
| IMG-QA-05 — Entrega | IMG-AC-05 | Formato, análisis y pruebas existentes de interfaz adaptadas al nuevo acceso; build normal y `adb install -r` en Android físico. Confirmar instalación antes de anunciarla. | Pendiente. |

## Protocolo de revisión independiente

- El área interactiva debe envolver solo ProductPhoto, sin incorporar el checkbox
  ni el resto de la tarjeta. Revisar InkWell/foco y semántica sin duplicar acción.
- El destino usa `product.id` de la tarjeta y `ProductDetailView` con el mismo VM;
  mantiene MaterialPageRoute y retorno existentes.
- El InkWell permanece aun cuando ProductPhoto use fallback por foto ausente o
  error. La alternativa textual no se pierde en el árbol accesible.
- Revisar que la eliminación del botón no cambie precios, disponibilidad,
  selección ni otros usos de fotos. No añadir pruebas que solo reproduzcan texto.
- La prueba de navegación existente debe activar el nuevo acceso de imagen y
  seguir comprobando detalle/retorno. Ejecutar pruebas y análisis de manera
  secuencial respecto de la build Android para evitar artefactos concurrentes.

## Límites

Inspección estática, pruebas host y validación física se registran separadas.
Las pruebas de widgets no acreditan gesto nativo ni lector de pantalla físico.
No sembrar ni reemplazar el catálogo del usuario para completar casos de fotos.
Si no hay foto inválida/ausente en datos reales, registrar cobertura disponible y
casos pendientes. No usar emuladores. iOS queda pendiente de su entorno nativo.

## Revisión independiente de implementación — 2026-10-08

- ProductTile envuelve únicamente ProductPhoto con Semantics e InkWell. El
  checkbox queda fuera y conserva su callback de selección independiente.
- La etiqueta `Abrir detalle de <nombre>` y acción semántica usan `_openDetail`;
  InkWell usa el mismo método con su acción semántica excluida para no duplicarla.
  Mantiene el foco/activación por teclado estándar de InkWell, no deshabilitados.
- `_openDetail` navega con MaterialPageRoute a ProductDetailView usando
  `product.id` y el mismo VM. Se retiró el botón anterior de la tarjeta.
- El área interactiva permanece cuando ProductPhoto muestra su alternativa por
  ausencia/error. No se excluye la alternativa textual del árbol accesible.
- ProductPhoto conserva cover y su implementación de decode; el detalle mantiene
  precios por Kg y navegación existentes.
- La prueba de navegación existente fue adaptada para tocar la imagen y comprobar
  destino ID, retorno y selección preservada; inspeccionar el test no acredita
  que haya pasado. Resultados de ejecución se añadirán por el coordinador.

Sin defectos bloqueantes confirmados por esta inspección. No equivale a validación
ejecutada de teclado, árbol semántico completo ni dispositivo físico.

## Ejecución host — 2026-10-08

- Formato de los dos archivos Dart afectados: correcto, sin cambios pendientes.
- `flutter analyze`: sin incidencias.
- `flutter test test/ui/catalog_app_test.dart --reporter expanded`: 14 pruebas
  aprobadas, incluida navegación desde imagen, destino correcto, ausencia de
  botón y conservación de selección tras volver a escala de texto 2.
- La primera ejecución falló porque el test encontraba un checkbox montado pero
  fuera de pantalla. Se corrigieron sus finders con `hitTestable()` para desplazar
  y tocar controles visibles; la segunda ejecución completa pasó.
- La capa Material transparente sobre la foto conserva la respuesta visual de
  InkWell. La imagen y el checkbox permanecen en áreas interactivas separadas.

Pendientes: lector de pantalla y teclado físicos, gesto nativo y compilación iOS.

## Entrega y ejecución Android — 2026-10-08

- Build release arm64 completada después de las pruebas, versión 0.6.2+9.
- AAPT confirmó paquete normal `com.example.catalogo_legum_pro`, código 9 y
  versión 0.6.2 antes de instalar.
- `adb install -r` devolvió Success en el Android físico 99934aee. No se
  desinstaló la app ni se reemplazaron datos. El catálogo existente sigue visible.
- Tocar la foto de Poroto Tortola abrió su detalle, con imagen ajustada y precio
  `$1.500 CLP x Kg`. El botón anterior no aparece entre disponibilidad y checkbox.
- Regresar mediante Back nativo volvió al catálogo. Selección independiente y
  regreso por botón quedaron cubiertos por la prueba de widgets.
- Evidencia: `artifacts/009-image-opens-detail/android-catalog.png`,
  `android-detail.png`, `android-return.png` y `legumpro-0.6.2-release.apk`.

IMG-QA-01, 02, 04 y 05 tienen verificaciones ejecutadas host/Android descritas
arriba. IMG-QA-03 conserva revisión y comprobación de propiedades semánticas
host; teclado y lector físicos, gesto de borde, foto inválida en datos reales
e iOS siguen pendientes. No se usaron emuladores ni se modificaron productos.
