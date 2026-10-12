# QA — SPEC-013

Estado: siete pruebas QA y suite completa aprobadas; entrega y revisión Android
físico completadas, versión 0.7.1+13.

Verificar ACC-01–06: loading durante autenticación pendiente, ausencia de doble
entrada, errores y reintento, recuperación conservada; separación de 24 dp entre
botón añadir y primera tarjeta; 320 dp/texto 2×; nombres largos y estado vacío;
editar/reordenar/cancelar eliminación. Separar pruebas host de revisión física.
No modificar el catálogo real para sembrar escenarios. No usar emuladores.

## Casos host preparados

Archivo: `test/qa/admin_access_categories_test.dart`.

- QA-013-01 / ACC-02,03: autenticación diferida mediante Completer; indicador
  circular y botón deshabilitado durante trabajo real; segundo toque no duplica
  solicitudes; respuesta incorrecta muestra error y permite reintento correcto.
  Medir 24 dp entre el campo PIN y la acción; desmontar para cancelar el Timer.
- QA-013-02 / ACC-03,04,05: Categorías a 320 dp y texto 2×, nombre largo,
  conteos singular/plural, geometría de 24 dp entre creación y primera tarjeta
  y 16 dp entre tarjetas; acciones con tamaño mínimo y sin excepciones Flutter.
- QA-013-03 / ACC-04: editar nombre, reordenar por botón y cancelar eliminación
  conserva ambas categorías y su orden. Datos de pruebas en memoria.
- QA-013-04 / ACC-04: estado vacío mantiene creación accesible y abre editor.
- QA-013-05 / ACC-05: calcular luminancia y contrastes de roles de texto en temas
  claro/oscuro; exigir 4.5:1 y registrar valores numéricos en la salida host.
- QA-013-06 / ACC-02: desmontar AuthPanel mientras unlock espera, completar
  posteriormente y comprobar ausencia de excepción por controlador descartado.
- QA-013-07 / ACC-01,02,05: a 320 dp/texto 2×, recuperar acceso conserva código,
  nuevo PIN y confirmación; configuración mantiene código seleccionable y exige
  marcar reconocimiento antes de habilitar confirmación. Sin overflow Flutter.

El coordinador centraliza las ejecuciones Flutter para evitar carreras de build.
Los siete casos fueron ejecutados posteriormente: todos aprobados.

## Ejecución QA final

`flutter test test/qa/admin_access_categories_test.dart --reporter expanded`
finalizó con exit 0 y **7 pruebas aprobadas**, con evidencia en
`artifacts/013-admin-access-categories/qa-tests.log`. Incluye loading real,
reintento, ausencia de doble entrada, geometría de separaciones a 320 dp/2×,
edición/orden/cancelación, vacío, retorno tardío tras desmontaje y estados de
recuperación/configuración. No se ejecutó en emulador ni se usó catálogo real.

En los reintentos de harness se materializaron widgets lazy antes de accederlos,
se esperó a que el scroll terminara y se seleccionó el Scrollable vertical de
ListView, evitando confundirlo con el Scrollable interno del código seleccionable.
Se conservaron todas las comprobaciones; no se detectó un defecto de la app.

## Ejecución inicial host

El coordinador ejecutó una primera selección junto con la suite UI anterior:
21 pruebas pasaron y dos fallaron por expectativas de montaje de listas lazy
(el segundo Card aún no estaba montado y el conteo singular quedaba fuera del
viewport tras crecer la cabecera). No hubo excepción funcional de la app en
esa ejecución. Se ajustó el harness para desplazar explícitamente el contenido,
manteniendo las verificaciones de separación y conteo. Reejecución pendiente.

La medición de contraste sí se ejecutó en esa selección:

| Par de roles | Claro | Oscuro |
| --- | ---: | ---: |
| primary / onPrimary | 6.48:1 | 7.72:1 |
| primaryContainer / onPrimaryContainer | 7.22:1 | 7.22:1 |
| surface / onSurface | 16.29:1 | 14.33:1 |
| surfaceContainerLow / onSurface | 15.56:1 | 13.25:1 |
| surfaceContainerLow / onSurfaceVariant | 8.50:1 | 10.04:1 |
| secondaryContainer / onSecondaryContainer | 7.22:1 | 7.22:1 |
| surface / error | 6.14:1 | 10.93:1 |

Todos superan 4.5:1. No se extiende esta conclusión al texto deshabilitado,
al indicador circular ni a un lector de pantalla nativo. Valores registrados en
`artifacts/013-admin-access-categories/targeted-tests.log`.

## Revisión y límites pendientes

Revisar conservación de recuperación/configuración, lockout y seguridad; salida
de AuthPanel mientras una operación espera y limpieza de controladores; contraste
de los roles concretos finalmente usados; tamaños medidos y contenido sin overflow.
La suite anterior también debe verificar el conteo singular `1 producto`.

Revisión independiente del código completada: el retorno asíncrono de unlock y
recuperación comprueba mounted antes de limpiar controladores; dispose cancela el
Timer y libera los tres controladores. Categorías conserva edición, confirmación
de borrado y orden; gaps explícitos y controles de 48 dp. Los pares de texto
utilizados coinciden con el test de contraste preparado. Sin defecto funcional
identificado por inspección; esta revisión no sustituye ejecución.

Las pruebas host no acreditan lector de pantalla
nativo, benchmark de 120 Hz ni iOS; iOS requiere entorno Xcode.

## Verificación coordinada host final — 2026-10-08

- `flutter test --reporter expanded`: 122 pruebas aprobadas, exit 0.
  Evidencia: `artifacts/013-admin-access-categories/host-tests.log`.
- Las siete pruebas independientes del rediseño también pasan aisladamente.
  Evidencia: `artifacts/013-admin-access-categories/qa-tests.log`.
- `dart format --output=none --set-exit-if-changed` sobre los tres archivos Dart
  modificados: cero cambios. `flutter analyze`: sin incidencias, exit 0.
- Los fallos iniciales fueron del harness: controles fuera de viewport o todavía
  no montados en ListView. Se materializan mediante desplazamiento, se centran y
  se espera a terminar el scroll. En setup se delimita el Scrollable de ListView,
  evitando el Scrollable interno de SelectableText. Se conservaron las verificaciones.
- Regla de separación persistida en AGENTS.md; no se realizó una auditoría ni
  rediseño general de pantallas fuera de alcance.

## Entrega Android físico — 2026-10-08

- Build release arm64 final completada, exit 0 (113.6 s). AAPT verificó paquete
  `com.example.catalogo_legum_pro`, versión 0.7.1, código 13 antes de instalar.
- `adb install -r`: Success; PackageManager confirma 0.7.1+13. Se preservaron
  catálogo, imágenes, categorías y PIN. APK: `artifacts/013-admin-access-categories/legumpro-0.7.1-release.apk`.
- Android físico 23049PCD8G: acceso rediseñado visible; PIN existente autentica;
  administración muestra los productos existentes y sus imágenes/SKU. Categorías
  muestra 3 categorías y 11 productos, conteos 9/1/1 y acciones separadas.
- Se abrió Nueva categoría y se volvió sin introducir ni guardar registros.
  Campo y acción Guardar muestran separación visible. No se modificaron datos reales.
- Capturas: `android-access.png`, `android-after-entry.png`,
  `android-categories.png` y `android-new-category.png` en el directorio de evidencia.
- Indicador durante operación pendiente, errores, reintento, recuperación/setup,
  cancelación y reordenamiento se acreditan con pruebas host. La validación nativa
  breve no reproduce esas operaciones sobre los datos reales ni sustituye un benchmark.

Pendientes: iOS con Xcode y lector de pantalla físico. Sin nuevos benchmarks
nativos de 120 Hz en esta entrega. No se usaron emuladores.