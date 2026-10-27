'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: jemaf@free.fr                 ********
'********* telecharge sur le site jemaf.free.fr  ********
'********************************************************

'DUTCH BLITZ POUR QBASIC
'Jeu de rapidite d'origine Amish des Etats-Unis (proche du Ligretto).

DECLARE SUB Scores ()
DECLARE SUB Joue (joueur!)
DECLARE SUB Fond ()
DECLARE SUB Aide ()
DECLARE SUB Demande (j!)
DECLARE SUB Affiche ()
DECLARE SUB Done ()
DECLARE SUB Init ()
DECLARE SUB RedessineTout ()

DIM SHARED Couleur(0 TO 4)         ' Couleur des cartes
DIM SHARED Carte$(0 TO 40)         ' Nom affiche des cartes
DIM SHARED jeu(16, 10, 2)          ' Contenu des positions du jeu
DIM SHARED DerJeu(16, 2)           ' Carte visible des positions du jeu
DIM SHARED Tas(5, 41, 4)           ' Contenu des 5 tas des joueurs
DIM SHARED DerTas(5, 2, 4)         ' Carte visible des tas des joueurs
DIM SHARED Score(4, 5, 3)          ' Score des joueurs
DIM SHARED Partie                  ' Numero de la partie dans la manche
DIM SHARED QuitterJeu              ' Drapeau d'arret

Couleur(0) = 0
Couleur(1) = 12                    ' Rouge = 1
Couleur(2) = 2                     ' Vert  = 2
Couleur(3) = 9                     ' Bleu  = 3
Couleur(4) = 14                    ' Jaune = 4

RANDOMIZE TIMER
SCREEN 7: COLOR 15, 0: CLS

DO
    QuitterJeu = 0

    ' Reinitialiser les scores pour la manche de 5 parties
    FOR j = 1 TO 4
        FOR p = 1 TO 5
            FOR s = 1 TO 3
                Score(j, p, s) = 0
            NEXT s
        NEXT p
    NEXT j

    FOR Partie = 1 TO 5
        CLS
        Fond
        Init
        Done
        Affiche

        LOCATE 24, 2: COLOR 11: PRINT "Appuyez sur une touche pour lancer...";
        DO
            k$ = UCASE$(INKEY$)
            IF k$ = "Q" OR k$ = CHR$(27) THEN QuitterJeu = 1: EXIT DO
        LOOP UNTIL k$ <> ""
        LOCATE 24, 2: PRINT STRING$(38, " ");

        IF QuitterJeu = 1 THEN EXIT FOR

        Fin = 0
        joueur = 1
        tDernierTour# = TIMER

        DO
            ' Gestion des entrees joueur et de la cadence
            k$ = UCASE$(INKEY$)
            IF k$ <> "" THEN
                IF k$ = "Q" OR k$ = CHR$(27) THEN
                    QuitterJeu = 1
                    EXIT DO
                ELSEIF k$ = "H" OR RIGHT$(k$, 1) = ";" THEN
                    Aide
                ELSEIF k$ = "S" OR RIGHT$(k$, 1) = "<" THEN
                    Scores
                ELSEIF k$ >= "1" AND k$ <= "5" THEN
                    Demande VAL(k$)
                END IF
            END IF

            ' Victoire du joueur humain (joueur 4)
            IF DerTas(4, 2, 4) = 0 THEN
                COLOR Couleur(4): LOCATE 23, 2
                PRINT "* * * BLITZ * *   VOUS   * BLITZ * * *";
                Fin = 1
                PLAY "O4L16 C E G O5 C2"
                LOCATE 24, 2: COLOR 11: PRINT "Appuyez sur Entree pour continuer...";
                DO: k$ = INKEY$: LOOP UNTIL k$ = CHR$(13) OR k$ = " "
                Scores
                EXIT DO
            END IF

            ' Cadence de l'IA (environ tous les 0.18s)
            tActuel# = TIMER
            tDiff# = tActuel# - tDernierTour#
            IF tDiff# < 0 THEN tDiff# = tDiff# + 86400

            IF tDiff# >= 0.18 THEN
                tDernierTour# = tActuel#
                Joue joueur

                IF DerTas(4, 2, joueur) = 0 THEN
                    COLOR Couleur(joueur): LOCATE 23, 2
                    PRINT "* * * BLITZ * * JOUEUR"; joueur; "* BLITZ * * *";
                    Fin = 1
                    PLAY "O3L16 G E C2"
                    LOCATE 24, 2: COLOR 11: PRINT "Appuyez sur Entree pour continuer...";
                    DO: k$ = INKEY$: LOOP UNTIL k$ = CHR$(13) OR k$ = " "
                    Scores
                    EXIT DO
                END IF

                joueur = joueur + 1
                IF joueur >= 4 THEN joueur = 1
            END IF

            SLEEP 0.005
        LOOP UNTIL Fin = 1 OR QuitterJeu = 1

        IF QuitterJeu = 1 THEN EXIT FOR
    NEXT Partie

    IF QuitterJeu = 1 THEN EXIT DO

    ' Fin des 5 parties : afficher les scores finaux
    CLS
    COLOR 14: LOCATE 2, 10: PRINT "=== FIN DU TOURNOI ==="
    Scores

    LOCATE 24, 2: COLOR 11: PRINT "Voulez-vous rejouer un tournoi ? (O/N) : ";
    rep$ = ""
    DO
        k$ = UCASE$(INKEY$)
        IF k$ = "O" OR k$ = "N" OR k$ = "Q" OR k$ = CHR$(27) THEN rep$ = k$
    LOOP UNTIL rep$ <> ""

LOOP WHILE rep$ = "O"

COLOR 15: CLS
PRINT "Merci d'avoir joue a Dutch Blitz !"
SYSTEM

SUB Affiche
    FOR jAct = 1 TO 4
        FOR j = 1 TO 5
            cardNum = DerTas(j, 1, jAct)
            IF cardNum > 0 THEN
                COLOR Couleur(INT((cardNum - 1) / 10) + 1)
            ELSE
                COLOR 0
            END IF
            LOCATE -1 + 5 * jAct, -1 + j * 4
            PRINT Carte$(cardNum);

            LOCATE 5 * jAct, -1 + j * 4
            COLOR Couleur(jAct)
            IF DerTas(j, 2, jAct) > 1 AND j < 4 THEN
                PRINT DerTas(j, 2, jAct);
            ELSE
                PRINT "   ";
            END IF
        NEXT j

        COLOR 8: LOCATE 5 * jAct, 15
        DT = DerTas(4, 2, jAct)
        SELECT CASE DT
            CASE 0: PRINT " B ";
            CASE 10: PRINT STR$(DT);
            CASE ELSE: PRINT STR$(DT); " ";
        END SELECT
    NEXT jAct

    FOR j = 1 TO 16
        cardNum = DerJeu(j, 1)
        IF cardNum > 0 THEN
            COLOR Couleur(INT((cardNum - 1) / 10) + 1)
        ELSE
            COLOR 0
        END IF
        LOCATE 7 + 4 * INT((j - 1) / 4), 24 + 4 * ((j - 1) MOD 4)
        PRINT Carte$(cardNum);
    NEXT j
END SUB

SUB Aide
    CLS
    COLOR 13: LOCATE 2, 9: PRINT "***  COMMENT JOUER  ***"

    COLOR 10: LOCATE 4, 2: PRINT "But du Blitz :"
    COLOR 15: LOCATE 5, 2: PRINT "Vider en premier votre 4e tas de cartes"
    LOCATE 6, 2: PRINT "en placant un maximum de cartes au centre."

    COLOR 10: LOCATE 8, 2: PRINT "Regles du jeu :"
    COLOR 15: LOCATE 9, 2: PRINT "- Poser les 1 sur une case vide du centre"
    LOCATE 10, 2: PRINT "- Empiler les cartes de meme couleur dans"
    LOCATE 11, 2: PRINT "  l'ordre croissant (1 a 10)."
    LOCATE 13, 2: PRINT "- Touches 1 a 5 : jouer le tas correspondant"
    LOCATE 14, 2: PRINT "- Touche 5 : faire tourner le paquet pioche"
    LOCATE 15, 2: PRINT "- H : Aide | S : Scores | Q : Quitter"
    LOCATE 17, 2: PRINT "- A la fin du jeu, chaque carte restante"
    LOCATE 18, 2: PRINT "  dans le 4e tas penalise de -2 points."

    COLOR 11: LOCATE 22, 2: PRINT "Appuyez sur une touche pour revenir...";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    RedessineTout
END SUB

SUB Demande (j)
    SELECT CASE j
        CASE 1 TO 5
            Fait = 0
            i = 1
            DO
                IF DerTas(j, 1, 4) MOD 10 = 1 AND DerJeu(i, 1) = 0 THEN
                    Fait = j
                END IF

                IF DerJeu(i, 1) = DerTas(j, 1, 4) - 1 AND DerJeu(i, 2) < 10 THEN
                    Fait = j
                END IF

                IF Fait = j THEN
                    DerJeu(i, 2) = DerJeu(i, 2) + 1
                    jeu(i, DerJeu(i, 2), 1) = Tas(j, DerTas(j, 2, 4), 4)
                    jeu(i, DerJeu(i, 2), 2) = 4
                    DerJeu(i, 1) = jeu(i, DerJeu(i, 2), 1)
                    Tas(j, DerTas(j, 2, 4), 4) = 0

                    IF j = 5 THEN
                        k = DerTas(j, 2, 4)
                        DO
                            k = (k MOD 40) + 1
                        LOOP UNTIL Tas(j, k, 4) > 0
                        DerTas(j, 1, 4) = Tas(j, k, 4)
                        DerTas(j, 2, 4) = k
                    ELSE
                        DerTas(j, 1, 4) = Tas(j, DerTas(j, 2, 4) - 1, 4)
                        DerTas(j, 2, 4) = DerTas(j, 2, 4) - 1
                    END IF
                END IF

                i = i + 1
            LOOP UNTIL i > 16 OR Fait > 0 OR DerJeu(i - 1, 1) = 0

            ' Garcon / Fille (alternance sur les tas de transition)
            IF Fait = 0 THEN
                i = 1
                DO
                    IF DerTas(j, 1, 4) MOD 20 = (DerTas(i, 1, 4) + 9) MOD 20 AND (DerTas(j, 2, 4) = 1 AND j < 4 OR j = 4) THEN
                        DerTas(i, 2, 4) = DerTas(i, 2, 4) + 1
                        Tas(i, DerTas(i, 2, 4), 4) = Tas(j, DerTas(j, 2, 4), 4)
                        DerTas(i, 1, 4) = Tas(i, DerTas(i, 2, 4), 4)
                        Tas(j, DerTas(j, 2, 4), 4) = 0
                        DerTas(j, 1, 4) = Tas(j, DerTas(j, 2, 4) - 1, 4)
                        DerTas(j, 2, 4) = DerTas(j, 2, 4) - 1
                        Fait = j
                    END IF
                    i = i + 1
                LOOP UNTIL i > 3 OR Fait > 0
            END IF

            ' Remplacement des tas vides par le tas 4
            IF Fait > 0 AND Fait < 4 THEN
                IF DerTas(Fait, 1, 4) = 0 AND DerTas(Fait, 2, 4) = 0 THEN
                    Tas(Fait, 1, 4) = Tas(4, DerTas(4, 2, 4), 4)
                    Tas(4, DerTas(4, 2, 4), 4) = 0
                    DerTas(Fait, 2, 4) = 1
                    DerTas(Fait, 1, 4) = Tas(Fait, 1, 4)
                    DerTas(4, 2, 4) = DerTas(4, 2, 4) - 1
                    DerTas(4, 1, 4) = Tas(4, DerTas(4, 2, 4), 4)
                END IF
            END IF

            ' Rotation de la pioche (tas 5)
            IF Fait = 0 AND j = 5 THEN
                k = DerTas(5, 2, 4)
                FOR i = 1 TO 3
                    DO
                        k = (k MOD 40) + 1
                    LOOP UNTIL Tas(5, k, 4) > 0
                NEXT i
                DerTas(5, 2, 4) = k
                DerTas(5, 1, 4) = Tas(5, k, 4)
                Fait = 5
            END IF

            IF Fait > 0 THEN Affiche
    END SELECT
END SUB

SUB Done
    RANDOMIZE TIMER

    FOR jAct = 1 TO 4
        DO
            FOR j = 1 TO 40
                FOR i = 1 TO 5
                    Tas(i, j, jAct) = 0
                NEXT i
            NEXT j

            FOR sign = 1 TO 4
                FOR num = 1 TO 10
                    DO
                        x = INT(RND * 40) + 1
                    LOOP UNTIL Tas(5, x, jAct) = 0
                    Tas(5, x, jAct) = num + (sign - 1) * 10
                NEXT num
            NEXT sign

            Tas(1, 1, jAct) = Tas(5, 40, jAct): Tas(5, 40, jAct) = 0
            Tas(2, 1, jAct) = Tas(5, 39, jAct): Tas(5, 39, jAct) = 0
            Tas(3, 1, jAct) = Tas(5, 38, jAct): Tas(5, 38, jAct) = 0

            FOR i = 1 TO 10
                Tas(4, i, jAct) = Tas(5, 38 - i, jAct)
                Tas(5, 38 - i, jAct) = 0
            NEXT i

            DerTas(1, 1, jAct) = Tas(1, 1, jAct): DerTas(1, 2, jAct) = 1
            DerTas(2, 1, jAct) = Tas(2, 1, jAct): DerTas(2, 2, jAct) = 1
            DerTas(3, 1, jAct) = Tas(3, 1, jAct): DerTas(3, 2, jAct) = 1
            DerTas(4, 1, jAct) = Tas(4, 10, jAct): DerTas(4, 2, jAct) = 10
            DerTas(5, 1, jAct) = Tas(5, 27, jAct): DerTas(5, 2, jAct) = 27

            Total = 0
            FOR i = 1 TO 4
                Total = Total + (DerTas(i, 1, jAct) - 1) MOD 10 + 1
            NEXT i
        LOOP UNTIL Total > 10 AND Total < 30
    NEXT jAct
END SUB

SUB Fond
    COLOR 13: LOCATE 2, 26: PRINT "DUTCH BLITZ"
    LOCATE 3, 26: PRINT "For QBasic"

    COLOR 8: LOCATE 1, 2: PRINT "Partie"; Partie;

    h3$ = CHR$(205) + CHR$(205) + CHR$(205)
    tTop$ = CHR$(201) + h3$ + CHR$(209) + h3$ + CHR$(209) + h3$ + CHR$(203) + h3$ + CHR$(203) + h3$ + CHR$(187)
    tBot$ = CHR$(200) + h3$ + CHR$(207) + h3$ + CHR$(207) + h3$ + CHR$(202) + h3$ + CHR$(202) + h3$ + CHR$(188)
    tMid$ = CHR$(186) + "   " + CHR$(179) + "   " + CHR$(179) + "   " + CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186)

    FOR i = 0 TO 3
        COLOR Couleur(i + 1)
        LOCATE 2 + 5 * i, 2: PRINT tTop$
        LOCATE 3 + 5 * i, 2: PRINT tMid$
        LOCATE 4 + 5 * i, 2: PRINT tMid$
        LOCATE 5 + 5 * i, 2: PRINT tMid$
        LOCATE 6 + 5 * i, 2: PRINT tBot$
    NEXT i

    cTop$ = CHR$(201) + h3$ + CHR$(209) + h3$ + CHR$(209) + h3$ + CHR$(209) + h3$ + CHR$(187)
    cBot$ = CHR$(200) + h3$ + CHR$(207) + h3$ + CHR$(207) + h3$ + CHR$(207) + h3$ + CHR$(188)
    cSep$ = CHR$(199) + CHR$(196) + CHR$(196) + CHR$(196) + CHR$(197) + CHR$(196) + CHR$(196) + CHR$(196) + CHR$(197) + CHR$(196) + CHR$(196) + CHR$(196) + CHR$(197) + CHR$(196) + CHR$(196) + CHR$(196) + CHR$(182)
    cMid$ = CHR$(186) + "   " + CHR$(179) + "   " + CHR$(179) + "   " + CHR$(179) + "   " + CHR$(186)

    COLOR 8
    LOCATE 5, 23: PRINT cTop$
    FOR i = 0 TO 3
        LOCATE 6 + 4 * i, 23: PRINT cMid$
        LOCATE 7 + 4 * i, 23: PRINT cMid$
        LOCATE 8 + 4 * i, 23: PRINT cMid$
        IF i < 3 THEN LOCATE 9 + 4 * i, 23: PRINT cSep$
    NEXT i
    LOCATE 21, 23: PRINT cBot$

    COLOR 13: LOCATE 22, 4: PRINT "1   2   3   4   5";
    LOCATE 23, 1: PRINT STRING$(40, " ");
END SUB

SUB Init
    FOR num = 1 TO 10
        FOR sign = 1 TO 4
            SELECT CASE num
                CASE 1 TO 9: a$ = STR$(num)
                CASE 10: a$ = LTRIM$(STR$(num))
            END SELECT

            SELECT CASE sign
                CASE 1, 3: b$ = " "
                CASE 2, 4: b$ = CHR$(3)
            END SELECT

            Carte$(num + (sign - 1) * 10) = a$ + b$
        NEXT sign
    NEXT num

    Carte$(0) = "   "

    LOCATE 24, 2: COLOR 7: PRINT "1-5:Joue  H:Aide  S:Score  Q:Quitte";

    FOR i = 1 TO 16
        FOR j = 1 TO 10
            jeu(i, j, 1) = 0
            jeu(i, j, 2) = 0
        NEXT j
        DerJeu(i, 1) = 0
        DerJeu(i, 2) = 0
    NEXT i
END SUB

SUB Joue (joueur)
    Fait = 0
    j = 1
    DO
        i = 1
        DO
            IF DerTas(j, 1, joueur) MOD 10 = 1 AND DerJeu(i, 1) = 0 THEN
                Fait = j
            END IF

            IF DerJeu(i, 1) = DerTas(j, 1, joueur) - 1 AND DerJeu(i, 2) < 10 THEN
                Fait = j
            END IF

            IF Fait = j THEN
                DerJeu(i, 2) = DerJeu(i, 2) + 1
                jeu(i, DerJeu(i, 2), 1) = Tas(j, DerTas(j, 2, joueur), joueur)
                jeu(i, DerJeu(i, 2), 2) = joueur
                DerJeu(i, 1) = jeu(i, DerJeu(i, 2), 1)
                Tas(j, DerTas(j, 2, joueur), joueur) = 0

                IF j = 5 THEN
                    k = DerTas(j, 2, joueur)
                    DO
                        k = (k MOD 40) + 1
                    LOOP UNTIL Tas(j, k, joueur) > 0
                    DerTas(j, 1, joueur) = Tas(j, k, joueur)
                    DerTas(j, 2, joueur) = k
                ELSE
                    DerTas(j, 1, joueur) = Tas(j, DerTas(j, 2, joueur) - 1, joueur)
                    DerTas(j, 2, joueur) = DerTas(j, 2, joueur) - 1
                END IF
            END IF

            i = i + 1
        LOOP UNTIL i > 16 OR Fait > 0 OR DerJeu(i - 1, 1) = 0
        j = j + 1
    LOOP UNTIL j >= 6 OR Fait > 0

    ' Garcon / Fille
    IF Fait = 0 THEN
        j = 1
        DO
            i = 1
            DO
                IF DerTas(j, 1, joueur) MOD 20 = (DerTas(i, 1, joueur) + 9) MOD 20 AND (DerTas(j, 2, joueur) = 1 AND j < 4 OR j = 4) THEN
                    DerTas(i, 2, joueur) = DerTas(i, 2, joueur) + 1
                    Tas(i, DerTas(i, 2, joueur), joueur) = Tas(j, DerTas(j, 2, joueur), joueur)
                    DerTas(i, 1, joueur) = Tas(i, DerTas(i, 2, joueur), joueur)
                    Tas(j, DerTas(j, 2, joueur), joueur) = 0
                    DerTas(j, 1, joueur) = Tas(j, DerTas(j, 2, joueur) - 1, joueur)
                    DerTas(j, 2, joueur) = DerTas(j, 2, joueur) - 1
                    Fait = j
                END IF
                i = i + 1
            LOOP UNTIL i > 3 OR Fait > 0
            j = j + 1
        LOOP UNTIL j > 4 OR Fait > 0
    END IF

    ' Remplacement des tas vides par le tas 4
    IF Fait > 0 AND Fait < 4 THEN
        IF DerTas(Fait, 1, joueur) = 0 AND DerTas(Fait, 2, joueur) = 0 THEN
            Tas(Fait, 1, joueur) = Tas(4, DerTas(4, 2, joueur), joueur)
            Tas(4, DerTas(4, 2, joueur), joueur) = 0
            DerTas(Fait, 2, joueur) = 1
            DerTas(Fait, 1, joueur) = Tas(Fait, 1, joueur)
            DerTas(4, 2, joueur) = DerTas(4, 2, joueur) - 1
            DerTas(4, 1, joueur) = Tas(4, DerTas(4, 2, joueur), joueur)
        END IF
    END IF

    ' Rotation de la pioche
    IF Fait = 0 THEN
        j = DerTas(5, 2, joueur)
        FOR i = 1 TO 3
            DO
                j = (j MOD 40) + 1
            LOOP UNTIL Tas(5, j, joueur) > 0
        NEXT i
        DerTas(5, 2, joueur) = j
        DerTas(5, 1, joueur) = Tas(5, j, joueur)
        Fait = 5
    END IF

    IF Fait > 0 THEN Affiche
END SUB

SUB RedessineTout
    CLS
    Fond
    LOCATE 24, 2: COLOR 7: PRINT "1-5:Joue  H:Aide  S:Score  Q:Quitte";
    Affiche
END SUB

SUB Scores
    CLS
    DIM Total(4)

    COLOR 13: LOCATE 2, 11: PRINT "SCORES DE LA MANCHE"

    h8$ = STRING$(8, CHR$(205))
    sTop$ = CHR$(201) + h8$ + CHR$(203) + h8$ + CHR$(203) + h8$ + CHR$(203) + h8$ + CHR$(187)
    sBot$ = CHR$(200) + h8$ + CHR$(202) + h8$ + CHR$(202) + h8$ + CHR$(202) + h8$ + CHR$(188)
    sMid$ = CHR$(186) + "   " + CHR$(179) + "    " + CHR$(186) + "   " + CHR$(179) + "    " + CHR$(186) + "   " + CHR$(179) + "    " + CHR$(186) + "   " + CHR$(179) + "    " + CHR$(186)

    COLOR 8
    LOCATE 4, 2: PRINT sTop$
    LOCATE 5, 2: PRINT CHR$(186) + "  J1    " + CHR$(186) + "  J2    " + CHR$(186) + "  J3    " + CHR$(186) + "  VOUS  " + CHR$(186)
    LOCATE 6, 2: PRINT CHR$(204) + STRING$(8, CHR$(205)) + CHR$(206) + STRING$(8, CHR$(205)) + CHR$(206) + STRING$(8, CHR$(205)) + CHR$(206) + STRING$(8, CHR$(205)) + CHR$(185)

    FOR i = 7 TO 17
        LOCATE i, 2: PRINT sMid$
    NEXT i

    LOCATE 18, 2: PRINT CHR$(204) + STRING$(8, CHR$(205)) + CHR$(206) + STRING$(8, CHR$(205)) + CHR$(206) + STRING$(8, CHR$(205)) + CHR$(206) + STRING$(8, CHR$(205)) + CHR$(185)
    LOCATE 19, 2: PRINT CHR$(186) + " TOTAL  " + CHR$(186) + " TOTAL  " + CHR$(186) + " TOTAL  " + CHR$(186) + " TOTAL  " + CHR$(186)
    LOCATE 20, 2: PRINT CHR$(186) + "        " + CHR$(186) + "        " + CHR$(186) + "        " + CHR$(186) + "        " + CHR$(186)
    LOCATE 21, 2: PRINT sBot$

    LOCATE 23, 2: COLOR 11: PRINT "Appuyez sur une touche...";

    ' Calcul des points pour la partie courante
    IF Partie >= 1 AND Partie <= 5 THEN
        FOR jAct = 1 TO 4
            Score(jAct, Partie, 2) = 0
        NEXT jAct

        FOR j = 1 TO 16
            FOR i = 1 TO 10
                jOwner = jeu(j, i, 2)
                IF jOwner >= 1 AND jOwner <= 4 THEN
                    Score(jOwner, Partie, 2) = Score(jOwner, Partie, 2) + 1
                END IF
            NEXT i
        NEXT j

        FOR jAct = 1 TO 4
            Score(jAct, Partie, 1) = DerTas(4, 2, jAct) * -2
            Score(jAct, Partie, 3) = Score(jAct, Partie, 1) + Score(jAct, Partie, 2)
        NEXT jAct
    END IF

    ' Affichage des scores
    FOR k = 1 TO Partie
        IF k <= 5 THEN
            FOR jAct = 1 TO 4
                COLOR 13: LOCATE 6 + k * 2, -1 + 9 * jAct: PRINT STR$(Score(jAct, k, 1));
                COLOR 15: LOCATE 6 + k * 2, -5 + 9 * jAct: PRINT STR$(Score(jAct, k, 3));
            NEXT jAct
        END IF
    NEXT k

    FOR jAct = 1 TO 4
        Total(jAct) = 0
        FOR i = 1 TO Partie
            Total(jAct) = Total(jAct) + Score(jAct, i, 3)
        NEXT i
        COLOR Couleur(jAct): LOCATE 20, -4 + 9 * jAct: PRINT STR$(Total(jAct));
    NEXT jAct

    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    RedessineTout
END SUB
