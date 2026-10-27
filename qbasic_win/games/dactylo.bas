'********************************************************
'********* Programme cree par Christian Hoffmann ********
'********* E-Mail: jemaf@free.fr                 ********
'********* telecharge sur le site jemaf.free.fr  ********
'********* Rectifie pour QBasic / Win64          ********
'********************************************************

' DACTYLO
' Testez et ameliorez votre rapidite de saisie au clavier.
' 3 textes d'auteurs classiques au choix.

DECLARE SUB textes (txt!)
DECLARE SUB principal (xlettre!, ylettre!, e!, txt!)

DIM SHARED Baudelaire$, Hugo$, Poe$, choix, SortieDactylo

SCREEN 0: WIDTH 80, 25: CLS

DO
    xlettre = 4
    ylettre = 1
    e = 1
    txt = 0

    textes txt
    IF SortieDactylo THEN EXIT DO

    principal xlettre, ylettre, e, txt
LOOP

CLS
COLOR 15: PRINT "Merci d'avoir utilise Dactylo. A bientot !"
COLOR 7
END

SUB principal (xlettre, ylettre, e, txt)

erreur = 0
nbtouches = 0

IF choix = 1 THEN t$ = Baudelaire$
IF choix = 2 THEN t$ = Hugo$
IF choix = 3 THEN t$ = Poe$

TIMER ON
DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
hdepart = TIMER

DO
    IF k$ <> "" THEN
        IF k$ = CHR$(27) THEN EXIT DO   ' Possibilite d'abandonner avec Echap

        nbtouches = nbtouches + 1
        IF k$ = MID$(t$, e + 4, 1) THEN
            e = e + 1
            xlettre = xlettre + 1
            IF xlettre >= 81 THEN ylettre = ylettre + 1: xlettre = 1
            COLOR 15: LOCATE ylettre, xlettre: PRINT k$
        ELSE
            IF erreur < 5 THEN
                son$ = MID$("CDEFG", erreur + 1, 1)
                PLAY "O3L10" + son$
            END IF
            erreur = erreur + 1
            COLOR 12: LOCATE 10, 27: PRINT erreur; "erreur(s)"
        END IF
    END IF

    COLOR 15: LOCATE 6, 10: PRINT "Longueur du texte :"; txt; "caracteres"
    LOCATE 8, 10: PRINT "Caracteres frappes :"; nbtouches; "  "
    IF txt > 0 THEN
        pct = CINT((nbtouches - erreur) * 100 / txt)
        IF pct < 0 THEN pct = 0
        IF pct > 100 THEN pct = 100
        LOCATE 16, 10: PRINT "Progression :"; pct; "% du texte "
    END IF

    temps = TIMER - hdepart
    IF temps < 0 THEN temps = 0
    t_restant = CINT(70 - temps)
    IF t_restant < 0 THEN t_restant = 0
    COLOR 9: LOCATE 23, 27: PRINT t_restant; "s  "

    k$ = INKEY$
LOOP UNTIL temps > 70 OR erreur >= 5 OR (nbtouches - erreur >= txt)

COLOR 4
LOCATE 19, 1: PRINT STRING$(80, CHR$(219));
LOCATE 20, 1: PRINT STRING$(25, CHR$(219));
LOCATE 20, 56: PRINT STRING$(25, CHR$(219));
LOCATE 21, 1: PRINT STRING$(80, CHR$(219));

COLOR 14
IF temps > 70 THEN
    LOCATE 20, 34: PRINT " TEMPS ECOULE ! "
ELSEIF erreur >= 5 THEN
    LOCATE 20, 33: PRINT " TROP DE FAUTES ! "
ELSE
    LOCATE 20, 31: PRINT " VOUS AVEZ REUSSI ! "
    PLAY "O3L20CDEFG"
END IF

COLOR 7: LOCATE 24, 20: PRINT "Appuyez sur une touche pour continuer...";
DO: k$ = INKEY$: LOOP UNTIL k$ <> ""

END SUB

SUB textes (txt)

CLS
COLOR 14: LOCATE 3, 24: PRINT "=== TEST DE DACTYLOGRAPHIE ==="
COLOR 15
LOCATE 6, 5: PRINT "Vous avez 70 secondes pour recopier fidelement le texte choisi !"
LOCATE 8, 5: PRINT "Quel texte voulez-vous recopier ?"

COLOR 11
LOCATE 11, 10: PRINT "1) Extrait de 'Petits Poemes en prose' (Baudelaire)"
LOCATE 13, 10: PRINT "2) Extrait de 'Les Miserables' (Victor Hugo)"
LOCATE 15, 10: PRINT "3) Extrait de 'Histoires extraordinaires' (Edgar Allan Poe)"
LOCATE 17, 10: PRINT "4) Quitter"

COLOR 14: LOCATE 20, 10: PRINT "Votre choix (1-4) : ";

DO
    k$ = INKEY$
    IF k$ = "1" OR k$ = "2" OR k$ = "3" OR k$ = "4" OR k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN EXIT DO
LOOP

IF k$ = "4" OR k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN
    SortieDactylo = 1
    EXIT SUB
END IF

choix = VAL(k$)
PRINT choix

CLS : COLOR 3

SELECT CASE choix
    CASE 1
        Baudelaire$ = "    Ma petite folle bien-aimee me donnait a diner, et par la fenetre ouverte de la salle a manger je contemplais les mouvantes architectures que Dieu fait avec les vapeurs, les merveilleuses constructions de l'impalpable."
        PRINT Baudelaire$
        txt = LEN(Baudelaire$) - 4
    CASE 2
        Hugo$ = "    Il existe des etres qui, pour connaitre le mot de ces enigmes, lesquelles leur sont du reste parfaitement indifferentes, depensent plus d'argent, prodiguent plus de temps, se donnent plus de peine qu'il n'en faudrait pour dix bonnes actions."
        PRINT Hugo$
        txt = LEN(Hugo$) - 4
    CASE 3
        Poe$ = "    Bien que les tenebres du doute enveloppent encore toute la theorie positive du magnetisme, ses foudroyants effets sont maintenant presque universellement admis. Ceux qui doutent de ces effets sont de purs douteurs de profession, une impuissante et peu honorable caste."
        PRINT Poe$
        txt = LEN(Poe$) - 4
END SELECT

COLOR 15
LOCATE 6, 10: PRINT "Longueur du texte :"; txt; "caracteres"
LOCATE 8, 10: PRINT "Caracteres frappes : 0"
LOCATE 10, 10: PRINT "Erreurs commises   : 0"
LOCATE 16, 10: PRINT "Progression        : 0 %"
COLOR 9: LOCATE 23, 10: PRINT "Temps restant      : 70 s"

END SUB
