# Plan — SPEC-001 v2

Estado: implementación v2 integrada. Evidencia ejecutada y pendientes en `qa.md`.
La evidencia anterior permanece en `history/v1/`, sin aprobar V2-AC.
Fuente funcional: `spec.md`; interfaz: `design.md`; verificaciones: `qa.md`.
Coordinación adoptó las propuestas técnicas siguientes como valores iniciales de
planificación, sin considerarlas verificadas. Compatibilidad, coste KDF, contraste
y durabilidad se comprueban durante implementación y cualquier ajuste se documenta.

## Arquitectura y archivos

Correspondencia final: `lib/contracts.dart` contiene contratos inyectables;
`lib/models/catalog_models.dart` agrupa modelos; `lib/app/bootstrap.dart` compone
los servicios. `lib/data/sql_catalog_repository.dart` reúne esquema/consultas/
transacciones sin DAO separado; autenticación está en `lib/data/auth/`, enlaces
en `lib/data/whatsapp/`, medios y respaldos en servicios de `lib/data/`.
Views y ViewModels están en `lib/features/`, tokens/widgets M3 en `lib/ui/`.
Las rutas, lifecycle y guardia visual viven en `features/catalog_app.dart`.
Esta agrupación conserva las responsabilidades MVVM del plan siguiente.

La composición exige sesión y recuperación confirmada para mutaciones/backups.
Un token por transición de sesión cancela comandos iniciados antes del bloqueo,
incluso si otra autenticación ocurre durante su espera. Los ZIP compartidos con
éxito se retienen para el receptor y se limpian al arranque tras 24 horas;
compartición fallida/cancelada limpia inmediatamente. La limpieza posterior al
commit es best effort y se reintenta al inicio sin declarar rollback inexistente.

MVVM con inyección por constructor, comandos asíncronos y ChangeNotifier/Listenable;
no añadir gestor externo, contenedor DI ni capa genérica de casos de uso.
Views presentan estado y emiten acciones; ViewModels mantienen formularios, filtros,
selección y comandos; repositorios validan/persisten y publican snapshots; servicios
aíslan plataforma. Referencia: [guía Flutter](https://docs.flutter.dev/app-architecture/guide).

- `lib/app/`: composición, rutas protegidas, lifecycle y temas M3.
- `lib/models/`: Category, Product, ProductImage, Settings, ProductDraft y BackupManifest.
- `lib/data/local/`: DatabaseService versionado y CatalogDao con SQL/transacciones.
- `lib/data/services/`: MediaService, PickerService, SecureCredentialService,
  ExternalLinkService y BackupFileService.
- `lib/data/repositories/`: CatalogRepository, SettingsRepository, AuthRepository
  y BackupRepository. Compartir validador puro entre edición e importación; no
  duplicar reglas ni hacer llamadas circulares entre repositorios.
- `lib/features/<catalog|detail|selection|auth|admin|settings|backup>/`: pares
  View/ViewModel. Ningún widget accede a SQL, archivos privados o credenciales.
- `test/` para lógica/widgets; `integration_test/` para plugins y recuperación reales.

SQLite es fuente de verdad; emitir cambios después de commit. Reconciliar selección
con IDs públicos vigentes y volver a consultar datos antes de preparar WhatsApp.
Actualización v1→v2 inicia vacío: v1 no guardaba fichas editables y no se migran sus
assets demo. Nuevas instalaciones sin seed. Cambios de esquema nunca borran datos
ante errores. PIN real y número faltantes no bloquean documentos; PIN se requiere
antes de distribuir y ningún valor real se publica aquí.

## Esquema mínimo sqflite

Una sola DB activa, `user_version=1` inicial (independiente de versión del spec).
Medios privados externos a SQL, con paths relativos generados por la app.

| Tabla | Columnas y restricciones |
| --- | --- |
| categories | id TEXT PK, name TEXT NOT NULL, name_key TEXT NOT NULL UNIQUE, sort_order INTEGER NOT NULL CHECK >=0 |
| products | id TEXT PK, category_id TEXT NOT NULL FK categories(id) ON DELETE RESTRICT, name/description/sku/presentation TEXT NOT NULL, sku_key TEXT NOT NULL UNIQUE, search_key TEXT NOT NULL, normal_clp INTEGER NOT NULL CHECK >=0, sale_clp INTEGER NULL CHECK >=0 AND <normal_clp, available/visible INTEGER NOT NULL CHECK IN(0,1), sort_order INTEGER NOT NULL CHECK >=0 |
| product_images | id TEXT PK, product_id TEXT NOT NULL FK products(id) ON DELETE CASCADE, relative_path TEXT NOT NULL UNIQUE, sort_order INTEGER NOT NULL CHECK >=0, UNIQUE(product_id,sort_order) |
| settings | singleton INTEGER PK CHECK=1, whatsapp TEXT NULL, theme_mode TEXT CHECK IN('system','light','dark') |

Activar FK por conexión e índices products(category_id,visible,sort_order) y
product_images(product_id,sort_order). Validar no vacíos y mínimo una imagen en
repositorio/importación. CLP enteros no negativos: rechazar decimales y coerciones;
propuesta rango portable JSON hasta 9.007.199.254.740.991. Oferta estrictamente menor.

Orden global de productos, estable también filtrado; categorías independientes.
Ordenar por (sort_order,id), renumerar transaccionalmente. Primera imagen es portada;
reordenarla con posiciones temporales para respetar UNIQUE.

Conservar texto original y claves derivadas: SKU sin caso; categoría y búsqueda
con normalización Unicode, eliminación de diacríticos y minúsculas. search_key
concatena nombre/descripción/SKU. Buscar substring parametrizado, escapando LIKE,
AND categoría y visible=1. Recalcular claves de importación, sin confiar en claves
externas ni NOCASE SQLite para acentos. No FTS para este volumen.

Migraciones onCreate/onUpgrade explícitas y pruebas por versión soportada; versión
futura incompatible conserva datos e informa. Dentro de transacción usar su objeto,
no otra conexión. Ver [sqflite](https://pub.dev/packages/sqflite).

## Medios, borradores y sesión

Galería múltiple y cámara una foto por acción repetible. Copiar a staging privado
por borrador; no depender de rutas temporales ni modificar originales de galería.
Normalizar copias a JPEG/PNG legibles Android/iOS, incluyendo orientación; si formato
como HEIC no puede convertirse con herramientas verificadas, rechazar explicando
sin perder borrador. No añadir edición avanzada. Propuestas de límites: 20 MiB y
40 megapíxeles por imagen; comprobar tamaño y dimensiones antes de decodificar.
Medir conversión en plataformas antes de elegir paquete.

Guardar prepara/promueve nuevas imágenes inmutables, luego transacciona producto
más referencias. Fallo SQL mantiene anteriores y limpia nuevos huérfanos. Cancelar
borra solo staging propio. Eliminar medios antiguos únicamente después de commit;
GC idempotente consulta referencias vigentes, sin tocar borradores activos.

Cámara/galería/share pueden pausar app: cerrar sesión siempre, preservar formulario
y selección; al regresar exigir PIN antes de comandos administrativos. Cancelar PIN
vuelve al público sin borrar borrador. Revalidar sesión antes de commit, no solo al
abrir pantalla. Recuperar resultados perdidos Android y asociarlos al borrador;
no guardarlos sin reautenticar. [image_picker](https://pub.dev/packages/image_picker)
documenta archivos temporales y retrieveLostData. Permisos/cancelación no descartan
formularios. Revocación de sesión durante operación previa al commit cancela cambios.

## Propuestas técnicas de autenticación

PIN cadena de cuatro dígitos preservando ceros iniciales. Almacenamiento protegido
con sobre versionado: verificadores con sal aleatoria y parámetros KDF, estado de
configuración, contador y plazo de bloqueo. Nunca PIN/código plano en DB, logs,
backup o fixtures reales. KDF auditada: propuesta PBKDF2-HMAC-SHA256, 600.000
iteraciones iniciales sujetas a medición móvil, comparación constante; no criptografía
propia. Escribir sobre completo de forma coherente; fallo secure storage bloquea,
no reinicializa credenciales ni borra catálogo.

Primer acceso correcto muestra código aleatorio de recuperación de 128 bits Base32
agrupada; aceptar mayúsculas/minúsculas y separadores de presentación. Confirmar
custodia antes de activar configuración; cancelar retoma paso generando otro código.
Guardar solo verificador. Recuperación válida prepara PIN nuevo y código sustituto,
lo muestra para custodiar y confirma antes de reemplazar el sobre; error/cancelación
conserva anterior. Éxito invalida código usado y cierra sesión. Cambio normal exige
PIN actual y confirmación doble del nuevo.

Política propuesta: 5 fallos consecutivos de PIN o recuperación→espera30s; cada fallo
posterior a espera duplica hasta15min. Éxito válido reinicia contadores. Contador/plazo
persisten ante reinicio; conservar máximo reloj observado para que retrasarlo no
acorte espera. Probar relojes y no asumir reloj local invulnerable. Sesión en memoria,
revocada al salir o pausar. Guardia compartida en rutas y todas las mutaciones,
configuración, exportación/importación. Referencia de plataforma:
[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), revisar
opciones, backups del sistema y fallos con la versión elegida.

## Respaldo portable y recuperación DB + archivos

Propuesta ZIP con manifest.json UTF-8 format_version=1, datos lógicos, orden,
WhatsApp/tema y medios JPEG/PNG. No copiar DB/WAL ni secretos/sesión. Declarar
size/SHA-256 por medio para detectar corrupción, sin afirmar autenticidad/cifrado.
Exportar snapshot bajo exclusión de escrituras, terminar copia privada y liberar
bloqueo antes de compartir. Cleanup al cancelar/fallar.

Límites propuestos: archivo500MiB, expansión1GiB, manifest5MiB, 10.000 entradas,
1.000 categorías/5.000 productos/9.000 imágenes; por imagen límites anteriores y
ratio expansión máximo100:1. Son límites del respaldo, no del catálogo estimado.
Exportación sobre límite informa sin archivo incompleto. Validar en streaming antes
y durante extracción; rechazar symlinks, rutas absolutas/.., duplicados, medios no
declarados/faltantes, hash/tamaño incorrectos, relaciones/IDs/SKU/precios inválidos,
versión incompatible. Recalcular claves, validar ajustes y decodificar imágenes.
Reserva propuesta: tamaño expandido+20%+50MiB libres; no borrar previo para hacer
espacio. Si consulta de espacio no disponible, capturar fallos de escritura durante
staging y abortar antes de commit, conservando activo.

Algoritmo de reemplazo, con exclusión mutua frente a escrituras/exportación:

1. Exigir sesión, copiar a staging privado, validar y mostrar resumen; cancelar no
   cambia nada. No aceptar rutas del archivo como destinos privados.
2. Tras confirmar y revalidar sesión, extraer/validar todos los medios a generación
   nueva. Promover carpeta completa e inmutable dentro del mismo volumen ANTES
   de modificar SQL. Si promoción/validación falla, mantener catálogo anterior.
3. Una transacción sqflite reemplaza categorías/productos/imágenes/ajustes: borrar
   hijos antes de padres, insertar padres antes de hijos, validar FK y reglas.
   Las nuevas filas apuntan a archivos que ya existen. Credenciales receptoras
   no participan. Commit SQL es punto de cambio; FS no pertenece a esa transacción.
4. Antes de commit, cualquier fallo/interrupción conserva filas/medios viejos.
   Después, filas nuevas apuntan a medios preparados; al reiniciar reconstruir
   vistas desde SQL, vaciar selección y aplicar ajustes. No interpretar una caída
   postcommit como importación cancelada. Reabrir/verificar antes de anunciar éxito.
5. Conservar medios antiguos hasta commit y validación; luego GC por referencias.
   Crash/cleanup fallido solo deja huérfanos; reintentar al arranque sin borrar
   activos ni borradores. Si falla validación previa al commit, rollback SQL; nunca
   compensar borrando datos previos. Un error inesperado después de commit no
   permite fingir rollback SQL: detener nuevas escrituras y conservar archivos
   para diagnóstico/recuperación, sin crear catálogo vacío.

Reimportar mismo archivo es otro reemplazo confirmado, sin merge ni duplicación.
Pruebas de interrupción antes/después de cada fase, corrupción, falta de espacio,
fallos SQL/FS, reapertura y limpieza repetida. Verificar durabilidad de escrituras y
promoción en Android/iOS; si no garantizada no activar ni declarar restauración
validada. Recuperación SQLite real se comprueba en integración, no solo con fakes.

## Dependencias y entrega

Requerido sqflite; candidatos sin versiones fijadas: path_provider/path, image_picker,
flutter_secure_storage, KDF auditada, normalización Unicode, intl, url_launcher,
archive u otro ZIP streaming, selector de archivos y exportación/share; conversión
de medios solo si hace falta. Verificar compatibilidad SDK, permisos, plataformas y
licencias antes de modificar pubspec. No paquetes de red/backend/sincronización.

Diseño M3 v2 entregado: paleta propuesta bosque/salvia/superficies cálidas, claro/
oscuro/sistema, tokens/componentes, errores, estados y accesibilidad. Catálogo con
una columna y margen16 en compacto; dos columnas y margen24 en medio; dos columnas,
máximo1200 y margen32 en expandido. Texto a escala>=1.5 vuelve a una columna máximo720.
Panel puede usar rail en expandido; seguir design.md para cada pantalla.
No reutilizar descripción completa en tarjeta v1: ahora
pertenece al detalle. Medir contraste real y verificar controles48dp, 320/390
escala1/2 y 600/840; comprobar ambos esquemas y TalkBack/VoiceOver.

Incrementos/dependencias en tasks.md. Pruebas por incremento: validadores,
DAO/migraciones, repositorios/ViewModels, widgets y plugins reales. Dataset5/20
solo en tests. QA verifica offline, lifecycle, permisos, recuperación, mensajes y
fallos externos. Formato/análisis/tests y recorridos Android/iOS con evidencia
separada; iOS requiere macOS/Xcode. No se ejecutaron verificaciones v2 en esta fase.
