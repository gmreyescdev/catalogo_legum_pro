# Plan — Rediseño editorial del catálogo PDF

Usuario autorizó implementación; no requiere otra confirmación. Registrar evidencia.

1. En `lib/data/whatsapp/native_whatsapp_gateway.dart`, mantener carga única logo
   y fuentes locales; definir paleta/estilos de diseño sin dependencias, edición
   de imagen ni cambios UI/DB.
2. Cabecera forest repetida con logo completo, título, modalidad scope y cantidad
   deduplicada; footer marca/paginación. PDF-AC-02/03.
3. Widgets independientes: nombre span, foto contain 190 pt, presentación span,
   bloque atómico precio Kg/normal tachado, estado textual y separador. No agrupar
   producto entero en Container/Row/Table indivisible. Revisar salto condicionado
   y densidad natural sin forzar cantidad/página. PDF-AC-01/04.
4. Adaptar pruebas existentes de modalidades/precios/cantidad/logo. Mantener
   regresión textos extensos/fotos ausentes/corruptas, sin fijar número antiguo
   de páginas. Extraer nombres/presentaciones completos con marcadores finales,
   importes/estados y excluir campos ajenos al alcance. PDF-AC-01 a 04.
5. Generar ambos PDF con oferta/sin oferta; render primera/intermedia/última del
   largo. Revisar jerarquía, proporción, solapamientos, márgenes, distintivos y
   legibilidad. Ajustar huérfanos sin perder texto. Documentar formato/análisis/
   pruebas; conservar nombres/compartir sin enviar a contactos. PDF-AC-05.
6. Build y actualización Android físico con `adb install -r`, confirmar éxito
   antes de iniciar; no desinstalar ni sustituir datos. Integración solo APK
   `.integration` verificado. iOS requiere entorno separado.

Coordinador mantiene spec/tareas/QA consistentes. Pendientes no son resultados.
