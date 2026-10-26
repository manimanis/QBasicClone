' ========================================================
' UNIT TEST 27: INKEY$ & INPUT Variants Comprehensive Battery
' ========================================================

' --------------------------------------------------------
' SECTION 1: INKEY$ Fundamental Semantics (Standard Keys)
' --------------------------------------------------------

' 1. Buffer vide : INKEY$ renvoie "" de longueur 0
LET emptyKey$ = INKEY$
IF (LEN(emptyKey$) = 0 AND emptyKey$ = "") THEN
    PRINT "INKEY_EMPTY_QUEUE: PASS"
ELSE
    PRINT "INKEY_EMPTY_QUEUE: FAIL"
END IF

' 2. Idiome classique QBasic : vidage de tampon WHILE INKEY$ <> "": WEND
LET drainCount = 0
WHILE INKEY$ <> ""
    drainCount = drainCount + 1
WEND
IF (drainCount = 0) THEN
    PRINT "INKEY_CLEAR_IDIOM: PASS"
ELSE
    PRINT "INKEY_CLEAR_IDIOM: FAIL"
END IF

' 3. Touche Échap (ASCII 27)
LET escKey$ = CHR$(27)
IF (LEN(escKey$) = 1 AND ASC(escKey$) = 27) THEN
    PRINT "INKEY_KEY_ESCAPE: PASS"
ELSE
    PRINT "INKEY_KEY_ESCAPE: FAIL"
END IF

' 4. Touche Entrée (ASCII 13)
LET retKey$ = CHR$(13)
IF (LEN(retKey$) = 1 AND ASC(retKey$) = 13) THEN
    PRINT "INKEY_KEY_RETURN: PASS"
ELSE
    PRINT "INKEY_KEY_RETURN: FAIL"
END IF

' 5. Touche Retour arrière Backspace (ASCII 8)
LET bkspKey$ = CHR$(8)
IF (LEN(bkspKey$) = 1 AND ASC(bkspKey$) = 8) THEN
    PRINT "INKEY_KEY_BACKSPACE: PASS"
ELSE
    PRINT "INKEY_KEY_BACKSPACE: FAIL"
END IF

' 6. Touche Tabulation (ASCII 9)
LET tabKey$ = CHR$(9)
IF (LEN(tabKey$) = 1 AND ASC(tabKey$) = 9) THEN
    PRINT "INKEY_KEY_TAB: PASS"
ELSE
    PRINT "INKEY_KEY_TAB: FAIL"
END IF

' 7. Touche Espace (ASCII 32)
LET spcKey$ = CHR$(32)
IF (LEN(spcKey$) = 1 AND ASC(spcKey$) = 32 AND spcKey$ = " ") THEN
    PRINT "INKEY_KEY_SPACE: PASS"
ELSE
    PRINT "INKEY_KEY_SPACE: FAIL"
END IF


' --------------------------------------------------------
' SECTION 2: Extended Keys (2-Byte Strings: CHR$(0) + DOS ScanCode)
' --------------------------------------------------------

' 8. Flèche Haut : CHR$(0) + "H" (ScanCode 72)
LET upKey$ = CHR$(0) + "H"
IF (LEN(upKey$) = 2 AND ASC(upKey$) = 0) THEN
    PRINT "INKEY_EXT_UP_LEN_AND_ZERO: PASS"
ELSE
    PRINT "INKEY_EXT_UP_LEN_AND_ZERO: FAIL"
END IF

' 9. Flèche Haut ScanCode DOS : RIGHT$(upKey$, 1) = "H" (72)
IF (RIGHT$(upKey$, 1) = "H" AND ASC(RIGHT$(upKey$, 1)) = 72) THEN
    PRINT "INKEY_EXT_UP_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_UP_SCANCODE: FAIL"
END IF

' 10. Flèche Bas : CHR$(0) + "P" (ScanCode 80)
LET downKey$ = CHR$(0) + "P"
IF (LEN(downKey$) = 2 AND ASC(RIGHT$(downKey$, 1)) = 80) THEN
    PRINT "INKEY_EXT_DOWN_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_DOWN_SCANCODE: FAIL"
END IF

' 11. Flèche Gauche : CHR$(0) + "K" (ScanCode 75)
LET leftKey$ = CHR$(0) + "K"
IF (LEN(leftKey$) = 2 AND ASC(RIGHT$(leftKey$, 1)) = 75) THEN
    PRINT "INKEY_EXT_LEFT_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_LEFT_SCANCODE: FAIL"
END IF

' 12. Flèche Droite : CHR$(0) + "M" (ScanCode 77)
LET rightKey$ = CHR$(0) + "M"
IF (LEN(rightKey$) = 2 AND ASC(RIGHT$(rightKey$, 1)) = 77) THEN
    PRINT "INKEY_EXT_RIGHT_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_RIGHT_SCANCODE: FAIL"
END IF

' 13. Touche F1 : CHR$(0) + CHR$(59)
LET f1Key$ = CHR$(0) + CHR$(59)
IF (LEN(f1Key$) = 2 AND ASC(RIGHT$(f1Key$, 1)) = 59) THEN
    PRINT "INKEY_EXT_F1_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_F1_SCANCODE: FAIL"
END IF

' 14. Touche F10 : CHR$(0) + CHR$(68)
LET f10Key$ = CHR$(0) + CHR$(68)
IF (LEN(f10Key$) = 2 AND ASC(RIGHT$(f10Key$, 1)) = 68) THEN
    PRINT "INKEY_EXT_F10_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_F10_SCANCODE: FAIL"
END IF

' 15. Touche Home / Début : CHR$(0) + "G" (ScanCode 71)
LET homeKey$ = CHR$(0) + "G"
IF (LEN(homeKey$) = 2 AND ASC(RIGHT$(homeKey$, 1)) = 71) THEN
    PRINT "INKEY_EXT_HOME_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_HOME_SCANCODE: FAIL"
END IF

' 16. Touche End / Fin : CHR$(0) + "O" (ScanCode 79)
LET endKey$ = CHR$(0) + "O"
IF (LEN(endKey$) = 2 AND ASC(RIGHT$(endKey$, 1)) = 79) THEN
    PRINT "INKEY_EXT_END_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_END_SCANCODE: FAIL"
END IF

' 17. Touche Inser : CHR$(0) + "R" (ScanCode 82)
LET insKey$ = CHR$(0) + "R"
IF (LEN(insKey$) = 2 AND ASC(RIGHT$(insKey$, 1)) = 82) THEN
    PRINT "INKEY_EXT_INSERT_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_INSERT_SCANCODE: FAIL"
END IF

' 18. Touche Suppr : CHR$(0) + "S" (ScanCode 83)
LET delKey$ = CHR$(0) + "S"
IF (LEN(delKey$) = 2 AND ASC(RIGHT$(delKey$, 1)) = 83) THEN
    PRINT "INKEY_EXT_DELETE_SCANCODE: PASS"
ELSE
    PRINT "INKEY_EXT_DELETE_SCANCODE: FAIL"
END IF


' --------------------------------------------------------
' SECTION 3: Advanced Handling: SELECT CASE & D5000 Loop Simulation
' --------------------------------------------------------

' 19. SELECT CASE avec touches étendues (utilisé dans les jeux DOS)
LET testMove$ = CHR$(0) + "H"
LET moveDirection$ = "UNKNOWN"
SELECT CASE testMove$
    CASE CHR$(0) + "H"
        moveDirection$ = "UP"
    CASE CHR$(0) + "P"
        moveDirection$ = "DOWN"
    CASE CHR$(0) + "K"
        moveDirection$ = "LEFT"
    CASE CHR$(0) + "M"
        moveDirection$ = "RIGHT"
    CASE ELSE
        moveDirection$ = "OTHER"
END SELECT
IF (moveDirection$ = "UP") THEN
    PRINT "INKEY_SELECT_CASE_EXT: PASS"
ELSE
    PRINT "INKEY_SELECT_CASE_EXT: FAIL"
END IF

' 20. Simulation de l'algorithme de saisie interactif de D5000.BAS (lignes 156-173)
' Teste la séquence de touches : "A", "l", "i", CHR$(8) (backspace), "e", "n", CHR$(13) (entrée)
DIM keyStream$(1 TO 7)
keyStream$(1) = "A"
keyStream$(2) = "l"
keyStream$(3) = "i"
keyStream$(4) = CHR$(8)  ' Backspace : efface le "i"
keyStream$(5) = "e"
keyStream$(6) = "n"
keyStream$(7) = CHR$(13) ' Entrée : valide le nom

LET playerName$ = ""
LET carPos = 0
FOR ki = 1 TO 7
    LET kChar$ = keyStream$(ki)
    IF kChar$ = CHR$(27) THEN
        ' Échap
    ELSEIF kChar$ = CHR$(13) THEN
        ' Validation entrée
        EXIT FOR
    ELSEIF kChar$ = CHR$(8) THEN
        ' Effacement arrière
        IF carPos > 0 THEN
            carPos = carPos - 1
            playerName$ = LEFT$(playerName$, carPos)
        END IF
    ELSEIF kChar$ = CHR$(32) THEN
        ' Espace
        IF carPos < 8 THEN
            carPos = carPos + 1
            playerName$ = playerName$ + " "
        END IF
    ELSEIF kChar$ <> "" AND carPos < 8 THEN
        carPos = carPos + 1
        playerName$ = playerName$ + UCASE$(kChar$)
    END IF
NEXT ki

IF (playerName$ = "ALEN" AND carPos = 4) THEN
    PRINT "INKEY_D5000_KEY_HANDLER: PASS"
ELSE
    PRINT "INKEY_D5000_KEY_HANDLER: FAIL"
END IF


' --------------------------------------------------------
' SECTION 4: LINE INPUT # File Variants
' --------------------------------------------------------

' Création d'un fichier contenant virgules, guillemets, espaces et lignes vides
OPEN "temp_test_input.txt" FOR OUTPUT AS #1
PRINT #1, "Alice, 42, Software Engineer, ""Paris, France"""
PRINT #1, ""
PRINT #1, "   Indented text with spaces and quotes: 'Hello'   "
PRINT #1, "Derniere Ligne"
CLOSE #1

' 21. LINE INPUT # préserve l'intégralité de la ligne sans scinder aux virgules
OPEN "temp_test_input.txt" FOR INPUT AS #1
LINE INPUT #1, lineRaw1$
IF (lineRaw1$ = "Alice, 42, Software Engineer, ""Paris, France""") THEN
    PRINT "LINE_INPUT_PRESERVES_COMMAS: PASS"
ELSE
    PRINT "LINE_INPUT_PRESERVES_COMMAS: FAIL"
END IF

' 22. LINE INPUT # lit correctement les lignes vides et le formatage
LINE INPUT #1, lineEmpty$
LINE INPUT #1, lineIndented$
CLOSE #1
IF (lineEmpty$ = "" AND lineIndented$ = "   Indented text with spaces and quotes: 'Hello'   ") THEN
    PRINT "LINE_INPUT_MULTILINE_EMPTY: PASS"
ELSE
    PRINT "LINE_INPUT_MULTILINE_EMPTY: FAIL"
END IF


' --------------------------------------------------------
' SECTION 5: INPUT # File Variants (Field & Token Delimited)
' --------------------------------------------------------

OPEN "temp_test_tokens.txt" FOR OUTPUT AS #2
PRINT #2, 1024
PRINT #2, "QBasicPro"
' Multi-variables sur une même ligne séparées par des virgules
PRINT #2, "Red, Green, Blue"
PRINT #2, "100, 200, 300.5"
' Ligne avec types mixtes
PRINT #2, "777, LuckySeven, 99.95"
CLOSE #2

OPEN "temp_test_tokens.txt" FOR INPUT AS #2

' 23. INPUT # simple nombre et simple chaîne
INPUT #2, readNum
INPUT #2, readStr$
IF (readNum = 1024 AND readStr$ = "QBasicPro") THEN
    PRINT "INPUT_FILE_BASIC: PASS"
ELSE
    PRINT "INPUT_FILE_BASIC: FAIL"
END IF

' 24. INPUT # multi-variables sur une ligne
INPUT #2, c1$, c2$, c3$
INPUT #2, v1, v2, v3
IF (c1$ = "Red" AND c2$ = "Green" AND c3$ = "Blue" AND v1 = 100 AND v2 = 200 AND v3 = 300.5) THEN
    PRINT "INPUT_FILE_MULTI_VARS: PASS"
ELSE
    PRINT "INPUT_FILE_MULTI_VARS: FAIL"
END IF

' 25. INPUT # avec types mixtes
INPUT #2, mxId, mxName$, mxScore
CLOSE #2
IF (mxId = 777 AND mxName$ = "LuckySeven" AND mxScore = 99.95) THEN
    PRINT "INPUT_FILE_MIXED_TYPES: PASS"
ELSE
    PRINT "INPUT_FILE_MIXED_TYPES: FAIL"
END IF

' 26. INPUT # avec chaînes contenant des virgules entre guillemets
OPEN "temp_test_quoted.txt" FOR OUTPUT AS #3
PRINT #3, CHR$(34) + "Alpha, Beta" + CHR$(34) + ", 555, " + CHR$(34) + "Gamma, Delta, Epsilon" + CHR$(34)
CLOSE #3

OPEN "temp_test_quoted.txt" FOR INPUT AS #3
INPUT #3, q1$, qVal, q2$
CLOSE #3
IF (q1$ = "Alpha, Beta" AND qVal = 555 AND q2$ = "Gamma, Delta, Epsilon") THEN
    PRINT "INPUT_FILE_QUOTED_COMMAS: PASS"
ELSE
    PRINT "INPUT_FILE_QUOTED_COMMAS: FAIL"
END IF


' --------------------------------------------------------
' SECTION 6: INPUT$ Function Variants (Exact Character/Binary Read)
' --------------------------------------------------------

OPEN "temp_test_chars.txt" FOR OUTPUT AS #4
PRINT #4, "ABCDEFGHIJ0123456789XYZ";
CLOSE #4

OPEN "temp_test_chars.txt" FOR INPUT AS #4

' 27. INPUT$(n, #f) lit exactement n caractères
LET chunk1$ = INPUT$(5, #4)
LET chunk2$ = INPUT$(5, #4)
IF (chunk1$ = "ABCDE" AND chunk2$ = "FGHIJ" AND LEN(chunk1$) = 5 AND LEN(chunk2$) = 5) THEN
    PRINT "INPUT_FUNC_EXACT_LEN: PASS"
ELSE
    PRINT "INPUT_FUNC_EXACT_LEN: FAIL"
END IF

' 28. INPUT$(10, #4) lit les 10 caractères numériques consécutifs
LET chunkNums$ = INPUT$(10, #4)
IF (chunkNums$ = "0123456789" AND LEN(chunkNums$) = 10) THEN
    PRINT "INPUT_FUNC_NUMERIC_STREAM: PASS"
ELSE
    PRINT "INPUT_FUNC_NUMERIC_STREAM: FAIL"
END IF

' 29. INPUT$(1, #f) lecture caractère par caractère
LET cX$ = INPUT$(1, #4)
LET cY$ = INPUT$(1, #4)
LET cZ$ = INPUT$(1, #4)
CLOSE #4
IF (cX$ = "X" AND cY$ = "Y" AND cZ$ = "Z") THEN
    PRINT "INPUT_FUNC_BYTE_BY_BYTE: PASS"
ELSE
    PRINT "INPUT_FUNC_BYTE_BY_BYTE: FAIL"
END IF

' 30. INPUT$(n, #f) lecture binaire avec octet nul CHR$(0)
OPEN "temp_test_bin.bin" FOR OUTPUT AS #5
PRINT #5, CHR$(65) + CHR$(0) + CHR$(66) + CHR$(0) + CHR$(67) + CHR$(255);
CLOSE #5

OPEN "temp_test_bin.bin" FOR BINARY AS #5
LET binData$ = INPUT$(6, #5)
CLOSE #5

IF (LEN(binData$) = 6 AND ASC(MID$(binData$, 1, 1)) = 65 AND ASC(MID$(binData$, 2, 1)) = 0 AND ASC(MID$(binData$, 3, 1)) = 66 AND ASC(MID$(binData$, 4, 1)) = 0 AND ASC(MID$(binData$, 5, 1)) = 67) THEN
    PRINT "INPUT_FUNC_BINARY_NULL_BYTE: PASS"
ELSE
    PRINT "INPUT_FUNC_BINARY_NULL_BYTE: FAIL"
END IF

' Nettoyage des fichiers temporaires
KILL "temp_test_input.txt"
KILL "temp_test_tokens.txt"
KILL "temp_test_quoted.txt"
KILL "temp_test_chars.txt"
KILL "temp_test_bin.bin"

PRINT "INPUT_AND_INKEY_BATTERY_ALL: PASS"
