# QA — SPEC-012: catálogo compacto y administración

Estado: implementación, revisión independiente y verificaciones host completadas.
El usuario confirmó SKU numérico correlativo `1`, `2`, … conservando códigos existentes.
Los estados iniciales de la tabla son el protocolo; resultados ejecutados al final.

## Casos de aceptación

| Caso | Criterios | Verificación | Estado |
| --- | --- | --- | --- |
| ADM-QA-01 — Catálogo compacto | ADM-AC-01/08 | Exactamente dos tarjetas por fila a 320 dp/texto 2×, claro/oscuro; solo imagen/nombre/control PDF. Nombre completo sin altura fija ni overflow. Última fila sin tarjeta ficticia. | Pendiente. |
| ADM-QA-02 — Imagen y selección | ADM-AC-02 | Imagen abre ID correcto y regreso conserva filtro/selección; checkbox actúa independientemente. Fotos cover/decode acotado y fallback navegable. Compartir ambos scopes sigue vigente. | Pendiente. |
| ADM-QA-03 — Navegación administrativa | ADM-AC-03/08 | NavigationBar en compacto y Rail desde 600 dp, tres destinos; estado/borradores conservados y contenido protegido al bloquear/suspender sesión. | Pendiente. |
| ADM-QA-04 — FAB y tarjetas | ADM-AC-04/08 | FAB de Productos separado, fuera de tarjetas, oculto en otros destinos; padding permite acceder a última tarjeta/acciones. Editar, estados, borrar/reordenar actuales accesibles 48 dp. | Pendiente. |
| ADM-QA-05 — Categorías/Ajustes | ADM-AC-07 | Conteo vigente incluye visibles/ocultos; editar/borrar/reordenar intactos. Apariencia, Seguridad y Respaldo conservan tema, PIN, recuperación, preview y confirmación de reemplazo. | Pendiente. |
| ADM-QA-06 — Categoría desde borrador | ADM-AC-06 | Crear guarda/selecciona ID sin perder texto/fotos/precios/estado. Cancelar, duplicado, error y bloqueo no alteran categoría previa ni borrador; sin escritura tras revocación. | Pendiente. |
| ADM-QA-07 — SKU automático | ADM-AC-05 | Campo nuevo readonly, preview estable; abrir/cancelar/guardar inválido no consume números. Guardado atómico concurrente asigna únicos; borrar máximo no permite reutilizar. | Formato confirmado; ejecución pendiente. |
| ADM-QA-08 — Migración y restauración | ADM-AC-05/09 | Base v1→v2 conserva productos/categorías/fotos/settings/SKU originales. Parte del mayor código del formato; restaurar mantiene máximo local y reconcilia importados, sin bajar contador. | Pendiente. |
| ADM-QA-09 — Calidad y entrega | ADM-AC-09 | Pruebas relevantes de datos/borrador/UI/seguridad, formato y análisis. Android físico, integración solo ID aislado verificado e instalación normal -r confirmada; datos reales intactos. | Pendiente. |

## Casos de datos de alto impacto

- Bases nuevas vacías, v1 con SKU alfanumérico y correlativos numéricos; códigos
  con ceros iniciales, mayor borrado y números excepcionalmente grandes admitidos
  por el SKU libre anterior. No renumerar ni bloquear apertura de datos válidos.
- Apertura de múltiples borradores con el mismo preview y guardados concurrentes:
  los códigos definitivos se asignan desde persistencia, no desde el texto de UI.
- Fallo de validación/conflicto de producto o sesión revocada antes del commit:
  no hay producto parcial ni consumo del contador. Volver a intentar funciona.
- Restauración menor/mayor que contador local; con productos borrados previamente,
  el máximo local no se reduce. Respaldo antiguo de otro dispositivo no demuestra
  historia de códigos borrados allí, limitación que debe conservarse explícita.
- Cerrar/reabrir la base mantiene contador; edición de un producto existente
  conserva su SKU. Migración no cambia credenciales ni imágenes.

## Protocolo de UI y borrador

- Revisar lazy rows sin dos columnas que vuelvan a una por escala, ni imágenes
  decodificadas a resolución completa. Los campos removidos de tarjeta siguen en
  detalle/PDF. Verificar buscador/categoría AND, orden y selecciones actuales.
- Crear categoría con todos los campos de producto ya completados y fotos
  pendientes. Al éxito verificar nueva categoría seleccionada y resto idéntico;
  cancelar/error/duplicado mantienen selección anterior. Bloquear durante el
  guardado no expone panel ni permite escrituras posteriores.
- Catálogo/admin compacto a 320 dp y escala 2; controles y acciones de menú no
  cortados, nombres crecen, keyboard/focus y regreso protegidos. Lista puede
  desplazar última tarjeta por encima del FAB sin ocultar acciones.
- Cambiar destinos no superpone FAB ni pierde borradores existentes. PIN,
  recuperación y respaldo mantienen guardias y confirmación de reemplazo.

## Hallazgo temprano de migración

QA detectó una versión intermedia que rechazaba SKU numéricos antiguos fuera
de int64 durante reconciliación, impidiendo abrir una base v1 previamente válida.
El código posterior inspeccionado usa contador BigInt almacenado como TEXT, sin
rechazo por rango int64, preservando códigos gigantes al reconciliar. El hallazgo
intermedio ya no es un bloqueo presente en esa implementación. Sigue pendiente
comprobar migración/restauración de SKU gigante con pruebas ejecutadas.

## Límites

Revisión estática, pruebas host y Android físico se acreditan separadamente.
No ejecutar emuladores, sembrar/reemplazar catálogo real ni enviar PDF a contactos.
No ejecutar integración con el applicationId normal. El formato SKU confirmado
se conserva como decisión de alcance, sin renumerar registros existentes.
iOS requiere entorno nativo con Xcode y queda pendiente.

## Defecto confirmado — ADM-DEF-01: cierre del diálogo

El coordinador ejecutó las regresiones de interfaz y observó una excepción de
TextEditingController usado después de dispose al guardar/cerrar el diálogo de
nueva categoría. La finalización del Future de showDialog precede al desmontaje
completo de la ruta durante su animación; liberar el controlador en ese momento
deja al TextField todavía activo con controlador destruido.

Corrección en curso por el propietario de frontend: el diálogo debe poseer su
controlador y liberarlo en su ciclo de vida al desmontarse. QA exige repetir
guardar con éxito, cancelar y protección al revocar sesión; registrar ausencia
de excepción además de conservación del borrador. Estado: **confirmado, pendiente
de corrección y verificación**. No dar por aprobado ADM-QA-06 hasta esa ejecución.

## Regresiones independientes preparadas

`test/qa/admin_redesign_regression_test.dart` añade dos casos, sin duplicar el
caso básico de éxito/duplicado del frontend:

- Cancelar creación de categoría conserva nombre/presentación/precio modificados,
  categoría previa y foto del producto; no guarda categoría ni producto parcial.
- A 320 dp/texto 2×, la última tarjeta administrativa puede desplazarse por encima
  del FAB. Menú accesible conserva ocultar, marcar agotado y cancelar eliminación.

Archivo formateado con Dart. Ejecución pendiente de la corrección del diálogo y
orquestación del coordinador; QA no ejecutó Flutter simultáneamente con frontend.

## Revisión independiente final de código

- Schema 2 añade contador TEXT y reconcilia con BigInt los SKU numéricos; otros
  códigos y ceros iniciales se conservan. Generación lee/escribe contador e inserta
  producto dentro de la misma transacción, bajo el guard de sesión antes del commit.
  Preview no actualiza el contador. Borrar producto no reduce el máximo.
- Restauración conserva la fila de contador local y reconcilia contra productos
  entrantes dentro de la transacción de reemplazo. Migración crea/reconcilia el
  contador sin reescribir códigos existentes. La prueba preparada incluye un
  código numérico superior a int64 y prevé su siguiente BigInt exacto.
- Creación de categoría desde borrador mantiene campos/fotos; su VM comprueba
  sesión y revocación, selecciona el ID guardado únicamente al éxito y dispone
  del VM temporal/listener. Cancelar diálogo no llama a guardar categoría.
- El diálogo inline posterior posee TextEditingController en StatefulWidget y
  lo libera en dispose de su State; la revisión confirma la corrección de ciclo
  de vida de ADM-DEF-01. Cierre definitivo depende de regresiones ejecutadas.
- La administración usa NavigationBar/Rail según ventana, FAB exclusivo de
  Productos y padding inferior 112 dp en su lista. Menú conserva visibilidad,
  disponibilidad y eliminar con confirmación; edición y reordenamiento permanecen.
- El SKU se muestra readonly con previsión, asignando el definitivo desde repo al
  guardar. Tema, PIN, recuperación y respaldo siguen en grupos correspondientes;
  el navegador protegido mantiene el diálogo bajo el mismo guard de sesión.

Esta inspección no acredita concurrencia nativa entre conexiones independientes,
migración del catálogo real, respuesta física/fluidez, activación de teclado ni
desmontaje sin errores. Registrar las pruebas reales antes de aprobar esos casos.

## Ejecución host — 2026-10-08

- SQL y VM: 19 pruebas aprobadas, incluidas migración v1→v2, SKU históricos grandes,
  alta atómica frente a previsiones concurrentes, contador tras borrar/restaurar,
  rollback sin consumo y creación de categoría preservando borrador/sesión.
- UI: 17 pruebas aprobadas después de corregir ADM-DEF-01. La categoría inline
  se guarda, vuelve al formulario y queda seleccionada sin errores de controlador.
- Regresiones independientes: dos aprobadas. Cancelación mantiene nombre,
  presentación, precio, categoría y foto; la última tarjeta queda sobre el FAB
  y conserva cambios de estado/visibilidad y confirmación de eliminación.
- El primer test independiente falló por desplazarse durante el foco automático
  del campo y buscar elementos lazy no montados; se corrigió el harness delimitando
  el Scrollable del formulario, retirando foco antes del desplazamiento y mostrando
  el selector antes de leerlo. No se retiraron verificaciones.
- Suite completa `flutter test --reporter expanded`: **115 aprobadas**. Incluye
  autenticación, respaldos, medios, datos, VM, UI, transiciones y PDF de cuatro
  productos. Evidencia `artifacts/012-catalog-admin-redesign/host-tests.log`.
- Formato de diez archivos: correcto. Análisis final sin incidencias; se corrigieron
  tres avisos de llaves en if sin cambiar comportamiento y se aplicó formato.
- ADM-DEF-01 cerrado mediante las regresiones de cierre del diálogo, cancelación
  y retorno al formulario. La revisión estática sola no acreditó su solución.

Pendientes: build/instalación y revisión física, iOS con Xcode, lector de pantalla
físico y benchmark nativo de fluidez. No confundir host con mediciones del teléfono.
