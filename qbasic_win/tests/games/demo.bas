' ===============================================
' DEMONSTRATION DU PORT NATIF QBASIC SOUS WINDOWS
' ===============================================
CLS
COLOR 14, 1
PRINT "*************************************************"
PRINT "*     MICROSOFT QBASIC 1.1 - PORT NATIF WIN64   *"
PRINT "*************************************************"
COLOR 15, 0
PRINT

' 1. Test des variables et chaines
LET NOM$ = "QBasic Recompile"
LET VERSION$ = "1.1-Win64"
PRINT "Programme : "; NOM$; " - Version : "; VERSION$
PRINT "Longueur du titre : "; LEN(NOM$)
PRINT "En majuscules     : "; UCASE$(NOM$)
PRINT "Sous-chaine MID$  : "; MID$(NOM$, 1, 6)
PRINT

' 2. Test des calculs mathematiques
COLOR 10, 0
PRINT "Calculs mathematiques :"
LET X = 25
PRINT "Racine carree SQR("; X; ") = "; SQR(X)
PRINT "Cosinus COS(0) = "; COS(0)
PRINT "Calcul flottant (3.14 * 2) = "; 3.14 * 2
PRINT

' 3. Test de boucle FOR ... NEXT
COLOR 11, 0
PRINT "Compteur FOR ... NEXT :"
FOR I = 1 TO 5
    PRINT "  Iteration "; I; " au carre = "; I * I
NEXT I
PRINT

' 4. Test conditionnel
LET SCORE = 100
IF SCORE >= 50 THEN PRINT "Condition Verifiee : SCORE >= 50 !"

' 5. Signal et Horloge
PRINT "Heure systeme TIMER : "; INT(TIMER); " secondes depuis minuit"
COLOR 14, 0
PRINT "Test termine avec succes !"
COLOR 7, 0
