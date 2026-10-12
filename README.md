# LegumPro

Catálogo local Flutter para Android e iOS, con MVVM, sqflite y Material Design 3.
La implementación activa corresponde a [SPEC-001 v2](specs/001-product-catalog/spec.md).

Incluye catálogo vacío inicial, búsqueda y categorías, detalle con galería,
precios CLP/ofertas, disponibilidad y selección para compartir catálogo PDF
con clientes por WhatsApp (SPEC-002).
El panel local permite administrar categorías, productos y fotos, cambiar el PIN,
configurar el tema y exportar o reemplazar el catálogo mediante respaldos ZIP.
Los datos y fotos permanecen en el dispositivo; no hay sincronización ni backend.

## Equipo y SDD

El [coordinador](.agents/roles/coordinator.md) integra al
[diseñador](.agents/roles/designer.md), [planificador](.agents/roles/planner.md),
[QA](.agents/roles/qa.md) y [codificador](.agents/roles/coder.md).
El diseñador aplica la [skill M3 local](.agents/skills/flutter-product-design/SKILL.md).
Los roles son instrucciones para tareas delegadas, no procesos permanentes.

Requisitos, diseño, plan, tareas y resultados se encuentran en
[specs/001-product-catalog](specs/001-product-catalog/spec.md).
La evidencia de v1 se conserva en `history/v1/` y no acredita requisitos de v2.

El flujo actualizado se define en [SPEC-002](specs/002-share-selected-catalog/spec.md).
Selecciona productos y abre la selección para compartir un PDF con nombre,
precio, presentación, portada y disponibilidad. Elige WhatsApp y al cliente
en el selector del sistema; confirma allí el envío. No requiere destinatario fijo.

[SPEC-004](specs/004-full-and-personalized-pdf/spec.md) añade **Compartir catálogo
completo**, independiente de búsqueda/filtros, con archivo `LegumPro_Catalogo.pdf`.
**Compartir selección** usa `LegumPro_Catalogo_Personalizado.pdf`, incluso si
seleccionas todos los productos. Ambos excluyen ocultos e incluyen agotados.
La marca es LegumPro; las portadas llenan las tarjetas sin deformarse y el detalle
conserva la imagen completa (SPEC-003).

[SPEC-007](specs/007-catalog-performance/spec.md) incorpora decode de imágenes
según el tamaño visible y la densidad del dispositivo, conservando los originales.
La comparación profile en Android físico midió por separado 60 y 120 Hz;
las transiciones mantienen el comportamiento Material y movimiento reducido.
Consultar [QA de rendimiento](specs/007-catalog-performance/qa.md) para métricas,
condiciones y verificaciones pendientes; Hz observados no garantizan FPS sostenidos.

## Ejecución local

1. Ejecutar `flutter pub get`.
2. Crear el archivo privado `.local/build-config.json` con la clave
   `INITIAL_ADMIN_PIN` y un valor string de cuatro dígitos. Este archivo está ignorado.
3. Conectar un Android físico con depuración USB y ejecutar
   `flutter run -d <dispositivo> --dart-define-from-file=.local/build-config.json`.

El PIN inicial ya está configurado para esta entrega local. No incluirlo en código,
documentación ni comandos compartidos. Al entrar por primera vez, guardar y confirmar
el código de recuperación. Las credenciales se guardan como verificadores en
almacenamiento protegido y no se incluyen en respaldos. Una build sin PIN inicial
puede mostrar el catálogo público, pero no inicializar administración en una
instalación nueva.

Para generar APK: `flutter build apk --debug --dart-define-from-file=.local/build-config.json`.
La configuración local no sustituye un proceso de distribución firmado.

## Verificación

`dart format --output=none --set-exit-if-changed lib test integration_test`,
`flutter analyze` y `flutter test --reporter expanded` verifican formato, análisis,
lógica y widgets. La integración nativa se ejecuta exclusivamente en dispositivo físico:
`flutter test integration_test/native_catalog_test.dart -d <dispositivo> --reporter expanded`.

Las builds con target en `integration_test/` usan el applicationId Android
`com.example.catalogo_legum_pro.integration`, separado de la app normal.
Verificar este identificador en el APK antes de instalar pruebas: Flutter test
desinstala su paquete al terminar por defecto. No usar el paquete normal para
pruebas de integración sobre un catálogo con datos del usuario.

Consultar [QA](specs/001-product-catalog/qa.md) para resultados y pendientes concretos.
iOS requiere macOS/Xcode para compilar y probar; no se acredita mediante Android.
Los respaldos compartidos con éxito se conservan temporalmente para permitir su lectura
por el receptor y se limpian al siguiente arranque una vez superadas 24 horas.
