# SPEC-001 — Catálogo simple de productos

Estado: implementado; 15 pruebas automatizadas y análisis estático aprobados,
APK Android compilado. Validación manual Android y compilación/recorrido iOS
pendientes. Consultar `qa.md` para evidencia y límites de cobertura.

## Objetivo

Permitir que una persona explore un catálogo de productos desde Android o iOS
y vea la imagen y descripción de cada producto. Esta es la primera entrega.

## Requisitos confirmados por el usuario

- Catálogo simple de productos.
- Cada producto presenta imagen y descripción.
- Plataformas objetivo: Android e iOS.

## Decisiones para acotar la primera entrega

Para esta entrega se adopta una única pantalla con listado vertical y datos locales
de demostración, sin servicios externos. Un nombre corto identifica cada producto junto a su imagen
y descripción. Los productos y recursos definitivos de marca quedan por suministrar;
los ejemplos deben identificarse como contenido de demostración. El diseño usa
Material Design 3 con tokens de color y tipografía y adaptación al ancho disponible.

## Alcance

- Pantalla inicial con título y listado desplazable de productos.
- Tarjeta por producto con nombre, imagen y descripción completa.
- Datos e imágenes incluidos en la aplicación para uso sin conexión.
- Estado de catálogo vacío y alternativa visual para imagen ausente o inválida.
- Diseño móvil con áreas seguras, texto ampliado y semántica accesible.

## Fuera del primer incremento

Búsqueda, filtros, detalle separado, precios, carrito, pagos, login, panel de
administración, backend y sincronización. Se podrán definir en specs posteriores.

## Criterios de aceptación

- **AC-01:** Al abrir la app con datos locales, se muestra el catálogo sin pasos
  previos y cada producto presenta nombre, imagen y descripción.
- **AC-02:** Con suficientes productos para exceder la altura disponible, el usuario
  puede desplazarse hasta el último producto.
- **AC-03:** La descripción completa permanece disponible en la tarjeta, incluso
  cuando es larga; no se recorta con puntos suspensivos.
- **AC-04:** Si falta una imagen o el recurso no puede decodificarse, se muestra un
  placeholder y siguen visibles el nombre y la descripción; la pantalla no falla.
- **AC-05:** Con una colección vacía, se muestra «No hay productos disponibles».
- **AC-06:** El catálogo con recursos incluidos funciona sin conexión.
- **AC-07:** La pantalla respeta áreas seguras y no presenta desbordamientos en
  anchos lógicos de 320 y 390 con escala de texto de 1.0 y 2.0. El lector de pantalla
  permite identificar cada producto y leer su descripción en orden lógico.
- **AC-08:** El mismo alcance está implementado para Android e iOS. La evidencia
  de compilación y ejecución se registra por plataforma; lo no ejecutado queda pendiente.

## Escenarios principales

1. Abrir la app → leer productos → desplazarse → leer la descripción del último.
2. Abrir un catálogo sin datos → ver el mensaje de catálogo vacío.
3. Mostrar un producto sin imagen válida → ver placeholder y leer su descripción.
4. Activar texto ampliado o lector de pantalla → explorar el mismo contenido.

## Definición de terminado

Implementación coherente con este spec, pruebas de comportamiento pertinentes,
formato y análisis Flutter correctos, y reporte QA que identifica evidencia por
criterio y plataforma. La validación iOS pendiente no equivale a iOS validado.
