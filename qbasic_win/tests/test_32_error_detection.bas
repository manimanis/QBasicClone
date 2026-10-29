' ========================================================
' UNIT TEST 32: Official QBasic Error Detection & Diagnostics Battery
' Complete verification of all 54 Microsoft QBasic standard error codes (1-76)
' ========================================================

DIM caught_err AS INTEGER
DIM caught_erl AS INTEGER
DIM caught_cnt AS INTEGER

caught_err = 0
caught_erl = 0
caught_cnt = 0

ON ERROR GOTO TestErrorHandler

' --------------------------------------------------------
' SECTION 1: Official Error Message Mapping Verification (54 Codes)
' --------------------------------------------------------
SUB CheckMsg (code AS INTEGER, expected$)
    DIM actual$
    actual$ = _ERRORMESSAGE$(code)
    IF actual$ = expected$ THEN
        PRINT "ERR_MSG_" + LTRIM$(STR$(code)) + ": PASS"
    ELSE
        PRINT "ERR_MSG_" + LTRIM$(STR$(code)) + ": FAIL (Got: " + actual$ + ", Expected: " + expected$ + ")"
    END IF
END SUB

CheckMsg 1, "NEXT without FOR"
CheckMsg 2, "Syntax error"
CheckMsg 3, "RETURN without GOSUB"
CheckMsg 4, "Out of DATA"
CheckMsg 5, "Illegal function call"
CheckMsg 6, "Overflow"
CheckMsg 7, "Out of memory"
CheckMsg 8, "Label not defined"
CheckMsg 9, "Subscript out of range"
CheckMsg 10, "Duplicate definition"
CheckMsg 11, "Division by zero"
CheckMsg 12, "Illegal in direct mode"
CheckMsg 13, "Type mismatch"
CheckMsg 14, "Out of string space"
CheckMsg 16, "String formula too complex"
CheckMsg 17, "Cannot continue"
CheckMsg 18, "Function not defined"
CheckMsg 19, "No RESUME"
CheckMsg 20, "RESUME without error"
CheckMsg 24, "Device timeout"
CheckMsg 25, "Device fault"
CheckMsg 26, "FOR without NEXT"
CheckMsg 27, "Out of paper"
CheckMsg 29, "WHILE without WEND"
CheckMsg 30, "WEND without WHILE"
CheckMsg 33, "Duplicate label"
CheckMsg 35, "Subprogram not defined"
CheckMsg 37, "Argument-count mismatch"
CheckMsg 38, "Array not defined"
CheckMsg 40, "Variable required"
CheckMsg 50, "FIELD overflow"
CheckMsg 51, "Internal error"
CheckMsg 52, "Bad file name or number"
CheckMsg 53, "File not found"
CheckMsg 54, "Bad file mode"
CheckMsg 55, "File already open"
CheckMsg 56, "FIELD statement active"
CheckMsg 57, "Device I/O error"
CheckMsg 58, "File already exists"
CheckMsg 59, "Bad record length"
CheckMsg 61, "Disk full"
CheckMsg 62, "Input past end of file"
CheckMsg 63, "Bad record number"
CheckMsg 64, "Bad file name"
CheckMsg 67, "Too many files"
CheckMsg 68, "Device unavailable"
CheckMsg 69, "Communication-buffer overflow"
CheckMsg 70, "Permission denied"
CheckMsg 71, "Disk not ready"
CheckMsg 72, "Disk-media error"
CheckMsg 73, "Feature unavailable"
CheckMsg 74, "Rename across disks"
CheckMsg 75, "Path/File access error"
CheckMsg 76, "Path not found"

' --------------------------------------------------------
' SECTION 2: Direct Runtime Triggers and Error Handler Traps
' --------------------------------------------------------

' Test R1: Error 5 (Illegal function call - SQR negative)
caught_err = 0
x# = SQR(-16)
IF caught_err = 5 THEN
    PRINT "ERR_RUN_ILLEGAL_FUNC_SQR: PASS"
ELSE
    PRINT "ERR_RUN_ILLEGAL_FUNC_SQR: FAIL"
END IF

' Test R2: Error 5 (Illegal function call - LOG negative/zero)
caught_err = 0
x# = LOG(0)
IF caught_err = 5 THEN
    PRINT "ERR_RUN_ILLEGAL_FUNC_LOG: PASS"
ELSE
    PRINT "ERR_RUN_ILLEGAL_FUNC_LOG: FAIL"
END IF

' Test R3: Error 5 (Illegal function call - CHR$ negative)
caught_err = 0
s$ = CHR$(-5)
IF caught_err = 5 THEN
    PRINT "ERR_RUN_ILLEGAL_FUNC_CHR: PASS"
ELSE
    PRINT "ERR_RUN_ILLEGAL_FUNC_CHR: FAIL"
END IF

' Test R4: Error 5 (Illegal function call - ASC empty string)
caught_err = 0
n% = ASC("")
IF caught_err = 5 THEN
    PRINT "ERR_RUN_ILLEGAL_FUNC_ASC: PASS"
ELSE
    PRINT "ERR_RUN_ILLEGAL_FUNC_ASC: FAIL"
END IF

' Test R5: Error 11 (Division by zero)
caught_err = 0
x# = 100 / 0
IF caught_err = 11 THEN
    PRINT "ERR_RUN_DIV_ZERO_SLASH: PASS"
ELSE
    PRINT "ERR_RUN_DIV_ZERO_SLASH: FAIL"
END IF

' Test R6: Error 11 (Integer division by zero)
caught_err = 0
x% = 100 \ 0
IF caught_err = 11 THEN
    PRINT "ERR_RUN_DIV_ZERO_BACKSLASH: PASS"
ELSE
    PRINT "ERR_RUN_DIV_ZERO_BACKSLASH: FAIL"
END IF

' Test R7: Error 11 (Modulo by zero)
caught_err = 0
x% = 100 MOD 0
IF caught_err = 11 THEN
    PRINT "ERR_RUN_DIV_ZERO_MOD: PASS"
ELSE
    PRINT "ERR_RUN_DIV_ZERO_MOD: FAIL"
END IF

' Test R8: Error 9 (Subscript out of range on assignment)
caught_err = 0
DIM test_bounds_arr(5) AS INTEGER
test_bounds_arr(999) = 42
IF caught_err = 9 THEN
    PRINT "ERR_RUN_SUBSCRIPT_OUT_OF_RANGE: PASS"
ELSE
    PRINT "ERR_RUN_SUBSCRIPT_OUT_OF_RANGE: FAIL"
END IF

' Test R9: Error 10 (Duplicate definition of array at module level)
caught_err = 0
DIM dup_test_arr(5) AS INTEGER
DIM dup_test_arr(10) AS INTEGER
IF caught_err = 10 THEN
    PRINT "ERR_RUN_DUPLICATE_DEFINITION: PASS"
ELSE
    PRINT "ERR_RUN_DUPLICATE_DEFINITION: FAIL"
END IF

' Test R10: Error 13 (Type mismatch on variable assignment)
caught_err = 0
num_var% = "this_is_a_string"
IF caught_err = 13 THEN
    PRINT "ERR_RUN_TYPE_MISMATCH: PASS"
ELSE
    PRINT "ERR_RUN_TYPE_MISMATCH: FAIL"
END IF

' Test R11: Error 38 (Array not defined on ERASE)
caught_err = 0
ERASE NonExistentDynamicArr
IF caught_err = 38 THEN
    PRINT "ERR_RUN_ARRAY_NOT_DEFINED: PASS"
ELSE
    PRINT "ERR_RUN_ARRAY_NOT_DEFINED: FAIL"
END IF

' Test R12: Error 52 (Bad file name or number)
caught_err = 0
PRINT #99, "hello bad file"
IF caught_err = 52 THEN
    PRINT "ERR_RUN_BAD_FILE_NUMBER: PASS"
ELSE
    PRINT "ERR_RUN_BAD_FILE_NUMBER: FAIL"
END IF

' Test R13: Error 53 (File not found on OPEN INPUT)
caught_err = 0
OPEN "non_existent_qb_file_987654.xyz" FOR INPUT AS #1
IF caught_err = 53 THEN
    PRINT "ERR_RUN_FILE_NOT_FOUND: PASS"
ELSE
    PRINT "ERR_RUN_FILE_NOT_FOUND: FAIL"
END IF

' Test R14: Error 54 (Bad file mode - writing to an input file)
OPEN "test_err_mode.tmp" FOR OUTPUT AS #1
PRINT #1, "line 1"
CLOSE #1

caught_err = 0
OPEN "test_err_mode.tmp" FOR INPUT AS #1
PRINT #1, "illegal write to input file"
CLOSE #1
IF caught_err = 54 THEN
    PRINT "ERR_RUN_BAD_FILE_MODE: PASS"
ELSE
    PRINT "ERR_RUN_BAD_FILE_MODE: FAIL"
END IF

' Test R15: Error 55 (File already open)
caught_err = 0
OPEN "test_err_mode.tmp" FOR OUTPUT AS #2
OPEN "test_err_mode.tmp" FOR OUTPUT AS #2
CLOSE #2
IF caught_err = 55 THEN
    PRINT "ERR_RUN_FILE_ALREADY_OPEN: PASS"
ELSE
    PRINT "ERR_RUN_FILE_ALREADY_OPEN: FAIL"
END IF
KILL "test_err_mode.tmp"

' Test R16: Error 59 (Bad record length on RANDOM file)
caught_err = 0
OPEN "test_err_rec.tmp" FOR RANDOM AS #3 LEN = 0
IF caught_err = 59 THEN
    PRINT "ERR_RUN_BAD_RECORD_LENGTH: PASS"
ELSE
    PRINT "ERR_RUN_BAD_RECORD_LENGTH: FAIL"
END IF

' Test R17: Error 63 (Bad record number on GET)
OPEN "test_err_rec.tmp" FOR RANDOM AS #3 LEN = 64
caught_err = 0
GET #3, 0
CLOSE #3
IF caught_err = 63 THEN
    PRINT "ERR_RUN_BAD_RECORD_NUMBER: PASS"
ELSE
    PRINT "ERR_RUN_BAD_RECORD_NUMBER: FAIL"
END IF
KILL "test_err_rec.tmp"

' Test R18: Error 76 (Path not found on CHDIR)
caught_err = 0
CHDIR "Z:\nonexistent_qb_directory_12345"
IF caught_err = 76 THEN
    PRINT "ERR_RUN_PATH_NOT_FOUND: PASS"
ELSE
    PRINT "ERR_RUN_PATH_NOT_FOUND: FAIL"
END IF

' Test R19: Error 4 (Out of DATA)
caught_err = 0
READ dummy_var$
IF caught_err = 4 THEN
    PRINT "ERR_RUN_OUT_OF_DATA: PASS"
ELSE
    PRINT "ERR_RUN_OUT_OF_DATA: FAIL"
END IF

' Test R20: Error 3 (RETURN without GOSUB)
caught_err = 0
RETURN
IF caught_err = 3 THEN
    PRINT "ERR_RUN_RETURN_WITHOUT_GOSUB: PASS"
ELSE
    PRINT "ERR_RUN_RETURN_WITHOUT_GOSUB: FAIL"
END IF

' Test R21: Error 30 (WEND without WHILE)
caught_err = 0
WEND
IF caught_err = 30 THEN
    PRINT "ERR_RUN_WEND_WITHOUT_WHILE: PASS"
ELSE
    PRINT "ERR_RUN_WEND_WITHOUT_WHILE: FAIL"
END IF

' Test R22: Error 18 (Function not defined for FN call)
caught_err = 0
res_fn = FNUndefinedCustomFunction(10)
IF caught_err = 18 THEN
    PRINT "ERR_RUN_FUNCTION_NOT_DEFINED: PASS"
ELSE
    PRINT "ERR_RUN_FUNCTION_NOT_DEFINED: FAIL"
END IF

' --------------------------------------------------------
' SECTION 3: Trapping all remaining error codes via ERROR statement at module level
' --------------------------------------------------------

caught_err = 0: ERROR 1: IF caught_err = 1 THEN PRINT "ERR_STMT_CODE_1: PASS" ELSE PRINT "ERR_STMT_CODE_1: FAIL"
caught_err = 0: ERROR 2: IF caught_err = 2 THEN PRINT "ERR_STMT_CODE_2: PASS" ELSE PRINT "ERR_STMT_CODE_2: FAIL"
caught_err = 0: ERROR 6: IF caught_err = 6 THEN PRINT "ERR_STMT_CODE_6: PASS" ELSE PRINT "ERR_STMT_CODE_6: FAIL"
caught_err = 0: ERROR 7: IF caught_err = 7 THEN PRINT "ERR_STMT_CODE_7: PASS" ELSE PRINT "ERR_STMT_CODE_7: FAIL"
caught_err = 0: ERROR 8: IF caught_err = 8 THEN PRINT "ERR_STMT_CODE_8: PASS" ELSE PRINT "ERR_STMT_CODE_8: FAIL"
caught_err = 0: ERROR 12: IF caught_err = 12 THEN PRINT "ERR_STMT_CODE_12: PASS" ELSE PRINT "ERR_STMT_CODE_12: FAIL"
caught_err = 0: ERROR 14: IF caught_err = 14 THEN PRINT "ERR_STMT_CODE_14: PASS" ELSE PRINT "ERR_STMT_CODE_14: FAIL"
caught_err = 0: ERROR 16: IF caught_err = 16 THEN PRINT "ERR_STMT_CODE_16: PASS" ELSE PRINT "ERR_STMT_CODE_16: FAIL"
caught_err = 0: ERROR 17: IF caught_err = 17 THEN PRINT "ERR_STMT_CODE_17: PASS" ELSE PRINT "ERR_STMT_CODE_17: FAIL"
caught_err = 0: ERROR 19: IF caught_err = 19 THEN PRINT "ERR_STMT_CODE_19: PASS" ELSE PRINT "ERR_STMT_CODE_19: FAIL"
caught_err = 0: ERROR 20: IF caught_err = 20 THEN PRINT "ERR_STMT_CODE_20: PASS" ELSE PRINT "ERR_STMT_CODE_20: FAIL"
caught_err = 0: ERROR 24: IF caught_err = 24 THEN PRINT "ERR_STMT_CODE_24: PASS" ELSE PRINT "ERR_STMT_CODE_24: FAIL"
caught_err = 0: ERROR 25: IF caught_err = 25 THEN PRINT "ERR_STMT_CODE_25: PASS" ELSE PRINT "ERR_STMT_CODE_25: FAIL"
caught_err = 0: ERROR 26: IF caught_err = 26 THEN PRINT "ERR_STMT_CODE_26: PASS" ELSE PRINT "ERR_STMT_CODE_26: FAIL"
caught_err = 0: ERROR 27: IF caught_err = 27 THEN PRINT "ERR_STMT_CODE_27: PASS" ELSE PRINT "ERR_STMT_CODE_27: FAIL"
caught_err = 0: ERROR 29: IF caught_err = 29 THEN PRINT "ERR_STMT_CODE_29: PASS" ELSE PRINT "ERR_STMT_CODE_29: FAIL"
caught_err = 0: ERROR 33: IF caught_err = 33 THEN PRINT "ERR_STMT_CODE_33: PASS" ELSE PRINT "ERR_STMT_CODE_33: FAIL"
caught_err = 0: ERROR 35: IF caught_err = 35 THEN PRINT "ERR_STMT_CODE_35: PASS" ELSE PRINT "ERR_STMT_CODE_35: FAIL"
caught_err = 0: ERROR 37: IF caught_err = 37 THEN PRINT "ERR_STMT_CODE_37: PASS" ELSE PRINT "ERR_STMT_CODE_37: FAIL"
caught_err = 0: ERROR 40: IF caught_err = 40 THEN PRINT "ERR_STMT_CODE_40: PASS" ELSE PRINT "ERR_STMT_CODE_40: FAIL"
caught_err = 0: ERROR 50: IF caught_err = 50 THEN PRINT "ERR_STMT_CODE_50: PASS" ELSE PRINT "ERR_STMT_CODE_50: FAIL"
caught_err = 0: ERROR 51: IF caught_err = 51 THEN PRINT "ERR_STMT_CODE_51: PASS" ELSE PRINT "ERR_STMT_CODE_51: FAIL"
caught_err = 0: ERROR 56: IF caught_err = 56 THEN PRINT "ERR_STMT_CODE_56: PASS" ELSE PRINT "ERR_STMT_CODE_56: FAIL"
caught_err = 0: ERROR 57: IF caught_err = 57 THEN PRINT "ERR_STMT_CODE_57: PASS" ELSE PRINT "ERR_STMT_CODE_57: FAIL"
caught_err = 0: ERROR 58: IF caught_err = 58 THEN PRINT "ERR_STMT_CODE_58: PASS" ELSE PRINT "ERR_STMT_CODE_58: FAIL"
caught_err = 0: ERROR 61: IF caught_err = 61 THEN PRINT "ERR_STMT_CODE_61: PASS" ELSE PRINT "ERR_STMT_CODE_61: FAIL"
caught_err = 0: ERROR 62: IF caught_err = 62 THEN PRINT "ERR_STMT_CODE_62: PASS" ELSE PRINT "ERR_STMT_CODE_62: FAIL"
caught_err = 0: ERROR 64: IF caught_err = 64 THEN PRINT "ERR_STMT_CODE_64: PASS" ELSE PRINT "ERR_STMT_CODE_64: FAIL"
caught_err = 0: ERROR 67: IF caught_err = 67 THEN PRINT "ERR_STMT_CODE_67: PASS" ELSE PRINT "ERR_STMT_CODE_67: FAIL"
caught_err = 0: ERROR 68: IF caught_err = 68 THEN PRINT "ERR_STMT_CODE_68: PASS" ELSE PRINT "ERR_STMT_CODE_68: FAIL"
caught_err = 0: ERROR 69: IF caught_err = 69 THEN PRINT "ERR_STMT_CODE_69: PASS" ELSE PRINT "ERR_STMT_CODE_69: FAIL"
caught_err = 0: ERROR 70: IF caught_err = 70 THEN PRINT "ERR_STMT_CODE_70: PASS" ELSE PRINT "ERR_STMT_CODE_70: FAIL"
caught_err = 0: ERROR 71: IF caught_err = 71 THEN PRINT "ERR_STMT_CODE_71: PASS" ELSE PRINT "ERR_STMT_CODE_71: FAIL"
caught_err = 0: ERROR 72: IF caught_err = 72 THEN PRINT "ERR_STMT_CODE_72: PASS" ELSE PRINT "ERR_STMT_CODE_72: FAIL"
caught_err = 0: ERROR 73: IF caught_err = 73 THEN PRINT "ERR_STMT_CODE_73: PASS" ELSE PRINT "ERR_STMT_CODE_73: FAIL"
caught_err = 0: ERROR 74: IF caught_err = 74 THEN PRINT "ERR_STMT_CODE_74: PASS" ELSE PRINT "ERR_STMT_CODE_74: FAIL"
caught_err = 0: ERROR 75: IF caught_err = 75 THEN PRINT "ERR_STMT_CODE_75: PASS" ELSE PRINT "ERR_STMT_CODE_75: FAIL"

END

' ========================================================
' Global Error Handler Routine
' ========================================================
TestErrorHandler:
    caught_err = ERR
    caught_erl = ERL
    caught_cnt = caught_cnt + 1
    RESUME NEXT
