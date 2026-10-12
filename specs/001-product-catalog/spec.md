# SPEC-001 v2 — Catálogo local con administración

Estado: implementación v2 integrada; verificación registrada por separado en
`qa.md`. Los recorridos manuales y la validación iOS pendientes no equivalen a
criterios aprobados.
Cambio posterior autorizado: [SPEC-002](../002-share-selected-catalog/spec.md)
sustituye el flujo de consulta WhatsApp por compartir selección en PDF a clientes.
Documentos y evidencia anteriores (15 pruebas y
APK Android) se conservan en `history/v1/`; no validan los requisitos nuevos.

## Objetivo y requisitos confirmados

App Flutter Android/iOS con arquitectura MVVM y sqflite. Todos los cambios son
locales al dispositivo, sin backend ni sincronización.

- Catálogo público sin PIN; panel dentro de la app protegido por PIN.
- PIN inicial predefinido de 4 dígitos, modificable; recuperación con código
  generado al configurar la app, conservando el catálogo.
- Crear, editar, ocultar, eliminar y ordenar productos; administrar categorías.
- Búsqueda, filtros por categoría y pantalla de detalle.
- Nombre, descripción, SKU, presentación, precio y exactamente una categoría
  por producto. Disponibilidad «Disponible / Agotado», sin stock numérico.
- Agotados visibles; ocultar es una operación diferente.
- Varias imágenes desde galería y cámara. El usuario dispone de fotos reales.
- Precios CLP y ofertas con precio normal y rebajado.
- Compartir productos seleccionados como catálogo PDF a clientes por WhatsApp;
  alcance y criterios vigentes en SPEC-002.
- Consulta, búsqueda, filtros y administración sin conexión. WhatsApp requiere internet.
- Instalación con catálogo vacío; volumen estimado: 5 categorías y 20 productos.
- Exportar/importar respaldo con productos, categorías e imágenes. Importar
  REEMPLAZA el catálogo, nunca combina los registros.
- Material Design 3, modos claro y oscuro, paleta propuesta por el diseñador.

## Reglas adoptadas para concretar el alcance

Las decisiones de esta sección completan los requisitos adoptados durante la
implementación; no se presentan como respuestas adicionales del usuario.

### Catálogo, búsqueda y detalle

Instalación limpia sin productos ni categorías de ejemplo. Actualizar desde v1
tampoco importa los ejemplos: v1 no tenía un catálogo editable persistido.
Mostrar «No hay
productos disponibles» si no hay productos públicos, y «No se encontraron
productos» para búsqueda/filtro sin coincidencias. El acceso al panel siempre
permanece disponible. Buscar nombre, descripción y SKU sin distinguir mayúsculas
ni acentos; combinar búsqueda y categoría con AND, incluyendo filtro «Todas».

Tarjetas: nombre, portada, presentación, precio vigente y disponibilidad. Detalle:
descripción completa, SKU, categoría, presentación, precios y galería completa.
El detalle sustituye la obligación v1 de descripción completa en cada tarjeta.
Ocultos no aparecen en catálogo, detalle público, búsquedas ni selección WhatsApp;
agotados sí, con etiqueta explícita y estado incluido al consultar.

Orden manual de categorías y productos persistido. Editar/ocultar/eliminar/importar
actualiza vistas sin reiniciar; la selección descarta referencias que dejan de
ser públicas y consulta siempre datos vigentes.

### Administración de productos y categorías

Obligatorios: nombre, descripción, SKU, presentación, precio normal, una categoría
existente y al menos una imagen. SKU único sin distinguir mayúsculas. Categorías
con nombre no vacío y único sin distinguir mayúsculas ni acentos. No eliminar una
categoría con productos: solicitar reasignarlos o eliminarlos primero.

CLP como enteros no negativos, sin decimales. Oferta opcional: precio rebajado no
negativo y menor que el normal, sin fechas programadas. Mostrar ambos precios y
señalar oferta sin depender solo del color. Precio vigente = rebajado si hay oferta.

Agregar, quitar y reordenar imágenes; la primera es portada. Copiar medios a
almacenamiento privado persistente, sin depender de rutas temporales de cámara
o selector. Cancelar selección/denegar permisos conserva formulario y datos.
Imagen inválida muestra alternativa sin perder textos. Eliminar producto requiere
confirmación. Guardar/cancelar no deja cambios parciales; limpiar medios que ya no
estén referenciados, sin borrar imágenes de productos vigentes.

### PIN y recuperación

PIN de cuatro caracteres numéricos, incluidos ceros iniciales. Valor inicial real
suministrado por el usuario y configurado en archivo local ignorado para esta build;
no publicar credenciales aquí. Guardar verificadores protegidos de PIN y código,
sin texto plano en sqflite, logs ni respaldos. El plan define y prueba la política
de espera temporal ante intentos erróneos repetidos.

En el primer acceso administrativo correcto, completar configuración y mostrar
un código de recuperación para guardar fuera de la app. Cancelar retoma el paso
en el siguiente acceso. Código válido permite definir PIN nuevo sin borrar datos;
invalidar el usado y generar sustituto. Cambio normal de PIN exige PIN actual y
confirmación del nuevo; nunca mostrar el vigente. Errores no alteran credenciales.

Validar sesión en rutas y operaciones, no solo en botones. Al salir del panel o
pasar a segundo plano, cerrar sesión administrativa. El catálogo sigue público.
Si se abrió cámara, galería o selector/compartidor nativo, conservar el borrador y
los medios seleccionados; al volver, pedir PIN antes de guardar o ejecutar otra
operación administrativa. El bloqueo no descarta el formulario. No guardar
automáticamente datos del borrador sin sesión válida.

### WhatsApp

El usuario corrigió el objetivo: enviar catálogo a clientes. SPEC-002 reemplaza
las consultas individuales/conjuntas a un número fijo. Selección temporal de
productos visibles; PDF con nombre, precio, presentación, portada y disponibilidad.
Elegir WhatsApp y cliente en el compartidor nativo, confirmar el envío allí;
no enviar automáticamente ni afirmar entrega. El número legado se conserva en
datos/backups por compatibilidad, sin intervenir ni mostrarse en el nuevo flujo.

### Respaldo y restauración

Solo en administración autenticada. Archivo portable versionado con catálogo,
categorías, orden, imágenes y ajustes no secretos (WhatsApp y tema). Excluir PIN,
código de recuperación y sesión. Mostrar qué incluye el respaldo.

Importación: validar archivo y mostrar resumen antes de confirmar reemplazo.
Cancelar conserva todo. Conservar credenciales del dispositivo receptor; importar
no desbloquea el panel. Validar versión, estructura, relaciones, SKU, precios,
imágenes y rutas. Rechazar incompatibles o inválidos antes de reemplazar.

Sustituir datos y medios con recuperación ante fallo/interrupción: no perder el
catálogo previo ni dejar mezclados datos nuevos/anteriores. El plan concreta
límites de recursos y algoritmo de staging/confirmación. Tras éxito, refrescar
vistas, vaciar selección temporal y conservar el resultado al reiniciar.

### Temas y accesibilidad

Identidad propuesta: verde bosque, verde salvia y superficies cálidas; esquemas
claro/oscuro mediante roles M3. Permitir Sistema/Claro/Oscuro y persistir elección;
Sistema por defecto es decisión adoptada, no requisito expresado por el usuario.

Áreas táctiles mínimas 48 × 48 dp, contraste medido, etiquetas semánticas y errores
accesibles. Respetar áreas seguras y texto ampliado a 320/390 dp y escala 1/2.
Adaptar ventanas medianas/expandidas sin añadir plataforma web.

## Arquitectura y persistencia

MVVM: Views presentan estado/acciones; ViewModels coordinan estado, validación y
comandos; repositorios proporcionan datos/reglas; servicios aíslan sqflite,
archivos, cámara/galería, apertura externa y almacenamiento protegido. Widgets no
ejecutan SQL ni lógica de credenciales. Inyectar dependencias para pruebas, sin
imponer gestor de estado externo. [Guía Flutter](https://docs.flutter.dev/app-architecture/guide).

sqflite persiste categorías, productos, referencias de imágenes, orden y ajustes
no secretos, con esquema versionado, relaciones y transacciones. Imágenes en
archivos privados. Una transacción SQLite no hace atómicas las operaciones de
archivos: planificar staging, commit y recuperación. [sqflite](https://pub.dev/packages/sqflite).

## Criterios de aceptación v2

Para planificar se adoptan los valores iniciales documentados en `plan.md`:
5 intentos fallidos antes de espera de 30 segundos, incremento hasta 15 minutos;
código de recuperación aleatorio de 128 bits; respaldo ZIP versionado con límites
de recursos y medios JPEG/PNG privados. Son decisiones técnicas del equipo,
no respuestas atribuidas al usuario. Algoritmos, durabilidad, accesibilidad y
parámetros criptográficos deben comprobarse al implementar; no están validados
por haberlos documentado. Ajustes derivados de mediciones se reflejan en el plan.

IDs nuevos para no confundirlos con `AC-*` y evidencia archivada v1.

| ID | Comportamiento verificable |
| --- | --- |
| V2-AC-01 | Instalación limpia o actualización desde v1 abre catálogo vacío sin PIN ni datos demo; permite acceder al panel. |
| V2-AC-02 | PIN inicial de 4 dígitos abre panel; errores no acceden; cambio y espera temporal funcionan según política documentada. |
| V2-AC-03 | Recuperación genera PIN nuevo conservando datos; invalida código usado; errores/cancelación no alteran credenciales. |
| V2-AC-04 | Salir del panel o enviar app a segundo plano exige PIN; rutas/operaciones sin sesión se rechazan; volver de cámara/galería conserva borrador y exige reautenticación antes de guardar. |
| V2-AC-05 | CRUD y orden de categorías persisten; se rechazan duplicados y eliminación de categorías con productos. |
| V2-AC-06 | CRUD de producto valida campos, SKU único y una categoría; guardar/cancelar no produce cambios parciales. |
| V2-AC-07 | Cámara/galería permiten múltiples fotos, orden y portada persistentes; cancelación/permisos no pierden formulario. |
| V2-AC-08 | Imágenes inválidas muestran alternativa; eliminar/cancelar limpia medios sin romper productos vigentes. |
| V2-AC-09 | Ocultos se excluyen de toda vista pública/selección; agotados siguen visibles con etiqueta; el panel distingue ambos. |
| V2-AC-10 | CLP/ofertas válidas persisten; se muestran precio normal y rebajado; formulario/importación validan igual. |
| V2-AC-11 | Búsqueda ignora caso/acentos, combina categoría y distingue vacío de sin resultados. |
| V2-AC-12 | Detalle ofrece descripción completa, SKU, categoría, presentación, estado, precios y galería. |
| V2-AC-13 | Orden persiste; edición y cambios de visibilidad refrescan vistas y selección sin reiniciar. |
| V2-AC-14 | Sustituido por PDF-AC-01..04 de SPEC-002: compartir catálogo PDF de selección a clientes. |
| V2-AC-15 | Sustituido por PDF-AC-04/05: no autoenvío ni confirmación ficticia; selección conservada. |
| V2-AC-16 | En modo avión consulta/búsqueda/filtros/administración funcionan y persisten fotos/datos tras reiniciar. |
| V2-AC-17 | Exportación autenticada contiene catálogo, medios y ajustes no secretos; excluye PIN/código/sesión. |
| V2-AC-18 | Importar exige sesión/confirmación, reemplaza sin mezclar, conserva credenciales receptoras y refresca vistas. |
| V2-AC-19 | Respaldo inválido, cancelación, falta de espacio o interrupción conservan catálogo anterior y coherencia datos/medios. |
| V2-AC-20 | Sistema/Claro/Oscuro persisten y usan roles M3; contraste y áreas táctiles se verifican en ambos esquemas. |
| V2-AC-21 | Catálogo/detalle/formularios/PIN funcionan a 320/390 dp y escalas 1/2; lectores anuncian controles, estados y errores. |
| V2-AC-22 | Views no acceden a SQL/archivos/secretos; ViewModels y repositorios se prueban por separado y esquema sqflite se versiona. |
| V2-AC-23 | Con 5 categorías y 20 productos se recorre, busca, filtra y edita sin pérdida; las cifras no son límites máximos. |
| V2-AC-24 | Formato/análisis/pruebas/compilación y recorrido Android/iOS registran evidencia separada; pendiente no equivale a aprobado. |

## Fuera de alcance

Backend/sincronización, panel web, usuarios remotos, cuentas de cliente, pagos,
pedidos, carrito con cantidades, inventario numérico, ofertas programadas,
notificaciones y publicación en tiendas. Respaldo manual no es sincronización.

## Datos pendientes de suministro

Nombres de categorías y fichas/fotos reales. El PIN inicial ya
fue suministrado y configurado localmente. Cargar contenido desde el panel, sin
inventar fichas ni incluir los fixtures sintéticos de QA en el catálogo.

## Definición de terminado

Implementación v2 trazable a estos criterios y verificada con pruebas significativas,
recuperación de datos y evidencia por plataforma. La evidencia v1 no aprueba MVVM,
sqflite, administración, credenciales, cámara, respaldos ni WhatsApp nuevos.
