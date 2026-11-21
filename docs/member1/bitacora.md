# Bitácora de decisiones — Halley-7, Persona 1

## Registro

| Fecha | Decisión/actividad | Estado | Evidencia/pendiente |
|---|---|---|---|
| 2026-11-21 | Se consolidó el reparto de Persona 1 a partir de los planes de los tres integrantes. | Preparado | Falta aprobación explícita de Personas 2 y 3. |
| 2026-11-21 | Se propuso conservar registros originales, separar correcciones y fijar snapshots para consultas. | Propuesta | Revisar con equipo y probar reconstrucción de respuestas. |
| 2026-11-21 | Se compararon SQLite WAL, PostgreSQL y JSON Lines; SQLite WAL quedó como recomendación provisional. | Pendiente de ratificación | Verificar controladores y concurrencia en el entorno del proyecto. |
| 2026-11-21 | Se propuso API HTTP local JSON bajo `/v1` e IDs idempotentes. | Pendiente de ratificación | Validar contra Java, Haskell, Prolog y Smalltalk. |
| 2026-11-21 | Se redactó catálogo inicial de pruebas para los seis archivos de evidencia y dos referencias. | Preparado | Los originales del curso aún no aparecen en `data/raw/` ni `data/reference/`. |
| 2026-11-21 | Se crearon ocho fixtures sintéticos bajo `tests/fixtures/member1-demo/` en CSV, JSON y texto. | Completo para demostración | Son datos inventados de prueba, no evidencia oficial. Cubren alias `Luka`, tarjeta incompleta y duplicada, presencia malformada, `LAB_B` fuera del mapa y conteos contradictorios. |
| 2026-11-21 | Se implementaron tipos Haskell, parsers de las seis fuentes y dos referencias, UTC explícito, alias, diagnósticos de campos/módulos, duplicados/conflictos, timeline, informe y salida JSONL. | Prototipo compilado | Ajustar parsers al recibir fuentes oficiales. |
| 2026-11-21 | Se añadió SHA-256 calculado sobre los bytes exactos de cada archivo de origen y se incluye en la procedencia de cada evento; se verificó el vector conocido `abc`. | Pasó | La huella aplica a los fixtures sintéticos por ahora; debe cotejarse con fuentes oficiales al recibirlas. |
| 2026-11-21 | Se ejecutaron 27 verificaciones y se parsearon los 28 eventos JSONL producidos por la demo. Se ajustó el parser CSV para aceptar CRLF preservando el terminador en `record_original`; SHA-256 se verificó con vectores de una y varias rondas y contra los bytes del fixture. | Pasó en fixtures sintéticos | `-Wall -Wcompat -Werror`; tres inválidos, dos lecturas en conflicto y un duplicado permanecen identificados. Esto no valida los formatos oficiales. |
| 2026-11-21 | Se publicaron el contrato (`d9fd57a`), componente Haskell (`c637369`), fixtures/demo (`914046a`) y respuestas JSONL en C6 (`636c162`) a `origin/codex/member1-haskell`. | Publicado | `data/raw/` y `data/reference/` siguen sin los archivos originales del curso. |
| 2026-11-21 | Se añadió carga de respuestas JSONL al informe C6 con evidencia, certeza, supuestos, límites y versión. | Publicado (`636c162`) | La demo usa una respuesta sintética; falta conectar el emisor Prolog real. |

## Alternativa descartada provisionalmente

JSON Lines como almacén canónico se descarta provisionalmente porque no resuelve por sí solo transacciones, escrituras concurrentes, snapshots ni consultas relacionales. Se conserva como formato de intercambio/exportación. Confirmar mediante prueba de reinicio y comparación con SQLite.

## Pendiente para completar y aprobar

1. Incorporar los archivos oficiales en `data/raw/` y `data/reference/` sin modificarlos.
2. Inspeccionar estructura real, codificación, zona horaria, unidades, duplicados y errores.
3. Ratificar modelo, transporte, persistencia y arranque único con los otros integrantes.
4. Conectar la recepción de respuestas Prolog para incluir consultas reales en C6.
5. Persistir originales y correcciones en el almacén común acordado; la ingesta Haskell ya calcula el hash de fuente.
6. Seguir publicando commits por hitos en `codex/member1-haskell`.
