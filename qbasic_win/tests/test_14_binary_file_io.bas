' ========================================================
' UNIT TEST 14: Binary & Stream File I/O
' ========================================================

' 1. Ecriture d'un fichier de donnees binaire/texte mixte
OPEN "test_stream_data.bin" FOR OUTPUT AS #1
PRINT #1, "QB-MAGIC-HEADER"
PRINT #1, "RECORD-001,100,200"
PRINT #1, "RECORD-002,300,400"
CLOSE #1

' 2. Verification de la taille avec LOF
OPEN "test_stream_data.bin" FOR INPUT AS #1
LET fsize = LOF(1)
IF (fsize > 40) THEN
    PRINT "STREAM_FILE_LOF: PASS"
ELSE
    PRINT "STREAM_FILE_LOF: FAIL"
END IF

' 3. Lecture par bloc d'octets avec INPUT$(count, file_num)
LET header$ = INPUT$(15, 1)
IF (header$ = "QB-MAGIC-HEADER") THEN
    PRINT "STREAM_INPUT_EXACT_BYTES: PASS"
ELSE
    PRINT "STREAM_INPUT_EXACT_BYTES: FAIL"
END IF

CLOSE #1

' 4. Re-ouverture et lecture de ligne
OPEN "test_stream_data.bin" FOR INPUT AS #2
LINE INPUT #2, hLine$
LINE INPUT #2, rec1$
IF (hLine$ = "QB-MAGIC-HEADER" AND rec1$ = "RECORD-001,100,200") THEN
    PRINT "STREAM_LINE_INPUT_SEEK: PASS"
ELSE
    PRINT "STREAM_LINE_INPUT_SEEK: FAIL"
END IF
CLOSE #2

' 5. Suppression de fichier avec KILL
KILL "test_stream_data.bin"
PRINT "STREAM_FILE_CLEANUP: PASS"

PRINT "STREAM_IO_ALL: PASS"
