(Object << #InformeForense package: 'Halley7') install.

InformeForense compile: 'eventos
    | lista |

    lista := OrderedCollection new.
    lista add: ''01:20:33 - Uso de tarjeta IV-07 en P4''.
    lista add: ''01:40:00 - Corte de energia''.

    ^ lista
'.

InformeForense compile: 'problemas
    | lista |

    lista := OrderedCollection new.
    lista add: ''Registro duplicado en tarjetas.csv''.
    lista add: ''Registro corrupto en tarjetas.csv''.

    ^ lista
'.

InformeForense compile: 'generar
    | archivo eventos problemas |

    eventos := self eventos.
    problemas := self problemas.
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

InformeForense new generar.
