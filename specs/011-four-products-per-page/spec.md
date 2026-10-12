# SPEC-011 — Cuatro productos por página

Estado: implementada y entregada en Android físico, versión 0.6.4+11.

## Objetivo y alcance

Ambos catálogos PDF usan una cuadrícula A4 de dos columnas y dos filas, cuatro
productos por página. La última página contiene los restantes sin tarjetas vacías.
Sustituye la densidad natural de SPEC-010. El usuario autorizó resumir nombres y
presentaciones excepcionalmente largos con puntos suspensivos; los datos originales
de la app se conservan, sin anexos ni reducción ilegible del texto.

## Criterios

- GRID-AC-01: N productos únicos visibles generan ceil(N/4) páginas, orden de
  izquierda a derecha y de arriba abajo, cuatro por página salvo la última.
- GRID-AC-02: Cada tarjeta muestra nombre, presentación, imagen proporcional o
  alternativa, precio vigente por Kg, precio normal por Kg tachado si hay oferta,
  y disponibilidad explícita. Nombres/presentaciones largos terminan en puntos
  suspensivos dentro de su espacio reservado sin invadir otras tarjetas.
- GRID-AC-03: Logo y cabecera de marca presentes en cada página; contraste,
  separación y tipografía legibles en A4, footer numerado sin superposiciones.
- GRID-AC-04: Ambos modos mantienen nombres de archivo, selección, deduplicación,
  fotos ausentes/corruptas, retención y compartir. No incluir campos privados.
- GRID-AC-05: Verificar páginas y distribución sobre PDF emitido, renderizar casos
  de cuatro y cinco productos y texto largo; formato/análisis/regresiones y build
  Android físico con instalación -r si conectado. iOS requiere Xcode.
