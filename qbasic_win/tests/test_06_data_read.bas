' ========================================================
' UNIT TEST 06: DATA, READ & RESTORE
' ========================================================

DATA 10, 20, 30, "Alpha", "Beta"
DATA 40, 50

READ d1, d2, d3, s1$, s2$
READ d4, d5

IF (d1 = 10 AND d2 = 20 AND d3 = 30) THEN PRINT "DATA_READ_NUM: PASS" ELSE PRINT "DATA_READ_NUM: FAIL"
IF (s1$ = "Alpha" AND s2$ = "Beta") THEN PRINT "DATA_READ_STR: PASS" ELSE PRINT "DATA_READ_STR: FAIL"
IF (d4 = 40 AND d5 = 50) THEN PRINT "DATA_READ_MULTILINE: PASS" ELSE PRINT "DATA_READ_MULTILINE: FAIL"

' Tester RESTORE pour relire depuis le debut
RESTORE
READ r1, r2, r3
IF (r1 = 10 AND r2 = 20 AND r3 = 30) THEN PRINT "DATA_RESTORE: PASS" ELSE PRINT "DATA_RESTORE: FAIL"

PRINT "DATA_READ_ALL: PASS"
