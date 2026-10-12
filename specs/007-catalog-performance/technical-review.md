# Revisión técnica — SPEC-007

Estado: revisión estática para planificar. No se modificó la aplicación, no se
instalaron APK ni se ejecutaron benchmarks. Las observaciones de código siguientes
son hechos inspeccionados; su impacto en tiempo y memoria sigue siendo hipótesis.

## Imágenes: oportunidad y restricciones

`ProductPhoto` (`lib/ui/widgets.dart`) solicita directamente el proveedor de
`LocalMediaManager.imageProvider`, un `FileImage` sin tamaño de decodificación.
El contenedor usa relación 4:3; tarjetas usan `BoxFit.cover` y detalle `contain`.
La UI no solicita actualmente una resolución reducida. Esto justifica medir
imágenes grandes, sin concluir todavía que causen los tirones observados.

Para una optimización posterior:

- Obtener ancho y alto finales del área de foto mediante sus constraints reales,
  después de márgenes, límite de contenido y columnas; multiplicarlos por el DPR
  de la vista y redondear hacia arriba. Validar dimensiones finitas y positivas.
  El ancho de pantalla completo no equivale al ancho de una tarjeta.
- Con imagen intrínseca `Iw × Ih` y área física `Tw × Th`, `contain` necesita escala
  `min(1, Tw/Iw, Th/Ih)`; `cover`, `min(1, max(Tw/Iw, Th/Ih))`. Redondear las
  dimensiones manteniendo proporción y sin superar la imagen original. La imagen
  pequeña puede ampliarse al pintar, sin fabricar una decodificación mayor.
- `ResizeImagePolicy.exact` con ambos tamaños impuestos puede deformar una fuente
  de otra proporción. `ResizeImagePolicy.fit` conserva proporción y sirve para
  contain; aplicado directamente al rectángulo visible de cover puede quedarse
  corto en uno de los ejes y luego ampliarse al pintar. Debe resolverse esta
  diferencia antes de seleccionar API. Para cover, evaluar metadatos intrínsecos
  y un tamaño proporcional, o un proveedor que calcule target al decodificar.
- No decodificar primero una imagen completa solo para consultar sus dimensiones.
  Evaluar descriptor de imagen codificada, ciclo de vida y coste de lectura antes
  de añadir otra caché. No migrar esquema ni crear miniaturas persistentes por
  defecto. Mantener los originales para detalle, exportación y respaldo.
- Las claves de ResizeImage incluyen dimensiones; cambios de orientación o ancho
  pueden retener varias variantes. Medir y limitar el trabajo necesario, sin
  inflar ImageCache. No evacuar agresivamente una imagen mientras otra ruta la usa.
- Verificar fuentes verticales, panorámicas, pequeñas, ausentes y corruptas,
  además de 4000 × 3000. Preservar recorte, labels y fallback accesible actuales.

Como referencia teórica, 4000 × 3000 × 4 son unos 45,8 MiB de píxeles RGBA por
imagen, antes de otros costes. No es una medición de esta app ni del proceso.
`ImageCache.currentSizeBytes` tampoco representa toda la memoria: imágenes live,
trabajo de decodificación, engine, GPU y recursos nativos se registran por separado.

## Reconstrucciones y datos derivados

`CatalogViewModel` filtra/ordena nuevamente en getters `publicProducts`, `products`,
`categories` y `selected`; normaliza nombre, descripción y SKU al buscar.
`CatalogView` escucha al VM completo, lee varios getters por reconstrucción y
vuelve a generar la estructura tras selección, búsqueda o busy. La lista principal
ya utiliza `ListView.builder`; no atribuirle construcción inmediata de todo el
catálogo. `SelectionView` sí construye su colección de hijos de forma anticipada.

Si las trazas lo justifican, evaluar derivados calculados por snapshot y filtros,
reutilizar lecturas dentro de una construcción y limitar reconstrucciones de
selección/contadores. Mantener MVVM y ChangeNotifier. Invalidar al cambiar snapshot,
orden, imágenes, visibilidad, precios, texto o categorías; no cachear productos
obsoletos al compartir PDF. No introducir debounce ni índices mutables complejos
sin necesidad demostrada. `ListenableBuilder.child` solo ayuda para subárboles que
realmente no dependen del estado cambiante; un widget pequeño por sí solo no
garantiza menos reconstrucciones.

## Apertura y trabajo asíncrono

`createAppServices` espera almacenamiento protegido, carga SQLite y limpiezas de
medios/respaldos/PDF antes de entregar servicios. Medir spans separados para
determinar qué precede al catálogo utilizable. Una espera de I/O no implica un
bloqueo síncrono del hilo UI. Diferir limpieza puede introducir carreras con
borradores, restauración y referencias actuales; no cambiar su orden por intuición.

`normalizedPng` usa APIs asíncronas de dart:ui y libera buffer, descriptor, codec
e imagen en finally. No equivale a procesamiento ejecutado automáticamente en un
isolate Dart, pero tampoco demuestra bloqueo. No mover dart:ui o plugins de forma
ingenua a `compute`; aislar únicamente CPU Dart transferible si una medición lo
requiere. PDF, importación y respaldos conservan comportamiento en esta etapa.

## Transiciones — PERF-AC-09

Detalle y selección usan `MaterialPageRoute`. Administración tiene Navigator
anidado; Offstage y TickerMode mantienen rutas/borradores mientras la sesión está
bloqueada. Preservar esa protección y no desmontar formularios como optimización.
La entrada a administración usa cambio de índice de IndexedStack: distinguir
un cambio de sección sin transición actual de un push/pop animado, sin añadir
animaciones nuevas para simular mejora.

Medir push y pop por ruta, separados de reposo y scroll. Hipótesis a contrastar:
decodificación de una foto durante el push, reconstrucción del catálogo retenido
bajo la ruta y coste de layout en el primer frame de destino. Registrar primera
visita frente a visita calentada; evaluar UI y raster por separado durante toda
la ventana de transición. No precargar toda la galería ni cambiar duraciones para
ocultar frames lentos. Conservar navegación atrás, foco, semántica y preferencia
de reducir/desactivar animaciones; cualquier animación personalizada futura debe
consultar esa preferencia. Probar navegación rápida y bloqueo sin doble acción ni
exposición de contenido administrativo.

## Instrumentación física aislada

`android/app/build.gradle.kts` selecciona `.integration` si el Gradle property
`target`, normalizado a `/`, contiene `integration_test/`. Un nuevo harness debe
vivir bajo esa carpeta; un target en `tool/` no activa el aislamiento actual.
Verificar `applicationId` del APK con AAPT antes de instalar, incluso en profile.
Los fixtures no deben llamar al bootstrap del catálogo del usuario ni copiar sus
archivos; generar datos reproducibles dentro del sandbox `.integration`.

En el SDK Flutter local inspeccionado,
`packages/flutter_tools/lib/src/commands/test.dart:433` llama a
`getBuildInfo(forcedBuildMode: BuildMode.debug)`. Por tanto, las ejecuciones
habituales `flutter test integration_test/...` son regresiones funcionales y no
acreditan métricas profile. No asumir que añadir `--profile` convierte ese runner.

Ruta propuesta para validar en implementación: construir el harness explícitamente
con `flutter build apk --profile --target=integration_test/<harness>.dart`, revisar
paquete y modo efectivo (`kProfileMode` como guard de instrumentación), instalar
exclusivamente ese APK y recoger trazas/FrameTiming con DevTools o instrumentación.
Otra opción es `flutter drive --profile`, una vez validado su flujo de build,
recogida y aislamiento. Estos comandos son una propuesta, no ejecuciones realizadas.

Para comparar baseline y cambio se mantienen modo, flags, backend, fixture y
secuencia; las revisiones de código/APK sí difieren y deben identificarse. Evitar
trazas de rebuild muy detalladas durante la pasada usada para aceptación, porque
añaden coste; usarlas en pasadas diagnósticas separadas. La captura FrameTiming no
representa por sí sola tiempo desde input a resultado ni arranque de proceso:
esos escenarios necesitan marcas explícitas y límites definidos. Guardar muestras
crudas y no sumar build+raster de etapas que funcionan en pipeline.

## Fuentes y límites

- [ResizeImage](https://api.flutter.dev/flutter/painting/ResizeImage-class.html).
- [ResizeImagePolicy](https://api.flutter.dev/flutter/painting/ResizeImagePolicy.html).
- [Profiling físico en Flutter](https://docs.flutter.dev/perf/ui-performance).
- Implementaciones inspeccionadas del SDK local: `painting/image_provider.dart`
  y `flutter_tools/lib/src/commands/test.dart`.

Pendientes: baseline, elección de política exacta de decode, implementación y
comparación física. No se acredita ningún criterio de rendimiento con esta revisión.
iOS requiere su propio entorno Xcode y dispositivo; Android no lo valida.
