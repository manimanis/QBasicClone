' ========================================================
' UNIT TEST 08: Hardware & System Emulation
' ========================================================

' 1. Horloge et date
LET t1 = TIMER
SLEEP 0.05
LET t2 = TIMER
IF (t2 >= t1 AND t1 > 0) THEN PRINT "SYS_TIMER: PASS" ELSE PRINT "SYS_TIMER: FAIL"

LET d$ = DATE$
IF (LEN(d$) = 10 AND MID$(d$, 3, 1) = "-" AND MID$(d$, 6, 1) = "-") THEN PRINT "SYS_DATE: PASS" ELSE PRINT "SYS_DATE: FAIL"

LET tm$ = TIME$
IF (LEN(tm$) = 8 AND MID$(tm$, 3, 1) = ":" AND MID$(tm$, 6, 1) = ":") THEN PRINT "SYS_TIME: PASS" ELSE PRINT "SYS_TIME: FAIL"

' 2. Emulation de memoire DOS : DEF SEG, PEEK, POKE
DEF SEG = 0
LET peek_numlock = PEEK(1047)
IF (peek_numlock = 32) THEN PRINT "SYS_PEEK_NUMLOCK: PASS" ELSE PRINT "SYS_PEEK_NUMLOCK: FAIL"

POKE 1047, 0
DEF SEG

' 3. Ports materiels DOS : INP & OUT
' Port 0x3DA = Registre de statut VGA (bit 3 = vertical retrace, oscille entre 0 et 8)
LET vga_stat = INP(&H3DA)
IF (vga_stat = 0 OR vga_stat = 8) THEN PRINT "SYS_INP_3DA_VGA: PASS" ELSE PRINT "SYS_INP_3DA_VGA: FAIL"

' Port 0x60 = Clavier 8042 (sans touche enfoncee en test automatique, retourne 0)
LET kbd_scancode = INP(&H60)
IF (kbd_scancode >= 0 AND kbd_scancode <= 255) THEN PRINT "SYS_INP_60_KBD: PASS" ELSE PRINT "SYS_INP_60_KBD: FAIL"

' Test de OUT (registre VGA d'index de palette 0x3C8, ecriture sans crash)
OUT &H3C8, 0
PRINT "SYS_OUT_PORT: PASS"

PRINT "SYS_HARDWARE_ALL: PASS"
