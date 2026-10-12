# Plan — Precio por kilogramo e imagen ajustada en el detalle

1. En `lib/ui/widgets.dart`, añadir opción booleana `perKilogram` a `Prices`, con valor
   por defecto `false`. Añadir ` x Kg` a precio normal y vigente solo al activarla.
   Conservar cálculo CLP, estilos y etiqueta de oferta. KG-AC-01/02/03.
2. En `lib/features/public_views.dart`, activar la opción exclusivamente en
   `ProductDetailView`. Mantener tarjetas, selección y otros usos sin cambios.
   No modificar modelos, sqflite, presentación almacenada ni PDF. KG-AC-03.
3. En el `ProductPhoto` del detalle, añadir `fit: BoxFit.cover`. Reutilizar el
   marco 4:3 y decode acotado existentes; conservar navegación de cada foto,
   fallback, semántica y originales. No añadir Cards ni cambiar las otras vistas
   o el PDF. KG-AC-05.
4. Verificar formato y análisis, y comprobar los casos sin oferta/con oferta y
   aislamiento del resto de vistas según QA. No añadir dependencias ni pruebas
   que solo reproduzcan la interpolación del sufijo. Revisar fotos verticales,
   panorámicas y cambio de foto: llenar marco con recorte, sin deformar ni perder
   fallback accesible. KG-AC-01 a 05.
5. Construir APK normal y actualizar el Android físico autorizado mediante
   `adb install -r`; confirmar éxito antes de abrir. No desinstalar ni sembrar
   datos. Si se usa integración, verificar primero su paquete aislado `.integration`.
   Registrar evidencia real y pendientes; ejecución iOS requiere Xcode. KG-AC-04.

Este documento define el plan; sus pasos ejecutados se registran en `tasks.md`
y `qa.md`, sin presumir instalación o validación completadas.
