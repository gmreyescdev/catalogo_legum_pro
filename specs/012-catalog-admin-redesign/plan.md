# Plan — Catálogo y administración

1. Resolver en spec formato/generación de SKU y alcance sobre productos existentes
   antes de implementar ese comportamiento. No inferir migración desde cambio visual.
   ADM-AC-05.
2. En `lib/features/public_views.dart`, simplificar `ProductTile` a foto/nombre/
   selección y fijar dos columnas. Mantener lazy rows, alturas naturales, imagen
   accesible y filtro/selección/detalle/PDF vigentes; sin pérdida de originales.
   ADM-AC-01/02/08.
3. En `lib/features/admin_views.dart` y soporte mínimo de `PageFrame` si necesario,
   mover destinos a NavigationBar compacto/NavigationRail mediano-expandido;
   separar FAB de lista con padding reservado. Preservar Navigator, bloqueo,
   sesión, regreso y borradores en `catalog_app.dart`, sin reiniciar formularios.
   ADM-AC-03/04/08.
4. Refinar tarjetas Productos/Categorías y grupos de Ajustes con tokens actuales.
   Inventariar acciones antes/después para conservar editar, borrar, estados,
   reordenar, crear, PIN, tema y respaldo; callbacks siguen protegidos y ocupados.
   ADM-AC-04/07/08.
5. En formulario, integrar creación de categoría con ID retornado y autoselección;
   preservar borrador y errores. Implementar SKU readonly solo al resolver spec,
   generación estable y unicidad desde persistencia, no desde render.
   Asignación atómica al guardar, contador sin consumo al cancelar ni reutilización
   tras borrar; migración y reconciliación de respaldos conservan SKU y mayor
   correlativo. Verificar concurrencia. ADM-AC-05/06.
6. QA verifica exactamente dos columnas a 320 dp/2× sin overflow, accesibilidad de
   imagen/checkbox, navegación tres destinos, última tarjeta sin cubrir por FAB,
   categorías desde formulario, SKU y regresiones de seguridad/datos/PDF. Ejecutar
   formato/análisis/pruebas pertinentes, sin confundir host con rendimiento nativo.
   ADM-AC-01 a 09.
7. Revisar físicamente Android, mantener decode acotado/lazy y comprobar fluidez.
   Build normal y `adb install -r` confirmado sin desinstalar ni sustituir datos.
   Integración solo APK `.integration` verificado; sin emuladores ni envíos a contactos.
   iOS requiere Xcode y verificación separada.

Coordinador vincula criterios una vez publicados y mantiene tareas/QA fieles a lo
ejecutado. Diseño y plan no acreditan tests, contrastes ni instalación.
