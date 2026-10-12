# Diseño — SPEC-002: catálogo PDF seleccionado

Skill aplicada: `.agents/skills/flutter-product-design/SKILL.md`. Flutter con
Material Design 3, conservando la identidad bosque/salvia/crema de SPEC-001.
Decisiones de este documento son la propuesta del producto; no todas son reglas M3.

## Jerarquía y recorrido

PDF-AC-01/02/04/06: las tarjetas públicas conservan nombre, portada, presentación,
precios y disponibilidad; el checkbox se llama «Incluir en catálogo PDF».
«Ver selección (N)» abre la revisión. El detalle permite incluir/quitar y abrir esa
misma revisión; nunca comparte directamente un producto ajeno a la selección.

La revisión «Catálogo PDF seleccionado» presenta solo productos públicos vigentes,
en orden de catálogo. Cada tarjeta muestra nombre, portada, presentación, precio
CLP vigente (normal y oferta cuando corresponda), disponibilidad textual y acción
«Quitar [nombre]». La descripción y el SKU siguen disponibles en el detalle,
pero no pertenecen al contenido exportado.

Antes de «Compartir catálogo PDF» se explica: «El PDF incluye solo esta selección,
con imagen, presentación, precio y disponibilidad. Elige WhatsApp y el cliente en
el menú para compartir; confirma el envío allí». La app no promete entrega ni
requiere destinatario fijo. Se retira el ajuste de número WhatsApp de la interfaz;
el modelo legado se conserva para SQLite y respaldos compatibles (PDF-AC-07).

## Componentes, estados y tokens

| Elemento | Componente M3 / comportamiento | Tokens |
| --- | --- | --- |
| Encabezado | Encabezado con botón volver, superficie sin sombra | surface / onSurface; titleLarge |
| Producto seleccionado | Card.outlined, elevación 0; contenido completo | surfaceContainerLow / onSurface; titleMedium y bodyMedium |
| Inclusión | CheckboxListTile; seleccionado/desmarcado | primary / onPrimary; bodyLarge |
| Quitar producto | TextButton.icon; deshabilitado mientras comparte | primary; labelLarge |
| Compartir PDF | FilledButton.icon; deshabilitado vacío/ocupado | primary / onPrimary; labelLarge |
| Generación/compartidor abierto | LinearProgressIndicator indeterminado y texto «Preparando catálogo para compartir…» | primary / surfaceContainerHighest; bodyMedium |
| Fallo | ErrorMessage con región semántica viva; conserva selección | error sobre surface; bodyMedium |
| Disponibilidad | Texto Disponible/Agotado sin depender del color | onSurface; bodyMedium |

PDF-AC-05: el VM impide comandos simultáneos. No se borra la selección al compartir,
cancelar o fallar. Se conservan los estados al lifecycle porque la selección reside
en el VM del catálogo. La preparación utiliza el snapshot seleccionado vigente.
La acción captura el RenderBox del botón en coordenadas globales y entrega su Rect
al compartidor, necesario para el popover de iPad.

## Adaptación y accesibilidad

Ventana compacta (<600 dp): una columna, margen 16 dp. Mediana (600–839) y expandida
(>=840): revisión en una columna centrada, máximo 720 dp; el catálogo existente
admite dos columnas cuando el texto permite lectura, con medianil 16 dp y márgenes
24/32 dp. Texto ampliado puede volver a una columna; no truncar textos principales.

Controles mínimos 48×48 dp heredados del tema. Se conserva el espaciado solicitado:
24 dp antes de compartir y 8 dp entre acciones apiladas. El contenido se desplaza
para que la acción no quede bloqueada por texto ampliado. Fotos tienen etiqueta y
alternativa de imagen inválida. Los estados vacíos bloquean el comando tanto en UI
como VM. Las pruebas de contraste existentes comprueban pares de tokens concretos
claros/oscuros con mínimo 4.5:1; el coordinador debe ejecutar esas pruebas y registrar
el resultado de esta entrega. Pruebas añadidas de revisión a 320 dp / escala 2,
progreso, ancla y conservación de selección aún pendientes de ejecución al diseñar.

## Código base integrado (Flutter)

```dart
Builder(
  builder: (buttonContext) => FilledButton.icon(
    onPressed: vm.busy || vm.selected.isEmpty ? null : () async {
      final box = buttonContext.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size : null;
      await vm.shareSelected(sharePositionOrigin: origin);
    },
    icon: const Icon(Icons.picture_as_pdf_outlined),
    label: const Text('Compartir catálogo PDF'),
  ),
)
```

Referencias oficiales: [Botones M3](https://m3.material.io/components/buttons/overview),
[Cards M3](https://m3.material.io/components/cards/overview),
[Progreso M3](https://m3.material.io/components/progress-indicators/overview),
[RenderBox.localToGlobal Flutter](https://api.flutter.dev/flutter/rendering/RenderBox/localToGlobal.html).
