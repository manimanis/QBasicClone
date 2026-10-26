' ===================================================
' ANIMATION CONSOLE EN QBASIC NATIF WINDOWS
' ===================================================
CLS
COLOR 14, 0
LOCATE 2, 10
PRINT "=== SIMULATION BALLE REBONDISSANTE (QBASIC WIN64) ==="
COLOR 11, 0
LOCATE 3, 10
PRINT "Appuyez sur une touche pour commencer..."

LET X = 5
LET Y = 5
LET DX = 1
LET DY = 1

FOR STEP_COUNT = 1 TO 35
    ' Effacer l'ancienne position
    COLOR 7, 0
    LOCATE Y, X
    PRINT " "

    ' Calculer la nouvelle position
    LET X = X + DX
    LET Y = Y + DY

    ' Rebond sur les bords (Console 80x25)
    IF X >= 50 THEN LET DX = -1
    IF X <= 2  THEN LET DX = 1
    IF Y >= 18 THEN LET DY = -1
    IF Y <= 5  THEN LET DY = 1

    ' Dessiner la balle avec une couleur vive
    COLOR 12, 0
    LOCATE Y, X
    PRINT "O"
    
    ' Petite pause
    SLEEP 0.05
NEXT STEP_COUNT

COLOR 10, 0
LOCATE 20, 10
PRINT "Animation terminee avec succes dans la console Windows !"
COLOR 7, 0
LOCATE 22, 1
PRINT
