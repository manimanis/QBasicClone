'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: jemaf@free.fr                 ********
'********* telecharge sur le site jemaf.free.fr  ********
'********************************************************

'JEU DU CAVALIER (JEU CARRE)
'Deplacez-vous comme un cavalier d'echecs et tentez
'de passer par toutes les 64 cases de l'echiquier.

DECLARE SUB premier ()
DECLARE FUNCTION demande! (max!)
DECLARE SUB dposs (p!(), nb!)
DECLARE SUB eposs (p!(), nb!)
DECLARE SUB numerote (x!, y!)
DECLARE SUB poss (x!, y!)
DECLARE SUB quadrillage ()

SCREEN 9: CLS
RANDOMIZE TIMER

DIM SHARED etat(8, 8), num

DO
    ' Reinitialiser le jeu
    FOR r = 1 TO 8
        FOR c = 1 TO 8
            etat(c, r) = 0
        NEXT c
    NEXT r
    num = 0

    CLS
    LOCATE 1, 1: COLOR 14: PRINT "=== LE JEU DU CAVALIER ===";
    LOCATE 2, 1: COLOR 7: PRINT "Remplissez les 64 cases en vous deplacant comme un cavalier.";
    CALL quadrillage
    CALL premier

    cx = demande(64)
    IF cx = 0 THEN EXIT DO

    CLS
    LOCATE 1, 1: COLOR 14: PRINT "=== LE JEU DU CAVALIER ===";
    CALL quadrillage
    y = INT((cx - 1) / 8) + 1
    x = ((cx - 1) MOD 8) + 1
    CALL numerote(x, y)

    DO
        CALL poss(x, y)
        IF x > 0 AND y > 0 THEN
            CALL numerote(x, y)
            IF num >= 60 THEN PLAY "O3L16" + MID$("CDEFG", num - 59, 1)
        END IF
    LOOP UNTIL num = 64 OR x = 0

    LOCATE 1, 1: PRINT STRING$(80, " ")
    LOCATE 23, 10
    IF num = 64 THEN
        COLOR 10: PRINT "FELICITATIONS ! Vous avez complete tout le carre (64/64) !";
        PLAY "O4L16 C E G O5 C2"
    ELSE
        COLOR 12: PRINT "Partie terminee ! Cases visitees : "; num; " sur 64.";
    END IF

    LOCATE 24, 10: COLOR 11: PRINT "Voulez-vous rejouer ? (O/N) : ";
    rep$ = ""
    DO
        k$ = UCASE$(INKEY$)
        IF k$ = "O" OR k$ = "N" OR k$ = CHR$(27) THEN rep$ = k$
    LOOP UNTIL rep$ <> ""

LOOP WHILE rep$ = "O"

COLOR 15: CLS
PRINT "Merci d'avoir joue au Jeu du Cavalier !"
SYSTEM

FUNCTION demande (max)
    DO
        LOCATE 1, 1: PRINT STRING$(80, " ")
        IF max > 9 THEN
            COLOR 9: LOCATE 1, 1: INPUT "Quelle case de depart (1-64, Q=Quitter) : "; a$
            IF UCASE$(a$) = "Q" OR a$ = "0" THEN
                demande = 0: COLOR 15: EXIT FUNCTION
            END IF
            a = VAL(a$)
        ELSE
            COLOR 9: LOCATE 1, 1
            PRINT "Quel mouvement choisissez-vous ? (1-"; LTRIM$(STR$(max)); ", Q=Quitter) : ";
            DO
                k$ = UCASE$(INKEY$)
            LOOP UNTIL k$ <> ""
            IF k$ = "Q" OR k$ = "0" OR k$ = CHR$(27) THEN
                demande = 0: COLOR 15: EXIT FUNCTION
            END IF
            a = VAL(k$)
        END IF
    LOOP UNTIL a >= 1 AND a <= max

    demande = a
    COLOR 15
END FUNCTION

SUB dposs (p(), nb)
    FOR i = 1 TO nb
        COLOR 9: LOCATE 4 + 2 * p(i, 2), 12 + 5 * p(i, 1): PRINT i;
    NEXT i
    COLOR 15
END SUB

SUB eposs (p(), nb)
    FOR i = 1 TO nb
        COLOR 15: LOCATE 4 + 2 * p(i, 2), 12 + 5 * p(i, 1): PRINT "  ";
    NEXT i
    COLOR 15
END SUB

SUB numerote (j, i)
    x = 12 + 5 * j
    y = 4 + 2 * i
    IF i + j > 0 THEN
        num = num + 1
        COLOR 15: LOCATE y, x: PRINT num;
    END IF
    etat(j, i) = num
END SUB

SUB poss (x, y)
    DIM p(8, 2)
    nb = 0

    IF x < 7 THEN
        IF y > 1 THEN
            IF etat(x + 2, y - 1) = 0 THEN
                nb = nb + 1: p(nb, 1) = x + 2: p(nb, 2) = y - 1
            END IF
        END IF
        IF y < 8 THEN
            IF etat(x + 2, y + 1) = 0 THEN
                nb = nb + 1: p(nb, 1) = x + 2: p(nb, 2) = y + 1
            END IF
        END IF
    END IF

    IF y < 7 THEN
        IF x < 8 THEN
            IF etat(x + 1, y + 2) = 0 THEN
                nb = nb + 1: p(nb, 1) = x + 1: p(nb, 2) = y + 2
            END IF
        END IF
        IF x > 1 THEN
            IF etat(x - 1, y + 2) = 0 THEN
                nb = nb + 1: p(nb, 1) = x - 1: p(nb, 2) = y + 2
            END IF
        END IF
    END IF

    IF x > 2 THEN
        IF y < 8 THEN
            IF etat(x - 2, y + 1) = 0 THEN
                nb = nb + 1: p(nb, 1) = x - 2: p(nb, 2) = y + 1
            END IF
        END IF
        IF y > 1 THEN
            IF etat(x - 2, y - 1) = 0 THEN
                nb = nb + 1: p(nb, 1) = x - 2: p(nb, 2) = y - 1
            END IF
        END IF
    END IF

    IF y > 2 THEN
        IF x > 1 THEN
            IF etat(x - 1, y - 2) = 0 THEN
                nb = nb + 1: p(nb, 1) = x - 1: p(nb, 2) = y - 2
            END IF
        END IF
        IF x < 8 THEN
            IF etat(x + 1, y - 2) = 0 THEN
                nb = nb + 1: p(nb, 1) = x + 1: p(nb, 2) = y - 2
            END IF
        END IF
    END IF

    IF nb > 1 THEN
        CALL dposs(p(), nb)
        a = demande(nb)
        CALL eposs(p(), nb)
        IF a = 0 THEN
            x = 0: y = 0
        ELSE
            x = p(a, 1): y = p(a, 2)
        END IF
    ELSEIF nb = 1 THEN
        x = p(1, 1): y = p(1, 2)
    ELSE
        x = 0: y = 0
    END IF
END SUB

SUB premier
    FOR i = 1 TO 8
        FOR j = 1 TO 8
            x = 12 + 5 * j
            y = 4 + 2 * i
            COLOR 9: LOCATE y, x: PRINT (i - 1) * 8 + j;
        NEXT j
    NEXT i
    COLOR 15
END SUB

SUB quadrillage
    FOR i = 1 TO 9
        a = 37 + i * 28
        LINE (122, a)-(441, a), 15
        LINE (121 + (i - 1) * 40, 66)-(121 + (i - 1) * 40, 289), 15
    NEXT i
END SUB
