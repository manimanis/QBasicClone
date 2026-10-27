'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: jemaf@free.fr                 ********
'********* telecharge sur le site jemaf.free.fr  ********
'********************************************************

'COLUMNS POUR QBASIC
'Alignez 3 joyaux de meme couleur horizontalement,
'verticalement ou en diagonale !

DECLARE SUB Choixauto ()
DECLARE FUNCTION calcpoints! (xt!, ct!)
DECLARE FUNCTION auto! ()
DECLARE SUB Choix ()
DECLARE SUB FIN (col!(), points!)
DECLARE SUB aide ()
DECLARE FUNCTION mizajour! (tabl!(), tabl1!(), points!)
DECLARE SUB verif (tabl!(), tabl1!(), points!)
DECLARE SUB affiche (tabl!(), tabl1!(), maxi!())
DECLARE FUNCTION clavier! (k$)
DECLARE SUB affcol (x!, y!, c1!, c2!, c3!)
DECLARE SUB init ()
DECLARE SUB redessineJeu ()

RANDOMIZE TIMER

DIM SHARED col(1 TO 6)
col(1) = 7: col(2) = 9: col(3) = 10: col(4) = 12: col(5) = 13: col(6) = 14
DIM SHARED tabl(1 TO 18, 1 TO 6)
DIM SHARED tabl1(1 TO 18, 1 TO 6)
DIM SHARED maxi(1 TO 6) ' 1ere case libre
DIM SHARED parmi(1 TO 18, 0 TO 1)
DIM SHARED Mode, colpos, colauto, x, y, xauto, c1, c2, c3, c1b, c2b, c3b
DIM SHARED points, partieEnCours, demandeQuitter

DO
    Choix
    IF Mode = 3 THEN EXIT DO

    init
    FOR i = 1 TO 6: maxi(i) = 18: NEXT i
    FOR r = 1 TO 18
        FOR c = 1 TO 6
            tabl(r, c) = 0
            tabl1(r, c) = 0
        NEXT c
    NEXT r

    c1 = col(INT(RND * 6) + 1)
    c2 = col(INT(RND * 6) + 1)
    c3 = col(INT(RND * 6) + 1)
    points = 0
    partieEnCours = 1
    demandeQuitter = 0

    DO
        IF Mode = 2 THEN Choixauto
        x = 4  ' 1 <= x <= 6
        y = 1  ' 1 <= y <= 18
        colpos = 0

        c1b = col(INT(RND * 6) + 1)
        c2b = col(INT(RND * 6) + 1)
        c3b = col(INT(RND * 6) + 1)

        COLOR c3b: LOCATE 10, 70: PRINT STRING$(3, 219)
        COLOR c2b: LOCATE 11, 70: PRINT STRING$(3, 219)
        COLOR c1b: LOCATE 12, 70: PRINT STRING$(3, 219)

        DO
            affcol x, y, c1, c2, c3

            ' Vitesse de chute selon le score
            IF points < 500 THEN
                delaiLigne# = 0.45
            ELSEIF points < 1500 THEN
                delaiLigne# = 0.32
            ELSE
                delaiLigne# = 0.22
            END IF
            IF Mode = 2 THEN delaiLigne# = 0.12

            tLigneDebut# = TIMER
            dropVoulu = 0

            DO
                act = 0
                IF Mode = 1 THEN
                    k$ = INKEY$
                    IF k$ <> "" THEN
                        IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN
                            demandeQuitter = 1
                            partieEnCours = 0
                            EXIT DO
                        ELSEIF UCASE$(k$) = "H" OR RIGHT$(k$, 1) = ";" THEN
                            aide
                        ELSE
                            act = clavier(k$)
                        END IF
                    END IF
                ELSE
                    k$ = INKEY$
                    IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN
                        demandeQuitter = 1
                        partieEnCours = 0
                        EXIT DO
                    END IF
                    act = auto
                END IF

                IF act > 0 THEN
                    affcol x, y, 0, 0, 0
                    SELECT CASE act
                        CASE 1: ' Gauche
                            IF x > 1 THEN
                                IF maxi(x - 1) >= y THEN x = x - 1
                            END IF
                        CASE 3: ' Droite
                            IF x < 6 THEN
                                IF maxi(x + 1) >= y THEN x = x + 1
                            END IF
                        CASE 5: ' Rotation
                            c4 = c1: c1 = c2: c2 = c3: c3 = c4
                            colpos = (colpos + 1) MOD 3
                        CASE 2: ' Chute directe
                            y = maxi(x)
                            dropVoulu = 1
                    END SELECT
                    affcol x, y, c1, c2, c3
                    act = 0
                    IF dropVoulu = 1 THEN EXIT DO
                END IF

                SLEEP 0.01
                tEcoule# = TIMER - tLigneDebut#
                IF tEcoule# < 0 THEN tEcoule# = tEcoule# + 86400
            LOOP UNTIL tEcoule# >= delaiLigne#

            IF demandeQuitter = 1 THEN EXIT DO

            IF y < maxi(x) THEN affcol x, y, 0, 0, 0
            y = y + 1

        LOOP UNTIL y > maxi(x)

        IF demandeQuitter = 1 THEN EXIT DO

        IF y <= 3 THEN
            FIN col(), points
            EXIT DO
        END IF

        tabl(maxi(x), x) = c1
        tabl(maxi(x) - 1, x) = c2
        tabl(maxi(x) - 2, x) = c3
        maxi(x) = maxi(x) - 3

        DO
            verif tabl(), tabl1(), points
        LOOP UNTIL mizajour(tabl(), tabl1(), points) = 0

        FOR j = 1 TO 6
            i = 0
            l = 0
            DO
                i = i + 1
                IF i > 18 THEN l = 1 ELSE IF tabl(i, j) > 0 THEN l = 1
            LOOP UNTIL l = 1
            maxi(j) = i - 1
        NEXT j

        c1 = c1b: c2 = c2b: c3 = c3b

    LOOP WHILE partieEnCours = 1

LOOP WHILE Mode <> 3

COLOR 15: CLS
PRINT "Merci d'avoir joue a Columns !"
SYSTEM

SUB affcol (x, y, c1, c2, c3)
    IF y >= 3 THEN LOCATE 4 + y - 2, 28 + 3 * x: COLOR c3: PRINT STRING$(3, 219)
    IF y >= 2 THEN LOCATE 4 + y - 1, 28 + 3 * x: COLOR c2: PRINT STRING$(3, 219)
    IF y >= 1 THEN LOCATE 4 + y, 28 + 3 * x: COLOR c1: PRINT STRING$(3, 219)
END SUB

SUB affiche (tabl(), tabl1(), maxi())
    COLOR 15
    FOR j1 = 1 TO 6
        LOCATE 22, 3 + 3 * j1: PRINT maxi(j1)
        FOR i = 1 TO 18
            LOCATE 2 + i, 3 + 3 * j1: PRINT tabl(i, j1)
            LOCATE 2 + i, 53 + 3 * j1: PRINT tabl1(i, j1)
        NEXT i
    NEXT j1
END SUB

SUB aide
    CLS
    COLOR 13: LOCATE 4, 30: PRINT "=== AIDE DE COLUMNS ==="
    COLOR 15
    LOCATE 7, 5: PRINT "Le jeu consiste a aligner au moins 3 blocs de meme couleur :"
    LOCATE 8, 8: PRINT "- horizontalement, verticalement ou en diagonale !"
    LOCATE 11, 8: PRINT "- Gauche / Droite : Deplacer la colonne"
    LOCATE 13, 8: PRINT "- Haut / Espace   : Faire pivoter l'ordre des 3 couleurs"
    LOCATE 15, 8: PRINT "- Bas             : Faire tomber immediatement la colonne"
    LOCATE 17, 8: PRINT "- Q / Echap       : Quitter la partie"
    COLOR 14
    LOCATE 20, 8: PRINT "Plus le score grimpe, plus la vitesse augmente !"
    COLOR 11
    LOCATE 23, 15: PRINT "Appuyez sur une touche pour revenir a la partie...";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    redessineJeu
END SUB

FUNCTION auto
    IF x < xauto THEN
        auto = 3
    ELSEIF x > xauto THEN
        auto = 1
    ELSEIF x = xauto THEN
        IF colauto > colpos THEN auto = 5 ELSE auto = 0
    END IF
END FUNCTION

FUNCTION calcpoints (xt, ct)
    DIM tablt(-1 TO 20, -1 TO 8)
    DIM colt(1 TO 3)

    FOR i = -1 TO 20
        FOR j = -1 TO 8
            IF j >= 1 AND j <= 6 AND i >= 1 AND i <= 18 THEN
                tablt(i, j) = tabl(i, j)
            ELSE
                tablt(i, j) = 1
            END IF
        NEXT j
    NEXT i

    SELECT CASE ct
        CASE 0: colt(1) = c1: colt(2) = c2: colt(3) = c3
        CASE 1: colt(1) = c2: colt(2) = c3: colt(3) = c1
        CASE 2: colt(1) = c3: colt(2) = c1: colt(3) = c2
    END SELECT

    tablt(maxi(xt), xt) = colt(1)
    tablt(maxi(xt) - 1, xt) = colt(2)
    tablt(maxi(xt) - 2, xt) = colt(3)

    pointt = 0
    FOR i = 1 TO 3
        IF tablt(maxi(xt) - i + 1 - 1, xt - 1) = colt(i) THEN
            pointt = pointt + 2
            IF tablt(maxi(xt) - i + 1 - 2, xt - 2) = colt(i) OR tablt(maxi(xt) - i + 1 + 1, xt + 1) = colt(i) THEN pointt = pointt + 8
            IF tablt(maxi(xt) - i + 1 - 2, xt - 2) = 0 OR tablt(maxi(xt) - i + 1 + 1, xt + 1) = 0 THEN pointt = pointt + 4
        END IF

        IF tablt(maxi(xt) - i + 1, xt - 1) = colt(i) THEN
            pointt = pointt + 2
            IF tablt(maxi(xt) - i + 1, xt - 2) = colt(i) OR tablt(maxi(xt) - i + 1, xt + 1) = colt(i) THEN pointt = pointt + 8
            IF tablt(maxi(xt) - i + 1, xt - 2) = 0 OR tablt(maxi(xt) - i + 1, xt + 1) = 0 THEN pointt = pointt + 4
        END IF

        IF tablt(maxi(xt) - i + 1 + 1, xt - 1) = colt(i) THEN
            pointt = pointt + 2
            IF tablt(maxi(xt) - i + 1 + 2, xt - 2) = colt(i) OR tablt(maxi(xt) - i + 1 - 1, xt + 1) = colt(i) THEN pointt = pointt + 8
            IF tablt(maxi(xt) - i + 1 + 2, xt - 2) = 0 OR tablt(maxi(xt) - i + 1 - 1, xt + 1) = 0 THEN pointt = pointt + 4
        END IF

        IF tablt(maxi(xt) - i + 1 + 1, xt) = colt(i) THEN
            pointt = pointt + 2
            IF tablt(maxi(xt) - i + 1 + 2, xt) = colt(i) OR tablt(maxi(xt) - i + 1 - 1, xt) = colt(i) THEN pointt = pointt + 8
            IF tablt(maxi(xt) - i + 1 + 2, xt) = 0 OR tablt(maxi(xt) - i + 1 - 1, xt) = 0 THEN pointt = pointt + 4
        END IF

        IF tablt(maxi(xt) - i + 1 + 1, xt + 1) = colt(i) THEN
            pointt = pointt + 2
            IF tablt(maxi(xt) - i + 1 + 2, xt + 2) = colt(i) OR tablt(maxi(xt) - i + 1 - 1, xt - 1) = colt(i) THEN pointt = pointt + 8
            IF tablt(maxi(xt) - i + 1 + 2, xt + 2) = 0 OR tablt(maxi(xt) - i + 1 - 1, xt - 1) = 0 THEN pointt = pointt + 4
        END IF

        IF tablt(maxi(xt) - i + 1, xt + 1) = colt(i) THEN
            pointt = pointt + 2
            IF tablt(maxi(xt) - i + 1, xt + 2) = colt(i) OR tablt(maxi(xt) - i + 1, xt - 1) = colt(i) THEN pointt = pointt + 8
            IF tablt(maxi(xt) - i + 1, xt + 2) = 0 OR tablt(maxi(xt) - i + 1, xt - 1) = 0 THEN pointt = pointt + 4
        END IF

        IF tablt(maxi(xt) - i + 1 - 1, xt + 1) = colt(i) THEN
            pointt = pointt + 2
            IF tablt(maxi(xt) - i + 1 - 2, xt + 2) = colt(i) OR tablt(maxi(xt) - i + 1 + 1, xt - 1) = colt(i) THEN pointt = pointt + 8
            IF tablt(maxi(xt) - i + 1 - 2, xt + 2) = 0 OR tablt(maxi(xt) - i + 1 + 1, xt - 1) = 0 THEN pointt = pointt + 4
        END IF
    NEXT i

    calcpoints = pointt + INT(maxi(xt) / 5)
END FUNCTION

SUB Choix
    CLS: SCREEN 9: COLOR 15, 0
    COLOR 13: LOCATE 5, 30: PRINT "COLUMNS For QBasic"
    COLOR 15: LOCATE 8, 33: PRINT "Modes de jeu"
    LOCATE 11, 31: PRINT "1 : Jouer"
    LOCATE 12, 31: PRINT "2 : Demonstration"
    LOCATE 13, 31: PRINT "3 : Quitter"
    LOCATE 16, 31: PRINT "Votre choix ? ";

    DO
        k$ = UCASE$(INKEY$)
    LOOP UNTIL k$ = "1" OR k$ = "2" OR k$ = "3" OR k$ = "Q" OR k$ = CHR$(27)

    IF k$ = "3" OR k$ = "Q" OR k$ = CHR$(27) THEN
        Mode = 3
    ELSEIF k$ = "1" THEN
        Mode = 1
    ELSE
        Mode = 2
    END IF
END SUB

SUB Choixauto
    maxScore = -1
    maxp = 0
    xauto = 1
    colauto = 0

    FOR i = 1 TO 6
        FOR j = 0 TO 2
            pointt = calcpoints(i, j)
            IF pointt > maxScore THEN
                maxScore = pointt
                maxp = 1
                parmi(1, 0) = i
                parmi(1, 1) = j
            ELSEIF pointt = maxScore AND maxp < 18 THEN
                maxp = maxp + 1
                parmi(maxp, 0) = i
                parmi(maxp, 1) = j
            END IF
        NEXT j
    NEXT i

    IF maxp > 0 THEN
        maxrnd = INT(RND * maxp) + 1
        xauto = parmi(maxrnd, 0)
        colauto = parmi(maxrnd, 1)
    END IF
END SUB

FUNCTION clavier (k$)
    IF LEN(k$) = 2 THEN
        SELECT CASE RIGHT$(k$, 1)
            CASE "K": clavier = 1  ' Gauche
            CASE "M": clavier = 3  ' Droite
            CASE "H": clavier = 5  ' Haut
            CASE "P": clavier = 2  ' Bas
            CASE ELSE: clavier = 0
        END SELECT
    ELSE
        SELECT CASE UCASE$(k$)
            CASE "4", "A", "J": clavier = 1  ' Gauche
            CASE "6", "D", "L": clavier = 3  ' Droite
            CASE "8", "Z", "W", "I", " ": clavier = 5  ' Rotation
            CASE "2", "S", "K": clavier = 2  ' Bas
            CASE ELSE: clavier = 0
        END SELECT
    END IF
END FUNCTION

SUB FIN (col(), points)
    FOR j = 1 TO 6
        FOR i = 18 TO 3 STEP -3
            c1 = col(INT(RND * 6) + 1)
            c2 = col(INT(RND * 6) + 1)
            c3 = col(INT(RND * 6) + 1)
            affcol j, i, c1, c2, c3
            SLEEP 0.02
        NEXT i
    NEXT j

    COLOR 15
    LOCATE 11, 32: PRINT STRING$(16, CHR$(176))
    LOCATE 12, 32: PRINT STRING$(2, CHR$(176)) + " GAME  OVER " + STRING$(2, CHR$(176))
    LOCATE 13, 32: PRINT STRING$(16, CHR$(176))

    LOCATE 15, 30: COLOR 14: PRINT "Score final : "; points
    LOCATE 17, 26: COLOR 11: PRINT "Appuyez sur une touche...";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
END SUB

SUB init
    CLS: SCREEN 9
    COLOR 10: LOCATE 2, 32: PRINT "*** COLUMNS ***"

    larg = 18
    haut = 18

    COLOR 15
    FOR i = 1 TO haut
        LOCATE 4 + i, 30: PRINT CHR$(219) + SPACE$(larg) + CHR$(219)
    NEXT i
    LOCATE 4 + haut + 1, 30: PRINT STRING$(larg + 2, CHR$(219))

    COLOR 13: LOCATE 7, 58: PRINT "Points : "; points
    LOCATE 10, 58: PRINT "Prochain :"
    COLOR 8: LOCATE 24, 65: PRINT "(F1/H: Aide, Q: Quitter)";
    COLOR 15
END SUB

SUB redessineJeu
    init
    ' Redessiner tous les blocs poses
    FOR r = 1 TO 18
        FOR c = 1 TO 6
            IF tabl(r, c) > 0 THEN
                LOCATE 4 + r, 28 + 3 * c
                COLOR tabl(r, c): PRINT STRING$(3, 219)
            END IF
        NEXT c
    NEXT r

    ' Redessiner la colonne en cours
    affcol x, y, c1, c2, c3

    ' Redessiner le prochain bloc
    COLOR c3b: LOCATE 10, 70: PRINT STRING$(3, 219)
    COLOR c2b: LOCATE 11, 70: PRINT STRING$(3, 219)
    COLOR c1b: LOCATE 12, 70: PRINT STRING$(3, 219)

    COLOR 13: LOCATE 7, 58: PRINT "Points : "; points; "   "
END SUB

FUNCTION mizajour (tabl(), tabl1(), points)
    k1 = 0

    FOR i = 18 TO 3 STEP -1
        FOR j = 1 TO 6
            IF tabl1(i, j) = -1 THEN
                k1 = 1
                tabl1(i, j) = 1
                IF tabl1(2, j) = -1 THEN tabl1(2, j) = 1
                IF tabl1(1, j) = -1 THEN tabl1(1, j) = 1
                IF i > 3 THEN
                    affcol j, i, 0, tabl(i - 1, j), tabl(i - 2, j)
                ELSE
                    affcol j, i, 0, tabl(i - 1, j) * (1 - tabl1(i - 1, j)), tabl(i - 2, j) * (1 - tabl1(i - 2, j))
                END IF
            END IF
        NEXT j
    NEXT i

    SLEEP 0.08

    FOR i = 18 TO 3 STEP -1
        FOR j = 1 TO 6
            IF tabl1(i, j) = 1 THEN
                affcol j, i, tabl(i, j), tabl(i - 1, j), tabl(i - 2, j)
            END IF
        NEXT j
    NEXT i

    SLEEP 0.08

    FOR i = 18 TO 3 STEP -1
        FOR j = 1 TO 6
            IF tabl1(i, j) = 1 THEN
                affcol j, i, 0, tabl(i - 1, j), tabl(i - 2, j)
            END IF
        NEXT j
    NEXT i

    COLOR 13: LOCATE 7, 66: PRINT points

    DO
        k = 0
        FOR j = 1 TO 6
            FOR i = 18 TO 2 STEP -1
                IF tabl1(i, j) = 1 OR k = j THEN
                    k = j
                    IF i > 3 THEN
                        affcol j, i, tabl(i - 1, j), tabl(i - 2, j), tabl(i - 3, j)
                    ELSEIF i = 3 THEN
                        affcol j, i, tabl(i - 1, j), tabl(i - 2, j), 0
                    END IF
                    tabl(i, j) = tabl(i - 1, j): tabl1(i, j) = tabl1(i - 1, j)
                END IF
            NEXT i
            IF k = j THEN tabl(1, j) = 0: tabl1(1, j) = 0
        NEXT j
    LOOP UNTIL k = 0

    mizajour = k1
END FUNCTION

SUB verif (tabl(), tabl1(), points)
    ' HORIZONTAL
    FOR i = 1 TO 18
        FOR j = 1 TO 4
            c = tabl(i, j)
            IF c > 0 THEN
                IF tabl(i, j + 1) = c AND tabl(i, j + 2) = c THEN
                    k = 0
                    points = points + 10
                    DO
                        tabl1(i, j + k) = -1
                        IF k > 3 THEN points = points + 20
                        k = k + 1
                        IF j + k > 6 THEN l = 1 ELSE IF tabl(i, j + k) <> c THEN l = 1 ELSE l = 0
                    LOOP UNTIL l = 1
                END IF
            END IF
        NEXT j
    NEXT i

    ' VERTICAL
    FOR i = 1 TO 16
        FOR j = 1 TO 6
            c = tabl(i, j)
            IF c > 0 THEN
                IF tabl(i + 1, j) = c AND tabl(i + 2, j) = c THEN
                    k = 0
                    points = points + 10
                    DO
                        tabl1(i + k, j) = -1
                        IF k > 3 THEN points = points + 20
                        k = k + 1
                        IF i + k > 18 THEN l = 1 ELSE IF tabl(i + k, j) <> c THEN l = 1 ELSE l = 0
                    LOOP UNTIL l = 1
                END IF
            END IF
        NEXT j
    NEXT i

    ' DIAGONALE DESCENDANTE
    FOR i = 1 TO 16
        FOR j = 1 TO 4
            c = tabl(i, j)
            IF c > 0 THEN
                IF tabl(i + 1, j + 1) = c AND tabl(i + 2, j + 2) = c THEN
                    k = 0
                    points = points + 10
                    DO
                        tabl1(i + k, j + k) = -1
                        IF k > 3 THEN points = points + 20
                        k = k + 1
                        IF j + k > 6 OR i + k > 18 THEN l = 1 ELSE IF tabl(i + k, j + k) <> c THEN l = 1 ELSE l = 0
                    LOOP UNTIL l = 1
                END IF
            END IF
        NEXT j
    NEXT i

    ' DIAGONALE MONTANTE
    FOR i = 3 TO 18
        FOR j = 1 TO 4
            c = tabl(i, j)
            IF c > 0 THEN
                IF tabl(i - 1, j + 1) = c AND tabl(i - 2, j + 2) = c THEN
                    k = 0
                    points = points + 10
                    DO
                        tabl1(i - k, j + k) = -1
                        IF k > 3 THEN points = points + 20
                        k = k + 1
                        IF j + k > 6 OR i - k < 1 THEN l = 1 ELSE IF tabl(i - k, j + k) <> c THEN l = 1 ELSE l = 0
                    LOOP UNTIL l = 1
                END IF
            END IF
        NEXT j
    NEXT i
END SUB
