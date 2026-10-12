# QA — SPEC-010: diseño, logo y precios por Kg en PDF

Estado: implementación, revisión, verificaciones host y entrega Android completadas. La tabla
inicial registra el protocolo; los resultados ejecutados figuran al final.

## Casos de aceptación

| Caso | Criterios | Comprobación | Estado |
| --- | --- | --- | --- |
| PDF-QA-01 — Precio normal | PDF-AC-01 | Generar PDF sin oferta y extraer del documento `Precio: <importe CLP> x Kg`, conservando el importe esperado. | Pendiente. |
| PDF-QA-02 — Oferta | PDF-AC-01 | Generar producto con oferta: precio normal y vigente incluyen x Kg; importe normal/oferta, tachado y estilos se mantienen. | Pendiente. |
| PDF-QA-03 — Logo sin foto | PDF-AC-02/04 | Exportar producto sin foto/corrupto; comprobar logo en cabecera aun cuando solo existe fallback de producto. | Pendiente. |
| PDF-QA-04 — Logo y portada distintos | PDF-AC-02/03 | Exportar producto con fotografía y comprobar imagen oficial del logo diferenciada de la foto del producto; renderizar para revisar proporción y separación del título. | Pendiente. |
| PDF-QA-05 — Páginas largas | PDF-AC-02/04/06 | Documento multipágina con nombre/presentación largos y marcadores finales: logo en todas las páginas, texto completo, sin superposición ni desbordamiento. | Pendiente. |
| PDF-QA-06 — Modos y selección | PDF-AC-03 | Generar ambos scopes, comprobar basenames exactos, productos recibidos/orden, deduplicación y rechazo de ocultos/vacío; no alterar disponibilidad/presentación. | Pendiente. |
| PDF-QA-07 — Regresión y entrega | PDF-AC-05 | Formato, análisis, pruebas pertinentes sobre PDF emitido, render/inspección visual; build e instalación -r Android físico si conectado. | Pendiente. |
| PDF-QA-08 — Composición atractiva | PDF-AC-06 | Revisar render real con cabecera, fotografía destacada proporcional, nombre/presentación legibles, precio destacado, estado distinguible por texto y color, separación y footer numerado. | Inspección estática conforme; render pendiente. |

## Protocolo de revisión independiente

- Cargar el asset oficial existente, reutilizando su imagen sin rediseño y con
  proporción conservada. Ubicarlo en `MultiPage.header` para incluir cada página.
- El encabezado debe reservar su altura y espacio respecto al contenido;
  inspeccionar páginas inicial, intermedia y final del caso largo renderizado.
- Diferenciar prueba de logo de prueba de foto: exportación sin foto debe tener
  logo; exportación con foto debe incorporar ambos recursos. Contar imágenes
  indistintamente no demuestra que el logo oficial sea el que se incrustó.
- Verificar texto del PDF realmente emitido, incluyendo los dos precios de una
  oferta. Normalizar espacios de extracción cuando PDF codifique espacios con
  desplazamientos; conservar importes y semántica esperada.
- Preservar `LegumPro_Catalogo.pdf` y `LegumPro_Catalogo_Personalizado.pdf`,
  campos vigentes y generación según la lista explícita recibida. Revisar que no
  se modifiquen credenciales, base de datos, selección ni comportamiento de envío.
- Pruebas largas conservan marcadores de final y paginación para detectar contenido
  perdido por el mayor encabezado. Fotos ausentes/corruptas siguen con fallback.
- La ampliación «PDF más atractivo» no puede convertir un producto largo en una
  tarjeta/fila indivisible que desborde la página. Mantener flujo paginable del
  nombre y presentación; revisar primera, intermedia y última página del fixture
  largo después del rediseño. Disponibilidad siempre conserva texto, no solo color.
- No incorporar descripción ni SKU al mejorar jerarquía; conservar el conjunto
  de campos autorizado, orden y lista recibida. Diseño atractivo no acredita por
  sí mismo legibilidad o paginación: se verifica mediante el documento emitido.

## Límites y pendientes

Separar revisión de código, pruebas host de documentos, inspección de renders y
validación Android física. Un selector abierto no acredita entrega a WhatsApp ni
autorización para enviar a contactos. No reemplazar los datos del usuario ni usar
emuladores. La ejecución iOS queda pendiente de Xcode y dispositivo.

## Revisión independiente ejecutada — 2026-10-08

- `generateCatalog` carga el asset oficial `assets/branding/legumpro-logo.jpg`
  una vez, usando su rango de bytes completo y `pw.MemoryImage`. Header de
  MultiPage lo muestra en 70×70 pt con contain: conserva proporción y repite
  marca por página. Título, alcance y cantidad deduplicada permanecen textuales.
- La composición final usa cabecera forest con padding 12 pt y texto blanco:
  título 22 pt, alcance/cantidad 13 pt; logo 70 pt y gap 14 pt. Footer conserva
  marca textual y página/total, separados por línea. Esas posiciones requieren
  comprobación en render.
- Precio vigente y normal de oferta incluyen `CLP x Kg`, con los mismos campos
  numéricos y formato CLP. El normal conserva tachado; el vigente destaca en
  tamaño 20 pt y color forest sobre bloque mint. Solo el bloque corto de precios
  es atómico; no contiene los textos variables largos del producto.
- Nombre y presentación siguen como textos paginables (`TextOverflow.span`)
  directamente en la lista de MultiPage. No se encapsula el producto completo
  en una fila/tarjeta indivisible. Imagen tiene marco fijo 190 pt, contain y
  alternativa textual; los textos largos quedan fuera de ese marco.
- El salto preventivo entre productos usa `freeSpace: 450` para conservar un
  bloque corto completo cuando es posible; no vuelve indivisible al nombre ni a
  la presentación largos. El caso multipágina sigue requiriendo prueba emitida.
- Disponibilidad combina texto y color; selección, campos, nombres físicos de
  archivo y lógica de compartir/retención mantienen la implementación previa.
- Las pruebas de PDF propuestas distinguen el JPEG del logo de la foto de
  producto normalizada a PNG y cuentan usos del logo por página. Para acreditar
  identidad oficial, el coordinador puede comparar bytes/hash del JPEG extraído
  del PDF con el asset; contar recursos de imagen por sí solo no prueba identidad.

## Contraste calculado sobre colores implementados

QA calculó luminancia sRGB y relación `(Lmáxima + 0,05)/(Lmínima + 0,05)`:

| Texto / fondo | Relación |
| --- | --- |
| Blanco / `#285343` (cabecera) | 8,72:1 |
| `#285343` / blanco (nombre) | 8,72:1 |
| `#526157` / blanco | 6,55:1 |
| `#285343` / `#E7F2E8` (precio vigente) | 7,58:1 |
| `#526157` / `#E7F2E8` (precio normal de oferta) | 5,70:1 |
| `#285343` / `#F0F3E9` (disponible) | 7,76:1 |
| `#526157` / `#F0F3E9` (alternativa de foto) | 5,83:1 |
| `#8C2C26` / `#FBE9E7` (agotado) | 7,15:1 |

Son cálculos de pares concretos de color, no verificación de todos los elementos
del documento ni certificación de PDF etiquetado/accesible. Render, paginación,
integridad de contenido largo y legibilidad visual continúan pendientes.

## Ejecución host e inspección del documento — 2026-10-08

- Formato Dart de fuente y pruebas: correcto.
- `flutter test test/whatsapp/native_whatsapp_gateway_test.dart
  test/qa/pdf_selection_regression_test.dart --reporter expanded`: 22 aprobadas.
  Se comprobó el documento emitido: precios normal/oferta por Kg, ambos scopes,
  nombres de archivo, selección, imagen válida/corrupta y contenido extenso.
- `flutter analyze`: sin incidencias en ejecución final. Una ejecución previa
  señaló falta de llaves en un if del lector PDF del test; se corrigió.
- Exportados cinco documentos de ejemplo en `artifacts/010-pdf-brand-and-price`.
  Render independiente con PyMuPDF: ambos modos y vista previa tienen dos páginas;
  foto válida una página; caso extenso 16 páginas.
- En cada página de los cinco PDFs se localizó el logo dibujado y se comparó el
  SHA-256 del JPEG incrustado contra el asset oficial: coincidencia exacta.
- Texto extraído dentro de los márgenes en los cinco documentos. La prueba larga
  conserva marcadores finales y repeticiones completas de nombre/presentación.
- Inspección visual de las dos páginas de `LegumPro_Vista_Previa.pdf` y páginas
  1, 9 y 16 del caso largo: cabecera, proporciones, precio, etiquetas, separación
  y footer sin superposiciones observadas. La vista previa usa ilustraciones de
  productos reutilizadas de fixtures previos; no representa datos del usuario.
- Evidencia adicional: `render-verification.json`,
  `text-bounds-verification.json` y renders `*-page-*.png`.

## Entrega y exportación Android — 2026-10-08

- Build release arm64 completada, versión 0.6.3+10. AAPT confirmó paquete normal
  `com.example.catalogo_legum_pro`, versión 0.6.3 y código 10 antes de instalar.
- `adb install -r` devolvió Success en el Android físico 99934aee. La versión
  instalada se confirmó mediante PackageManager; el catálogo existente sigue
  visible sin desinstalar ni reemplazar datos.
- «Compartir catálogo completo» generó el archivo y abrió el selector nativo.
  La jerarquía UI confirmó `LegumPro_Catalogo.pdf`; se canceló sin enviar a contactos.
- APK y captura de catálogo en `artifacts/010-pdf-brand-and-price`.

Pendientes: inspección del PDF real del teléfono en visor externo, exportación
personalizada nativa (cubierta en host), entrega a contacto, PDF etiquetado/accesible
e iOS con Xcode. No se usaron emuladores ni se modificaron productos del usuario.
