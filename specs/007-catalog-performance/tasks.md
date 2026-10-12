# Tareas — SPEC-007

## Definición completada

- [x] T01: Definir alcance, escenarios y PERF-AC-01 a 09 en `spec.md`.
- [x] T02: Diseñar continuidad M3, imágenes y accesibilidad en `design.md`.
- [x] T03: Definir secuencia de medición, diagnóstico, ajustes y entrega en `plan.md`.
- [x] T03b: Definir protocolo y casos QA en `qa.md` y revisión de viabilidad en
  `technical-review.md`; sin ejecutar pruebas ni benchmarks.
- [x] T03c: Incorporar requisito de 120 Hz: presupuestos, series separadas de
  60/120 Hz, respeto a ajustes del sistema y límites de evidencia.

## Ejecución y pendientes

- [x] T04: Preparar fixture e instrumentación profile aislada; verificar applicationId
  antes de instalar. Depende T01–T03. PERF-AC-01/08.
- [x] T05: Ejecutar baseline físico reproducible: frames, apertura, detalle, búsqueda,
  selección, decode/cache, memoria y diez ciclos por ruta de transición.
  Series de 60/120 Hz separadas; 120 Hz permanece pendiente si no está habilitado
  efectivamente en el dispositivo, sin modificar ajustes globales.
  Depende T04. PERF-AC-01 a 06/09.
  Ejecutados baseline/comparación 60/120 Hz, bootstrap SQLite (5 aperturas por
  variante), detalle F20 (dos parejas conservadas), F100 completo y panel sintético.
  Límites de instrumentación y alerta de primera pareja F20 en `qa.md`.
- [x] T06: Registrar diagnóstico y decidir ajustes respaldados por baseline.
  Depende T05. PERF-AC-02/04/05/06.
  Diagnóstico del incremento: decode de imágenes; entradas medidas ya <100 ms.
- [x] T07: Implementar decode acotado preservando fit, calidad, originales y fallback;
  demostrar reducción de bytes de tarjetas. Depende T06. PERF-AC-05/07.
  Foto medida: 48.000.000 → 2.952.192 bytes decodificados, 93,85% menos.
- [x] T08: Ajustar trabajo repetido y reconstrucciones solo donde diagnóstico lo
  justifique; invalidación completa de derivados y listeners. Depende T06.
  PERF-AC-04/06/07. Si no aporta, registrar omisión fundamentada.
  Omitida refactorización VM/cachés/listeners: entradas medidas <100 ms y sin
  beneficio adicional demostrado; se conserva el comportamiento vigente.
- [x] T08b: Optimizar transiciones según evidencia, respetando patrón Material,
  movimiento reducido, estado y seguridad. Depende T06. PERF-AC-09.
  Decode acotado mejora frames de detalle/selección sin cambiar `MaterialPageRoute`
  ni sus duraciones. Panel protegido, navegación rápida, BACK y gesto Android
  verificados; movimiento reducido real del sistema permanece pendiente.
- [ ] T09: Ejecutar comparación, 100 productos, memoria por ciclos y regresiones;
  formato, análisis y pruebas; registrar fallos. Depende T07/T08/T08b.
  Comparar antes/después dentro de la misma frecuencia efectiva y documentar
  60/120 Hz por separado; no inferir FPS sostenidos desde una lectura de Hz.
  PERF-AC-01 a 09.
  Ejecutados: 88 pruebas host aprobadas, análisis sin incidencias, formato de 37
  archivos y comparación a 60/120 Hz. Baseline/candidato cumplen tres recorridos
  calentados; frames fuera de presupuesto detalle push 5,660% → 2,439% y selección
  push 15,547% → 2,597%. Bootstrap SQLite +2,45%; detalle F20 ampliado +6,89%,
  con alerta original +11,17% conservada. F100 completo sin errores; panel
  sintético y gesto/BACK físico comprobados. Falta movimiento reducido real SO;
  iOS requiere Xcode. No se declara aceptación global.
- [x] T10: Integrar resultados QA y actualizar la app normal en Android físico
  sin desinstalar ni alterar datos; confirmar instalación real. Depende T09.
  PERF-AC-07/08.
  Release 0.6.0+7 instalada con `adb install -r`: Success, versión confirmada,
  catálogo existente/fotos y acceso protegido comprobados. Entrega Android del
  incremento con límites explícitos de T09, sin declarar validación iOS.

Documentar resultados ejecutados y limitaciones en `qa.md`. Hay implementación y
mediciones físicas y actualización Android; T09 conserva las verificaciones
pendientes. iOS requiere validación propia
en un entorno Xcode y permanece pendiente.
