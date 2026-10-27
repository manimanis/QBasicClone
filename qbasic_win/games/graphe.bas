'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: jemaf@free.fr                 ********
'********* telecharge sur le site jemaf.free.fr  ********
'********* Rectifie pour QBasic / Win64          ********
'********************************************************

' GRAPHE
' Traceur de fonctions mathematiques en mode graphique haute resolution.
' Fonction tracee : y = ln(x) sur [0.01, 5]

DECLARE SUB axes (xmin!, xmax!, xstep!, ymax!, ymin!, ystep!)

SCREEN 12: CLS
CONST PI = 3.141593

DIM SHARED x(1), y(1)

'*****************************************************************************
'               DEFINITION DU DOMAINE ET DES MARGES
'*****************************************************************************

xmin = 0
xmax = 5
xstep = 1
ymin = -5
ymax = 3
ystep = 1

CALL axes(xmin, xmax, xstep, ymax, ymin, ystep)

cy = 479 / (ymax - ymin)
yzero = ymax * cy
ypas = ystep * cy

'*****************************************************************************
'               TRACE DE LA COURBE
'*****************************************************************************

COLOR 14: LOCATE 2, 3: PRINT "Courbe : y = ln(x)";
COLOR 7: LOCATE 3, 3: PRINT "Appuyez sur une touche pour quitter...";

FOR i = 1 TO 638
    valid = 1
    FOR j = 0 TO 1
        x(j) = xmin + (i + j) * (xmax - xmin) / 639
        IF x(j) > 0.0001 THEN
            y(j) = LOG(x(j))
        ELSE
            valid = 0
        END IF
    NEXT j

    IF valid = 1 THEN
        y1 = yzero - y(0) * ypas / ystep
        y2 = yzero - y(1) * ypas / ystep

        ' Clamping pour eviter les debordements graphiques hors ecran
        IF y1 < 0 THEN y1 = 0
        IF y1 > 479 THEN y1 = 479
        IF y2 < 0 THEN y2 = 0
        IF y2 > 479 THEN y2 = 479

        LINE (i, y1)-(i + 1, y2), 10
    END IF
NEXT i

DO
    k$ = INKEY$
LOOP WHILE k$ = ""

CLS : SCREEN 0: WIDTH 80, 25
PRINT "Fin du programme Graphe."
END

SUB axes (xmin, xmax, xstep, ymax, ymin, ystep)

'*****************************************************************************
'               TRACE DES AXES
'*****************************************************************************

cx = 639 / (xmax - xmin)
cy = 479 / (ymax - ymin)
xzero = -xmin * cx
yzero = ymax * cy
xpas = xstep * cx
ypas = ystep * cy

' Axe vertical Y
LINE (xzero, 1)-(xzero, 479), 15

' Graduations axe Y
FOR i = 1 TO FIX(ABS(ymin) / ystep)
    LINE (xzero - 3, yzero + i * ypas)-(xzero + 3, yzero + i * ypas), 15
NEXT i

FOR i = 1 TO FIX(ABS(ymax) / ystep)
    LINE (xzero - 3, yzero - i * ypas)-(xzero + 3, yzero - i * ypas), 15
NEXT i

' Axe horizontal X
LINE (1, yzero)-(639, yzero), 15

' Graduations axe X
IF xstep > 0 THEN
    FOR i = 1 TO FIX(ABS(xmin) / xstep)
        LINE (xzero - i * xpas, yzero - 3)-(xzero - i * xpas, yzero + 3), 15
    NEXT i

    FOR i = 1 TO FIX(ABS(xmax) / xstep)
        LINE (xzero + i * xpas, yzero - 3)-(xzero + i * xpas, yzero + 3), 15
    NEXT i
END IF

END SUB
