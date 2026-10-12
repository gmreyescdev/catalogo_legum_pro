# Tareas — SPEC-001 v2

Estado: T01–T11 implementadas; T12/T13 conservan pendientes de verificación nativa,
recorridos manuales y plataforma iOS. Las casillas de implementación siguientes
no acreditan todos los criterios: consultar evidencia y límites en `qa.md`.

| ID | Responsable y salida con verificación | Depende | V2-AC |
| --- | --- | --- | --- |
| T01 | Coordinador/equipo: reconciliar spec/design/plan/qa/tasks; adoptar políticas de intentos, límites, backups, medios y permisos. | Entregas documentales | 01–24 |
| T02 | Codificador: composición lib/app, modelos, contratos servicios/repositorios y ViewModels; paquetes compatibles verificados, quitar demo de arranque. Tests separación MVVM. | T01 | 01,22 |
| T03 | Codificador: lib/data/local, esquema/FK/índices, migraciones, normalización/validador común y orden. Tests constraints, vacío, upgrades, CLP/duplicados y persistencia sqflite nativa. | T02 | 01,05,06,10,11,13,22 |
| T04 | Codificador: servicio seguro/AuthRepository, PIN configurable, KDF/verificadores, setup/recovery/rotación/throttling, guardias/lifecycle. Tests fallo secure storage, reloj/reinicio, cancelación, revocación y ceros iniciales. | T02 | 02,03,04,22 |
| T05 | Codificador: categorías CRUD/orden con RESTRICT y feedback M3. Tests duplicados normalizados, eliminación referenciada y orden persistente. | T03,T04 | 05,13 |
| T06 | Codificador: formularios/productos/precios/estados, medios privados, selector/cámara, normalización JPEG/PNG, borradores, portada/orden y GC. Tests rollback DB/FS, permisos/cancelación, relock/reautenticación, imágenes inválidas y medios vigentes intactos. | T03,T04,T05 | 06,07,08,09,10,13,16 |
| T07 | Codificador: catálogo público/búsqueda/filtros/detalle/galería/selección temporal y refresh reactivo. Tests ocultos/agotados, normalización, AND, vacío/sinresultados, detalle completo y dataset5/20. | T03,T06 | 01,09,11,12,13,16,23 |
| T08 | Codificador: ajuste de número y ExternalLinkService, mensajes vigentes individual/conjunto y URI encoding. Tests número inválido, fallo externo, selección conservada y no autoenvío. | T04,T07 | 14,15 |
| T09 | Codificador: temas persistidos y UI M3 v2 en todas vistas. Tests claro/oscuro/sistema, contraste, targets48dp, 320/390 escala1/2 y 600/840. | T04–T08 | 20,21 |
| T10 | Codificador: exportación autenticada portable manifest+medios, snapshot consistente, límites/streaming y compartir copia. Tests secretos excluidos, ajustes/orden, límites/cancelación/error y offline. | T03,T04,T06,T09 | 16,17 |
| T11 | Codificador: importación validada/resumen/confirmación, generación de medios precommit, reemplazo SQL transaccional preservando auth, recuperación/GC. Tests fallos en cada frontera, espacio, cancelación, reimportación, crossplatform y crash pre/postcommit. | T03,T04,T06,T10 | 18,19 |
| T12 | QA: revisión arquitectura y suite integrada v2; SQL/plugins reales, PIN/recovery, migraciones, permisos, lifecycle, modoavión, muerte de proceso, rollback/recuperación. Corregir defectos con codificador. | T05–T11 | 01–23 |
| T13 | QA/coordinador: formato/análisis/tests/builds, recorridos Android/iOS y lectores, evidencia por criterio/plataforma, integrar pendientes reales. | T12 | 16,21,22,23,24 |

- [x] T01 Documentación v2 integrada: revisión coordinada de requisitos, diseño,
  plan, QA y tareas; revisión técnica independiente en `technical-review.md`.
  Políticas propuestas adoptadas como valores de planificación en `spec.md`;
  la evidencia posterior de contrastes, autenticación y plugins está en `qa.md`;
  durabilidad ante muerte real de proceso y validación iOS siguen pendientes.
- [x] T02 Composición MVVM implementada y pruebas host.
- [x] T03 SQLite/modelos/versionado implementados; apertura/reapertura nativa Android.
- [x] T04 PIN/recuperación/sesión implementados; autenticación y carreras en host.
- [x] T05 Categorías implementadas; constraints/orden en host y FK nativa Android.
- [x] T06 Productos/medios implementados; cámara/permisos físicos pendientes en T12.
- [x] T07 Catálogo/detalle/selección implementados; búsqueda y widgets en host.
- [x] T08 WhatsApp/configuración implementados; gateway probado con launcher inyectado.
- [x] T09 Temas/accesibilidad implementados; contrastes/widgets host; lectores pendientes.
- [x] T10 Exportación implementada y roundtrip host/nativo Android.
- [x] T11 Importación/recuperación implementada; rollback inyectado host/nativo Android.
- [ ] T12 QA integrado: automatización ejecutada; hardware/permisos/crash real pendientes.
- [ ] T13 Plataformas/integración final: iOS y recorridos completos pendientes.

T04 protege también mutaciones/configuración/backups; T09 aplica a público y panel.
Cada incremento implementado aporta pruebas pertinentes, sin esperar T12. T12
comprueba todos los criterios y políticas técnicas, incluidos fallos; fakes host no
validan sqflite nativo/cámara/secure storage. T13 no se cierra con solo build Android
si iOS sigue pendiente. La autorización de implementación ya fue recibida y ejecutada.

Propiedad al cierre de integración: coordinador integra documentación y evidencia;
diseñador entregó features/ui, codificador data, planificador auth/whatsapp y QA test/qa.
Evitar edición concurrente. Tras autorización de implementación, asignar archivos de
app/tests por incremento y transferir a QA al estabilizar. Cambios de alcance primero
en spec y tareas. Nunca insertar PIN/número reales en docs o fixtures.
