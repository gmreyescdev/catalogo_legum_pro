# SPEC-012 — Catálogo compacto y administración Material 3

Estado: implementación autorizada. El usuario confirmó formato SKU numérico
correlativo `1`, `2`, `3`… conservando los SKU existentes.

## Objetivo y alcance

Rediseñar el catálogo público y las secciones de administración existentes.
Facilitar crear un producto con SKU automático y crear su categoría sin perder
el borrador. Conservar el catálogo real, PIN, respaldos y PDF de cuatro productos
por página. No añadir sincronización, funciones comerciales ni campos nuevos.

## Criterios de aceptación

- ADM-AC-01: Catálogo público con dos tarjetas por fila. Cada tarjeta contiene
  únicamente imagen, nombre y control de incluir en PDF; tocar imagen abre detalle.
  Precio, presentación y disponibilidad permanecen en detalle y PDF.
- ADM-AC-02: Selección PDF independiente, filtros, búsqueda, orden y compartir
  completos/personalizados conservados. Fotos ajustadas y decode acotado.
- ADM-AC-03: Administración con NavigationBar Productos, Categorías y Ajustes en
  ventana compacta y navegación adaptable cuando haya más espacio.
- ADM-AC-04: Añadir producto mediante FAB en Productos, separado de las tarjetas,
  con espacio de desplazamiento para no tapar acciones. Tarjetas administrativas
  compactas con imagen, identificación y acciones actuales accesibles.
- ADM-AC-05: SKU nuevo único, automático y correlativo, precargado de solo lectura.
  Conservar SKU de productos existentes. Asignación definitiva atómica al guardar,
  sin consumir números al abrir/cancelar ni reutilizar números emitidos tras borrar.
  Migración conserva datos y parte del mayor correlativo numérico existente.
  Formato adoptado: `1`, `2`, `3`…; campo de solo lectura también en edición.
- ADM-AC-06: Crear categoría desde formulario de producto, guardar y seleccionarla
  automáticamente sin perder campos, fotos, precios ni estado del borrador.
  Cancelación/error no cambian selección; duplicados y sesión protegidos.
- ADM-AC-07: Categorías rediseñadas con nombre, cantidad de productos y acciones
  actuales; Ajustes agrupados en Apariencia, Seguridad y Respaldo, sin alterar PIN,
  recuperación, confirmación de reemplazo ni funcionalidades existentes.
- ADM-AC-08: M3 con controles de al menos 48 dp, estados vacíos/error/progreso,
  claro/oscuro y ausencia de overflow a 320 dp y escala 2. Nombres completos pueden
  crecer; usar filas lazy sin alturas fijas que corten contenido.
- ADM-AC-09: Pruebas de SKU/migración/concurrencia y borrador/categoría, regresiones
  de UI y protección, formato/análisis y Android físico con instalación -r.
  No emuladores ni sustitución de datos reales. iOS requiere Xcode.

## Decisiones de datos

El correlativo considera SKU existentes del formato elegido; otros códigos se
conservan y no se renumeran. Un respaldo restablecido reconcilia el mayor valor
con el contador local sin reducirlo. Un respaldo antiguo no puede acreditar
historial de SKU de productos borrados en otro dispositivo.
