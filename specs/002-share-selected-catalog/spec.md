# SPEC-002 — Compartir selección como catálogo PDF

Estado: implementación integrada y pruebas host/nativas Android ejecutadas;
evidencia y límites en `qa.md`. Sustituye el flujo de consultas por WhatsApp de
SPEC-001 (V2-AC-14/15) para enviar catálogo a clientes.
Actualización posterior: SPEC-004 añade catálogo completo y los nombres fijos
solicitados. Su alcance prevalece sobre la restricción de solo selección de aquí.

## Alcance confirmado

Solo productos seleccionados por el usuario. El PDF muestra nombre identificador,
precio CLP vigente, presentación, una imagen de portada y disponibilidad
Disponible/Agotado. Esta lista final sustituye la propuesta anterior de incluir
la descripción. No exportar todo el catálogo automáticamente ni productos ocultos.
No se necesita un número fijo: el usuario elige WhatsApp y destinatario en el
compartidor nativo, y confirma allí el envío. La app no envía automáticamente.

## Escenarios y criterios

- PDF-AC-01: selección vacía bloquea generación; seleccionar/quitar conserva orden
  de catálogo. Los ocultos/eliminados quedan fuera; los agotados siguen incluidos.
- PDF-AC-02: generar solo selección vigente con nombre, presentación, portada,
  precio vigente CLP y etiqueta textual de disponibilidad. Si hay oferta, mostrar
  precio normal y oferta. No incluir descripción, SKU, credenciales ni datos ocultos.
- PDF-AC-03: generación local sin red; imagen ausente/corrupta tiene alternativa
  visible. Texto extenso pagina completo y acentos españoles se conservan.
- PDF-AC-04: compartir archivo real application/pdf con nombre legible mediante
  selector nativo. Instruir elegir WhatsApp/cliente. No exigir número configurado,
  no afirmar entrega, no enviar mensajes a terceros durante pruebas automatizadas.
- PDF-AC-05: cancelación/error conserva selección y datos; impedir duplicar comando
  mientras está ocupado, mostrar progreso/error y conservar borrador al lifecycle.
- PDF-AC-06: controles M3 con targets48dp, 24dp antes de acción, texto ampliado;
  sustituir etiquetas de consulta y retirar ajuste de destinatario fijo de la UI.
- PDF-AC-07: mantener compatibilidad SQLite/backups anteriores, proteger temporales,
  verificar formato/análisis/tests y Android físico; iOS explícitamente pendiente.

## Decisiones de implementación

La portada es la primera imagen ordenada. El detalle permite incluir/quitar y abrir
la selección para enviar; no exporta un producto ajeno a la selección. La selección
se conserva incluso tras abrir el compartidor. El número legado en ajustes/backup
se conserva para compatibilidad, sin usarse ni mostrarse en este flujo.
PDF A4 legible con paleta bosque/crema propuesta, fuente local licenciada y sin
contenido remoto. Retención de PDF privado 24h para que receptor pueda leer;
limpieza al arranque o al generar cuando superan 24h, inmediata en
fallo/cancelación confirmada. No hay temporizador de borrado con la app cerrada.
