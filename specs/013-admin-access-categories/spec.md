# SPEC-013 — Acceso administrativo y Categorías

Estado: entregada en Android físico, versión 0.7.1+13.

## Objetivo y alcance
Rediseñar el acceso administrativo y Categorías manteniendo sus funciones.
El botón Entrar indica visualmente la operación real en curso. Separar acciones,
campos y tarjetas claramente; aplicar este criterio a futuros diseños del proyecto.
No cambiar PIN, recuperación, autenticación, datos ni navegación existentes.

## Criterios de aceptación
- ACC-01: acceso con jerarquía M3 clara, icono de seguridad, título e indicación,
  formulario y acciones en layout scroll adaptable al teclado y texto ampliado.
- ACC-02: Entrar muestra indicador indeterminado y texto accesible mientras vm.busy;
  acción deshabilitada y sin envíos duplicados; error permite reintento. Sin demora
  artificial. Recuperación/configuración conservan sus estados y controles.
- ACC-03: mínimo 24 dp entre campos y grupo de acciones y entre añadir categoría
  y primera tarjeta; 16 dp entre tarjetas/grupos y 12 dp dentro de grupos de acciones.
  Son decisiones del proyecto, no requisitos universales de Material Design.
- ACC-04: Categorías presenta encabezado, resumen, creación separada, tarjetas
  con nombre/conteo/icono y acciones editar/eliminar/reordenar existentes.
  Estado vacío claro. Conserva restricciones al eliminar categorías con productos.
- ACC-05: controles táctiles >=48 dp, layout compacto 320 dp/texto 2× sin overflow,
  colores con roles M3 en tema claro/oscuro; textos y acciones accesibles.
- ACC-06: formato/análisis/pruebas pertinentes; build e instalación Android físico
  conservando catálogo cuando esté disponible. iOS se acredita solo con Xcode.

## Escenarios
Acceso correcto, PIN incorrecto, operación pendiente y reintento; recuperación
existente; categorías vacías/con productos/nombres largos; editar, reordenar y
cancelar eliminación; ventana estrecha, teclado y escala de texto ampliada.
