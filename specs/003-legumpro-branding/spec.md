# SPEC-003 — LegumPro e imágenes de tarjeta

Estado: marca e imágenes implementadas; pregunta del nombre PDF resuelta por
SPEC-004 con dos modos y nombres fijos, sin configuración editable.

## Alcance y criterios

- BRAND-AC-01: nombre visible de app, catálogo y marca PDF cambia de Legum a
  LegumPro. Preservar identificador de paquete, DB, rutas y claves protegidas
  para mantener datos y acceso existentes.
- BRAND-AC-02: la portada llena el área 4:3 de la tarjeta sin deformarse, con
  recorte centrado cuando difieren proporciones. Detalle/galería muestran imagen
  completa. Mantener fallback, texto ampliado y semántica accesible.
- BRAND-AC-03: respuesta posterior en SPEC-004 define LegumPro_Catalogo.pdf para
  completo y LegumPro_Catalogo_Personalizado.pdf para selección, sin ajustes editables.
- BRAND-AC-04: formato/análisis/tests/build y actualización Android físico;
  evidencia separada de iOS pendiente.
