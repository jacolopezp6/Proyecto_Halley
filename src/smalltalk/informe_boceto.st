
(Object << #InformeForense package: 'Halley7') install.

InformeForense compile: 'eventosDesde: carpeta
    ^ (carpeta / ''eventos_prueba.txt'') readStreamDo: [ :entrada |
        entrada contents lines
    ]
'.

InformeForense compile: 'problemasDesde: carpeta
    ^ (carpeta / ''problemas_prueba.txt'') readStreamDo: [ :entrada |
        entrada contents lines
    ]
'.

InformeForense compile: 'generarDesde: carpeta
    | archivo eventos problemas |

    eventos := self eventosDesde: carpeta.
    problemas := self problemasDesde: carpeta.
    archivo := FileSystem disk workingDirectory / ''informe_halley7.txt''.

    archivo writeStreamDo: [ :salida |
        salida nextPutAll: ''INFORME HALLEY-7''; cr.
        salida cr.

        salida nextPutAll: ''1. LINEA DE TIEMPO''; cr.
        eventos do: [ :evento |
            salida nextPutAll: evento; cr.
        ].
        salida cr.

        salida nextPutAll: ''2. PROBLEMAS DETECTADOS''; cr.
        problemas do: [ :problema |
            salida nextPutAll: problema; cr.
        ].
        salida cr.

        salida nextPutAll: ''3. PREGUNTAS Y RESPUESTAS''; cr.
        salida nextPutAll: ''Pregunta: Quien pudo abrir P8?''; cr.
        salida nextPutAll: ''Respuesta: Pendiente de Prolog''; cr.
        salida cr.

        salida nextPutAll: ''4. EVIDENCIAS''; cr.
        salida nextPutAll: ''tarjetas.csv y energia.json''; cr.
    ].

    Transcript show: ''Informe generado: '', archivo fullName; cr.
'.
