# Diseño — SPEC-004

## Jerarquía visual y modos

SHARE-AC-01/02: la pantalla pública Catálogo LegumPro presenta una acción
**Compartir catálogo completo**, seguida de una explicación de su alcance,
búsqueda, categorías y tarjetas. Se comparte todo producto visible vigente,
incluidos agotados, independientemente de filtros o selección. El botón se
deshabilita si no hay productos públicos o hay una operación en curso.

La selección mantiene su entrada Ver selección y su revisión de tarjetas.
Su acción es **Compartir selección** y conserva el texto que explica imagen,
presentación, precio y disponibilidad y la elección posterior de WhatsApp y
cliente. Seleccionar todos manualmente sigue siendo el modo personalizado.
Ninguno de los modos borra la selección ni incorpora campos de nombre en Ajustes.

SHARE-AC-03: título interior Catálogo LegumPro. El archivo completo se llama
LegumPro_Catalogo.pdf; el seleccionado LegumPro_Catalogo_Personalizado.pdf.

## Material Design 3, tokens y estados

Se conserva el tema M3 existente, claro/oscuro/sistema. Las acciones PDF usan
FilledButton.icon con icono picture_as_pdf_outlined, colores primary/onPrimary,
tipografía labelLarge y elevación por defecto del componente Flutter. No se añade
elevación propia. Las tarjetas conservan Card.outlined, surfaceContainerLow,
titleMedium y bodyMedium. La portada mantiene proporción 4:3 con BoxFit.cover,
sin deformarse; el detalle conserva la imagen completa.

SHARE-AC-04: ambos modos usan el mismo estado busy. LinearProgressIndicator y
texto Preparando catálogo para compartir aparecen junto a la acción de cada
pantalla. Los errores usan ErrorMessage con token error y semántica liveRegion.
El catálogo muestra estos estados aunque no exista selección. El origen del
compartidor procede del RenderBox del botón pulsado, también para iPad.

## Adaptación y accesibilidad

Se mantienen márgenes 16 dp compactos (<600), 24 dp medianos (<840) y 32 dp
expandidos. Tarjetas en una columna compacta y dos a partir de 600 si la escala
de texto lo permite, medianil 16 dp. El botón ocupa el ancho útil y permite que
su texto crezca; todo el contenido superior participa del desplazamiento.
Se separa el bloque de acción de búsqueda con 24 dp y la ayuda con 8 dp.
Las áreas de botones heredan mínimo 48 × 48 dp del tema. La prueba de regresión
320 dp y texto ampliado existente se mantiene; el coordinador registra resultados.
El contraste conserva pares ya comprobados por la prueba del tema, sin introducir
colores nuevos; no se declara nueva verificación física de accesibilidad.

## Código integrado y referencias

Flutter: `CatalogViewModel.shareAll` obtiene `publicProducts` y envía scope
complete; `shareSelected` obtiene `selected` y envía scope personalized.
`CatalogView`, `SelectionView` y `_ShareFeedback` implementan los estados.

Referencias oficiales consultadas:

- [Botones Material Design 3](https://m3.material.io/components/buttons/overview).
- [FilledButton de Flutter](https://api.flutter.dev/flutter/material/FilledButton-class.html)
  (consulta web temporalmente no disponible; se conserva el componente existente).

Verificaciones propuestas: vacío con ocultos, filtros sin coincidencias que no
deshabilitan completo, disponibilidad/ocultos, ancla no vacía, busy/error visibles,
selección conservada y regresiones de texto ampliado. Las pruebas escritas no
equivalen a resultados ejecutados ni acreditan iOS.
