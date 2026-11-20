
| archivo |

archivo := FileSystem disk workingDirectory / 'informe_halley7.txt'.

archivo writeStreamDo: [ :salida |
    salida nextPutAll: 'INFORME HALLEY-7'; cr.
    salida cr.

    salida nextPutAll: '1. LINEA DE TIEMPO'; cr.
    salida nextPutAll: '01:20:33 - Uso de tarjeta IV-07 en P4'; cr.
    salida nextPutAll: '01:40:00 - Corte de energia'; cr.
    salida cr.

    salida nextPutAll: '2. PROBLEMAS DETECTADOS'; cr.
    salida nextPutAll: 'Registro duplicado en tarjetas.csv'; cr.
    salida nextPutAll: 'Registro corrupto en tarjetas.csv'; cr.
    salida cr.

    salida nextPutAll: '3. PREGUNTAS Y RESPUESTAS'; cr.
    salida nextPutAll: 'Pregunta: Quien pudo abrir P8?'; cr.
    salida nextPutAll: 'Respuesta: Pendiente de Prolog'; cr.
    salida cr.

    salida nextPutAll: '4. EVIDENCIAS'; cr.
    salida nextPutAll: 'tarjetas.csv y energia.json'; cr.
].

Transcript show: 'Informe generado: ', archivo fullName; cr.
