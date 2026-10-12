# Diseño — Cabecera compacta LegumPro

## Jerarquía y componentes

Aplicar la skill local `flutter-product-design`. La cabecera existente de `PageFrame` mantiene el patrón de título y acciones de una barra superior M3, con fondo `surface`, elevación cero y sin nueva tarjeta. Se incorpora un leading opcional únicamente en el catálogo: símbolo circular de 40 dp, separación de 12 dp, título flexible. Las acciones existentes siguen debajo y conservan sus estados habilitado/deshabilitado. El logo no actúa como botón.

El círculo de 40 dp es una decisión de marca acordada para este proyecto, no una medida obligatoria M3. La imagen conserva su proporción con `BoxFit.contain`, el círculo recorta únicamente el marco exterior y evita mostrar esquinas cuadradas. El cuerpo inicia con compartir catálogo y búsqueda, eliminando el bloque de 160 dp.

## Tokens

| Elemento | Token |
| --- | --- |
| Fondo cabecera | `colorScheme.surface` |
| Título | `textTheme.titleLarge`, contenido `colorScheme.onSurface` |
| Símbolo | Colores originales del asset, sin recolorear |
| Acciones existentes | Tema M3 actual, sin redefinir Primary/Secondary/Tertiary/Error |

## Adaptación y accesibilidad

Conservar márgenes de cabecera 16 dp horizontales y 8 dp verticales. La fila tiene símbolo fijo y título `Expanded`, sin `maxLines` ni elipsis. Permitir crecimiento vertical. Para ventanas compactas (<600 dp), medianas (600–839 dp) y expandidas (≥840 dp), conservar esta misma cabecera; la grilla del catálogo mantiene sus columnas, márgenes 16/24/32 dp y medianiles actuales. No introducir una navegación adicional.

Excluir el símbolo de semántica porque el título ya identifica la marca. Mantener `Semantics(header: true)` sobre el título. El símbolo no requiere área táctil de 48 dp porque no es interactivo; las acciones conservan ese mínimo. Verificar ausencia de overflow a 320 dp y escala de texto 2, y claro/oscuro. No se declara un contraste numérico nuevo validado: se conservan los pares de tokens existentes y queda la inspección visual para QA.

## Base Flutter orientativa

```dart
Row(
  children: [
    ClipOval(
      child: Image.asset(
          'assets/branding/legumpro-icon.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          semanticLabel: 'Logo LegumPro',
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Semantics(
        header: true,
        child: Text(
          'Catálogo LegumPro',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  ],
)
```

Integrar mediante leading opcional de `PageFrame`, conservando su comportamiento cuando no se aporta leading y su botón de volver cuando corresponda.

## Referencias oficiales consultadas

- [Barras superiores M3](https://m3.material.io/components/app-bars/overview): referencia de anatomía y jerarquía. La página exige JavaScript en el lector; no se atribuyen medidas específicas a su contenido inaccesible.
- [Flutter ClipOval](https://api.flutter.dev/flutter/widgets/ClipOval-class.html): recorte oval del área del widget.
- [Flutter Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html): asignación del espacio restante de la fila al título.
