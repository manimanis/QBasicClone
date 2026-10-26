' ========================================================
' UNIT TEST 12: Deeply Nested Control Flow & Complex Types
' ========================================================

' 1. Triples boucles FOR imbriquees (calcul de somme cubique)
' sum_{i=1..3} sum_{j=1..3} sum_{k=1..3} (i * j * k) = (1+2+3)^3 = 216
LET cube_sum = 0
FOR i = 1 TO 3
    FOR j = 1 TO 3
        FOR k = 1 TO 3
            cube_sum = cube_sum + (i * j * k)
        NEXT k
    NEXT j
NEXT i

IF (cube_sum = 216) THEN PRINT "NESTED_FOR_3_LEVELS: PASS" ELSE PRINT "NESTED_FOR_3_LEVELS: FAIL"

' 2. SELECT CASE a l'interieur d'un DO ... LOOP avec conditions IF et EXIT DO
LET loop_counter = 0
LET total_score = 0
DO
    loop_counter = loop_counter + 1
    SELECT CASE loop_counter
        CASE 1
            total_score = total_score + 10
        CASE 2 TO 3
            total_score = total_score + 20
        CASE 4
            IF total_score = 50 THEN
                total_score = total_score + 100
                EXIT DO
            END IF
        CASE ELSE
            EXIT DO
    END SELECT
LOOP

IF (loop_counter = 4 AND total_score = 150) THEN
    PRINT "NESTED_DO_SELECT_IF: PASS"
ELSE
    PRINT "NESTED_DO_SELECT_IF: FAIL"
END IF

' 3. GOSUB appele a chaque iteration d'une boucle FOR
LET gosub_accum = 0
FOR step_i = 1 TO 5
    GOSUB AddSquare
NEXT step_i
' Somme des carres de 1 a 5 = 1 + 4 + 9 + 16 + 25 = 55
IF (gosub_accum = 55) THEN PRINT "NESTED_FOR_GOSUB: PASS" ELSE PRINT "NESTED_FOR_GOSUB: FAIL"
GOTO DoneNestedFlow

AddSquare:
gosub_accum = gosub_accum + (step_i * step_i)
RETURN

DoneNestedFlow:

' 4. Types composes et tableau de structures
TYPE Particle
    id AS INTEGER
    vx AS INTEGER
    vy AS INTEGER
    speed AS INTEGER
END TYPE

DIM partList(1 TO 3) AS Particle

partList(1).id = 101: partList(1).vx = 3: partList(1).vy = 4
partList(2).id = 102: partList(2).vx = 6: partList(2).vy = 8
partList(3).id = 103: partList(3).vx = 5: partList(3).vy = 12

' Calculer la vitesse euclidienne v = SQR(vx^2 + vy^2)
FOR pi = 1 TO 3
    partList(pi).speed = INT(SQR(partList(pi).vx ^ 2 + partList(pi).vy ^ 2))
NEXT pi

IF (partList(1).speed = 5 AND partList(2).speed = 10 AND partList(3).speed = 13) THEN
    PRINT "NESTED_TYPE_ARRAY_CALC: PASS"
ELSE
    PRINT "NESTED_TYPE_ARRAY_CALC: FAIL"
END IF

PRINT "NESTED_STRUCTURES_ALL: PASS"
