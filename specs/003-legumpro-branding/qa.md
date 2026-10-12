# QA — SPEC-003

Resultados pendientes. Verificar marca visible, portada ajustada sin deformación,
imagen completa en detalle, persistencia previa, PDF y controles de configuración
si son confirmados. Android exclusivamente físico; iOS requiere Xcode.

## Verificación coordinada — 2026-10-08

Implementados marca visible LegumPro y ajuste de portadas en tarjetas. El PDF
por defecto usa título Catálogo LegumPro y archivo Catalogo_LegumPro.pdf.
El nombre PDF configurable sigue pendiente de respuesta sobre título/archivo.

- Formato aplicado, analizador EXIT0 sin observaciones.
- Pruebas del servicio PDF: 8 aprobadas.
- Pruebas UI y regresión de bloqueo PIN: 11 aprobadas.
- Build APK debug: EXIT0 (18,4 s).
- SHA-256 APK: 4698C1B7136530728335FB5E3BED74D6B6C74C0AAFF9835F4F9C9BB7281C0B71.
- No se instaló esta build: ADB no detecta dispositivo conectado. No se usó emulador.
- El recorte cover está limitado a tarjetas; detalle y editor mantienen contain.
  Inspección visual física del ajuste e iOS siguen pendientes.
- Se conservaron package ID, rutas persistentes y claves de autenticación.
