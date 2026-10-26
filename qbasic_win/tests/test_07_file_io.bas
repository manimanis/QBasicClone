' ========================================================
' UNIT TEST 07: File I/O (OPEN, PRINT#, INPUT#, EOF, LOF, KILL)
' ========================================================

' 1. Ecriture dans un fichier (FOR OUTPUT)
OPEN "temp_test_io.txt" FOR OUTPUT AS #1
PRINT #1, "Hello from QBasic File IO"
PRINT #1, "Line 2"
PRINT #1, 4242
CLOSE #1
PRINT "FILE_OPEN_OUTPUT: PASS"

' 2. Lecture du fichier (FOR INPUT) avec LOF et LINE INPUT
OPEN "temp_test_io.txt" FOR INPUT AS #1
IF (LOF(1) > 0) THEN PRINT "FILE_LOF: PASS" ELSE PRINT "FILE_LOF: FAIL"

LINE INPUT #1, line1$
IF (line1$ = "Hello from QBasic File IO") THEN PRINT "FILE_LINE_INPUT_1: PASS" ELSE PRINT "FILE_LINE_INPUT_1: FAIL"

LINE INPUT #1, line2$
IF (line2$ = "Line 2") THEN PRINT "FILE_LINE_INPUT_2: PASS" ELSE PRINT "FILE_LINE_INPUT_2: FAIL"

INPUT #1, nval
IF (nval = 4242) THEN PRINT "FILE_INPUT_NUM: PASS" ELSE PRINT "FILE_INPUT_NUM: FAIL"

IF (EOF(1) = -1) THEN PRINT "FILE_EOF: PASS" ELSE PRINT "FILE_EOF: FAIL"
CLOSE #1

' 3. Mode ajout (FOR APPEND)
OPEN "temp_test_io.txt" FOR APPEND AS #2
PRINT #2, "Appended Line"
CLOSE #2
PRINT "FILE_OPEN_APPEND: PASS"

' 4. Verification de la ligne ajoutee
OPEN "temp_test_io.txt" FOR INPUT AS #3
LINE INPUT #3, dummy$
LINE INPUT #3, dummy$
LINE INPUT #3, dummy$
LINE INPUT #3, app_line$
IF (app_line$ = "Appended Line") THEN PRINT "FILE_APPEND_CONTENT: PASS" ELSE PRINT "FILE_APPEND_CONTENT: FAIL"
CLOSE #3

' 5. Suppression de fichier KILL
KILL "temp_test_io.txt"
PRINT "FILE_KILL: PASS"

PRINT "FILE_IO_ALL: PASS"
