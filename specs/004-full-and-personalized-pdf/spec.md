# SPEC-004 — Catálogo completo y personalizado

Estado: implementación integrada, suite y Android físico verificados según qa.md.
Sustituye la restricción de
solo selección de SPEC-002 y resuelve la pregunta de nombres PDF de SPEC-003.

## Requisitos y escenarios

El usuario elige explícitamente compartir todos los productos visibles o compartir
su selección. Ambos incluyen nombre, portada, presentación, precio CLP y estado.
Agotados incluidos; ocultos excluidos. Título interior: Catálogo LegumPro.
Nombres fijos, no campos editables de Ajustes:

- Completo: LegumPro_Catalogo.pdf.
- Personalizado: LegumPro_Catalogo_Personalizado.pdf.

## Criterios de aceptación

- SHARE-AC-01: acción Catálogo completo usa todos los productos públicos vigentes
  en orden de catálogo, ignorando búsqueda/filtro y selección; vacío la deshabilita.
- SHARE-AC-02: acción Compartir selección usa solo seleccionados públicos vigentes.
  Conserva selección incluso si contiene todo el catálogo; sigue siendo personalizado.
- SHARE-AC-03: nombre real del archivo adjunto y nombre ofrecido al compartir
  coinciden exactamente con modo completo/personalizado. Guardar cada exportación
  en ubicación privada única para evitar sobrescribir un PDF entregado antes.
- SHARE-AC-04: error/cancel no modifica catálogo ni selección. Ambos modos comparten
  bloqueo busy para evitar acciones simultáneas, con progreso y errores visibles.
- SHARE-AC-05: conservar contenido PDF, marca LegumPro, portada ajustada a tarjetas,
  paginación/fuentes, retención/limpieza, sin número fijo ni envío automático.
- SHARE-AC-06: verificación host/build y Android físico cuando esté conectado;
  no emuladores ni envío a contactos, iOS pendiente separado.

## Compatibilidad

Sin cambios de esquema, credenciales ni formato de respaldo. Limpieza considera
PDF antiguos y nuevos directorios privados; retira archivos propios >24h al
iniciar/generar y cancel/error inmediato. No borra archivos ajenos.
