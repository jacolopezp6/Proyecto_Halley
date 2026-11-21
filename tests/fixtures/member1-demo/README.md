# Fixtures sintéticos de Persona 1

Los ocho archivos de fuente fueron creados para demostrar la ingesta del componente Haskell; `queries.jsonl` contiene una respuesta sintética. **Todos los valores, fechas y mensajes son ficticios; no son evidencia oficial del caso ni reemplazan archivos entregados por el curso.** Mantenerlos en `tests/fixtures/`, nunca en `data/raw/` o `data/reference/`.

Los ejemplos incluyen:

- alias `Luka` en una lectura de tarjeta y un mensaje de radio;
- una tarjeta sin identificador;
- una lectura de tarjeta duplicada byte a byte;
- conteo de presencia malformado (`dos`);
- referencia de módulo `LAB_B` ausente de `estacion.csv`;
- dos conteos diferentes del mismo sensor y hora;
- un corte de energía de ejemplo.
- una respuesta JSONL sintética y otra incompleta para probar la sección de consultas del informe.

Los parsers y las pruebas describen estos formatos de demostración. Al recibir las fuentes reales, actualizar el esquema y los casos sin editar los originales.
