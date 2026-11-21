# Requisitos y casos de prueba — Semana 1

Los nombres de archivo se toman del plan del proyecto. Los archivos no estaban presentes en `sources/` al preparar este catálogo; por ello son criterios de inspección y aceptación, no resultados de ejecución. Al incorporarlos, registrar hash, codificación, delimitador, zona horaria/unidades declaradas y ajustar cada caso a sus filas reales. No editar los originales.

| ID | Fuente(s) | Caso | Criterio de aceptación |
|---|---|---|---|
| ING-01 | `tarjetas.csv` | Ingerir una fila válida, tarjeta incompleta, fila con columnas extra y fila malformada. | Conservar bytes/texto y ubicación; diagnosticar el registro incompleto sin descartarlo. |
| ING-CRLF | CSV | Leer filas con terminador CRLF. | El `\r` final no se trata como dato ni error; el registro original conserva el terminador. |
| ING-02 | `radio.txt` | Procesar línea válida, vacía, hora no interpretable y texto con alias. | Texto exacto y línea permanecen disponibles; normalización/identidad separadas; parseo parcial no pierde evidencia. |
| ING-03 | `energia.json` | Cargar JSON válido y probar sintaxis inválida/campo ausente. | Error incluye ubicación; archivo bruto se conserva; registros parseables no se descartan por otro registro defectuoso. |
| ING-04 | `presencia.csv` | Cargar conteos e incluir un valor mal escrito (caso indicado por el plan). | El valor corrupto nunca se convierte en conteo válido; queda diagnóstico y procedencia. |
| ING-05 | `temperatura.csv` | Cargar lectura válida y probar valor no numérico, unidad ausente y hora inválida. | Unidad/valor/hora se validan; el original y cada anomalía se preservan. |
| ING-06 | `bitacora.txt` | Ingerir anotaciones estructuradas y libres, incluyendo líneas vacías. | Entrada y número de línea se pueden recuperar incluso si queda `unparsed`. |
| REF-01 | `personal.csv` | Resolver persona por ID/nombre, alias `Luka`, alias desconocido y alias ambiguo. | Se conserva forma registrada; canonical ID y alias se anotan aparte; ambigüedad queda sin resolver. |
| REF-02 | `estacion.csv` y lecturas | Cargar módulos/topología y revisar una lectura del módulo `LAB_B`, ausente del mapa. | La referencia queda versionada; el módulo desconocido se diagnostica y conserva el original. |
| NORM-01 | Seis fuentes | Normalizar timestamps UTC, offset explícito, zona faltante y fecha inválida. | Conversión correcta solo cuando la fuente permite inferirla; UTC termina en `Z`; original queda intacto; hora desconocida no se inventa. |
| NORM-02 | Seis fuentes | Encontrar duplicado byte a byte y dos lecturas del mismo sensor/módulo en el mismo instante con valores distintos. | Ninguno desaparece; marcar duplicado candidato o conflicto y señalar los IDs relacionados. |
| PROV-01 | Ocho archivos | Seguir cualquier evento/anomalía hasta archivo, SHA-256, fila/línea y parser. | La procedencia es completa y reproducible. |
| STORE-01 | Eventos/correcciones | Añadir corrección, consultar vista original y corregida; reconstruir respuesta guardada. | Original inalterado; corrección versionada; respuesta conserva snapshot y IDs de soporte. |
| API-01 | Ingesta | Reenviar misma solicitud e ID; luego reutilizar ID con contenido distinto. | Primera repetición es idempotente; contenido distinto da conflicto auditable. |
| API-02 | Consultas | Consultar pregunta con evidencia y pregunta con evidencia insuficiente. | Respuesta incluye estado de certeza, evidencia, supuestos, límites y versión; ausencia de registro no prueba falsedad. |
| C6-01 | `queries.jsonl` | Cargar respuesta estructurada con ID, certeza, evidencia, supuestos, límites y snapshot; probar campo requerido ausente y escape Unicode. | El informe incluye la respuesta y sus referencias; JSONL incompleto da error visible y no se registra como válido. |
| C6-02 | `queries.jsonl` | Entregar un nivel de certeza ajeno al enum del contrato. | La respuesta se rechaza con error de archivo/línea; no se incorpora al informe. |
| CONC-01 | Ingesta/consultas | Consultas simultáneas idénticas mientras ingresa una lectura nueva. | Consultas del mismo snapshot dan la misma respuesta/version; nueva lectura aparece en versión posterior. |
| REC-01 | Integración | Detener el componente destino durante una lectura y reiniciarlo. | Lectura queda durable/pendiente, reintenta con el mismo ID y termina confirmada o expuesta como error. |
| RUN-01 | Sistema | Arrancar desde cero con un solo comando y ocho archivos. | Dependencias/servicios reportan estado; errores de fuente son visibles; el proceso no oculta fallas. |

## Trazabilidad y reporte

Cada ejecución debe registrar: ID de caso, hash y versión de cada archivo, comando/consulta, resultado esperado, resultado observado, diagnósticos y evidencia citada. No marcar como aprobado hasta ejecutar con los archivos auténticos. El informe diferencia `supported`, `refuted`, `insufficient_evidence` e `indeterminate`; una falta de registro no se presenta como prueba negativa.
