' ========================================================
' UNIT TEST 05: Procedures (SUB, FUNCTION, DEF FN)
' ========================================================

DECLARE SUB AddOne (x)
DECLARE SUB TryModify (x)
DECLARE SUB EarlyExit (x, res)
DECLARE FUNCTION Factorial (n)
DECLARE FUNCTION AddTogether (a, b)

' 1. DEF FN (inline user function 1-param)
DEF FNDouble (x) = x * 2
DEF FNSqr (x) = x * x

IF (FNDouble(21) = 42) THEN PRINT "DEF_FN_1PARAM: PASS" ELSE PRINT "DEF_FN_1PARAM: FAIL"
IF (FNSqr(9) = 81) THEN PRINT "DEF_FN_SQR: PASS" ELSE PRINT "DEF_FN_SQR: FAIL"

' 2. Appel de FUNCTION standard
LET sum = AddTogether(100, 250)
IF (sum = 350) THEN PRINT "FUNCTION_CALL: PASS" ELSE PRINT "FUNCTION_CALL: FAIL"

' 3. Recursion FUNCTION
LET fact5 = Factorial(5)
IF (fact5 = 120) THEN PRINT "FUNCTION_RECURSION: PASS" ELSE PRINT "FUNCTION_RECURSION: FAIL"

' 4. SUB avec CALL et passage par reference
LET original = 10
CALL AddOne(original)
IF (original = 11) THEN PRINT "SUB_BY_REF: PASS" ELSE PRINT "SUB_BY_REF: FAIL"

' 5. SUB avec passage par valeur (parentheses forcant l'expression)
LET val_protected = 50
CALL TryModify((val_protected))
IF (val_protected = 50) THEN PRINT "SUB_BY_VAL: PASS" ELSE PRINT "SUB_BY_VAL: FAIL"

' 6. SUB avec EXIT SUB
LET exit_res = 0
CALL EarlyExit(1, exit_res)
IF (exit_res = 111) THEN PRINT "SUB_EXIT_SUB: PASS" ELSE PRINT "SUB_EXIT_SUB: FAIL"

PRINT "PROCEDURES_ALL: PASS"
SYSTEM

' Definitions des procedures ci-dessous
SUB AddOne (x)
    x = x + 1
END SUB

SUB TryModify (x)
    x = 999
END SUB

SUB EarlyExit (x, res)
    IF x = 1 THEN
        res = 111
        EXIT SUB
    END IF
    res = 222
END SUB

FUNCTION Factorial (n)
    IF n <= 1 THEN
        Factorial = 1
    ELSE
        Factorial = n * Factorial(n - 1)
    END IF
END FUNCTION

FUNCTION AddTogether (a, b)
    AddTogether = a + b
END FUNCTION
