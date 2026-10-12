# SPEC-006 — Marca compacta en cabecera

## Objetivo y decisión autorizada

El usuario rechazó el bloque de logo de 160 dp de SPEC-005 y aprobó mostrar un símbolo pequeño dentro de un círculo junto al título «Catálogo LegumPro». Esta spec sustituye únicamente la ubicación del logo dentro del catálogo de SPEC-005.

## Alcance y escenarios

Al abrir el catálogo, con o sin productos, el encabezado muestra el símbolo y el título en una misma fila. Al reducir el ancho o ampliar el texto, el título puede ocupar varias líneas y la cabecera crece. El cuerpo comienza con las acciones existentes, sin el antiguo bloque de marca.

## Criterios de aceptación

- CAB-AC-01: El catálogo muestra `assets/branding/legumpro-icon.png` en un círculo de 40 × 40 dp, a la izquierda del título, separado por 12 dp. Se conserva la proporción del símbolo y no se muestra texto rasterizado adicional.
- CAB-AC-02: El bloque grande con `legumpro-logo.jpg` y su separación reservada desaparecen del cuerpo. El título «Catálogo LegumPro» se conserva una sola vez en la cabecera.
- CAB-AC-03: La cabecera usa los tokens existentes `surface`, `onSurface` y `titleLarge`, admite título multilínea sin recorte ni desbordamiento en ancho compacto y con texto ampliado; funciona en claro y oscuro.
- CAB-AC-04: El símbolo es decorativo, sin acción ni foco independiente; el título sigue marcado como encabezado accesible. Los controles existentes mantienen áreas de toque de al menos 48 × 48 dp.
- CAB-AC-05: Los demás encabezados conservan su apariencia; administración, navegación, búsqueda, filtros, selección, PDF, iconos de launcher, datos y credenciales conservan su comportamiento.
- CAB-AC-06: Verificar formato, análisis y pruebas pertinentes en host. Compilar la actualización Android y, si está conectado, instalar con actualización sin desinstalar en dispositivo físico. Registrar evidencia pendiente por separado. No usar emuladores; iOS requiere Xcode para validación nativa.

No se modifican imágenes ni assets de marca; se reutiliza el símbolo existente.
