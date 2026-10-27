'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: jemaf@free.fr                 ********
'********* telecharge sur le site jemaf.free.fr  ********
'********************************************************

'DEMINEUR
'Trouvez toutes les mines sans les faire exploser !

DECLARE SUB aide ()
DECLARE SUB depl ()
DECLARE SUB trace ()
DECLARE SUB interroge ()
DECLARE SUB init ()
DECLARE SUB valeur (i!, j!)
DECLARE SUB dessineCase (r!, c!)
DECLARE SUB redessine ()

SCREEN 9: CLS

DIM SHARED tabl(0 TO 11, 0 TO 11)
DIM SHARED tabl1(0 TO 11, 0 TO 11) ' 0=cache, 1=ouvert, 2=drapeau
DIM SHARED px, py, nbmines_restantes, perdu, quitte
DIM SHARED tdeb#, X0, Y0, dX, dY

CONST nbmin = 13
X0 = 191
Y0 = 112
dX = 24
dY = 14

DO
    CALL init
    CLS
    CALL trace
    px = 1: py = 1
    perdu = 0
    quitte = 0
    tdeb# = TIMER

    CALL depl

    IF quitte = 1 THEN EXIT DO

    LOCATE 22, 28: PRINT STRING$(40, " ");
    LOCATE 23, 28: PRINT STRING$(40, " ");
    IF perdu = 1 THEN
        LOCATE 22, 32: COLOR 12: PRINT "BOOM ! PERDU !";
        PLAY "O2L16 D# C O1 A#2"
    ELSE
        tfin# = TIMER
        duree = INT(tfin# - tdeb#)
        IF duree < 0 THEN duree = duree + 86400
        LOCATE 22, 30: COLOR 10: PRINT "BRAVO ! VICTOIRE !";
        LOCATE 23, 31: COLOR 14: PRINT "(en "; LTRIM$(STR$(duree)); " secondes)";
        PLAY "O4L16 C E G O5 C2"
    END IF

    LOCATE 24, 25: COLOR 11: PRINT "Voulez-vous rejouer ? (O/N) : ";
    rep$ = ""
    DO
        k$ = UCASE$(INKEY$)
        IF k$ = "O" OR k$ = "N" OR k$ = CHR$(27) OR k$ = "Q" THEN rep$ = k$
    LOOP UNTIL rep$ <> ""

LOOP WHILE rep$ = "O"

COLOR 15: CLS
PRINT "Merci d'avoir joue au Demineur !"
SYSTEM

SUB aide
    CLS
    COLOR 14: LOCATE 3, 26: PRINT "=== REGLES DU DEMINEUR ==="
    COLOR 15
    LOCATE 6, 8: PRINT "1. Le but est de decouvrir toutes les cases sans mine."
    LOCATE 8, 8: PRINT "2. Deplacez le curseur avec les touches Flechees."
    LOCATE 10, 8: PRINT "3. Appuyez sur Entree pour ouvrir la case courante."
    LOCATE 12, 8: PRINT "4. Appuyez sur Espace pour marquer un drapeau [F] sur une case suspectee."
    LOCATE 14, 8: PRINT "5. Un chiffre indique le nombre exact de mines dans les cases voisines."
    LOCATE 16, 8: PRINT "6. Appuyez sur Entree sur une case ouverte pour reveler ses voisines."
    LOCATE 18, 8: PRINT "7. Si vous ouvrez une mine, c'est perdu !"
    COLOR 11
    LOCATE 22, 18: PRINT "Appuyez sur une touche pour revenir a la partie...";
    DO
        k$ = INKEY$
    LOOP UNTIL k$ <> ""
    CALL redessine
END SUB

SUB depl
    CALL dessineCase(py, px)

    DO
        ' Mettre en valeur la case courante
        x = X0 + (px - 1) * dX
        y = Y0 + (py - 1) * dY
        LINE (x + 1, y + 1)-(x + dX - 1, y + dY - 1), 14, B

        DO
            k$ = INKEY$
        LOOP UNTIL k$ <> ""

        ' Restaurer la bordure normale de la case
        CALL dessineCase(py, px)

        ' Quitter
        IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN
            quitte = 1
            EXIT SUB
        END IF

        ' Aide
        IF UCASE$(k$) = "H" OR RIGHT$(k$, 1) = ";" THEN
            CALL aide
        END IF

        ' Drapeau (Espace)
        IF k$ = " " THEN
            IF tabl1(py, px) = 0 THEN
                tabl1(py, px) = 2
                nbmines_restantes = nbmines_restantes - 1
                CALL dessineCase(py, px)
            ELSEIF tabl1(py, px) = 2 THEN
                tabl1(py, px) = 0
                nbmines_restantes = nbmines_restantes + 1
                CALL dessineCase(py, px)
            END IF
            LOCATE 10, 5: COLOR 13: PRINT "Mines : "; nbmines_restantes; "  ";
        END IF

        ' Ouvrir (Entree)
        IF k$ = CHR$(13) THEN
            IF tabl1(py, px) <> 2 THEN
                CALL interroge
                IF perdu = 1 THEN EXIT SUB
            END IF
        END IF

        ' Deplacement
        oldx = px: oldy = py
        IF LEN(k$) = 2 THEN
            SELECT CASE RIGHT$(k$, 1)
                CASE "K": px = px - 1: IF px < 1 THEN px = 10
                CASE "M": px = px + 1: IF px > 10 THEN px = 1
                CASE "H": py = py - 1: IF py < 1 THEN py = 10
                CASE "P": py = py + 1: IF py > 10 THEN py = 1
            END SELECT
        ELSE
            SELECT CASE UCASE$(k$)
                CASE "4": px = px - 1: IF px < 1 THEN px = 10
                CASE "6": px = px + 1: IF px > 10 THEN px = 1
                CASE "8": py = py - 1: IF py < 1 THEN py = 10
                CASE "2": py = py + 1: IF py > 10 THEN py = 1
            END SELECT
        END IF

        ' Verifier la condition de victoire :
        ' Toutes les cases sans mine (tabl <> -1) doivent etre ouvertes (tabl1 = 1)
        cases_restantes = 0
        FOR r = 1 TO 10
            FOR c = 1 TO 10
                IF tabl(r, c) <> -1 AND tabl1(r, c) <> 1 THEN
                    cases_restantes = cases_restantes + 1
                END IF
            NEXT c
        NEXT r

    LOOP UNTIL cases_restantes = 0
END SUB

SUB dessineCase (r, c)
    x = X0 + (c - 1) * dX
    y = Y0 + (r - 1) * dY

    IF tabl1(r, c) = 0 THEN
        ' Case non decouverte
        LINE (x + 2, y + 2)-(x + dX - 2, y + dY - 2), 7, BF
    ELSEIF tabl1(r, c) = 2 THEN
        ' Drapeau
        LINE (x + 2, y + 2)-(x + dX - 2, y + dY - 2), 12, BF
        LOCATE 8 + r, 22 + 3 * c
        COLOR 15: PRINT " F ";
    ELSEIF tabl1(r, c) = 1 THEN
        ' Case decouverte
        LINE (x + 2, y + 2)-(x + dX - 2, y + dY - 2), 0, BF
        CALL valeur(r, c)
    END IF
END SUB

SUB init
    RANDOMIZE TIMER

    FOR r = 0 TO 11
        FOR c = 0 TO 11
            tabl(r, c) = 0
            tabl1(r, c) = 0
        NEXT c
    NEXT r

    nbmines_restantes = nbmin

    FOR i = 1 TO nbmin
        DO
            x = INT(RND * 10) + 1
            y = INT(RND * 10) + 1
        LOOP UNTIL tabl(x, y) = 0
        tabl(x, y) = -1
    NEXT i

    FOR i = 1 TO 10
        FOR j = 1 TO 10
            IF tabl(i, j) <> -1 THEN
                n = 0
                FOR di = -1 TO 1
                    FOR dj = -1 TO 1
                        IF tabl(i + di, j + dj) = -1 THEN n = n + 1
                    NEXT dj
                NEXT di
                tabl(i, j) = n
            END IF
        NEXT j
    NEXT i
END SUB

SUB interroge
    ' Si on clique sur une case deja ouverte avec un chiffre :
    ' ouvrir automatiquement les voisines non-drapeaux si les drapeaux suffisent
    IF tabl1(py, px) = 1 AND tabl(py, px) > 0 THEN
        nb_drapeaux = 0
        FOR di = -1 TO 1
            FOR dj = -1 TO 1
                IF tabl1(py + di, px + dj) = 2 THEN nb_drapeaux = nb_drapeaux + 1
            NEXT dj
        NEXT di
        IF nb_drapeaux = tabl(py, px) THEN
            FOR di = -1 TO 1
                FOR dj = -1 TO 1
                    nr = py + di: nc = px + dj
                    IF nr >= 1 AND nr <= 10 AND nc >= 1 AND nc <= 10 THEN
                        IF tabl1(nr, nc) = 0 THEN
                            IF tabl(nr, nc) = -1 THEN
                                ' Mine touchee !
                                tabl1(nr, nc) = 1
                                CALL dessineCase(nr, nc)
                                perdu = 1
                                EXIT SUB
                            ELSE
                                tabl1(nr, nc) = 1
                                CALL dessineCase(nr, nc)
                            END IF
                        END IF
                    END IF
                NEXT dj
            NEXT di
        END IF
        EXIT SUB
    END IF

    ' Ouverture normale
    IF tabl(py, px) = -1 THEN
        ' Mine explosee !
        tabl1(py, px) = 1
        FOR r = 1 TO 10
            FOR c = 1 TO 10
                IF tabl(r, c) = -1 THEN
                    tabl1(r, c) = 1
                    CALL dessineCase(r, c)
                END IF
            NEXT c
        NEXT r
        perdu = 1
        EXIT SUB
    END IF

    tabl1(py, px) = 1
    CALL dessineCase(py, px)

    ' Si la case est vide (0), propager a tous les voisins
    IF tabl(py, px) = 0 THEN
        tabl1(py, px) = 3 ' Marque pour propagation
        DO
            zero = 0
            FOR r = 1 TO 10
                FOR c = 1 TO 10
                    IF tabl(r, c) = 0 AND tabl1(r, c) = 3 THEN
                        tabl1(r, c) = 1
                        FOR dr = -1 TO 1
                            FOR dc = -1 TO 1
                                nr = r + dr: nc = c + dc
                                IF nr >= 1 AND nr <= 10 AND nc >= 1 AND nc <= 10 THEN
                                    IF tabl1(nr, nc) = 0 THEN
                                        IF tabl(nr, nc) = 0 THEN
                                            tabl1(nr, nc) = 3
                                            zero = 1
                                        ELSEIF tabl(nr, nc) > 0 THEN
                                            tabl1(nr, nc) = 1
                                        END IF
                                        CALL dessineCase(nr, nc)
                                    END IF
                                END IF
                            NEXT dc
                        NEXT dr
                    END IF
                NEXT c
            NEXT r
        LOOP UNTIL zero = 0
    END IF
END SUB

SUB redessine
    CALL trace
    LOCATE 10, 5: COLOR 13: PRINT "Mines : "; nbmines_restantes; "  ";
    FOR r = 1 TO 10
        FOR c = 1 TO 10
            CALL dessineCase(r, c)
        NEXT c
    NEXT r
END SUB

SUB trace
    LOCATE 2, 29: COLOR 14: PRINT "==================";
    LOCATE 3, 29: COLOR 15: PRINT "***  DEMINEUR  ***";
    LOCATE 4, 29: COLOR 14: PRINT "==================";

    COLOR 13
    LOCATE 8, 3: PRINT "Mines a trouver :"
    LOCATE 10, 5: PRINT "Mines : "; nbmines_restantes; "  "

    COLOR 7
    LOCATE 13, 3: PRINT "Fleches : Deplacement"
    LOCATE 14, 3: PRINT "Entree  : Decouvrir"
    LOCATE 15, 3: PRINT "Espace  : Drapeau [F]"
    LOCATE 16, 3: PRINT "H / F1  : Aide"
    LOCATE 17, 3: PRINT "Q / Esc : Quitter"

    COLOR 15
    LINE (X0 - 2, Y0 - 1)-(X0 + 10 * dX + 2, Y0 + 10 * dY + 1), 7, B
    LINE (X0 - 5, Y0 - 3)-(X0 + 10 * dX + 5, Y0 + 10 * dY + 3), 15, B

    FOR i = 1 TO 10
        FOR j = 1 TO 10
            x = X0 + (i - 1) * dX
            y = Y0 + (j - 1) * dY
            LINE (x + 2, y + 2)-(x + dX - 2, y + dY - 2), 7, BF
        NEXT j
    NEXT i
END SUB

SUB valeur (i, j)
    LOCATE 8 + i, 22 + 3 * j
    SELECT CASE tabl(i, j)
        CASE -1:
            COLOR 12: PRINT " * ";
        CASE 0:
            PRINT "   ";
        CASE 1:
            COLOR 9: PRINT " 1 ";
        CASE 2:
            COLOR 10: PRINT " 2 ";
        CASE 3:
            COLOR 12: PRINT " 3 ";
        CASE 4:
            COLOR 1: PRINT " 4 ";
        CASE 5:
            COLOR 4: PRINT " 5 ";
        CASE 6:
            COLOR 3: PRINT " 6 ";
        CASE 7:
            COLOR 13: PRINT " 7 ";
        CASE 8:
            COLOR 15: PRINT " 8 ";
    END SELECT
    COLOR 15
END SUB
