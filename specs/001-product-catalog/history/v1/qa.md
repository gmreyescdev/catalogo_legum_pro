# QA — SPEC-001 Catálogo simple de productos

Estado: verificación automatizada aprobada; recorridos manuales y validación iOS
pendientes. No hay defectos funcionales confirmados abiertos en lo ejecutado.

## Preparación

El spec autorizado adopta datos locales de demostración y pantalla única.
La suite usa fixtures con varios productos, una
descripción larga, colección vacía, imagen ausente, recurso inexistente y recurso
no decodificable. Los datos de demostración deben identificarse como tales.
Los estados alternativos se inyectan mediante fixtures de prueba; no requieren
añadir controles de depuración al producto.

## Matriz de pruebas

| Caso | Criterios | Procedimiento y resultado esperado | Nivel | Estado |
| --- | --- | --- | --- | --- |
| QA-01 | AC-01 | Abrir con datos locales: aparece el catálogo directamente y cada tarjeta muestra nombre, imagen y descripción del producto correcto. | Widget y manual | Widget aprobado; manual pendiente |
| QA-02 | AC-02 | Usar suficientes productos para exceder la pantalla; desplazar hasta localizar y leer el último, sin perder contenido. | Widget y manual | Widget aprobado; manual pendiente |
| QA-03 | AC-03 | Inyectar descripción extensa; comprobar texto completo y ausencia de elipsis; desplazar para leer su final. | Widget y manual | Widget aprobado; manual pendiente |
| QA-04 | AC-04 | Probar por separado imagen ausente, ruta inexistente y bytes no decodificables: aparece placeholder, permanecen nombre y descripción y no ocurre excepción no manejada. | Widget y manual | Widget aprobado, tres variantes; manual pendiente |
| QA-05 | AC-05 | Inyectar colección vacía: aparece exactamente «No hay productos disponibles» y no se muestran tarjetas residuales. | Widget y manual | Widget aprobado en 320/escala 2; manual pendiente |
| QA-06 | AC-06 | Cerrar la app, desactivar conectividad y abrirla de nuevo: datos e imágenes incluidas aparecen y el catálogo permite desplazamiento. | Manual Android e iOS | Pendiente |
| QA-07 | AC-07 | Ejecutar las cuatro combinaciones de ancho lógico 320/390 y escala de texto 1.0/2.0 con descripción larga: sin overflow, superposición o contenido inaccesible por desplazamiento. | Widget y manual | Cuatro variantes widget aprobadas; manual pendiente |
| QA-08 | AC-07 | Simular insets y revisar dispositivo con áreas seguras: título, tarjetas y último contenido no quedan ocultos por sistema, notch o indicador de inicio. | Widget y manual | Insets simulados 44 superior/34 inferior aprobados; manual pendiente |
| QA-09 | AC-07 | Activar TalkBack y VoiceOver: identificar productos y leer nombre y descripción en orden lógico; el placeholder no impide identificar el producto. | Semántica widget y manual por plataforma | Nodo semántico con nombre antes de descripción y sin rol botón aprobado; TalkBack/VoiceOver pendientes |
| QA-10 | AC-08 | Compilar, instalar y recorrer QA-01 a QA-09 en Android; registrar dispositivo, SO, comando y resultado. | Plataforma Android | Compilación aprobada; instalación y recorrido pendientes |
| QA-11 | AC-08 | Compilar, instalar y recorrer QA-01 a QA-09 en iOS; registrar dispositivo/simulador, SO, Xcode, comando y resultado. | Plataforma iOS | Pendiente |
| QA-12 | AC-07, diseño M3 | Medir contraste de `onSurface/surface`, `onSurface/surfaceContainerLow`, `onSurfaceVariant/surface` y `onSurfaceVariant/surfaceContainerHighest` sobre el esquema real; cada pareja de texto alcanza al menos 4.5:1. | Automatizada | Aprobado: medición independiente, 2026-10-08 |
| QA-13 | Diseño M3 | Comprobar ventanas 600 y 840: una columna, ancho máximo de 600 y márgenes internos respectivos de 24 y 32. | Widget | Aprobado; también ventana 1200 |

## Comandos de verificación

Desde la raíz del proyecto:

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Adaptar las rutas de formato a los directorios Dart existentes. Las pruebas
widget cubrirán los fixtures y variantes de viewport anteriores, comprobando
excepciones, contenido visible y alcanzable, y árbol semántico. En los casos de
imagen corrupta se debe comprobar el manejo esperado del error sin silenciar
indiscriminadamente errores del framework. La lectura real con tecnologías de
asistencia requiere además validación manual.

En macOS con Xcode configurado, prever `flutter build ios --simulator` y ejecución
en simulador o dispositivo iOS. Las compilaciones no sustituyen las pruebas de
comportamiento. Una ejecución Android no valida iOS.

## Registro de evidencia

Entorno reportado por coordinación: Windows, Flutter 3.47.6, Dart 3.13.5.
Fecha de verificación: 2026-10-08, America/Santiago.

Medición independiente: `flutter test build/qa/contrast_test.dart --reporter expanded`,
salida 0, 1 prueba aprobada. Script temporal retirado al finalizar. Se utilizó
`ColorScheme.fromSeed(seedColor: Color(0xFF315C38))` y luminancias reales de Flutter.

| Pareja de texto / fondo | Contraste | Umbral | Resultado |
| --- | --- | --- | --- |
| `onSurface/surface` | 16.3189:1 | 4.5:1 | Aprobado |
| `onSurface/surfaceContainerLow` | 15.4852:1 | 4.5:1 | Aprobado |
| `onSurfaceVariant/surface` | 8.8886:1 | 4.5:1 | Aprobado |
| `onSurfaceVariant/surfaceContainerHighest` | 7.2267:1 | 4.5:1 | Aprobado |

| Verificación | Resultado ejecutado | Evidencia / limitación |
| --- | --- | --- |
| Formato | Aprobado por coordinación | Comprobación sobre `lib test`, salida 0. |
| Análisis estático | Aprobado por coordinación | `flutter analyze` final tras corrección de semántica, sin problemas, salida 0 (1.6 s de análisis). |
| Pruebas Flutter | Aprobado por QA | `flutter test --reporter expanded`, salida 0, 15/15 pruebas aprobadas; 6.75 s de proceso. |
| Compilación Android | Aprobado por coordinación | `flutter build apk --debug`, salida 0; regeneración final 37.8 s, `build/app/outputs/flutter-apk/app-debug.apk`. |
| Recorrido Android y sin conexión | Pendiente | `adb devices` sin dispositivos disponibles; no hubo instalación ni recorrido. |
| Compilación y recorrido iOS | Pendiente | Entorno Windows; se necesita macOS/Xcode. |

La suite decodifica los tres recursos locales incluidos, además de probar fixtures
de imagen ausente, ruta inexistente y bytes corruptos. Esto acredita el empaquetado
y manejo de recursos en pruebas Flutter; no sustituye el arranque sin conexión en
dispositivo. Los errores esperados de imagen se resuelven con `errorBuilder`, sin
silenciar globalmente excepciones.

Identificación del snapshot final (SHA-256):

```text
lib/catalog_page.dart B5E12256E34C49768334FF23E3DC6C45A352AF2AE4E2420A1DBAFDBC26AE9D9E
lib/main.dart EC5A5D6821C7ED5C5B4F3BAE8DDBC6C6E1AA3410F86583B0EBE3DE225A7E9D42
test/catalog_page_test.dart 9903E4149324C2C8222CA5EBF4454EBEC48F86C3F8F610B492FE7D13B18176C6
```

Para cada ejecución registrar fecha, revisión del código, caso, fixture, plataforma,
comando o pasos, resultado real y evidencia. Para un defecto añadir pasos de
reproducción, resultado esperado, resultado observado e impacto.

### Iteraciones de la suite

1. Primer intento interrumpido (salida 1): la prueba de decodificación aguardaba
   operaciones asíncronas nativas bajo el reloj simulado de `testWidgets`. Se
   corrigió envolviendo la decodificación explícita en `tester.runAsync`.
2. `flutter test --reporter expanded`: salida 1, 12 pruebas aprobadas y 3 fallidas.
   Las variantes a escala 2 no alcanzaron el final de descripciones muy altas con
   un único desplazamiento fijo de 5000; se pidió verificar el extremo real del
   scroll. La comprobación semántica esperaba etiquetas individuales, mientras
   Flutter entregó un nodo combinado con placeholder, nombre y descripción en
   orden. Se pidió comprobar ese contenido y orden reales. No se observó un
   desbordamiento de layout ni se confirmó defecto funcional en este intento.
3. Repetición: salida 1, 14 pruebas aprobadas y una fallida porque el handle de
   semántica se liberaba en un teardown posterior a la verificación de Flutter.
   Corregido mediante `dispose()` en `finally` dentro del cuerpo de la prueba.
4. Suite final: salida 0, 15/15 pruebas aprobadas. Las correcciones anteriores
   afectan la infraestructura y las aserciones de prueba. Los desajustes menores
   de diseño detectados en revisión (colores, fondo de imagen, estilo placeholder
   y padding vacío) también se corrigieron antes de este snapshot.

## Cierre QA

QA automatizado completado. Permanecen pendientes el arranque sin conexión,
recorridos visuales en Android/iOS, TalkBack, VoiceOver y compilación iOS.
AC-06 y AC-08 conservan estas limitaciones; no se declara validación completa de
ambas plataformas. La compilación Android no acredita comportamiento en iOS.
