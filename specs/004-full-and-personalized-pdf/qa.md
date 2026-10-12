# QA — SPEC-004

## Casos y trazabilidad

| Criterio | Verificación | Estado |
| --- | --- | --- |
| SHARE-AC-01 | Completo ignora búsqueda, categoría y selección, conserva orden e incluye agotados; excluye ocultos. Vacío y solo ocultos no invocan compartidor. | Automatizada host aprobada |
| SHARE-AC-02 | Seleccionar todos conserva modo personalizado; selección usa valores públicos vigentes y se conserva después de compartir. | Automatizada host y regresiones aprobadas |
| SHARE-AC-03 | Basename real y override exactos para ambos modos; exportaciones sucesivas aisladas sin sobrescritura. | Gateway host aprobado; nombre mostrado en selector físico confirmado |
| SHARE-AC-04 | Ambos modos comparten bloqueo busy, probado en ambas direcciones. Error del completo conserva selección/catálogo y permite reintento personalizado. Cancelación conserva selección. | Automatizada host y regresiones aprobadas |
| SHARE-AC-05 | PDF conserva marca/contenido, portada, paginación y fuentes; retención limpia únicamente archivos propios antiguos. | Regresiones de gateway aprobadas; PDF sintético verificado |
| SHARE-AC-06 | Formato, análisis, pruebas host y compilación. Compartidor físico Android con ambos nombres y cancelación. | Ejecutado en Android físico; iOS pendiente separado |

Archivo de regresiones de selección: `test/qa/pdf_selection_regression_test.dart`.

## Revisión independiente

La inspección del gateway muestra que el archivo se escribe con el basename de
`CatalogPdfScope.fileName`, dentro de un directorio privado único por exportación.
El compartidor usa el mismo nombre en `fileNameOverrides`. Esta revisión de código
no acredita ejecución nativa ni recepción por WhatsApp.

## Pendientes físicos

- Android conectado: compartir catálogo completo, comprobar nombre
  `LegumPro_Catalogo.pdf`, cancelar y verificar selección conservada.
- Android conectado: seleccionar algunos productos, comprobar nombre
  `LegumPro_Catalogo_Personalizado.pdf`; seleccionar todos desde el modo selección
  y comprobar que conserva ese nombre.
- Inspeccionar PDF con imagen, presentación, precio y disponibilidad de agotados.
- Recepción real por WhatsApp queda separada de la apertura del compartidor;
  no enviar a contactos sin instrucción explícita del usuario.
- iOS requiere Xcode y dispositivo compatible; sin verificación en esta estación.

## Resultados ejecutados

Pendientes de los comandos centralizados por el coordinador. No se atribuyen a
esta spec los resultados de specs anteriores.

## Ejecución coordinada — 2026-10-08

- Formato: 29 archivos, 0 cambios, EXIT0.
- `flutter analyze`: EXIT0, sin observaciones.
- `flutter test --reporter expanded`: EXIT0, 78 pruebas aprobadas.
  Incluye 11 servicio PDF, 21 QA (11 selección/modos y 10 regresiones previas),
  12 UI, 8 auth y 26 data/SQLite/medios/backups.
- `flutter test tool/pdf_smoke_test.dart --reporter expanded`: EXIT0, 1 escenario.
  Se generaron ambos PDF sintéticos con los nombres exactos bajo artifacts/qa-pdf/.
  PyMuPDF confirmó marca LegumPro, imágenes, precios y estados, sin SKU/descripción.
- `flutter test integration_test/native_pdf_test.dart -d <Android físico> --reporter expanded`:
  EXIT0, 1 escenario con ambos modos, 42s. Android15 modelo23049PCD8G por USB.
  Asertó basename real y override exactos de cada modo. El selector Android
  com.android.intentresolver/.ChooserActivity mostró ambos nombres completos;
  lectura puntual del árbol UI confirmó True para cada filename, sin conservar
  ni imprimir otros contenidos del selector. Se cancelaron con Back y el plugin
  devolvió dismissed en ambos. No destinatarios elegidos, no envío a contactos.
- Pruebas usan fixtures privados temporales, sin cargar ni modificar catálogo real.
- Selección, filtros, ocultos/agotados, nombres iguales al seleccionar todos,
  rutas únicas, cleanup legacy/nuevo/ajenos y bloqueo cruzado cubiertos en host.

No se infiere recepción WhatsApp de abrir el selector. Quedan pendientes envío y
recepción manual, lifecycle completo entre apps, lectores físicos e iOS/Xcode.
La compilación/instalación final del APK normal se registra a continuación.

## APK final: instalación bloqueada

Build debug v0.4.0+4: EXIT0 (44,4 s) con configuración privada local.
`adb install -r` en Android físico: EXIT1 INSTALL_FAILED_USER_RESTRICTED: Install canceled by user. No se abrió MainActivity; Android indicó que no existe la actividad del paquete. Pendiente resolver el bloqueo de instalación en el dispositivo.
Incluye marca LegumPro e imágenes ajustadas de SPEC-003 y ambos modos SPEC-004.
La implementación no cambia DB ni credenciales; los fixtures de prueba son aislados. La presencia de la app normal y sus datos no se acredita mediante este intento fallido.

APK: build/app/outputs/flutter-apk/app-debug.apk.
SHA-256: B7A8B23D8AFAE24CEF1165DF2D35989F8334BC9BCA1481AF9EEA553E787BA87D.

## Incidencia del flujo de pruebas e instalación

La instalación final fue rechazada por el dispositivo (INSTALL_FAILED_USER_RESTRICTED).
`pm path com.example.catalogo_legum_pro` no devuelve paquete instalado. Revisión del
SDK Flutter local: commands/test.dart flag uninstall defaultsTo:true y
integration_test_device.dart kill() llama uninstallApp. Las pruebas se habían
compilado con el identificador normal, por lo que su limpieza desinstaló ese paquete
 y puede haber borrado datos locales. La afirmación anterior de conservación de
los datos del usuario no queda acreditada y se corrige. Se comunicó al usuario.

Corrección: android/app/build.gradle.kts asigna applicationId separado
com.example.catalogo_legum_pro.integration cuando target está en integration_test/.
AGENTS.md exige comprobar el ID de la build nativa antes de instalar pruebas.
La aplicación normal conserva su ID original. Verificación de ambas builds
pendiente de ejecución a continuación; no repetir integración con paquete normal.

Verificación de aislamiento de pruebas: build debug
--target=integration_test/native_pdf_test.dart EXIT0 (34,9 s).
AAPT confirmó package=com.example.catalogo_legum_pro.integration y actividad
com.example.catalogo_legum_pro.MainActivity. No se instaló esta build durante el
bloqueo del teléfono. La separación de package queda acreditada por APK compilado.

Build normal posterior al aislamiento: EXIT0 (17,0 s), applicationId original
verificado por AAPT. El APK queda preparado; no se reintentó instalar tras la
cancelación del teléfono. Esperar que usuario resuelva el estado del instalador.
La restauración de contenido, si había productos cargados, requiere identificar
un respaldo disponible; no se afirma recuperación ni conservación después de
la desinstalación automática de la prueba anterior.


## Instalaci?n final confirmada ? 2026-10-08

El usuario solicit? instalar la app. Android f?sico conectado por USB.
`adb install -r build/app/outputs/flutter-apk/app-debug.apk`: EXIT0, Success.
`adb shell am start -n com.example.catalogo_legum_pro/.MainActivity`: EXIT0,
Starting Intent sin error. Se instal? y abri? el APK normal. Esto resuelve el
bloqueo de instalaci?n anterior; no acredita recuperaci?n de los datos que
pudieron perderse por la incidencia documentada ni recepci?n por WhatsApp.
