# Proyecto Halley-7: lo que pasó durante la tormenta

Proyecto final de Paradigmas del Lenguaje. El repositorio contiene la estructura del sistema y el primer componente Haskell de Persona 1; las demás capacidades y la integración total se completarán en equipo.

## Contexto

Halley-7 es una estación antártica aislada donde desapareció la glacióloga Irene Valcárcel durante una tormenta. La estación conserva registros de seis fuentes con formatos distintos, además de dos archivos de referencia. Un sistema forense debe reunirlos, responder consultas con evidencia trazable y conservar íntegra la evidencia original.

El proyecto debe integrar **Haskell, Prolog, Java, Smalltalk** (lenguaje asignado al grupo) y una base de datos elegida por el equipo. Cada uno de los cuatro lenguajes debe tener responsabilidad sobre al menos una capacidad completa con entrada, lógica y salida; no basta con reenviar datos. Los componentes deben comunicarse automáticamente y todo el sistema debe poder levantarse con un solo comando o script documentado.

## Capacidades del sistema

- **C1. Integrar evidencia:** leer las seis fuentes, validar registros y construir una línea de tiempo unificada. Los registros corruptos, duplicados o contradictorios se conservan con su diagnóstico.
- **C2. Responder consultas:** inferir ubicaciones y recorridos posibles, identificar quién pudo usar una tarjeta y respaldar las respuestas con evidencia. Diferenciar lo falso de lo que no se puede determinar y garantizar que las búsquedas terminen.
- **C3. Recibir lecturas en vivo:** simular y recibir nuevas lecturas de tarjetas, presencia y temperatura sin perder datos ante fallos de otros componentes.
- **C4. Atender investigadores concurrentes:** permitir consultas simultáneas consistentes y avisos por nueva evidencia relevante.
- **C5. Custodiar evidencia:** conservar originales inmutables, registrar correcciones por separado y reconstruir exactamente respuestas anteriores.
- **C6. Generar informe:** producir línea de tiempo, problemas en las fuentes y consultas/respuestas con sus evidencias.

La asignación de capacidades a lenguajes es una decisión del grupo y debe justificarse desde los paradigmas. La propuesta inicial está en `ROLES_Y_GITHUB.md`; puede cambiarse con una decisión registrada.

## Estructura

```text
Proyecto_Halley/
├── README.md
├── ROLES_Y_GITHUB.md
├── docs/                 # arquitectura, protocolo, modelo de datos, decisiones
│   └── member1/          # contrato, bitácora, pruebas e informe de demostración
├── data/
│   ├── raw/              # seis fuentes originales, preservadas sin cambios
│   ├── reference/        # personal.csv y estacion.csv
│   └── live/             # lecturas generadas por el simulador
├── src/
│   ├── haskell/          # C1/C6: ingesta, normalización e informe
│   ├── prolog/
│   ├── java/
│   ├── smalltalk/
│   └── database/         # esquema y scripts de persistencia
├── simulator/            # generador configurable de lecturas en vivo
└── tests/                # pruebas por lenguaje y de integración
    ├── fixtures/member1-demo/ # datos sintéticos, no evidencia oficial
    └── haskell/
```

Las fuentes oficiales del curso deben colocarse en `data/raw/` y `data/reference/` sin modificarlas. Los ejemplos de `tests/fixtures/member1-demo/` son sintéticos y solo sirven para ejecutar el componente Haskell; no deben citarse como evidencia del caso.

## Componente de Persona 1

La primera implementación de C1/C6 vive en `src/haskell/`: procesa los seis tipos de fuente y dos referencias con los formatos de demostración, normaliza horas que tienen zona explícita, conserva texto original y procedencia por registro (incluido SHA-256 de los bytes originales), resuelve alias, señala errores, duplicados y conflictos, y genera un informe Markdown y una salida JSONL. El informe puede incorporar respuestas de consulta desde un archivo JSONL, con sus IDs de evidencia, certeza, supuestos, límites y versión de datos. Los contratos y límites están en `docs/member1/`.

Desde la raíz del repo, ejecutar con GHC:

```powershell
.\src\haskell\run.ps1
.\src\haskell\test.ps1
```

En Linux/macOS: `./src/haskell/run.sh` y `./src/haskell/test.sh`. Las salidas generadas quedan en `src/haskell/.build/output/`; los ejemplos versionados en `docs/member1/` son muestras estáticas. Los parsers deben contrastarse con los archivos oficiales antes de interpretar el caso. La generación automática de respuestas desde Prolog y la persistencia común aún requieren integración.

## Fuentes que debe integrar el sistema

**Evidencia:** `tarjetas.csv`, `radio.txt`, `energia.json`, `presencia.csv`, `temperatura.csv`, `bitacora.txt`.

**Referencia:** `personal.csv`, `estacion.csv`.

El enunciado señala datos problemáticos que deben mantenerse trazables, por ejemplo un registro de tarjeta corrupto, un uso duplicado, el alias “Luka” en radio y la medición `LAB_B` en presencia.

## Entregables y demostración

El informe debe incluir arquitectura y diagrama de comunicación, justificación de la responsabilidad de cada lenguaje, protocolo y modelo de datos, bitácora fechada con alternativas y pruebas, y tratamiento de problemas en las fuentes. La sustentación contempla arranque desde cero, integración de los ocho archivos, lecturas en vivo, consultas y pruebas de robustez.

## Bitácora de decisiones

Registren decisiones durante las tres semanas, no solo al final. Para cada una documenten fecha, problema, alternativas, decisión y evidencia o prueba que la respalda. Incluyan al menos una alternativa descartada y reflejen los cambios en Git.

## Inicio

1. Revisen el enunciado completo y coloquen los ocho archivos en `data/` sin modificar las fuentes originales.
2. Acuerden la arquitectura, el protocolo y el modelo de datos; documenten las decisiones en `docs/`.
3. Asignen capacidades completas a cada lenguaje y justifiquen el reparto.
4. Mantengan pruebas comunes y prueben el sistema integrado, incluidos concurrencia, correcciones y fallos.
5. Documenten en esta sección el comando único de arranque cuando la integración esté definida.

## Uso de herramientas de IA

El enunciado permite usar IA para resolver dudas, pero el equipo debe declarar su uso en el informe y ser capaz de justificar sus propias decisiones y código.
