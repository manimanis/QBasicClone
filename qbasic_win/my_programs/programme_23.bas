' ========================================================
' programme_23.bas
' Créé dans QBasic Studio
' ========================================================

CLS
PRINT "Bonjour depuis QBasic Studio !"

LET a = 259748

WHILE a <> 0
    r = a mod 10
    a = a \ 10
    PRINT r
WEND

END
