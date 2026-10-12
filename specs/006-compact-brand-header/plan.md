# Plan — Cabecera compacta

Se conserva Flutter/MVVM y se reutiliza el asset existente. No se necesitan dependencias ni cambios de persistencia.

1. Especificar y diseñar la decisión autorizada (CAB-AC-01 a 06). Salidas: `spec.md`, `design.md`.
2. Codificador: incorporar un leading opcional a `PageFrame` en `lib/ui/widgets.dart`; mantener otros consumidores y botón de volver. En `lib/features/public_views.dart`, aportar el símbolo circular y retirar bloque grande/espacio asociado. Cubre CAB-AC-01 a 05. Depende de 1.
3. QA: adaptar la prueba de marca existente y comprobar título, recorte circular, ausencia de bloque, texto ampliado y regresión de acciones. Archivos de pruebas pertinentes y `qa.md`. Cubre CAB-AC-01 a 05. Depende de 2.
4. Coordinador: formato, análisis, pruebas pertinentes y build; instalar APK de producción con `adb install -r` en Android físico disponible, sin desinstalar. Inspeccionar resultado antes de afirmar instalación. Cubre CAB-AC-06. Depende de 3.

Las pruebas nativas, si se requieren, usan exclusivamente applicationId `.integration`, verificado antes de instalar; no ejecutar Flutter integration test con la identidad de producción. iOS nativo permanece pendiente de Xcode.
