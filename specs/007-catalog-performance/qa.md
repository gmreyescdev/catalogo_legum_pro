# QA — SPEC-007: rendimiento del catálogo

Estado: mejora implementada y entregada en Android 0.6.0+7, con comparación
física a 60/120 Hz y QA complementaria ejecutadas; aceptación global pendiente
de movimiento reducido real del sistema e iOS. Resultados ejecutados al
final del documento. El protocolo siguiente no convierte pendientes en aprobados.

## Preparación y seguridad

1. Usar únicamente Android físico. Registrar modelo, versión Android, Flutter/Dart,
   revisión o huella de fuentes, SHA-256 de APK, resolución, densidad, orientación,
   frecuencia observada de pantalla y configuración de batería. Registrar estado
   térmico antes y después; descartar y repetir comparaciones con throttling o con
   cambios de frecuencia no controlados. Mantener iluminación, alimentación,
   aplicaciones concurrentes y herramientas de captura comparables.
2. Construir baseline y candidata en **modo profile**, con el mismo toolchain,
   opciones e instrumentación. Son revisiones distintas; no se exige el mismo APK.
   Guardar las dos identidades y usar orden baseline/candidata repetible.
3. Verificar en el APK el applicationId exacto
   `com.example.catalogo_legum_pro.integration` antes de cualquier instalación o
   ejecución nativa. La build profile de medición debe satisfacer esta condición,
   aunque un comando profile genérico pudiera producir el paquete normal.
   No ejecutar hasta disponer de esa verificación. Flutter test puede desinstalar
   su paquete; jamás apuntar al identificador del catálogo del usuario.
   En el SDK local, `flutter test integration_test/...` fuerza debug: sirve para
   comportamiento, no para las métricas de esta spec. La ruta propuesta es
   `flutter build apk --profile --target=integration_test/<target_de_medicion>.dart`,
   verificar package con AAPT, instalar exclusivamente el paquete aislado y
   capturar su ejecución profile. Target implementado en
   `integration_test/catalog_performance_test.dart`; ejecuciones concretas y
   métodos de extracción de resultados se registran abajo.
4. Generar datos sintéticos exclusivamente en el sandbox de integración. No copiar,
   consultar, exportar ni sustituir la base o las fotos privadas del usuario. No
   desinstalar, limpiar ni detener por error su aplicación normal. Cualquier
   actualización normal posterior usa `adb install -r`.
5. Conservar manifiesto de fixtures: versión, semilla, orden, IDs, hashes de fotos,
   dimensiones, bytes y valores esperados. Baseline y candidata usan ese mismo
   manifiesto, sin datos aleatorios nuevos entre mediciones.

## Fixtures reproducibles

- F0: catálogo vacío.
- F20: 5 categorías, 20 productos, 3 imágenes distintas por producto (60 imágenes),
  incluyendo fotos de 4000 × 3000 px. Fijar visibilidad, disponible/agotado,
  precios normales/oferta, nombre con acentos, SKU y presentación. Incluir ocultos
  en la base y anotar cuántas tarjetas públicas se esperan. Guardar resultados
  esperados de búsquedas, filtros y selección con precios actuales.
- F100: 5 categorías y 100 productos con la misma distribución y 3 imágenes
  distintas por producto; manifiesto independiente. Es estrés, sin extrapolar las
  metas numéricas de F20.

La implementación del fixture y las trazas de medición quedan pendientes. Antes
de obtener la línea base, fijar en su manifiesto la distribución exacta y la lista
ordenada de acciones; no comparar fixtures descritos solo por cantidad.

## Método de medición

Capturar trazas DevTools/Flutter de build y raster por frame, más eventos
correlacionados de entrada/estado visible cuando corresponda. No sustituir los
tiempos por la duración total de comandos ADB ni por la impresión del observador.
La instrumentación debe tener el mismo coste en baseline y candidata.

Para percentiles usar **nearest-rank**: ordenar N muestras y elegir la posición
`ceil(p × N)` (posiciones desde 1). Con 20 acciones, p95 es la muestra 19;
con 5 aperturas, la mediana es la muestra 3; con 10 detalles, la mediana es el
promedio de las posiciones 5 y 6. Guardar también todas las muestras crudas.

El presupuesto por frame es `B = 1000 / Hz` ms (60 Hz: 16,67 ms; 120 Hz: 8,33 ms).
Un frame queda fuera si `build > B` **o** `raster > B`. Contar una sola vez los
frames que incumplen ambas etapas. No sumar build y raster: trabajan en pipeline.
Usar como denominador los frames de la ventana activa capturada, e informar N y
duración. No inferir FPS a partir del promedio de una etapa. Si cambia Hz durante
el recorrido, registrar el cambio y repetir con condiciones comparables; no
aplicar un presupuesto fijo sin explicar esa variación.

## Casos y aceptación

| Caso | Criterios | Procedimiento y evidencia | Aceptación | Estado |
| --- | --- | --- | --- | --- |
| QA-P01 — Comparabilidad | AC-01, AC-08 | Completar ficha de entorno, hashes, manifest y applicationId; capturar baseline y candidata con iguales opciones. | Evidencia suficiente para reproducir; paquete de pruebas aislado; sin emulador ni acceso a datos reales. | Pendiente |
| QA-P02 — Scroll inicial | AC-02 | En F20, proceso recién iniciado y caché de imágenes de proceso inicialmente vacía: un recorrido de 30 s, desde inicio hasta final y regreso, con acciones fijadas. Guardar traza separada de calentamiento. | Primera pasada informada separadamente; no mezclarla con recorridos calentados ni exigirle su umbral. | Pendiente |
| QA-P03 — Scroll calentado | AC-02 | Tras la primera pasada, ejecutar 3 recorridos de 30 s con la misma secuencia y velocidad. Por recorrido: N, p50/p95/p99 de build y raster, número y porcentaje de frames fuera de B. | Cada recorrido de F20: p95 build ≤ B, p95 raster ≤ B y frames fuera ≤ 5%. No aprobar por promedio entre recorridos. | Pendiente |
| QA-P04 — Apertura | AC-03 | 5 inicios de proceso con F20, conservando datos. Medir primer frame y catálogo utilizable desde el mismo marcador de lanzamiento; documentar qué marcador se usa. Detener exclusivamente proceso de integración entre muestras, sin borrar datos. | Mediana y máximo de ambas métricas registrados; mediana hasta catálogo utilizable no empeora > 10% frente a baseline comparable. Investigar ruido antes de dictaminar un cruce. | Pendiente |
| QA-P05 — Detalle | AC-03, AC-05 | 10 pares apertura/regreso con productos y galería fijados. Medir toque→detalle utilizable y volver→catálogo utilizable por separado; fijar condición de caché. Verificar detalle de foto grande y aspecto. | Mediana/máximo por dirección; ninguna mediana empeora > 10%; originales y detalle legible preservados. | Pendiente |
| QA-P06 — Búsqueda | AC-04 | 20 eventos de búsqueda de lista fija, incluyendo acentos, vacío, sin coincidencias y categoría activa. Medir entrada→frame con resultado correcto; registrar cantidad/IDs esperados. | p95 ≤ 100 ms, búsqueda normalizada AND categoría; sin resultado obsoleto tras entradas rápidas. | Pendiente |
| QA-P07 — Selección | AC-04 | 20 cambios fijos seleccionar/deseleccionar. Medir entrada→frame con estado y contador actualizados. Incluir búsqueda/categoría activa y navegación a selección. | p95 ≤ 100 ms; selección, disponibilidad y precios vigentes correctos; ocultos no expuestos. | Pendiente |
| QA-P08 — Imágenes | AC-05 | En idénticos layout y densidad, registrar tamaño visible, tamaño de imagen decodificada y bytes por tarjeta antes/después. Registrar ImageCache y memoria de proceso por separado. Revisar fotos vertical/horizontal y fallback. | Reducción demostrable de bytes decodificados en tarjetas grandes, aspecto/recorte vigentes y detalle legible, sin modificar originales. | Pendiente |
| QA-P09 — Retención | AC-06 | En F20, cinco ciclos idénticos de recorrido y detalle, volver al mismo punto, esperar el mismo reposo fijado antes de baseline y capturar memoria/caché/listeners. Guardar serie temporal y acciones. | Sin crecimiento sostenido no explicado de imágenes/listeners; no aumentar caché para ocultarlo. Si hay crecimiento, investigar y dejar defecto abierto hasta explicar/corregir. | Pendiente |
| QA-P10 — Estrés | AC-06 | Repetir desplazamiento y detalle con F100; registrar build/raster, memoria de proceso, ImageCache, errores y cierres. | Sin cierre inesperado ni errores de recursos. Métricas informadas; no exigir metas F20. | Pendiente |
| QA-P11 — Regresión | AC-07 | Formato, análisis y pruebas pertinentes; F0 y F20, navegación, filtros, selección, fotos, temas, texto ampliado, controles accesibles y administración protegida. Verificar ambos alcances y nombres PDF mediante dobles de prueba o selector nativo sin destinatario. | Conductas existentes preservadas; nombres `LegumPro_Catalogo.pdf` y `LegumPro_Catalogo_Personalizado.pdf`; nunca enviar a contactos. | Pendiente |
| QA-P12 — Transiciones | AC-09 | En F20 calentado, 10 ciclos por ruta de ida/vuelta: detalle, selección y acceso al panel. Capturar ventanas de animación por dirección, separadas del tiempo de carga/contenido listo. Conservar trazas y número de frames por ventana; agregar por ruta/dirección. | En cada agregado: p95 build y raster ≤ B y frames fuera ≤ 5%. Inspección de continuidad visual sin saltos, parpadeos ni pantallas intermedias indebidas. | Pendiente |
| QA-P13 — Movimiento y navegación | AC-07, AC-09 | Repetir rutas con movimiento reducido/desactivación de animaciones del sistema y verificar la preferencia expuesta a Flutter; volver rápidamente durante la transición y repetir sin apilar rutas accidentalmente. Bloquear sesión al suspender la app y regresar hacia el panel durante navegación. | Respetar movimiento reducido, sin animaciones decorativas obligatorias; Back y estado de selección correctos; panel protegido durante y después de la transición, sin exposición de contenido administrativo con sesión bloqueada. | Pendiente |

## Registro y dictamen

Guardar un informe por variante con: ficha del entorno, revisión/APK, manifiesto,
acciones, muestras crudas, trazas y tabla baseline/candidata/diferencia porcentual.
Anotar tiempo de reposo, condiciones de caché y marcador temporal exactos **antes**
de ambas ejecuciones. No llamar «arranque frío del dispositivo» a reiniciar solo
el proceso; la caché del sistema operativo puede persistir.

Para memoria documentar unidad y fuente (por ejemplo, ImageCache en bytes y memoria
del proceso/PSS por herramienta nativa), y separar objetos activos, retenidos y
caché cuando la herramienta lo permita. No exigir liberación inmediata del SO.
Si el indicador de memoria aumenta, usar la serie y la retención de objetos para
investigar; una cifra aislada no demuestra fuga.

Las regresiones de presentación pueden cubrirse en ambos temas y texto ampliado;
la comparación principal de tiempos usa una configuración fija. Las pruebas de
widgets o lógica no acreditan rendimiento del teléfono. No se repite una medición
para seleccionar solo resultados favorables: conservar fallos, razón de descarte
y repeticiones cuando exista ruido, cambios térmicos o errores de captura.

Estado inicial del protocolo: baseline, optimización, candidata, comparación,
verificación nativa y actualización estaban pendientes; consultar resultados
posteriores para el estado vigente. iOS queda pendiente de Xcode/dispositivo;
los resultados Android no lo acreditan. Si una meta falla, registrar defecto y
evidencia; no rebajar umbrales ni declarar completada la implementación.

## Puntos a resolver antes de ejecutar

- Interpretar «misma build profile» como mismo modo y opciones entre revisiones,
  no binario idéntico; conservar hashes diferentes explícitos.
- Fijar manifiesto exacto, secuencia de gestos, marcador de apertura y reposo.
- Confirmar que la herramienta elegida expone el frame correspondiente al estado
  visible para latencia de búsqueda/selección; el fin del método de ViewModel por
  sí solo no cumple la medición hasta frame.
- Asegurar que el target profile obtiene el applicationId aislado; no asumirlo
  por usar `--profile`.
- Para transiciones, fijar marcadores de comienzo/fin de animación y anotar duración
  configurada, ruta y dirección. No incluir frames de esperas posteriores a la
  animación para diluir el porcentaje fuera de presupuesto; una ruta sin animación
  por movimiento reducido no genera un percentil comparable y se valida como tal.

## Primera ejecución y baseline de imágenes — 2026-10-08

- Harness profile compilado e instalado con applicationId .integration verificado por AAPT; ninguna instalación de prueba usó el paquete normal. Primera preparación generó fixture F20 persistente, pero no produjo un JSON final recuperado. La desconexión del dispositivo interrumpió la recogida; no se acredita baseline de frames con ese intento.
- Prueba host `flutter test tool/image_decode_baseline_test.dart --reporter expanded`: EXIT0, 1 passed, antes de modificar lib. ProductPhoto real con PNG 4000×3000 y tarjeta 352×264 dp/DPR 3: RenderImage 4000×3000, RGBA 48,000,000 bytes, ImageCache 48,000,000 bytes/1 entrada. Es evidencia de tamaño decodificado, no de fluidez nativa.
- Instrumentación ajustada para establecer superficie mediante una pantalla de preparación antes de rasterizar fixtures; misma instrumentación para baseline/candidata. Frecuencia del callback se identifica como observada al recibir lote, no Hz exactos de cada frame.

## Verificación independiente de fotos en el host — 2026-10-08

Comando ejecutado: `flutter test test/ui/product_photo_performance_test.dart --reporter expanded`.
Resultado: EXIT 0, **6 pruebas aprobadas**. Archivo formateado con Dart.

- PNG sintético real 4000×3000: proveedor original decodifica 4000×3000;
  con bounds físicos 1056×792, candidata decodifica 1056×792. RGBA pasa de
  48,000,000 a 3,345,408 bytes (**93,03% menos**). No son métricas de frame.
- Fotos vertical 1200×1600 y panorámica 2400×600 conservan proporción en
  `cover`/`contain`; cover cubre el rectángulo y contain cabe dentro.
- Original 80×60 no se amplía durante decode, incluso con bounds mayores.
- Dos solicitudes equivalentes reutilizan ImageCache sin añadir otra entrada;
  la solicitud de detalle obtiene 900×675, separada de tarjeta 300×225.
- ProductPhoto real usa bounds y DPR 3: ancho 100 dp produce 300×225 píxeles;
  cambiar a detalle 300 dp produce 900×675. AspectRatio, cover/contain se mantienen.
- Imagen inválida conserva alternativa visible y accesible «Imagen no disponible»;
  la prueba no registra una excepción de widgets sin manejar.

Estas pruebas validan dimensión/calidad de decode, identidad de caché y fallback
en host. No acreditan Android/iOS nativo, 120 Hz, presupuesto de frames,
transiciones ni ausencia de fugas después de recorridos completos.

## Movimiento reducido y regreso rápido en host — 2026-10-08

Comando ejecutado: `flutter test test/ui/catalog_transition_test.dart --reporter expanded`.
Resultado final: EXIT 0, **2 pruebas aprobadas**, sin cambios en las rutas de la app.

- Con ThemeData real de LegumPro y MaterialPageRoute, la transición normal aún
  está avanzando a los 40 ms. Un regreso durante esa transición retorna al
  catálogo sin ruta sobrante ni excepción de widgets.
- La preferencia de accesibilidad del sistema `disableAnimations: true` se
  propaga a MediaQuery. Push y pop Material terminan antes de los 40 ms probados;
  no se confirmó un defecto que requiera cambiar el comportamiento estándar.
- El primer intento falló por consultar el detalle con un finder que omitía la
  ruta todavía offstage; el test se corrigió para consultar también offstage.
  Fue un error del test, no un fallo observado en la navegación de la app.

Es cobertura de widgets con preferencia del sistema simulada. No acredita
transiciones a 120 Hz, gesto nativo de volver ni bloqueo administrativo durante
navegación en Android físico. Estas pruebas por sí solas no acreditan esa ejecución.

## Comparación física a 120 Hz — 2026-10-08

Android 23049PCD8G, Android 15, 1080×2400, DPR 2,75; Flutter 3.47.6,
Dart 3.13.5. Ambos APK profile usan `.integration`, verificado con AAPT antes
de instalar con `adb install -r`. Fixtures sintéticos F20/F100 persistentes,
manifestos en `artifacts/performance/native/`; no se consultó ni reemplazó
el catálogo normal. Callbacks observaron 120,0000076 Hz; dumpsys confirmó modo
activo de 120 Hz y estado térmico 0 durante las ventanas. No acredita FPS
presentados ni VSYNC exacto de cada frame.

Baseline SHA-256:
`F0899D38F94AC2D8E396FF08113FF1AD5026C82B43ACF55F790530D6D87F8DF9`.
Candidata SHA-256:
`6EED645DD31B3179CA5F51EC619663B8EC77E724C340B5D22F9F1C56E433B0A5`.
Cambió ProductPhoto y su proveedor de decode; rutas y duraciones Material
permanecieron iguales. Fuentes previas/posteriores conservadas junto a los APK.

`baseline-raw.json`: 20.854 frames; `candidate-raw.json`: 20.773.
Se recuperaron campos de la instrumentación mediante lectura del VM service
después de las ventanas medidas, porque scoped storage negó lectura externa
por ADB. Percentiles nearest-rank y conteos OR calculados con
`tool/performance_summary.py --hz 120`. QA independiente recalculó todas las
ventanas, cuatro agregados de rutas y resultados de búsqueda/selección: coincidencia
total, sin timestamps duplicados ni solapamiento.

| Medida | Baseline | Candidata |
| --- | ---: | ---: |
| Detalle push: raster p95 | 8,042 ms | 6,958 ms |
| Detalle push: frames fuera de 8,33 ms | 5,660% | 2,439% |
| Selección push: raster p95 | 9,182 ms | 7,519 ms |
| Selección push: frames fuera de 8,33 ms | 15,547% | 2,597% |
| Búsqueda: post-frame p95, 20 eventos | 15,635 ms | 9,901 ms |
| Selección: post-frame p95, 20 eventos | 9,762 ms | 12,670 ms |
| Foto tarjeta: decode RGBA | 48.000.000 bytes | 2.952.192 bytes |
| ImageCache tras cinco ciclos | 102.290.064 bytes | 91.289.624 bytes |

Tres recorridos calentados de 30 segundos cumplen ambos umbrales en ambas
versiones. Candidata: p95 build 1,402–1,445 ms, raster 2,659–2,677 ms y
frames fuera 0,307–0,392%; no se afirma mejora de todos los tiempos de scroll.
Las cuatro direcciones de detalle/selección candidatas cumplen p95 y ≤5%.
Las 20 búsquedas y 20 selecciones devuelven IDs esperados y p95 <100 ms.
Selección aumentó en latencia, aunque permanece dentro de la meta.

Foto 4000×3000 decodificada a 992×744 para tamaño/DPR real: 93,85% menos
bytes de esa imagen, no de la memoria total. Cinco puntos de reposo mantienen
ImageCache constante, 30 entradas/live 2/pending 0. RSS candidata 262,7–264,1 MB
frente a 288,1–290,0 MB baseline en esos ciclos. La muestra posterior a F100
no mejoró en todas las condiciones: no se afirma reducción universal de RSS.
No se aumentaron límites globales de caché.

La preparación inicial de F100 baseline tuvo una salida temporal al fondo,
posterior a las ventanas F20. Se restauró foreground antes del stress. La candidata
reutilizó el fixture; no se compara preparación fría/caliente como arranque.
Stress original recorre un subconjunto y último detalle, no el catálogo completo.
Los resultados originales se conservan.

## Apertura con bootstrap real y SQLite — 2026-10-08

Target profile `integration_test/app_startup_probe.dart`, APK aislado verificado.
Guard de ruta `.integration` antes de sembrar; SQLite real, media manager, auth
protegida, limpiezas y CatalogApp de producción. F20 sintético, PIN de pruebas
independiente. Primera preparación de 5.231 ms excluida y conservada; no se
borraron datos entre cinco aperturas de proceso por variante. Resultados en
`startup-baseline.json` y `startup-candidate.json`, capturados desde logs del PID
de pruebas por `tool/collect_startup_samples.py`.

Baseline: 556,267 / 441,724 / 424,075 / 405,215 / 402,870 ms; mediana
424,075 ms, máximo 556,267 ms. Candidata: 575,223 / 434,484 / 420,944 /
427,939 / 448,097 ms; mediana 434,484 ms, máximo 575,223 ms. Mediana +2,45%,
dentro de ≤10%. Bootstrap real: medianas 307,476 y 302,041 ms.
Marcador: Dart main → primer post-frame del catálogo con controles/datos listos;
imágenes pueden continuar cargando. Excluye inicio nativo del motor/proceso.

SHA-256 startup baseline:
`4F698DA38BA1837F84DBF35FFF864EB005744EF2F680FED8C2BE24B887E92930`.
SHA-256 startup candidata:
`63102CC01B3E8F9447114490AD47C878717542B3159ED3C23CC9AA2C3C826155`.

## Comprobaciones generales ejecutadas

`flutter test --reporter expanded`: EXIT 0, 88 pruebas aprobadas. Incluye
auth, filtros, selección, nombres/alcances PDF y UI existentes. `flutter analyze`:
EXIT 0, sin incidencias; formato Dart de 35 archivos. Después de añadir exportación
privada de benchmarks se repitió análisis sin incidencias y formato (un archivo
ajustado). Compilaciones profile/release son evidencia de compilación Android;
iOS permanece pendiente de macOS/Xcode.

Primer baseline60 completado: 10.792 frames, observado 60 Hz. La primera
instalación candidata60 falló por desconexión USB; no se presenta como ejecución.
La validación de metadatos inicial también tuvo un error del script PowerShell
al comparar un array de líneas; fue corregida usando una cadena y no instaló un
paquete incorrecto. Los resultados válidos posteriores son los que se comparan.

## Series separadas a 60 Hz

Modo activo 1/render 60,000004 Hz durante los recorridos; thermal status 0.
Baseline conservó 120 Hz cacheados en la lectura Flutter del callback; la primera
captura dumpsys (0,4 s, antes de medir) también mostraba 120 Hz, y las posteriores
(33–194 s) confirmaron 60 Hz. Sus recorridos presentan aproximadamente 1.831 frames
por 30 segundos. No se usa esa lectura cacheada como frecuencia exacta del frame.
Candidata observó 60 Hz en callbacks y dumpsys (0,4–192 s).
Preferencia de ventana únicamente de `.integration`; el paquete normal ignora
el extra y no se tocaron ajustes globales de frecuencia/batería. Misma
instrumentación y flags dentro de la serie; exportación privada después de
las ventanas medidas, obtenida con run-as. Raw baseline 10.792 frames,
candidata 10.800, en `baseline60-raw.json` y `candidate60-raw.json`.

| Medida | Baseline | Candidata |
| --- | ---: | ---: |
| Detalle push: raster p95 | 7,311 ms | 6,270 ms |
| Detalle push: fuera de 16,67 ms | 3,191% | 3,214% |
| Selección push: raster p95 | 8,231 ms | 6,689 ms |
| Selección push: fuera de 16,67 ms | 2,500% | 2,491% |
| Búsqueda: post-frame p95 | 22,734 ms | 25,894 ms |
| Selección: post-frame p95 | 19,125 ms | 21,173 ms |

Ambas versiones cumplen tres recorridos calentados y cuatro direcciones de
rutas, con presupuestos build/raster separados. Todas las entradas p95 <100 ms.
No se afirma mejora de todas las latencias. Fotos candidatas mantienen
992×744/2.952.192 bytes frente a 4000×3000/48.000.000 bytes baseline.
Hashes: baseline60
`FDA360E16EA44803EE1DC7034E00DB217B8536B7ECA0B0D4F03CF8039F07FEA5`;
candidata60
`EA90B202DFB885D959222D13012005CB3262AF4492C99D4ED5ED5973DAD8F692`.

## Intento complementario de regresión conservado

`regression-baseline-initial-failed.json`: recorrido claro de 90/90 productos
públicos y diez ciclos detalle/admin sin errores Flutter. El segundo recorrido
con texto 1,6 no desplazó el catálogo observado; faltaron 89 productos y el
harness registró failure. No se declara aprobado. La primera corrección restringió
el selector al scroll vertical visible del catálogo, pero tampoco completó ese
recorrido (`regression-baseline-selector-failed.json`). Se añadió espera tras
theme/MediaQuery, consulta de la ScrollPosition vigente y saltos por pasos para
esta comprobación de recursos. No altera el benchmark animado ni la app.

QA independiente verificó ambas series a 60 Hz: percentiles/conteos coinciden;
20 búsquedas y 20 selecciones por variante devuelven IDs correctos; los siete
muestreos térmicos de cada variante son 0. La primera lectura QA de JSON por Python
sin encoding explícito usó ANSI y señaló un falso defecto de acentos. La relectura
de bytes con UTF-8 confirmó que originales y consultas acentuadas eran correctos;
se retiró ese defecto de lectura, sin modificar la app ni los artefactos.

## Regresión completa F100 y variación de latencia

Probe corregido ejecutado con los mismos APK profile entre variantes. Ambas
versiones visitan 90/90 productos visibles de F100 en claro y oscuro/texto 1,6,
sin missing ni errores Flutter/recursos. Cada variante verifica veinte ciclos
administrativos: acceso bloqueado, desbloqueo sintético, bloqueo y salida; panel
protegido tras lock y entrada/salida inmediata. IndexedStack no anima: presupuesto
animado N/A, se registra tiempo conjunto de respuesta. Tres regresos rápidos de
detalle por condición sin errores. No se usan PIN ni credenciales del usuario.

Primera pareja conservada en `regression-*-run1.json`: primer post-frame de detalle
normal mediana 18,864→20,881 ms (+10,69%), máximo 35,969→24,853 ms; variante
MediaQuery con movimiento reducido 20,668→23,697 ms (+14,65%). Se investigó la
variación repitiendo la pareja sin cambiar código, umbrales ni APK; no se descartó
la primera para escoger el resultado favorable. Segunda pareja `regression-*-run2.json`:
normal 20,652→19,486 ms (−5,65%); MediaQuery 20,802→18,184 ms (−12,59%).
La dirección del cambio no se mantuvo; estas mediciones F100 no acreditan la
meta F20 de AC-03. Se prepara una serie específica F20 con los mismos marcadores.

Retorno `returnPostFrameMs` incluye esperar la transición y el siguiente frame
del catálogo plenamente expuesto (~430 ms), no solo lectura de datos. La variante
MediaQuery registra `disableAnimations: true` pero no cambia el ajuste Android;
AnimationController todavía consulta la accesibilidad del sistema. Es cobertura
de preferencia/layout, no evidencia de reducción nativa de duración. La prueba
host con accesibilidad real simulada sí valida finalización antes de 40 ms.

RSS/caché del stress son métricas de recursos, sin umbral F20: caché baseline
96.000.000 bytes frente a candidata 103.326.720 bytes al recorrer todas las
portadas. La candidata retiene más imágenes pequeñas; no demuestra menor caché
total en este recorrido. No aumentó su límite global ni tuvo cierre/errores.

Hashes APK regression baseline:
`837CF3CE1C260AC8FCDC4E4C56FBAE54D5CB22AF7BD4E614DF0CB480D60A6465`;
candidata:
`FB3E66D3CD1408C85674B30C510B18390291F6E52463A9C6BA19282A3C490280`.

## Actualización normal y comprobación física

APK release normal 0.6.0+7, 23,1 MB, package `com.example.catalogo_legum_pro`
verificado con AAPT, hash
`D6EB31A30AA4EBC51A9B3830FFC95554726ED9278C7E386440698C635F1BF90D`.
`adb install -r`: Success; dumpsys confirma versionName 0.6.0/versionCode 7.
No desinstalación, limpieza ni reemplazo de datos. Apertura nativa Status ok;
captura propia confirma catálogo existente y foto ajustada a la tarjeta. El
detalle mantiene imagen completa. Toque real de «Ver detalle» y BACK Android
regresa al catálogo; «Administrar» muestra acceso bloqueado y BACK cancela.
No se introdujo PIN ni se modificaron productos, selección, ajustes o respaldos.
Capturas en `artifacts/performance/release-*-screen.png`.

El `am start -W` registró 366 ms hasta Activity, distinto del marcador utilizable
de los probes: no se combina con la mediana de bootstrap ni se declara mejora.
La comprobación inicial cubrió BACK; el gesto de borde se verificó posteriormente
(ver abajo). Ajuste real Android de movimiento reducido e iOS requieren validación
propia. Aceptación global se mantiene separada de la
actualización Android entregada.

## Detalle del caso principal F20 y repeticiones conservadas

Target profile `detail_latency_probe.dart`, fixture F20 con 18 productos públicos,
dos variantes de código y marcadores idénticos. Primera pareja: diez aperturas
normales, mediana 16,2615→18,0785 ms (+11,17%), máximo 23,957→23,805 ms.
Supera inicialmente el margen del 10%; se registra la alerta y se investiga sin
cambiar código, APK, umbral ni excluir muestras. Segunda pareja: mediana
16,5945→17,342 ms (+4,50%), máximo 21,816→25,401 ms.

Los dos recorridos permanecen en `regression-*-20-run1.json` (nombres reales:
`regression-baseline20-run1.json`, `regression-candidate20-run1.json`) y sus
equivalentes run2. `detail-f20-repetitions.json` conserva las listas de muestras
por corrida; el resumen incluye todas, no escoge el recorrido favorable.
Veinte aperturas por variante: mediana 16,3945→17,5245 ms (+6,89%), máximo
23,957→25,401 ms. Veinte regresos hasta catálogo plenamente expuesto: mediana
430,2875→433,491 ms (+0,74%), máximo 442,647→450,726 ms.

La comparación ampliada cumple el margen de mediana, conservando la alerta
original. No se afirma que el primer frame de detalle sea más rápido ni una
causa precisa de la variación; diferencias absolutas son del orden de 1–2 ms.
QA independiente recalculó ambas parejas y el conjunto de 20 muestras: coincidencia
total. Variante MediaQuery simulada se registra aparte; no sustituye ajuste SO.
Ambas parejas visitaron 18/18 visibles en claro y oscuro/texto 1,6, veinte ciclos
admin por variante y cero errores. Marcador hasta post-frame Flutter, no raster
ni presentación física. Entorno 120 Hz observado, thermal status 0.

Hashes F20 baseline:
`B98A3AC21135F820EDDF0012F247C3B241DCC2C92DB924D3BC02C698D3428D1D`;
candidata:
`BA123DAA41717F4FF5C89593BD8CF3EBFECA68EAB9288F69A067AB92B0AE04CB`.

## Gesto Android y cierre de la entrega

Versión release instalada: toque de detalle seguido de swipe desde borde izquierdo
retorna al catálogo sin cambiar selección/datos; capturas `release-gesture-*-screen.png`.
`navigation_mode` leído: 2; `animator_duration_scale`: 1.0. Solo lecturas, sin
modificar los ajustes globales. Esta prueba usa eventos de toque nativos inyectados
con ADB en el Android físico; no un gesto humano ni un test de widgets.
Formato final: 37 archivos, cero cambios pendientes; análisis final EXIT 0 sin
incidencias. Las 88 pruebas host aprobadas se mantienen como evidencia ejecutada.
Pendiente: ajuste de movimiento reducido real en Android, y compilación/pruebas iOS.

Después de archivar todas las series y manifiestos, se retiró únicamente el
paquete temporal `.integration` (ADB Success) para evitar un segundo icono con
catálogo sintético. La app normal conserva versionCode 7/versionName 0.6.0 y
quedó abierta con Status ok; no se desinstaló el paquete del usuario.
