# Plan — Medir antes de optimizar

Estado: plan en ejecución. Decode implementado, comparaciones profile a 60/120 Hz
y apertura SQLite ejecutadas; resultados y límites en `qa.md`. El plan describe
la secuencia, no acredita por sí solo los pasos pendientes.

## 1. Instrumentación y baseline — PERF-AC-01/02/03/04/06/08/09

Preparar un entrypoint de profiling bajo `integration_test/` y fixture determinista
de pruebas con 0, 20 y 100 productos. Esa ruta activa el applicationId aislado en
`android/app/build.gradle.kts`; comprobar `com.example.catalogo_legum_pro.integration`
en el APK profile antes de instalar. No usar catálogo, credenciales ni fotos privadas
de la app normal. No ejecutar emuladores ni instalar fixtures en el paquete normal.

Construir con `flutter build apk --profile --target=integration_test/catalog_performance_test.dart`,
verificar APK mediante AAPT y abrir el paquete aislado con DevTools. El entrypoint
debe permitir el recorrido instrumentado sin depender de `flutter test`: ese comando
usa debug en el SDK local y no acredita mediciones profile. Antes de automatizar
con otra herramienta, verificar su modo efectivo y conservar idéntico protocolo.

Archivos previstos: `integration_test/catalog_performance_test.dart`, fixture/helper
de rendimiento y evidencia bajo `artifacts/performance/` (ruta propuesta).

Usar `SchedulerBinding.addTimingsCallback` para series build/raster, retirar callback
al terminar; registrar muestras fuera de los tramos medidos y evitar I/O por frame.
Marcar inicio de acción y primer frame con el resultado correspondiente para búsqueda
y selección. Registrar apertura de proceso y momento de catálogo utilizable por
separado; no equiparar tiempo del comando de instalación con apertura de la app.

Fijar secuencia, calentamiento, reposo, orientación y frecuencia observada. Guardar
versión exacta del código y toolchain; baseline y versión optimizada usan misma
configuración profile e instrumentación. Ejecutar muestras y estadísticas del spec,
ImageCache, tamaño real decodificado y memoria de proceso diferenciados. Primera
pasada separada; sin inspección costosa de widgets simultánea a la corrida principal.
Si cambian térmicas/frecuencia, repetir tramos comparables o documentar limitación.
Mantener series independientes a 60 y 120 Hz: presupuestos 16,67 y 8,33 ms,
respectivamente, para build y raster. Respetar ajustes del usuario y ahorro de
energía; no modificar configuración global para forzar una corrida. Registrar
frecuencia observada al inicio/final y cambios detectables durante el tramo.
Una lectura o callback de frecuencia no es una medición exacta de cada vsync:
correlacionar con trazas y condiciones del sistema. No mezclar muestras de modos
distintos ni comparar baseline 60 Hz con optimizado 120 Hz. Si Android no habilita
120 Hz, dejar pendiente esa validación; no prometer FPS ni relajar criterios.
Añadir diez ciclos por ruta de catálogo↔detalle, catálogo↔selección y acceso al
panel; delimitar transición separada de carga y aplicar el agregado por ruta de
PERF-AC-09. Registrar patrón, preferencia de movimiento y frames build/raster.

## 2. Diagnóstico y decisión — PERF-AC-02/04/05/06

Correlacionar trazas con pausas y memoria; registrar hipótesis confirmadas y descartadas.
`ProductPhoto` actualmente no fija resolución de decode; getters del VM ordenan y
normalizan repetidamente y `CatalogView` escucha cambios del VM completo. Son puntos
de inspección, no causas demostradas. Si baseline cumple y una refactorización no
aporta beneficio medido, omitirla justificadamente; preservar evidencia.

## 3. Ajustes medidos, uno a la vez — PERF-AC-04/05/06/07

Archivos candidatos: `lib/ui/widgets.dart`, `lib/features/view_models.dart`,
`lib/features/public_views.dart`. Mantener MVVM/ChangeNotifier/sqflite y dependencias.

- Fotos: aplicar tamaño de decode calculado con bounds, DPR, fit y proporción.
  Conservar originales, fallback y detalle; comprobar reducción real de bytes.
  Preferir APIs existentes. No crear miniaturas persistentes, migraciones ni nuevo
  pipeline de medios sin evidencia y revisión explícita del alcance.
- VM: cachear orden/normalización/derivados solo si la medición lo justifica. Invalidar
  en notificación del repositorio, CRUD, reordenamiento, ocultamiento, categoría y
  reemplazo desde respaldo. Cambiar query/categoría invalida resultados; seleccionar
  invalida derivados de selección. Listas expuestas no permiten mutar cachés internas.
  Resolver selección, detalle y PDF desde snapshot vigente, nunca objetos obsoletos.
- Vista: acotar listeners/rebuilds y usar identidades estables cuando se demuestre
  beneficio; conservar búsqueda controlada, foco, navegación, scroll y texto ampliado.
  No añadir cachés/listeners sin dispose ni un gestor de estado nuevo.
- Transiciones: identificar trabajo durante cambios de ruta y tickers de contenido
  fuera de pantalla. Revisar `Offstage`/`TickerMode` del navegador administrativo
  preservando estado, borradores y bloqueo. Conservar patrón Material y preferencia
  de reducir movimiento; no ajustar duración para ocultar tirones. PERF-AC-09.

Repetir tramos afectados tras cada ajuste; revertir cambios sin mejora o con regresión.

## 4. Verificación comparativa — PERF-AC-01 a 09

QA ejecuta el protocolo de `qa.md`, regresiones de lógica/widgets, formato y análisis.
Incluye navegación rápida, atrás, apertura repetida y bloqueo durante transición.
La prueba host no acredita presupuesto de frames nativos. Archivar tabla antes/después,
series crudas, condiciones, fallos y pendientes. Correlacionar cada afirmación con evidencia.
La comparación incluye tablas separadas por frecuencia efectiva; los resultados
de 60 Hz no sustituyen evidencia a 120 Hz.
No ampliar esta etapa a optimización de PDF, respaldos o importación.

## 5. Entrega

Solo después de evidenciar resultados: build normal y actualización física mediante
`adb install -r`, inspeccionar éxito antes de iniciar; no desinstalar ni reemplazar datos.
La validación iOS queda pendiente de Mac/Xcode/dispositivo y no se acredita con Android.
Una meta incumplida permanece abierta; no cambiar umbrales para aparentar aprobación.

## Referencias oficiales

- [Perfil físico y modo profile](https://docs.flutter.dev/perf/ui-performance).
- [FrameTiming](https://api.flutter.dev/flutter/dart-ui/FrameTiming-class.html):
  build y raster son etapas distintas; debug puede producir métricas diferentes.
- [DevTools Performance](https://docs.flutter.dev/tools/devtools/performance).
