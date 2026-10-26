' =========================================================================
' SUITE DE TESTS 17 : MOTEUR & MÉCANIQUES DU JEU TETRIS (FUTURE BLOCKS)
' Valide les tableaux 3D, DATA des pièces, polices matricielles,
' détection de collision, suppression de lignes, ports VGA DAC, IA
' et rendu multi-lettres avec isolation des scopes de procédures
' =========================================================================

DECLARE SUB Assert (testName$, condition%)
DECLARE SUB ReadPieceData ()
DECLARE SUB ReadFontData ()
DECLARE SUB DrawLetter (x%, y%, letter%, c%, size%, typ%)
DECLARE SUB DrawText (x%, y%, txt$, c%, size%, typ%)
DECLARE SUB MenuCheck ()

COMMON SHARED test_count%, pass_count%, fail_count%
COMMON SHARED PieceData%(), Text%(), Occupied%()
COMMON SHARED FieldWidth%, FieldHeight%, gap%, shadow%, menu_label_ran%

test_count% = 0
pass_count% = 0
fail_count% = 0

FieldWidth% = 12
FieldHeight% = 24

PRINT "=========================================================="
PRINT "  SUITE 17 : MOTEUR DU JEU TETRIS (FUTURE BLOCKS)"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. TABLEAUX 3D : DIM & ACCÈS MULTI-DIMENSIONNELS (DIM PieceData%(17, 3, 6))
' -------------------------------------------------------------------------
DIM PieceData%(17, 3, 6)
PieceData%(0, 0, 0) = 2
PieceData%(1, 0, 0) = 3
PieceData%(2, 0, 0) = 1
PieceData%(3, 1, 6) = 42
PieceData%(17, 3, 6) = 99

c1% = (PieceData%(0, 0, 0) = 2) AND (PieceData%(1, 0, 0) = 3) AND (PieceData%(3, 1, 6) = 42) AND (PieceData%(17, 3, 6) = 99)
Assert "TETRIS_3D_ARRAY_DIM_ACCESS", c1%

' -------------------------------------------------------------------------
' 2. CHARGEMENT COMPLET DES 7 PIÈCES ET 4 ROTATIONS (DATA / RESTORE)
' -------------------------------------------------------------------------
ReadPieceData
p1_ok% = (PieceData%(0, 0, 0) = 2) AND (PieceData%(1, 0, 0) = 3)
p3_ok% = (PieceData%(0, 0, 2) = 2) AND (PieceData%(1, 0, 2) = 2) AND (PieceData%(2, 0, 2) = 1)
p4_ok% = (PieceData%(0, 0, 3) = 1) AND (PieceData%(1, 0, 3) = 4) AND (PieceData%(0, 1, 3) = 4) AND (PieceData%(1, 1, 3) = 1)
p7_ok% = (PieceData%(0, 0, 6) = 3) AND (PieceData%(1, 0, 6) = 2)

Assert "TETRIS_PIECE_DATA_LOAD", (p1_ok% = -1) AND (p3_ok% = -1) AND (p4_ok% = -1) AND (p7_ok% = -1)

' -------------------------------------------------------------------------
' 3. POLICE MATRICIELLE BITMAP 5x7 (40 CARACTÈRES x 35 BITS)
' -------------------------------------------------------------------------
DIM Text%(39, 34)
ReadFontData
charA_ok% = (Text%(0, 0) = 0) AND (Text%(0, 2) = 1) AND (Text%(0, 15) = 1)
Assert "TETRIS_BITMAP_FONT_DATA", charA_ok%

' -------------------------------------------------------------------------
' 4. DÉTECTION DE COLLISION / SORTIE DU TERRAIN (CHECK OVERLAP)
' -------------------------------------------------------------------------
DIM Occupied%(FieldWidth%, FieldHeight%)
Occupied%(5, 20) = 1

test_col1% = Occupied%(5, 20) > 0
test_col2% = Occupied%(6, 20) = 0
test_bounds% = (5 >= 1 AND 5 <= FieldWidth% AND 20 >= 1 AND 20 <= FieldHeight%)
Assert "TETRIS_COLLISION_DETECTION", (test_col1% = -1) AND (test_col2% = -1) AND (test_bounds% = -1)

' -------------------------------------------------------------------------
' 5. ROTATION GÉOMÉTRIQUE DES TÉDROMINOS (DIMENSIONS INVERSÉES Xs <-> Ys)
' -------------------------------------------------------------------------
rot_xs0% = PieceData%(0, 0, 3)
rot_ys0% = PieceData%(1, 0, 3)
rot_xs1% = PieceData%(0, 1, 3)
rot_ys1% = PieceData%(1, 1, 3)
Assert "TETRIS_PIECE_ROTATION_MATH", (rot_xs0% = 1 AND rot_ys0% = 4 AND rot_xs1% = 4 AND rot_ys1% = 1)

' -------------------------------------------------------------------------
' 6. SUPPRESSION DE LIGNE COMPLÈTE & GRAVITÉ (CHECK COMPLETE / SHIFT)
' -------------------------------------------------------------------------
FOR col% = 1 TO FieldWidth%
  Occupied%(col%, 24) = 2
NEXT col%
Occupied%(3, 23) = 4

full_line% = 1
FOR col% = 1 TO FieldWidth%
  IF Occupied%(col%, 24) = 0 THEN full_line% = 0
NEXT col%

IF full_line% = 1 THEN
  FOR y% = 24 TO 2 STEP -1
    FOR x% = 1 TO FieldWidth%
      Occupied%(x%, y%) = Occupied%(x%, y% - 1)
    NEXT x%
  NEXT y%
  FOR x% = 1 TO FieldWidth%
    Occupied%(x%, 1) = 0
  NEXT x%
END IF

shifted_ok% = (Occupied%(3, 24) = 4) AND (Occupied%(3, 23) = 0)
Assert "TETRIS_LINE_CLEAR_GRAVITY", (full_line% = 1) AND (shifted_ok% = -1)

' -------------------------------------------------------------------------
' 7. CALCUL DU SCORE & BONUS TEMPS (SCORING FORMULA)
' -------------------------------------------------------------------------
lines_cleared% = 2
air_time! = 1.5
score_bonus& = lines_cleared% * 100 * (5 - air_time!)
Assert "TETRIS_SCORING_CALCULATION", (score_bonus& = 700)

' -------------------------------------------------------------------------
' 8. ÉMULATION DES PORTS VGA DAC (LECTURE/ÉCRITURE PALETTE 0x3C8 / 0x3C9)
' -------------------------------------------------------------------------
OUT &H3C8, 7
OUT &H3C9, 40
OUT &H3C9, 50
OUT &H3C9, 60

OUT &H3C7, 7
r_in% = INP(&H3C9)
g_in% = INP(&H3C9)
b_in% = INP(&H3C9)

dac_ok% = (r_in% = 40) AND (g_in% = 50) AND (b_in% = 60)
Assert "TETRIS_VGA_DAC_PALETTE_PORTS", dac_ok%

' -------------------------------------------------------------------------
' 9. SYNCHRONISATION SYNTAXIQUE WAIT (WAIT 986, 8)
' -------------------------------------------------------------------------
WAIT 986, 8
Assert "TETRIS_WAIT_VSYNC_STATEMENT", -1

' -------------------------------------------------------------------------
' 10. IA & HEURISTIQUE DE PLACEMENT (COMPUTER PLAY EVALUATION)
' -------------------------------------------------------------------------
LineWeight = 3
GapWeight = 4
HeightWeight = 1
SideWeight = 1

eval1 = (1 * LineWeight * 10) - (0 * GapWeight * 5) - (20 * HeightWeight)
eval2 = (0 * LineWeight * 10) - (2 * GapWeight * 5) - (22 * HeightWeight)
ai_eval_ok% = (eval1 > eval2)
Assert "TETRIS_AI_HEURISTIC_WEIGHTS", ai_eval_ok%

' -------------------------------------------------------------------------
' 11. RENDU DE TEXTE MULTI-LETTRES (ISOLATION SCOPE PROCÉDURE)
' -------------------------------------------------------------------------
SCREEN 12
gap% = 10: shadow% = 3
DrawText 50, 50, "FUTURE", 2, 14, 2
DrawText 100, 200, "BLOCKS", 2, 14, 2

col_F% = POINT(55, 55)
col_U% = POINT(140, 55)
col_T% = POINT(225, 55)
col_E% = POINT(480, 55)
render_ok% = (col_F% > 0) AND (col_U% > 0) AND (col_T% > 0) AND (col_E% > 0)
Assert "TETRIS_MULTI_LETTER_RENDER", render_ok%

' -------------------------------------------------------------------------
' 12. ÉTIQUETTE PORTANT LE MÊME NOM QUE LA PROCÉDURE (SUB Menu / Menu:)
' -------------------------------------------------------------------------
menu_label_ran% = 0
MenuCheck
Assert "TETRIS_SUB_SAME_NAME_LABEL", (menu_label_ran% = 1)

' -------------------------------------------------------------------------
' BILAN DE LA SUITE
' -------------------------------------------------------------------------
PRINT "----------------------------------------------------------"
PRINT "RÉSULTAT SUITE 17 : "; pass_count%; "/"; test_count%; " tests réussis."
IF fail_count% = 0 THEN
  PRINT "STATUS: ALL TESTS PASSED"
ELSE
  PRINT "STATUS: SOME TESTS FAILED"
END IF
END

' =========================================================================
' DONNÉES ET SOUS-ROUTINES
' =========================================================================

Piece1:
 DATA 2,3
 DATA 1,0
 DATA 1,1
 DATA 0,1
 DATA 3,2
 DATA 0,1,1
 DATA 1,1,0
 DATA 2,3
 DATA 1,0
 DATA 1,1
 DATA 0,1
 DATA 3,2
 DATA 0,1,1
 DATA 1,1,0
Piece2:
 DATA 2,3
 DATA 0,1
 DATA 1,1
 DATA 1,0
 DATA 3,2
 DATA 1,1,0
 DATA 0,1,1
 DATA 2,3
 DATA 0,1
 DATA 1,1
 DATA 1,0
 DATA 3,2
 DATA 1,1,0
 DATA 0,1,1
Piece3:
 DATA 2,2
 DATA 1,1
 DATA 1,1
 DATA 2,2
 DATA 1,1
 DATA 1,1
 DATA 2,2
 DATA 1,1
 DATA 1,1
 DATA 2,2
 DATA 1,1
 DATA 1,1
Piece4:
 DATA 1,4
 DATA 1
 DATA 1
 DATA 1
 DATA 1
 DATA 4,1
 DATA 1,1,1,1
 DATA 1,4
 DATA 1
 DATA 1
 DATA 1
 DATA 1
 DATA 4,1
 DATA 1,1,1,1
Piece5:
 DATA 2,3
 DATA 1,0
 DATA 1,0
 DATA 1,1
 DATA 3,2
 DATA 1,1,1
 DATA 1,0,0
 DATA 2,3
 DATA 1,1
 DATA 0,1
 DATA 0,1
 DATA 3,2
 DATA 0,0,1
 DATA 1,1,1
Piece6:
 DATA 2,3
 DATA 0,1
 DATA 0,1
 DATA 1,1
 DATA 3,2
 DATA 1,0,0
 DATA 1,1,1
 DATA 2,3
 DATA 1,1
 DATA 1,0
 DATA 1,0
 DATA 3,2
 DATA 1,1,1
 DATA 0,0,1
Piece7:
 DATA 3,2
 DATA 0,1,0
 DATA 1,1,1
 DATA 2,3
 DATA 1,0
 DATA 1,1
 DATA 1,0
 DATA 3,2
 DATA 1,1,1
 DATA 0,1,0
 DATA 2,3
 DATA 0,1
 DATA 1,1
 DATA 0,1

Text:
 DATA 0,0,1,0,0
 DATA 0,1,0,1,0
 DATA 1,0,0,0,1
 DATA 1,1,1,1,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,1,1,0
 DATA 0,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,1
 DATA 0,1,1,1,0
 DATA 1,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,1,1,0
 DATA 1,1,1,1,1
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,1,1,1,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,1,1,1,1
 DATA 1,1,1,1,1
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,1,1,1,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 0,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,0
 DATA 1,0,1,1,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,1,1,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,1,1,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,1,1,1,0
 DATA 0,0,0,0,1
 DATA 0,0,0,0,1
 DATA 0,0,0,0,1
 DATA 0,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,1,0
 DATA 1,0,1,0,0
 DATA 1,1,0,0,0
 DATA 1,0,1,0,0
 DATA 1,0,0,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,1,1,1,1
 DATA 1,0,0,0,1
 DATA 1,1,0,1,1
 DATA 1,0,1,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,0,0,1
 DATA 1,0,1,0,1
 DATA 1,0,0,1,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,1,1,0
 DATA 1,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,1,1,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 0,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,1,0,1
 DATA 1,0,0,1,1
 DATA 0,1,1,1,1
 DATA 1,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,1,1,1,0
 DATA 1,0,1,0,0
 DATA 1,0,0,1,0
 DATA 1,0,0,0,1
 DATA 0,1,1,1,1
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 0,1,1,1,0
 DATA 0,0,0,0,1
 DATA 0,0,0,0,1
 DATA 1,1,1,1,0
 DATA 1,1,1,1,1
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,1,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,0,1,0
 DATA 0,0,1,0,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,1,0,1
 DATA 1,0,1,0,1
 DATA 1,1,0,1,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,0,1,0
 DATA 0,0,1,0,0
 DATA 0,1,0,1,0
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 1,0,0,0,1
 DATA 0,1,0,1,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 0,0,1,0,0
 DATA 1,1,1,1,1
 DATA 0,0,0,1,0
 DATA 0,0,1,0,0
 DATA 0,1,0,0,0
 DATA 1,0,0,0,0
 DATA 1,0,0,0,0
 DATA 1,1,1,1,1

SUB ReadPieceData
  RESTORE Piece1
  FOR p% = 0 TO 6
    FOR r% = 0 TO 3
      READ Xs%, Ys%
      PieceData%(0, r%, p%) = Xs%
      PieceData%(1, r%, p%) = Ys%
      b% = Xs% * Ys%
      FOR n% = 0 TO b% - 1
        READ PieceData%(n% + 2, r%, p%)
      NEXT n%
    NEXT r%
  NEXT p%
END SUB

SUB ReadFontData
  RESTORE Text
  FOR l% = 0 TO 25
    FOR n% = 0 TO 6
      READ Text%(l%, n% * 5), Text%(l%, n% * 5 + 1), Text%(l%, n% * 5 + 2), Text%(l%, n% * 5 + 3), Text%(l%, n% * 5 + 4)
    NEXT n%
  NEXT l%
END SUB

SUB DrawText (x%, y%, txt$, c%, size%, typ%)
 txt$ = UCASE$(txt$)
 sx% = x%: sy% = y%
 n% = 1
 DO
 t$ = MID$(txt$, n%, 1)
 t% = ASC(t$)
 IF t% = 32 THEN GOTO Skip
 IF t% = 41 THEN t% = 36
 IF t% = 46 THEN t% = 37
 IF t% = 43 THEN t% = 38
 IF t% = 45 THEN t% = 39
 IF t% > 64 AND t% < 91 THEN
  t% = t% - 65
 END IF
 IF t% > 47 AND t% < 58 THEN
  t% = t% - 22
 END IF
 DrawLetter x%, y%, t%, c%, size%, typ%
Skip:
 y% = sy%
 x% = x% + (size% + 1) * 5 + gap%
 n% = n% + 1
 LOOP WHILE n% < LEN(txt$) + 1
END SUB

SUB DrawLetter (x%, y%, letter%, c%, size%, typ%)
 sx% = x%: sy% = y%
 xn% = 0: yn% = 0
 n% = 0
 DO
 d% = Text%(letter%, n%)
 IF d% = 1 THEN
  IF typ% = 0 THEN
   LINE (x% + 1, y% + 1)-(x% + size% - 1, y% + size% - 1), c%, BF
   LINE (x%, y%)-(x% + size%, y%), 15
   LINE (x%, y%)-(x%, y% + size%), 15
   LINE (x% + size%, y%)-(x% + size%, y% + size%), 8
   LINE (x%, y% + size%)-(x% + size%, y% + size%), 8
  END IF
  IF typ% = 1 THEN
   LINE (x%, y%)-(x% + size%, y% + size%), c%, BF
  END IF
  IF typ% = 2 THEN
   LINE (x% + 1 + shadow%, y% + 1 + shadow%)-(x% + size% + 1 + shadow%, y% + size% + 1 + shadow%), 0, BF
   LINE (x% + 1, y% + 1)-(x% + size% - 1, y% + size% - 1), c%, BF
   LINE (x%, y%)-(x% + size%, y%), 15
   LINE (x%, y%)-(x%, y% + size%), 15
   LINE (x% + size%, y%)-(x% + size%, y% + size%), 8
   LINE (x%, y% + size%)-(x% + size%, y% + size%), 8
  END IF
 END IF
 n% = n% + 1
 xn% = xn% + 1
 x% = x% + size% + 1
 IF xn% > 4 THEN xn% = 0: x% = sx%: y% = y% + size% + 1
 LOOP WHILE n% < 35
END SUB

SUB Assert (testName$, condition%)
  test_count% = test_count% + 1
  IF condition% THEN
    pass_count% = pass_count% + 1
    PRINT testName$; ": PASS"
  ELSE
    fail_count% = fail_count% + 1
    PRINT testName$; ": FAIL"
  END IF
END SUB

SUB MenuCheck
MenuCheck:
  menu_label_ran% = 1
END SUB

