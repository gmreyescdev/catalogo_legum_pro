# Plan — SPEC-005

## Incrementos

1. T01: fijar cabecera e iconos como alcance, con LOGO-AC-01..04. El diseñador
   aplica la skill local M3 y documenta proporción, tamaño y adaptación en
   `design.md`. Conservar el logo completo aportado como asset y usar una
   derivación del símbolo sin texto para el launcher.
2. T02 depende de T01: incorporar el asset original en `assets/branding/` y
   declararlo en `pubspec.yaml`. Integrar la cabecera en
   `lib/features/public_views.dart`, respetando proporciones, contraste en ambos
   temas, controles existentes y ventanas compactas. No cambiar PDF, esquema,
   credenciales ni servicios.
3. T03 depende de T01: generar recursos launcher desde el símbolo derivado.
   Sustituir PNG por densidad en `android/app/src/main/res/mipmap-*`, añadir
   icono adaptativo con fondo y primer plano en los recursos Android y conservar
   compatibilidad anterior a API 26. Actualizar todos los tamaños declarados por
   `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`, incluido 1024 px
   opaco. No añadir dependencias de ejecución para una sustitución de assets.
4. T04 depende de T02/T03: QA inspecciona cabecera, límites de recorte del icono,
   densidades Android y correspondencia de recursos iOS. Ejecutar formato,
   análisis y pruebas pertinentes de regresión existentes; registrar resultados
   reales en `qa.md`. La inspección no acredita ejecución en dispositivo.
5. T05 depende de T04: compilar APK normal con la configuración local existente,
   verificar applicationId de producción e instalar mediante `adb install -r`
   en Android físico. Inspeccionar resultado antes de abrir la app. Comprobar
   cabecera e icono y registrar evidencia; no desinstalar ni usar emulador.
   Recursos iOS preparados no equivalen a compilación o validación con Xcode.

## Verificación y límites

- LOGO-AC-01: logo completo reconocible, sin estirar ni cubrir botones en claro
  y oscuro; comprobar la cabecera con navegación, búsqueda y selección.
- LOGO-AC-02: icono propio legible sin texto pequeño, máscaras Android sin
  recortar el símbolo central y recursos iOS con tamaños declarados correctos.
- LOGO-AC-03: la revisión del diff confirma cambios visuales y de recursos; las
  regresiones existentes cubren filtros, selección y PDF. La instalación por
  actualización conserva el paquete y no garantiza recuperar datos borrados
  previamente.
- LOGO-AC-04: build normal e instalación física verificados separadamente.
  Cualquier integración futura usa exclusivamente el paquete aislado
  `com.example.catalogo_legum_pro.integration`, comprobado antes de instalar.
  No hace falta ejecutar integración nativa para sustituir imágenes.

## Propiedad de archivos

Coordinador: `spec.md`, integración y ejecución de comandos. Diseñador:
`design.md`. Planificador: `plan.md` y `tasks.md`. Codificador: asset, cabecera,
declaración Flutter y recursos de plataformas. QA: `qa.md` y revisión. No editar
archivos asignados a otro rol simultáneamente.
