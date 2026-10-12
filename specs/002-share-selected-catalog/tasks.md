# Tareas — SPEC-002

Los checks distinguen implementación e inspección de ejecución.
La evidencia ejecutada corresponde a qa.md; no heredar aprobación de SPEC-001.

- [x] T01 Alcance autorizado y PDF-AC-01..07 registrados en spec.md.
- [x] T02 Diseño M3 y código VM/pantallas presentes: revisión de seleccionados,
  progreso/error, acceso desde detalle, selección conservada y número fijo
  retirado de ajustes. PDF-AC-01/04/05/06; depende de T01 y contrato T03.
- [x] T03 Contrato, bootstrap, servicio PDF, fuentes locales y compartidor
  presentes. Portada/fallback, precios/disponibilidad, MIME/ancla y limpieza de
  temporales implementados. PDF-AC-02/03/04/05/07; depende de T01.
- [x] T04a Matriz QA y pruebas servicio/VM/UI/regresión preparadas.
  PDF-AC-01..07; depende de T02/T03 integradas.
- [x] T04b Ejecutar formato/análisis/suite y regresiones SQLite/backups; corregir
  fallos y registrar comando, resultado y alcance real en qa.md.
- [x] T04c Extraer e inspeccionar PDF sintético renderizado: campos permitidos,
  acentos, portada/fallback, oferta y texto largo completo. PDF-AC-02/03.
- [ ] T05a Generar APK e instalar sin borrar datos en Android físico; verificar
  selector PDF, cancelación, lifecycle y selección conservada. Selector/cancelación
  nativos aprobados; recorrido lifecycle completo pendiente. Sin emulador ni
  envío a contactos. PDF-AC-04/05/06/07; depende de T04b/c.
- [x] T05b Integrar evidencia y límites en QA/README; informar pruebas nativas
  manuales pendientes. iOS permanece pendiente de Xcode/dispositivo.
