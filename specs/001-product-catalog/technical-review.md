# Revisión técnica — SPEC-001 v2

Estado histórico: revisión previa a implementar. La implementación v2 ya está
integrada; consultar resultados actuales en `qa.md` y mapa de archivos en `plan.md`.
Las brechas descritas abajo corresponden a la base v1 y a esta revisión inicial.
Se leyeron spec, diseño, plan y QA v2. No se ejecutaron herramientas Flutter,
instalaron dependencias ni modificó código de aplicación en esta revisión.

## Base y brechas

La app v1 solo presenta productos de demostración en una pantalla y tema claro.
Su modelo tiene nombre, descripción y una ruta de asset; no persiste catálogo,
categorías, precios, fotografías privadas ni ajustes. `pubspec.yaml` solo declara
Flutter, flutter_test y flutter_lints. No existe aún la composición MVVM, SQL,
autenticación, navegación administrativa, respaldo o apertura externa de v2.
Las pruebas y APK v1 archivados no acreditan ninguno de estos comportamientos.

El alcance es técnicamente viable; requiere una ampliación estructural. La
inyección por constructor y ChangeNotifier/Listenable del plan permiten separar
Views, ViewModels, repositorios y servicios sin un contenedor DI adicional.
SQLite será fuente de verdad; emitir snapshots después del commit y reconciliar
selección/detalle evita consultar productos ocultos o datos de precios obsoletos.

## Dependencias propuestas y riesgos concretos

- sqflite es requerido. Los candidatos de archivos, cámara/galería, almacenamiento
  protegido, KDF, Unicode, CLP, URLs y ZIP/share del plan aún no están instalados
  ni fijados por versión. Comprobar compatibilidad y permisos nativos al elegirlos.
- Buscar sin acentos y unicidad normalizada requiere claves derivadas compartidas
  entre formulario/importación; no delegarlo a NOCASE. Constraints SQL y reglas
  transaccionales deben impedir huérfanos, SKU duplicado y ofertas inválidas.
- Cámara/galería entregan resultados temporales: copiar a medios privados y
  conservar borrador al bloquear sesión. Reautenticar y volver a autorizar antes
  de mutar; probar interrupción Android y vuelta de superficies nativas reales.
- HEIC/orientación, dimensiones y límites requieren un adaptador comprobado.
  Un paquete que seleccione fotos no demuestra conversión portable ni durabilidad.
- PIN inicial real sigue pendiente para distribución. Mantener verificador con
  sal/KDF en almacenamiento protegido; contador/plazo y rotación del código deben
  sobrevivir fallos sin reinicializar credenciales. Medir el coste KDF propuesto.
  El código mostrado intencionalmente debe ser legible también con lector de pantalla;
  no duplicarlo en etiquetas, logs, respaldo ni capturas de evidencia.
- WhatsApp debe abrir URL codificada con datos vigentes y confirmación del usuario
  en la app externa. Probar fallo/ausencia sin vaciar selección ni anunciar envío.

## Respaldo y coherencia

El plan mantiene una DB activa: prepara/promueve generación de medios antes de
reemplazar filas dentro de una transacción SQL. Hasta commit conserva catálogo
anterior; después recupera el nuevo completo. No sustituye archivo DB ni promete
atomicidad SQLite+archivos. Excluir credenciales, sus verificadores y sesión.
Validar ZIP/rutas/relaciones/precios/medios antes de confirmar; limpieza idempotente
solo borra huérfanos y respeta borradores. Probar cierre forzado, falta de espacio,
durabilidad de promoción, rollback y caída postcommit con SQLite/archivos reales.

Diseño y plan v2 son compatibles. Coordinación sincronizó QA con las propuestas
del plan (espera, KDF y límites), adoptadas como valores iniciales de planificación.
Su viabilidad práctica y mediciones pendientes se comprueban al implementar;
la adopción documental no es evidencia de prueba.
Claro/oscuro, accesibilidad, plugins, offline y restauración siguen sin validar.
Android e iOS necesitan evidencia separada; iOS requiere macOS con Xcode.
