# QA — SPEC-002: selección compartida como PDF

Estado: 67 pruebas host y escenario nativo Android aprobados; resultados detallados
al final. Las inspecciones de código no equivalen a pruebas aprobadas.
No iniciar emuladores ni enviar archivos a contactos durante la verificación.

## Matriz de aceptación

| Criterio | Comprobación | Evidencia requerida |
| --- | --- | --- |
| PDF-AC-01 | Vacío no invoca compartidor. Selección conserva orden del catálogo, incluye agotados y excluye ocultos/eliminados tras cambios del repositorio. Búsqueda/filtros no pierden selección. | Pruebas VM y UI con catálogo mutable. |
| PDF-AC-02 | PDF contiene únicamente seleccionados vigentes: nombre, presentación, imagen de portada, CLP vigente y disponibilidad textual. Oferta muestra ambos precios. Ausentes descripción, SKU, secretos y productos ajenos. | Prueba del generador y extracción/inspección del PDF sintético. |
| PDF-AC-03 | Generación sin dependencias de red; portada ausente/corrupta muestra alternativa. Texto extenso no desaparece ni desborda; acentos españoles visibles. | Casos del servicio más inspección de páginas renderizadas con texto largo. |
| PDF-AC-04 | Compartidor recibe archivo existente `application/pdf` con nombre legible; funciona sin número configurado. Se informa elegir WhatsApp y cliente; nunca se afirma envío. | Pruebas del adaptador y apertura del selector en Android físico. Envío real queda manual. |
| PDF-AC-05 | Error/cancelación mantiene selección y catálogo. Doble pulsación no genera dos operaciones. Progreso/error visible y selección conservada al cambiar lifecycle. | Pruebas VM/UI con operación diferida, error y cancelación; dispositivo físico para lifecycle nativo. |
| PDF-AC-06 | Acciones M3 con área de toque mínima 48 dp, separación 24 dp campo/acción, legibles en ancho 320 dp y escala 2. No quedan etiquetas de consulta ni destinatario fijo en ajustes. | Widget tests, revisión UI y control físico. |
| PDF-AC-07 | Abrir base/backup v2 anterior sigue funcionando. PDF privado retenido para lectura externa; se limpia al iniciar/generar después de 24 h; cancelar/error confirmado limpia inmediatamente y arranque limpia antiguos sin borrar recientes. | Regresión SQLite/backup, pruebas de temporales, formato/análisis/suite/build y Android físico. |

## Límites de validación

- Pruebas host de lógica/widgets no validan plugins nativos.
- Android: exclusivamente dispositivo físico; registrar ID, comandos y resultados
  cuando se ejecuten. Abrir selector no demuestra recepción por WhatsApp.
- iOS: pendiente de entorno macOS/Xcode y dispositivo; no inferir aprobación
  desde Android. Revisar ancla del selector para iPad mediante contrato/fake.
- No sustituir las evidencias anteriores de SPEC-001; esta matriz cubre el cambio
  PDF y sus regresiones.

## Resultados ejecutados

Consultar «Ejecución coordinada» y «Android físico» al final para comandos,
resultados, artefactos y limitaciones reales.

## Inspección independiente (sin ejecución)

Revisados `NativeWhatsAppGateway`, `CatalogViewModel`, pantallas públicas y
bootstrap. El servicio copia la selección antes de las operaciones asíncronas;
renderiza explícitamente los campos permitidos, sin serializar el producto
completo. Portada ordenada, límites de bytes/píxeles, reducción a 800 px y
reencodificación PNG con fallback. Compartidor con MIME PDF y ancla, limpieza de
archivos propios antiguos, conservación tras resultado no cancelado. Ajustes no
exponen número fijo y bootstrap conserva compatibilidad de almacenamiento.
Estas observaciones no acreditan que el PDF se renderice correctamente ni que
WhatsApp reciba el archivo.

Casos QA independientes preparados en
`test/qa/pdf_selection_regression_test.dart`: vacío, orden/agotados/filtros/sin
teléfono/ancla, exclusión posterior de ocultos/eliminados y lectura de valores
vigentes, error/reintento sin mutación y bloqueo de doble comando. La cancelación
nativa y el contenido visual se verifican además en las pruebas del servicio.

## Defectos

Registrar aquí defectos reproducibles, corrección y evidencia de repetición.

## Ejecución coordinada — 2026-10-08

- Formato final: 29 archivos, 0 cambios, EXIT0.
- `flutter analyze`: EXIT0, sin observaciones.
- `flutter test --reporter expanded`: EXIT0, 67 pruebas aprobadas. Incluye 8 del
  servicio PDF, 5 regresiones QA de selección y 10 pruebas UI, además de regresiones
  de autenticación, SQLite, medios y respaldos. Las 4 pruebas del flujo anterior
  de mensajes WhatsApp fueron sustituidas por 8 del flujo PDF.
- `flutter test tool/pdf_smoke_test.dart --reporter expanded`: EXIT0, 1 escenario
  de generación real con fuentes/fotos locales, sin usar compartidor externo.
- PDF de ejemplo renderizado e inspeccionado con PyMuPDF:
  `artifacts/qa-pdf/catalogo-ejemplo.pdf` (1 página, 2 productos sintéticos).
  Texto extraído confirma acentos, presentación, precio normal/oferta y Disponible/
  Agotado; 2 imágenes incrustadas; descripción y SKU excluidos.
- Caso extremo `artifacts/qa-pdf/catalogo-texto-largo.pdf`: 13 páginas.
  Extracción independiente confirma 350 frases completas del nombre y 1000 de
  presentación, con marcadores finales y sin truncamiento. Se excluyeron cabeceras/
  pies al contar frases que cruzan página. Primera página del ejemplo y última
  del caso largo inspeccionadas visualmente; PNG en el mismo directorio.
- Build debug Android v0.3.0+3 con configuración local: EXIT0.
  La compilación final del APK instalable y prueba nativa se registran abajo.

Correcciones de pruebas durante integración: tipo de bytes de lector PDF, lectura
mínima que no reconstruía espacios expresados mediante offsets TJ y botón fuera
 del viewport al insertar progreso. Se corrigieron las pruebas; los resultados
 anteriores fallidos no son evidencia de aprobación. PyMuPDF independiente
 confirma los espacios/texto del archivo generado.

Los PDF de más de 24 horas se limpian al iniciar/generar; no se promete borrado
exacto mientras la app está cerrada. El dato telefónico legado sigue compatible
con SQLite/backups pero no interviene en compartir.

### Android físico — PDF

`flutter test integration_test/native_pdf_test.dart -d <Android físico> --reporter expanded`:
EXIT0, 1 prueba aprobada en Android 15 (USB, modelo 23049PCD8G), 17 s de ejecución.
Generación local con foto PNG nativa, PDF real y MIME correcto. El selector
`com.android.intentresolver/.ChooserActivity` quedó en primer plano; se canceló
con Back y share_plus devolvió `dismissed`. No se eligió destinatario ni se envió
contenido. La prueba usa directorio temporal y producto sintético, conserva su
selección y elimina solo sus fixtures; no modifica catálogo/credenciales reales.

Esto acredita generación/apertura/cancelación del selector Android, no recepción
por WhatsApp. El recorrido completo lifecycle entre aplicaciones y entrega manual,
así como iOS/VoiceOver, permanecen pendientes. La suite host acredita conservación
 de selección tras error/cancelación y rechazo de comandos duplicados.

### APK final e instalación

Build final debug Android v0.3.0+3 EXIT0 (29,7 s), usando configuración privada.
`adb install -r` en el Android físico: Success; se abrió MainActivity de la app
normal después de la integración. No se borraron datos ni se cargaron fixtures
al catálogo real.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256: `19B76B6B7765CA1E6710C724BC83AB9175709CF324596CAF361C6901F412730F`.
Pendientes: envío manual y recepción en WhatsApp, lifecycle completo con esa app,
matriz de accesibilidad física e iOS/Xcode. No inferir entrega por abrir selector.
