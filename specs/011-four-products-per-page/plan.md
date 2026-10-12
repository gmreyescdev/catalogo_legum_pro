# Plan — Grilla PDF fija de cuatro productos

1. En `lib/data/whatsapp/native_whatsapp_gateway.dart`, conservar selección,
   deduplicación, logo, fuentes, `_cover`, importes y archivos. Sustituir flujo
   editorial `MultiPage` por páginas A4 explícitas de hasta cuatro productos.
2. Implementar cabecera/footer compactos y grilla 2 × 2 de `design.md`; cantidad
   total/paginación derivadas. Página final sin productos ficticios. No forzar
   saltos condicionales anteriores ni reutilizar `NewPage(freeSpace: 450)`.
3. Tarjetas con foto contain/fallback, precio Kg completo, normal/oferta y estado.
   Aplicar resumen confirmado: nombre máximo tres líneas, presentación dos líneas
   con ellipsis. Sin anexo ni modificación de datos originales/otras vistas.
   Reservar nombre 49 pt y foto 100 pt (76 pt para variante de precios extremos),
   manteniendo presupuesto total; revalidar tercera línea y ellipsis mediante render.
4. Adaptar pruebas PDF existentes a `ceil(N / 4)` y asignación exacta por página.
   La regresión anterior de texto extenso completo queda sustituida por la decisión
   explícita de resumen solo en PDF; comprobar ellipsis sin errores/solapamientos,
   precios completos, fotos corruptas y ambos alcances/nombres.
5. Generar y renderizar 1/3/4/5/8/9 productos; verificar primera/última, márgenes,
   tamaño legible, fotos proporcionales, precio con oferta y últimas páginas sin
   rellenos. Ejecutar formato/análisis/pruebas pertinentes y registrar evidencia.
6. Construir y actualizar Android físico autorizado con `adb install -r`, confirmar
   éxito antes de abrir; no desinstalar ni sustituir datos. Si se necesita prueba
   nativa, comprobar antes APK `.integration`. Sin enviar a contactos. iOS separado.

No necesita aprobación adicional: usuario autorizó el cambio y resolvió el resumen.
El coordinador vincula criterios y registra tareas/QA reales, sin dar por ejecutadas
pruebas o instalaciones por existir este plan.
