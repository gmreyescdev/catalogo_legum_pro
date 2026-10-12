# SPEC-008 — Precio por kilogramo e imagen ajustada en el detalle

Estado: implementado y entregado en Android 0.6.1+8. Verificaciones y límites en
`qa.md`; iOS pendiente de su entorno nativo.

## Objetivo y alcance

Mostrar que el precio del producto corresponde a un kilogramo en la pantalla
de detalle. Conservar importes y formato CLP actuales, agregando ` x Kg`.
Ejemplo: `Precio: $1.500 CLP x Kg`.

Ampliación solicitada: la foto del detalle debe llenar su marco de imagen,
conservando la proporción. Usar `BoxFit.cover`: recortar bordes cuando la foto
tenga otra proporción, sin deformar ni modificar el archivo original. Aplicar
el mismo comportamiento a cada foto de la galería del detalle.

## Escenarios y criterios de aceptación

- KG-AC-01: Un producto sin oferta muestra `Precio: <importe CLP> x Kg` en detalle.
- KG-AC-02: Con oferta, tanto el precio normal tachado como el precio de oferta
  indican `x Kg`, conservando distintivo y estilos existentes.
- KG-AC-03: La modificación corresponde al detalle; los otros usos del componente
  de precios conservan su presentación. No modifica importes, presentación,
  datos guardados ni generación de PDF.
- KG-AC-04: Verificar formato y análisis; actualizar la app Android física con
  `adb install -r`, conservando datos. Registrar ejecutado y pendiente por separado.
- KG-AC-05: Las fotos del detalle llenan el marco con `BoxFit.cover`, sin bandas
  vacías ni deformación. Galería, alternativas accesibles y decode acotado se
  conservan; los originales y el contenido PDF no se alteran.

## Entregables

Diseño, plan, tareas y resultados QA se registran junto a esta especificación.
iOS requiere su entorno nativo para comprobar ejecución.
