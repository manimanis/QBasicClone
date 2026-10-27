'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: christian@hoffmannteam.com    ********
'********* telecharge sur le site jemaf.free.fr  ********
'********* Rectifie et optimise pour QBasic / Win64 *****
'********************************************************

DECLARE SUB Fond ()
DECLARE SUB aide ()
DECLARE SUB Calcul ()
DECLARE SUB Demande ()
DECLARE SUB Affiche ()
DECLARE SUB Done (mem%)
DECLARE SUB Init ()
DECLARE SUB EnrCoup (Col1!, L1!, Col2!, L2!, AffCache!)
DECLARE SUB AnnuleCoup ()
DECLARE SUB VerifSuite (col%)
DECLARE FUNCTION Coul! (sign!)

' Dimensionnement global des variables (place avant Debut pour eviter l'erreur 'Duplicate definition')
DIM SHARED carte$(13, 4)       ' Nom affiche des cartes
DIM SHARED Jeu(50, 15, 2)      ' Contenu des positions du jeu (1..10=colonnes, 11..15=pioche)
DIM SHARED JeuMem(10, 15, 2)   ' Memoire de la distribution initiale pour recommencer
DIM SHARED tas(8, 13, 2)       ' Contenu des 8 suites completes (fondations)
DIM SHARED Cache(10)           ' Nombre de cartes masquees par colonne
DIM SHARED Dem1, Dem2          ' Colonne de depart, colonne de destination
DIM SHARED MemAnnul(5, 5)      ' Memorisation des coups joues pour annulation (5 niveaux)
DIM SHARED Again               ' Indicateur pour recommencer avec la meme distribution
DIM SHARED SortieJeu           ' Flag de fin de jeu demande par l'utilisateur

Debut:

SCREEN 9, 1, 0: WIDTH 80, 43: COLOR 15: CLS

KEY(1) ON: ON KEY(1) GOSUB KeyHelp
KEY(2) ON: ON KEY(2) GOSUB KeyRecommencer

Fond                           ' Affichage du decor et du tapis
Init                           ' Initialisation du nom des cartes et des structures
Done (Again)                   ' Distribution des cartes
Again = 0
Affiche                        ' Affichage des cartes

DO
        Demande                ' Saisie et verification de la commande joueur
        IF SortieJeu THEN EXIT DO
        Calcul                 ' Calcul et execution du deplacement
        Affiche                ' Rafraichissement de l'affichage

LOOP UNTIL tas(8, 13, 1) = 13 OR SortieJeu

IF tas(8, 13, 1) = 13 THEN
        COLOR 14: LOCATE 37, 1: PRINT " * * * GAGNE ! TOUTES LES SUITES SONT COMPLETEES ! * * * ";
        SLEEP 5
END IF

COLOR 7: LOCATE 37, 1: PRINT STRING$(80, " ");
LOCATE 37, 1: PRINT "Partie terminee. A bientot !";
COLOR 8
END

KeyHelp:
        aide
        RETURN

KeyRecommencer:
        LOCATE 37, 1: PRINT STRING$(80, " ");
        LOCATE 37, 3: COLOR 14: INPUT "Recommencer la partie ? (O/N) ", Rep$
        IF UCASE$(LEFT$(LTRIM$(Rep$), 1)) = "O" THEN
                LOCATE 37, 1: PRINT STRING$(80, " ");
                LOCATE 37, 3: INPUT "Meme distribution de cartes ? (O/N) ", Rep2$
                IF UCASE$(LEFT$(LTRIM$(Rep2$), 1)) = "O" THEN Again = 1 ELSE Again = 0
                GOTO Debut
        END IF
        COLOR 9: LOCATE 37, 1: PRINT STRING$(80, " ");
        RETURN

SUB Affiche

FOR j = 1 TO 10
        i = 51
        DO
                i = i - 1
                IF Jeu(i, j, 1) > 0 THEN
                        a$ = ""
                        IF i > 27 THEN
                                i1 = 27
                                a$ = "+" + LTRIM$(carte$(Jeu(i, j, 1), Jeu(i, j, 2)))
                        ELSE
                                i1 = i
                                a$ = carte$(Jeu(i, j, 1), Jeu(i, j, 2))
                        END IF

                        IF i <= Cache(j) THEN
                                ' Carte masquee (face cachee) : dos vert, sans reveler la valeur
                                LOCATE 5 + i, j * 7 - 2: COLOR 2
                                PRINT CHR$(201) + STRING$(5, 205) + CHR$(187)
                        ELSE
                                ' Carte visible : bordure grise, valeur et enseigne colorees
                                LOCATE 5 + i1, j * 7 - 2: COLOR 8
                                PRINT CHR$(218) + STRING$(5, 196) + CHR$(191)
                                LOCATE 5 + i1, j * 7: COLOR Coul(Jeu(i, j, 2))
                                PRINT a$
                        END IF

                        IF Jeu(i + 1, j, 1) = 0 THEN
                                ' Carte du bas : corps et bordure inferieure
                                FOR k = 1 TO 3
                                        LOCATE 5 + i1 + k, j * 7 - 2: COLOR 8
                                        PRINT CHR$(179) + SPACE$(5) + CHR$(179)
                                NEXT k
                                LOCATE 5 + i1 + 4, j * 7 - 2: COLOR 8
                                PRINT CHR$(192) + CHR$(196) + "   " + CHR$(196) + CHR$(217)
                                LOCATE 5 + i1 + 4, j * 7: COLOR Coul(Jeu(i, j, 2))
                                PRINT a$
                        END IF

                        IF i > 27 THEN
                                OK = 0
                                DO
                                        i = i - 1
                                        IF Jeu(i + 1, j, 1) = Jeu(i, j, 1) - 1 AND ABS((Jeu(i + 1, j, 2) - Jeu(i, j, 2)) MOD 2) = 0 THEN OK = 1 ELSE OK = 0
                                LOOP UNTIL OK = 0 OR i = 26
                                i = i + 1

                                IF OK = 0 THEN
                                        a$ = "-" + LTRIM$(carte$(Jeu(i, j, 1), Jeu(i, j, 2)))
                                ELSE
                                        a$ = carte$(Jeu(i, j, 1), Jeu(i, j, 2))
                                END IF

                                LOCATE 5 + i1, j * 7 - 2: COLOR 8
                                PRINT CHR$(218) + STRING$(5, 196) + CHR$(191)
                                LOCATE 5 + i1, j * 7: COLOR Coul(Jeu(i, j, 2))
                                PRINT a$

                                i = 27
                        END IF
                ELSE
                        IF i > 31 THEN i1 = 27 ELSE i1 = i
                        LOCATE 5 + i1, j * 7 - 2: PRINT SPACE$(7)
                END IF
        LOOP UNTIL i = 1
NEXT j

' Affichage de toutes les suites completes (fondations n = 1 a 8)
FOR n = 1 TO 8
        IF tas(n, 1, 1) > 0 THEN
                COLOR 1
                IF n > 1 THEN
                        LOCATE 38, -1 + n * 4: PRINT CHR$(203) + STRING$(3, 205) + CHR$(187)
                        LOCATE 39, -1 + n * 4: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 40, -1 + n * 4: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 41, -1 + n * 4: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 42, -1 + n * 4: PRINT CHR$(202) + STRING$(3, 205) + CHR$(188);
                ELSE
                        LOCATE 38, 3: PRINT CHR$(201) + STRING$(3, 205) + CHR$(187)
                        LOCATE 39, 3: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 40, 3: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 41, 3: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 42, 3: PRINT CHR$(200) + STRING$(3, 205) + CHR$(188);
                END IF
                LOCATE 40, n * 4: COLOR Coul(tas(n, 13, 2))
                PRINT carte$(13, tas(n, 13, 2))
        END IF
NEXT n

' Affichage visuel des paquets de pioche restants
COLOR 2
FOR p = 11 TO 15
        boxCol = 58 + (p - 11) * 4
        IF Jeu(1, p, 1) > 0 THEN
                IF p = 11 THEN
                        LOCATE 38, boxCol: PRINT CHR$(201) + STRING$(3, 205) + CHR$(187)
                        LOCATE 39, boxCol: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 40, boxCol: PRINT CHR$(186) + " D " + CHR$(186)
                        LOCATE 41, boxCol: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 42, boxCol: PRINT CHR$(200) + STRING$(3, 205) + CHR$(188);
                ELSE
                        LOCATE 38, boxCol: PRINT CHR$(203) + STRING$(3, 205) + CHR$(187)
                        LOCATE 39, boxCol: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 40, boxCol: PRINT CHR$(186) + " D " + CHR$(186)
                        LOCATE 41, boxCol: PRINT CHR$(186) + "   " + CHR$(186)
                        LOCATE 42, boxCol: PRINT CHR$(202) + STRING$(3, 205) + CHR$(188);
                END IF
        ELSE
                LOCATE 38, boxCol: PRINT "     "
                LOCATE 39, boxCol: PRINT "     "
                LOCATE 40, boxCol: PRINT "     "
                LOCATE 41, boxCol: PRINT "     "
                LOCATE 42, boxCol: PRINT "     ";
        END IF
NEXT p

END SUB

SUB aide

CLS
COLOR 13: LOCATE 4, 26: PRINT "=== AIDE : SPIDER SOLITAIRE ==="

COLOR 15
LOCATE 8, 5: PRINT "Le but est de constituer 8 series completes (du Roi a l'As) de meme couleur."
LOCATE 10, 5: PRINT "Les cartes rouges vont ensemble (Coeur/Carreau), les noires ensemble (Pique/Trefle)."
LOCATE 12, 5: PRINT "Vous pouvez deplacer une suite decroissante de meme couleur sur une carte"
LOCATE 13, 5: PRINT "de valeur immediatement superieure (ex: un 7 sur un 8)."
LOCATE 15, 5: PRINT "Une colonne vide peut accueillir n'importe quelle carte ou suite valide."

COLOR 11
LOCATE 18, 5: PRINT "COMMANDES DISPONIBLES AU CLAVIER :"
COLOR 14
LOCATE 20, 7: PRINT "col1.col2   : Deplacer des cartes (ex: 1.3 ou 1 3 ou 1,3)"
LOCATE 22, 7: PRINT "D           : Distribuer 1 carte sur chaque colonne (5 donnes)"
LOCATE 24, 7: PRINT "Z           : Annuler le dernier coup (jusqu'a 5 coups)"
LOCATE 26, 7: PRINT "H ou A ou ? : Afficher cette aide"
LOCATE 28, 7: PRINT "R ou F2     : Recommencer la partie"
LOCATE 30, 7: PRINT "Q           : Quitter la partie"

COLOR 10
LOCATE 34, 5: PRINT "Les series completes (Roi -> As) sont retirees automatiquement."

COLOR 7
LOCATE 38, 18: PRINT "Appuyez sur une touche pour revenir au jeu...";

DO
        k$ = INKEY$
LOOP WHILE k$ = ""

CLS
Fond
Affiche

END SUB

SUB AnnuleCoup

FOR i = 1 TO 4
        FOR j = 1 TO 5
                MemAnnul(j, i) = MemAnnul(j, i + 1)
        NEXT j
NEXT i

FOR j = 1 TO 5
        MemAnnul(j, 5) = 0
NEXT j

END SUB

SUB VerifSuite (col)

i = 51
DO
        i = i - 1
LOOP UNTIL Jeu(i, col, 1) > 0 OR i = 1

IF i >= 13 AND Jeu(i, col, 1) = 1 THEN
        OK0 = 1
        topCard = i
        DO
                i = i - 1
                IF Jeu(i + 1, col, 1) = Jeu(i, col, 1) - 1 AND ABS((Jeu(i + 1, col, 2) - Jeu(i, col, 2)) MOD 2) = 0 AND i > Cache(col) THEN
                        OK0 = OK0 + 1
                ELSE
                        OK0 = 0
                END IF
        LOOP UNTIL OK0 = 0 OR OK0 = 13 OR i = 1

        IF OK0 = 13 THEN
                n = 0
                DO
                        n = n + 1
                LOOP UNTIL n > 8 OR tas(n, 1, 1) = 0

                IF n <= 8 THEN
                        FOR j = 1 TO 13
                                tas(n, j, 1) = j
                                tas(n, j, 2) = Jeu(topCard - j + 1, col, 2)
                                Jeu(topCard - j + 1, col, 1) = 0
                                Jeu(topCard - j + 1, col, 2) = 0
                        NEXT j

                        IF Cache(col) = topCard - 13 AND topCard - 13 > 0 THEN
                                Cache(col) = Cache(col) - 1
                        END IF

                        CALL EnrCoup(0, 0, 0, 0, 0)
                        Affiche
                END IF
        END IF
END IF

END SUB

SUB Calcul

OK = 0                          ' Validation ou erreur de la demande

' *** Derniere carte de la colonne de destination ***
i = 51
DO
        i = i - 1
LOOP UNTIL Jeu(i, Dem2, 1) > 0 OR i = 1

IF Jeu(i, Dem2, 1) > 0 THEN
        i2 = i
        num2 = Jeu(i2, Dem2, 1)
        sign2 = Jeu(i2, Dem2, 2)
ELSE
        i2 = 0
        num2 = 14
END IF

' *** Recherche de la suite deplacable dans la colonne source ***
i = 51
i10 = 0
OK0 = 1

DO
        i = i - 1

        IF i10 > 0 THEN
                IF Jeu(i, Dem1, 1) = Jeu(i + 1, Dem1, 1) + 1 AND ABS((Jeu(i + 1, Dem1, 2) - Jeu(i, Dem1, 2)) MOD 2) = 0 AND i > Cache(Dem1) THEN
                        OK0 = 1
                ELSE
                        OK0 = 0
                END IF
        END IF

        IF i10 = 0 AND Jeu(i, Dem1, 1) > 0 THEN i10 = i

LOOP UNTIL i = 1 OR (i10 > 0 AND OK0 = 1 AND Jeu(i, Dem1, 1) = num2 - 1) OR OK0 = 0

IF OK0 = 0 THEN i1 = i + 1 ELSE i1 = i

' *** Verification et Deplacement ***
IF i10 > 0 AND i1 <= i10 THEN
        IF i2 = 0 OR Jeu(i1, Dem1, 1) = num2 - 1 THEN
                FOR k = 1 TO i10 - i1 + 1
                        Jeu(i2 + k, Dem2, 1) = Jeu(i1 + k - 1, Dem1, 1)
                        Jeu(i2 + k, Dem2, 2) = Jeu(i1 + k - 1, Dem1, 2)
                        Jeu(i1 + k - 1, Dem1, 1) = 0
                        Jeu(i1 + k - 1, Dem1, 2) = 0
                NEXT k

                OK = 1

                AffCache = 0
                IF i1 > 1 AND i1 - 1 = Cache(Dem1) THEN
                        Cache(Dem1) = Cache(Dem1) - 1
                        AffCache = 1
                END IF

                CALL EnrCoup(Dem1, i1, Dem2, i2 + 1, AffCache)

                ' Verification si une suite complete (Roi a As) est formee
                CALL VerifSuite(Dem2)
        END IF
END IF

IF OK = 0 THEN
        COLOR 12: LOCATE 37, 5: PRINT "Coup impossible !"; STRING$(55, " ");
        SLEEP 1
END IF

END SUB

FUNCTION Coul (sign)

IF sign = 2 OR sign = 4 THEN c = 15 ELSE c = 12
Coul = c

END FUNCTION

SUB Demande

DO
        OK = 0                   ' Validation de la demande

        COLOR 9: LOCATE 37, 1: PRINT STRING$(80, " ");
        LOCATE 37, 3: INPUT "? ", Dem$
        cmd$ = UCASE$(LTRIM$(RTRIM$(Dem$)))

        IF cmd$ = "Q" OR cmd$ = "QUIT" OR cmd$ = "FIN" THEN
                SortieJeu = 1
                EXIT SUB

        ELSEIF cmd$ = "H" OR cmd$ = "A" OR cmd$ = "AIDE" OR cmd$ = "HELP" OR cmd$ = "?" THEN
                aide

        ELSEIF cmd$ = "R" THEN
                LOCATE 37, 1: PRINT STRING$(80, " ");
                LOCATE 37, 3: COLOR 14: INPUT "Recommencer la partie ? (O/N) ", Rep$
                IF UCASE$(LEFT$(LTRIM$(Rep$), 1)) = "O" THEN
                        LOCATE 37, 1: PRINT STRING$(80, " ");
                        LOCATE 37, 3: INPUT "Meme distribution de cartes ? (O/N) ", Rep2$
                        IF UCASE$(LEFT$(LTRIM$(Rep2$), 1)) = "O" THEN Again = 1 ELSE Again = 0
                        GOTO Debut
                END IF

        ELSEIF cmd$ = "D" THEN
                ' Distribution d'une nouvelle ligne de 10 cartes depuis la pioche
                i = 10
                DO
                        i = i + 1
                LOOP UNTIL Jeu(1, i, 1) > 0 OR i = 15

                IF Jeu(1, i, 1) > 0 THEN
                        FOR k = 1 TO 10
                                j = 51
                                DO
                                        j = j - 1
                                LOOP UNTIL Jeu(j, k, 1) > 0 OR j = 1

                                IF Jeu(j, k, 1) > 0 THEN j = j + 1

                                Jeu(j, k, 1) = Jeu(k, i, 1)
                                Jeu(j, k, 2) = Jeu(k, i, 2)
                                Jeu(k, i, 1) = 0
                                Jeu(k, i, 2) = 0
                        NEXT k

                        ' Verifier si la donne a complete une suite sur l'une des colonnes
                        FOR k = 1 TO 10
                                CALL VerifSuite(k)
                        NEXT k

                        Affiche
                        CALL EnrCoup(0, 0, 0, 0, 0)
                ELSE
                        LOCATE 37, 5: COLOR 12: PRINT "Plus de cartes en pioche !"; STRING$(45, " ");
                        SLEEP 1
                END IF

        ELSEIF cmd$ = "Z" THEN
                ' Annulation du dernier coup
                IF MemAnnul(1, 1) > 0 THEN
                        i = 0
                        DO
                                Jeu(MemAnnul(2, 1) + i, MemAnnul(1, 1), 1) = Jeu(MemAnnul(4, 1) + i, MemAnnul(3, 1), 1)
                                Jeu(MemAnnul(2, 1) + i, MemAnnul(1, 1), 2) = Jeu(MemAnnul(4, 1) + i, MemAnnul(3, 1), 2)
                                Jeu(MemAnnul(4, 1) + i, MemAnnul(3, 1), 1) = 0
                                Jeu(MemAnnul(4, 1) + i, MemAnnul(3, 1), 2) = 0
                                i = i + 1
                        LOOP UNTIL Jeu(MemAnnul(4, 1) + i, MemAnnul(3, 1), 1) = 0

                        Cache(MemAnnul(1, 1)) = Cache(MemAnnul(1, 1)) + MemAnnul(5, 1)

                        AnnuleCoup
                        Affiche
                ELSE
                        LOCATE 37, 5: COLOR 12: PRINT "Aucun coup a annuler !"; STRING$(50, " ");
                        SLEEP 1
                END IF

        ELSEIF LEN(cmd$) > 0 THEN
                ' Recherche du separateur : point, virgule, espace ou tiret
                x = INSTR(cmd$, ".")
                IF x = 0 THEN x = INSTR(cmd$, ",")
                IF x = 0 THEN x = INSTR(cmd$, " ")
                IF x = 0 THEN x = INSTR(cmd$, "-")

                IF x > 0 THEN
                        Dem1$ = LEFT$(cmd$, x - 1)
                        Dem2$ = RIGHT$(cmd$, LEN(cmd$) - x)
                        IF VAL(Dem1$) >= 1 AND VAL(Dem1$) <= 10 THEN OK = OK + 1
                        IF VAL(Dem2$) >= 1 AND VAL(Dem2$) <= 10 AND VAL(Dem1$) <> VAL(Dem2$) THEN OK = OK + 1
                        Dem1 = VAL(Dem1$)
                        Dem2 = VAL(Dem2$)
                END IF

                IF OK < 2 THEN
                        LOCATE 37, 5: COLOR 12: PRINT "Format invalide ! Tapez col1.col2 (ex: 1.3), D, Z, H ou Q"; STRING$(20, " ");
                        SLEEP 1
                END IF
        END IF

LOOP UNTIL OK = 2 OR SortieJeu

END SUB

SUB Done (mem)

FOR i = 1 TO 10
        FOR j = 7 TO 10
                Jeu(j, i, 1) = 1: Jeu(j, i, 2) = 1
        NEXT j
NEXT i

FOR i = 5 TO 10
        Jeu(6, i, 1) = 1: Jeu(6, i, 2) = 1
NEXT i

RANDOMIZE TIMER

IF mem = 0 THEN
        FOR i = 1 TO 2
                FOR num = 1 TO 13
                        FOR sign = 1 TO 4
                                DO
                                        x = INT(RND * 15) + 1
                                        y = INT(RND * 10) + 1
                                LOOP UNTIL Jeu(y, x, 1) = 0
                                Jeu(y, x, 1) = num
                                Jeu(y, x, 2) = sign
                                JeuMem(y, x, 1) = num
                                JeuMem(y, x, 2) = sign
                        NEXT sign
                NEXT num
        NEXT i
ELSE
        FOR x = 1 TO 15
                FOR y = 1 TO 10
                        Jeu(y, x, 1) = JeuMem(y, x, 1)
                        Jeu(y, x, 2) = JeuMem(y, x, 2)
                NEXT y
        NEXT x
END IF

FOR i = 1 TO 10
        FOR j = 7 TO 10
                Jeu(j, i, 1) = 0: Jeu(j, i, 2) = 0
        NEXT j
NEXT i

FOR i = 5 TO 10
        Jeu(6, i, 1) = 0: Jeu(6, i, 2) = 0
NEXT i

END SUB

SUB EnrCoup (Col1, L1, Col2, L2, AffCache)

FOR i = 4 TO 1 STEP -1
        FOR j = 1 TO 5
                MemAnnul(j, i + 1) = MemAnnul(j, i)
        NEXT j
NEXT i

MemAnnul(1, 1) = Col1
MemAnnul(2, 1) = L1
MemAnnul(3, 1) = Col2
MemAnnul(4, 1) = L2
MemAnnul(5, 1) = AffCache

END SUB

SUB Fond

COLOR 13: LOCATE 2, 27: PRINT "SPIDER SOLITAIRE For QBasic"

COLOR 7
FOR i = 1 TO 10
        LOCATE 4, 7 * i: PRINT i
NEXT i

COLOR 2
LOCATE 38, 58: PRINT CHR$(201) + STRING$(3, 205) + CHR$(203) + STRING$(3, 205) + CHR$(203) + STRING$(3, 205) + CHR$(203) + STRING$(3, 205) + CHR$(203) + STRING$(3, 205) + CHR$(187)
LOCATE 39, 58: PRINT CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186)
LOCATE 40, 58: PRINT CHR$(186) + " D " + CHR$(186) + " D " + CHR$(186) + " D " + CHR$(186) + " D " + CHR$(186) + " D " + CHR$(186)
LOCATE 41, 58: PRINT CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186) + "   " + CHR$(186)
LOCATE 42, 58: PRINT CHR$(200) + STRING$(3, 205) + CHR$(202) + STRING$(3, 205) + CHR$(202) + STRING$(3, 205) + CHR$(202) + STRING$(3, 205) + CHR$(202) + STRING$(3, 205) + CHR$(188);

COLOR 7
LOCATE 43, 8: PRINT "D=Donne";
LOCATE 43, 20: PRINT "Z=Annuler";
LOCATE 43, 34: PRINT "F2/R=Recommencer";
LOCATE 43, 54: PRINT "F1/H=Aide";
LOCATE 43, 67: PRINT "Q=Quitter";

END SUB

SUB Init

FOR num = 1 TO 13                       ' Numero de la carte
        FOR sign = 1 TO 4               ' Symbole / enseigne de la carte

                SELECT CASE num
                        CASE 1: a$ = " A"
                        CASE 2 TO 9: a$ = STR$(num)
                        CASE 10: a$ = LTRIM$(STR$(num))
                        CASE 11: a$ = " V"
                        CASE 12: a$ = " D"
                        CASE 13: a$ = " R"
                END SELECT

                SELECT CASE sign
                        CASE 1: b$ = CHR$(4)     ' Carreau (Diamond)
                        CASE 2: b$ = CHR$(6)     ' Pique (Spade)
                        CASE 3: b$ = CHR$(3)     ' Coeur (Heart)
                        CASE 4: b$ = CHR$(5)     ' Trefle (Club)
                END SELECT

                carte$(num, sign) = a$ + b$
        NEXT sign
NEXT num

' Initialisation du tapis de jeu
FOR i = 1 TO 50
        FOR j = 1 TO 10
                Jeu(i, j, 1) = 0
                Jeu(i, j, 2) = 0
        NEXT j
NEXT i

' Initialisation des 8 suites completes (fondations)
FOR i = 1 TO 8
        FOR j = 1 TO 13
                tas(i, j, 1) = 0
                tas(i, j, 2) = 0
        NEXT j
NEXT i

' Initialisation des cartes masquees par colonne
FOR i = 1 TO 10
        IF i > 4 THEN Cache(i) = 4 ELSE Cache(i) = 5
NEXT i

' Initialisation de la pile d'annulation
FOR i = 1 TO 5
        FOR j = 1 TO 5
                MemAnnul(j, i) = 0
        NEXT j
NEXT i

SortieJeu = 0

END SUB
