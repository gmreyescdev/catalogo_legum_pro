# Plan de implementación — SPEC-001

Estado: implementación y comprobaciones automatizadas completadas; diseño M3
integrado. APK Android compilado; verificaciones manuales y compilación iOS pendientes.

## Base y límites

El proyecto ya contiene un punto de entrada Flutter mínimo en `lib/main.dart` y
usa únicamente Flutter, `flutter_test` y `flutter_lints`. Se conservarán estas
dependencias: este catálogo local no necesita paquetes, backend, navegación ni
un gestor de estado externo.

La fuente funcional es `spec.md`. El coordinador adopta una pantalla única y
datos locales de demostración como decisiones de esta implementación autorizada.
La descripción completa, estados alternativos y pruebas de `qa.md` se conservan.
Se integró `design.md`, actualizado según la skill local
`.agents/skills/flutter-product-design/SKILL.md`: usar exclusivamente Material
Design 3 con tokens, componentes, adaptación de layout, accesibilidad y código
base Flutter documental. Aplicar sus decisiones en T04. Las propuestas que
cambien comportamiento deberán resolverse en el spec;
una decisión visual no amplía el alcance.

## Integración del diseño Material 3

Aplicar `ThemeData(useMaterial3: true)`, los roles de `ColorScheme` con sus pares
de contenido y la escala `TextTheme` indicados por el diseñador. Seleccionar solo
los componentes pertinentes para lectura del catálogo: no incorporar controles,
navegación o acciones adicionales por aparecer como ejemplos en la skill.

Generar el esquema claro desde semilla `#315C38`; usar `surface/onSurface` en
pantalla, `surfaceContainerLow/onSurface` en tarjetas y
`surfaceContainerHighest/onSurfaceVariant` en el marco de imagen. El aviso usa
`onSurfaceVariant` sobre `surface`. Tarjetas `Card.outlined`, radio 12, elevación
0 y borde `outlineVariant`. El título y nombres usan `titleLarge`, descripción y
estados `bodyLarge`, aviso `bodyMedium`.

Mantener imagen 4:3 y descripción completa. Encabezado flexible con mínimo 64 dp;
una columna centrada con máximo 600 dp incluyendo márgenes. Márgenes laterales:
16 dp en ventanas menores a 600, 24 dp entre 600 y 839, 32 dp desde 840.
Separación entre tarjetas 16 y margen final 24. La adaptación conserva la misma
pantalla y contenido. La paleta sigue siendo propuesta hasta recibir identidad
de marca. Los contrastes solo se consideran verificados con colores concretos
medidos; la evidencia de texto ampliado, semántica y plataformas sigue en `qa.md`.
Las referencias oficiales y el código base de interfaz pertenecen a `design.md`.

## Estructura prevista

- `lib/main.dart`: arranque y aplicación con el tema definido por diseño.
- `lib/product.dart`: modelo inmutable con identificador, nombre, descripción y
  ruta de imagen local opcional, sin lógica de red.
- `lib/catalog_data.dart`: colección de demostración identificada como tal.
- `lib/catalog_page.dart`: lista desplazable, tarjeta y estado vacío. Recibe la
  colección por constructor para verificar escenarios sin modificar datos globales.
- `assets/products/`: imágenes de demostración incluidas en el paquete.
- `pubspec.yaml`: declaración de los assets realmente incluidos.
- `test/catalog_page_test.dart`: pruebas de los comportamientos del spec.

Es posible mantener componentes pequeños privados en `catalog_page.dart`; no
crear capas de repositorio, servicios o abstracciones sin una necesidad concreta.

## Secuencia y dependencias

| Paso | Trabajo y resultado | Depende de | Criterios |
| --- | --- | --- | --- |
| T01 | Integrar actualización M3 de `design.md` y revisar consistencia con spec y QA | Diseño y revisión QA | AC-01–08 |
| T02 | Modelo, datos de demostración, imágenes y declaración de assets | T01 | AC-01, AC-04, AC-06 |
| T03 | Sustituir pantalla inicial por catálogo, tarjetas y estado vacío | T02 | AC-01–05 |
| T04 | Aplicar tokens y componentes M3, layouts adaptables, áreas seguras, reflujo de texto y semántica | T03 y diseño M3 integrado | AC-03, AC-07 |
| T05 | Pruebas de contenido, desplazamiento, imagen fallida, vacío y tamaños | T04 y casos QA | AC-01–07 |
| T06 | Formato, análisis y pruebas; corregir fallos pertinentes | T05 | AC-01–07 |
| T07 | Verificación de plataforma disponible y registro de limitaciones | T06 | AC-06–08 |
| T08 | Integración final de evidencia y estado de tareas por coordinador | T07 | AC-01–08 |

No editar concurrentemente el mismo archivo. El codificador posee `lib/`, assets,
`pubspec.yaml` y pruebas durante la implementación; QA recibe esos archivos una
vez estables y registra sus resultados en `qa.md`. El coordinador integra el estado
final de los documentos.

## Verificación prevista

Usar pruebas de widgets para comprobar todos los nombres y descripciones, llegar
al último producto, conservar descripciones largas, renderizar el mensaje vacío y
mantener contenido ante imagen ausente o inválida. Verificar anchos 320 y 390 con
escalas 1.0 y 2.0, ausencia de excepciones de layout y orden semántico. Las pruebas
deben observar comportamiento; no limitarse a comprobar tipos internos de widgets.
Complementar con ventanas 600 y 840 para verificar adaptación del diseño.
Calcular contraste de las cuatro parejas de texto usadas con los colores
generados y registrar si alcanzan 4.5:1; este cálculo no sustituye la comprobación
de lectura con TalkBack/VoiceOver.

Ejecutar `dart format`, `flutter analyze` y `flutter test` con el SDK disponible.
Comprobar que las imágenes locales están declaradas y empaquetadas; el uso sin
conexión en dispositivo se registra aparte de las pruebas automatizadas. Compilar
y ejecutar Android cuando el entorno lo permita. Para iOS, compilar y probar en
macOS con Xcode: cualquier ejecución pendiente se documentará como pendiente,
sin inferir soporte verificado a partir de Android ni de widgets.

## Dependencias abiertas y riesgos

- Seguir la actualización M3 integrada; no inventar una segunda dirección visual.
- Los productos definitivos y recursos de marca no fueron suministrados. Usar
  ejemplos claramente identificados y recursos locales válidos sin afirmar que
  representan productos comerciales definitivos.
- La disponibilidad del SDK y herramientas de plataforma debe comprobarse al
  ejecutar; todavía no hay resultados de formato, análisis, pruebas o compilación.
