# Componente de Persona 1 — Halley-7

Componente Haskell para integrar fuentes del caso, conservar procedencia, construir la línea de tiempo y generar el informe C6.

## Datos

`tests/fixtures/member1-demo/` contiene ocho fixtures sintéticos creados para demostrar el flujo. No son evidencia oficial ni datos recibidos del equipo. Se mantienen separados de `data/raw/` y `data/reference/`, reservados para los archivos entregados por el curso.

Los parsers implementan los formatos y columnas de esos fixtures. Deben ajustarse a las fuentes auténticas antes de usar el informe para el caso.

## Ejecución

Con GHC instalado, desde la raíz del repositorio:

```powershell
.\src\haskell\run.ps1
```

En Linux/macOS, usa `./src/haskell/run.sh`. Los argumentos opcionales son directorio de datos, ruta del informe y ruta de eventos JSONL, relativos a la raíz del repositorio. Por defecto se leen los fixtures sintéticos y se generan ejemplos en `docs/member1/`.

Para ejecutar las verificaciones del núcleo, usa `./src/haskell/test.ps1` en Windows o `./src/haskell/test.sh` en Linux/macOS. También se puede usar `cabal test` desde `src/haskell`.

## Estructura

- `src/Halley/Event.hs`: tipos algebraicos y transformaciones puras para UTC, ordenamiento, JSONL e informe.
- `src/Halley/Ingest.hs`: lectura de CSV, texto delimitado y JSON de energía; diagnósticos, duplicados, conflictos y alias.
- `app/Main.hs`: entrada/salida del componente.
- `../../tests/fixtures/member1-demo/`: datos sintéticos repetibles.
- `../../tests/haskell/`: verificaciones del componente.
- `../../docs/member1/`: decisiones, contrato, casos e informes de demostración.

El informe reserva una sección para respuestas de Prolog mediante `QueryAnswer`, con nivel de certeza, evidencia, supuestos, límites y versión del conjunto de datos. La función de informe es pura; conectar Prolog en vivo depende del protocolo acordado por el equipo.

## Pendientes de integración real

Esta versión conserva procedencia por archivo y fila/línea, pero no calcula SHA-256 ni persiste en la base compartida. La ingesta de respuestas de Prolog tampoco está conectada a la CLI. Hay que ratificar el contrato con el equipo y adaptar los parsers a los archivos originales.

Este paquete cubre el componente de Persona 1; no implementa las capacidades Prolog, Java o Smalltalk de los otros integrantes.
