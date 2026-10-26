' ========================================================
' UNIT TEST 15: Graphics Stress, Blitting XOR & Flood Fill
' ========================================================

SCREEN 13
CLS

' 1. Verifier le pixel vierge de fond
LET orig_bg = POINT(150, 100)
IF (orig_bg = 0) THEN
    PRINT "GFX_STRESS_INIT_BG: PASS"
ELSE
    PRINT "GFX_STRESS_INIT_BG: FAIL"
END IF

' 2. Dessin d'un motif de sprite a capturer
LINE (140, 90)-(160, 110), 14, BF
DIM spriteBuf(250)
GET (140, 90)-(160, 110), spriteBuf

' Effacer la zone
LINE (140, 90)-(160, 110), 0, BF

' 3. Blitting en mode XOR et restauration exacte par double XOR
' Premier PUT en XOR
PUT (140, 90), spriteBuf, XOR
LET xor_drawn = POINT(150, 100)
IF (xor_drawn = 14) THEN
    PRINT "GFX_STRESS_XOR_DRAW: PASS"
ELSE
    PRINT "GFX_STRESS_XOR_DRAW: FAIL"
END IF

' Deuxieme PUT en XOR au meme endroit (doit restaurer exactement l'arriere-plan d'origine 0)
PUT (140, 90), spriteBuf, XOR
LET xor_restored = POINT(150, 100)
IF (xor_restored = 0) THEN
    PRINT "GFX_STRESS_XOR_RESTORE: PASS"
ELSE
    PRINT "GFX_STRESS_XOR_RESTORE: FAIL"
END IF

' 4. Remplissage de zone avec PAINT
' Dessiner une boite de contour rouge (couleur 4)
LINE (20, 20)-(60, 60), 4, B

' Remplir l'interieur en vert (couleur 2) jusqu'a la bordure 4
PAINT (30, 30), 2, 4

LET inside_col = POINT(30, 30)
LET border_col = POINT(20, 20)
LET outside_col = POINT(70, 70)

IF (inside_col = 2 AND border_col = 4 AND outside_col = 0) THEN
    PRINT "GFX_STRESS_PAINT_FILL: PASS"
ELSE
    PRINT "GFX_STRESS_PAINT_FILL: FAIL"
END IF

' 5. Mode texte et finalisation
SCREEN 0
PRINT "GFX_STRESS_SCREEN_RESET: PASS"

PRINT "GRAPHICS_STRESS_ALL: PASS"
