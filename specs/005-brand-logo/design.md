# Diseño — Identidad LegumPro

## Jerarquía y alcance

LOGO-AC-01: conservar la barra superior con título accesible «Catálogo LegumPro» y acceso a administración. Incorporar el logo completo en el primer bloque desplazable del catálogo, antes de compartir y buscar. Así acompaña la entrada al catálogo y se desplaza con el contenido. Mantener las posiciones relativas y separación de los controles existentes.

La imagen original tiene fondo oscuro y espacio alrededor del símbolo y la palabra. Mostrarla contenida en una cabecera compacta, centrada, con altura propuesta de 160 dp y ancho máximo 360 dp. Son decisiones de composición para este producto, no medidas obligatorias de M3. No estirar, cambiar sus colores ni recortar el contenido de la imagen dentro de la app. El bloque puede usar el mismo fondo oscuro de la imagen para evitar una discontinuidad visible; dejar 24 dp antes del botón de compartir. No convertir el logo en un botón.

LOGO-AC-02: el icono de inicio usa el símbolo vegetal de la imagen, sin el texto pequeño, centrado sobre el fondo oscuro original. Adaptación de tamaño y encuadre, sin rediseñar la identidad. Android debe proporcionar capas adaptativas de fondo y primer plano y versiones raster para dispositivos anteriores. Situar todo el símbolo en la zona segura central 66 × 66 de una capa de 108 × 108; comprobar máscaras circular y cuadrada redondeada. Recursos iOS opacos preparados, con validación en Xcode pendiente. [Guía oficial de iconos adaptativos Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

## Componentes, estados y tokens M3

La cabecera es contenido de marca estático, sin elevación ni sombra. Mantener la estructura existente de barra superior y sus acciones; conservar FilledButton para compartir, SearchBar y FilterChip con sus estados actuales. No añadir navegación ni funciones por la incorporación del logo. [App bars M3](https://m3.material.io/components/app-bars/overview).

| Elemento | Color | Tipografía / estado |
| --- | --- | --- |
| Barra y página | `surface`, `onSurface` existentes | `titleLarge` para el título, sin alterar escala |
| Imagen de marca | Colores originales de la imagen | Wordmark raster original; sin recrearlo como texto |
| Compartir / selección | `primary`, `onPrimary` existentes | `labelLarge`, estados habilitado / deshabilitado existentes |
| Buscar / categorías | Tokens actuales de SearchBar y FilterChip | Sin cambios de comportamiento ni contenido |
| Errores existentes | `error` | Texto de error ya implementado |

Mantener los esquemas claro y oscuro existentes; el fondo oscuro del logo es parte de la identidad suministrada y no reemplaza el token `surface` global. No introducir una paleta nueva ni tintar la fotografía.

## Adaptabilidad y accesibilidad

- Compacto: respetar margen de contenido de 16 dp; cabecera centrada que se reduce al ancho disponible. Los controles permanecen debajo y pueden envolver sus etiquetas.
- Mediano: margen existente de 24 dp, logo con ancho máximo 360 dp y misma altura. Mantener las dos columnas de productos cuando la escala de texto lo permita.
- Expandido: margen existente de 32 dp, contenido limitado a 1200 dp, logo centrado; no ampliar la marca hasta ocupar todo el catálogo. Medianil existente de 16 dp entre tarjetas.
- No fijar la altura de toda la fila de título, acciones o contenido textual. La imagen no depende de la escala de texto; títulos y botones mantienen su escalado.
- El logo tiene etiqueta semántica «Logo LegumPro» y no recibe foco como control. El título textual permanece disponible aun si falla la carga del asset. Evitar dos etiquetas para la misma imagen (`semanticLabel` y `Semantics` simultáneos).
- Mantener áreas táctiles de al menos 48 × 48 dp en los controles existentes. El logo estático no requiere área táctil.
- No se cambia ningún par de color de texto/fondo funcional. El contraste del wordmark raster no se declara medido; QA debe comprobar legibilidad visual sobre su fondo original en ambos temas. La validación de la imagen no acredita un nuevo análisis de contraste de todos los tokens.

## Código base Flutter

Integrar en el primer bloque del ListView, antes de compartir; el asset debe declararse en pubspec. El codificador puede ajustar la ruta y el color exacto al asset entregado.

```dart
Padding(
  padding: const EdgeInsets.only(bottom: 24),
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Image.asset(
        'assets/branding/legumpro_logo.jpg',
        height: 160,
        fit: BoxFit.contain,
        semanticLabel: 'Logo LegumPro',
      ),
    ),
  ),
)
```

`BoxFit.contain` conserva la relación de aspecto y muestra el contenido completo. [API oficial Flutter Image](https://api.flutter.dev/flutter/widgets/Image-class.html).

## Verificación a cargo de QA

Comprobar cabecera sin distorsión, sin desbordamiento a 320 dp y texto ampliado, en temas claro/oscuro; revisar logo y máscaras del icono y confirmar que reemplaza el predeterminado. LOGO-AC-03 y LOGO-AC-04 requieren regresiones y actualización del paquete normal en Android físico sin desinstalación. Este documento define el diseño; no afirma pruebas ejecutadas.
