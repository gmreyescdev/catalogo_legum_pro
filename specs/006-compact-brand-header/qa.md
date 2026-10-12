# QA — Cabecera compacta LegumPro

## Resultados ejecutados en host — 2026-10-08

- `dart format test/ui/catalog_app_test.dart`: completado.
- `flutter test test/ui/catalog_app_test.dart --reporter expanded`: **14 pruebas aprobadas**, salida `All tests passed!`, código de salida 0.
- CAB-AC-01/02: en claro y oscuro, a 320 dp y escala de texto 2, se comprueba símbolo de 40 × 40 dp dentro de `ClipOval`, asset PNG con `BoxFit.contain`, separación de 12 dp y alineación vertical con el título. El JPG grande no está en el árbol y el título aparece una sola vez.
- CAB-AC-03: título dentro del ancho disponible, sin excepciones de layout en ambos temas con texto ampliado; la regresión de catálogo y detalle a 320 dp también pasa.
- CAB-AC-04: imagen accesible «Logo LegumPro»; los controles Administrar y búsqueda están operables y conservan altura mínima de 48 dp. El símbolo no introduce una acción. La prueba existente de contraste de tokens claro/oscuro pasa.
- CAB-AC-05: pasan regresiones de catálogo completo, selección PDF, progreso y error sin perder selección, búsqueda, visibilidad, precio vigente, autenticación y conservación de borradores. La búsqueda se escribe y actualiza el ViewModel en ambos escenarios de cabecera.

## Límites y verificaciones pendientes

Estas pruebas usan widgets y servicios en memoria; no acreditan instalación, persistencia nativa, selector de compartir ni apariencia real del dispositivo. La compilación y actualización del Android físico corresponden al coordinador y deben registrar su propia evidencia. No se ejecutaron integraciones ni se instalaron paquetes durante esta verificación QA; no se usaron emuladores.

La validación nativa iOS sigue pendiente de un entorno con Xcode. No se modifican los iconos de launcher en esta spec.

## Verificaci?n final del coordinador ? 2026-10-08

- Formato lib/test: 26 archivos, 0 cambios, EXIT0.
- flutter analyze: EXIT0, sin observaciones.
- Build debug con configuraci?n privada: EXIT0, 33,2 s.
- AAPT confirma applicationId normal com.example.catalogo_legum_pro, versi?n0.5.1+6.
- adb install -r en Android f?sico: EXIT0, Success; no se desinstal? ni se ejecut? integraci?n.
- MainActivity iniciada sin error y foco del paquete confirmado.
- Captura artifacts/qa-logo/android-compact-header.png inspeccionada: s?mbolo circular junto al t?tulo, sin bloque grande; administraci?n, compartir, b?squeda, filtro y producto existente visibles sin superposici?n.
- Esta evidencia f?sica es de tema oscuro; claro y texto ampliado verificados en pruebas widgets. iOS/Xcode contin?a pendiente.
