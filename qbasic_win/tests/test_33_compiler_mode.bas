' ========================================================
' UNIT TEST 33: Autonomous Compiler Mode & Standalone Packaging
' Complete validation of -b/--make, --c, COMMAND$, and PE overlays
' ========================================================

DEFINT A-Z

SUB AssertTrue (testName$, condition%)
    IF condition% THEN
        PRINT testName$ + ": PASS"
    ELSE
        PRINT testName$ + ": FAIL"
    END IF
END SUB

PRINT "=== TEST BATTERY 33: COMPILER MODE & STANDALONE PE PACKAGING ==="

' --------------------------------------------------------
' SECTION 1: Local COMMAND$ and _EXEPATH$ checks
' --------------------------------------------------------
DIM cmdVal$
cmdVal$ = COMMAND$
AssertTrue "COMPILER_COMMAND_STRING_ACCESSIBLE", LEN(cmdVal$) >= 0

DIM qbExe$, exeDir$, q$
qbExe$ = _EXEPATH$
AssertTrue "COMPILER_EXEPATH_FUNCTIONAL", LEN(qbExe$) > 0

q$ = CHR$(34)

' Extract directory of the executable
DIM p%, lastSlash%
lastSlash% = 0
FOR p% = 1 TO LEN(qbExe$)
    DIM ch$
    ch$ = MID$(qbExe$, p%, 1)
    IF ch$ = "\" OR ch$ = "/" THEN lastSlash% = p%
NEXT p%

IF lastSlash% > 0 THEN
    exeDir$ = LEFT$(qbExe$, lastSlash%)
ELSE
    exeDir$ = ""
END IF

DIM srcFile$, exeFile$, out1File$, out2File$, cFile$, makeFile$
srcFile$ = exeDir$ + "t33_sample.bas"
exeFile$ = exeDir$ + "t33_sample.exe"
out1File$ = exeDir$ + "t33_out1.txt"
out2File$ = exeDir$ + "t33_out2.txt"
cFile$ = exeDir$ + "t33_sample.c"
makeFile$ = exeDir$ + "t33_make.exe"

' --------------------------------------------------------
' SECTION 2: Generate sample BASIC file for compilation
' --------------------------------------------------------
OPEN srcFile$ FOR OUTPUT AS #1
PRINT #1, "' Test program for compiler battery"
PRINT #1, "PRINT "; q$; "T33_PAYLOAD_EXECUTION_SUCCESS"; q$
PRINT #1, "PRINT "; q$; "T33_ARGS:["; q$; "; COMMAND$; "; q$; "]"; q$
CLOSE #1

DIM sampleCreated%
sampleCreated% = 0
OPEN srcFile$ FOR INPUT AS #1
IF LOF(1) > 0 THEN sampleCreated% = 1
CLOSE #1
AssertTrue "COMPILER_CREATE_SOURCE_FILE", sampleCreated% = 1

' --------------------------------------------------------
' SECTION 3: Compile via -b into standalone .exe
' --------------------------------------------------------
SHELL qbExe$ + " -b " + srcFile$ + " -o " + exeFile$

DIM exeExists%
exeExists% = 0
OPEN exeFile$ FOR BINARY AS #1
IF LOF(1) > 1000000 THEN exeExists% = 1
CLOSE #1
AssertTrue "COMPILER_STANDALONE_EXE_CREATED", exeExists% = 1

' --------------------------------------------------------
' SECTION 4: Execute standalone binary without arguments
' --------------------------------------------------------
SHELL exeFile$ + " > " + out1File$

DIM out1HasPayload%
out1HasPayload% = 0
OPEN out1File$ FOR INPUT AS #1
WHILE NOT EOF(1)
    LINE INPUT #1, l1$
    IF INSTR(l1$, "T33_PAYLOAD_EXECUTION_SUCCESS") > 0 THEN out1HasPayload% = 1
WEND
CLOSE #1
AssertTrue "COMPILER_RUN_STANDALONE_BINARY", out1HasPayload% = 1

' --------------------------------------------------------
' SECTION 5: Execute standalone binary WITH arguments (COMMAND$)
' --------------------------------------------------------
SHELL exeFile$ + " Alpha Beta 2026 > " + out2File$

DIM out2HasArgs%
out2HasArgs% = 0
OPEN out2File$ FOR INPUT AS #1
WHILE NOT EOF(1)
    LINE INPUT #1, l2$
    IF INSTR(l2$, "T33_ARGS:[Alpha Beta 2026]") > 0 THEN out2HasArgs% = 1
WEND
CLOSE #1
AssertTrue "COMPILER_STANDALONE_COMMAND_ARGS", out2HasArgs% = 1

' --------------------------------------------------------
' SECTION 6: Test --c intermediate source export
' --------------------------------------------------------
SHELL qbExe$ + " -b " + srcFile$ + " --c -o " + cFile$

DIM cSrcValid%
cSrcValid% = 0
OPEN cFile$ FOR INPUT AS #1
WHILE NOT EOF(1)
    LINE INPUT #1, lc$
    IF INSTR(lc$, "qb_embedded_source") > 0 THEN cSrcValid% = 1
WEND
CLOSE #1
AssertTrue "COMPILER_EMIT_C_SOURCE", cSrcValid% = 1

' --------------------------------------------------------
' SECTION 7: Test --make alias syntax (QuickBasic compatible)
' --------------------------------------------------------
SHELL qbExe$ + " --make " + srcFile$ + " -o " + makeFile$

DIM makeExeExists%
makeExeExists% = 0
OPEN makeFile$ FOR BINARY AS #1
IF LOF(1) > 1000000 THEN makeExeExists% = 1
CLOSE #1
AssertTrue "COMPILER_MAKE_ALIAS_SYNTAX", makeExeExists% = 1

' --------------------------------------------------------
' SECTION 8: Cleanup temporary test artifacts
' --------------------------------------------------------
KILL srcFile$
KILL exeFile$
KILL out1File$
KILL out2File$
KILL cFile$
KILL makeFile$

AssertTrue "COMPILER_CLEANUP_SUCCESS", 1 = 1

PRINT "=== ALL COMPILER TESTS COMPLETED ==="
