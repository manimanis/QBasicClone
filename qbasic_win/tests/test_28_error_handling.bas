' ========================================================
' UNIT TEST 28: Comprehensive Error Handling Battery
' (ON ERROR GOTO, RESUME, RESUME NEXT, RESUME label, ERR, ERL, ERROR)
' ========================================================

DECLARE SUB SubWithoutHandler ()
DECLARE SUB SubWithLocalHandler ()

' --------------------------------------------------------
' SECTION 1: Basic ON ERROR GOTO, ERROR Statement & RESUME NEXT
' --------------------------------------------------------
LET h1_called = 0
LET h1_err = 0
LET after_error = 0

ON ERROR GOTO BasicHandler
ERROR 55
after_error = 1
GOTO AfterBasicTest

BasicHandler:
    h1_called = h1_called + 1
    h1_err = ERR
    RESUME NEXT

AfterBasicTest:
IF (h1_called = 1 AND h1_err = 55 AND after_error = 1) THEN
    PRINT "ERR_BASIC_RESUME_NEXT: PASS"
ELSE
    PRINT "ERR_BASIC_RESUME_NEXT: FAIL"
END IF

' --------------------------------------------------------
' SECTION 2: ERL Line Number Inspection (Numbered & Unnumbered)
' --------------------------------------------------------
LET erl_val = -1
LET err_code = 0

ON ERROR GOTO ErlHandler
200 ERROR 77
GOTO AfterErlTest1

ErlHandler:
    err_code = ERR
    erl_val = ERL
    RESUME NEXT

AfterErlTest1:
IF (err_code = 77 AND erl_val = 200) THEN
    PRINT "ERR_ERL_NUMBERED_LINE: PASS"
ELSE
    PRINT "ERR_ERL_NUMBERED_LINE: FAIL"
END IF

LET erl_zero = -1
ON ERROR GOTO ErlZeroHandler
ERROR 88
GOTO AfterErlTest2

ErlZeroHandler:
    erl_zero = ERL
    RESUME NEXT

AfterErlTest2:
IF (erl_zero = 0) THEN
    PRINT "ERR_ERL_UNNUMBERED_ZERO: PASS"
ELSE
    PRINT "ERR_ERL_UNNUMBERED_ZERO: FAIL"
END IF

' --------------------------------------------------------
' SECTION 3: RESUME (Re-executing the Faulting Statement)
' --------------------------------------------------------
LET retry_count = 0
LET retry_flag = 0

ON ERROR GOTO RetryHandler
IF retry_flag = 0 THEN ERROR 12
GOTO AfterRetryTest

RetryHandler:
    retry_count = retry_count + 1
    retry_flag = 1
    RESUME

AfterRetryTest:
IF (retry_count = 1 AND retry_flag = 1) THEN
    PRINT "ERR_RESUME_RETRY: PASS"
ELSE
    PRINT "ERR_RESUME_RETRY: FAIL"
END IF

' --------------------------------------------------------
' SECTION 4: RESUME <label> (Branching to Recovery Point)
' --------------------------------------------------------
LET resume_label_ok = 0
LET skipped_code = 0

ON ERROR GOTO ResumeLabelHandler
ERROR 99
skipped_code = 1

ResumeLabelHandler:
    RESUME RecoveryTarget

RecoveryTarget:
IF (skipped_code = 0) THEN
    PRINT "ERR_RESUME_LABEL: PASS"
ELSE
    PRINT "ERR_RESUME_LABEL: FAIL"
END IF

' --------------------------------------------------------
' SECTION 5: Dynamic Handlers & ON ERROR GOTO 0
' --------------------------------------------------------
LET handler_choice = 0

ON ERROR GOTO HandlerOne
ERROR 101
GOTO CheckHandlerOne

HandlerOne:
    handler_choice = 1
    RESUME NEXT

CheckHandlerOne:
IF (handler_choice = 1) THEN
    PRINT "ERR_HANDLER_SWITCH_1: PASS"
ELSE
    PRINT "ERR_HANDLER_SWITCH_1: FAIL"
END IF

ON ERROR GOTO HandlerTwo
ERROR 102
GOTO CheckHandlerTwo

HandlerTwo:
    handler_choice = 2
    RESUME NEXT

CheckHandlerTwo:
IF (handler_choice = 2) THEN
    PRINT "ERR_HANDLER_SWITCH_2: PASS"
ELSE
    PRINT "ERR_HANDLER_SWITCH_2: FAIL"
END IF

LET h_zero_step = 0
ON ERROR GOTO HandlerDisabled
ON ERROR GOTO 0
ON ERROR GOTO HandlerReEnabled
ERROR 105
GOTO AfterReEnabled

HandlerDisabled:
    h_zero_step = 1
    RESUME NEXT

HandlerReEnabled:
    h_zero_step = 2
    RESUME NEXT

AfterReEnabled:
IF (h_zero_step = 2) THEN
    PRINT "ERR_HANDLER_GOTO_ZERO_RESET: PASS"
ELSE
    PRINT "ERR_HANDLER_GOTO_ZERO_RESET: FAIL"
END IF

' --------------------------------------------------------
' SECTION 6: Standard Runtime Errors (Division by Zero, File, Subscript)
' --------------------------------------------------------
LET div_err = 0
LET div_res = 0
ON ERROR GOTO DivZeroHandler
LET zero_val = 0
LET div_res = 100 / zero_val
GOTO AfterDivZero

DivZeroHandler:
    div_err = ERR
    RESUME NEXT

AfterDivZero:
IF (div_err = 11) THEN
    PRINT "ERR_RUNTIME_DIV_ZERO: PASS"
ELSE
    PRINT "ERR_RUNTIME_DIV_ZERO: FAIL"
END IF

LET file_err = 0
ON ERROR GOTO FileNotFoundHandler
OPEN "non_existent_file_error_test_999.xyz" FOR INPUT AS #50
CLOSE #50
GOTO AfterFileNotFound

FileNotFoundHandler:
    file_err = ERR
    RESUME NEXT

AfterFileNotFound:
IF (file_err = 53) THEN
    PRINT "ERR_RUNTIME_FILE_NOT_FOUND: PASS"
ELSE
    PRINT "ERR_RUNTIME_FILE_NOT_FOUND: FAIL"
END IF

LET sub_err = 0
DIM bounds_arr(5)
ON ERROR GOTO SubscriptHandler
LET bounds_arr(25) = 999
GOTO AfterSubscript

SubscriptHandler:
    sub_err = ERR
    RESUME NEXT

AfterSubscript:
IF (sub_err = 9) THEN
    PRINT "ERR_RUNTIME_SUBSCRIPT_OUT_OF_RANGE: PASS"
ELSE
    PRINT "ERR_RUNTIME_SUBSCRIPT_OUT_OF_RANGE: FAIL"
END IF

' --------------------------------------------------------
' SECTION 7: Loop Integrity with RESUME NEXT (FOR and WHILE)
' --------------------------------------------------------
LET loop_errors = 0
LET for_sum = 0
ON ERROR GOTO ForLoopErrHandler

FOR i = 1 TO 5
    IF i = 3 THEN ERROR 33 ELSE for_sum = for_sum + i
NEXT i
GOTO AfterForTest

ForLoopErrHandler:
    loop_errors = loop_errors + 1
    RESUME NEXT

AfterForTest:
IF (loop_errors = 1 AND for_sum = 12) THEN
    PRINT "ERR_LOOP_FOR_INTEGRITY: PASS"
ELSE
    PRINT "ERR_LOOP_FOR_INTEGRITY: FAIL"
END IF

LET while_errors = 0
LET while_sum = 0
LET w_idx = 0
ON ERROR GOTO WhileErrHandler

WHILE w_idx < 4
    w_idx = w_idx + 1
    IF w_idx = 2 THEN ERROR 44 ELSE while_sum = while_sum + w_idx
WEND
GOTO AfterWhileTest

WhileErrHandler:
    while_errors = while_errors + 1
    RESUME NEXT

AfterWhileTest:
IF (while_errors = 1 AND while_sum = 8) THEN
    PRINT "ERR_LOOP_WHILE_INTEGRITY: PASS"
ELSE
    PRINT "ERR_LOOP_WHILE_INTEGRITY: FAIL"
END IF

' --------------------------------------------------------
' SECTION 8: Multiple Consecutive Handled Errors
' --------------------------------------------------------
LET multi_count = 0
LET sum_err_codes = 0
ON ERROR GOTO MultiHandler

ERROR 10
ERROR 20
ERROR 30
GOTO AfterMulti

MultiHandler:
    multi_count = multi_count + 1
    sum_err_codes = sum_err_codes + ERR
    RESUME NEXT

AfterMulti:
IF (multi_count = 3 AND sum_err_codes = 60) THEN
    PRINT "ERR_MULTIPLE_CONSECUTIVE: PASS"
ELSE
    PRINT "ERR_MULTIPLE_CONSECUTIVE: FAIL"
END IF

' --------------------------------------------------------
' SECTION 9: Error Propagation across SUB Calls
' --------------------------------------------------------
LET caller_caught = 0
LET caller_err = 0

ON ERROR GOTO CallerHandler
CALL SubWithoutHandler
GOTO AfterSubCall

CallerHandler:
    caller_caught = 1
    caller_err = ERR
    RESUME NEXT

AfterSubCall:
IF (caller_caught = 1 AND caller_err = 66) THEN
    PRINT "ERR_PROPAGATE_FROM_SUB: PASS"
ELSE
    PRINT "ERR_PROPAGATE_FROM_SUB: FAIL"
END IF

LET sub_local_caught = 0
CALL SubWithLocalHandler
IF (sub_local_caught = 1) THEN
    PRINT "ERR_SUB_LOCAL_HANDLER: PASS"
ELSE
    PRINT "ERR_SUB_LOCAL_HANDLER: FAIL"
END IF

' --------------------------------------------------------
' SECTION 10: ERR Reset after RESUME
' --------------------------------------------------------
LET err_before = 0
LET err_after = -1

ON ERROR GOTO ErrResetHandler
ERROR 70
err_after = ERR
GOTO AfterResetCheck

ErrResetHandler:
    err_before = ERR
    RESUME NEXT

AfterResetCheck:
IF (err_before = 70 AND err_after = 0) THEN
    PRINT "ERR_RESET_AFTER_RESUME: PASS"
ELSE
    PRINT "ERR_RESET_AFTER_RESUME: FAIL"
END IF

END

SUB SubWithoutHandler
    ERROR 66
END SUB

SUB SubWithLocalHandler
    SHARED sub_local_caught
    ON ERROR GOTO LocalHandler
    ERROR 88
    EXIT SUB

LocalHandler:
    IF ERR = 88 THEN sub_local_caught = 1
    RESUME NEXT
END SUB
