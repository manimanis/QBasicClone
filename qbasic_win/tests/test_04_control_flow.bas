' ========================================================
' UNIT TEST 04: Control Flow & Branching
' ========================================================

' 1. Single-line IF/THEN/ELSE
LET if_single = 0
IF 10 > 5 THEN if_single = 1 ELSE if_single = 2
IF if_single = 1 THEN PRINT "IF_SINGLE_TRUE: PASS" ELSE PRINT "IF_SINGLE_TRUE: FAIL"

IF 5 > 10 THEN if_single = 1 ELSE if_single = 2
IF if_single = 2 THEN PRINT "IF_SINGLE_FALSE: PASS" ELSE PRINT "IF_SINGLE_FALSE: FAIL"

' 2. Multi-line Block IF / ELSEIF / ELSE / END IF
LET v = 20
LET res$ = "NONE"
IF v = 10 THEN
    res$ = "TEN"
ELSEIF v = 20 THEN
    res$ = "TWENTY"
ELSE
    res$ = "OTHER"
END IF
IF res$ = "TWENTY" THEN PRINT "IF_BLOCK_ELSEIF: PASS" ELSE PRINT "IF_BLOCK_ELSEIF: FAIL"

LET v = 99
IF v = 10 THEN
    res$ = "TEN"
ELSEIF v = 20 THEN
    res$ = "TWENTY"
ELSE
    res$ = "OTHER"
END IF
IF res$ = "OTHER" THEN PRINT "IF_BLOCK_ELSE: PASS" ELSE PRINT "IF_BLOCK_ELSE: FAIL"

' 3. FOR / NEXT avec STEP positif et negatif
LET sum = 0
FOR i = 1 TO 5
    sum = sum + i
NEXT i
IF sum = 15 THEN PRINT "FOR_NEXT_STEP1: PASS" ELSE PRINT "FOR_NEXT_STEP1: FAIL"

LET countdown = 0
FOR k = 10 TO 2 STEP -2
    countdown = countdown + 1
NEXT k
IF countdown = 5 THEN PRINT "FOR_NEXT_STEP_NEG: PASS" ELSE PRINT "FOR_NEXT_STEP_NEG: FAIL"

' 4. FOR avec EXIT FOR
LET exit_for_hits = 0
FOR m = 1 TO 10
    exit_for_hits = exit_for_hits + 1
    IF m = 3 THEN EXIT FOR
NEXT m
IF exit_for_hits = 3 THEN PRINT "FOR_EXIT_FOR: PASS" ELSE PRINT "FOR_EXIT_FOR: FAIL"

' 5. WHILE / WEND
LET w = 1
WHILE w < 8
    w = w * 2
WEND
IF w = 8 THEN PRINT "WHILE_WEND: PASS" ELSE PRINT "WHILE_WEND: FAIL"

' 6. DO / LOOP variantes
LET d1 = 0
DO WHILE d1 < 5
    d1 = d1 + 1
LOOP
IF d1 = 5 THEN PRINT "DO_WHILE_LOOP: PASS" ELSE PRINT "DO_WHILE_LOOP: FAIL"

LET d2 = 0
DO
    d2 = d2 + 1
LOOP WHILE d2 < 4
IF d2 = 4 THEN PRINT "DO_LOOP_WHILE: PASS" ELSE PRINT "DO_LOOP_WHILE: FAIL"

LET d3 = 0
DO UNTIL d3 >= 6
    d3 = d3 + 2
LOOP
IF d3 = 6 THEN PRINT "DO_UNTIL_LOOP: PASS" ELSE PRINT "DO_UNTIL_LOOP: FAIL"

LET d4 = 0
DO
    d4 = d4 + 1
    IF d4 = 3 THEN EXIT DO
LOOP
IF d4 = 3 THEN PRINT "DO_EXIT_DO: PASS" ELSE PRINT "DO_EXIT_DO: FAIL"

' 7. SELECT CASE
LET target_case = 7
LET matched$ = ""
SELECT CASE target_case
    CASE 1
        matched$ = "ONE"
    CASE 2 TO 5
        matched$ = "RANGE"
    CASE IS >= 6
        matched$ = "GREATER"
    CASE ELSE
        matched$ = "DEFAULT"
END SELECT
IF matched$ = "GREATER" THEN PRINT "SELECT_CASE_IS: PASS" ELSE PRINT "SELECT_CASE_IS: FAIL"

target_case = 3
SELECT CASE target_case
    CASE 1
        matched$ = "ONE"
    CASE 2 TO 5
        matched$ = "RANGE"
    CASE ELSE
        matched$ = "DEFAULT"
END SELECT
IF matched$ = "RANGE" THEN PRINT "SELECT_CASE_RANGE: PASS" ELSE PRINT "SELECT_CASE_RANGE: FAIL"

target_case = 100
SELECT CASE target_case
    CASE 1 TO 10
        matched$ = "LOW"
    CASE ELSE
        matched$ = "DEFAULT"
END SELECT
IF matched$ = "DEFAULT" THEN PRINT "SELECT_CASE_ELSE: PASS" ELSE PRINT "SELECT_CASE_ELSE: FAIL"

' 8. GOTO et GOSUB / RETURN
LET goto_flag = 0
GOTO SkipHere
goto_flag = 999
SkipHere:
goto_flag = 42
IF goto_flag = 42 THEN PRINT "GOTO_LABEL: PASS" ELSE PRINT "GOTO_LABEL: FAIL"

LET gosub_val = 10
GOSUB DoubleVal
IF gosub_val = 20 THEN PRINT "GOSUB_RETURN: PASS" ELSE PRINT "GOSUB_RETURN: FAIL"
GOTO DoneControlFlow

DoubleVal:
gosub_val = gosub_val * 2
RETURN

DoneControlFlow:
PRINT "CONTROL_FLOW_ALL: PASS"
