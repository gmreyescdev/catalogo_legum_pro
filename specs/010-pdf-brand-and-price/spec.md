# SPEC-010 — Diseño del PDF, logo y precios por Kg

Estado: implementada y entregada en Android físico, versión 0.6.3+10.

La distribución y el flujo completo de nombres/presentaciones largos se sustituyen
por SPEC-011: cuatro productos por página y resúmenes con puntos suspensivos,
autorizados por el usuario. La marca y precios por Kg se conservan.

## Objetivo y alcance

El PDF compartido incorpora el logo existente de LegumPro en su cabecera,
expresa todos los precios por kilogramo y mejora su presentación visual.
El usuario amplió el alcance con «diseña un pdf más atractivo» durante la
implementación. Aplica al catálogo completo y al
personalizado, conservando la selección, los nombres de archivo y los campos
actuales (presentación, imagen y disponibilidad).

## Criterios de aceptación

- PDF-AC-01: El precio vigente muestra `Precio: $1.500 CLP x Kg` o `Oferta: ...
  CLP x Kg`; el precio normal de una oferta también lleva `x Kg`.
- PDF-AC-02: Cada página incluye el logo oficial existente en la cabecera,
  proporcional, sin deformación ni superposición con título o productos.
- PDF-AC-03: Ambos tipos de catálogo aplican el cambio y conservan nombres
  `LegumPro_Catalogo.pdf` y `LegumPro_Catalogo_Personalizado.pdf`, campos y selección.
- PDF-AC-04: Fotos ausentes/corruptas y contenido largo siguen exportándose.
- PDF-AC-05: Formato, análisis, pruebas PDF pertinentes e inspección visual del
  documento; build e instalación Android físico con datos conservados si conectado.
- PDF-AC-06: Diseño legible y consistente con LegumPro: cabecera de marca,
  imágenes destacadas proporcionales, jerarquía clara para nombre/presentación,
  precio destacado, disponibilidad identificada con texto y color, separación
  entre productos y numeración de páginas. El contenido largo conserva su flujo.

## Límites

No modificar precios guardados, presentación ni comportamiento de WhatsApp. No
incorporar descripción privada ni SKU al documento. El logo se reutiliza sin
rediseñarlo. iOS requiere entorno nativo con Xcode.
