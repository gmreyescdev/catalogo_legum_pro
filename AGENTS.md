# Equipo Flutter con SDD

Este proyecto usa desarrollo guiado por especificaciones (Spec-Driven Development).
El producto es un catálogo local para Android e iOS. La spec activa v2 amplía la
entrega inicial con MVVM, sqflite, administración con PIN, categorías, imágenes,
precios/ofertas, WhatsApp y respaldos. La fuente de verdad está en `specs/`.
La app y la evidencia de la entrega v1 no acreditan requisitos nuevos de v2.

## Coordinación y delegación

El agente principal es el coordinador. El usuario solicita trabajar con subagentes
diseñador, planificador, tester QA y codificador. Delegar tareas concretas según
`.agents/roles/`, con archivos de salida y contexto explícitos.
No permitir ediciones concurrentes del mismo archivo. Si no hay cupos disponibles,
ejecutar roles por turnos. Las instrucciones de roles son documentación del equipo,
no una configuración de agentes persistentes del runtime.

## Flujo SDD

1. Especificar objetivo, alcance, escenarios y criterios de aceptación numerados.
2. Diseñar la experiencia usando la skill local
   `.agents/skills/flutter-product-design/SKILL.md`.
3. Planificar tareas vinculadas a los criterios y definir verificaciones con QA.
4. Implementar el alcance solicitado siguiendo spec, diseño y plan consistentes.
5. QA verifica comportamiento y regresiones; el coordinador integra resultados.

Un borrador puede contener propuestas identificadas. Antes de implementar, resolver
ambigüedades que cambien el comportamiento. No añadir funcionalidades por iniciativa
propia. No exigir una aprobación adicional si el usuario ya autorizó desarrollar
el alcance. Registrar cambios del alcance en el spec y sus tareas.

## Entregables y verificación

Cada spec contiene `spec.md`, `design.md`, `plan.md`, `qa.md` y `tasks.md`.
Separar resultados ejecutados de pruebas pendientes. No declarar soporte iOS
verificado con una ejecución Android: compilar y probar iOS requiere un entorno
con Xcode. Verificar cambios Flutter con formato, análisis y pruebas pertinentes
disponibles; documentar cualquier limitación real.

Para esta implementación, el usuario exige pruebas nativas exclusivamente en
dispositivo físico Android. No iniciar ni usar emuladores. Las pruebas de lógica
y widgets en el host siguen permitidas; no equivalen a validación nativa.

Las pruebas de integración Android usan exclusivamente el paquete
`com.example.catalogo_legum_pro.integration`, aislado del paquete normal y sus datos.
Antes de instalar una build de pruebas, verificar su applicationId. Flutter test
desinstala el paquete de pruebas por defecto; no ejecutar integración con el mismo
identificador de la app que contiene el catálogo del usuario.

## Separación visual de controles

Desde SPEC-013, los diseños deben separar claramente botones de campos y tarjetas:
24 dp entre campos y acciones principales y entre acciones de creación y listas;
16 dp entre tarjetas/grupos, y 12 dp dentro de grupos de acciones cuando corresponda.
Son decisiones del proyecto; adaptar sin recortar texto ni reducir áreas de toque
mínimas de 48 dp. Aplicar en futuros cambios de interfaz.
