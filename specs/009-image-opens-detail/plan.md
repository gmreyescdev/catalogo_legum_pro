# Plan — Navegación desde la imagen

1. En `ProductTile` de `lib/features/public_views.dart`, reutilizar la navegación
   vigente hacia `ProductDetailView` desde el `InkWell` de la foto y retirar el
   `TextButton` «Ver detalle». Conservar `cover`, marco 4:3 y fallback.
   Usar foto base de `Stack` y `Positioned.fill` con Material transparente e
   `InkWell` encima para que foco, hover y splash permanezcan visibles.
   IMG-AC-01/02/04.
2. Añadir etiqueta accesible `Abrir detalle de <nombre>`, rol botón y foco/teclado;
   aportar `Semantics.onTap` y excluir la semántica duplicada del `InkWell`;
   mantener una sola acción semántica. Verificar que checkbox y otras áreas no
   abran detalle ni alteren selección por pulsar la imagen. IMG-AC-02/03.
3. Adaptar la prueba de navegación existente: localizar y activar el acceso
   accesible de la imagen en lugar del texto eliminado. Comprobar detalle y
   regreso, incluida imagen no disponible, sin añadir una batería redundante.
   IMG-AC-01 a 04.
4. Ejecutar formato, análisis y pruebas pertinentes. Construir y actualizar
   Android físico autorizado con `adb install -r`, confirmando éxito antes de
   abrir. No emuladores, desinstalaciones ni alteración de datos. Cualquier prueba
   nativa usa paquete `.integration` verificado previamente; iOS queda separado.
   IMG-AC-05.

Registrar criterios del spec cubiertos, resultados reales y pendientes en
`tasks.md`/`qa.md`. Este plan no acredita ejecución ni instalación completadas.
