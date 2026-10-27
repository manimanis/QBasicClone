'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: jemaf@free.fr                 ********
'********* telecharge sur le site jemaf.free.fr  ********
'********* Rectifie pour QBasic / Win64          ********
'********************************************************

' CUBES 3D
' Economiseur d'ecran ou un cube dessine en perspective
' technique se transforme de maniere fluide.
' Appuyez sur Echap ou 'Q' pour quitter.

DECLARE SUB trace (x!(), y!())
DECLARE SUB efface (x!(), y!())

SCREEN 9: CLS
RANDOMIZE TIMER

DIM SHARED x(4), y(4), xi(4), yi(4), xf(4), yf(4)

x(1) = 100: x(2) = 200: x(3) = 120
y(1) = 100: y(2) = 200: y(3) = 80

COLOR 7: LOCATE 1, 24: PRINT "Cube 3D - Appuyez sur Echap pour quitter";

DO
    xf(2) = RND * 600 + 20: xi(2) = x(2)
    xf(1) = RND * xf(2): xi(1) = x(1)
    xf(3) = RND * (620 - xf(2) + xf(1)): xi(3) = x(3)
    yf(2) = RND * 320 + 20: yi(2) = y(2)
    yf(1) = RND * yf(2): yi(1) = y(1)
    yf(3) = RND * (340 - yf(2) + yf(1)): yi(3) = y(3)

    inc = 150

    FOR i = 0 TO inc
        FOR j = 1 TO 3
            x(j) = xi(j) + i * (xf(j) - xi(j)) / inc
            y(j) = yi(j) + i * (yf(j) - yi(j)) / inc
        NEXT j

        CALL trace(x(), y())
        SLEEP 0.005
        CALL efface(x(), y())

        k$ = INKEY$
        IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN EXIT DO
    NEXT i

    k$ = INKEY$
    IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN EXIT DO
LOOP

CLS : SCREEN 0: WIDTH 80, 25
PRINT "Animation terminee."
END

SUB efface (x(), y())
    x(4) = x(2) + x(3) - x(1): y(4) = y(2) + y(3) - y(1)

    LINE (x(1), y(2))-(x(3), y(4)), 0
    LINE (x(3), y(3))-(x(3), y(4)), 0
    LINE (x(3), y(4))-(x(4), y(4)), 0
    LINE (x(1), y(1))-(x(2), y(2)), 0, B
    LINE (x(1), y(1))-(x(3), y(3)), 0
    LINE (x(2), y(1))-(x(4), y(3)), 0
    LINE (x(2), y(2))-(x(4), y(4)), 0
    LINE (x(3), y(3))-(x(4), y(3)), 0
    LINE (x(4), y(3))-(x(4), y(4)), 0
END SUB

SUB trace (x(), y())
    x(4) = x(2) + x(3) - x(1): y(4) = y(2) + y(3) - y(1)

    kp = &HF0F0: kc = &HFFFF

    IF (x(3) < x(1) OR y(4) > y(2)) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(1), y(2))-(x(3), y(4)), b, , a

    IF (x(3) < x(1)) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(3), y(3))-(x(3), y(4)), b, , a

    IF (x(4) > x(2) OR y(4) > y(2)) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(2), y(2))-(x(4), y(4)), b, , a

    IF (x(4) > x(2)) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(4), y(3))-(x(4), y(4)), b, , a

    IF (y(4) > y(2)) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(3), y(4))-(x(4), y(4)), b, , a

    IF (y(3) < y(1) OR x(3) < x(1)) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(1), y(1))-(x(3), y(3)), b, , a

    IF (x(4) > x(2) OR y(3) < y(1)) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(2), y(1))-(x(4), y(3)), b, , a

    IF y(3) < y(1) THEN a = kc: b = 15 ELSE a = kp: b = 9
    LINE (x(3), y(3))-(x(4), y(3)), b, , a

    LINE (x(1), y(1))-(x(2), y(2)), 15, B
END SUB
