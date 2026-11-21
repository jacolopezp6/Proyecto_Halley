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

En Linux/macOS, usa `./src/haskell/run.sh`. Los argumentos opcionales son directorio de datos, ruta del informe, ruta de eventos JSONL y ruta de respuestas JSONL, relativos a la raíz del repositorio. Por defecto se leen los fixtures sintéticos, incluida una respuesta sintética, y las salidas se escriben en `src/haskell/.build/output/`. Los ejemplos versionados en `docs/member1/` son estáticos. Para omitir respuestas en PowerShell, pasa una cadena vacía como cuarto argumento.

Para ejecutar las verificaciones del núcleo, usa `./src/haskell/test.ps1` en Windows o `./src/haskell/test.sh` en Linux/macOS. También se puede usar `cabal test` desde `src/haskell`.

## Estructura

- `src/Halley/Event.hs`: tipos algebraicos y transformaciones puras para UTC, ordenamiento, JSONL e informe.
- `src/Halley/Ingest.hs`: lectura de CSV (incluidas filas CRLF), texto delimitado y JSON de energía; diagnósticos, duplicados, conflictos y alias. Calcula SHA-256 de los bytes originales antes de decodificar UTF-8.
- `app/Main.hs`: entrada/salida del componente.
- `../../tests/fixtures/member1-demo/`: datos sintéticos repetibles.
- `../../tests/haskell/`: verificaciones del componente.
- `../../docs/member1/`: decisiones, contrato, casos e informes de demostración.

El informe incorpora respuestas en `QueryAnswer`, con nivel de certeza, evidencia, supuestos, límites y versión del conjunto de datos. El CLI puede leerlas desde JSONL compatible con el esquema de respuesta; conectar Prolog en vivo para producir ese archivo depende del protocolo acordado por el equipo.

## Pendientes de integración real

Esta versión conserva procedencia por archivo, hash y fila/línea, pero todavía no persiste en la base compartida. La generación de respuestas de Prolog tampoco está conectada a la CLI. Hay que ratificar el contrato con el equipo y adaptar los parsers a los archivos originales.

Este paquete cubre el componente de Persona 1; no implementa las capacidades Prolog, Java o Smalltalk de los otros integrantes.
