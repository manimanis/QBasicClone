10 REM =========================================================================
20 REM TEST SUITE 16: VINTAGE QBASIC PROGRAMS SUITE (qbasic-programs)
30 REM Validation des algorithmes et fonctionnalites utilises dans qbasic-programs
40 REM =========================================================================
50 CLS
60 testCount% = 0: passCount% = 0

100 REM --- Test 1: FIBONUM.BAS Recursion ---
110 testCount% = testCount% + 1
120 fn7 = fact(7)
130 IF fn7 = 13 THEN
140    PRINT "TEST 16.01 - Fibonacci fact(7) == 13: PASS"
150    passCount% = passCount% + 1
160 ELSE
170    PRINT "TEST 16.01 - Fibonacci fact(7) == 13: FAIL"
180 END IF

200 REM --- Test 2: PRIME1.BAS 10th Prime ---
210 testCount% = testCount% + 1
220 p10 = getNthPrime(10)
230 IF p10 = 29 THEN
240    PRINT "TEST 16.02 - 10th Prime Number == 29: PASS"
250    passCount% = passCount% + 1
260 ELSE
270    PRINT "TEST 16.02 - 10th Prime Number == 29: FAIL"
280 END IF

300 REM --- Test 3: IDNUMS.BAS Check Digit Calculation ---
310 testCount% = testCount% + 1
320 rem# = 1234567
330 DIM dgt(7), prd(7)
340 totpro = 0
350 FOR rx = 7 TO 1 STEP -1
360    dgt(rx) = rem# \ 10 ^ (rx - 1)
370    FOR ry = 1 TO 8 - rx
380       IF rx + ry >= 8 THEN EXIT FOR
390       dgt(rx) = dgt(rx) - dgt(rx + ry) * 10 ^ ry
400    NEXT ry
410    prd(rx) = dgt(rx) * (rx + 1)
420    totpro = totpro + prd(rx)
430 NEXT rx
440 IF totpro = 112 THEN
450    PRINT "TEST 16.03 - IDNUMS weighted check sum == 112: PASS"
460    passCount% = passCount% + 1
470 ELSE
480    PRINT "TEST 16.03 - IDNUMS weighted check sum: FAIL"
490 END IF
500 
510 REM --- Test 4: HYBRID.BAS Genetic Ratio ---
520 testCount% = testCount% + 1
530 DIM hx(11)
540 hx(1) = 1
550 FOR hy = 1 TO 8
560    hx(hy + 1) = 2 * hx(hy)
570    IF hx(hy) = 2 * hx(hy - 1) THEN hx(hy + 1) = hx(hy - 1)
580    IF hy > 1 AND hx(hy) = hx(hy - 2) THEN hx(hy + 1) = 2 * hx(hy)
590    IF hy > 3 AND hx(hy) = hx(hy - 2) AND hx(hy - 2) = hx(hy - 4) THEN hx(hy + 1) = 2 * hx(hy)
600    IF hy > 4 AND hx(hy - 1) = 2 * hx(hy - 2) AND hx(hy - 2) = 2 * hx(hy - 3) THEN hx(hy + 1) = .5 * hx(hy)
610    IF (hy + 1) / 3 = (hy + 1) \ 3 THEN hx(hy + 1) = .5 * hx(hy)
620 NEXT hy
630 IF hx(1) = 1 AND hx(5) = 4 AND hx(9) = 1 THEN
640    PRINT "TEST 16.04 - HYBRID Mendelian dihybrid 1:2:1:2:4:2:1:2:1: PASS"
650    passCount% = passCount% + 1
660 ELSE
670    PRINT "TEST 16.04 - HYBRID Mendelian dihybrid: FAIL"
680 END IF

600 REM --- Test 5: TWOS.BAS Digit 2 Counting in Sequences ---
610 testCount% = testCount% + 1
620 c2% = countTwos(1, 1, 100)
630 IF c2% = 20 THEN
640    PRINT "TEST 16.05 - TWOS digit 2 count in 1..100 == 20: PASS"
650    passCount% = passCount% + 1
660 ELSE
670    PRINT "TEST 16.05 - TWOS digit 2 count in 1..100: FAIL"
680 END IF

700 REM --- Test 6: BWDATE.BAS Seconds to Date ---
710 testCount% = testCount% + 1
720 s# = 100000
730 ddate% = 1: yyear% = 2003
740 ssec% = s# MOD 60: mmins% = (s# \ 60) MOD 60: hhour% = (s# \ 3600) MOD 24
750 ddays% = s# \ 86400
760 ddate% = ddate% + ddays%
770 IF ddate% = 2 AND hhour% = 3 AND mmins% = 46 AND ssec% = 40 THEN
780    PRINT "TEST 16.06 - BWDATE 100,000s -> Jan 2 03:46:40: PASS"
790    passCount% = passCount% + 1
800 ELSE
810    PRINT "TEST 16.06 - BWDATE 100,000s: FAIL"
820 END IF

900 REM --- Test 7: DRAW statement ---
910 testCount% = testCount% + 1
915 SCREEN 12
920 DRAW "BM 100, 100 C15 U20 R20 D20 L20"
930 p_border% = POINT(100, 90)
940 SCREEN 0
950 IF p_border% = 15 THEN
960    PRINT "TEST 16.07 - DRAW square drawing & turtle positioning: PASS"
970    passCount% = passCount% + 1
980 ELSE
990    PRINT "TEST 16.07 - DRAW square drawing: FAIL"
1000 END IF

1100 REM --- Test 8: Shell Sort Algorithm (SHELL.BAS) ---
1110 testCount% = testCount% + 1
1120 DIM sarr(10)
1130 sarr(1) = 99: sarr(2) = 12: sarr(3) = 45: sarr(4) = 1: sarr(5) = 8
1140 sarr(6) = 23: sarr(7) = 5: sarr(8) = 67: sarr(9) = 3: sarr(10) = 50
1150 gap% = 5
1160 DO WHILE gap% > 0
1170    DO
1180       sw% = 0
1190       FOR si = 1 TO 10 - gap%
1200          IF sarr(si) > sarr(si + gap%) THEN
1210             SWAP sarr(si), sarr(si + gap%)
1220             sw% = 1
1230          END IF
1240       NEXT si
1250    LOOP UNTIL sw% = 0
1260    gap% = gap% \ 2
1270 LOOP
1280 IF sarr(1) = 1 AND sarr(2) = 3 AND sarr(9) = 67 AND sarr(10) = 99 THEN
1290    PRINT "TEST 16.08 - Shell Sort ascending 10 elements: PASS"
1300    passCount% = passCount% + 1
1310 ELSE
1320    PRINT "TEST 16.08 - Shell Sort: FAIL"
1330 END IF

1400 REM --- Test 9: Floppy A: path resolution in OPEN ---
1410 testCount% = testCount% + 1
1420 OPEN "A:test_floppy_compat.tmp" FOR OUTPUT AS #87
1430 PRINT #87, "FLOPPY_OK"
1440 CLOSE #87
1450 OPEN "A:test_floppy_compat.tmp" FOR INPUT AS #88
1460 INPUT #88, flchk$
1470 CLOSE #88
1480 KILL "test_floppy_compat.tmp"
1490 IF flchk$ = "FLOPPY_OK" THEN
1500    PRINT "TEST 16.09 - OPEN A: path resolution & file #87/#88: PASS"
1510    passCount% = passCount% + 1
1520 ELSE
1530    PRINT "TEST 16.09 - OPEN A: path resolution: FAIL"
1540 END IF

1600 REM --- Test 10: Tokenized File Reading (BWML.BAS format) ---
1610 testCount% = testCount% + 1
1620 OPEN "test_csv_tokens.tmp" FOR OUTPUT AS #102
1630 PRINT #102, "3, apple, banana, cherry"
1640 CLOSE #102
1650 OPEN "test_csv_tokens.tmp" FOR INPUT AS #103
1660 INPUT #103, ntok%
1670 INPUT #103, tok1$
1680 INPUT #103, tok2$
1690 INPUT #103, tok3$
1700 CLOSE #103
1710 KILL "test_csv_tokens.tmp"
1720 IF ntok% = 3 AND tok1$ = "apple" AND tok2$ = "banana" AND tok3$ = "cherry" THEN
1730    PRINT "TEST 16.10 - Tokenized multi-input from single line: PASS"
1740    passCount% = passCount% + 1
1750 ELSE
1760    PRINT "TEST 16.10 - Tokenized multi-input from single line: FAIL"
1770 END IF

1800 REM =========================================================================
1810 PRINT "========================================================================="
1820 PRINT "RESULTAT SUITE 16: "; passCount%; "/"; testCount%; " assertions reussies"
1830 END

2000 FUNCTION fact (num)
2010 IF num = 1 OR num = 2 THEN fact = 1 ELSE fact = fact(num - 1) + fact(num - 2)
2020 END FUNCTION

2100 FUNCTION getNthPrime (n)
2110 px = 1: pa = 0
2120 REM loop
2130 pd = 3: px = px + 1: pc = px / 2
2140 IF INT(pc) = pc THEN GOTO 2150 ELSE GOTO 2160
2150 IF pc = 1 THEN GOTO 2180 ELSE GOTO 2130
2160 pc = px / pd
2170 IF INT(pc) = pc THEN GOTO 2150 ELSE IF pc < pd THEN GOTO 2180 ELSE pd = pd + 2: GOTO 2160
2180 pa = pa + 1
2190 IF pa = n THEN getNthPrime = px: EXIT FUNCTION ELSE GOTO 2130
2200 END FUNCTION

2700 FUNCTION countTwos (startVal, stepVal, maxCount)
2710 cnt% = 0
2720 cv = startVal
2730 FOR ti = 1 TO maxCount
2740    cs$ = LTRIM$(RTRIM$(STR$(cv)))
2750    FOR si = 1 TO LEN(cs$)
2760       IF MID$(cs$, si, 1) = "2" THEN cnt% = cnt% + 1
2770    NEXT si
2780    cv = cv + stepVal
2790 NEXT ti
2800 countTwos = cnt%
2810 END FUNCTION
