DEFLNG A-Z

TYPE snakeBody
    row AS LONG
    col AS LONG
END TYPE

TYPE snaketype
    head      AS LONG
    length    AS LONG
    row       AS LONG
    col       AS LONG
    direction AS LONG
    lives     AS LONG
    score     AS LONG
    scolor    AS LONG
    alive     AS LONG
    col2      AS LONG
    col3      AS LONG
    row2      AS LONG
    row3      AS LONG
    wall      AS LONG
END TYPE

TYPE arenaType
    realRow     AS LONG
    acolor      AS LONG
    sister      AS LONG
END TYPE

DECLARE SUB SpacePause (ttext$)
DECLARE SUB Intro ()
DECLARE SUB GetInputs (numplayers, speed, diff$, monitor$, comp)
DECLARE SUB DrawScreen ()
DECLARE SUB PlayNibbles (numplayers, speed, diff$, comp)
DECLARE SUB set (row, col, acolor)
DECLARE SUB Center (row, ttext$)
DECLARE SUB DoIntro ()
DECLARE SUB Initialize ()
DECLARE SUB SparklePause ()
DECLARE SUB Level (WhatToDO, comp, numplayers, sammy() AS snaketype)
DECLARE SUB InitColors ()
DECLARE SUB EraseSnake (snake() AS ANY, snakeBod() AS ANY, snakeNum&)
DECLARE FUNCTION StillWantsToPlay ()
DECLARE FUNCTION PointIsThere (row, col, backColor)
DECLARE FUNCTION PointIsThere2 (row, col, c, d)


CONST TRUE = -1
CONST FALSE = NOT TRUE
CONST MAXSNAKELENGTH = 1000
CONST STARTOVER = 1
CONST SAMELEVEL = 2
CONST NEXTLEVEL = 3

DIM SHARED arena(1 TO 50, 1 TO 80) AS arenaType
DIM SHARED curlevel, colortable(13), exitRequested

    RANDOMIZE TIMER
    GOSUB ClearKeyLocks
    Intro
    GetInputs numplayers, speed, diff$, monitor$, comp
    GOSUB SetColors
    DrawScreen

    DO
      PlayNibbles numplayers, speed, diff$, comp
    LOOP WHILE NOT exitRequested AND StillWantsToPlay

    GOSUB RestoreKeyLocks
    COLOR 15, 0
    CLS
END

ClearKeyLocks:
    REM DEF SEG = 0
    REM  KeyFlags = PEEK(1047)
    REM POKE 1047, &H0
    REM DEF SEG
    RETURN

RestoreKeyLocks:
    REM DEF SEG = 0
    REM POKE 1047, KeyFlags
    REM DEF SEG
    RETURN

SetColors:
    RESTORE normal
    FOR a = 1 TO 9
        READ colortable(a)
    NEXT a
    RETURN

           'snake1 snake2 snake3 snake4 snake5 snake6 snake7 snake8  Walls
normal: DATA 15,    14,    13,    12,    11,    10,     9,     8,     7,
END

SUB Center (row, ttext$)
    LOCATE row, 41 - LEN(ttext$) / 2
    PRINT ttext$;
END SUB


SUB DrawScreen

    VIEW PRINT
    COLOR 14, 0
    CLS

    Center 1, "Nibbles!"
    Center 11, "Initializing Playing Field..."

    FOR row = 1 TO 50
        FOR col = 1 TO 80
            arena(row, col).realRow = INT((row + 1) / 2)
            arena(row, col).sister = (row MOD 2) * 2 - 1
        NEXT col
    NEXT row
END SUB

SUB EraseSnake (snake() AS snaketype, snakeBod() AS snakeBody, snakeNum)
    FOR b = 0 TO snake(snakeNum).length
        tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
        IF snakeBod(tail, snakeNum).row > 0 THEN
            set snakeBod(tail, snakeNum).row, snakeBod(tail, snakeNum).col, 0
            snakeBod(tail, snakeNum).row = 0
        END IF
    NEXT b
END SUB

SUB GetInputs (numplayers, speed, diff$, monitor$, comp)

    COLOR 7, 0
    CLS

    DO
        LOCATE 5, 47: PRINT SPACE$(34);
        LOCATE 5, 20
        INPUT "How many players (1 to 8)"; num$
    LOOP UNTIL VAL(num$) > 0 AND VAL(num$) < 9
    numplayers = VAL(num$)
    DO
      LOCATE 6, 47: PRINT SPACE$(34)
      LOCATE 6, 20
      INPUT "How many players does computer play"; comp$
    LOOP UNTIL VAL(comp$) = 0 OR VAL(comp$) = 1 OR VAL(comp$) = 2 OR VAL(comp$) = 3 OR VAL(comp$) = 4 OR VAL(comp$) = 5 OR VAL(comp$) = 6 OR VAL(comp$) = 7 OR VAL(comp$) = 8
    comp = VAL(comp$)


    LOCATE 8, 21: PRINT "Skill level (1 to 100)"
    LOCATE 9, 22: PRINT "1   = Novice"
    LOCATE 10, 22: PRINT "90  = Expert"
    LOCATE 11, 22: PRINT "100 = Twiddle Fingers"
    LOCATE 12, 15: PRINT "(Computer speed may affect your skill level)"
    DO
        LOCATE 8, 44: PRINT SPACE$(35);
        LOCATE 8, 43
        INPUT gamespeed$
    LOOP UNTIL VAL(gamespeed$) >= 1 AND VAL(gamespeed$) <= 1000
    speed = VAL(gamespeed$)
    IF speed < 1 THEN speed = 1
    IF speed > 100 THEN speed = 100

    ' Delai precis par tour (secondes) pour notre environnement SDL/Win64
    ' Niveau 1 (Novice) : ~95ms, Niveau 50 : ~58ms, Niveau 100 : ~20ms
    stepDelay# = 0.095 - (speed - 1) * 0.00075
    IF stepDelay# < 0.02 THEN stepDelay# = 0.02

    diff$ = "Y"
    monitor$ = "C"
END SUB

SUB InitColors

    FOR row = 1 TO 50
        FOR col = 1 TO 80
            arena(row, col).acolor = 0
        NEXT col
    NEXT row

    CLS

    FOR col = 1 TO 80
        set 3, col, colortable(9)

set 50, col, colortable(9)
    NEXT col

    FOR row = 4 TO 49
        set row, 1, colortable(9)
        set row, 80, colortable(9)
    NEXT row

END SUB

SUB Intro
    SCREEN 0
    WIDTH 80, 25
    COLOR 15, 0
    CLS

    Center 4, "Q B a s i c   N i b b l e s"
    COLOR 7
    Center 8, "Nibbles is a game for one to eight players.  Navigate your snakes"
    Center 9, "around the game board trying to eat up numbers. The more numbers you eat"
    Center 10, "up, the more points you gain and the longer you snake becomes."
    Center 11, "With more points you have more special functions available to you."
    Center 13, "+-------+-------------------------------------------------------------+"
    Center 14, "| Keys  | Controles :                                                 |"
    Center 15, "| (8246)| Joueur 1 : Fleches directionnelles ou Pave numerique        |"
    Center 16, "| Z S Q | Joueur 1 (Solo) : Touches ZSQD (AZERTY) ou WASD (QWERTY)     |"
    Center 17, "| W S A | Joueur 2 : Touches ZSQD ou WASD                             |"
    Center 18, "| P / X | Pause : Touche P  |  Quitter : Touche X ou Echap            |"
    Center 19, "+-------+-------------------------------------------------------------+"
    Center 24, "Press any key to continue"

    'PLAY "MBT160O1L8CDEDCDL4ECC"
    SparklePause

END SUB

SUB Level (WhatToDO, comp, numplayers, sammy() AS snaketype) STATIC

    SELECT CASE (WhatToDO)

    CASE STARTOVER
        curlevel = 1
    CASE NEXTLEVEL
        curlevel = curlevel + 1
    END SELECT

    FOR a = 1 TO 8
      sammy(a).head = 1
      sammy(a).length = ((numplayers - comp) < 1) * 0 + 2
      sammy(a).alive = TRUE
      sammy(a).scolor = colortable(a)
    NEXT a


    InitColors

    SELECT CASE curlevel
    CASE 1


    CASE 2
        FOR i = 20 TO 60
            set 25, i, colortable(9)
        NEXT i

    CASE 3
        FOR i = 10 TO 40
            set i, 20, colortable(9)
            set i, 60, colortable(9)
        NEXT i

    CASE 4
        FOR i = 4 TO 30
            set i, 20, colortable(9)
            set 53 - i, 60, colortable(9)
        NEXT i
        FOR i = 2 TO 40
            set 38, i, colortable(9)
            set 15, 81 - i, colortable(9)
        NEXT i

    CASE 5
        FOR i = 13 TO 39
            set i, 21, colortable(9)
            set i, 59, colortable(9)
        NEXT i
        FOR i = 23 TO 57
            set 11, i, colortable(9)
            set 41, i, colortable(9)
        NEXT i

    CASE 6
        FOR i = 4 TO 49
            IF i > 30 OR i < 23 THEN
                set i, 10, colortable(9)
                set i, 20, colortable(9)
                set i, 30, colortable(9)
                set i, 40, colortable(9)
                set i, 50, colortable(9)
                set i, 60, colortable(9)
                set i, 70, colortable(9)
            END IF
        NEXT i

    CASE 7
        FOR i = 4 TO 49 STEP 2
            set i, 40, colortable(9)
        NEXT i

    CASE 8
        FOR i = 4 TO 40
            set i, 10, colortable(9)
            set 53 - i, 20, colortable(9)
            set i, 30, colortable(9)
            set 53 - i, 40, colortable(9)
            set i, 50, colortable(9)
            set 53 - i, 60, colortable(9)
            set i, 70, colortable(9)
        NEXT i

    CASE 9
        FOR i = 6 TO 47
            set i, i, colortable(9)
            set i, i + 28, colortable(9)
        NEXT i

    CASE 10
        FOR i = 4 TO 49 STEP 2
            set i, 10, colortable(9)
            set i + 1, 20, colortable(9)
            set i, 30, colortable(9)
            set i + 1, 40, colortable(9)
            set i, 50, colortable(9)
            set i + 1, 60, colortable(9)
            set i, 70, colortable(9)
        NEXT i

     CASE 11
       FOR j = 5 TO 45 STEP 10
         FOR i = 5 + (j / 2) TO 48 - (j / 2)
           set i, j, colortable(9)
           set i, 81 - j, colortable(9)
         NEXT i
       NEXT j
       FOR j = 8 TO 36 STEP 4
         FOR i = -12 + (j * 2.5) TO 92 - (j * 2.5)
           set 53 - j, i, colortable(9)
           set j, i, colortable(9)
         NEXT i
       NEXT j

    CASE 12

FOR j = 5 TO 40 STEP 5
          FOR i = 5 + (j / 3) TO 48 - (j / 3)
            set i, j, colortable(9)
            set i, 81 - j, colortable(9)
          NEXT i
        NEXT j
        FOR j = 6 TO 12 STEP 2
          FOR i = -15 + (j * 4) TO 96 - (j * 4)
            set 53 - j, i, colortable(9)
            set j, i, colortable(9)
          NEXT i
        NEXT j

    CASE 13
      FOR j = 5 TO 48 STEP 1
        FOR i = 3 TO 78 STEP 2
          set j, i, colortable(9)
        NEXT i
      NEXT j

    CASE 14
      FOR j = 5 TO 48 STEP 2
        FOR i = 3 TO 78 STEP 1
          set j, i, colortable(9)
        NEXT i
      NEXT j

    CASE 15
      FOR j = 4 TO 77
        IF (j > 10 AND j < 14) OR (j > 25 AND j < 29) OR (j > 38 AND j < 43) OR (j > 51 AND j < 55) OR (j > 66 AND j < 70) THEN
          set 11, j, colortable(9)
          set 42, j, colortable(9)
        ELSE
          set 6, j, colortable(9)
          set 47, j, colortable(9)
        END IF
      NEXT j
      FOR j = 6 TO 47
        IF (j > 13 AND j < 16) OR (j > 25 AND j < 29) OR (j > 37 AND j < 40) THEN
          set j, 8, colortable(9)
          set j, 73, colortable(9)
        ELSE
          set j, 4, colortable(9)
          set j, 77, colortable(9)
        END IF
      NEXT j
      r = 0
      FOR q = 1 TO 8
        IF r = 66 THEN r = 70
        IF r = 55 THEN r = 66
        IF r = 51 THEN r = 55
        IF r = 29 THEN r = 51
        IF r = 25 THEN r = 29
        IF r = 14 THEN r = 25
        IF r = 10 THEN r = 14
        IF r = 0 THEN r = 10
      FOR j = 7 TO 11
        set j, r, colortable(9)
        set 53 - j, r, colortable(9)
      NEXT j
      NEXT q
      FOR j = 4 TO 8
        set 13, j, colortable(9)
        set 13, 81 - j, colortable(9)
        set 16, j, colortable(9)
        set 16, 81 - j, colortable(9)
        set 37, j, colortable(9)
        set 37, 81 - j, colortable(9)
        set 40, j, colortable(9)
        set 40, 81 - j, colortable(9)
      NEXT j
      FOR j = 13 TO 68
       IF (j > 16 AND j < 24) OR (j > 38 AND j < 43) OR (j > 57 AND j < 64) THEN
          set 11, j, colortable(9)
          set 42, j, colortable(9)
       ELSE
         set 15, j, colortable(9)
         set 38, j, colortable(9)
       END IF
      NEXT j
      FOR j = 15 TO 38
        IF (j > 18 AND j < 23) OR (j > 31 AND j < 35) THEN
          set j, 8, colortable(9)
          set j, 73, colortable(9)
        ELSE
          set j, 13, colortable(9)
          set j, 68, colortable(9)
        END IF
      NEXT j
      r = 0
      FOR q = 1 TO 4
        IF r = 57 THEN r = 64
        IF r = 23 THEN r = 57
        IF r = 16 THEN r = 23
        IF r = 0 THEN r = 16
      FOR j = 11 TO 15
        set j, r, colortable(9)
        set 53 - j, r, colortable(9)
      NEXT j
      NEXT q
      FOR j = 8 TO 12
        set 18, j, colortable(9)
        set 18, 81 - j, colortable(9)
        set 23, j, colortable(9)
        set 23, 81 - j, colortable(9)
        set 31, j, colortable(9)
        set 31, 81 - j, colortable(9)
        set 35, j, colortable(9)
        set 35, 81 - j, colortable(9)
      NEXT j
      FOR j = 16 TO 65
        IF (j > 38 AND j < 43) THEN
        ELSE
          set 18, j, colortable(9)
          set 35, j, colortable(9)
        END IF
      NEXT j
      FOR j = 18 TO 35
        set j, 16, colortable(9)
        set j, 65, colortable(9)
      NEXT j
      FOR j = 38 TO 43
        set 27, j, colortable(9)
      NEXT j
      FOR j = 25 TO 29
        set j, 40, colortable(9)
        set j, 41, colortable(9)
      NEXT j
      FOR r = 18 TO 38 STEP 2
        FOR j = 20 TO 33
          IF (j > 26 AND j < 28) THEN
          ELSE
            set j, r, colortable(9)
            REM set j,45,colortable(9)
          END IF
        NEXT j
      NEXT r
      FOR r = 43 TO 65 STEP 2
        FOR j = 20 TO 33
          IF (j > 26 AND j < 28) THEN
          ELSE
            set j, r, colortable(9)
            REM set j , 45, colortable(9)
          END IF
        NEXT j
      NEXT r

    CASE 16
      FOR j = 4 TO 77
        IF (j > 10 AND j < 14) OR (j > 25 AND j < 29) OR (j > 38 AND j < 43) OR (j > 51 AND j < 55) OR (j > 66 AND j < 70) THEN
          set 11, j, colortable(9)
          set 42, j, colortable(9)
        ELSE
          set 6, j, colortable(9)
          set 47, j, colortable(9)
        END IF

NEXT j
      FOR j = 6 TO 47
        IF (j > 13 AND j < 16) OR (j > 25 AND j < 29) OR (j > 37 AND j < 40) THEN
          set j, 8, colortable(9)
          set j, 73, colortable(9)
        ELSE
          set j, 4, colortable(9)
          set j, 77, colortable(9)
        END IF
      NEXT j
      r = 0
      FOR q = 1 TO 8
        IF r = 66 THEN r = 70
        IF r = 55 THEN r = 66
        IF r = 51 THEN r = 55
        IF r = 29 THEN r = 51
        IF r = 25 THEN r = 29
        IF r = 14 THEN r = 25
        IF r = 10 THEN r = 14
        IF r = 0 THEN r = 10
      FOR j = 7 TO 11
        set j, r, colortable(9)
        set 53 - j, r, colortable(9)
      NEXT j
      NEXT q
      FOR j = 4 TO 8
        set 13, j, colortable(9)
        set 13, 81 - j, colortable(9)
        set 16, j, colortable(9)
        set 16, 81 - j, colortable(9)
        set 37, j, colortable(9)
        set 37, 81 - j, colortable(9)
        set 40, j, colortable(9)
        set 40, 81 - j, colortable(9)
      NEXT j
      FOR j = 13 TO 68
       IF (j > 16 AND j < 24) OR (j > 38 AND j < 43) OR (j > 57 AND j < 64) THEN
          set 11, j, colortable(9)
          set 42, j, colortable(9)
       ELSE
         set 15, j, colortable(9)
         set 38, j, colortable(9)
       END IF
      NEXT j
      FOR j = 15 TO 38
        IF (j > 18 AND j < 23) OR (j > 31 AND j < 35) THEN
          set j, 8, colortable(9)
          set j, 73, colortable(9)
        ELSE
          set j, 13, colortable(9)
          set j, 68, colortable(9)
        END IF
      NEXT j
      r = 0
      FOR q = 1 TO 4
        IF r = 57 THEN r = 64
        IF r = 23 THEN r = 57
        IF r = 16 THEN r = 23
        IF r = 0 THEN r = 16
      FOR j = 11 TO 15
        set j, r, colortable(9)
        set 53 - j, r, colortable(9)
      NEXT j
      NEXT q
      FOR j = 8 TO 12
        set 18, j, colortable(9)
        set 18, 81 - j, colortable(9)
        set 23, j, colortable(9)
        set 23, 81 - j, colortable(9)
        set 31, j, colortable(9)
        set 31, 81 - j, colortable(9)
        set 35, j, colortable(9)
        set 35, 81 - j, colortable(9)
      NEXT j
      FOR j = 16 TO 65
        IF (j > 38 AND j < 43) THEN
        ELSE
          set 18, j, colortable(9)
          set 35, j, colortable(9)
        END IF
      NEXT j
      FOR j = 18 TO 35
        set j, 16, colortable(9)
        set j, 65, colortable(9)
      NEXT j
      FOR j = 18 TO 63
        set 27, j, colortable(9)
      NEXT j
      FOR j = 23 TO 31
        set j, 40, colortable(9)
        set j, 41, colortable(9)
      NEXT j

      FOR j = 20 TO 33
        IF (j > 25 AND j < 29) THEN
        ELSE
          set j, 38, colortable(9)
          set j, 43, colortable(9)
        END IF
      NEXT j
      FOR j = 18 TO 63
        IF (j > 38 AND j < 43) THEN
        ELSE
          set 20, j, colortable(9)
          set 25, j, colortable(9)
          set 29, j, colortable(9)
          set 33, j, colortable(9)
        END IF
      NEXT j
      FOR j = 1 TO 50
8
         q = INT(RND * 13) + 20
         IF (q > 25 AND q < 29) THEN GOTO 8
9
         r = INT(RND * 45) + 18
         IF (r > 38 AND r < 43) THEN GOTO 9
         set q, r, colortable(9)
      NEXT j



    CASE ELSE
      FOR i = 1 TO (curlevel - 15) * 100
            set (INT(RND * 46) + 4), (INT(RND * 79) + 1), colortable(9)
      NEXT i

    END SELECT

    FOR a = 1 TO numplayers
      sammy(a).head = 1
      sammy(a).length = 4
      sammy(a).alive = TRUE
      sammy(a).scolor = colortable(a)
      sammy(a).direction = 4
      DO
          sammy(a).row = INT(RND * 30) + 10
          sammy(a).col = INT(RND * 50) + 15
      LOOP WHILE PointIsThere(sammy(a).row, sammy(a).col, 0)
    NEXT a

    FOR a = 1 TO numplayers
      LOCATE 1, a * 8
      COLOR colortable(a), 0
      PRINT sammy(a).score
    NEXT a

END SUB

SUB PlayNibbles (numplayers, speed, diff$, comp)

    DIM sammyBody(MAXSNAKELENGTH - 1, 1 TO 8) AS snakeBody
    DIM sammy(1 TO 8) AS snaketype

    FOR a = 1 TO numplayers
      sammy(a).lives = 9
      sammy(a).score = 0
      sammy(a).scolor = colortable(a)
      sammy(a).wall = 0
      sammy(a).row = INT(RND * 30) + 10
      sammy(a).col = INT(RND * 50) + 15
      sammy(a).direction = 4
    NEXT a

    Level STARTOVER, comp, numplayers, sammy()

    curSpeed# = stepDelay#
    exitRequested = FALSE

    SpacePause "     Level" + STR$(curlevel) + ",  Push Space"
    gameOver = FALSE
    DO

        number = 1
        nonum = TRUE
        playerDied = FALSE

        DO

            IF nonum = TRUE THEN
                DO
                    numberrow = INT(RND(1) * 47 + 3)
                    numbercol = INT(RND(1) * 78 + 2)
                    sisterRow = numberrow + arena(numberrow, numbercol).sister
                    row1 = numberrow
                    col1 = numbercol
                LOOP UNTIL NOT PointIsThere(numberrow, numbercol, 0) AND NOT PointIsThere(sisterRow, numbercol, 0)
                numberrow = arena(numberrow, numbercol).realRow
                nonum = FALSE
                COLOR INT(RND * 7) + 9, 0
                LOCATE numberrow, numbercol
                PRINT LTRIM$(STR$(number));
            END IF

            ' === MODE CHEAT : AFFICHAGE ANGLE ET VITESSE REQUIS VERS ADVERSAIRE / CIBLE ===
            tarR = numRow: tarC = numCol
            IF numplayers > 1 THEN
                opp = 3 - curSnake
                IF opp >= 1 AND opp <= numplayers THEN
                    IF sammy(opp).alive THEN tarR = sammy(opp).row: tarC = sammy(opp).col
                END IF
            END IF
            dR = tarR - sammy(curSnake).row
            dC = tarC - sammy(curSnake).col
            IF dC = 0 THEN
                IF dR < 0 THEN cheatAng = 90 ELSE cheatAng = 270
            ELSE
                radCheat# = ATN(-dR / dC)
                cheatAng = CINT(radCheat# * 180 / 3.14159)
                IF dC < 0 THEN cheatAng = cheatAng + 180
                IF cheatAng < 0 THEN cheatAng = cheatAng + 360
            END IF
            cheatVel = CINT(1000 * curSpeed#)
            LOCATE 1, 1: COLOR 14, 0
            PRINT "CHEAT [Ang:"; cheatAng; "deg  Vit:"; cheatVel; "ms]";
            COLOR 7, 0

            ' Vitesse et animation reactive
            SLEEP curSpeed#

            kbd$ = INKEY$
            IF kbd$ <> "" THEN
                SELECT CASE kbd$
                    ' Controles Joueur 1 : Fleches (SDL / Extended DOS) et Pave numerique
                    CASE CHR$(0) + "H", "8":
                        IF sammy(1).direction <> 2 THEN sammy(1).direction = 1
                    CASE CHR$(0) + "P", "2", "5":
                        IF sammy(1).direction <> 1 THEN sammy(1).direction = 2
                    CASE CHR$(0) + "K", "4":
                        IF sammy(1).direction <> 4 THEN sammy(1).direction = 3
                    CASE CHR$(0) + "M", "6":
                        IF sammy(1).direction <> 3 THEN sammy(1).direction = 4

                    ' En solo, support ZSQD (AZERTY) et WASD (QWERTY) pour le Joueur 1
                    CASE "w", "W", "z", "Z":
                        IF numplayers = 1 THEN
                            IF sammy(1).direction <> 2 THEN sammy(1).direction = 1
                        ELSE
                            IF sammy(2).direction <> 2 THEN sammy(2).direction = 1
                        END IF
                    CASE "s", "S":
                        IF numplayers = 1 THEN
                            IF sammy(1).direction <> 1 THEN sammy(1).direction = 2
                        ELSE
                            IF sammy(2).direction <> 1 THEN sammy(2).direction = 2
                        END IF
                    CASE "a", "A", "q", "Q":
                        IF numplayers = 1 THEN
                            IF sammy(1).direction <> 4 THEN sammy(1).direction = 3
                        ELSE
                            IF sammy(2).direction <> 4 THEN sammy(2).direction = 3
                        END IF
                    CASE "d", "D":
                        IF numplayers = 1 THEN
                            IF sammy(1).direction <> 3 THEN sammy(1).direction = 4
                        ELSE
                            IF sammy(2).direction <> 3 THEN sammy(2).direction = 4
                        END IF

                    ' Autres joueurs si multijoueur (3 et 4)
                    CASE "i", "I": IF sammy(4).direction <> 2 THEN sammy(4).direction = 1
                    CASE "k", "K": IF sammy(4).direction <> 1 THEN sammy(4).direction = 2
                    CASE "j", "J": IF sammy(4).direction <> 4 THEN sammy(4).direction = 3
                    CASE "l", "L": IF sammy(4).direction <> 3 THEN sammy(4).direction = 4
                    CASE "t", "T": IF sammy(3).direction <> 2 THEN sammy(3).direction = 1
                    CASE "g", "G": IF sammy(3).direction <> 1 THEN sammy(3).direction = 2
                    CASE "f", "F": IF sammy(3).direction <> 4 THEN sammy(3).direction = 3
                    CASE "h", "H": IF sammy(3).direction <> 3 THEN sammy(3).direction = 4

                    ' Pause et Quitter
                    CASE "p", "P":
                        SpacePause " Game Paused ... Push Space  "
                    CASE CHR$(27), "x", "X":
                        exitRequested = TRUE
                        playerDied = TRUE
                        sammy(1).lives = 0
                END SELECT
            END IF

            IF exitRequested THEN
                playerDied = TRUE
                sammy(1).lives = 0
                EXIT DO
            END IF

            IF playerDied THEN EXIT DO

            ' Affichage des scores en haut
            FOR q = 1 TO numplayers
                LOCATE 1, q * 8
                COLOR colortable(q), 0
                PRINT sammy(q).score
            NEXT q
            LOCATE 1, 68
            COLOR 14, 0
            PRINT "Vies:"; sammy(1).lives; "  ";

            FOR a = 1 TO numplayers
                IF a > (numplayers - comp) THEN
                    ' IA de l'ordinateur
                    IF sammy(a).col < col1 THEN sammy(a).direction = 4
                    IF sammy(a).col > col1 THEN sammy(a).direction = 3
                    IF sammy(a).row < row1 THEN sammy(a).direction = 2
                    IF sammy(a).row > row1 THEN sammy(a).direction = 1
                END IF

                newRow = sammy(a).row
                newCol = sammy(a).col
                SELECT CASE sammy(a).direction
                    CASE 1: newRow = newRow - 1
                    CASE 2: newRow = newRow + 1
                    CASE 3: newCol = newCol - 1
                    CASE 4: newCol = newCol + 1
                END SELECT

                ' Test collision sur les murs ou d'autres serpents
                IF newRow < 4 OR newRow > 49 OR newCol < 2 OR newCol > 79 OR PointIsThere(newRow, newCol, 0) THEN
                    IF a <= (numplayers - comp) THEN
                        SOUND 200, 2
                        SOUND 120, 3
                        sammy(a).alive = FALSE
                        sammy(a).lives = sammy(a).lives - 1
                        playerDied = TRUE
                    ELSE
                        ' IA tente de tourner en cas d'obstacle
                        sammy(a).direction = (sammy(a).direction MOD 4) + 1
                    END IF
                ELSE
                    sammy(a).row = newRow
                    sammy(a).col = newCol
                END IF

                ' Test capture du chiffre
                IF numberrow = INT((sammy(a).row + 1) / 2) AND numbercol = sammy(a).col THEN
                    SOUND 1000, 1
                    IF sammy(a).length < (MAXSNAKELENGTH - 50) THEN
                        sammy(a).length = sammy(a).length + 4
                    END IF
                    sammy(a).score = sammy(a).score + number
                    LOCATE 1, a * 8
                    COLOR colortable(a), 0
                    PRINT sammy(a).score
                    number = number + 1
                    IF number > 9 THEN
                        SOUND 800, 1
                        SOUND 1200, 2
                        FOR b = 1 TO numplayers
                            EraseSnake sammy(), sammyBody(), b
                        NEXT b
                        LOCATE numberrow, numbercol: PRINT " "
                        Level NEXTLEVEL, comp, numplayers, sammy()
                        SpacePause "     Level" + STR$(curlevel) + ",  Push Space"
                        number = 1
                        IF diff$ = "Y" THEN
                            stepDelay# = stepDelay# * 0.93
                            IF stepDelay# < 0.02 THEN stepDelay# = 0.02
                            curSpeed# = stepDelay#
                        END IF
                    END IF
                    nonum = TRUE
                END IF

                ' Mise a jour graphique du corps
                sammy(a).head = (sammy(a).head + 1) MOD MAXSNAKELENGTH
                sammyBody(sammy(a).head, a).row = sammy(a).row
                sammyBody(sammy(a).head, a).col = sammy(a).col
                tail = (sammy(a).head + MAXSNAKELENGTH - sammy(a).length) MOD MAXSNAKELENGTH
                set sammyBody(tail, a).row, sammyBody(tail, a).col, 0
                sammyBody(tail, a).row = 0
                set sammy(a).row, sammy(a).col, sammy(a).scolor
            NEXT a

        LOOP UNTIL playerDied

        curSpeed# = stepDelay#

        FOR a = 1 TO numplayers
            EraseSnake sammy(), sammyBody(), a

            IF NOT exitRequested AND sammy(a).alive = FALSE THEN
                sammy(a).score = sammy(a).score - 10
                IF sammy(a).score < 0 THEN sammy(a).score = 0
                SpacePause " -- Someone Died! Push Space --"
            END IF
        NEXT a

        IF exitRequested THEN EXIT DO

        Level SAMELEVEL, comp, numplayers, sammy()

    LOOP UNTIL sammy(1).lives <= 0 OR (numplayers >= 2 AND sammy(2).lives <= 0)

END SUB

FUNCTION PointIsThere (row, col, acolor)
    IF row < 1 OR row > 50 OR col < 1 OR col > 80 THEN
        PointIsThere = TRUE
    ELSE
        IF arena(row, col).acolor <> acolor THEN
            PointIsThere = TRUE
        ELSE
            PointIsThere = FALSE
        END IF
    END IF
END FUNCTION

FUNCTION PointIsThere2 (row, col, c, d)
    PointIsThere2 = FALSE
    SELECT CASE d
    CASE 1: IF PointIsThere(row - 1, col, c) AND PointIsThere(row, col - 1, c) AND PointIsThere(row, col + 1, c) THEN PointIsThere2 = TRUE
    CASE 2: IF PointIsThere(row + 1, col, c) AND PointIsThere(row, col - 1, c) AND PointIsThere(row, col + 1, c) THEN PointIsThere2 = TRUE
    CASE 3: IF PointIsThere(row + 1, col, c) AND PointIsThere(row - 1, col, c) AND PointIsThere(row, col - 1, c) THEN PointIsThere2 = TRUE
    CASE 4: IF PointIsThere(row + 1, col, c) AND PointIsThere(row - 1, col, c) AND PointIsThere(row, col + 1, c) THEN PointIsThere2 = TRUE
    END SELECT
END FUNCTION

SUB set (row, col, acolor)
    IF row >= 1 AND row <= 50 AND col >= 1 AND col <= 80 THEN
        arena(row, col).acolor = acolor
        realRow = arena(row, col).realRow
        topFlag = (arena(row, col).sister + 1) / 2
        sisterRow = row + arena(row, col).sister
        IF sisterRow < 1 THEN sisterRow = 1
        IF sisterRow > 50 THEN sisterRow = 50
        sisterColor = arena(sisterRow, col).acolor

        IF realRow >= 1 AND realRow <= 25 THEN
            LOCATE realRow, col
            IF acolor = sisterColor THEN
                COLOR acolor, acolor
                PRINT CHR$(219);
            ELSE
                IF topFlag THEN
                    IF acolor > 7 THEN
                        COLOR acolor, sisterColor
                        PRINT CHR$(223);
                    ELSE
                        COLOR sisterColor, acolor
                        PRINT CHR$(220);
                    END IF
                ELSE
                    IF acolor > 7 THEN
                        COLOR acolor, sisterColor
                        PRINT CHR$(220);
                    ELSE
                        COLOR sisterColor, acolor
                        PRINT CHR$(223);
                    END IF
                END IF
            END IF
        END IF
    END IF
END SUB

SUB SpacePause (ttext$)

    COLOR 15, 4
    bTop$ = CHR$(201) + STRING$(31, 205) + CHR$(187)
    bMid$ = CHR$(186) + " " + LEFT$(ttext$ + SPACE$(29), 29) + " " + CHR$(186)
    bBot$ = CHR$(200) + STRING$(31, 205) + CHR$(188)
    Center 11, bTop$
    Center 12, bMid$
    Center 13, bBot$
    t0# = TIMER
    DO
        k$ = INKEY$
        IF k$ = " " OR k$ = CHR$(13) THEN EXIT DO
        IF k$ = "x" OR k$ = "X" OR k$ = CHR$(27) THEN
            exitRequested = TRUE
            EXIT DO
        END IF
        IF TIMER - t0# > 1.0 THEN EXIT DO
        SLEEP 0.05
    LOOP
    COLOR 15, 0

    FOR i = 21 TO 26
        FOR j = 23 TO 58
            set i, j, arena(i, j).acolor
        NEXT j
    NEXT i

END SUB

SUB SparklePause

    COLOR 4, 0
    a$ = "*    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    "
    t0# = TIMER
    DO
        IF INKEY$ <> "" THEN EXIT SUB
        IF TIMER - t0# > 0.8 THEN EXIT SUB

        FOR a = 1 TO 5
            LOCATE 1, 1
            PRINT MID$(a$, a, 80);
            LOCATE 22, 1
            PRINT MID$(a$, 6 - a, 80);

            FOR b = 2 TO 21
            c = (a + b) MOD 5
                IF c = 1 THEN
                    LOCATE b, 80
                    PRINT "*";
                    LOCATE 23 - b, 1
                    PRINT "*";
                ELSE
                    LOCATE b, 80
                    PRINT " ";
                    LOCATE 23 - b, 1
                    PRINT " ";
                END IF
            NEXT b
            SLEEP 0.04
            IF INKEY$ <> "" THEN EXIT SUB
            IF TIMER - t0# > 0.8 THEN EXIT SUB
        NEXT a
    LOOP

END SUB

FUNCTION StillWantsToPlay
    IF exitRequested THEN
        StillWantsToPlay = FALSE
        EXIT FUNCTION
    END IF

    COLOR 15, 4
    bTop$ = CHR$(201) + STRING$(31, 205) + CHR$(187)
    bBot$ = CHR$(200) + STRING$(31, 205) + CHR$(188)
    bSide$ = CHR$(186)
    Center 10, bTop$
    Center 11, bSide$ + "       G A M E   O V E R       " + bSide$
    Center 12, bSide$ + "                               " + bSide$
    Center 13, bSide$ + "      Play Again?   (Y/N)      " + bSide$
    Center 14, bBot$

    t0# = TIMER
    DO
        kbd$ = UCASE$(INKEY$)
        IF kbd$ = "Y" OR kbd$ = "N" THEN EXIT DO
        IF TIMER - t0# > 2.5 THEN kbd$ = "N": EXIT DO
        SLEEP 0.05
    LOOP

    COLOR 15, 0
    FOR r = 10 TO 14
        Center r, SPACE$(33)
    NEXT r

    IF kbd$ = "Y" THEN
        StillWantsToPlay = TRUE
    ELSE
        StillWantsToPlay = FALSE
        COLOR 7, 0
        CLS
    END IF

END FUNCTION

