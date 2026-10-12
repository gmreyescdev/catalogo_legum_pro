# Plan — SPEC-004

## Incrementos y dependencias

1. T01 fija alcance y nombres (SHARE-AC-01..06). No añadir nombres editables en
   Ajustes, cambios SQLite, credenciales ni cambios del respaldo.
2. T02 depende de T01: `lib/contracts.dart` declara
   `CatalogPdfScope.complete/personalized` con `fileName` fijo;
   `shareCatalog` conserva personalized por defecto para compatibilidad.
   `lib/data/whatsapp/native_whatsapp_gateway.dart` crea un directorio privado
   único por exportación y usa el mismo basename real y override (SHARE-AC-03).
   Mantiene contenido, fuentes, paginación y limpieza compatible (SHARE-AC-05).
3. T03 depende de T02: `lib/features/view_models.dart` usa `publicProducts` en
   `shareAll` y `selected` en `shareSelected`, en orden del catálogo y con scope
   explícito. No inferir modo por cantidad de productos. El estado command busy
   compartido impide concurrencia y conserva selección (SHARE-AC-01/02/04).
   `lib/features/public_views.dart` presenta acciones independientes, ancla del
   botón para el compartidor, progreso/error visibles y estados vacíos. Seguir
   `design.md` para M3, adaptación y separación de controles.
4. T04 depende de T02/T03: QA revisa y mantiene pruebas VM/UI y gateway para
   filtros sin coincidencias, ocultos/agotados, catálogo vacío, selección total
   personalizada, error/cancel/reintento y bloqueo en ambas direcciones.
   Verificar nombres reales, exports aislados, retención y PDF conservado.
   La inspección del código y las pruebas escritas no equivalen a ejecución.
5. T05 depende de T04: coordinador ejecuta formato, análisis y pruebas Flutter;
   compila APK e instala sin borrar datos en Android físico. El escenario
   `integration_test/native_pdf_test.dart` abre y cancela ambos modos, verifica
   basename/override antes del handoff y registra resultados separados de host.
   iOS permanece pendiente hasta disponer de Xcode y dispositivo compatible.

## Comportamiento y riesgos a verificar

- El completo ignora filtros, búsqueda y selección, pero excluye ocultos; incluye
  agotados. Seleccionar todos manualmente sigue generando personalizado.
- Cada archivo se conserva en ruta única para que una nueva exportación no
  sobrescriba un adjunto anterior. Éxito/unavailable se retiene hasta 24 h;
  dismissed/error elimina el archivo propio. Limpieza sólo reconoce archivos y
  directorios propios, incluidos nombres anteriores de SPEC-002.
- El compartidor nativo puede informar unavailable al cerrarse. Eso no demuestra
  entrega ni recepción por WhatsApp. Probar el nombre dentro del selector físico
  y distinguirlo de la inspección del basename por Dart. No enviar a contactos.
- El PDF usa una instantánea de productos al pulsar compartir. Cambios posteriores
  durante generación no deben convertir el modo ni alterar la selección.
- El ancla iPad está implementada pero no acredita verificación iOS.

## Estado observado por inspección

Contrato, servicio y VM/UI contienen los dos modos. Existen pruebas host y
escenario nativo para los nombres. Falta incorporar los resultados de comandos
centralizados del coordinador; no se certifica compilación ni ejecución aquí.

Propiedad: raíz contratos/spec/bootstrap/tool/native/README;
codificador lib/data/whatsapp+test/whatsapp; diseñador public_views/view_models+
test/ui+design; planificador plan/tasks; QA test/qa+qa. Sin ediciones concurrentes.
