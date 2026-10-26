' ========================================================
' UNIT TEST 30: Advanced File I/O, Random Access & File System
' (RANDOM, BINARY, FIELD, LSET, RSET, GET#, PUT#, MKI$, CVI, MKL$, CVL, MKS$, CVS, MKD$, CVD, SEEK, LOC, LOF, FREEFILE, NAME, KILL, MKDIR, RMDIR)
' ========================================================

' --------------------------------------------------------
' SECTION 1: Binary Type Conversion Functions (MKI$, CVI, MKL$, CVL, MKS$, CVS, MKD$, CVD)
' --------------------------------------------------------
LET i1 = -1234
LET s_i1$ = MKI$(i1)
LET i1_back = CVI(s_i1$)

LET l1 = 123456789
LET s_l1$ = MKL$(l1)
LET l1_back = CVL(s_l1$)

LET f1 = 3.1415
LET s_f1$ = MKS$(f1)
LET f1_back = CVS(s_f1$)

LET d1 = 123456789.987654
LET s_d1$ = MKD$(d1)
LET d1_back = CVD(s_d1$)

IF (i1_back = -1234 AND l1_back = 123456789) THEN
    PRINT "FILE_CONV_INT_LONG: PASS"
ELSE
    PRINT "FILE_CONV_INT_LONG: FAIL"
END IF

IF (ABS(f1_back - 3.1415) < 0.0001 AND ABS(d1_back - 123456789.987654) < 0.00001) THEN
    PRINT "FILE_CONV_FLOAT_DOUBLE: PASS"
ELSE
    PRINT "FILE_CONV_FLOAT_DOUBLE: FAIL"
END IF

' --------------------------------------------------------
' SECTION 2: LSET and RSET Formatting
' --------------------------------------------------------
LET str_left$ = SPACE$(10)
LSET str_left$ = "ABC"

LET str_right$ = SPACE$(10)
RSET str_right$ = "XYZ"

LET str_trunc$ = SPACE$(4)
LSET str_trunc$ = "TOOLONG"

IF (str_left$ = "ABC       " AND str_right$ = "       XYZ" AND str_trunc$ = "TOOL") THEN
    PRINT "FILE_LSET_RSET: PASS"
ELSE
    PRINT "FILE_LSET_RSET: FAIL"
END IF

' --------------------------------------------------------
' SECTION 3: Random Access with FIELD, LSET/RSET, GET and PUT
' --------------------------------------------------------
OPEN "test_rnd_field.dat" FOR RANDOM AS #1 LEN = 32
FIELD #1, 10 AS f_nom$, 4 AS f_code$, 18 AS f_desc$

' Ecriture enregistrement 1
LSET f_nom$ = "ALICE"
LSET f_code$ = MKI$(42)
RSET f_desc$ = "ADMIN"
PUT #1, 1

' Ecriture enregistrement 2
LSET f_nom$ = "BOB"
LSET f_code$ = MKI$(99)
LSET f_desc$ = "GUEST"
PUT #1, 2

LET lof_val = LOF(1)
LET loc_val = LOC(1)
CLOSE #1

IF (lof_val = 64 AND loc_val = 2) THEN
    PRINT "FILE_RANDOM_PUT_LOC_LOF: PASS"
ELSE
    PRINT "FILE_RANDOM_PUT_LOC_LOF: FAIL"
END IF

' Relecture et vérification des enregistrements
OPEN "test_rnd_field.dat" FOR RANDOM AS #1 LEN = 32
FIELD #1, 10 AS f_nom$, 4 AS f_code$, 18 AS f_desc$

GET #1, 1
LET rec1_nom$ = f_nom$
LET rec1_code = CVI(f_code$)
LET rec1_desc$ = f_desc$

GET #1, 2
LET rec2_nom$ = f_nom$
LET rec2_code = CVI(f_code$)
LET rec2_desc$ = f_desc$

CLOSE #1
KILL "test_rnd_field.dat"

IF (rec1_nom$ = "ALICE     " AND rec1_code = 42 AND rec1_desc$ = "             ADMIN") THEN
    PRINT "FILE_RANDOM_GET_REC1: PASS"
ELSE
    PRINT "FILE_RANDOM_GET_REC1: FAIL"
END IF

IF (rec2_nom$ = "BOB       " AND rec2_code = 99 AND rec2_desc$ = "GUEST             ") THEN
    PRINT "FILE_RANDOM_GET_REC2: PASS"
ELSE
    PRINT "FILE_RANDOM_GET_REC2: FAIL"
END IF

' --------------------------------------------------------
' SECTION 4: Random Access with User-Defined TYPE Records
' --------------------------------------------------------
TYPE ItemRecord
    title AS STRING * 12
    qty AS INTEGER
    price AS SINGLE
END TYPE

DIM itm_out AS ItemRecord
DIM itm_in AS ItemRecord

itm_out.title = "WIDGET"
itm_out.qty = 50
itm_out.price = 19.95

OPEN "test_type_io.dat" FOR RANDOM AS #2 LEN = 18
PUT #2, 3, itm_out

GET #2, 3, itm_in
CLOSE #2
KILL "test_type_io.dat"

IF (itm_in.qty = 50 AND ABS(itm_in.price - 19.95) < 0.01 AND itm_in.title = "WIDGET      ") THEN
    PRINT "FILE_RANDOM_TYPE_RECORD: PASS"
ELSE
    PRINT "FILE_RANDOM_TYPE_RECORD: FAIL"
END IF

' --------------------------------------------------------
' SECTION 5: Advanced Binary Access with SEEK, LOC, LOF
' --------------------------------------------------------
OPEN "test_adv_bin.dat" FOR BINARY AS #1
PUT #1, 1, "HEADER"
PUT #1, 50, MKL$(987654321)

LET bin_lof = LOF(1)
SEEK #1, 1
LET seek_start = SEEK(1)

LET h_read$ = SPACE$(6)
GET #1, , h_read$

SEEK #1, 50
LET l_read$ = SPACE$(4)
GET #1, , l_read$
LET l_val = CVL(l_read$)

CLOSE #1
KILL "test_adv_bin.dat"

IF (bin_lof >= 53 AND seek_start = 1 AND h_read$ = "HEADER" AND l_val = 987654321) THEN
    PRINT "FILE_BINARY_ADVANCED_SEEK: PASS"
ELSE
    PRINT "FILE_BINARY_ADVANCED_SEEK: FAIL"
END IF

' --------------------------------------------------------
' SECTION 6: FREEFILE Function
' --------------------------------------------------------
LET f1 = FREEFILE
OPEN "temp_ff1.tmp" FOR OUTPUT AS #f1
LET f2 = FREEFILE
OPEN "temp_ff2.tmp" FOR OUTPUT AS #f2

CLOSE #f1, #f2
KILL "temp_ff1.tmp"
KILL "temp_ff2.tmp"

IF (f1 = 1 AND f2 = 2) THEN
    PRINT "FILE_FREEFILE_ALLOC: PASS"
ELSE
    PRINT "FILE_FREEFILE_ALLOC: FAIL"
END IF

' --------------------------------------------------------
' SECTION 7: File System Commands (MKDIR, NAME, KILL, RMDIR)
' --------------------------------------------------------
MKDIR "temp_test_fs_dir"

OPEN "temp_test_fs_dir/doc_orig.tmp" FOR OUTPUT AS #1
PRINT #1, "QBASIC_FS_SUCCESS"
CLOSE #1

NAME "temp_test_fs_dir/doc_orig.tmp" AS "temp_test_fs_dir/doc_ren.tmp"

OPEN "temp_test_fs_dir/doc_ren.tmp" FOR INPUT AS #1
LINE INPUT #1, fs_content$
CLOSE #1

KILL "temp_test_fs_dir/doc_ren.tmp"
RMDIR "temp_test_fs_dir"

IF (fs_content$ = "QBASIC_FS_SUCCESS") THEN
    PRINT "FILE_SYSTEM_OPERATIONS: PASS"
ELSE
    PRINT "FILE_SYSTEM_OPERATIONS: FAIL"
END IF

PRINT "ALL_FILE_TESTS_DONE: PASS"
END
