# QA — SPEC-011: cuatro productos por página

Estado: revisión, documentos emitidos, verificaciones host, renders y entrega Android completados.
La tabla inicial corresponde al protocolo; resultados ejecutados al final.

## Casos de aceptación

| Caso | Criterios | Procedimiento | Estado |
| --- | --- | --- | --- |
| GRID-QA-01 — Conteo y reparto | GRID-AC-01 | Exportar N=1/4/5/8/9 únicos visibles: 1/1/2/2/3 páginas respectivamente, con 1; 4; 4+1; 4+4; 4+4+1 tarjetas. Última página sin tarjetas vacías. | Pendiente. |
| GRID-QA-02 — Orden | GRID-AC-01/04 | Extraer nombres/IDs de fixture identificables por página y revisar posiciones: izquierda→derecha, arriba→abajo, conservando orden recibido tras deduplicar. Repetir en ambos scopes. | Pendiente. |
| GRID-QA-03 — Contenido completo de tarjeta | GRID-AC-02 | Comprobar nombre, presentación, foto/fallback, disponibilidad, precio vigente x Kg y normal tachado x Kg si hay oferta. Importes no truncados. | Pendiente. |
| GRID-QA-04 — Texto excepcional | GRID-AC-02 | Nombre/presentación extensos terminan con puntos suspensivos dentro de reservas; no generan página adicional ni invaden tarjeta contigua. Valores originales permanecen intactos en app. | Pendiente. |
| GRID-QA-05 — Marca y legibilidad | GRID-AC-03 | Logo oficial y cabecera en cada página; revisar render A4 de cuatro y cinco productos, y último footer, sin superposición ni texto demasiado pequeño. | Pendiente. |
| GRID-QA-06 — Regresión de exportación | GRID-AC-04 | Ambos filenames exactos, selección, deduplicación, rechazo de vacío/ocultos, foto ausente/corrupta, retención y compartir intactos; sin descripción privada/SKU. | Pendiente. |
| GRID-QA-07 — Entrega | GRID-AC-05 | Formato, análisis y regresiones pertinentes ejecutadas; PDF emitido y renders revisados. Build e instalación -r Android físico si conectado, confirmar resultado. | Pendiente. |

## Protocolo de revisión independiente

- Revisar suma vertical de header, separaciones, dos filas, footer y márgenes:
  deben caber en la página A4 real. Las medidas de diseño no acreditan por sí
  mismas el resultado: comprobar documento guardado y render.
- Revisar agrupación en lotes de cuatro y orden de celdas. Último lote no puede
  dibujar una tarjeta/placeholder de producto inexistente.
- La truncación autorizada aplica exclusivamente a nombre y presentación
  excepcionalmente largos. No cortar precios/etiquetas x Kg/disponibilidad ni
  sustituir importes. No incorporar anexos para recuperar texto.
- Cubrir el máximo monetario admitido `9007199254740991` CLP y oferta válida:
  todos los dígitos, separadores y `x Kg` deben aparecer sin recorte. Si ocupan
  varias líneas, mantener altura acotada de tarjeta y tipografía legible.
- Revisar elipsis Unicode real `U+2026`, acentos y caracteres fuera de BMP:
  la lógica no debe dividir pares UTF-16 ni sustituir texto por signos de pregunta
  debido a errores de codificación de archivos fuente.
- Documento emitido debe demostrar conteo de páginas y campos por página, no
  solo cantidad de widgets/listas previa a generación. Comprobar marcas/posiciones
  de fixture para detectar saltos, duplicados o distribución incorrecta.
- Foto usa proporción conservada y alternativa si falla. Distinguir logo de
  producto; marca repetida en todas las páginas, incluso sin foto de producto.
- Revisar separación de tarjetas, filas y reservas: ofertas con dos importes,
  agotado y nombres extensos no pueden empujar footer ni atravesar otra celda.

## Cambio respecto a SPEC-010

SPEC-011 sustituye la prueba anterior de conservación completa de texto largo en
el PDF por resumen autorizado con puntos suspensivos para nombre/presentación.
El original en la app sigue completo. No exigir aquí marcadores finales de esos
dos campos en PDF ni permitir que el texto extenso rompa el límite de cuatro por
página. Se conserva la obligación de no perder precios, disponibilidad y productos.

## Límites

Separar revisión estática, pruebas host del PDF, renders y Android físico. No
usar emuladores, reemplazar datos del usuario ni enviar a contactos durante QA.
No declarar PDF etiquetado accesible solo por contraste o texto extraíble.
iOS permanece pendiente de entorno nativo con Xcode.

## Revisión independiente de implementación — 2026-10-08

- La lista visible deduplicada se divide en lotes de cuatro; una `pw.Page` A4
  por lote conserva el orden recibido. Filas usan índices 0/1 y 2/3; las celdas
  inexistentes no dibujan tarjeta ni alternativa de producto.
- Márgenes 28 pt: área vertical 785,89 pt. Header 72 + gap 12 + grilla 654 +
  gap 12 + footer 22 = 772 pt, con 13,89 pt de holgura. Dos tarjetas de 320 pt
  separadas 14 pt forman la grilla; estas cuentas requieren verificar el PDF real.
- Cada tarjeta conserva nombre, presentación, foto contain/fallback, precio
  vigente x Kg, normal tachado x Kg si hay oferta y estado textual Disponible/Agotado.
- Nombre reserva tres líneas a 11,5 pt (altura ajustada a 49 pt tras el defecto
  visual indicado abajo) y presentación dos a 10 pt. `_summarize`
  mide avances de fuente y añade elipsis U+2026 en la última línea resumida;
  recorre runes, evitando dividir pares UTF-16. No se aplica a precios/estados.
- Precios grandes se miden con fuente/tamaño reales: el bloque pasa de 60 a
  84 pt y la foto de 100 a 76 pt, conservando altura de tarjeta. Los importes
  permanecen completos como texto, sin resumir ni bajar el tamaño de fuente.
- Logo 52 pt contain, cabecera por página y footer página/total se mantienen;
  nombres físicos, lista, retención, selector y campos privados mantienen alcance.
- Pruebas preparadas inspeccionan PDF emitido para N=1/3/4/5/8/9 en ambos scopes,
  nombres por página, deduplicación, logo, máximo importe y elipsis. Su existencia
  no acredita ejecución; orden geométrico, superposiciones y legibilidad requieren
  render independiente.

Durante la revisión intermedia se detectaron signos `?` literales por codificación
del escritor en cabecera/presentación/elipsis. El codificador corrigió con parche
UTF-8; la inspección final encuentra acentos y U+2026 correctos. Se conserva el
incidente como detección corregida, no como fallo presente del documento emitido.

La revisión estática inicial no detectó el recorte que luego evidenció el render.
Pendientes resultados posteriores a la corrección y nueva revisión visual antes
de dictaminar los casos.

## Defecto detectado al renderizar — GRID-DEF-01

El coordinador observó la tercera línea del nombre excepcional cortada y su
elipsis no visible. El PDF contenía los caracteres esperados y las aserciones de
extracción los encontraban: texto emitido no demuestra que todo sea visible.
La reserva original de 39 pt era insuficiente para las tres líneas reales.

Corrección aplicada por el codificador: nombre 39→49 pt; foto estándar
110→100 pt y foto con importe grande 86→76 pt. Se mantienen tarjetas de 320 pt,
grilla, precios y resto de campos. Inspección estática posterior confirma esos
valores; el total interior conserva la misma altura al compensar los 10 pt.

Estado del defecto: **corrección implementada, verificación pendiente**. Repetir
pruebas PDF y render del nombre largo; comprobar tercera línea y U+2026 visibles,
sin tocar la foto ni afectar los precios máximos. No cerrar el defecto solo con
extracción de texto. No se realizó build adicional desde QA.

## Resultados ejecutados por el coordinador — 2026-10-08

- Primer intento de pruebas: error de compilación al declarar como const un ancho
  obtenido de `PdfPageFormat.a4.width`. Corregido usando final.
- Suite PDF y selección: 35 pruebas aprobadas antes y después del ajuste visual.
  Verifican ambos scopes para 1/3/4/5/8/9 productos, asignación exacta por página,
  orden, máximos importes completos, selección, archivos y resumen autorizado.
- Formato final: dos archivos, sin cambios. Análisis final: sin incidencias.
- PyMuPDF independiente verificó y renderizó los 12 fixtures finales: páginas
  ceil(N/4), marcadores en sus páginas y cuadrantes correctos, logo oficial
  dibujado en cada página con SHA-256 idéntico al JPEG original y texto dentro
  de márgenes. Evidencia `artifacts/011-four-products-per-page/render-verification.json`.
- Inspección visual: cuadrícula de cuatro; segunda página con el quinto producto
  sin tarjetas ficticias; precio máximo entero y por Kg; nombre y presentación
  largos resumidos. Tras la corrección, la tercera línea y su elipsis son visibles
  en `long-summarized-page-1.png`: **GRID-DEF-01 cerrado mediante re-render**.
- Vistas con foto usan los gráficos de ejemplo previos, no datos del catálogo real.

## Entrega Android físico — 2026-10-08

- Build release arm64 completada después de pruebas. AAPT verificó paquete normal
  `com.example.catalogo_legum_pro`, versión 0.6.4 y código 11.
- `adb install -r` devolvió Success en 99934aee; PackageManager confirmó 0.6.4+11.
  Catálogo existente visible, sin desinstalar ni reemplazar datos.
- Exportación de catálogo completo abrió selector nativo mostrando
  `LegumPro_Catalogo.pdf`. Se canceló sin enviar a contactos.
- APK y captura de catálogo: `artifacts/011-four-products-per-page`.

Pendientes: inspección en visor del PDF real del teléfono y modalidad personalizada
nativa (ambas modalidades y cuadrícula verificadas en host), iOS con Xcode,
lector de PDF accesible/etiquetado y entrega a un contacto. Sin emuladores.
