# Halley-7 — informe de ingesta

> Conjunto de demostración: verificar contra las fuentes originales antes de extraer conclusiones del caso.

## Resumen

- Registros procesados: 28
- Registros válidos: 22
- Registros con anomalías: 6
- Eventos sin hora UTC interpretable: 6

## Línea de tiempo (UTC)

| UTC | Fuente | Registro | Tipo | Estado | Contenido |
|---|---|---|---|---|---|
| 2042-07-12T02:52:00Z | bitacora.txt | line:1 | LogEntry | Valid | label=sistema; message=Inicio de turno registrado.; time_original=2042-07-12T02:52:00Z |
| 2042-07-12T02:54:00Z | temperatura.csv | line:2 | TemperatureReading | Valid | module=P3; temp_c=-18.4; timestamp_utc=2042-07-12T02:54:00Z |
| 2042-07-12T02:55:00Z | presencia.csv | line:2 | PresenceReading | Conflicting | count=2; module=P3; timestamp_utc=2042-07-12T02:55:00Z |
| 2042-07-12T02:55:00Z | presencia.csv | line:5 | PresenceReading | Conflicting | count=1; module=P3; timestamp_utc=2042-07-12T02:55:00Z |
| 2042-07-12T02:56:00Z | tarjetas.csv | line:2 | CardRead | Valid | canonical_person_id=PERS-014; card_id=C-014; identity_as_recorded=Irene Valcárcel; person_as_recorded=Irene Valcárcel; reader_id=P3; timestamp_utc=2042-07-12T02:56:00Z |
| 2042-07-12T02:56:00Z | tarjetas.csv | line:6 | CardRead | DuplicateCandidate | canonical_person_id=PERS-014; card_id=C-014; identity_as_recorded=Irene Valcárcel; person_as_recorded=Irene Valcárcel; reader_id=P3; timestamp_utc=2042-07-12T02:56:00Z |
| 2042-07-12T02:58:00Z | radio.txt | line:1 | RadioMessage | Valid | label=canal-2; message=Ruido estático breve; sin identificación de voz.; time_original=2042-07-12T02:58:00Z |
| 2042-07-12T03:00:00Z | energia.json | record:1 | EnergyReading | Valid | module=P8; status=nominal; timestamp_utc=2042-07-12T03:00:00Z; voltage_v=24.1 |
| 2042-07-12T03:02:00Z | tarjetas.csv | line:4 | CardRead | Valid | canonical_person_id=PERS-021; card_id=C-021; identity_as_recorded=Luka; person_as_recorded=Luka; reader_id=P8; timestamp_utc=2042-07-12T03:02:00Z |
| 2042-07-12T03:04:00Z | energia.json | record:2 | EnergyReading | Valid | module=P3; status=outage; timestamp_utc=2042-07-12T03:04:00Z; voltage_v=0.0 |
| 2042-07-12T03:04:00Z | temperatura.csv | line:3 | TemperatureReading | Valid | module=P3; temp_c=-18.1; timestamp_utc=2042-07-12T03:04:00Z |
| 2042-07-12T03:05:00Z | presencia.csv | line:3 | PresenceReading | Invalid | count=dos; module=P3; timestamp_utc=2042-07-12T03:05:00Z |
| 2042-07-12T03:06:00Z | radio.txt | line:2 | RadioMessage | Valid | label=canal-2; message=Luka reporta que el pasillo norte está despejado.; time_original=2042-07-12T03:06:00Z |
| 2042-07-12T03:07:00Z | tarjetas.csv | line:5 | CardRead | Valid | canonical_person_id=PERS-014; card_id=C-014; identity_as_recorded=Irene Valcárcel; person_as_recorded=Irene Valcárcel; reader_id=P3; timestamp_utc=2042-07-12T03:07:00Z |
| 2042-07-12T03:08:00Z | bitacora.txt | line:2 | LogEntry | Valid | label=operador; message=Revisión manual pendiente para sensor de presencia en P3.; time_original=2042-07-12T03:08:00Z |
| 2042-07-12T03:09:00Z | energia.json | record:3 | EnergyReading | Valid | module=P8; status=nominal; timestamp_utc=2042-07-12T03:09:00Z; voltage_v=23.8 |
| 2042-07-12T03:10:00Z | presencia.csv | line:4 | PresenceReading | Valid | count=1; module=P8; timestamp_utc=2042-07-12T03:10:00Z |
| 2042-07-12T03:11:00Z | radio.txt | line:3 | RadioMessage | Valid | label=canal-1; message=Señal incompleta: «...puerta...»; time_original=2042-07-12T03:11:00Z |
| 2042-07-12T03:12:00Z | temperatura.csv | line:4 | TemperatureReading | Valid | module=P8; temp_c=-17.9; timestamp_utc=2042-07-12T03:12:00Z |
| 2042-07-12T03:13:00Z | tarjetas.csv | line:3 | CardRead | Invalid | canonical_person_id=PERS-021; card_id=; identity_as_recorded=Luka; person_as_recorded=Luka; reader_id=P8; timestamp_utc=2042-07-12T03:13:00Z |
| 2042-07-12T03:14:00Z | presencia.csv | line:6 | PresenceReading | Invalid | count=1; module=LAB_B; timestamp_utc=2042-07-12T03:14:00Z |
| 2042-07-12T03:15:00Z | bitacora.txt | line:3 | LogEntry | Valid | label=sistema; message=Se abre incidencia H7-17 por pérdida de contacto con Irene Valcárcel.; time_original=2042-07-12T03:15:00Z |
| sin hora | estacion.csv | line:2 | ReferenceRecord | Valid | adjacent_modules=P3; module_id=P1; reader_ids=P1 |
| sin hora | estacion.csv | line:3 | ReferenceRecord | Valid | adjacent_modules=P1\|P8; module_id=P3; reader_ids=P3 |
| sin hora | estacion.csv | line:4 | ReferenceRecord | Valid | adjacent_modules=P3; module_id=P8; reader_ids=P8 |
| sin hora | personal.csv | line:2 | ReferenceRecord | Valid | aliases=; canonical_person_id=PERS-014; card_ids=C-014; identity_as_recorded=Irene Valcárcel; name=Irene Valcárcel; permissions=P1\|P3\|P8; person_id=PERS-014 |
| sin hora | personal.csv | line:3 | ReferenceRecord | Valid | aliases=Luka; canonical_person_id=PERS-021; card_ids=C-021; identity_as_recorded=Lucas Kovács; name=Lucas Kovács; permissions=P1\|P3\|P8; person_id=PERS-021 |
| sin hora | personal.csv | line:4 | ReferenceRecord | Valid | aliases=; canonical_person_id=PERS-033; card_ids=C-033; identity_as_recorded=Noa Ríos; name=Noa Ríos; permissions=P1\|P3; person_id=PERS-033 |

## Diagnósticos

- **presencia.csv#2** (presencia.csv:line:2):
  - CONFLICTING_SENSOR_READINGS: Mismo sensor y hora que presencia.csv#5 con valores distintos.
- **presencia.csv#5** (presencia.csv:line:5):
  - CONFLICTING_SENSOR_READINGS: Mismo sensor y hora que presencia.csv#2 con valores distintos.
- **tarjetas.csv#6** (tarjetas.csv:line:6):
  - DUPLICATE_RECORD: Registro idéntico al evento tarjetas.csv#2; ambos se conservan.
- **presencia.csv#3** (presencia.csv:line:3):
  - FIELD_NOT_NUMERIC_count: El valor de count no es numérico: dos
- **tarjetas.csv#3** (tarjetas.csv:line:3):
  - FIELD_MISSING_card_id: Falta el campo requerido card_id.
- **presencia.csv#6** (presencia.csv:line:6):
  - UNKNOWN_MODULE: El módulo LAB_B no aparece en estacion.csv.

## Consultas y respuestas

No se recibieron respuestas de consultas para esta ejecución.
