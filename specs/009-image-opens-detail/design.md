# Diseño — Abrir detalle desde la imagen

Aplicada la skill local `flutter-product-design`. Conservar `Card.outlined`,
tokens, foto `cover` en marco 4:3, precios y disponibilidad existentes. Retirar
el botón «Ver detalle» y usar la imagen como acceso al detalle; no convertir
la tarjeta completa en un botón ni cambiar la selección.

## Componente y estados

Conservar la foto como base de un `Stack` y superponer `Material` transparente
con `InkWell` mediante `Positioned.fill`. Así foco, hover y pulsación se pintan
encima de la imagen opaca y resultan visibles, manteniendo recorte y tema de la
tarjeta sin añadir elevación. El área de imagen supera el mínimo táctil de 48 × 48 dp
en los layouts existentes; verificarlo en la revisión de pantalla compacta.
La imagen ausente/inválida mantiene fallback y sigue permitiendo abrir detalle.

Añadir semántica de botón con etiqueta `Abrir detalle de <nombre>` y una sola
acción de activación, evitando duplicar el nodo de botón. Conservar foco y
activación por teclado de `InkWell`. El checkbox «Incluir en catálogo PDF»
permanece fuera del área de navegación y actúa exclusivamente sobre selección.

## Adaptación y base Flutter

Conservar columnas, márgenes, medianiles, texto completo y temas actuales. Al
retirar el botón, la tarjeta reduce su altura naturalmente; no rellenar el hueco
ni añadir otra acción visual. No se cambian colores ni pares de contraste.

```dart
Semantics(
  button: true,
  label: 'Abrir detalle de ${product.name}',
  onTap: openDetail,
  child: Stack(
    children: [
      ProductPhoto(
        media: vm.services.media,
        image: product.images.firstOrNull,
        fit: BoxFit.cover,
      ),
      Positioned.fill(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: openDetail,
          ),
        ),
      ),
    ],
  ),
)
```

La integración debe comprobar que semántica y gesto produzcan un único destino
accesible, con retorno del detalle y selección independientes. Este bloque es
orientativo; no acredita una comprobación ejecutada.

El marco y altura del `Stack` derivan del `ProductPhoto` 4:3, sin otro control
visible. `Semantics.onTap` aporta la acción accesible; `excludeFromSemantics` en
`InkWell` evita duplicarla y mantiene activación por gesto, foco y teclado.
La alternativa textual de foto no disponible conserva su lectura.

## Referencia oficial

[Flutter InkWell](https://api.flutter.dev/flutter/material/InkWell-class.html)
explica que contenido opaco entre el Material y la reacción de tinta puede
ocultarla, y documenta la opción de un Material transparente encima del contenido.
