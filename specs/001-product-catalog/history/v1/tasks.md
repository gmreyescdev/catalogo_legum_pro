# Tareas — SPEC-001

Estado: implementación y verificaciones automatizadas completadas.
La validación manual en Android e iOS permanece pendiente.
Los checks solo se completan con evidencia registrada.

- [x] **T01 — Integrar diseño y verificación.** Coordinador, diseñador y QA.
  Leer `design.md` y casos de `qa.md`; reconciliar decisiones con `spec.md` y
  actualizar este plan cuando corresponda. Dependencia: entrega del diseñador y
  QA. Cubre AC-01–08. Salida: documentos consistentes para el codificador.
  Evidencia: revisión cruzada por el coordinador de spec, diseño y matriz QA;
  decisiones de interfaz incorporadas en `plan.md`. No implica pruebas de app.
- [x] **T02 — Preparar datos y recursos locales.** Codificador.
  Crear `lib/product.dart`, `lib/catalog_data.dart`, `assets/products/` y declarar
  assets en `pubspec.yaml`. Incluir suficientes productos de demostración para
  verificar desplazamiento; permitir ausencia de imagen. Dependencia: T01.
  Cubre AC-01, AC-04, AC-06.
- [x] **T03 — Implementar el catálogo.** Codificador.
  Actualizar `lib/main.dart` y crear `lib/catalog_page.dart` con colección
  inyectable, tarjetas de nombre, imagen y descripción completa, lista desplazable,
  placeholder ante imagen ausente o inválida y mensaje exacto de vacío.
  Dependencia: T02. Cubre AC-01–05.
- [x] **T04 — Aplicar diseño y accesibilidad.** Codificador.
  Usar decisiones de `design.md`, áreas seguras, contenido de altura flexible y
  semántica para nombre y descripción en orden lógico. Evitar truncamiento y
  medidas que impidan texto ampliado. Archivos: `lib/main.dart`,
  `lib/catalog_page.dart`. Dependencia: T03. Cubre AC-03, AC-07.
- [x] **T05 — Añadir pruebas de comportamiento.** Codificador con casos QA.
  Crear `test/catalog_page_test.dart` para contenido, desplazamiento hasta el final,
  descripción larga completa, imagen ausente e inválida, colección vacía y matriz
  de anchos 320/390 con escalas 1.0/2.0; revisar semántica accesible y recursos
  locales. Dependencia: T04. Cubre AC-01–07.
- [x] **T06 — Ejecutar verificaciones Flutter.** Codificador y QA.
  Ejecutar formato, análisis y pruebas; corregir fallos y registrar comandos y
  resultados reales en `qa.md`. Dependencia: T05. Cubre AC-01–07.
  Evidencia: formato aplicado a 5 archivos; `flutter analyze` sin incidencias;
  QA independiente ejecutó `flutter test --reporter expanded`: 15/15 correctas.
- [ ] **T07 — Verificar plataformas y uso sin conexión.** QA.
  Registrar compilación, ejecución y exploración del catálogo por cada plataforma
  disponible. Probar sin conexión en dispositivo o emulador; comprobar texto
  ampliado y lector de pantalla cuando estén disponibles. Anotar Android o iOS
  pendientes y causas concretas; iOS necesita macOS/Xcode. Dependencia: T06.
  Cubre AC-06–08.
  Evidencia parcial: `flutter build apk --debug` correcto; APK generado en
  `build/app/outputs/flutter-apk/app-debug.apk`. `adb devices` sin dispositivos.
  El recorrido Android, prueba sin conexión y TalkBack/VoiceOver siguen pendientes.
  iOS requiere macOS/Xcode y no se ejecutó desde Windows.
- [x] **T08 — Integrar entrega y registrar pendientes.** Coordinador.
  Revisar `spec.md`, `design.md`, `plan.md`, `qa.md` y `tasks.md`; reflejar resultados,
  pendientes y cambios de alcance de forma consistente. No declarar validación
  de plataforma sin evidencia. Se integró la evidencia parcial de T07 sin cerrar
  esa tarea ni declarar terminado el recorrido de ambas plataformas. Cubre AC-01–08.

## Trazabilidad

| Criterio | Implementación | Verificación |
| --- | --- | --- |
| AC-01 | T02, T03 | T05, T06 |
| AC-02 | T03 | T05, T06 |
| AC-03 | T03, T04 | T05, T06 |
| AC-04 | T02, T03 | T05, T06 |
| AC-05 | T03 | T05, T06 |
| AC-06 | T02 | T05, T06, T07 |
| AC-07 | T04 | T05, T06, T07 |
| AC-08 | T03, T04 | T07, T08 |
