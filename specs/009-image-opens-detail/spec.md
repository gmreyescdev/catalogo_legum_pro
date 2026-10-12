# SPEC-009 — Abrir detalle desde la imagen

Estado: implementada y entregada en Android físico, versión 0.6.2+9.

## Objetivo y alcance

En las tarjetas del catálogo, eliminar el botón «Ver detalle». Tocar la imagen
abre el detalle del producto mediante la navegación Material existente.

## Criterios de aceptación

- IMG-AC-01: La imagen de cada tarjeta del catálogo abre su producto correcto.
- IMG-AC-02: El botón «Ver detalle» desaparece de las tarjetas; selección y otros
  controles conservan su comportamiento.
- IMG-AC-03: La imagen tiene acción accesible de abrir detalle, identificada por
  nombre de producto, y foco para teclado. La alternativa de imagen ausente o
  inválida también permite entrar al detalle.
- IMG-AC-04: Mantener ajuste cover, decode acotado, estilos M3, precios por Kg
  del detalle y botón/gesto de regreso existentes.
- IMG-AC-05: Verificar formato, análisis y pruebas pertinentes; actualizar el
  Android físico mediante `adb install -r`, sin desinstalar ni reemplazar datos.

## Verificación

Registrar ejecutado y pendiente en `qa.md`. iOS requiere su entorno nativo.
