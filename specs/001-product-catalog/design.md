# Diseño — SPEC-001 v2 · Catálogo local con administración

Estado: diseño implementado en `lib/features/` y `lib/ui/`; verificación por
plataforma y pendientes en `qa.md`.
Fuente: `spec.md` v2 y skill `.agents/skills/flutter-product-design/SKILL.md`.
El diseño v1 está archivado en `history/v1/`; su evidencia no valida estas pantallas.

## Identidad propuesta y tokens M3

Paleta reemplazable bosque/salvia/crema, sin marca definitiva suministrada:
semillas bosque `#315C38`, salvia `#7B8F71`, crema `#D8C9A7`. Generar esquemas
light/dark mediante `ColorScheme.fromSeed` y componer familias como el código
inferior. Los hexadecimales son semillas, no los colores finales generados.
No extraer colores del dispositivo ni agregar un selector de paletas.

| Roles en ambos esquemas | Origen tonal | Uso |
| --- | --- | --- |
| Primary/OnPrimary y PrimaryContainer/OnPrimaryContainer | Familia primary de bosque | Guardar, consultar, foco y selección |
| Secondary/OnSecondary y SecondaryContainer/OnSecondaryContainer | Familia secondary de salvia | Filtro de categoría seleccionado |
| Tertiary/OnTertiary y TertiaryContainer/OnTertiaryContainer | Familia primary de crema | Etiqueta textual «Oferta» |
| Surface y SurfaceContainerLowest/Low/normal/High/Highest | Neutrales de crema | Fondos cálidos, tarjetas, campos, diálogos y medios |
| OnSurface/OnSurfaceVariant, Outline/OutlineVariant | Neutrales de crema | Texto principal/secundario y límites |
| Error/OnError y ErrorContainer/OnErrorContainer | Familia error de bosque | Errores de validación/operación con explicación textual |

Dark genera superficies cálidas oscuras y contenido claro; no invertir fotografías.
«Consultar por WhatsApp» usa Primary, sin sustituirlo por un botón de otra marca.
Agotado, oculto y oferta siempre tienen etiqueta; no depender solo del color.
Fuente: [roles M3](https://m3.material.io/styles/color/roles) y
[ColorScheme.fromSeed](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html).

Tipografía `TextTheme`: `headlineSmall` detalle 24/32, `titleLarge` encabezado 22/28,
`titleMedium` tarjeta/secciones 16/24, `bodyLarge` descripción/campos 16/24,
`bodyMedium` metadatos/ayuda 14/20, `labelLarge` botones 14/20. Valores nominales
(tamaño/altura dp); respetar escala del sistema. Display no es necesario. Sin
fuentes remotas. [Tipografía M3](https://m3.material.io/styles/typography/applying-type),
[TextTheme Flutter](https://api.flutter.dev/flutter/material/TextTheme-class.html).
Espaciado 4/8/12/16/24/32dp. `Card.outlined` radio 12/elevación 0; formularios sin
sombras. App bar elevación 0 en reposo; respuesta tonal de scroll M3. Diálogos y
bottom sheets usan forma/elevación del tema M3; no sombras personalizadas.

## Pantallas y flujos

Catálogo público → detalle o selección; «Administrar» siempre disponible → PIN →
panel con destinos Productos/Categorías/Ajustes. Navegar fuera del panel o pasar a
segundo plano cierra sesión. Views representan estado/comandos del ViewModel;
no leen SQL/archivos/secretos. El panel no introduce onboarding en el catálogo.

### Catálogo — V2-AC-01,09–11,13,16,23

Encabezado «Catálogo Legum», entrada «Administrar». `SearchBar` etiquetada
«Buscar por nombre, descripción o SKU», con limpiar búsqueda. Debajo `FilterChip`
«Todas» y categorías ordenadas en `Wrap`, uno seleccionado; búsqueda y categoría
se combinan según spec. Lectura inicial SQLite: progreso local etiquetado; error
persistente con Reintentar, nunca falso vacío.

Tarjeta: portada 4:3/contain, nombre completo, presentación, precio vigente CLP,
etiqueta Disponible/Agotado. Oferta: «Oferta», precio normal tachado y precio
rebajado, cada uno con etiqueta semántica explícita. Formato entero `$12.000 CLP`
(ejemplo de formato, no ficha precargada). Descripción completa vive en detalle.
Área Ver detalle separada de checkbox «Seleccionar [nombre]»; evitar anidar
controles en un nodo semántico único de botón. Agotados seleccionables; ocultos
excluidos. Barra inferior segura «Ver selección (n)» aparece con selección.
Vacío limpio «No hay productos disponibles»; sin coincidencias «No se encontraron
productos» y Limpiar filtros (restablece búsqueda y categoría). Sin datos demo.

### Detalle y WhatsApp — V2-AC-08–10,12–15

Detalle con volver: galería, nombre, presentación, estado, precios, categoría,
SKU, descripción completa, selección y Consultar por WhatsApp. Galería anuncia
«Foto x de n», miniaturas y controles anterior/siguiente: swipe complementario,
no única vía. Imágenes contain, sin deformar; placeholder «Imagen no disponible»
conserva marco y texto. Sin truncar descripción ni cantidades/stock numérico.
Selección temporal lista nombre/SKU/presentación/precio vigente/estado y Quitar;
CTA Consultar selección. Actualizar datos vigentes y retirar ocultos/eliminados.
No llamarla carrito/pedido. Aviso «Se abrirá WhatsApp con un mensaje preparado.
Confirma el envío allí; requiere conexión». Número ausente/inválido explica motivo
sin lanzar servicio y remite a Administración. Fallo conserva selección; nunca
mostrar «Enviado» por abrir WhatsApp. La app no envía automáticamente.

### PIN y recuperación — V2-AC-02–04

Acceso desplazable: PIN de4 dígitos en campo único oculto, teclado numérico,
conservar ceros iniciales; Entrar/Recuperar acceso/Volver. No publicar PIN real.
Errores inline y foco en error; espera muestra tiempo restante conforme al plan,
sin anuncio cada segundo. Credenciales nunca aparecen en logs/respaldos.
Primer acceso correcto: paso obligatorio para guardar código generado fuera de
la app y confirmación «He guardado el código». Cancelar sale; retomar siguiente
acceso. Sin copia automática al portapapeles. Recuperación: código/nuevo PIN/
confirmación; conserva catálogo e invalida código usado, muestra sustituto.
Cambio normal exige PIN actual y confirmación del nuevo; nunca mostrar vigente.

Al volver del segundo plano se exige PIN antes de revelar panel/ejecutar comandos.
Cámara/galería/selector/compartición nativa también pueden provocar relock:
conservar borrador y medios pendientes en memoria, retomar solo tras autenticación.
No guardar automáticamente ni perder formulario por denegar/cancelar permisos.

### Administración — V2-AC-05–10,13,16

Productos: lista con etiquetas separadas Público/Oculto y Disponible/Agotado;
Añadir producto (`FilledButton` en cabecera), editar, eliminar con diálogo y ordenar.
Arrastre con handle48 dp más Subir/Bajar accesibles. No FAB redundante.
Formulario de una columna: nombre, descripción multilínea, SKU, presentación,
categoría única (`DropdownMenu`), precio normal CLP, switch En oferta y precio
oferta condicional, switches separados de disponibilidad y visibilidad. Validación
inline y resumen al guardar; foco primer inválido. Precio entero>=0, oferta menor
que normal, SKU único, categoría existente y al menos una foto. Sin categorías,
explicar crear una antes de guardar; no crearla automáticamente.

Fotos: Añadir fotos → bottom sheet M3 Cámara/Galería; cámara una por captura y
selector múltiples. Miniaturas con posición, Portada en primera, quitar y
Subir/Bajar; arrastre opcional. Cancelación/permisos conserva borrador. Recursos
inválidos muestran alternativa. Guardar muestra progreso local y evita doble envío;
no éxito antes de completar. Cancelar con cambios pide descartar y revierte borrador
completo. El servicio gestiona medios privados/limpieza; widgets no manipulan rutas.
Categorías: CRUD y orden; nombre único; eliminación usada bloqueada con «Reasigna
o elimina sus productos primero». Sin borrado en cascada ni cambio parcial.

### Ajustes y respaldos — V2-AC-14,17–20

Número WhatsApp internacional con ayuda/validación; radios Sistema/Claro/Oscuro,
Sistema inicial y elección persistida; cambiar PIN, exportar/importar y Salir.
Exportación explica catálogo/categorías/orden/fotos/WhatsApp/tema incluidos y
PIN/código/sesión excluidos. Progreso real, cancelación/error sin falso éxito.
Importar → selector → validar con progreso → resumen de categorías/productos/fotos
→ confirmación «Reemplazará todo el catálogo de este dispositivo. No combinará
datos. El PIN y código de recuperación se conservan». Botones Cancelar/Reemplazar
catálogo. Inválido/incompatible/falta de espacio conserva anterior. Durante commit
impedir doble envío/salida accidental, sin porcentajes ficticios. Tras interrupción,
mostrar recuperación y resultado coherente del servicio. Éxito refresca vistas/tema/
WhatsApp y vacía selección, sin desbloquear panel. Staging/transacción y límites
son responsabilidad técnica del plan; UI no reemplaza antes de validar/confirmar.

## Layout y accesibilidad — V2-AC-20–21,23

| Ventana disponible | Composición propuesta |
| --- | --- |
| Compacta <600dp | Margen16; catálogo/detalle/formulario una columna; panel con menú de destinos |
| Media 600–839dp | Margen24/gutter16; catálogo dos columnas; detalle/formulario centrados max720; panel menú |
| Expandida >=840dp | Margen32/gutter24; catálogo dos columnas en max1200; NavigationRail de tres destinos administrativos; formulario max720/detalle max800 |

A escala>=1.5 catálogo vuelve a una columna max720 en cualquier ventana. Usar filas
con tarjetas de altura natural alineadas arriba, sin grid de altura fija. Clasificar
ancho de ventana, no hardware. Header intrínseco mínimo 64 dp y título envuelto;
acciones secundarias pasan a menú si no caben. Barra de consulta/guardar crece con
texto, usando Wrap/botón de ancho completo. Son decisiones del proyecto sobre M3,
no obligaciones oficiales. SafeArea/scroll/padding inferior y teclado contemplados.

Controles>=48×48 dp, incluidos iconos, fotos y reordenar; icono 24 no reduce hit target.
Orden lector: título, búsqueda/filtro, productos; en detalle, galería y ficha.
Fotos decorativas de tarjeta excluidas; galería anuncia nombre/posición una vez.
Estados de checkbox/chips/switches explícitos, errores vinculados al campo y live
region relevante sin duplicación ni lectura de secretos. Mover elemento conserva
foco. Texto completo sin elipsis; etiquetas distinguen normal/oferta/oculto/agotado.

**Contraste:** la suite host mide 12 pares de tokens en ambos esquemas. Para
ampliar cobertura, calcular también los colores reales de cada nuevo estado:
`(Lmax+0.05)/(Lmin+0.05)` usando computeLuminance. Exigir 4.5:1 para texto normal,
3:1 para indicadores/límites esenciales. Pares: primary/onPrimary y container;
secondary/tertiary y containers; surface y cada container usado con onSurface/
onSurfaceVariant; error/onError y container. No declarar medición por fromSeed.
La suite cubre catálogo/detalle a 320dp y escala2; quedan pendientes otras
combinaciones 320/390dp×escala1/2,600/840, lectores, teclado y permisos físicos.
La evidencia de ejecución Android/iOS se registra por separado en `qa.md`.

## Código Flutter documental: tema

No modifica app. Trasladar familias usadas juntas; no usar roles Fixed sin completar
su familia correspondiente y verificarlos. Estado ThemeMode proviene del ViewModel.

```dart
ColorScheme catalogScheme(Brightness brightness) {
  ColorScheme seeded(int color) => ColorScheme.fromSeed(
    seedColor: Color(color), brightness: brightness,
  );
  final forest = seeded(0xFF315C38);
  final sage = seeded(0xFF7B8F71);
  final cream = seeded(0xFFD8C9A7);
  return forest.copyWith(
    secondary: sage.secondary, onSecondary: sage.onSecondary,
    secondaryContainer: sage.secondaryContainer,
    onSecondaryContainer: sage.onSecondaryContainer,
    tertiary: cream.primary, onTertiary: cream.onPrimary,
    tertiaryContainer: cream.primaryContainer,
    onTertiaryContainer: cream.onPrimaryContainer,
    surface: cream.surface, onSurface: cream.onSurface,
    onSurfaceVariant: cream.onSurfaceVariant,
    surfaceDim: cream.surfaceDim, surfaceBright: cream.surfaceBright,
    surfaceContainerLowest: cream.surfaceContainerLowest,
    surfaceContainerLow: cream.surfaceContainerLow,
    surfaceContainer: cream.surfaceContainer,
    surfaceContainerHigh: cream.surfaceContainerHigh,
    surfaceContainerHighest: cream.surfaceContainerHighest,
    outline: cream.outline, outlineVariant: cream.outlineVariant,
    inverseSurface: cream.inverseSurface,
    onInverseSurface: cream.onInverseSurface,
  );
}
ThemeData catalogTheme(Brightness brightness) => ThemeData(
  useMaterial3: true, colorScheme: catalogScheme(brightness),
);
// MaterialApp(theme: catalogTheme(Brightness.light),
//   darkTheme: catalogTheme(Brightness.dark), themeMode: persistedThemeMode,
//   home: catalogView);
// persistedThemeMode: ThemeMode.system / light / dark.
```

## Trazabilidad de diseño: resultados de ejecución en qa.md

| ID | Flujo/verificación |
| --- | --- |
| V2-AC-01 | Vacío limpio, acceso panel visible |
| V2-AC-02 | PIN, cambio y espera temporal |
| V2-AC-03 | Configuración/recuperación, sustitución código, catálogo conservado |
| V2-AC-04 | Rutas protegidas, relock y borrador tras selector |
| V2-AC-05 | Categorías, duplicados, bloqueo eliminación usada, orden |
| V2-AC-06 | Validación producto y borrador atómico |
| V2-AC-07 | Cámara/galería, permisos, orden/portada |
| V2-AC-08 | Placeholder, limpieza y fotos vigentes intactas |
| V2-AC-09 | Oculto separado de agotado y selección actualizada |
| V2-AC-10 | CLP/oferta válida etiquetada y precios normales |
| V2-AC-11 | Búsqueda combinada y vacíos distintos |
| V2-AC-12 | Ficha completa y galería alcanzable |
| V2-AC-13 | Orden/refresco sin reinicio |
| V2-AC-14 | Número y mensaje individual/conjunto vigentes |
| V2-AC-15 | Fallo externo y envío confirmado fuera de app |
| V2-AC-16 | Flujos locales sin red y persistencia tras reiniciar |
| V2-AC-17 | Respaldo completo sin secretos |
| V2-AC-18 | Validación/resumen/confirmación y reemplazo sin mezcla |
| V2-AC-19 | Error/interrupción conserva coherencia catálogo/medios |
| V2-AC-20 | Tema persistido, contraste y48 dp medidos |
| V2-AC-21 | Pantallas críticas, semántica, escalas y teclado |
| V2-AC-22 | Views/ViewModels/servicios separados, pruebas técnicas del plan |
| V2-AC-23 | Recorrido 5 categorías/20 productos; no son límites máximos |
| V2-AC-24 | Evidencia por plataforma; historial v1 no certifica v2 |

No inventar PIN/número/fichas reales. Ningún resultado anterior está certificado.
Fuentes: [Cards M3](https://m3.material.io/components/cards/overview),
[Search M3](https://m3.material.io/components/search/overview),
[Dialogs M3](https://m3.material.io/components/dialogs/overview),
[breakpoints M3](https://m3.material.io/foundations/layout/breakpoints/overview),
[ventanas Google](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes),
[accesibilidad Flutter](https://docs.flutter.dev/ui/accessibility),
[ThemeMode](https://api.flutter.dev/flutter/material/ThemeMode.html).
Las páginas M3 consultadas requieren JavaScript; mezcla de semillas y layouts
concretos se identifican como propuestas del proyecto, no citas de reglas oficiales.

## Ajuste de separación de formularios — 2026-10-08

Para V2-AC-20 y V2-AC-21, separar visualmente los campos y las acciones de
administración con 24 dp de espacio vertical fijo, también cuando no hay mensajes
de error. Aplicar a acceso/recuperación, confirmación del código, categoría,
WhatsApp y cambio de PIN. En producto, separar el grupo de fotos de sus acciones
y la acción de guardar con 24 dp; dejar 8 dp entre botones apilados de acceso,
producto y respaldo. Son decisiones de composición del proyecto dentro de M3,
sin cambios en colores, tipografía, componentes ni áreas táctiles de 48 dp.

El espacio no depende del contenido de `ErrorMessage`; los errores conservan su
presentación y anuncio accesible. Las comprobaciones ejecutadas se registran en
`qa.md`; esta nota de diseño no acredita una validación física nueva.

