# SPEC-007 — Rendimiento del catálogo

Estado: implementación entregada en Android 0.6.0+7; aceptación global pendiente
de movimiento reducido real del sistema y validación iOS. Resultados en `qa.md`.

## Objetivo

Mejorar la fluidez de LegumPro conservando Flutter, MVVM, sqflite y la experiencia
actual. El usuario autorizó su implementación. La medición compara baseline y
candidato antes de aceptar ajustes; cada mejora declarada debe tener evidencia.

## Alcance

Apertura hasta catálogo utilizable, desplazamiento de tarjetas, apertura y regreso
del detalle, búsqueda combinada con categorías, selección de productos y transiciones
entre catálogo, detalle, selección y acceso al panel administrativo. Prioridad
inicial: resolución de imágenes decodificadas y trabajo repetido en las vistas.
Se mide memoria asociada al recorrido. Solo se optimizan cuellos de botella
respaldados por mediciones. PDF, respaldos e importación conservan su comportamiento;
su optimización interna queda fuera de esta primera etapa.

No rediseñar pantallas, cambiar de gestor de estado, migrar la base, reducir la
calidad de los originales ni introducir precarga ilimitada. No añadir dependencias
sin justificar su necesidad. No cambiar PIN, seguridad, contenido ni iconos.

## Escenarios y datos

- Catálogo vacío: apertura y estados deshabilitados intactos.
- Caso principal: fixture reproducible de 5 categorías y 20 productos, 3 imágenes
  distintas por producto, incluyendo fotos de 4000 × 3000 px; disponibles, agotados,
  ocultos y ofertas. Fixture exclusivo de pruebas, nunca reemplaza el catálogo real.
- Comprobación de crecimiento: 100 productos con la misma distribución, escenario
  de estrés técnico, sin ampliar funciones ni prometer soporte ilimitado.
- Temas claro/oscuro y texto ampliado: regresiones de presentación y accesibilidad.

## Criterios de aceptación

Ampliación solicitada durante implementación: uso fluido en pantallas compatibles
de 120 Hz. Medir 60 y 120 Hz por separado, con presupuesto de 16,67 y 8,33 ms
respectivamente. Respetar frecuencia y ahorro de energía elegidos en el dispositivo;
no modificar ajustes globales ni prometer 120 FPS sin comprobar las trazas.
Si Android no habilita 120 Hz durante la prueba, registrar el bloqueo y mantener
esa validación pendiente. No presentar una medición a 60 Hz como evidencia de 120 Hz.

- PERF-AC-01: Obtener y guardar línea base y comparación en el mismo Android físico,
  mismo modo profile y configuración, versión de Flutter, fixture, frecuencia y secuencia.
  Identificar las revisiones de código anterior y posterior. Registrar
  dispositivo, Android, frecuencia observada, condiciones térmicas y número de muestras.
  Debug no se usa para concluir sobre rendimiento; sin emuladores. iOS separado.
- PERF-AC-02: Desplazamiento calentado: tres recorridos de 30 segundos. Registrar
  p50/p95/p99 de build y raster por separado y proporción de frames donde cualquiera
  supera B = 1000 / Hz ms. Meta del proyecto: p95 de cada etapa ≤ B y frames fuera
  de presupuesto ≤ 5% en cada recorrido del caso principal. No sumar etapas que
  trabajan en pipeline ni inferir FPS de su promedio. Primera pasada se mide aparte.
- PERF-AC-03: Medir 5 aperturas de proceso y 10 aperturas/regresos de detalle.
  Distinguir primer frame de catálogo utilizable (datos y controles listos, con
  placeholders permitidos). Registrar mediana y máximo. Ninguna mediana de apertura
  o detalle empeora más del 10% frente a su línea base comparable; investigar ruido
  si se cruza el límite antes de aceptar o rechazar. No borrar datos para simular frío.
- PERF-AC-04: En 20 búsquedas y 20 cambios de selección del caso principal, medir
  desde evento de entrada hasta frame con resultado/estado correspondiente. Meta
  p95 ≤ 100 ms. Se mantiene búsqueda normalizada AND categoría, estados de agotados
  y ocultos, selección y precios vigentes; sin debounce que deje resultados obsoletos.
- PERF-AC-05: Las tarjetas no necesitan decodificar fotos completas de alta resolución
  cuando su tamaño visible es menor. Dimensionar según layout y densidad real,
  conservar aspecto, recorte actual y fallback; detalle legible sin degradar originales.
  Registrar tamaño decodificado e ImageCache antes/después con fixtures grandes;
  demostrar reducción de bytes decodificados de las tarjetas. Medir también memoria
  del proceso sin confundirla con ImageCache ni exigir que el SO la libere de inmediato.
- PERF-AC-06: Tras cinco ciclos del mismo recorrido y detalle, registrar memoria y
  caché bajo las mismas condiciones de reposo. Investigar crecimiento sostenido de
  imágenes retenidas o listeners. No aumentar límites globales de caché para ocultar
  el problema; el escenario de 100 productos registra métricas y no presenta cierre
  inesperado ni errores de recursos. No exige los umbrales de 20 productos.
- PERF-AC-07: Pruebas pertinentes mantienen navegación, filtros, selección, fotos,
  accesibilidad, administración protegida y ambos alcances/nombres PDF. Formato,
  análisis y pruebas documentados. La mejora visual percibida sola no acredita métricas.
- PERF-AC-08: Instrumentación/fixtures nativos usan exclusivamente applicationId
  `.integration`, verificado en el APK antes de instalar; no ejecutar pruebas que
  desinstalen el paquete real. Actualización normal posterior solo con `adb install -r`.
  No sembrar, sustituir, exportar ni leer datos privados para generar fixtures. No
  enviar archivos a contactos. Registrar ejecución real, pendientes y límites.
- PERF-AC-09: Medir transiciones catálogo↔detalle, catálogo↔selección y acceso/salida
  del panel: 10 ciclos ida/vuelta por ruta en profile físico. Registrar duración
  observada y frames build/raster durante las animaciones. Meta por ruta agregando
  sus ciclos: p95 de cada etapa ≤ B y frames fuera de presupuesto ≤ 5%. Medir
  lectura de datos por separado de la duración de transición. Mantener patrón visual,
  gesto y botón de volver; no añadir efectos ni alargar duraciones para ocultar tirones.
  Respetar reducir/desactivar animaciones. Verificar navegación rápida y bloqueo de
  sesión sin exposición del panel ni acciones duplicadas. Las muestras de frames
  con movimiento reducido se registran aparte, sin mezclar perfiles. Un cambio de
  vista que actualmente no anima (por ejemplo pestañas del panel) se valida por
  respuesta y ausencia de errores; no se inventa una animación ni un percentil de
  transición inexistente. Registrar ese caso como no aplicable al presupuesto animado.

Los umbrales numéricos son metas de este proyecto, no garantías de Flutter ni
resultados obtenidos. Si la línea base ya cumple, conservarla y evitar refactorizar
sin beneficio. Si alguna meta no se cumple, registrar el fallo y la evidencia;
no ajustar el umbral silenciosamente ni declarar completa la implementación.

## Fuentes

- [Profiling Flutter en dispositivo físico y modo profile](https://docs.flutter.dev/perf/ui-performance).
- [Buenas prácticas de rendimiento](https://docs.flutter.dev/perf/best-practices).
- [DevTools Performance](https://docs.flutter.dev/tools/devtools/performance).

## Entrega

Se entregaron spec, diseño, plan y protocolo QA, y comenzó la ejecución autorizada.
En la comparación física a 120 Hz, baseline y candidato aprobaron los tres recorridos
calentados. La proporción de frames fuera de presupuesto al abrir detalle pasó de
5,660% a 2,439%, y al abrir selección de 15,547% a 2,597%. El tamaño decodificado
de la foto medida pasó de 48.000.000 a 2.952.192 bytes (93,85% menos); esto no
equivale a una reducción idéntica de memoria total del proceso.

Se ejecutaron 88 pruebas host, análisis sin incidencias y comprobación de formato
de 35 archivos. La mejora usa decode acotado; no cambia `MaterialPageRoute` ni
duraciones. Las entradas medidas cumplen <100 ms y no justificaron refactorizar
VM/cachés/listeners en este incremento. Estas cifras no acreditan todavía todos
los criterios: también se ejecutaron la serie de 60 Hz, bootstrap SQLite, detalle
F20, recorridos completos de 100 productos y panel con autenticación sintética.
La comparación ampliada F20 conserva la alerta de la primera pareja y todas las
muestras; mediana de detalle +6,89%, regreso +0,74%, bootstrap +2,45%.
La versión release normal 0.6.0+7 quedó instalada mediante actualización y se
comprobaron catálogo existente, fotos, acceso bloqueado, BACK y gesto de borde.
Pendientes: movimiento reducido real del sistema Android e iOS; la preferencia
MediaQuery simulada y pruebas host no acreditan esa ejecución nativa.
Consultar `qa.md` para condiciones, series y límites. No reemplazar datos del usuario;
iOS permanece pendiente de su entorno nativo.
