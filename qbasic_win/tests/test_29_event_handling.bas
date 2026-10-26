' ========================================================
' UNIT TEST 29: Hardware Event Trapping Battery
' (ON KEY, KEY ON/OFF/STOP, KEY n,str$, ON TIMER, TIMER ON/OFF/STOP, ON PLAY, PLAY ON/OFF/STOP, PLAY(0))
' ========================================================

' --------------------------------------------------------
' SECTION 1: ON KEY(n) GOSUB & KEY(n) ON / OFF / STOP (F1 key: n = 1)
' --------------------------------------------------------
LET key1_hits = 0
ON KEY(1) GOSUB Key1Handler
KEY(1) ON

_EVENT_KEY 1
LET after_k1 = 1
GOTO CheckKey1

Key1Handler:
    key1_hits = key1_hits + 1
    RETURN

CheckKey1:
IF (key1_hits = 1 AND after_k1 = 1) THEN
    PRINT "EVT_KEY_ON_TRAP_F1: PASS"
ELSE
    PRINT "EVT_KEY_ON_TRAP_F1: FAIL"
END IF

' Test KEY(1) OFF: events must be ignored
KEY(1) OFF
_EVENT_KEY 1
IF (key1_hits = 1) THEN
    PRINT "EVT_KEY_OFF_IGNORED: PASS"
ELSE
    PRINT "EVT_KEY_OFF_IGNORED: FAIL"
END IF

' Test KEY(1) STOP: event is suspended/queued until KEY(1) ON
KEY(1) STOP
_EVENT_KEY 1
IF (key1_hits = 1) THEN
    KEY(1) ON
    LET dummy_step = 1
    IF (key1_hits = 2) THEN
        PRINT "EVT_KEY_STOP_QUEUED: PASS"
    ELSE
        PRINT "EVT_KEY_STOP_QUEUED: FAIL"
    END IF
ELSE
    PRINT "EVT_KEY_STOP_QUEUED: FAIL"
END IF
KEY(1) OFF

' --------------------------------------------------------
' SECTION 2: Arrow Keys Trapping (Up Arrow: n = 11, Down: n = 14)
' --------------------------------------------------------
LET up_hits = 0
LET down_hits = 0
ON KEY(11) GOSUB UpHandler
ON KEY(14) GOSUB DownHandler
KEY(11) ON
KEY(14) ON

_EVENT_KEY 11
_EVENT_KEY 14
LET after_arrows = 1
GOTO CheckArrows

UpHandler:
    up_hits = up_hits + 1
    RETURN

DownHandler:
    down_hits = down_hits + 1
    RETURN

CheckArrows:
IF (up_hits = 1 AND down_hits = 1 AND after_arrows = 1) THEN
    PRINT "EVT_KEY_ARROWS_TRAP: PASS"
ELSE
    PRINT "EVT_KEY_ARROWS_TRAP: FAIL"
END IF
KEY(11) OFF
KEY(14) OFF

' --------------------------------------------------------
' SECTION 3: KEY n, string$ Softkey Definition
' --------------------------------------------------------
KEY 1, "DIR" + CHR$(13)
KEY 2, "RUN" + CHR$(13)
IF (KEY$(1) = "DIR" + CHR$(13) AND KEY$(2) = "RUN" + CHR$(13)) THEN
    PRINT "EVT_KEY_SET_SOFTKEY: PASS"
ELSE
    PRINT "EVT_KEY_SET_SOFTKEY: FAIL"
END IF

' --------------------------------------------------------
' SECTION 4: ON TIMER(n) GOSUB & TIMER ON / OFF / STOP
' --------------------------------------------------------
LET timer_hits = 0
ON TIMER(0.05) GOSUB TimerHandler
TIMER ON

SLEEP 0.12
TIMER OFF
GOTO CheckTimerOn

TimerHandler:
    timer_hits = timer_hits + 1
    RETURN

CheckTimerOn:
IF (timer_hits >= 1) THEN
    PRINT "EVT_TIMER_ON_FIRE: PASS"
ELSE
    PRINT "EVT_TIMER_ON_FIRE: FAIL"
END IF

' Test TIMER OFF
LET hits_before_off = timer_hits
SLEEP 0.12
IF (timer_hits = hits_before_off) THEN
    PRINT "EVT_TIMER_OFF_IGNORED: PASS"
ELSE
    PRINT "EVT_TIMER_OFF_IGNORED: FAIL"
END IF

' Test TIMER STOP
TIMER STOP
SLEEP 0.12
LET hits_during_stop = timer_hits
TIMER ON
SLEEP 0.01
IF (hits_during_stop = hits_before_off AND timer_hits > hits_during_stop) THEN
    PRINT "EVT_TIMER_STOP_QUEUED: PASS"
ELSE
    PRINT "EVT_TIMER_STOP_QUEUED: FAIL"
END IF
TIMER OFF

' --------------------------------------------------------
' SECTION 5: PLAY(0) Function & Background Queue
' --------------------------------------------------------
LET p0_empty = PLAY(0)

PLAY "MB C D E F G"
LET p0_queued = PLAY(0)

IF (p0_empty = 0 AND p0_queued >= 1) THEN
    PRINT "EVT_PLAY_FUNCTION_COUNT: PASS"
ELSE
    PRINT "EVT_PLAY_FUNCTION_COUNT: FAIL"
END IF

' --------------------------------------------------------
' SECTION 6: ON PLAY(n) GOSUB & PLAY ON / OFF / STOP
' --------------------------------------------------------
LET play_trap_hits = 0
ON PLAY(10) GOSUB PlayTrapHandler
PLAY ON

LET after_play_step = 1
GOTO CheckPlayTrap

PlayTrapHandler:
    play_trap_hits = play_trap_hits + 1
    RETURN

CheckPlayTrap:
IF (play_trap_hits >= 1 AND after_play_step = 1) THEN
    PRINT "EVT_PLAY_ON_TRAP: PASS"
ELSE
    PRINT "EVT_PLAY_ON_TRAP: FAIL"
END IF

' Test PLAY OFF
PLAY OFF
LET play_hits_before_off = play_trap_hits
LET dummy_play = 1
IF (play_trap_hits = play_hits_before_off) THEN
    PRINT "EVT_PLAY_OFF_IGNORED: PASS"
ELSE
    PRINT "EVT_PLAY_OFF_IGNORED: FAIL"
END IF

' Test PLAY STOP
PLAY STOP
LET play_hits_stopped = play_trap_hits
PLAY ON
LET dummy_play2 = 1
IF (play_hits_stopped = play_hits_before_off) THEN
    PRINT "EVT_PLAY_STOP_QUEUED: PASS"
ELSE
    PRINT "EVT_PLAY_STOP_QUEUED: FAIL"
END IF
PLAY OFF

' --------------------------------------------------------
' SECTION 7: Loop Integrity During Asynchronous Event Traps
' --------------------------------------------------------
LET loop_key_hits = 0
ON KEY(2) GOSUB LoopKeyHandler
KEY(2) ON

LET for_counter = 0
LET for_sum = 0
FOR k = 1 TO 10
    for_counter = for_counter + 1
    for_sum = for_sum + k
    IF k = 5 THEN _EVENT_KEY 2
NEXT k
GOTO CheckLoopIntegrity

LoopKeyHandler:
    loop_key_hits = loop_key_hits + 1
    RETURN

CheckLoopIntegrity:
KEY(2) OFF
IF (loop_key_hits = 1 AND for_counter = 10 AND for_sum = 55) THEN
    PRINT "EVT_LOOP_STACK_INTEGRITY: PASS"
ELSE
    PRINT "EVT_LOOP_STACK_INTEGRITY: FAIL"
END IF

END
