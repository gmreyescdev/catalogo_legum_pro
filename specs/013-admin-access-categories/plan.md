# Plan — Acceso administrativo, separación y Categorías

Cambios de presentación autorizados por solicitud del usuario. Dependencias existentes
Flutter Material 3 y MVVM; no agregar paquetes ni modificar persistencia/PIN.
Coordinador mantiene spec.md, tasks.md y qa.md y sincroniza criterios numerados.

## Incrementos y dependencias

1. **Diseño y regla persistente.** Coordinador registra alcance y criterios; diseñador
   entrega design.md. Registrar norma24/16/12 y touch48 en documentación de diseño
   del equipo (skill local o instrucciones elegidas por coordinador), para futuras
   pantallas nuevas/modificadas. Evitar auditoría masiva no solicitada de vistas intactas.
2. **Acceso.** Codificador modifica exclusivamente lib/features/admin_views.dart en
   AuthPanel: ancho480, jerarquía tonal, scroll, spacing, spinner dentro de acción
   dependiente de vm.busy. Mantener todas las ramas recovery/setup, restricciones y
   controladores existentes. No editar AuthViewModel si su busy actual basta.
3. **Categorías.** Mismo codificador/archivo en turno secuencial: cabecera y resumen,
   gap24 tras creación, cards outlined icono/nombre/conteo, controlsWrap12/padding16,
   separación de acciones de editor y diálogo inline manteniendo lógica existente.
4. **QA host.** QA posee un nuevo test/qa/admin_access_categories_test.dart; pruebas
   de widgets con gate/completer en fake auth prueban spinner durante Future real,
   disabled/dobleenvío y retorno estado ante error. Pruebas de layout miden gap24
   creación→card, y en320dp/text2× nombres largos, scroll y targets48. Cancelar y
   editar/borrar categoría con productos/reordenar siguen cubiertos; ampliar solo
   regresiones afectadas que no cubra suite existente. QA no ejecuta Flutter hasta
   coordinador autorice exclusividad de herramientas de build/test.
5. **Verificación coordinada.** dart format, flutter analyze y tests relevantes;
   suite completa una vez cambios estabilizados. Registrar ejecutado vs pendiente.
6. **Entrega Android física.** Build normal release con configuración local sin leer
   secretos; verificar applicationId normal antes de adb install -r. Revisión física
   acceso, teclado y categorías sin mutar catálogo del usuario. Si se necesita
   integración automatizada, solo paquete .integration y verificar ID antes instalar.
   No emulador. iOS y screenreader físico no verificados sin ejecución correspondiente.

## Matriz de cobertura prevista

| Área de aceptación (sincronizar IDs del spec) | Archivos previstos | Verificación |
| --- | --- | --- |
| ACC-01: acceso profesional y estados intactos | admin_views.dart, test nuevo | PIN/recovery/setup, teclado, scroll |
| ACC-02: loading real y prevención de envío repetido | admin_views.dart, test nuevo | Future pendiente, spinner, botón disabled, error/success |
| ACC-03: separación actual/futura | AGENTS.md, admin_views.dart | normas registradas, gap geométrico24/16/12 |
| ACC-04: categorías profesionales sin funciones nuevas | admin_views.dart, test nuevo + suite | resumen/conteo, nombre largo, edit/delete/reorder |
| ACC-05: accesibilidad/adaptación | diseño y test nuevo | 320dp, texto2×, targets48, ambos temas |
| ACC-06: entrega sin pérdida de datos | artefactos/qa.md | analyze/tests/build e instalación física conservadora |

Cada entrega debe registrar versión, evidencia física si disponible, resultados host
y límites. El spinner puede pasar brevemente en autenticación rápida: no introducir
retardo para hacerlo visible en el teléfono. La evidencia determinista del busy se
obtiene con Future controlado en test host.
