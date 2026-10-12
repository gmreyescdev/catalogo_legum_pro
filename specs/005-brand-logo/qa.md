# QA — SPEC-005

## Resultados ejecutados por QA

2026-10-08, host Windows; no emulador, integración ni instalación ejecutados por este rol.

- `flutter test test/ui/catalog_app_test.dart --reporter expanded`: EXIT 0, **14 pruebas aprobadas**. Incluye las 12 regresiones previas y dos casos de cabecera, claro/oscuro, ventana de 320 × 900 dp y escala de texto 2.
- LOGO-AC-01: en ambos temas la imagen tiene etiqueta semántica única «Logo LegumPro», altura 160 dp, ancho dentro de los 288 dp disponibles; permanecen título y administración. El desplazamiento permite acceder a SearchBar sin excepciones de layout. Inspección de implementación confirma `BoxFit.contain`, separación de 24 dp y conservación del original sin tintado.
- El SHA-256 del JPG incluido coincide con el archivo aportado por el usuario: `316336FE3985590F66BEA7F57F098C2F361B0523D3287FE3023843C23208BC98`.
- LOGO-AC-03: regresiones UI mantienen filtros, exclusión de ocultos, estado vacío, selección, ambos alcances PDF, progreso, error y ancla; también bloqueo y conservación de borradores. La expectativa del estado vacío con filtro se conserva, desplazando explícitamente el ListView para materializar su contenido lazy y volviendo al botón antes de compartir.
- LOGO-AC-02: los PNG Android legacy tienen 48, 72, 96, 144 y 192 px; foreground adaptativo 108, 162, 216, 324 y 432 px. XML API 26 referencia fondo de marca y foreground; `brand_colors.xml` define `#0E1E1E`.
- Los 19 recursos declarados por Contents.json de iOS existen y sus dimensiones coinciden con tamaño × escala. El marketing de 1024 × 1024 usa `Format24bppRgb`, sin canal alpha. Inspección visual del símbolo fuente: conserva identidad vegetal y omite wordmark pequeño.

## Hallazgos y resolución

- El agregado de la cabecera desplazó el estado vacío fuera de la construcción inicial del ListView. Se ajustó la prueba para desplazarse al estado real, sin relajar sus expectativas.
- Inspección independiente detectó posible recorte circular del extremo superior derecho en foreground adaptativo, ya que inicialmente se escalaba el símbolo igual que el icono legacy. El coordinador corrigió el generador reduciendo solo foreground al 80 % y centrándolo. QA verificó el recurso final de 432 px: píxeles luminosos del símbolo (máximo RGB > 80, excluyendo fondo oscuro) alcanzan radio 130,16 px, dentro del radio seguro de 132 px correspondiente a 66/108. La comprobación geométrica reduce el riesgo de recorte circular; el launcher físico sigue requiriendo revisión visual.

## Verificaciones pendientes del coordinador

- Suite completa, análisis y build normal finales; registrar resultados ejecutados por separado.
- LOGO-AC-04: actualización mediante `adb install -r`, sin desinstalar, en Android físico y comprobación visual de cabecera e icono. Estas pruebas host no acreditan instalación ni conservación de datos en el teléfono.
- Legibilidad visual real de la marca y máscaras launcher en Android físico. La prueba semántica/layout no equivale a una revisión visual ni a medición de contraste del logo raster.
- Compilación y ejecución iOS con Xcode pendientes; recursos inspeccionados no acreditan plataforma verificada.


## Resultados finales del coordinador ? 2026-10-08

- Formato lib/test: 26 archivos, 0 cambios; EXIT0.
- flutter analyze: EXIT0, sin observaciones.
- flutter test --reporter expanded: EXIT0, 80 pruebas aprobadas.
- Build final debug con configuraci?n privada: EXIT0, 13,4 s. Versi?n 0.5.0+5.
- AAPT: com.example.catalogo_legum_pro, icono res/mipmap-anydpi-v26/ic_launcher.xml.
- SHA256 APK: E4B0AEC87C9631D1B1582C635A41DFD601128286FE95B5CB8AF9B86DF5C0B8B0.
- adb install -r en Android f?sico: EXIT0, Success. No se desinstal? ni se ejecutaron pruebas de integraci?n.
- MainActivity abierta sin error; dumpsys window confirm? foco del paquete normal.
- Captura artifacts/qa-logo/android-catalog.png inspeccionada: tema oscuro, logo completo legible y sin deformaci?n, administraci?n, compartir, b?squeda y categor?a visibles; producto existente visible. No se modific? contenido del cat?logo.
- Recursos iOS preparados, sin compilaci?n ni ejecuci?n Xcode.
- La revisi?n visual del icono en el launcher personalizado del tel?fono queda pendiente; se acreditan instalaci?n, referencia nativa del icono, dimensiones y zona segura geom?trica, sin afirmar una captura del launcher.
