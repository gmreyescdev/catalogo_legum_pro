# Entorno físico — 2026-10-08

- Android físico 23049PCD8G, Android 15, 1080 × 2400, densidad 440 dpi.
- Flutter 3.47.6, Dart 3.13.5, engine b8c8d3d8d5d0095127057f8a29ca8cc53da2167c.
- Pantalla admite 60/90/120 Hz. Lectura inicial en reposo: 60 Hz.
- `peak_refresh_rate`: 120; `min_refresh_rate`: null; `low_power`: 0.
- Estado térmico inicial: 0. Verificar nuevamente durante y después del recorrido.
- Medición con APK profile aislado, datos sintéticos y app real de catálogo conservada.
- El campo `observedHzAtCallback` se lee al entregar el callback; es frecuencia
  observada en ese momento, no prueba de Hz exactos del frame histórico.
- El harness mide widgets/VM públicos, fotos locales y rutas MaterialPageRoute.
  Repositorio en memoria; no acredita bootstrap SQLite, autenticación ni arranque
  nativo. Primera generación de fixtures excluida de estadísticas de apertura.

Resultados, hashes de APK y condiciones de cada corrida se registran por separado.

Comparación principal: observado 120 Hz y thermal status 0. Serie separada de
60 Hz: preferencia de ventana aplicada exclusivamente al paquete `.integration`
mediante extra `PERF_DISPLAY_HZ`; dumpsys confirma modo activo 1 y 60,000004 Hz.
No se escribieron ajustes globales. El paquete normal ignora ese extra.
Bootstrap real SQLite medido por separado con app_startup_probe; marcador desde
Dart main hasta primer post-frame utilizable, no inicio nativo total del proceso.
