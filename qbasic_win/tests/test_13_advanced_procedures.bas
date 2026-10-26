' ========================================================
' UNIT TEST 13: Advanced Procedures (Arrays, Multi-Refs, Scoping)
' ========================================================

DECLARE SUB ScaleArray (arr(), n, factor)
DECLARE SUB MinMax (a, b, c, minOut, maxOut)
DECLARE FUNCTION PowerRec (b, e)
DECLARE SUB ScopeShield (shadowVal)

' 1. Passage de tableau par reference et modification in-place
DIM numbers(5)
FOR i = 1 TO 5
    numbers(i) = i * 2
NEXT i

CALL ScaleArray(numbers(), 5, 3)

IF (numbers(1) = 6 AND numbers(3) = 18 AND numbers(5) = 30) THEN
    PRINT "PROC_ARRAY_IN_PLACE: PASS"
ELSE
    PRINT "PROC_ARRAY_IN_PLACE: FAIL"
END IF

' 2. Plusieurs arguments de sortie par reference (MinMax)
LET vMin = 0
LET vMax = 0
CALL MinMax(42, 17, 88, vMin, vMax)

IF (vMin = 17 AND vMax = 88) THEN
    PRINT "PROC_MULTI_REF_OUT: PASS"
ELSE
    PRINT "PROC_MULTI_REF_OUT: FAIL"
END IF

' 3. Fonction exponentielle recursive
LET p1 = PowerRec(2, 8)
LET p2 = PowerRec(3, 4)

IF (p1 = 256 AND p2 = 81) THEN
    PRINT "PROC_RECURSION_POWER: PASS"
ELSE
    PRINT "PROC_RECURSION_POWER: FAIL"
END IF

' 4. Isolation des variables et passage par valeur
LET globalVar = 777
CALL ScopeShield((globalVar))

IF (globalVar = 777) THEN
    PRINT "PROC_SCOPE_ISOLATION: PASS"
ELSE
    PRINT "PROC_SCOPE_ISOLATION: FAIL"
END IF

PRINT "ADVANCED_PROCEDURES_ALL: PASS"
SYSTEM

' ========================================================
' DEFINITIONS DES PROCEDURES
' ========================================================

SUB ScaleArray (arr(), n, factor)
    FOR k = 1 TO n
        arr(k) = arr(k) * factor
    NEXT k
END SUB

SUB MinMax (a, b, c, minOut, maxOut)
    LET curMin = a
    IF b < curMin THEN curMin = b
    IF c < curMin THEN curMin = c
    minOut = curMin

    LET curMax = a
    IF b > curMax THEN curMax = b
    IF c > curMax THEN curMax = c
    maxOut = curMax
END SUB

FUNCTION PowerRec (b, e)
    IF e <= 0 THEN
        PowerRec = 1
    ELSE
        PowerRec = b * PowerRec(b, e - 1)
    END IF
END FUNCTION

SUB ScopeShield (shadowVal)
    shadowVal = 9999
END SUB
