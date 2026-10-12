# QA — SPEC-001 v2: catálogo local con administración

Estado: implementación v2 integrada; 56 pruebas host y 1 escenario nativo Android
aprobados por coordinación. QA realizó revisión independiente y escribió regresiones.
Resultados ejecutados y pendientes de aceptación se separan al final del documento.
La implementación y las 15 pruebas anteriores pertenecen a v1, archivadas en
`history/v1/`; no constituyen aprobación de ningún criterio V2-AC-*.

## Alcance, entorno y preparación

Fuente de verdad: `spec.md` v2. Probar Android e iOS por separado, con sqflite,
almacenamiento protegido, archivos privados, cámara/galería y apertura externa
reales cuando corresponda. El entorno conocido es Windows; iOS requiere un
entorno macOS/Xcode y dispositivo físico adecuado. Por instrucción del usuario
**no usar ni iniciar emuladores**. Android se verificó en teléfono físico conectado
por USB; el recorrido inspeccionado cubre catálogo vacío y acceso al panel.
Confirmar herramientas,
versiones y dispositivos al ejecutar; no reutilizar el entorno histórico como
resultado actual. Las fotos de prueba serán fixtures identificables sin datos
personales, además de las fotos reales suministradas cuando estén disponibles.

Usar instalación limpia, base existente versionada y catálogo de referencia de
5 categorías y 20 productos. Incluir nombres con acentos, SKU con ceros y caso
mixto, descripciones extensas, productos ocultos/agotados y ofertas. Los 20
productos no son un máximo. Preparar imágenes decodificables, corruptas, ausentes
y con rutas temporales; respaldos válidos y alterados. Usar PIN y códigos
exclusivamente de prueba, incluido un PIN como `0042`; no publicar credenciales
reales en fixtures, evidencias o logs. El PIN inicial real y el número WhatsApp
siguen pendientes de suministro/configuración.

## Matriz de trazabilidad

Los criterios completos de esta matriz siguen pendientes; las pruebas parciales
no aprueban automáticamente un criterio ni plataforma. U = unidad; W = widget;
I = integración nativa; M = recorrido manual; R = revisión de arquitectura.

| Caso | Criterio | Verificación y resultado esperado | Capas |
| --- | --- | --- | --- |
| V2-QA-01 | V2-AC-01 | Instalación limpia y actualización desde v1 abren catálogo vacío sin PIN ni demos; mensaje exacto «No hay productos disponibles», acceso al panel visible. Solo entrar al panel solicita PIN. Repetir después de cerrar y abrir app; no importar demos v1. | W, I, M |
| V2-QA-02 | V2-AC-02 | PIN configurado correcto abre panel; longitud distinta de 4, caracteres no numéricos y PIN incorrecto no acceden. `0042` conserva sus cuatro caracteres. Cambiar exige PIN vigente y confirmación coincidente; error no cambia verificador. Probar espera, vencimiento y reinicio según política de plan. | U, W, I |
| V2-QA-03 | V2-AC-03 | Primer acceso correcto inicia configuración y muestra código para guardar; cancelar retoma paso siguiente acceso. Recuperación válida permite PIN nuevo y mantiene catálogo, fotos y ajustes; código usado queda inválido y sustituto funciona. Código incorrecto y cancelaciones conservan credenciales; errores no revelan PIN/código. | U, W, I, M |
| V2-QA-04 | V2-AC-04 | Salir del panel, background/foreground y reiniciar cierran sesión. Intentar rutas directas, comandos pendientes y operaciones de repositorio administrativo sin sesión se rechaza; catálogo sigue público. La sesión no se reconstruye desde respaldo/ajustes. | U, W, I, M |
| V2-QA-05 | V2-AC-05 | Crear/editar/ordenar/eliminar categorías libres y reiniciar conserva resultados. Rechazar vacío y duplicados por caso/acentos. Eliminar categoría con producto visible, oculto o agotado se bloquea; reasignar antes permite eliminarla sin huérfanos. | U, W, I |
| V2-QA-06 | V2-AC-06 | Crear/editar exige nombre, descripción, SKU, presentación, precio normal, exactamente una categoría existente y al menos una foto. SKU duplicado por caso se rechaza. Categoría eliminada durante formulario o fallo de guardado no deja producto parcial. Cancelar creación/edición conserva estado previo. Eliminación exige confirmación. | U, W, I |
| V2-QA-07 | V2-AC-07 | Cámara y galería agregan varias imágenes; quitar/reordenar cambia portada a primera. Tras limpiar rutas temporales/reiniciar, fotos privadas siguen válidas. Cancelación de selector, denegación/revocación de permisos y error de captura conservan formulario/datos; conciliar reautenticación por lifecycle. | U, W, I, M |
| V2-QA-08 | V2-AC-08 | Imagen inexistente/corrupta muestra alternativa en tarjeta, detalle y galería sin perder textos ni bloquear lectura. Cancelar edición limpia nuevas copias no referenciadas; guardar elimina solo medios que dejan de usarse; eliminar producto limpia sus medios. Fallos y referencias compartidas no borran archivos de otros productos. | U, W, I |
| V2-QA-09 | V2-AC-09 | Ocultos no aparecen en catálogo, resultados, detalle público por ruta directa ni selección/consulta. Agotados permanecen visibles con etiqueta y estado de mensaje. Panel distingue oculto de agotado; combinaciones oculto+agotado no filtran datos al público. | U, W, I |
| V2-QA-10 | V2-AC-10 | CLP admite enteros ≥0 y rechaza negativos, fracciones y entradas inválidas. Oferta exige rebajado ≥0 y <normal; probar cero, igualdad y normal cero. Tarjeta/detalle muestran precio vigente y ambos importes cuando hay oferta, con señal no basada solo en color. Formulario e importación comparten reglas. | U, W, I |
| V2-QA-11 | V2-AC-11 | Buscar por nombre, descripción y SKU ignorando caso/acentos; combinar categoría con AND y opción Todas. Diferenciar catálogo sin productos públicos de búsqueda/filtro sin coincidencias con mensajes exactos. Resultados nunca incluyen ocultos; sí agotados. | U, W, I |
| V2-QA-12 | V2-AC-12 | Abrir detalle y recorrer descripción completa sin elipsis, SKU, categoría, presentación, estado, precios y todas las imágenes en orden. Galería inválida tiene alternativa. Producto ocultado/eliminado mientras detalle está abierto no deja detalle público consultable obsoleto. | W, I, M |
| V2-QA-13 | V2-AC-13 | Orden manual de categorías/productos sobrevive reinicio. Edición, ocultar, eliminación e importación refrescan vistas sin relanzar; selección elimina referencias no públicas y consulta atributos/precio actuales. Reordenar/cancelar/fallo no pierde productos. | U, W, I |
| V2-QA-14 | V2-AC-14 | Solo panel autenticado edita número internacional. Número ausente/inválido informa y no invoca lanzador. Mensaje individual/conjunto incluye nombre, SKU, presentación, CLP vigente y disponibilidad de datos actuales; codificar acentos/símbolos y permitir agregar/quitar selección sin cantidades. | U, W, I, M |
| V2-QA-15 | V2-AC-15 | Lanzador externo prepara mensaje y destino; no llama servicio de envío ni marca como enviado. WhatsApp ausente, rechazo/error del sistema y vuelta a app informan apropiadamente/conservan selección. Agotados incluyen estado; sin conexión no se promete envío. Verificar borrador externo sin enviarlo. | U, W, I, M |
| V2-QA-16 | V2-AC-16 | En modo avión recorrer, buscar, filtrar, autenticar, crear/editar/ordenar y usar fotos ya locales; cerrar/reabrir conserva datos, fotos y ajustes. La app no depende de backend; WhatsApp se verifica como acción externa con conectividad limitada. | I, M |
| V2-QA-17 | V2-AC-17 | Exportar sin sesión se rechaza. Respaldo autenticado versionado contiene productos, categorías, relaciones, orden, medios y ajustes WhatsApp/tema; inspeccionar archivo e inventario. Nunca contiene PIN, verificadores secretos, código ni sesión; cancelar/fallar no altera catálogo. | U, W, I |
| V2-QA-18 | V2-AC-18 | Importar sin sesión se rechaza. Archivo válido muestra resumen y exige confirmar reemplazo. Receptor con datos distintos queda exactamente con catálogo importado, sin mezcla, mantiene credenciales propias y sesión no se concede por archivo. Refresca vistas, vacía selección y persiste al reiniciar. | U, W, I, M |
| V2-QA-19 | V2-AC-19 | Rechazar versión/estructura/relaciones/SKU/precios/medios/rutas inválidos antes de reemplazar. Cancelar, falta de espacio y fallos/interrupciones por fase mantienen el catálogo anterior hasta confirmación durable; recuperación no produce mezcla ni referencias rotas. Aplicar matriz de fallos inferior. | U, I, M |
| V2-QA-20 | V2-AC-20 | Sistema por defecto; elegir Claro/Oscuro/Sistema persiste tras reiniciar. Sistema reacciona a cambio del SO. Todos los estados usan roles M3; medir parejas reales texto/fondo en ambos esquemas y controles ≥48×48 dp. No reutilizar contrastes de v1. | U, W, I, M |
| V2-QA-21 | V2-AC-21 | Matriz 320/390 dp × escala 1/2 × claro/oscuro para catálogo/detalle/formularios/PIN y estados de error; teclado e insets no ocultan acciones ni textos. TalkBack/VoiceOver anuncian nombres, estados, errores y orden; PIN/recuperación no exponen secretos por etiquetas. Ventanas medianas/expandidas siguen diseño sin overflow. | W, I, M |
| V2-QA-22 | V2-AC-22 | Revisar dependencias MVVM: View sin SQL/archivos/secretos; VM y repositorios probados aislados. SQLite real versionado crea y migra esquema; restricciones, transacciones y rollback cubren datos y ajustes. Fakes de host no aprueban sqflite nativo. | R, U, I |
| V2-QA-23 | V2-AC-23 | Fixture 5 categorías/20 productos permite recorrer todos, buscar/filtrar/editar/reordenar y reiniciar sin pérdida ni bloqueo. Verificar conteos/relaciones e integridad de medios antes/después; no introducir tope de 20 ni SLA no definido. | U, I, M |
| V2-QA-24 | V2-AC-24 | Registrar formato/análisis/pruebas de unidad/widget/integración, compilación e instalación/recorrido por plataforma con evidencia. Android aprobado no valida iOS; compilar no equivale a recorrido. | Todas |

## Automatización significativa por capa

### Unidad: reglas, ViewModels y repositorios

- Validación compartida formulario/importación de campos, SKU, categoría, CLP y
  ofertas; normalización de búsqueda; visibilidad pública y datos vigentes.
- ViewModels con servicios/repositorios controlados: carga, éxito, error,
  cancelación, comandos repetidos y lifecycle. Fallos de persistencia dejan estado
  recuperable y no anuncian éxito antes del guardado. Pruebas de autorización
  invocan operaciones directamente, sin depender de ocultar botones.
- PIN/código: preservar ceros, verificar sin revelar secretos, cambio y rotación,
  errores y cancelación; reloj inyectado para espera temporal. No comparar secretos
  en aserciones que puedan imprimir valores reales.
- Repositorios: transacciones pedidas, reglas comunes y propagación de fallos;
  dobles permiten inyectar cada fase de respaldo/medios. No confundir una prueba
  de fake con evidencia de SQLite, permisos o almacenamiento protegido.
- Mensajes WhatsApp y adaptador: número inválido produce cero intentos, selección
  vigente, URL/contenido codificado, error conserva estado, ausencia de autoenvío.

### Widget: estados y acciones observables

Formularios y sus errores, confirmaciones destructivas, navegación pública/admin,
PIN y recuperación, catálogo/búsqueda/detalle/galería, selección, resumen de respaldo
y ambos temas. Probar los estados alternativos de la matriz, semántica y geometría
con teclado/insets/texto ampliado. Validar contenido alcanzable al final real del
scroll; no fijar un desplazamiento arbitrario para textos largos. Los contrastes
se calculan sobre parejas efectivamente renderizadas de ambos esquemas y estados;
texto normal ≥4.5:1, texto grande ≥3:1 cuando aplique, elementos informativos y
límites de controles ≥3:1 según diseño. No imponer contraste a fotos decorativas.

### Integración SQLite y archivos reales

Ejecutar en Android y iOS con sqflite nativo y directorios privados de prueba,
separados de datos personales. Crear base nueva, cerrar/abrir y comprobar
categorías/productos/imágenes/orden/ajustes. Por cada versión soportada, partir de
fixture de esquema anterior y migrar con datos, preservando relaciones e índices.
Validar integridad posterior y fallo de migración sin marcar versión como completada.
La actualización desde v1 inicia sin demos: v1 no persistía catálogo editable.

Probar SQL real para unicidad normalizada, claves foráneas activas, referencia a
categoría inexistente, eliminación restringida y referencias de imagen inválidas;
la validación en UI no reemplaza estas comprobaciones. Inyectar fallo tras la
primera escritura de una operación compuesta y verificar rollback íntegro.
Cerrar proceso/conexión y reabrir para comprobar persistencia. Nunca limpiar bases
o medios fuera del directorio aislado de la prueba.

Los archivos y SQLite no comparten una transacción. El protocolo coordinado usa
una única base sqflite y reemplazo de filas dentro de transacción; prepara y
promueve una generación de medios antes del commit SQL, manteniendo los medios
anteriores hasta éxito. No hay sustitución de archivo DB ni otra DB de control.
Comprobar fallos antes/después de promoción, durante transacción, justo antes y
después de commit y durante limpieza. Antes del commit durable sigue vigente el
catálogo anterior; después se recupera el nuevo completo. Nuevos archivos sin
referencias se limpian con seguridad; archivos antiguos vigentes no se borran.
Verificar que rollback SQL no se presente como garantía suficiente de fotos.

## Matriz de medios y recuperación de respaldo

Todos los casos siguientes están pendientes y complementan V2-QA-07/08/17/18/19.

| Entrada o punto de fallo | Oráculo de integridad |
| --- | --- |
| Galería/cámara cancelada o permiso denegado/revocado | Formulario y datos previos intactos; ninguna foto nueva parcialmente guardada; sesión según lifecycle. |
| Captura temporal eliminada por el SO después de guardar | Copia privada sigue decodificable tras reinicio; referencias no apuntan al temporal. |
| Cancelar tras agregar/quitar/reordenar fotos | Producto y portada anteriores intactos; limpiar solo copias nuevas sin referencia. |
| Error al copiar/guardar/eliminar medios | No anunciar éxito parcial ni borrar fotos vigentes; recuperar/limpiar sin afectar otros productos. |
| Exportación vacía y catálogo completo | Archivo válido o resultado definido en plan, conteos y medios exactos; nunca secretos. |
| Archivo truncado, corrupto, versión desconocida o estructura incorrecta | Rechazo previo; sin cambio de catálogo, ajustes, medios o credenciales. |
| IDs duplicados, FK huérfanas, SKU duplicado por caso, categoría duplicada por caso/acentos | Rechazo previo, sin mezcla ni datos parcialmente importados. |
| Precio fraccionario/negativo, oferta ≥normal, campo obligatorio o foto faltante | Mismas reglas que formulario; rechazo previo y catálogo anterior íntegro. |
| Ruta `../`, absoluta, separadores alternativos, colisiones o enlace que escape del staging cuando el formato lo permita | No escribir/leer fuera del área aislada; rechazo antes de reemplazo. |
| Archivo/imagen demasiado grande, expansión excesiva o conteos sobre límites definidos | Rechazo controlado, sin agotar memoria/espacio; límites pendientes de plan. |
| Cancelar selector o resumen antes de confirmar | Catálogo, selección, ajustes y credenciales receptores intactos. |
| Sin espacio en staging, copia de fotos, escritura DB o confirmación | Fallo controlado; catálogo previo y sus medios íntegros; limpiar restos seguros al recuperar. |
| Cierre forzado durante validación/staging, antes/después de commit y antes/durante limpieza | Reabrir según protocolo documentado; estado anterior o nuevo confirmado completo, nunca mezcla. El punto que permite conservar el nuevo debe quedar explícito en plan. |
| Respaldo con archivos ajenos o campos de credenciales manipulados | No sobrescribir secretos ni sesión receptoras ni archivos externos; aplicar política documentada de rechazo. |
| Importación válida entre dos dispositivos con PIN/código diferentes | Catálogo y ajustes no secretos se reemplazan; PIN/código receptores funcionan; remitentes no desbloquean; selección se vacía. |

Comparar snapshots de registros, orden, ajustes, inventario y hashes de medios
antes/después de cada fallo. Verificar que toda referencia activa tenga archivo
privado decodificable y que limpieza no elimine medios del snapshot vigente.
Credenciales permanecen independientes del catálogo en todas las fases. No incluir
secretos en diffs de evidencia.

## Seguridad y lifecycle

Inspeccionar base sqflite, archivos exportados y logs capturados usando credenciales
sintéticas: no contener PIN/código en texto plano ni sesión serializada. Revisar
almacenamiento de verificadores protegidos y configuración de backup automático
Android/iOS para evitar exponer material de credenciales. Los detalles concretos
los debe fijar el plan; inspección de código sola no aprueba seguridad nativa.
Verificar cancelación/errores de almacenamiento protegido, y que importar nunca
restaure sesión ni sustituya credenciales. No declarar resistencia a ataques ni
protección criptográfica sin evidencia pertinente.

Probar interrupción al cambiar PIN, recuperar y mostrar código sustituto: no dejar
credenciales sin vía válida de recuperación según protocolo definido. Verificar
que rutas/operaciones se vuelvan a autorizar al retornar de cámara, galería,
selector/compartidor de respaldo y WhatsApp. Cámara, galería y superficies nativas
que envían la app a background cierran sesión, pero conservan borrador y datos
seleccionados en memoria. Al volver, exigir PIN antes de guardar o ejecutar
operaciones administrativas. Cancelar PIN vuelve al catálogo público sin borrar
el borrador en memoria ni persistirlo sin sesión. Probar estos límites también
durante importación/exportación y limpieza de medios preparados.

## Verificación manual nativa y comandos previstos

En cada plataforma: instalación limpia, administración inicial, creación con
cámara/galería, permisos concedidos/denegados/revocados, cambio/recuperación PIN,
bloqueo por background, edición/visibilidad, búsqueda/detalle, consulta externa,
respaldo/reemplazo, fallo de importación y reinicio. Repetir uso local en modo
avión; probar selección WhatsApp con/sin app externa y sin enviar mensajes.
TalkBack en Android y VoiceOver en iOS requieren recorridos reales separados.
Las pruebas de cámara/permisos y demás plugins requieren el dispositivo físico;
los dobles de host no acreditan comportamiento de hardware ni permisos nativos.

Comandos orientativos para cuando exista implementación v2 y pruebas pertinentes;
**no ejecutados en esta entrega**:

```text
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test -d <dispositivo_android>
flutter build apk --debug
flutter test integration_test -d <dispositivo_ios>
flutter build ios --no-codesign
```

Ajustar rutas a archivos existentes. Registrar versión SDK/plugins, revisión,
plataforma/OS/dispositivo, fixtures, comandos y salidas; no ejecutar host con un
backend SQLite alternativo y declararlo aprobación de sqflite Android/iOS.

## Políticas de referencia y verificaciones pendientes

Las propuestas técnicas de `plan.md` fueron adoptadas por coordinación como
valores iniciales de planificación en `spec.md`. No son resultados de pruebas.

1. Espera PIN: 5 fallos, 30 segundos iniciales y aumento hasta 15 minutos;
   comprobar persistencia de contador/plazo, reloj, reinicio y segundo plano.
2. Código: 128 bits aleatorios Base32, verificadores protegidos y KDF descrita
   en el plan; comprobar normalización, custodia y fallos durante cambio/rotación.
   Medir rendimiento móvil antes de fijar parámetros; PIN inicial real fuera de docs.
3. Respaldo ZIP v1, límites exactos de `plan.md`, medios JPEG/PNG y staging antes
   de commit SQL; comprobar validación, recursos, durabilidad y recuperación
   anteriores/posteriores a esa frontera conforme a V2-AC-19.

Actualización desde v1 y lifecycle nativo están resueltos en spec. La medición,
selección final de plugins y evidencia nativa siguen pendientes de implementación.
El código de recuperación mostrado intencionalmente al administrador debe ser
accesible; no confundir protección de campos ocultos/logs con impedir su lectura.

## Registro y cierre

### Revisión independiente de implementación — 2026-10-08

Se leyeron contratos, autenticación, repositorio SQL, medios, respaldos,
ViewModels y composición/UI provisional. El código implementa MVVM por contratos,
SQLite versionada con FK/transacciones, verificadores protegidos inyectables y
staging de restauración. Esto describe código presente; no acredita ejecución
en Android/iOS, durabilidad ante cierre forzado ni comportamiento de permisos.

Hallazgos comunicados a los responsables, con correcciones reportadas pendientes
de ejecutar/verificar sobre el snapshot final:

| Hallazgo de lectura | Corrección comunicada por responsable | Verificación restante |
| --- | --- | --- |
| VM conservaba códigos de setup/recuperación al bloquear; AuthPanel podía mostrarlos después de invalidarlos. | UI: listener limpia ambos códigos al perder autenticación. | Regresiones QA de bloqueo y recorrido lifecycle físico. |
| Borrar producto/quitar foto original no disparaba limpieza; no había recuperación de GC al arranque. | UI: GC tras commit sin declarar rollback por fallo de limpieza. Data: protección de generación promovida; coordinación integra limpieza de arranque. | Ficheros vigentes conservados, huérfanos eliminados y crash/reapertura. |
| Copia parcial de selección podía quedar sin registrar para descarte; copia inicial del ZIP estaba fuera del try de cleanup. | Data: registrar draft antes de escribir y mover copia fuente al try. | Inyección de fallo de escritura/copia y comprobación de staging vacío. |
| Exportación compartida fallida/cancelada dejaba ZIP temporal. | Data: cleanup al fallo. Coordinación define retención privada hasta 24 h en éxito para que receptor externo pueda leer; limpieza al arranque. `share:false` conserva archivo explícito. | Error limpia; éxito permite leer; caducidad/cleanup y share físico pendientes. |
| Timer PIN no reconstruía al llegar a cero y podía dejar Entrar deshabilitado. | UI: reconstruir incluyendo transición a cero; mostrar segundos redondeados hacia arriba. | Regresión widget QA y comportamiento físico. |
| Placeholder fotográfico quedaba excluido del árbol semántico. | UI: mantener semántica del fallback y excluir solo imagen decorativa. | Árbol final y TalkBack/VoiceOver físicos. |

Coordinación define la escritura protegida ya despachada y autorizada como punto
de compromiso: no prometer rollback de `store.write` si ocurre un lock durante
esa escritura. Sí exigir fail-closed: su terminación no reabre sesión revocada.
Una regresión QA bloquea/libera esa escritura para verificarlo. Para comandos de
catálogo/respaldo, coordinación integra un token de sesión que invalida operaciones
iniciadas antes de lock incluso si hay reautenticación posterior. La comprobación
booleana por sí sola no identifica la sesión original; pruebas de carrera y
evidencia nativa siguen pendientes. No se afirma vulnerabilidad explotada.

### Nuevas pruebas de QA escritas, no ejecutadas por QA

| Archivo | Casos | Qué comprueba |
| --- | --- | --- |
| `test/qa/view_model_security_media_test.dart` | 6 | Códigos de setup/recuperación desaparecen al lock; una escritura protegida despachada no reabre sesión revocada; eliminar/editar limpia originales no referenciados sin borrar otros; fallo SQL conserva ficheros. |
| `test/qa/backup_cleanup_session_test.dart` | 3 | Compartir con error retira ZIP; éxito lo conserva temporalmente para receptor; perder sesión entre validación/promoción y reemplazo conserva catálogo al reabrir. |
| `test/qa/auth_panel_lockout_test.dart` | 1 | Vencer espera habilita Entrar sin otra acción/notify. |

Estas diez regresiones quedan pendientes de formato, análisis y ejecución por
coordinación. Usan credenciales sintéticas, temporales privados, fakes de catálogo
para límites VM y SQLite FFI para rollback host; no prueban sqflite Android/iOS ni
secure storage, share, cámara o permisos nativos. Los tests de otros responsables
en `test/auth`, `test/whatsapp`, `test/data` y `test/ui` tienen ejecución central.

### Evidencia ejecutada por coordinación — 2026-10-08

Resultados sobre la implementación v2 integrada. La ejecución anterior con un
fallo de navegación del test UI fue corregida y reemplazada por la pasada final.
El test ahora desplaza el botón a pantalla antes de tocarlo; no silencia el fallo.

| Verificación | Resultado real | Alcance y límites |
| --- | --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | EXIT0, 26 archivos, 0 cambios | Formato del snapshot final. |
| `flutter analyze` | EXIT0, No issues found | Código app, tests e integración. |
| `flutter test --reporter expanded` | EXIT0, 56 pruebas aprobadas | Auth 8, WhatsApp 4, data 26, QA 10, UI 8. SQLite FFI host; plugins externos inyectados. |
| `flutter test integration_test/native_catalog_test.dart -d <Android físico> --reporter expanded` | EXIT0, 1 prueba nativa aprobada, 20 s de ejecución | Android 15, modelo 23049PCD8G, USB físico. SQLite nativo, lectura/escritura/borrado de clave protegida aislada, KDF real 600000 iteraciones, 5 categorías/20 productos, reapertura persistente, FK, roundtrip ZIP y rollback inyectado antes de reemplazo. |
| `flutter build apk --debug --dart-define-from-file=.local/build-config.json` | EXIT0, APK v2 generado | Compilación debug Android; configuración privada, sin publicar PIN. |
| Instalación `adb install -r` y apertura actividad | Success; pantalla pública vacía y acceso PIN inspeccionados | Instalación sobre dispositivo físico sin borrar datos. Se volvió al catálogo sin completar setup ni ingresar PIN real. |
| Compilación/ejecución iOS | No ejecutada | Este workspace Windows carece de macOS/Xcode. |

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256: `EEB7C10CBEB2E187FA06FF73E72ADF99FAAA639901C83CBBA4D9BF939C44C5BF`.
Capturas inspeccionadas: `artifacts/qa-v2/android-public.png` y
`artifacts/qa-v2/android-pin.png`. No contienen credenciales ni catálogo personal.
La integración usa datos y claves sintéticos aislados y elimina sus temporales;
los 20 productos de QA no se precargan en el catálogo de la app.

La suite final ejecutó las diez regresiones independientes QA descritas arriba,
además de rollback SQL, límites/rutas de ZIP, hash manipulado, conservación de
medios vigentes, limpieza, retención de ZIP y revocación incluso con reautenticación.
Los widgets comprueban búsqueda/selección, borrador tras picker y bloqueo, sesión
visual con editor real, catálogo/detalle a 320dp y texto2 y 12 pares de contraste
por cada tema. Los pares medidos satisfacen el umbral declarado por sus pruebas.
No se generaliza este resultado a todos los estados ni a lectores físicos.

No se midió un tiempo aislado de KDF exportado como artefacto: el protocolo nativo
lo cronometra en `reportData`, pero el resultado CLI conservado solo acredita
finalización del escenario. No inferir rendimiento de release a partir de debug.

### Pendientes de aceptación y plataforma

- Cámara/galería reales, permisos rechazados, recuperación del picker tras muerte
  de proceso y conservación del formulario en el lifecycle del hardware.
- WhatsApp instalado/ausente y recepción del texto; compartir/seleccionar archivos
  mediante aplicaciones externas. Los tests de launcher/share inyectados no los acreditan.
- Modo avión físico y reinicio/muerte real del proceso; fallo por falta real de espacio
  e interrupciones en cada frontera del protocolo de respaldo. Los fallos inyectados
  aprobados solo acreditan sus fronteras concretas.
- Matriz completa 320/390dp×escala1/2, 600/840dp, teclado, TalkBack y VoiceOver.
- Compilar, instalar y recorrer iOS con Xcode, incluidos keychain, fotos y portabilidad
  de un respaldo entre Android e iOS reales.
- Upgrade real desde APK v1 y versiones futuras del esquema; los tests verifican
  base vacía inicial y rechazo preservador de versiones incompatibles.

T12/T13 permanecen abiertas para estos pendientes. La app implementa el alcance;
no se declaran los 24 criterios completamente aceptados ni soporte iOS verificado.
Todas las pruebas nativas reportadas aquí corresponden al Android físico; no se
utilizó emulador para esta evidencia. El catálogo quedó vacío y listo para que el
usuario complete setup, cree categorías y cargue sus fotos/productos reales.

### Ajuste visual solicitado — 2026-10-08

Separación de formularios: 24 dp entre campos/grupos y acciones, 8 dp entre
botones apilados. Cambios limitados a `lib/features/admin_views.dart`;
la política visual queda en `design.md`. No cambia el alcance funcional.

- Formato: 1 archivo, 0 cambios, EXIT0.
- `flutter analyze`: EXIT0, sin observaciones.
- `flutter test test/ui test/qa/auth_panel_lockout_test.dart --reporter expanded`:
  EXIT0, 9 pruebas aprobadas (incluyen navegación, bloqueo y texto ampliado).
- La evidencia completa anterior conserva su fecha/snapshot; los resultados de
  instalación del APK con este ajuste se registran a continuación.
- APK con separación: build debug EXIT0 (15,6 s); instalación sobre Android físico
  mediante `adb install -r`: Success. Datos persistidos conservados por instalación.
- SHA-256 del APK actualizado:
  `6046886B1CE2D9A6462DB64DFC1715D420C1C9E55635E23CBE68549A738DEC46`.
