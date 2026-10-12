# Plan — SPEC-002

Estado: implementación presente; verificaciones centralizadas pendientes de
registrar por el coordinador. Código y tests existentes no acreditan ejecución.
Alcance: solo selección vigente, sin destinatario fijo ni envío automático.

## Incrementos y trazabilidad

| Tarea | Dependencias | Archivos y cambio | Criterios | Verificación |
| --- | --- | --- | --- | --- |
| T01 | Ninguna | spec.md: alcance autorizado | PDF-AC-01..07 | Revisión contra decisiones del usuario |
| T02 | T01 y contrato T03 | design.md, lib/features/public_views.dart, view_models.dart, admin_views.dart: revisión, progreso/error, detalle hacia selección y retirar número fijo | PDF-AC-01/04/05/06 | Tests VM/UI, 320 dp y escala 2, contraste y spacing |
| T03 | T01 | lib/contracts.dart, lib/data/whatsapp/native_whatsapp_gateway.dart, lib/app/bootstrap.dart, pubspec.yaml, assets/fonts/: PDF y compartidor | PDF-AC-02/03/04/05/07 | Tests servicio, extracción y renderizado visual sintético |
| T04 | T02/T03 integradas | test/whatsapp/, test/ui/, test/qa/pdf_selection_regression_test.dart, qa.md | PDF-AC-01..07 | Ejecutar pruebas nuevas y regresiones SQLite/backups |
| T05 | T04 y correcciones | Build, instalación Android físico y documentación | PDF-AC-04/05/06/07 | Formato/análisis/suite/APK; selector/lifecycle físico, sin envío a contactos |

## Contrato y flujo implementado

Se conserva el nombre WhatsAppGateway para evitar una refactorización ajena al
alcance. Su método es shareCatalog(List<Product>, {Rect? sharePositionOrigin}).
CatalogViewModel.shareSelected obtiene los productos públicos seleccionados del
snapshot vigente en orden de catálogo antes de generar. Bloquea vacío y comandos
simultáneos. El detalle abre la revisión; no exporta productos fuera de selección.
Cambios del repositorio excluyen ocultos/eliminados; filtros conservan selección.

NativeWhatsAppGateway recibe MediaManager, directorio privado y compartidor
inyectable. Genera A4 con Noto Sans local licenciada, portada por sortOrder,
límite 20 MiB/40 MP y reducción a 800 px; ausencia/corrupción tiene alternativa.
Exporta explícitamente nombre, presentación, precio normal/oferta y disponibilidad,
sin serializar descripción, SKU o credenciales. Paginación y acentos requieren
comprobar contenido y páginas renderizadas.

share_plus recibe archivo application/pdf, nombre legible y origen del botón
para iPad. El usuario elige aplicación y cliente en el selector nativo. Cancelar
o fallar mantiene selección; el retorno del selector no demuestra entrega.
PDF eliminado ante cancelación confirmada/error; resultado satisfactorio o no
determinado conserva archivo para lectura externa. cleanupExpired() limpia
archivos propios de más de 24 h al arranque y al generar: es la edad mínima de
elegibilidad, no una alarma de borrado cuando la app está cerrada.

## Compatibilidad y límites

No cambiar esquema SQLite ni formato de backup por este flujo. Número legado
conservado en modelo/almacenamiento/respaldos, sin mostrarse ni exigirse para
compartir. Mantener regresiones de restauración y catálogo; instalar sin borrar
datos del usuario. Sin generación remota ni descarga de fuentes.

Host permite lógica/widgets pero no valida plugins nativos. La prueba existente
integration_test/native_catalog_test.dart cubre SQLite/auth/backup; por sí sola
no acredita selector PDF ni lifecycle. Verificación nativa exclusivamente Android
físico. iOS pendiente de macOS/Xcode/dispositivo; ancla comprobable mediante fakes.

## Propiedad de archivos

Coordinador: contratos/bootstrap/pubspec/README/spec e integración. Planificador:
plan.md/tasks.md. Codificador: servicio PDF y sus tests. Diseñador:
features/UI/design/tests UI. QA: fixtures/tests QA y qa.md. Sin ediciones
concurrentes del mismo archivo; herramientas/resultados a cargo del coordinador.
