# Coordinación y decisiones — Semana 1

## Reparto de capacidades

| Integrante | Capacidades | Trabajo principal |
|---|---|---|
| Persona 1 | C1, C6 | Integración y validación en Haskell; línea de tiempo e informe sustentado |
| Persona 2 | C2; apoyo C5 | Inferencia/consultas en Prolog; propuesta de persistencia y trazabilidad |
| Persona 3 | C3, C4 | Ingesta/simulador en Java; sesiones concurrentes y alertas en Smalltalk |
| Equipo | C5 | Elegir e integrar persistencia para originales, correcciones, consultas y respuestas |

Este reparto coincide con los planes entregados para los tres integrantes. La aprobación de cada persona no se presume. Persona 1 coordina el modelo, mantiene la bitácora e integra; Persona 2 valida el contrato de consultas y custodia; Persona 3 valida eventos en vivo, reintentos y concurrencia.

## Modelo compartido propuesto

La especificación normativa está en `event.schema.json`. Principios:

1. El original recibido se conserva exactamente y no se sobrescribe.
2. Toda observación obtiene un `event_id` estable, incluso si no se puede parsear.
3. Se guardan por separado hora textual original e instante UTC normalizado; si la hora no puede interpretarse, el instante queda nulo y se documenta la anomalía.
4. Identidad registrada, identidad canónica y alias son valores separados. Una coincidencia ambigua no se fuerza.
5. Cada evento y anomalía conserva procedencia al archivo, hash, ubicación y versión del parser.
6. Una corrección es un registro nuevo con vínculo al original, motivo, autor y fecha.
7. Consultas e informes fijan una vista (`original` o `corrected`) y una versión de datos para poder reproducirse.

## Persistencia: comparación y recomendación provisional

Criterios: inmutabilidad auditable, correcciones separadas, snapshots consistentes, consultas, concurrencia y facilidad de arranque en varios lenguajes.

| Alternativa | Ventajas | Costos/riesgos | Evaluación |
|---|---|---|---|
| SQLite con WAL | Archivo local; SQL transaccional; conectores comunes; respaldo sencillo | Un escritor simultáneo; integridad append-only requiere restricciones y disciplina de acceso | Recomendada para el prototipo local; escritor único detrás del servicio de integración |
| PostgreSQL | Restricciones, historial y concurrencia robustos; SQL completo | Servicio y configuración adicionales; más trabajo de despliegue | Preferible si el sistema debe operar con varios escritores remotos |
| JSON Lines | Legible y fácil de exportar; permite anexar registros | Sin transacciones ni consultas relacionales; concurrencia, versiones y correcciones manuales | Útil para intercambio/depuración, no como almacén canónico |

**Recomendación provisional:** SQLite WAL para persistencia común, con originales append-only y correcciones separadas. La decisión final corresponde al equipo y debe registrarse tras verificar las bibliotecas disponibles y una prueba de concurrencia/reinicio.

**Alternativa descartada provisionalmente:** JSON Lines como almacén principal. La razón es que snapshots, consultas históricas y concurrencia tendrían que recrearse en cada componente. Se mantiene como formato de intercambio y exportación. La prueba de recuperación indicada en `casos-de-prueba.md` debe confirmar la decisión.

## Contrato de integración propuesto

Contrato OpenAPI en `api.yaml`. HTTP local y JSON UTF-8 versionado bajo `/v1`:

- Java entrega lecturas a `POST /events` con ID idempotente y registro original.
- La integración valida, normaliza y persiste el evento, y responde con versión de datos o error estructurado.
- Las consultas especifican vista y pueden fijar snapshot. La salida incluye certeza, IDs de evidencia, supuestos y límites.
- Correcciones crean una versión nueva y nunca alteran el original.
- Fallas temporales se reintentan con el mismo ID; errores de formato se guardan como inválidos y no se reintentan como válidos.
- Dos solicitudes con el mismo ID y contenido idéntico son idempotentes; el mismo ID con distinto contenido es conflicto auditable.

**Arranque único propuesto:** `./run.sh` y `./run.ps1` como envolturas del mismo flujo: verificar dependencias, inicializar persistencia, arrancar componentes por orden y mostrar estado. Nombre/implementación deben ratificarse antes de incorporarlo al README del proyecto.

## Acuerdos pendientes de ratificación

- Aprobación explícita de Personas 2 y 3 del modelo, protocolo, elección de persistencia y comando único.
- Confirmar transporte HTTP frente a colas locales, y acordar puertos/autenticación local si aplica.
- Verificar contrato con el simulador real y con las interfaces de Haskell, Prolog y Smalltalk.
- Revisar encabezados, codificación, zonas horarias, unidades, formatos y anomalías reales cuando estén disponibles los archivos fuente.
