
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

InformeForense compile: 'consultasDesde: carpeta
    ^ (carpeta / ''consultas_prueba.txt'') readStreamDo: [ :entrada |
        entrada contents lines
    ]
'.

InformeForense compile: 'generarDesde: carpeta
    | archivo eventos problemas consultas |

    eventos := self eventosDesde: carpeta.
    problemas := self problemasDesde: carpeta.
    consultas := self consultasDesde: carpeta.

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

        salida nextPutAll: ''3. PREGUNTAS, RESPUESTAS Y EVIDENCIAS''; cr.
        consultas do: [ :consulta |
            salida nextPutAll: consulta; cr.
        ].
    ].

    Transcript show: ''Informe generado: '', archivo fullName; cr.
'.
