'BUILDING TROUBLE, v1.2i; finished 14-03-2002
'(c) Pc72, 2002

'Press Shift+F5 to run

DEFINT A-Z
DECLARE FUNCTION CheckEnemyXY (EnemyNumber)
DECLARE FUNCTION CheckPlayerXY ()
DECLARE FUNCTION EnemyDir (EnemyNumber)
DECLARE FUNCTION Exist (I$)
DECLARE FUNCTION GetInput$ (I$)
DECLARE FUNCTION SetEnemyFrame (EnemyNumber)
DECLARE FUNCTION SetPlayerFrame ()
DECLARE FUNCTION Zero$ (Number, Length)
DECLARE SUB ActualizeMap ()
DECLARE SUB Center (I$, Y)
DECLARE SUB CheckEnemy (EnemyNumber)
DECLARE SUB CheckKey ()
DECLARE SUB DoGameOver ()
DECLARE SUB DoLevel (Level)
DECLARE SUB DoMovement ()
DECLARE SUB DoTitle ()
DECLARE SUB EndGame ()
DECLARE SUB HandleBomb (BombNumber)
DECLARE SUB InitArray ()
DECLARE SUB Initialize ()
DECLARE SUB MapEditor ()
DECLARE SUB MoveEnemy (EnemyNumber)
DECLARE SUB MovePlayer ()
DECLARE SUB Message (I$)
DECLARE SUB Pause (Time)
DECLARE SUB PlayerLose (Level)
DECLARE SUB PlayerWin (Level)
DECLARE SUB PutAhib (X, Y, Z)
DECLARE SUB PutEnemy (X, Y, Z)
DECLARE SUB PutNothing (IX, IY)
DECLARE SUB PutObject (X, Y, Z)
DECLARE SUB RandomMap (Level)
DECLARE SUB ReadMap (Level)
DECLARE SUB ResetMap ()
DECLARE SUB WaitKey ()
TYPE PlayerType
 X AS INTEGER
 Y AS INTEGER
 MapX AS INTEGER
 MapY AS INTEGER
 Dir AS INTEGER
 TestMove AS INTEGER
 TestFall AS INTEGER
 Speed AS INTEGER
 Health AS INTEGER
 Lives AS INTEGER
 Bombs AS INTEGER
 Moving AS INTEGER
 Action AS INTEGER
 JustHit AS INTEGER
 JustHitCount AS INTEGER
 JustHitFrame AS INTEGER
 JustLost AS INTEGER
 JustWon AS INTEGER
 Aborted AS INTEGER
 Invincible AS INTEGER
 Invisible AS INTEGER
 InfiniteBombs AS INTEGER
 InfiniteLives AS INTEGER
END TYPE
TYPE EnemyType
 X AS INTEGER
 Y AS INTEGER
 MapX AS INTEGER
 MapY AS INTEGER
 Dir AS INTEGER
 Alive AS INTEGER
 TestMove AS INTEGER
 TestFall AS INTEGER
 Action AS INTEGER
END TYPE
TYPE GameType
 SoundOn AS INTEGER
 Time AS INTEGER
 Over AS INTEGER
 Level AS INTEGER
 MoveBackward AS INTEGER
 InfiniteTime AS INTEGER
 ConLeft AS INTEGER
END TYPE
TYPE MapType
 Element AS STRING * 1
 Ahib AS INTEGER
 Enemy AS INTEGER
 EnemyNumber AS INTEGER
 Object AS INTEGER
END TYPE
TYPE BombType
 X AS INTEGER
 Y AS INTEGER
 MapX AS INTEGER
 MapY AS INTEGER
 Time AS INTEGER
 Boom AS INTEGER
 Exist AS INTEGER
 DestroyCount AS INTEGER
END TYPE
RANDOMIZE TIMER
CONST TRUE = -1, FALSE = NOT TRUE
DEF FNC (I) = (I - 1) * 16
DEF FNTrim$ (I) = LTRIM$(RTRIM$(STR$(I)))
OPTION BASE 0
DIM SHARED Ahib(1056) AS LONG, Enemy(1056) AS LONG, Object(1056) AS LONG, Nothing(66) AS LONG, Temp(660) AS LONG
DIM SHARED Snd(9) AS STRING, Cheat(16) AS STRING, CheatDesc(16) AS STRING, EditMap(1 TO 20, 1 TO 12) AS STRING, ImageFile
DIM SHARED BadGuy(1 TO 10) AS EnemyType, Player AS PlayerType, Game AS GameType, Map(1 TO 20, 1 TO 12) AS MapType, Bomb(1 TO 10) AS BombType
Initialize
IF Exist("bt.cfg") THEN
 OPEN "bt.cfg" FOR BINARY AS #1
  IF LOF(1) >= 2 THEN
   Game.SoundOn = ASC(INPUT$(1, 1)) - 2
   Game.Level = ASC(INPUT$(1, 1)) - 1
  ELSE
   Game.SoundOn = TRUE
   Game.Level = 1
  END IF
 CLOSE #1
 IF Game.Level > 100 THEN Game.Level = 100
 IF Game.Level < 1 THEN Game.Level = 1
ELSE
 Game.SoundOn = TRUE
 Game.Level = 1
END IF
SCREEN 13
Game.InfiniteTime = FALSE
Game.MoveBackward = FALSE
Player.InfiniteLives = FALSE
Player.InfiniteBombs = FALSE
Player.Invincible = FALSE
Player.Invisible = FALSE
Player.Speed = 1
DIM SetTimePoint AS DOUBLE
COLOR 41
Center "Pc72", 13
IF Game.SoundOn THEN PLAY "MFT127L4O0MLCEG>CP4"
CLS
DO
 Game.Over = FALSE
 FOR I = 1 TO 10
  BadGuy(I).Alive = FALSE
 NEXT I
 DoTitle
 Player.Lives = 3
 Player.Health = 10
 SetTimePoint = TIMER
 DO WHILE NOT Game.Over
  ReadMap Game.Level
  DoLevel Game.Level
  ActualizeMap
  DO UNTIL Player.JustLost OR Player.JustWon OR Player.Aborted
   CheckKey
   FOR I = 1 TO 10
    CheckEnemy I
   NEXT I
   DoMovement
   IF Player.Health < 1 THEN Player.JustLost = TRUE
   IF Game.ConLeft < 1 THEN Player.JustWon = TRUE
   IF NOT Game.InfiniteTime THEN
    IF (TIMER - SetTimePoint) > .7 THEN
     SetTimePoint = TIMER
     Game.Time = Game.Time - 1
    END IF
   END IF
   IF Game.Time < 1 THEN Player.JustLost = TRUE
   LOCATE 25, 1
   COLOR 7
   PRINT " Time: "; Zero$(Game.Time, 3);
   PRINT " þ : " + Zero$(Player.Lives, 2);
   PRINT " þ HP: " + Zero$(Player.Health, 2);
   PRINT " þ Bombs: " + Zero$(Player.Bombs, 2);
   COLOR 15
   Pause 1
  LOOP
  IF Player.JustLost THEN
   Player.JustLost = FALSE
   PlayerLose Game.Level
   IF Player.Lives < 1 THEN Game.Over = TRUE
  END IF
  IF Player.JustWon THEN
   Player.JustWon = FALSE
   PlayerWin Game.Level
   Game.Level = Game.Level + 1
  END IF
  IF Game.Level > 100 THEN
   EndGame
   Game.Over = TRUE
  END IF
 LOOP
 DoGameOver
LOOP

SUB ActualizeMap
 CLS
 Game.ConLeft = 0
 FOR I = 1 TO 10
  BadGuy(I).Alive = FALSE
 NEXT I
 I = 0
 FOR Y = 1 TO 12
  FOR X = 1 TO 20
   SELECT CASE Map(X, Y).Element
    CASE " "
     PutObject FNC(X), FNC(Y), -1
     Map(X, Y).Object = 0
    CASE "Û"
     PutObject FNC(X), FNC(Y), 0
     Map(X, Y).Object = 1
    CASE "±"
     PutObject FNC(X), FNC(Y), 1
     Game.ConLeft = Game.ConLeft + 1
     Map(X, Y).Object = 2
    CASE "="
     PutObject FNC(X), FNC(Y), 2
     Map(X, Y).Object = 3
    CASE "x"
     PutObject FNC(X), FNC(Y), 3
     Map(X, Y).Object = 4
    CASE "þ"
     PutObject FNC(X), FNC(Y), 12
     Map(X, Y).Object = 5
    CASE "E"
     IF I < 10 THEN
      I = I + 1
      PutEnemy FNC(X), FNC(Y), 4
      Map(X, Y).Enemy = TRUE
      Map(X, Y).EnemyNumber = I
      BadGuy(I).Action = 0
      BadGuy(I).TestMove = 0
      BadGuy(I).TestFall = 0
      BadGuy(I).MapX = X
      BadGuy(I).MapY = Y
      BadGuy(I).X = FNC(X)
      BadGuy(I).Y = FNC(Y)
      BadGuy(I).Alive = TRUE
     END IF
    CASE "A"
     PutAhib FNC(X), FNC(Y), 4
     Map(X, Y).Ahib = TRUE
     Player.Action = 0
     Player.TestMove = 0
     Player.TestFall = 0
     Player.MapX = X
     Player.MapY = Y
     Player.X = FNC(X)
     Player.Y = FNC(Y)
     Player.JustHit = FALSE
     Player.JustHitCount = 0
     Player.JustHitFrame = 1
     Player.JustLost = FALSE
     Player.JustWon = FALSE
     Player.Aborted = FALSE
   END SELECT
 NEXT X, Y
 Player.Bombs = Game.ConLeft * 3 + I
 Game.Time = Game.ConLeft * 25
END SUB

SUB Center (I$, Y)
 IF LEN(LTRIM$(I$)) = 0 THEN EXIT SUB
 LOCATE Y, 21 - INT(LEN(I$) / 2)
 PRINT I$;
END SUB

SUB CheckEnemy (EnemyNumber)
 SELECT CASE EnemyDir(EnemyNumber)
  CASE 1
   IF BadGuy(EnemyNumber).TestMove = 0 AND BadGuy(EnemyNumber).Action = 0 AND BadGuy(EnemyNumber).TestFall = 0 THEN
    BadGuy(EnemyNumber).Action = 1
    BadGuy(EnemyNumber).Dir = 1
   END IF
  CASE 2
   IF BadGuy(EnemyNumber).TestMove = 0 AND BadGuy(EnemyNumber).Action = 0 AND BadGuy(EnemyNumber).TestFall = 0 THEN
    BadGuy(EnemyNumber).Action = 1
    BadGuy(EnemyNumber).Dir = 2
   END IF
  CASE 3
   IF BadGuy(EnemyNumber).TestMove = 0 AND BadGuy(EnemyNumber).Action = 0 AND BadGuy(EnemyNumber).TestFall = 0 THEN
    BadGuy(EnemyNumber).Action = 1
    BadGuy(EnemyNumber).Dir = 3
   END IF
  CASE 4
   IF BadGuy(EnemyNumber).TestMove = 0 AND BadGuy(EnemyNumber).Action = 0 AND BadGuy(EnemyNumber).TestFall = 0 THEN
    BadGuy(EnemyNumber).Action = 1
    BadGuy(EnemyNumber).Dir = 4
   END IF
 END SELECT
END SUB

FUNCTION CheckEnemyXY (EnemyNumber)
 SELECT CASE BadGuy(EnemyNumber).Dir
  CASE 1
   IF BadGuy(EnemyNumber).MapY > 1 THEN
    Y = BadGuy(EnemyNumber).MapY - 1
    X = BadGuy(EnemyNumber).MapX
   ELSE
    CheckEnemyXY = FALSE
    EXIT FUNCTION
   END IF
  CASE 2
   IF BadGuy(EnemyNumber).MapY < 12 THEN
    Y = BadGuy(EnemyNumber).MapY + 1
    X = BadGuy(EnemyNumber).MapX
   ELSE
    CheckEnemyXY = FALSE
    EXIT FUNCTION
   END IF
  CASE 3
   IF BadGuy(EnemyNumber).MapX > 1 THEN
    Y = BadGuy(EnemyNumber).MapY
    X = BadGuy(EnemyNumber).MapX - 1
   ELSE
    CheckEnemyXY = FALSE
    EXIT FUNCTION
   END IF
  CASE 4
   IF BadGuy(EnemyNumber).MapX < 20 THEN
    Y = BadGuy(EnemyNumber).MapY
    X = BadGuy(EnemyNumber).MapX + 1
   ELSE
    CheckEnemyXY = FALSE
    EXIT FUNCTION
   END IF
 END SELECT
 IF BadGuy(EnemyNumber).Dir = 1 THEN
  SELECT CASE Map(X, Y).Object
   CASE 3, 4
    IF Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Object = 3 OR Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Object = 4 THEN
     CheckEnemyXY = TRUE
    ELSE
     CheckEnemyXY = FALSE
    END IF
   CASE 0
    IF Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Object = 3 OR Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Object = 4 THEN
     CheckEnemyXY = TRUE
    ELSE
     CheckEnemyXY = FALSE
    END IF
   CASE ELSE
    CheckEnemyXY = FALSE
  END SELECT
 ELSEIF BadGuy(EnemyNumber).Dir = 2 THEN
  SELECT CASE Map(X, Y).Object
   CASE 3, 4
    CheckEnemyXY = TRUE
   CASE 0
    IF Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Object = 3 OR Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Object = 4 THEN
     CheckEnemyXY = TRUE
    ELSE
     CheckEnemyXY = FALSE
    END IF
   CASE ELSE
    CheckEnemyXY = FALSE
  END SELECT
 ELSEIF BadGuy(EnemyNumber).Dir = 3 OR BadGuy(EnemyNumber).Dir = 4 THEN
  SELECT CASE Map(X, Y).Object
   CASE 0, 3, 4
    CheckEnemyXY = TRUE
   CASE ELSE
    CheckEnemyXY = FALSE
  END SELECT
 END IF
END FUNCTION

SUB CheckKey
 DIM KeyHit AS INTEGER
 DIM KeyDir AS INTEGER
 KeyHit = 0
 KeyDir = 0

 ' 1. Saisie prioritaire via INKEY$ (compatible SDL, fleches, WASD, ZQSD, Espace, Entree)
 K$ = INKEY$
 IF K$ <> "" THEN
  SELECT CASE K$
   CASE CHR$(0) + "H", "w", "W", "z", "Z", "8"
    KeyHit = 1: KeyDir = 1
   CASE CHR$(0) + "P", "s", "S", "2", "5"
    KeyHit = 1: KeyDir = 2
   CASE CHR$(0) + "K", "a", "A", "q", "Q", "4"
    KeyHit = 1: KeyDir = 3
   CASE CHR$(0) + "M", "d", "D", "6"
    KeyHit = 1: KeyDir = 4
   CASE " ", CHR$(13), "b", "B"
    KeyHit = 2
   CASE CHR$(0) + CHR$(63), "c", "C"
    KeyHit = 3
   CASE "m", "M"
    KeyHit = 4
   CASE "r", "R"
    KeyHit = 5
   CASE "p", "P"
    KeyHit = 6
   CASE CHR$(0) + CHR$(59)
    KeyHit = 7
   CASE CHR$(27), CHR$(3)
    KeyHit = 8
  END SELECT
 END IF

 ' 2. Saisie materielle de secours via INP(96) (scancodes DOS bruts)
 IF KeyHit = 0 THEN
  RawSc% = INP(96)
  SELECT CASE RawSc%
   CASE 72
    KeyHit = 1: KeyDir = 1
   CASE 80
    KeyHit = 1: KeyDir = 2
   CASE 75
    KeyHit = 1: KeyDir = 3
   CASE 77
    KeyHit = 1: KeyDir = 4
   CASE 29, 57
    KeyHit = 2
   CASE 63
    KeyHit = 3
   CASE 31
    KeyHit = 4
   CASE 19
    KeyHit = 5
   CASE 25
    KeyHit = 6
   CASE 59
    KeyHit = 7
   CASE 1
    KeyHit = 8
  END SELECT
 END IF

 SELECT CASE KeyHit
  CASE 1
   IF Player.TestMove = 0 AND Player.Action = 0 AND Player.TestFall = 0 THEN
    Player.Dir = KeyDir
    IF CheckPlayerXY THEN
     Player.Action = 1
     Player.Moving = TRUE
    ELSE
     Player.Action = 0
     Player.Moving = FALSE
    END IF
   END IF
  CASE 2
   IF Player.TestMove = 0 AND Player.Action = 0 AND Player.TestFall = 0 THEN
    Player.Action = 2
    Player.Moving = 0
   END IF
  CASE 3
   Code$ = UCASE$(GetInput("Enter cheat code: "))
   SELECT CASE Code$
    CASE Cheat(0)
     Player.InfiniteLives = NOT Player.InfiniteLives
     IF Player.InfiniteLives THEN Message "Infinite Lives On" ELSE Message "Infinite Lives Off"
    CASE Cheat(1)
     Player.Bombs = 1
     Player.InfiniteBombs = NOT Player.InfiniteBombs
     IF Player.InfiniteBombs THEN Message "Infinite Bombs On" ELSE Message "Infinite Bombs Off"
    CASE Cheat(2)
     Player.Invincible = NOT Player.Invincible
     IF Player.Invincible THEN Message "Invincibility On" ELSE Message "Invincibility Off"
    CASE Cheat(3)
     Game.InfiniteTime = NOT Game.InfiniteTime
     IF Game.InfiniteTime THEN Message "Timer Stopped" ELSE Message "Timer Resumed"
    CASE Cheat(4)
     Game.Time = Game.ConLeft * 25
     Player.Lives = 9
     Player.Health = 10
     Player.Bombs = Game.ConLeft * 3 + 10
     Message "Everything Refilled"
    CASE Cheat(5)
     FOR I = 1 TO 10
      IF BadGuy(I).Alive THEN
       BadGuy(I).Alive = FALSE
       Map(BadGuy(I).MapX, BadGuy(I).MapY).EnemyNumber = 0
       SELECT CASE Map(BadGuy(I).MapX, BadGuy(I).MapY).Object
        CASE 0
         PutObject FNC(BadGuy(I).MapX), FNC(BadGuy(I).MapY), -1
        CASE 3
         PutObject FNC(BadGuy(I).MapX), FNC(BadGuy(I).MapY), 2
        CASE 4
         PutObject FNC(BadGuy(I).MapX), FNC(BadGuy(I).MapY), 3
       END SELECT
      END IF
     NEXT I
     Message "All Enemies Removed"
    CASE Cheat(6)
     Game.MoveBackward = NOT Game.MoveBackward
     IF Game.MoveBackward THEN Message "Backward Movement On" ELSE Message "Backward Movement Off"
    CASE Cheat(7)
     Player.Bombs = Player.Bombs + 10
     Message "You Are Given 10 Bombs"
    CASE Cheat(8)
     Player.Health = 10
     Message "You Are Given Full Health"
    CASE Cheat(9)
     Player.Lives = 9
     Message "You Are Given Maximum Lives"
    CASE Cheat(10)
     Game.Time = Game.Time + 100
     Message "You Are Given 100 In Time"
    CASE Cheat(11)
     IF Player.Speed = 2 THEN
      Player.Speed = 1
      Message "Player Speed Halved"
     ELSE
      Player.Speed = 2
      Message "Player Speed Doubled"
     END IF
    CASE Cheat(12)
     I = VAL(GetInput("Warp to a level (1 - 99): "))
     IF I < 1 THEN I = 1
     IF I > 99 THEN I = 99
     Message "Warping To Level " + FNTrim$(I)
     Player.Aborted = TRUE
     Game.Level = I
    CASE Cheat(13)
     Player.JustWon = TRUE
    CASE Cheat(14)
     Player.JustLost = TRUE
    CASE Cheat(15)
     Player.Invisible = NOT Player.Invisible
     IF Player.Invisible THEN Message "Invisibility On" ELSE Message "Invisibility Off"
    CASE Cheat(16)
     I = VAL(GetInput("Play sound (0 - 9): "))
     IF I < 0 THEN I = 0
     IF I > 9 THEN I = 9
     IF Game.SoundOn THEN PLAY Snd(I)
     Message "Playing Sound " + FNTrim$(I)
   END SELECT
  CASE 4
   Game.SoundOn = NOT Game.SoundOn
   GET (0, 96)-(319, 103), Temp
   IF Game.SoundOn THEN S$ = "on " ELSE S$ = "off"
   Center " Sound is " + S$, 13
   WaitKey
   PUT (0, 96), Temp, PSET
  CASE 5
   IF UCASE$(GetInput("Restart level (y/n)? ")) = "Y" THEN
    Player.Aborted = TRUE
   ELSE
    ActualizeMap
   END IF
  CASE 6
   GET (0, 96)-(319, 103), Temp
   Center " GAME PAUSED ", 13
   WaitKey
   PUT (0, 96), Temp, PSET
  CASE 7
   OPEN "O", 1, "SCREEN" + FNTrim$(ImageFile) + ".BT"
    DEF SEG = &HA000
    FOR I& = 0 TO 63999
     PRINT #1, CHR$(PEEK(I&));
    NEXT I&
    DEF SEG
   CLOSE 1
   ImageFile = ImageFile + 1
  CASE 8
   IF UCASE$(GetInput("Really quit (y/n)? ")) = "Y" THEN
    Player.Aborted = TRUE
    Game.Over = TRUE
   ELSE
    ActualizeMap
   END IF
 END SELECT
END SUB

FUNCTION CheckPlayerXY
 SELECT CASE Player.Dir
  CASE 1
   IF Player.MapY > 1 THEN
    Y = Player.MapY - 1
    X = Player.MapX
   ELSE
    CheckPlayerXY = FALSE
    EXIT FUNCTION
   END IF
  CASE 2
   IF Player.MapY < 12 THEN
    Y = Player.MapY + 1
    X = Player.MapX
   ELSE
    CheckPlayerXY = FALSE
    EXIT FUNCTION
   END IF
  CASE 3
   IF Player.MapX > 1 THEN
    Y = Player.MapY
    X = Player.MapX - 1
   ELSE
    CheckPlayerXY = FALSE
    EXIT FUNCTION
   END IF
  CASE 4
   IF Player.MapX < 20 THEN
    Y = Player.MapY
    X = Player.MapX + 1
   ELSE
    CheckPlayerXY = FALSE
    EXIT FUNCTION
   END IF
 END SELECT
 IF Player.Dir = 1 THEN
  SELECT CASE Map(X, Y).Object
   CASE 3, 4
    IF Map(Player.MapX, Player.MapY).Object = 3 OR Map(Player.MapX, Player.MapY).Object = 4 THEN
     CheckPlayerXY = TRUE
    ELSE
     CheckPlayerXY = FALSE
    END IF
   CASE 0
    IF Map(Player.MapX, Player.MapY).Object = 3 OR Map(Player.MapX, Player.MapY).Object = 4 THEN
     CheckPlayerXY = TRUE
    ELSE
     CheckPlayerXY = FALSE
    END IF
   CASE ELSE
    CheckPlayerXY = FALSE
  END SELECT
 ELSEIF Player.Dir = 2 THEN
  SELECT CASE Map(X, Y).Object
   CASE 3, 4
    CheckPlayerXY = TRUE
   CASE 0
    IF Map(Player.MapX, Player.MapY).Object = 3 OR Map(Player.MapX, Player.MapY).Object = 4 THEN
     CheckPlayerXY = TRUE
    ELSE
     CheckPlayerXY = FALSE
    END IF
   CASE ELSE
    CheckPlayerXY = FALSE
  END SELECT
 ELSEIF Player.Dir = 3 OR Player.Dir = 4 THEN
  SELECT CASE Map(X, Y).Object
   CASE 0, 3, 4
    CheckPlayerXY = TRUE
   CASE ELSE
    CheckPlayerXY = FALSE
  END SELECT
 END IF
END FUNCTION

SUB DoGameOver
 CLS
 COLOR 15
 Center "GAME  OVER", 13
 IF Game.SoundOn THEN PLAY Snd(0)
 WaitKey
 OPEN "bt.cfg" FOR OUTPUT AS #1
  PRINT #1, CHR$(Game.SoundOn + 2);
  PRINT #1, CHR$(Game.Level + 1);
 CLOSE #1
 SOUND 0, 0
END SUB

SUB DoLevel (Level)
 CLS
 COLOR 15
 I$ = "LEVEL " + FNTrim$(Level)
 LOCATE 12, 21 - INT(LEN(I$) / 2)
 PRINT I$;
 COLOR 7
 Center "Press any key to start", 15
 IF Game.SoundOn THEN PLAY Snd(1)
 WaitKey
 SOUND 0, 0
END SUB

SUB DoMovement
 IY = 0
 MovePlayer
 FOR I = 1 TO 10
  IF BadGuy(I).Alive THEN
   IF BadGuy(I).TestMove = 0 AND BadGuy(I).TestFall = 0 THEN
    IF BadGuy(I).MapY < 12 THEN
     IF Map(BadGuy(I).MapX, BadGuy(I).MapY + 1).Object = 0 AND Map(BadGuy(I).MapX, BadGuy(I).MapY).Object = 0 THEN BadGuy(I).Action = 2
    END IF
   END IF
   MoveEnemy I
  END IF
  IF Bomb(I).Exist THEN HandleBomb I
  IF BadGuy(I).Alive THEN
   PutEnemy BadGuy(I).X, BadGuy(I).Y, SetEnemyFrame(I)
  END IF
 NEXT I
 IF Player.JustHit THEN
  IF Map(Player.MapX, Player.MapY).EnemyNumber > 0 AND Player.JustHitCount < 50 THEN
   Player.JustHitCount = 50
  END IF
 ELSE
  IF Map(Player.MapX, Player.MapY).EnemyNumber > 0 THEN
   IF Player.Health > 0 AND NOT Player.Invincible AND NOT Player.JustHit THEN
    Player.Health = Player.Health - 1
    IF Game.SoundOn THEN PLAY Snd(8)
    Player.JustHit = TRUE
    Player.JustHitCount = 0
   END IF
  END IF
 END IF
 IF Player.JustHitCount < 100 THEN
  Player.JustHitCount = Player.JustHitCount + 1
 ELSE
  Player.JustHit = FALSE
  Player.JustHitCount = 0
 END IF
 IF Player.TestMove = 0 AND Player.TestFall = 0 THEN
  IF Player.MapY < 12 THEN
   IF Map(Player.MapX, Player.MapY + 1).Object = 0 AND Map(Player.MapX, Player.MapY).Object = 0 THEN Player.Action = 3
  END IF
 END IF
 IF Player.Invisible THEN
  Player.JustHit = TRUE
  Player.JustHitCount = 50
 END IF
 PutAhib Player.X, Player.Y, SetPlayerFrame
END SUB

SUB DoTitle
 OPEN "bt.cfg" FOR OUTPUT AS #1
  PRINT #1, CHR$(Game.SoundOn + 2);
  PRINT #1, CHR$(Game.Level + 1);
 CLOSE #1
Main:
 CLS
 COLOR 32
 PRINT "  Building Trouble"
 FOR Y = 0 TO 7
  FOR X = 0 TO 142
   LINE (X * 2, Y * 2 + 12)-(X * 2 + 1, Y * 2 + 13), POINT(X, Y), BF
   PSET (X, Y), 0
 NEXT X, Y
 COLOR 1
 Center "Ahib el Mushman II", 1
 Center "v1.2i", 5
 Center "(c) Pc72, 2002", 25
 COLOR 9
 IF Game.SoundOn THEN PLAY Snd(2)
 Center "(B)egin new game", 8
 IF Game.Level < 2 THEN
  Center "(I)nstructions", 10
  Center "(T)he story", 12
  Center "(C)ontrols", 14
  Center "(D)esign", 16
  Center "(Q)uit", 18
 ELSE
  Center "(R)esume old game", 10
  Center "(I)nstructions", 12
  Center "(T)he story", 14
  Center "(C)ontrols", 16
  Center "(D)esign", 18
  Center "(Q)uit", 20
 END IF
In:
 IF Game.SoundOn THEN S$ = "on " ELSE S$ = "off"
 Center "(S)ound is " + S$, 24
 WHILE INKEY$ <> ""
 WEND
 I$ = UCASE$(INPUT$(1))
 SOUND 0, 0
 SELECT CASE I$
  CASE "S"
   Game.SoundOn = NOT Game.SoundOn
   GOTO In
  CASE "B", " ", CHR$(13)
   Game.Level = 1
   EXIT SUB
  CASE "R"
   IF Game.Level < 2 THEN GOTO In
   EXIT SUB
  CASE "I"
   GOTO Instructions
  CASE "T"
   GOTO Story
  CASE "C"
   GOTO Controls
  CASE "D"
   CALL MapEditor
   GOTO Main
  CASE "Q", CHR$(27)
   ERASE Ahib, Enemy, Object, Nothing, Snd, Cheat, CheatDesc, EditMap, Temp, BadGuy, Map, Bomb
   END
  CASE ELSE
   GOTO In
 END SELECT
Story:
 CLS
 COLOR 44
 Center "THE STORY", 2
 LINE (1, 1)-(318, 21), 43, B
 LOCATE 5, 1
 COLOR 15
 PRINT "  After defeating Lakum the first time,"
 PRINT "  Ahib has been a bit  careless  about"
 PRINT "  his oil fields.  What  he didn't see,"
 PRINT "  was,  that an army of Lakum's people"
 PRINT "  has  built  a  bunch  of derricks in"
 PRINT "  order to steal his oil again."
 PRINT
 PRINT "  Can  you  help  Ahib  destroy  those"
 PRINT "  derricks in order to save his fields"
 PRINT "  and get his oil back?"
 PRINT
 PRINT "  This  time  Ahib's  armed with bombs,"
 PRINT "  and there's  no  mercy  for  whoever"
 PRINT "  might be  on that derrick, Ahib will"
 PRINT "  blow up."
 Message "Press any key and go kick their butts!"
 GOTO Main
Instructions:
 CLS
 COLOR 44
 Center "INSTRUCTIONS", 2
 LINE (1, 1)-(318, 21), 43, B
 LOCATE 5, 1
 COLOR 15
 PRINT "  What you have got to do in this game,"
 PRINT "  is  to  blow  up  every   platform's"
 PRINT "  connection point (  )  in  order  to"
 PutObject 160, 48, 1
 PRINT "  destroy a derrick.  Those connection"
 PRINT "  points  hold  the platforms together,"
 PRINT "  and when you destroy them  all,  the"
 PRINT "  derrick is history."
 PRINT
 PRINT "  To set a bomb, press  Ctrl.  To move"
 PRINT "  around,  use the arrow keys.  If you"
 PRINT "  want to cheat,  press F5 to enter  a"
 PRINT "  cheat. Cheats are available when you"
 PRINT "  complete the game."
 PRINT
 PRINT "  If you have played enough, press Esc"
 PRINT "  to abort the game.  If you have come"
 PRINT "  to an impossible point, press 'R' to"
 PRINT "  restart the level."
 Message "Press any key to continue"
 GOTO Main
Controls:
 CLS
 COLOR 44
 Center "CONTROLS", 2
 LINE (1, 1)-(318, 21), 43, B
 LOCATE 5, 1
 COLOR 15
 Center "Move around:", 5
 Center "Arrows or W-A-S-D / Z-Q-S-D", 7
 Center "Place bomb:", 10
 Center "Space, Enter, B, or Ctrl", 12
 Center "In-game keys:", 15
 Center "P: Pause  |  R: Restart Level", 17
 Center "M: Toggle Sound  |  Esc: Abort", 19
 Message "Press any key to continue"
 GOTO Main
END SUB

SUB EndGame
 CLS
 COLOR 41
 PRINT "   The End"
 FOR Y = 0 TO 7
  FOR X = 0 TO 142
   LINE (X * 3, Y * 3 + 8)-(X * 3 + 2, Y * 3 + 10), POINT(X, Y), BF
   PSET (X, Y), 0
 NEXT X, Y
 LINE (0, 34)-(319, 34), 4
 LINE (0, 36)-(319, 36), 4
 Pause 64
 COLOR 12
 Center "...is it really the end?", 8
 IF Game.SoundOn THEN PLAY Snd(2)
 SOUND 0, 0
 Center "NO ! ! !", 10
 FOR I = 500 TO 37 STEP -2
  IF Game.SoundOn THEN SOUND I, .05
 NEXT I
 Pause 64
 Center "AHIB EL MUSHMAN WILL RETURN !", 12
 SOUND 0, 0
 IF Game.SoundOn THEN PLAY Snd(9)
 Message "Press any key..."
 CLS
 COLOR 44
 Center "CONGRATULATIONS", 2
 LINE (1, 1)-(318, 21), 43, B
 LOCATE 5, 1
 COLOR 15
 PRINT "  Finally,  all  derricks are blown up"
 PRINT "  and  Ahib has returned home for some"
 PRINT "  rest.  His oil fields are safe."
 PRINT
 PRINT "  ...And Lakum's  army?  They've  been"
 PRINT "  arrested, and thrown into jail. Nice!"
 PRINT
 PRINT "  From now  on,  Ahib's  more  careful"
 PRINT "  about his oil fields.  From  what he"
 PRINT "  just experienced,  he  learned  that"
 PRINT "  Lakum is dangerous, even in prison."
 PRINT
 PRINT
 PRINT "  Well, the game's over, but  the  fun"
 PRINT "  has just begun! This game is full of"
 PRINT "  sneaky cheat codes..."
 PRINT "  ...and the next keypress will reveal"
 PRINT "  them!"
 Message "Press a key to find some cheats!"
 CLS
 COLOR 44
 Center "CHEAT CODES", 2
 LINE (1, 1)-(318, 21), 43, B
 COLOR 15
 FOR I = 5 TO 20
  LOCATE I, 1
  PRINT Cheat(I - 4); TAB(20); CheatDesc(I - 4);
 NEXT I
 Message "Press any key to continue"
END SUB

FUNCTION EnemyDir (EnemyNumber)
 I = INT(RND * 2) + 1
 IF Player.Invisible THEN I = 2
 IF I = 2 THEN
  EnemyDir = INT(RND * 4) + 1
 ELSE
  EDir = INT(RND * 2) + 1
  SELECT CASE EDir
   CASE 1
    IF Player.MapY < BadGuy(EnemyNumber).MapY THEN
     EnemyDir = 1
    ELSE
     EnemyDir = 2
    END IF
   CASE 2
    IF Player.MapX < BadGuy(EnemyNumber).MapX THEN
     EnemyDir = 3
    ELSE
     EnemyDir = 4
    END IF
  END SELECT
 END IF
END FUNCTION

FUNCTION Exist (I$)
 OPEN I$ FOR BINARY AS #1
  IF LOF(1) = 0 THEN
   CLOSE #1
   KILL I$
   GOTO NotFound
  END IF
 CLOSE #1
 GOTO Found
NotFound:
 Exist = FALSE
 EXIT FUNCTION
Found:
 Exist = TRUE
END FUNCTION

FUNCTION GetInput$ (I$)
 LOCATE 25, 1
 PRINT SPACE$(40);
 LOCATE 25, 1
 PRINT I$;
 LINE INPUT ; GetInput$
 LOCATE 25, 1
 PRINT SPACE$(40);
END FUNCTION

SUB HandleBomb (BombNumber)
 IF Bomb(BombNumber).Time < 100 THEN
  Bomb(BombNumber).Time = Bomb(BombNumber).Time + 1
  PutObject Bomb(BombNumber).X, Bomb(BombNumber).Y, 4
 ELSE
  PutObject Bomb(BombNumber).X, Bomb(BombNumber).Y, 4 + INT(Bomb(BombNumber).Boom / 4)
  IF Bomb(BombNumber).Boom = 14 THEN
   IF Game.SoundOn THEN PLAY Snd(7)
  END IF
  IF Bomb(BombNumber).Boom < 15 THEN
   Bomb(BombNumber).Boom = Bomb(BombNumber).Boom + 1
  ELSE
   PutNothing Bomb(BombNumber).MapX, Bomb(BombNumber).MapY
   FOR I = 1 TO 5
    SELECT CASE I
     CASE 1
      IF Bomb(BombNumber).MapY > 1 THEN
       Y = Bomb(BombNumber).MapY - 1
       Skip = FALSE
      ELSE
       Skip = TRUE
      END IF
      X = Bomb(BombNumber).MapX
     CASE 2
      IF Bomb(BombNumber).MapY < 12 THEN
       Y = Bomb(BombNumber).MapY + 1
       Skip = FALSE
      ELSE
       Skip = TRUE
      END IF
      X = Bomb(BombNumber).MapX
     CASE 3
      IF Bomb(BombNumber).MapX > 1 THEN
       X = Bomb(BombNumber).MapX - 1
       Skip = FALSE
      ELSE
       Skip = TRUE
      END IF
      Y = Bomb(BombNumber).MapY
     CASE 4
      IF Bomb(BombNumber).MapX < 20 THEN
       X = Bomb(BombNumber).MapX + 1
       Skip = FALSE
      ELSE
       Skip = TRUE
      END IF
      Y = Bomb(BombNumber).MapY
     CASE 5
      X = Bomb(BombNumber).MapX
      Y = Bomb(BombNumber).MapY
    END SELECT
    IF NOT Skip THEN
     SELECT CASE Map(X, Y).Object
      CASE 2
       PutObject FNC(X), FNC(Y), 8 + INT(Bomb(BombNumber).DestroyCount / 4)
       IF Bomb(BombNumber).DestroyCount >= 14 THEN
        IF Game.SoundOn THEN PLAY Snd(6)
        Map(X, Y).Object = 6
        Game.ConLeft = Game.ConLeft - 1
       END IF
      CASE 5
       PutObject FNC(X), FNC(Y), 12 + INT(Bomb(BombNumber).DestroyCount / 4)
       IF Bomb(BombNumber).DestroyCount >= 14 THEN
        IF Game.SoundOn THEN PLAY Snd(6)
        Map(X, Y).Object = 0
        PutNothing X, Y
       END IF
      CASE ELSE
       PutNothing X, Y
     END SELECT
     IF Map(X, Y).Ahib THEN
      IF Bomb(BombNumber).DestroyCount >= 14 THEN
       IF Player.Health > 0 AND NOT Player.Invincible AND NOT Player.JustHit THEN
        Player.Health = Player.Health - 1
        IF Game.SoundOn THEN PLAY Snd(8)
        Player.JustHit = TRUE
        Player.JustHitCount = 0
       END IF
      END IF
     END IF
     IF Map(X, Y).Enemy AND Map(X, Y).EnemyNumber > 0 THEN
      PutEnemy FNC(X), FNC(Y), 12 + INT(Bomb(BombNumber).DestroyCount / 4)
      IF Bomb(BombNumber).DestroyCount >= 14 THEN
       IF Map(X, Y).EnemyNumber > 0 THEN
        IF Game.SoundOn THEN PLAY Snd(6)
        BadGuy(Map(X, Y).EnemyNumber).Alive = FALSE
        Map(X, Y).EnemyNumber = 0
        FOR IX = 1 TO INT(RND * 3) + 1
         IF Player.Health < 10 THEN Player.Health = Player.Health + 1
        NEXT IX
        PutNothing X, Y
       END IF
      END IF
     END IF
    END IF
   NEXT I
   IF Bomb(BombNumber).DestroyCount < 15 THEN
    Bomb(BombNumber).DestroyCount = Bomb(BombNumber).DestroyCount + 1
   ELSE
    Bomb(BombNumber).Exist = FALSE
    Bomb(BombNumber).DestroyCount = 0
   END IF
  END IF
 END IF
END SUB

SUB InitArray
 Nothing(0) = 1048704
 Ahib(0) = 1048704
 Ahib(5) = 320012288
 Ahib(6) = 320017171
 Ahib(7) = 318771987
 Ahib(9) = 318767104
 Ahib(10) = 323043649
 Ahib(11) = 1250067
 Ahib(13) = 1094778880
 Ahib(14) = 323031617
 Ahib(15) = 323043603
 Ahib(17) = 1094795520
 Ahib(18) = 1094795539
 Ahib(19) = 323043603
 Ahib(21) = 320012288
 Ahib(22) = 1094783763
 Ahib(23) = 1261889
 Ahib(25) = 1090519040
 Ahib(26) = 1094795585
 Ahib(27) = 16705
 Ahib(30) = 21037312
 Ahib(31) = 2105345
 Ahib(34) = 536944672
 Ahib(35) = 538976288
 Ahib(38) = 536944672
 Ahib(39) = 538976288
 Ahib(40) = 32
 Ahib(41) = 1090519040
 Ahib(42) = 321661971
 Ahib(43) = 1094783763
 Ahib(44) = 32
 Ahib(45) = 1090519040
 Ahib(46) = 538976288
 Ahib(47) = 1094795552
 Ahib(48) = 32
 Ahib(50) = 538976288
 Ahib(51) = 1094787104
 Ahib(54) = 18882560
 Ahib(55) = 538976288
 Ahib(58) = 320017152
 Ahib(59) = 1250067
 Ahib(62) = 320017171
 Ahib(63) = 1250067
 Ahib(66) = 1048704
 Ahib(71) = 320012288
 Ahib(72) = 320017171
 Ahib(73) = 318771987
 Ahib(75) = 318767104
 Ahib(76) = 323043649
 Ahib(77) = 1250067
 Ahib(79) = 1094778880
 Ahib(80) = 323031617
 Ahib(81) = 323043603
 Ahib(83) = 1094795520
 Ahib(84) = 1094795539
 Ahib(85) = 323043603
 Ahib(87) = 320012288
 Ahib(88) = 1094783763
 Ahib(89) = 1261889
 Ahib(91) = 1090519040
 Ahib(92) = 1094795585
 Ahib(93) = 16705
 Ahib(96) = 21037312
 Ahib(97) = 538976257
 Ahib(98) = 32
 Ahib(99) = 16705
 Ahib(100) = 536944672
 Ahib(101) = 538976288
 Ahib(102) = 4276512
 Ahib(103) = 541147457
 Ahib(104) = 536944672
 Ahib(105) = 2105376
 Ahib(106) = 4276545
 Ahib(107) = 538984769
 Ahib(108) = 321661971
 Ahib(109) = 1250067
 Ahib(110) = 4276480
 Ahib(111) = 536870912
 Ahib(112) = 538976288
 Ahib(113) = 538976288
 Ahib(115) = 538120979
 Ahib(116) = 538976288
 Ahib(117) = 538976288
 Ahib(118) = 32
 Ahib(119) = 320017152
 Ahib(120) = 8224
 Ahib(121) = 538976256
 Ahib(122) = 4883
 Ahib(123) = 320012288
 Ahib(125) = 318767104
 Ahib(126) = 4883
 Ahib(129) = 320012288
 Ahib(130) = 19
 Ahib(132) = 1048704
 Ahib(137) = 320012288
 Ahib(138) = 320017171
 Ahib(139) = 318771987
 Ahib(141) = 318767104
 Ahib(142) = 323043649
 Ahib(143) = 1250067
 Ahib(145) = 1094778880
 Ahib(146) = 323031617
 Ahib(147) = 323043603
 Ahib(149) = 1094795520
 Ahib(150) = 1094795539
 Ahib(151) = 323043603
 Ahib(153) = 320012288
 Ahib(154) = 1094783763
 Ahib(155) = 1261889
 Ahib(157) = 1090519040
 Ahib(158) = 1094795585
 Ahib(159) = 16705
 Ahib(162) = 21037312
 Ahib(163) = 2105345
 Ahib(166) = 536944672
 Ahib(167) = 538976288
 Ahib(170) = 536944672
 Ahib(171) = 538976288
 Ahib(172) = 32
 Ahib(173) = 1090519040
 Ahib(174) = 321661971
 Ahib(175) = 1094783763
 Ahib(176) = 32
 Ahib(177) = 1090519040
 Ahib(178) = 538976288
 Ahib(179) = 1094795552
 Ahib(180) = 32
 Ahib(182) = 538976288
 Ahib(183) = 1094787104
 Ahib(186) = 320017152
 Ahib(187) = 538976288
 Ahib(190) = 320017171
 Ahib(191) = 1250067
 Ahib(194) = 318767104
 Ahib(195) = 1250067
 Ahib(198) = 1048704
 Ahib(203) = 320012288
 Ahib(204) = 320017171
 Ahib(205) = 318771987
 Ahib(207) = 318767104
 Ahib(208) = 323043649
 Ahib(209) = 1250067
 Ahib(211) = 1094778880
 Ahib(212) = 323031617
 Ahib(213) = 323043603
 Ahib(215) = 1094795520
 Ahib(216) = 1094795539
 Ahib(217) = 323043603
 Ahib(219) = 320012288
 Ahib(220) = 1094783763
 Ahib(221) = 1261889
 Ahib(223) = 1090519040
 Ahib(224) = 1094795585
 Ahib(225) = 16705
 Ahib(228) = 21037312
 Ahib(229) = 2105345
 Ahib(232) = 536944640
 Ahib(233) = 538976288
 Ahib(236) = 1090592800
 Ahib(237) = 538976321
 Ahib(240) = 1094790163
 Ahib(241) = 2105409
 Ahib(243) = 536870912
 Ahib(244) = 1092624416
 Ahib(245) = 538976321
 Ahib(247) = 320017152
 Ahib(248) = 538976288
 Ahib(249) = 538976288
 Ahib(250) = 32
 Ahib(251) = 320012288
 Ahib(252) = 8211
 Ahib(253) = 538976256
 Ahib(254) = 4883
 Ahib(255) = 318767104
 Ahib(256) = 19
 Ahib(257) = 318767104
 Ahib(258) = 4883
 Ahib(261) = 320012288
 Ahib(262) = 19
 Ahib(264) = 1048704
 Ahib(270) = 320012307
 Ahib(271) = 320017171
 Ahib(272) = 4883
 Ahib(274) = 320017152
 Ahib(275) = 1094795539
 Ahib(276) = 19
 Ahib(278) = 323043603
 Ahib(279) = 1091715347
 Ahib(280) = 16705
 Ahib(282) = 323043603
 Ahib(283) = 323043649
 Ahib(284) = 4276545
 Ahib(286) = 1094783744
 Ahib(287) = 320028993
 Ahib(288) = 4883
 Ahib(290) = 1094778880
 Ahib(291) = 1094795585
 Ahib(292) = 65
 Ahib(294) = 18882560
 Ahib(295) = 82177
 Ahib(298) = 538976288
 Ahib(299) = 538968352
 Ahib(301) = 536870912
 Ahib(302) = 538976288
 Ahib(303) = 538968352
 Ahib(305) = 536870912
 Ahib(306) = 320028993
 Ahib(307) = 321661971
 Ahib(308) = 65
 Ahib(309) = 536870912
 Ahib(310) = 541147457
 Ahib(311) = 538976288
 Ahib(312) = 65
 Ahib(314) = 538984769
 Ahib(315) = 538976288
 Ahib(318) = 538976288
 Ahib(319) = 2105345
 Ahib(322) = 320017152
 Ahib(323) = 1250067
 Ahib(326) = 320017152
 Ahib(327) = 320017171
 Ahib(330) = 1048704
 Ahib(336) = 320012307
 Ahib(337) = 320017171
 Ahib(338) = 4883
 Ahib(340) = 320017152
 Ahib(341) = 1094795539
 Ahib(342) = 19
 Ahib(344) = 323043603
 Ahib(345) = 1091715347
 Ahib(346) = 16705
 Ahib(348) = 323043603
 Ahib(349) = 323043649
 Ahib(350) = 4276545
 Ahib(352) = 1094783744
 Ahib(353) = 320028993
 Ahib(354) = 4883
 Ahib(356) = 1094778880
 Ahib(357) = 1094795585
 Ahib(358) = 65
 Ahib(359) = 536870912
 Ahib(360) = 18882592
 Ahib(361) = 82177
 Ahib(363) = 541147392
 Ahib(364) = 538976288
 Ahib(365) = 538968352
 Ahib(366) = 1094778880
 Ahib(367) = 1094795520
 Ahib(368) = 538976256
 Ahib(369) = 538968352
 Ahib(370) = 1094795552
 Ahib(371) = 4276480
 Ahib(372) = 320017152
 Ahib(373) = 321661971
 Ahib(374) = 1094787104
 Ahib(376) = 538976288
 Ahib(377) = 538976288
 Ahib(378) = 32
 Ahib(379) = 536870912
 Ahib(380) = 538976288
 Ahib(381) = 538976288
 Ahib(382) = 320017184
 Ahib(383) = 320012288
 Ahib(384) = 2105376
 Ahib(385) = 538968064
 Ahib(386) = 1250067
 Ahib(387) = 320012288
 Ahib(388) = 19
 Ahib(390) = 4883
 Ahib(391) = 318767104
 Ahib(392) = 4883
 Ahib(396) = 1048704
 Ahib(402) = 320012307
 Ahib(403) = 320017171
 Ahib(404) = 4883
 Ahib(406) = 320017152
 Ahib(407) = 1094795539
 Ahib(408) = 19
 Ahib(410) = 323043603
 Ahib(411) = 1091715347
 Ahib(412) = 16705
 Ahib(414) = 323043603
 Ahib(415) = 323043649
 Ahib(416) = 4276545
 Ahib(418) = 1094783744
 Ahib(419) = 320028993
 Ahib(420) = 4883
 Ahib(422) = 1094778880
 Ahib(423) = 1094795585
 Ahib(424) = 65
 Ahib(426) = 18882560
 Ahib(427) = 82177
 Ahib(430) = 538976288
 Ahib(431) = 538968352
 Ahib(433) = 536870912
 Ahib(434) = 538976288
 Ahib(435) = 538968352
 Ahib(437) = 536870912
 Ahib(438) = 320028993
 Ahib(439) = 321661971
 Ahib(440) = 65
 Ahib(441) = 536870912
 Ahib(442) = 541147457
 Ahib(443) = 538976288
 Ahib(444) = 65
 Ahib(446) = 538984769
 Ahib(447) = 538976288
 Ahib(450) = 538976288
 Ahib(451) = 1250067
 Ahib(454) = 320017152
 Ahib(455) = 320017171
 Ahib(458) = 320017152
 Ahib(459) = 19
 Ahib(462) = 1048704
 Ahib(468) = 320012307
 Ahib(469) = 320017171
 Ahib(470) = 4883
 Ahib(472) = 320017152
 Ahib(473) = 1094795539
 Ahib(474) = 19
 Ahib(476) = 323043603
 Ahib(477) = 1091715347
 Ahib(478) = 16705
 Ahib(480) = 323043603
 Ahib(481) = 323043649
 Ahib(482) = 4276545
 Ahib(484) = 1094783744
 Ahib(485) = 320028993
 Ahib(486) = 4883
 Ahib(488) = 1094778880
 Ahib(489) = 1094795585
 Ahib(490) = 65
 Ahib(492) = 18882560
 Ahib(493) = 82177
 Ahib(496) = 538976288
 Ahib(497) = 2097440
 Ahib(500) = 1092624416
 Ahib(501) = 538968385
 Ahib(504) = 1092624384
 Ahib(505) = 321667393
 Ahib(508) = 1092624416
 Ahib(509) = 538976321
 Ahib(510) = 32
 Ahib(511) = 536870912
 Ahib(512) = 538976288
 Ahib(513) = 538976288
 Ahib(514) = 1250067
 Ahib(515) = 320012288
 Ahib(516) = 2105376
 Ahib(517) = 320864256
 Ahib(518) = 4883
 Ahib(519) = 320012288
 Ahib(520) = 19
 Ahib(521) = 318767104
 Ahib(522) = 19
 Ahib(523) = 318767104
 Ahib(524) = 4883
 Ahib(528) = 1048704
 Ahib(534) = 320017152
 Ahib(535) = 320017171
 Ahib(536) = 19
 Ahib(538) = 320017171
 Ahib(539) = 320017171
 Ahib(541) = 318767104
 Ahib(542) = 320017171
 Ahib(543) = 320017171
 Ahib(544) = 19
 Ahib(545) = 318767104
 Ahib(546) = 320017171
 Ahib(547) = 320017171
 Ahib(548) = 19
 Ahib(550) = 320017217
 Ahib(551) = 320017171
 Ahib(554) = 1094795520
 Ahib(555) = 4276545
 Ahib(558) = 16843040
 Ahib(559) = 536936705
 Ahib(561) = 536870912
 Ahib(562) = 538976288
 Ahib(563) = 538976288
 Ahib(564) = 32
 Ahib(565) = 538968064
 Ahib(566) = 538976288
 Ahib(567) = 538976288
 Ahib(568) = 8224
 Ahib(569) = 541130752
 Ahib(570) = 320017171
 Ahib(571) = 320017171
 Ahib(572) = 16672
 Ahib(573) = 1094778880
 Ahib(574) = 538976288
 Ahib(575) = 538976288
 Ahib(576) = 16705
 Ahib(577) = 1090519040
 Ahib(578) = 538976288
 Ahib(579) = 538976288
 Ahib(580) = 65
 Ahib(582) = 2105376
 Ahib(583) = 538976256
 Ahib(586) = 1250067
 Ahib(587) = 320017152
 Ahib(589) = 318767104
 Ahib(590) = 1250067
 Ahib(591) = 320017152
 Ahib(592) = 19
 Ahib(594) = 1048704
 Ahib(599) = 318767104
 Ahib(600) = 320017171
 Ahib(601) = 1250067
 Ahib(604) = 320017171
 Ahib(605) = 323043649
 Ahib(607) = 318767104
 Ahib(608) = 1091715393
 Ahib(609) = 1094783553
 Ahib(610) = 19
 Ahib(612) = 1094783809
 Ahib(613) = 1091780929
 Ahib(614) = 19
 Ahib(616) = 320017217
 Ahib(617) = 1091769107
 Ahib(620) = 1094795520
 Ahib(621) = 4276545
 Ahib(624) = 1090584864
 Ahib(625) = 536936705
 Ahib(627) = 536870912
 Ahib(628) = 18882592
 Ahib(629) = 538976288
 Ahib(630) = 32
 Ahib(631) = 538968064
 Ahib(632) = 18882592
 Ahib(633) = 538976288
 Ahib(634) = 8224
 Ahib(635) = 1094778880
 Ahib(636) = 739447571
 Ahib(637) = 320017196
 Ahib(638) = 16705
 Ahib(639) = 1094778880
 Ahib(640) = 538976288
 Ahib(641) = 538976288
 Ahib(642) = 16705
 Ahib(643) = 1090519040
 Ahib(644) = 538976288
 Ahib(645) = 538976288
 Ahib(646) = 65
 Ahib(648) = 2105376
 Ahib(649) = 538976256
 Ahib(652) = 2102035
 Ahib(653) = 320020480
 Ahib(655) = 318767104
 Ahib(656) = 1250067
 Ahib(657) = 320017152
 Ahib(658) = 19
 Ahib(660) = 1048704
 Ahib(665) = 1090519040
 Ahib(666) = 1091769088
 Ahib(667) = 1250113
 Ahib(668) = 65
 Ahib(669) = 1094795520
 Ahib(670) = 1094783763
 Ahib(671) = 320028993
 Ahib(672) = 4276545
 Ahib(673) = 541147392
 Ahib(674) = 320017217
 Ahib(675) = 1091769107
 Ahib(676) = 4276512
 Ahib(677) = 538968064
 Ahib(678) = 1094795585
 Ahib(679) = 1094795585
 Ahib(680) = 8224
 Ahib(681) = 538968064
 Ahib(682) = 1094795585
 Ahib(683) = 1094795585
 Ahib(684) = 8224
 Ahib(685) = 536870912
 Ahib(686) = 1094795552
 Ahib(687) = 541147457
 Ahib(688) = 32
 Ahib(689) = 536870912
 Ahib(690) = 1090584864
 Ahib(691) = 536936705
 Ahib(692) = 32
 Ahib(694) = 18882592
 Ahib(695) = 538976288
 Ahib(698) = 18882592
 Ahib(699) = 538976288
 Ahib(702) = 739447571
 Ahib(703) = 320017196
 Ahib(706) = 538976288
 Ahib(707) = 538976288
 Ahib(710) = 538976288
 Ahib(711) = 538976288
 Ahib(714) = 2105376
 Ahib(715) = 538976256
 Ahib(718) = 2102035
 Ahib(719) = 320020480
 Ahib(721) = 318767104
 Ahib(722) = 1250067
 Ahib(723) = 320017152
 Ahib(724) = 19
 Ahib(726) = 1048704
 Ahib(732) = 320017171
 Ahib(733) = 1250067
 Ahib(735) = 320012288
 Ahib(736) = 1091715347
 Ahib(737) = 323031617
 Ahib(739) = 318767104
 Ahib(740) = 1094783809
 Ahib(741) = 1091780929
 Ahib(744) = 320017217
 Ahib(745) = 1091769107
 Ahib(746) = 19
 Ahib(747) = 318767104
 Ahib(748) = 520110401
 Ahib(749) = 1094778911
 Ahib(750) = 19
 Ahib(752) = 4276480
 Ahib(753) = 4276480
 Ahib(755) = 536870912
 Ahib(756) = 1090584864
 Ahib(757) = 536936705
 Ahib(759) = 538968064
 Ahib(760) = 18882592
 Ahib(761) = 1092624416
 Ahib(762) = 16705
 Ahib(763) = 538968064
 Ahib(764) = 18882592
 Ahib(765) = 1092624416
 Ahib(766) = 16705
 Ahib(767) = 1094778880
 Ahib(768) = 739447571
 Ahib(769) = 538121004
 Ahib(770) = 8224
 Ahib(771) = 4259840
 Ahib(772) = 538976288
 Ahib(773) = 538976288
 Ahib(774) = 32
 Ahib(776) = 538976288
 Ahib(777) = 538976288
 Ahib(780) = 2105376
 Ahib(781) = 538976256
 Ahib(784) = 320872448
 Ahib(785) = 320020480
 Ahib(788) = 1250067
 Ahib(789) = 320017152
 Ahib(790) = 19
 Ahib(792) = 1048704
 Ahib(797) = 1090519040
 Ahib(798) = 320017217
 Ahib(799) = 320017171
 Ahib(800) = 19
 Ahib(801) = 1090519040
 Ahib(802) = 320017171
 Ahib(803) = 320017171
 Ahib(805) = 318767104
 Ahib(806) = 320017171
 Ahib(807) = 320017171
 Ahib(808) = 19
 Ahib(809) = 320864256
 Ahib(810) = 320017171
 Ahib(811) = 320017171
 Ahib(812) = 19
 Ahib(813) = 538968064
 Ahib(814) = 320017217
 Ahib(815) = 320017171
 Ahib(817) = 536870912
 Ahib(818) = 1094795552
 Ahib(819) = 4276545
 Ahib(821) = 536870912
 Ahib(822) = 16843040
 Ahib(823) = 536936705
 Ahib(824) = 32
 Ahib(826) = 538976288
 Ahib(827) = 538976288
 Ahib(828) = 8224
 Ahib(829) = 318767104
 Ahib(830) = 538976288
 Ahib(831) = 320872480
 Ahib(832) = 8224
 Ahib(833) = 538968064
 Ahib(834) = 320017171
 Ahib(835) = 538120979
 Ahib(837) = 538968064
 Ahib(838) = 538976288
 Ahib(839) = 538976288
 Ahib(840) = 32
 Ahib(841) = 536870912
 Ahib(842) = 2105376
 Ahib(843) = 538976256
 Ahib(844) = 32
 Ahib(845) = 318767104
 Ahib(846) = 1250067
 Ahib(847) = 538976288
 Ahib(848) = 32
 Ahib(850) = 536870912
 Ahib(851) = 538120979
 Ahib(854) = 318767104
 Ahib(855) = 320017171
 Ahib(858) = 1048704
 Ahib(864) = 320017152
 Ahib(865) = 320017171
 Ahib(866) = 19
 Ahib(868) = 320017171
 Ahib(869) = 320017171
 Ahib(870) = 65
 Ahib(871) = 318767104
 Ahib(872) = 320017171
 Ahib(873) = 320017171
 Ahib(874) = 19
 Ahib(875) = 318767104
 Ahib(876) = 320017171
 Ahib(877) = 320017171
 Ahib(878) = 8211
 Ahib(880) = 320017217
 Ahib(881) = 320017171
 Ahib(882) = 8224
 Ahib(884) = 1094795520
 Ahib(885) = 541147457
 Ahib(886) = 32
 Ahib(887) = 536870912
 Ahib(888) = 16843040
 Ahib(889) = 536936705
 Ahib(890) = 32
 Ahib(891) = 538968064
 Ahib(892) = 538976288
 Ahib(893) = 538976288
 Ahib(895) = 538968064
 Ahib(896) = 538976275
 Ahib(897) = 538976288
 Ahib(898) = 19
 Ahib(900) = 320017184
 Ahib(901) = 320017171
 Ahib(902) = 8224
 Ahib(903) = 536870912
 Ahib(904) = 538976288
 Ahib(905) = 538976288
 Ahib(906) = 8224
 Ahib(907) = 536870912
 Ahib(908) = 2105376
 Ahib(909) = 538976256
 Ahib(910) = 32
 Ahib(911) = 536870912
 Ahib(912) = 538976288
 Ahib(913) = 320017152
 Ahib(914) = 19
 Ahib(916) = 320017184
 Ahib(917) = 32
 Ahib(920) = 320017171
 Ahib(921) = 19
 Ahib(924) = 1048704
 Ahib(934) = 320017171
 Ahib(935) = 19
 Ahib(937) = 320012288
 Ahib(938) = 538976288
 Ahib(939) = 2105376
 Ahib(941) = 536870912
 Ahib(942) = 320017171
 Ahib(943) = 320017171
 Ahib(945) = 320864256
 Ahib(946) = 538976288
 Ahib(947) = 538976288
 Ahib(948) = 19
 Ahib(949) = 538976256
 Ahib(950) = 538976288
 Ahib(951) = 538976288
 Ahib(952) = 32
 Ahib(953) = 538976256
 Ahib(954) = 538976288
 Ahib(955) = 538976288
 Ahib(956) = 8224
 Ahib(957) = 541147392
 Ahib(958) = 538976288
 Ahib(959) = 538976288
 Ahib(960) = 8224
 Ahib(961) = 541147457
 Ahib(962) = 538976288
 Ahib(963) = 538976288
 Ahib(964) = 4268064
 Ahib(965) = 536870912
 Ahib(966) = 538976288
 Ahib(967) = 538976256
 Ahib(968) = 32
 Ahib(970) = 538976288
 Ahib(971) = 320017184
 Ahib(972) = 19
 Ahib(974) = 538976288
 Ahib(975) = 320017184
 Ahib(978) = 320020480
 Ahib(979) = 19
 Ahib(982) = 320017152
 Ahib(983) = 4883
 Ahib(986) = 320012288
 Ahib(987) = 4883
 Ahib(990) = 1048704
 Ahib(995) = 1090519040
 Ahib(996) = 320017171
 Ahib(997) = 1250067
 Ahib(998) = 65
 Ahib(999) = 1094795520
 Ahib(1000) = 320017171
 Ahib(1001) = 323043649
 Ahib(1002) = 4276545
 Ahib(1003) = 1094795520
 Ahib(1004) = 1091715393
 Ahib(1005) = 1094783553
 Ahib(1006) = 4276545
 Ahib(1007) = 538968064
 Ahib(1008) = 1094783809
 Ahib(1009) = 1091780929
 Ahib(1010) = 8224
 Ahib(1011) = 538968064
 Ahib(1012) = 320017217
 Ahib(1013) = 1091769107
 Ahib(1014) = 8224
 Ahib(1015) = 536870912
 Ahib(1016) = 521879840
 Ahib(1017) = 541137695
 Ahib(1018) = 32
 Ahib(1019) = 536870912
 Ahib(1020) = 1090584864
 Ahib(1021) = 536936769
 Ahib(1022) = 32
 Ahib(1024) = 18882592
 Ahib(1025) = 538976257
 Ahib(1028) = 538976275
 Ahib(1029) = 320872480
 Ahib(1031) = 536870912
 Ahib(1032) = 739447584
 Ahib(1033) = 538121004
 Ahib(1034) = 32
 Ahib(1035) = 320017152
 Ahib(1036) = 538976288
 Ahib(1037) = 538976288
 Ahib(1038) = 1250067
 Ahib(1039) = 320017152
 Ahib(1040) = 538976288
 Ahib(1041) = 538976288
 Ahib(1042) = 1250067
 Ahib(1043) = 320017152
 Ahib(1044) = 19
 Ahib(1045) = 318767104
 Ahib(1046) = 1250067
 Ahib(1047) = 318767104
 Ahib(1048) = 19
 Ahib(1049) = 318767104
 Ahib(1050) = 19
 Enemy(0) = 1048704
 Enemy(6) = 320017171
 Enemy(7) = 4883
 Enemy(10) = 323043649
 Enemy(11) = 1250067
 Enemy(13) = 1094778880
 Enemy(14) = -1162167622
 Enemy(15) = 323043770
 Enemy(17) = 1094795520
 Enemy(18) = 1094826682
 Enemy(19) = 323043649
 Enemy(21) = 1090519040
 Enemy(22) = 1094795585
 Enemy(23) = 1261889
 Enemy(26) = 1094795585
 Enemy(27) = 16705
 Enemy(30) = 1916891648
 Enemy(31) = 394866
 Enemy(34) = 1920075270
 Enemy(35) = 101058054
 Enemy(38) = 108163590
 Enemy(39) = 101058054
 Enemy(40) = 6
 Enemy(41) = 1090519040
 Enemy(42) = 320017171
 Enemy(43) = 1094783763
 Enemy(44) = 6
 Enemy(45) = 1090519040
 Enemy(46) = 101058054
 Enemy(47) = 1094795526
 Enemy(48) = 6
 Enemy(50) = 101058054
 Enemy(51) = 1094780422
 Enemy(54) = 319161856
 Enemy(55) = 101058054
 Enemy(58) = 320017152
 Enemy(59) = 1250067
 Enemy(62) = 320017171
 Enemy(63) = 1250067
 Enemy(66) = 1048704
 Enemy(72) = 320017171
 Enemy(73) = 4883
 Enemy(76) = 323043649
 Enemy(77) = 1250067
 Enemy(79) = 1094778880
 Enemy(80) = -1162167622
 Enemy(81) = 323043770
 Enemy(83) = 1094795520
 Enemy(84) = 1094826682
 Enemy(85) = 323043649
 Enemy(87) = 1090519040
 Enemy(88) = 1094795585
 Enemy(89) = 1261889
 Enemy(92) = 1094795585
 Enemy(93) = 16705
 Enemy(95) = 16705
 Enemy(96) = 1916891648
 Enemy(97) = 101058162
 Enemy(98) = 6
 Enemy(99) = 104939841
 Enemy(100) = 1920075270
 Enemy(101) = 101058054
 Enemy(102) = 4276486
 Enemy(103) = 101073217
 Enemy(104) = 108163590
 Enemy(105) = 394758
 Enemy(106) = 4276545
 Enemy(108) = 320017171
 Enemy(109) = 1250067
 Enemy(110) = 4276480
 Enemy(111) = 100663296
 Enemy(112) = 101058054
 Enemy(113) = 101058054
 Enemy(115) = 101913363
 Enemy(116) = 101058054
 Enemy(117) = 101058054
 Enemy(118) = 6
 Enemy(119) = 320017152
 Enemy(120) = 1542
 Enemy(121) = 101058048
 Enemy(122) = 4883
 Enemy(123) = 320012288
 Enemy(125) = 318767104
 Enemy(126) = 4883
 Enemy(129) = 320012288
 Enemy(130) = 19
 Enemy(132) = 1048704
 Enemy(138) = 320017171
 Enemy(139) = 4883
 Enemy(142) = 323043649
 Enemy(143) = 1250067
 Enemy(145) = 1094778880
 Enemy(146) = -1162167622
 Enemy(147) = 323043770
 Enemy(149) = 1094795520
 Enemy(150) = 1094826682
 Enemy(151) = 323043649
 Enemy(153) = 1090519040
 Enemy(154) = 1094795585
 Enemy(155) = 1261889
 Enemy(158) = 1094795585
 Enemy(159) = 16705
 Enemy(162) = 1916891648
 Enemy(163) = 394866
 Enemy(166) = 1920075270
 Enemy(167) = 101058054
 Enemy(170) = 108163590
 Enemy(171) = 101058054
 Enemy(172) = 6
 Enemy(173) = 1090519040
 Enemy(174) = 320017171
 Enemy(175) = 1094783763
 Enemy(176) = 6
 Enemy(177) = 1090519040
 Enemy(178) = 101058054
 Enemy(179) = 1094795526
 Enemy(180) = 6
 Enemy(182) = 101058054
 Enemy(183) = 1094780422
 Enemy(186) = 320017152
 Enemy(187) = 101058054
 Enemy(190) = 320017171
 Enemy(191) = 1250067
 Enemy(194) = 318767104
 Enemy(195) = 1250067
 Enemy(198) = 1048704
 Enemy(204) = 320017171
 Enemy(205) = 4883
 Enemy(208) = 323043649
 Enemy(209) = 1250067
 Enemy(211) = 1094778880
 Enemy(212) = -1162167622
 Enemy(213) = 323043770
 Enemy(215) = 1094795520
 Enemy(216) = 1094826682
 Enemy(217) = 323043649
 Enemy(219) = 1090519040
 Enemy(220) = 1094795585
 Enemy(221) = 1261889
 Enemy(224) = 1094795585
 Enemy(225) = 16705
 Enemy(228) = 1916891648
 Enemy(229) = 394866
 Enemy(232) = 1920075264
 Enemy(233) = 101058054
 Enemy(236) = 1098019334
 Enemy(237) = 101058113
 Enemy(240) = 1094783763
 Enemy(241) = 394817
 Enemy(243) = 100663296
 Enemy(244) = 1090913798
 Enemy(245) = 101058113
 Enemy(247) = 320017152
 Enemy(248) = 101058054
 Enemy(249) = 101058054
 Enemy(250) = 6
 Enemy(251) = 320012288
 Enemy(252) = 1555
 Enemy(253) = 101058048
 Enemy(254) = 4883
 Enemy(255) = 318767104
 Enemy(256) = 19
 Enemy(257) = 318767104
 Enemy(258) = 4883
 Enemy(261) = 320012288
 Enemy(262) = 19
 Enemy(264) = 1048704
 Enemy(270) = 320012288
 Enemy(271) = 320017171
 Enemy(274) = 320017152
 Enemy(275) = 1094795539
 Enemy(278) = -1170128621
 Enemy(279) = -1162167622
 Enemy(280) = 16705
 Enemy(282) = 1094795539
 Enemy(283) = -1162198719
 Enemy(284) = 4276545
 Enemy(286) = 1094783744
 Enemy(287) = 1094795585
 Enemy(288) = 65
 Enemy(290) = 1094778880
 Enemy(291) = 1094795585
 Enemy(294) = 1912997376
 Enemy(295) = 7487858
 Enemy(298) = 101058054
 Enemy(299) = 101085810
 Enemy(301) = 100663296
 Enemy(302) = 101058054
 Enemy(303) = 108163590
 Enemy(305) = 100663296
 Enemy(306) = 320028993
 Enemy(307) = 320017171
 Enemy(308) = 65
 Enemy(309) = 100663296
 Enemy(310) = 104939841
 Enemy(311) = 101058054
 Enemy(312) = 65
 Enemy(314) = 101073217
 Enemy(315) = 101058054
 Enemy(318) = 101058054
 Enemy(319) = 394771
 Enemy(322) = 320017152
 Enemy(323) = 1250067
 Enemy(326) = 320017152
 Enemy(327) = 320017171
 Enemy(330) = 1048704
 Enemy(336) = 320012288
 Enemy(337) = 320017171
 Enemy(340) = 320017152
 Enemy(341) = 1094795539
 Enemy(344) = -1170128621
 Enemy(345) = -1162167622
 Enemy(346) = 16705
 Enemy(348) = 1094795539
 Enemy(349) = -1162198719
 Enemy(350) = 4276545
 Enemy(352) = 1094783744
 Enemy(353) = 1094795585
 Enemy(354) = 65
 Enemy(356) = 1094778880
 Enemy(357) = 1094795585
 Enemy(359) = 100663296
 Enemy(360) = 1912997382
 Enemy(361) = 7487858
 Enemy(362) = 1094778880
 Enemy(363) = 104939776
 Enemy(364) = 101058054
 Enemy(365) = 101085810
 Enemy(366) = 1094795526
 Enemy(367) = 1094795520
 Enemy(368) = 101058048
 Enemy(369) = 108163590
 Enemy(370) = 1094780422
 Enemy(371) = 4276480
 Enemy(372) = 320017152
 Enemy(373) = 320017171
 Enemy(376) = 101058054
 Enemy(377) = 101058054
 Enemy(378) = 6
 Enemy(379) = 100663296
 Enemy(380) = 101058054
 Enemy(381) = 101058054
 Enemy(382) = 320017158
 Enemy(383) = 320012288
 Enemy(384) = 394758
 Enemy(385) = 101056512
 Enemy(386) = 1250067
 Enemy(387) = 320012288
 Enemy(388) = 19
 Enemy(390) = 4883
 Enemy(391) = 318767104
 Enemy(392) = 4883
 Enemy(396) = 1048704
 Enemy(402) = 320012288
 Enemy(403) = 320017171
 Enemy(406) = 320017152
 Enemy(407) = 1094795539
 Enemy(410) = -1170128621
 Enemy(411) = -1162167622
 Enemy(412) = 16705
 Enemy(414) = 1094795539
 Enemy(415) = -1162198719
 Enemy(416) = 4276545
 Enemy(418) = 1094783744
 Enemy(419) = 1094795585
 Enemy(420) = 65
 Enemy(422) = 1094778880
 Enemy(423) = 1094795585
 Enemy(426) = 1912997376
 Enemy(427) = 7487858
 Enemy(430) = 101058054
 Enemy(431) = 101085810
 Enemy(433) = 100663296
 Enemy(434) = 101058054
 Enemy(435) = 108163590
 Enemy(437) = 100663296
 Enemy(438) = 320028993
 Enemy(439) = 320017171
 Enemy(440) = 65
 Enemy(441) = 100663296
 Enemy(442) = 104939841
 Enemy(443) = 101058054
 Enemy(444) = 65
 Enemy(446) = 101073217
 Enemy(447) = 101058054
 Enemy(450) = 101058054
 Enemy(451) = 1250067
 Enemy(454) = 320017152
 Enemy(455) = 320017171
 Enemy(458) = 320017152
 Enemy(459) = 19
 Enemy(462) = 1048704
 Enemy(468) = 320012288
 Enemy(469) = 320017171
 Enemy(472) = 320017152
 Enemy(473) = 1094795539
 Enemy(476) = -1170128621
 Enemy(477) = -1162167622
 Enemy(478) = 16705
 Enemy(480) = 1094795539
 Enemy(481) = -1162198719
 Enemy(482) = 4276545
 Enemy(484) = 1094783744
 Enemy(485) = 1094795585
 Enemy(486) = 65
 Enemy(488) = 1094778880
 Enemy(489) = 1094795585
 Enemy(492) = 1912997376
 Enemy(493) = 7487858
 Enemy(496) = 101058054
 Enemy(497) = 422514
 Enemy(500) = 1090913798
 Enemy(501) = 108163649
 Enemy(504) = 1090913792
 Enemy(505) = 320028993
 Enemy(508) = 1090913798
 Enemy(509) = 101058113
 Enemy(510) = 6
 Enemy(511) = 100663296
 Enemy(512) = 101058054
 Enemy(513) = 101058054
 Enemy(514) = 1250067
 Enemy(515) = 320012288
 Enemy(516) = 394758
 Enemy(517) = 319160320
 Enemy(518) = 4883
 Enemy(519) = 320012288
 Enemy(520) = 19
 Enemy(521) = 318767104
 Enemy(522) = 19
 Enemy(523) = 318767104
 Enemy(524) = 4883
 Enemy(528) = 1048704
 Enemy(534) = 320017152
 Enemy(535) = 1091769107
 Enemy(536) = 65
 Enemy(538) = 320017171
 Enemy(539) = 320017171
 Enemy(540) = 65
 Enemy(542) = 320017171
 Enemy(543) = 320017171
 Enemy(544) = 6
 Enemy(546) = 320017171
 Enemy(547) = 320017171
 Enemy(548) = 1542
 Enemy(550) = 320017217
 Enemy(551) = 1091769107
 Enemy(552) = 1542
 Enemy(554) = 1094795520
 Enemy(555) = 104939841
 Enemy(556) = 6
 Enemy(557) = 100663296
 Enemy(558) = 1920102918
 Enemy(559) = 108163698
 Enemy(560) = 6
 Enemy(561) = 101056512
 Enemy(562) = 101058054
 Enemy(563) = 101058054
 Enemy(565) = 101056512
 Enemy(566) = 101058067
 Enemy(567) = 101058054
 Enemy(568) = 19
 Enemy(570) = 320017158
 Enemy(571) = 320017171
 Enemy(572) = 1542
 Enemy(573) = 100663296
 Enemy(574) = 101058054
 Enemy(575) = 101058054
 Enemy(576) = 1542
 Enemy(577) = 100663296
 Enemy(578) = 394758
 Enemy(579) = 101058048
 Enemy(580) = 6
 Enemy(581) = 100663296
 Enemy(582) = 101058054
 Enemy(583) = 320017152
 Enemy(584) = 19
 Enemy(586) = 320017158
 Enemy(587) = 6
 Enemy(590) = 320017171
 Enemy(591) = 19
 Enemy(594) = 1048704
 Enemy(599) = 1090519040
 Enemy(600) = 320017217
 Enemy(601) = 1250067
 Enemy(603) = 1090519040
 Enemy(604) = 320017171
 Enemy(605) = 320017171
 Enemy(607) = 100663296
 Enemy(608) = 320017171
 Enemy(609) = 320017171
 Enemy(611) = 101056512
 Enemy(612) = 320017171
 Enemy(613) = 320017171
 Enemy(615) = 101056512
 Enemy(616) = 320017217
 Enemy(617) = 1091769107
 Enemy(619) = 100663296
 Enemy(620) = 1094795526
 Enemy(621) = 4276545
 Enemy(623) = 100663296
 Enemy(624) = 1920102918
 Enemy(625) = 108163698
 Enemy(626) = 6
 Enemy(628) = 101058054
 Enemy(629) = 101058054
 Enemy(630) = 1542
 Enemy(631) = 318767104
 Enemy(632) = 101058054
 Enemy(633) = 319161862
 Enemy(634) = 1542
 Enemy(635) = 101056512
 Enemy(636) = 320017171
 Enemy(637) = 101913363
 Enemy(639) = 101056512
 Enemy(640) = 101058054
 Enemy(641) = 101058054
 Enemy(642) = 6
 Enemy(643) = 100663296
 Enemy(644) = 394758
 Enemy(645) = 101058048
 Enemy(646) = 6
 Enemy(647) = 318767104
 Enemy(648) = 1250067
 Enemy(649) = 101058054
 Enemy(650) = 6
 Enemy(652) = 100663296
 Enemy(653) = 101913363
 Enemy(656) = 318767104
 Enemy(657) = 320017171
 Enemy(660) = 1048704
 Enemy(670) = 320017152
 Enemy(671) = 19
 Enemy(674) = 101058054
 Enemy(675) = 394758
 Enemy(677) = 100663296
 Enemy(678) = 320017171
 Enemy(679) = 320017171
 Enemy(681) = 319160320
 Enemy(682) = 101058054
 Enemy(683) = 101058054
 Enemy(684) = 19
 Enemy(685) = 101058048
 Enemy(686) = 101058054
 Enemy(687) = 101058054
 Enemy(688) = 6
 Enemy(689) = 101058048
 Enemy(690) = 101058054
 Enemy(691) = 101058054
 Enemy(692) = 1542
 Enemy(693) = 104939776
 Enemy(694) = 101058054
 Enemy(695) = 101058054
 Enemy(696) = 1542
 Enemy(697) = 104939841
 Enemy(698) = 101058054
 Enemy(699) = 101058054
 Enemy(700) = 4261382
 Enemy(701) = 100663296
 Enemy(702) = 101058054
 Enemy(703) = 101058048
 Enemy(704) = 6
 Enemy(706) = 101058054
 Enemy(707) = 320017158
 Enemy(708) = 19
 Enemy(710) = 101058054
 Enemy(711) = 320017158
 Enemy(714) = 320013824
 Enemy(715) = 19
 Enemy(718) = 320017152
 Enemy(719) = 4883
 Enemy(722) = 320012288
 Enemy(723) = 4883
 Enemy(726) = 1048704
 Enemy(732) = 320017152
 Enemy(733) = 1250067
 Enemy(736) = 1094795539
 Enemy(737) = 323043603
 Enemy(740) = -1162167622
 Enemy(741) = -1162167622
 Enemy(744) = 1102756417
 Enemy(745) = 1102756417
 Enemy(748) = 1094795585
 Enemy(749) = 1094795585
 Enemy(752) = 1094795520
 Enemy(753) = 4276545
 Enemy(755) = 101056512
 Enemy(756) = 1920102918
 Enemy(757) = 108163649
 Enemy(758) = 1542
 Enemy(759) = 101058048
 Enemy(760) = 1912997382
 Enemy(761) = 108163698
 Enemy(762) = 394758
 Enemy(763) = 409921
 Enemy(764) = 1920102918
 Enemy(765) = 101058162
 Enemy(766) = 1094780416
 Enemy(767) = 16705
 Enemy(768) = 320017171
 Enemy(769) = 320017171
 Enemy(770) = 1094778880
 Enemy(771) = 65
 Enemy(772) = 101058054
 Enemy(773) = 101058054
 Enemy(774) = 1090519040
 Enemy(775) = 100663296
 Enemy(776) = 101058054
 Enemy(777) = 101058054
 Enemy(778) = 6
 Enemy(779) = 100663296
 Enemy(780) = 1542
 Enemy(781) = 101056512
 Enemy(782) = 6
 Enemy(783) = 318767104
 Enemy(784) = 1555
 Enemy(785) = 319160320
 Enemy(786) = 19
 Enemy(787) = 320012288
 Enemy(788) = 4883
 Enemy(789) = 320012288
 Enemy(790) = 4883
 Enemy(792) = 1048704
 Enemy(798) = 320012288
 Enemy(799) = 4883
 Enemy(802) = 1094783744
 Enemy(803) = 1261843
 Enemy(806) = -1162198784
 Enemy(807) = 12237377
 Enemy(810) = 1094795520
 Enemy(811) = 4276545
 Enemy(814) = 1094778880
 Enemy(815) = 16705
 Enemy(817) = 100663296
 Enemy(818) = 1920102918
 Enemy(819) = 108163649
 Enemy(820) = 6
 Enemy(821) = 101056512
 Enemy(822) = 101058054
 Enemy(823) = 101085810
 Enemy(824) = 1542
 Enemy(825) = 409856
 Enemy(826) = 1920075264
 Enemy(827) = 394866
 Enemy(828) = 4261376
 Enemy(829) = 16705
 Enemy(830) = 320017152
 Enemy(831) = 1250067
 Enemy(832) = 1094778880
 Enemy(834) = 101058048
 Enemy(835) = 394758
 Enemy(838) = 394758
 Enemy(839) = 101058048
 Enemy(842) = 1542
 Enemy(843) = 101056512
 Enemy(846) = 1555
 Enemy(847) = 319160320
 Enemy(849) = 318767104
 Enemy(850) = 4883
 Enemy(851) = 320012288
 Enemy(852) = 19
 Enemy(858) = 1048704
 Enemy(860) = 318767104
 Enemy(861) = 19
 Enemy(864) = 1094778880
 Enemy(865) = 16659
 Enemy(868) = -1162215424
 Enemy(869) = 47681
 Enemy(872) = 1094778880
 Enemy(873) = 16705
 Enemy(876) = 1090519040
 Enemy(877) = 65
 Enemy(880) = 1920073728
 Enemy(881) = 29249
 Enemy(883) = 100663296
 Enemy(884) = 101058054
 Enemy(885) = 101058162
 Enemy(886) = 6
 Enemy(887) = 393216
 Enemy(888) = 1912995840
 Enemy(889) = 1542
 Enemy(890) = 1536
 Enemy(891) = 16640
 Enemy(892) = 1920073728
 Enemy(893) = 29298
 Enemy(894) = 4259840
 Enemy(896) = 394752
 Enemy(897) = 394752
 Enemy(900) = 1542
 Enemy(901) = 101056512
 Enemy(904) = 6
 Enemy(905) = 100663296
 Enemy(908) = 19
 Enemy(909) = 318767104
 Enemy(911) = 318767104
 Enemy(912) = 19
 Enemy(913) = 318767104
 Enemy(914) = 19
 Enemy(924) = 1048704
 Enemy(946) = 318767104
 Enemy(947) = 19
 Enemy(950) = 1090519040
 Enemy(951) = 65
 Enemy(954) = 1912602624
 Enemy(955) = 65
 Enemy(958) = 101058054
 Enemy(959) = 101058162
 Enemy(961) = 1090519040
 Enemy(962) = 1912602624
 Enemy(963) = 6
 Enemy(964) = 65
 Enemy(966) = 100663296
 Enemy(967) = 6
 Enemy(970) = 393216
 Enemy(971) = 1536
 Enemy(974) = 1536
 Enemy(975) = 393216
 Enemy(978) = 19
 Enemy(979) = 318767104
 Enemy(990) = 1048704
 Enemy(1024) = 318767104
 Enemy(1028) = 1090519040
 Enemy(1032) = 101056512
 Enemy(1033) = 6
 Enemy(1036) = 318783744
 Enemy(1037) = 16640
 Enemy(1040) = 393216
 Enemy(1041) = 6
 Enemy(1044) = 1245184
 Enemy(1045) = 19
 Object(0) = 1048704
 Object(1) = 387389207
 Object(2) = 387389207
 Object(3) = 387389207
 Object(4) = 387389207
 Object(5) = 353703189
 Object(6) = 353703189
 Object(7) = 353703189
 Object(8) = 353703189
 Object(9) = 353702675
 Object(10) = 320017685
 Object(11) = 353702675
 Object(12) = 320017685
 Object(13) = 353566720
 Object(14) = 4885
 Object(15) = 353566720
 Object(16) = 4885
 Object(17) = 352321536
 Object(18) = 21
 Object(19) = 352321536
 Object(20) = 21
 Object(21) = 353697792
 Object(22) = 5397
 Object(23) = 353697792
 Object(24) = 5397
 Object(25) = 353703189
 Object(26) = 353703189
 Object(27) = 353703189
 Object(28) = 353703189
 Object(29) = 320017171
 Object(30) = 320017171
 Object(31) = 320017171
 Object(32) = 320017171
 Object(66) = 1048704
 Object(67) = 387389207
 Object(68) = 1920075285
 Object(69) = 364540530
 Object(70) = 387389207
 Object(71) = 353703189
 Object(72) = -1174405101
 Object(73) = 385876154
 Object(74) = 353703189
 Object(75) = 353702675
 Object(76) = 1920075283
 Object(77) = 398094962
 Object(78) = 320017685
 Object(79) = 353566720
 Object(80) = -1174405101
 Object(81) = 385876154
 Object(82) = 4885
 Object(83) = 352321536
 Object(84) = 1920075283
 Object(85) = 398094962
 Object(86) = 21
 Object(87) = 353697792
 Object(88) = -1174405101
 Object(89) = 385876154
 Object(90) = 5397
 Object(91) = 353703189
 Object(92) = 1920075283
 Object(93) = 398094962
 Object(94) = 353703189
 Object(95) = 320017171
 Object(96) = -1174405101
 Object(97) = 352321722
 Object(98) = 320017171
 Object(132) = 1048704
 Object(133) = 1912995840
 Object(136) = 29190
 Object(137) = 1912995840
 Object(138) = 101058054
 Object(139) = 101058054
 Object(140) = 29190
 Object(141) = 1912995840
 Object(144) = 29190
 Object(145) = 1912995840
 Object(148) = 29190
 Object(149) = 1912995840
 Object(152) = 29190
 Object(153) = 1912995840
 Object(154) = 101058054
 Object(155) = 101058054
 Object(156) = 29190
 Object(157) = 1912995840
 Object(160) = 29190
 Object(161) = 1912995840
 Object(164) = 29190
 Object(165) = 1912995840
 Object(168) = 29190
 Object(169) = 1912995840
 Object(170) = 101058054
 Object(171) = 101058054
 Object(172) = 29190
 Object(173) = 1912995840
 Object(176) = 29190
 Object(177) = 1912995840
 Object(180) = 29190
 Object(181) = 1912995840
 Object(184) = 29190
 Object(185) = 1912995840
 Object(186) = 101058054
 Object(187) = 101058054
 Object(188) = 29190
 Object(189) = 1912995840
 Object(192) = 29190
 Object(193) = 1912995840
 Object(196) = 29190
 Object(198) = 1048704
 Object(199) = 23
 Object(200) = 385875968
 Object(201) = 23
 Object(202) = 385875968
 Object(203) = 5888
 Object(204) = 1507328
 Object(205) = 5888
 Object(206) = 1507328
 Object(207) = 1507328
 Object(208) = 5888
 Object(209) = 1507328
 Object(210) = 5888
 Object(211) = 436207616
 Object(212) = 23
 Object(213) = 436207616
 Object(214) = 23
 Object(215) = 385875968
 Object(216) = 23
 Object(217) = 385875968
 Object(218) = 23
 Object(219) = 1507328
 Object(220) = 5888
 Object(221) = 1507328
 Object(222) = 5888
 Object(223) = 5888
 Object(224) = 1507328
 Object(225) = 5888
 Object(226) = 1507328
 Object(227) = 23
 Object(228) = 436207616
 Object(229) = 23
 Object(230) = 436207616
 Object(231) = 23
 Object(232) = 385875968
 Object(233) = 23
 Object(234) = 385875968
 Object(235) = 5888
 Object(236) = 1507328
 Object(237) = 5888
 Object(238) = 1507328
 Object(239) = 1507328
 Object(240) = 5888
 Object(241) = 1507328
 Object(242) = 5888
 Object(243) = 436207616
 Object(244) = 23
 Object(245) = 436207616
 Object(246) = 23
 Object(247) = 385875968
 Object(248) = 23
 Object(249) = 385875968
 Object(250) = 23
 Object(251) = 1507328
 Object(252) = 5888
 Object(253) = 1507328
 Object(254) = 5888
 Object(255) = 5888
 Object(256) = 1507328
 Object(257) = 5888
 Object(258) = 1507328
 Object(259) = 23
 Object(260) = 436207616
 Object(261) = 23
 Object(262) = 436207616
 Object(264) = 1048704
 Object(287) = -1150091264
 Object(288) = 115
 Object(291) = 29461
 Object(294) = 320017152
 Object(295) = 4885
 Object(298) = 320017171
 Object(299) = 4883
 Object(301) = 318767104
 Object(302) = 320017685
 Object(303) = 1250067
 Object(305) = 318767104
 Object(306) = 320017685
 Object(307) = 1250067
 Object(309) = 318767104
 Object(310) = 320017171
 Object(311) = 1250067
 Object(313) = 318767104
 Object(314) = 320017173
 Object(315) = 1249555
 Object(318) = 320017171
 Object(319) = 4881
 Object(322) = 320017152
 Object(323) = 19
 Object(330) = 1048704
 Object(354) = 42
 Object(355) = 707406336
 Object(356) = 42
 Object(357) = 10752
 Object(358) = 10794
 Object(359) = 707395584
 Object(360) = 704653866
 Object(361) = 707406336
 Object(362) = 10794
 Object(363) = 724183552
 Object(364) = 707406378
 Object(365) = 707395626
 Object(366) = 10795
 Object(367) = 741026346
 Object(368) = 707471915
 Object(369) = 724183594
 Object(370) = 2763307
 Object(371) = 741026602
 Object(372) = 724249388
 Object(373) = 741026347
 Object(374) = 2763307
 Object(375) = 741092138
 Object(376) = 741092396
 Object(377) = 741092139
 Object(378) = 2763564
 Object(379) = 741026602
 Object(380) = 741092396
 Object(381) = 741092396
 Object(382) = 2763563
 Object(383) = 724249130
 Object(384) = 724249387
 Object(385) = 724249387
 Object(386) = 2763307
 Object(387) = 707406336
 Object(388) = 707406378
 Object(389) = 707406378
 Object(390) = 10794
 Object(396) = 1048704
 Object(398) = 42
 Object(402) = 42
 Object(406) = 10794
 Object(407) = 2752512
 Object(410) = 10794
 Object(411) = 2752512
 Object(414) = 10794
 Object(415) = 2752512
 Object(416) = 42
 Object(418) = 2763306
 Object(419) = 2763264
 Object(420) = 10794
 Object(422) = 707406634
 Object(423) = 707471914
 Object(424) = 10794
 Object(425) = 704643072
 Object(426) = 707472170
 Object(427) = 707472170
 Object(428) = 10795
 Object(429) = 704643072
 Object(430) = 724314923
 Object(431) = 724249643
 Object(432) = 42
 Object(433) = 724172800
 Object(434) = 741092395
 Object(435) = 707472428
 Object(436) = 42
 Object(437) = 724249088
 Object(438) = 741092396
 Object(439) = 724249644
 Object(440) = 2752554
 Object(441) = 724249088
 Object(442) = 741092396
 Object(443) = 724315180
 Object(444) = 2763307
 Object(445) = 724183552
 Object(446) = 741092395
 Object(447) = 724249644
 Object(448) = 10794
 Object(449) = 707406336
 Object(450) = 724249387
 Object(451) = 707472171
 Object(452) = 10794
 Object(453) = 707395584
 Object(454) = 707406378
 Object(455) = 707406378
 Object(456) = 42
 Object(462) = 1048704
 Object(464) = 2752512
 Object(466) = 42
 Object(468) = 704643072
 Object(469) = 704643072
 Object(472) = 707395584
 Object(473) = 707395584
 Object(476) = 707395584
 Object(477) = 2763264
 Object(480) = 707471872
 Object(481) = 2763306
 Object(483) = 2752512
 Object(484) = 724249088
 Object(485) = 2763562
 Object(487) = 2752512
 Object(488) = 741026602
 Object(489) = 707406635
 Object(491) = 707395584
 Object(492) = 741092139
 Object(493) = 707406636
 Object(495) = 707395584
 Object(496) = 741092395
 Object(497) = 707472172
 Object(499) = 707395584
 Object(500) = 741092395
 Object(501) = 707472428
 Object(502) = 42
 Object(503) = 704643072
 Object(504) = 741092138
 Object(505) = 724249644
 Object(506) = 42
 Object(507) = 704643072
 Object(508) = 741092138
 Object(509) = 707472428
 Object(510) = 42
 Object(511) = 707395584
 Object(512) = 741092395
 Object(513) = 707472172
 Object(514) = 42
 Object(515) = 707395584
 Object(516) = 724249386
 Object(517) = 707406635
 Object(519) = 704643072
 Object(520) = 707406378
 Object(521) = 2763306
 Object(528) = 1048704
 Object(529) = 387389207
 Object(530) = 21
 Object(531) = 352321536
 Object(532) = 387389207
 Object(533) = 353703189
 Object(534) = 19
 Object(535) = 385875968
 Object(536) = 353703189
 Object(537) = 353702675
 Object(538) = 393235
 Object(539) = 385877504
 Object(540) = 320017685
 Object(541) = 353566720
 Object(542) = 100664851
 Object(543) = 385875968
 Object(544) = 4885
 Object(545) = 352321536
 Object(546) = 19
 Object(547) = 386269184
 Object(548) = 21
 Object(549) = 353697792
 Object(550) = 19
 Object(551) = 385875974
 Object(552) = 5397
 Object(553) = 353703189
 Object(554) = 19
 Object(555) = 385875968
 Object(556) = 353703189
 Object(557) = 320017171
 Object(558) = 19
 Object(559) = 352321536
 Object(560) = 320017171
 Object(594) = 1048704
 Object(595) = 387389207
 Object(596) = 21
 Object(597) = 352321536
 Object(598) = 387389207
 Object(599) = 353703189
 Object(600) = 19
 Object(601) = 385875968
 Object(602) = 353703189
 Object(603) = 353702675
 Object(604) = 7471123
 Object(605) = 385875968
 Object(606) = 320017685
 Object(607) = 353566720
 Object(608) = 19
 Object(609) = 385905152
 Object(610) = 4885
 Object(611) = 352321536
 Object(612) = 29203
 Object(613) = 385875968
 Object(614) = 21
 Object(615) = 353697792
 Object(616) = 1912602643
 Object(617) = 385875968
 Object(618) = 5397
 Object(619) = 353703189
 Object(620) = 19
 Object(621) = 385875968
 Object(622) = 353703189
 Object(623) = 320017171
 Object(624) = 19
 Object(625) = 352321650
 Object(626) = 320017171
 Object(660) = 1048704
 Object(661) = 387389207
 Object(662) = 21
 Object(663) = 352321536
 Object(664) = 387389207
 Object(665) = 353703189
 Object(666) = 19
 Object(667) = 385875968
 Object(668) = 353703189
 Object(669) = 353702675
 Object(670) = 19
 Object(671) = 385875968
 Object(672) = 320017685
 Object(673) = 353566720
 Object(674) = 12189715
 Object(675) = 385875968
 Object(676) = 4885
 Object(677) = 352321536
 Object(678) = 19
 Object(679) = 385875968
 Object(680) = 21
 Object(681) = 353697792
 Object(682) = 19
 Object(683) = 385923584
 Object(684) = 5397
 Object(685) = 353703189
 Object(686) = 47635
 Object(687) = 385875968
 Object(688) = 353703189
 Object(689) = 320017171
 Object(690) = 19
 Object(691) = 352321536
 Object(692) = 320017171
 Object(694) = -1174405120
 Object(707) = 186
 Object(726) = 1048704
 Object(727) = 387389207
 Object(728) = 21
 Object(729) = 352321536
 Object(730) = 387389207
 Object(731) = 353703189
 Object(732) = 19
 Object(733) = 385875968
 Object(734) = 353703189
 Object(735) = 353702675
 Object(736) = 19
 Object(737) = 385875968
 Object(738) = 320017685
 Object(739) = 353566720
 Object(740) = 19
 Object(741) = 385875968
 Object(742) = 4885
 Object(743) = 352321536
 Object(744) = 19
 Object(745) = 385875968
 Object(746) = 21
 Object(747) = 353697792
 Object(748) = 19
 Object(749) = 385875968
 Object(750) = 5397
 Object(751) = 353703189
 Object(752) = 19
 Object(753) = 385875968
 Object(754) = 353703189
 Object(755) = 320017171
 Object(756) = 19
 Object(757) = 352321536
 Object(758) = 320017171
 Object(792) = 1048704
 Object(793) = 67372144
 Object(794) = 67372036
 Object(795) = 67372036
 Object(796) = 1879311364
 Object(797) = 1886416900
 Object(798) = 1886417008
 Object(799) = 1886417008
 Object(800) = -1200590736
 Object(801) = 1886416900
 Object(802) = 1886417008
 Object(803) = 1886417008
 Object(804) = -1200590736
 Object(805) = 1886416900
 Object(806) = 1886417008
 Object(807) = 1886417008
 Object(808) = -1200590736
 Object(809) = 1886416900
 Object(810) = 1886417008
 Object(811) = 1886417008
 Object(812) = -1200590736
 Object(813) = 1886416900
 Object(814) = 1886417008
 Object(815) = 1886417008
 Object(816) = -1200590736
 Object(817) = 1886416900
 Object(818) = 1886417008
 Object(819) = 1886417008
 Object(820) = -1200590736
 Object(821) = 1886416900
 Object(822) = 1886417008
 Object(823) = 1886417008
 Object(824) = -1200590736
 Object(825) = 1886416900
 Object(826) = 1886417008
 Object(827) = 1886417008
 Object(828) = -1200590736
 Object(829) = 1886416900
 Object(830) = 1886417008
 Object(831) = 1886417008
 Object(832) = -1200590736
 Object(833) = 1886416900
 Object(834) = 1886417008
 Object(835) = 1886417008
 Object(836) = -1200590736
 Object(837) = 1886416900
 Object(838) = 1886417008
 Object(839) = 1886417008
 Object(840) = -1200590736
 Object(841) = 1886416900
 Object(842) = 1886417008
 Object(843) = 1886417008
 Object(844) = -1200590736
 Object(845) = 1886416900
 Object(846) = 1886417008
 Object(847) = 1886417008
 Object(848) = -1200590736
 Object(849) = 1886416900
 Object(850) = 1886417008
 Object(851) = 1886417008
 Object(852) = -1200590736
 Object(853) = -1195853712
 Object(854) = -1195853640
 Object(855) = -1195853640
 Object(856) = 12105912
 Object(858) = 1048704
 Object(859) = 67109888
 Object(860) = 262148
 Object(861) = 263172
 Object(862) = 1879049220
 Object(863) = 7340032
 Object(864) = 28784
 Object(865) = 7340032
 Object(866) = 112
 Object(867) = 1879048196
 Object(868) = 1886388336
 Object(869) = 7368704
 Object(870) = -1200590848
 Object(871) = 1879048196
 Object(872) = 7368704
 Object(873) = 7368816
 Object(874) = -1207930880
 Object(875) = 7340032
 Object(876) = 1886388224
 Object(877) = 1886388336
 Object(878) = -1207930768
 Object(880) = 1879048192
 Object(881) = 1879076864
 Object(882) = 7340032
 Object(883) = 7368708
 Object(885) = 28784
 Object(886) = 28672
 Object(887) = 28672
 Object(888) = 1879076976
 Object(889) = 1879076976
 Object(890) = -1200619520
 Object(891) = 1886416896
 Object(893) = 1886417008
 Object(894) = 7340144
 Object(895) = 1879076868
 Object(896) = 1886417008
 Object(897) = 1879048192
 Object(898) = -1207930768
 Object(899) = 1886388224
 Object(900) = 1879076864
 Object(901) = 1879076864
 Object(902) = -1207959440
 Object(903) = 1886388224
 Object(905) = 1879048192
 Object(906) = -1207930880
 Object(907) = 1879048196
 Object(908) = 7368704
 Object(909) = 7340032
 Object(910) = -1207959552
 Object(911) = 28676
 Object(912) = 112
 Object(913) = 1886417008
 Object(914) = 28672
 Object(915) = 7368704
 Object(916) = 1886388224
 Object(918) = -1207959440
 Object(921) = -1207912264
 Object(922) = 12058624
 Object(924) = 1048704
 Object(925) = 262144
 Object(926) = 262144
 Object(928) = 1024
 Object(930) = 1879048192
 Object(931) = 28672
 Object(932) = 7340032
 Object(933) = 28672
 Object(934) = 7340144
 Object(935) = 7340032
 Object(936) = 7340032
 Object(937) = 7340032
 Object(940) = 112
 Object(941) = 28676
 Object(942) = 1879048192
 Object(943) = 28672
 Object(945) = 28672
 Object(947) = 7340032
 Object(948) = 112
 Object(949) = 1879048196
 Object(954) = 112
 Object(957) = 1879048196
 Object(962) = 1886388224
 Object(964) = -1207930880
 Object(965) = 7340032
 Object(970) = 112
 Object(971) = 7340144
 Object(975) = 28784
 Object(977) = 4
 Object(978) = 7340144
 Object(979) = 1879076864
 Object(980) = 28672
 Object(982) = 28672
 Object(985) = -1207959552
 Object(986) = -1207959552
 Object(987) = 47104
 Object(988) = 12058624
 Object(990) = 1048704
 Object(992) = 262144
 Object(995) = 7340032
 Object(996) = 28784
 Object(999) = 4
 Object(1008) = 1879048192
 Object(1009) = 1879048192
 Object(1015) = 7340032
 Object(1018) = 28672
 Object(1030) = 112
 Object(1038) = 28672
 Object(1039) = 1879048192
 Object(1043) = 4
 Object(1045) = 28672
 Object(1046) = 28672
 Object(1047) = 7368704
END SUB

SUB Initialize
 FOR I = 0 TO 1056
  Object(I) = 0
 NEXT I
 FOR I = 0 TO 1056
  Ahib(I) = 0
 NEXT I
 FOR I = 0 TO 1056
  Enemy(I) = 0
 NEXT I
 FOR I = 0 TO 66
  Nothing(I) = 0
 NEXT I
 InitArray
 Snd(0) = "T207MBMNL16O3 BECBECBECBFDBFDBFDBGFBGFBGF>P64C4"
 Snd(1) = "T127MBMLL32O3 BP16A#P64BP64A#P64BP64A#P64BP64GP16F#P64GP64F#P64GP64F#P64GP64EP64FP64F#P64GEP64FP64F#P64GEP16C<P16A#16>P8"
 Snd(2) = "T159MBMNL4 O2 CF1G>DC3F1F6ECD1D6C<FA1P3CF1G>DC3F1F6GCA1A6A#G>C1P3"
 Snd(3) = "T207MBMLL64O2 ED#DC#C"
 Snd(4) = "T159MBMLL32O5 <B>G<B<G>>"
 Snd(5) = "T159MBMNL32O3 ED#DC#C<BA#AG#GF#FED#DC#C<BA#AG#GF#FED#DC#C>>"
 Snd(6) = "T255MBMNL64O0 B>B>B>B>B>B>B"
 Snd(7) = "T255MBMNL64O6 B<B<B<B<B<B<B"
 Snd(8) = "T255MBMNL64O2 GEC<GECP64>GEC<GECP64>GEC<GEC"
 Snd(9) = "T159MBMNL16O4 CCCC8DE8ED8CF6F6F8E4CCCC8DE8ED8CF6E8C2CCCC8DE8ED8CF6F6F8E4cccc8de8ed8cf6e8c2<CCCC8DE8ED8CD8ED8C<B8AG6>CCCC8DE8ED8CD8ED8C<A3>CCCC8DE8ED8CD8ED8C<B8AG6>G4FE6D6C2>"
 Cheat(0) = "_BTLIVES_"
 Cheat(1) = "_BTBOMBS_"
 Cheat(2) = "_BTNODEATH_"
 Cheat(3) = "_BTSTOPTIME_"
 Cheat(4) = "_BTREFILL_"
 Cheat(5) = "_BTKILLTHEM_"
 Cheat(6) = "_BTBACKWARD_"
 Cheat(7) = "_BTGIVEBOMBS_"
 Cheat(8) = "_BTGIVEHEALTH_"
 Cheat(9) = "_BTGIVELIVES_"
 Cheat(10) = "_BTGIVETIME_"
 Cheat(11) = "_BTSPEED_"
 Cheat(12) = "_BTWARPLEVEL_"
 Cheat(13) = "_BTWINGAME_"
 Cheat(14) = "_BTLOSEGAME_"
 Cheat(15) = "_BTISEEYOU_"
 Cheat(16) = "_BTJUKEBOX_"
 CheatDesc(0) = "Infinite lives"
 CheatDesc(1) = "Infinite bombs"
 CheatDesc(2) = "Invincibility"
 CheatDesc(3) = "Stop timer"
 CheatDesc(4) = "Refill everything"
 CheatDesc(5) = "Remove enemies"
 CheatDesc(6) = "Backward movement"
 CheatDesc(7) = "Get 10 bombs"
 CheatDesc(8) = "Get full health"
 CheatDesc(9) = "Get maximum lives"
 CheatDesc(10) = "Get +100 time"
 CheatDesc(11) = "Double player speed"
 CheatDesc(12) = "Warp to a level"
 CheatDesc(13) = "Forced 'Win'"
 CheatDesc(14) = "Forced 'Loss'"
 CheatDesc(15) = "Invisibility"
 CheatDesc(16) = "Play game sounds"
END SUB

SUB MapEditor
 CLS
 GET (0, 0)-(15, 15), Temp
 Skip = FALSE
 FOR Y = 1 TO 12
  FOR X = 1 TO 20
   EditMap(X, Y) = " "
 NEXT X, Y
 X = 1
 Y = 1
 I = 1
 I$ = "Nothing"
 DO
  IX$ = ""
  K$ = INKEY$
  IF K$ <> "" THEN
   SELECT CASE K$
    CASE CHR$(0) + "H", "w", "W", "z", "Z": IX$ = "H"
    CASE CHR$(0) + "P", "s", "S":          IX$ = "P"
    CASE CHR$(0) + "K", "a", "A", "q", "Q": IX$ = "K"
    CASE CHR$(0) + "M", "d", "D":          IX$ = "M"
    CASE CHR$(9):                          IX$ = CHR$(15)
    CASE " ":                              IX$ = "9"
    CASE "x", "X":                         IX$ = "-"
    CASE "e", "E", "d", "D":               IX$ = " "
    CASE "l", "L":                         IX$ = "&"
    CASE CHR$(27):                         IX$ = CHR$(1)
   END SELECT
  END IF
  IF IX$ = "" THEN
   RawSc% = INP(96)
   IF RawSc% <> 0 THEN IX$ = CHR$(RawSc%)
  END IF
  SELECT CASE IX$
   CASE "H"
    PUT (FNC(X), FNC(Y)), Temp, PSET
    IF Y > 1 THEN Y = Y - 1 ELSE Y = 12
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
    Skip = TRUE
   CASE "P"
    PUT (FNC(X), FNC(Y)), Temp, PSET
    IF Y < 12 THEN Y = Y + 1 ELSE Y = 1
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
    Skip = TRUE
   CASE "K"
    PUT (FNC(X), FNC(Y)), Temp, PSET
    IF X > 1 THEN X = X - 1 ELSE X = 20
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
    Skip = TRUE
   CASE "M"
    PUT (FNC(X), FNC(Y)), Temp, PSET
    IF X < 20 THEN X = X + 1 ELSE X = 1
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
    Skip = TRUE
   CASE CHR$(15)
    IF NOT Skip THEN
     IF I > 1 THEN I = I - 1 ELSE I = 8
    ELSE
     Skip = FALSE
    END IF
    SELECT CASE I
     CASE 1
      PutObject FNC(X), FNC(Y), -1
      EditMap(X, Y) = " "
      I$ = "Nothing"
     CASE 2
      PutObject FNC(X), FNC(Y), 0
      EditMap(X, Y) = "Û"
      I$ = "Platform"
     CASE 3
      PutObject FNC(X), FNC(Y), 1
      EditMap(X, Y) = "±"
      I$ = "Connection point"
     CASE 4
      PutObject FNC(X), FNC(Y), 2
      EditMap(X, Y) = "="
      I$ = "Ladder"
     CASE 5
      PutObject FNC(X), FNC(Y), 3
      EditMap(X, Y) = "x"
      I$ = "Wire net"
     CASE 6
      PutObject FNC(X), FNC(Y), 12
      EditMap(X, Y) = "þ"
      I$ = "Block"
     CASE 7
      PutEnemy FNC(X), FNC(Y), 4
      EditMap(X, Y) = "E"
      I$ = "Enemy"
     CASE 8
      PutAhib FNC(X), FNC(Y), 4
      EditMap(X, Y) = "A"
      I$ = "Ahib"
    END SELECT
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
   CASE "9"
    IF NOT Skip THEN
     IF I < 8 THEN I = I + 1 ELSE I = 1
    ELSE
     Skip = FALSE
    END IF
    SELECT CASE I
     CASE 1
      PutObject FNC(X), FNC(Y), -1
      EditMap(X, Y) = " "
      I$ = "Nothing"
     CASE 2
      PutObject FNC(X), FNC(Y), 0
      EditMap(X, Y) = "Û"
      I$ = "Platform"
     CASE 3
      PutObject FNC(X), FNC(Y), 1
      EditMap(X, Y) = "±"
      I$ = "Connection point"
     CASE 4
      PutObject FNC(X), FNC(Y), 2
      EditMap(X, Y) = "="
      I$ = "Ladder"
     CASE 5
      PutObject FNC(X), FNC(Y), 3
      EditMap(X, Y) = "x"
      I$ = "Wire net"
     CASE 6
      PutObject FNC(X), FNC(Y), 12
      EditMap(X, Y) = "þ"
      I$ = "Block"
     CASE 7
      PutEnemy FNC(X), FNC(Y), 4
      EditMap(X, Y) = "E"
      I$ = "Enemy"
     CASE 8
      PutAhib FNC(X), FNC(Y), 4
      EditMap(X, Y) = "A"
      I$ = "Ahib"
    END SELECT
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
   CASE "-"
    CLS
    FOR IY = 1 TO 12
     FOR IX = 1 TO 20
      EditMap(IX, IY) = " "
    NEXT IX, IY
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
   CASE ""
    PUT (FNC(X), FNC(Y)), Temp, PSET
    LOCATE 25, 1
    INPUT ; "Level number"; Level
    LOCATE 25, 1
    PRINT SPACE$(40);
    IF Level < 1 THEN EXIT SUB
    OPEN "bt" + Zero$(Level, 3) + ".Map" FOR OUTPUT AS #1
     FOR IY = 1 TO 12
      FOR IX = 1 TO 20
       PRINT #1, EditMap(IX, IY);
      NEXT IX
      PRINT #1,
     NEXT IY
    CLOSE #1
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
   CASE "&"
    PUT (FNC(X), FNC(Y)), Temp, PSET
    LOCATE 25, 1
    INPUT ; "Level number"; Level
    LOCATE 25, 1
    PRINT SPACE$(40);
    FOR IY = 1 TO 12
     FOR IX = 1 TO 20
      EditMap(IX, IY) = " "
    NEXT IX, IY
    IF Level < 1 THEN EXIT SUB
    IF Exist("bt" + Zero$(Level, 3) + ".Map") THEN
     OPEN "I", 1, "bt" + Zero$(Level, 3) + ".Map"
      FOR IY = 1 TO 12
       LINE INPUT #1, I$
       FOR IX = 1 TO 20
        EditMap(IX, IY) = MID$(I$, IX, 1)
      NEXT IX, IY
     CLOSE #1
    END IF
    CLS
    FOR IY = 1 TO 12
     FOR IX = 1 TO 20
      SELECT CASE EditMap(IX, IY)
       CASE " "
        PutObject FNC(IX), FNC(IY), -1
       CASE "Û"
        PutObject FNC(IX), FNC(IY), 0
       CASE "±"
        PutObject FNC(IX), FNC(IY), 1
       CASE "="
        PutObject FNC(IX), FNC(IY), 2
       CASE "x"
        PutObject FNC(IX), FNC(IY), 3
       CASE "þ"
        PutObject FNC(IX), FNC(IY), 12
       CASE "E"
        PutEnemy FNC(IX), FNC(IY), 4
       CASE "A"
        PutAhib FNC(IX), FNC(IY), 4
      END SELECT
    NEXT IX, IY
    GET (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), Temp
   CASE CHR$(1)
    EXIT SUB
  END SELECT
  LINE (FNC(X), FNC(Y))-(FNC(X) + 15, FNC(Y) + 15), 55, B
  I$ = I$ + SPACE$(39 - LEN(I$))
  LOCATE 25, 1
  PRINT I$;
  WaitKey
 LOOP
END SUB

SUB Message (I$)
 LOCATE 25, 1
 PRINT SPACE$(40);
 Center I$, 25
 WaitKey
 LOCATE 25, 1
 PRINT SPACE$(40);
END SUB

SUB MoveEnemy (EnemyNumber)
 SELECT CASE BadGuy(EnemyNumber).Action
  CASE 1
   SELECT CASE BadGuy(EnemyNumber).Dir
    CASE 1
     PutNothing BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY
     IF CheckEnemyXY(EnemyNumber) THEN
      BadGuy(EnemyNumber).Y = BadGuy(EnemyNumber).Y - 1
     END IF
     BadGuy(EnemyNumber).TestMove = BadGuy(EnemyNumber).TestMove + 1
    CASE 2
     PutNothing BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY
     IF CheckEnemyXY(EnemyNumber) THEN
      BadGuy(EnemyNumber).Y = BadGuy(EnemyNumber).Y + 1
     END IF
     BadGuy(EnemyNumber).TestMove = BadGuy(EnemyNumber).TestMove + 1
    CASE 3
     PutNothing BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY
     IF CheckEnemyXY(EnemyNumber) THEN
      BadGuy(EnemyNumber).X = BadGuy(EnemyNumber).X - 1
     END IF
     BadGuy(EnemyNumber).TestMove = BadGuy(EnemyNumber).TestMove + 1
    CASE 4
     PutNothing BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY
     IF CheckEnemyXY(EnemyNumber) THEN
      BadGuy(EnemyNumber).X = BadGuy(EnemyNumber).X + 1
     END IF
     BadGuy(EnemyNumber).TestMove = BadGuy(EnemyNumber).TestMove + 1
   END SELECT
  CASE 2
   PutNothing BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY
   BadGuy(EnemyNumber).Y = BadGuy(EnemyNumber).Y + 2
   BadGuy(EnemyNumber).TestFall = BadGuy(EnemyNumber).TestFall + 2
  CASE ELSE
   EXIT SUB
 END SELECT
 IF BadGuy(EnemyNumber).TestMove = 16 THEN
  BadGuy(EnemyNumber).Action = 0
  BadGuy(EnemyNumber).TestMove = 0
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Enemy = FALSE
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).EnemyNumber = 0
  SELECT CASE BadGuy(EnemyNumber).Dir
   CASE 1
    IF CheckEnemyXY(EnemyNumber) THEN BadGuy(EnemyNumber).MapY = BadGuy(EnemyNumber).MapY - 1
   CASE 2
    IF CheckEnemyXY(EnemyNumber) THEN BadGuy(EnemyNumber).MapY = BadGuy(EnemyNumber).MapY + 1
   CASE 3
    IF CheckEnemyXY(EnemyNumber) THEN BadGuy(EnemyNumber).MapX = BadGuy(EnemyNumber).MapX - 1
   CASE 4
    IF CheckEnemyXY(EnemyNumber) THEN BadGuy(EnemyNumber).MapX = BadGuy(EnemyNumber).MapX + 1
  END SELECT
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Enemy = TRUE
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).EnemyNumber = EnemyNumber
  BadGuy(EnemyNumber).X = FNC(BadGuy(EnemyNumber).MapX)
  BadGuy(EnemyNumber).Y = FNC(BadGuy(EnemyNumber).MapY)
 END IF
 IF BadGuy(EnemyNumber).TestFall = 16 THEN
  BadGuy(EnemyNumber).Action = 0
  BadGuy(EnemyNumber).TestFall = 0
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Enemy = FALSE
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).EnemyNumber = 0
  BadGuy(EnemyNumber).MapY = BadGuy(EnemyNumber).MapY + 1
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).Enemy = TRUE
  Map(BadGuy(EnemyNumber).MapX, BadGuy(EnemyNumber).MapY).EnemyNumber = EnemyNumber
  BadGuy(EnemyNumber).Y = FNC(BadGuy(EnemyNumber).MapY)
 END IF
END SUB

SUB MovePlayer
 SELECT CASE Player.Action
  CASE 1
   SELECT CASE Player.Dir
    CASE 1
     IF Player.Moving THEN PutNothing Player.MapX, Player.MapY
     IF CheckPlayerXY THEN
      Player.Y = Player.Y - Player.Speed
      Player.Moving = TRUE
     ELSE
      Player.Moving = FALSE
     END IF
     Player.TestMove = Player.TestMove + Player.Speed
    CASE 2
     IF Player.Moving THEN PutNothing Player.MapX, Player.MapY
     IF CheckPlayerXY THEN
      Player.Y = Player.Y + Player.Speed
      Player.Moving = TRUE
     ELSE
      Player.Moving = FALSE
     END IF
     Player.TestMove = Player.TestMove + Player.Speed
    CASE 3
     IF Player.Moving THEN PutNothing Player.MapX, Player.MapY
     IF CheckPlayerXY THEN
      Player.X = Player.X - Player.Speed
      Player.Moving = TRUE
     ELSE
      Player.Moving = FALSE
     END IF
     Player.TestMove = Player.TestMove + Player.Speed
    CASE 4
     IF Player.Moving THEN PutNothing Player.MapX, Player.MapY
     IF CheckPlayerXY THEN
      Player.X = Player.X + Player.Speed
      Player.Moving = TRUE
     ELSE
      Player.Moving = FALSE
     END IF
     Player.TestMove = Player.TestMove + Player.Speed
   END SELECT
  CASE 2
   IF Player.Bombs > 0 THEN
    IF Game.SoundOn THEN PLAY Snd(3)
    FOR I = 1 TO 10
     IF NOT Bomb(I).Exist THEN GOTO Ok
    NEXT I
    GOTO Set
Ok:
    Bomb(I).Time = 0
    Bomb(I).Boom = 0
    Bomb(I).X = Player.X
    Bomb(I).Y = Player.Y
    Bomb(I).MapX = Player.MapX
    Bomb(I).MapY = Player.MapY
    Bomb(I).Exist = TRUE
    Bomb(I).DestroyCount = 0
    IF NOT Player.InfiniteBombs THEN Player.Bombs = Player.Bombs - 1 ELSE Player.Bombs = 1
   END IF
Set:
   Player.Action = 0
  CASE 3
   PutNothing Player.MapX, Player.MapY
   Player.Y = Player.Y + Player.Speed * 2
   Player.TestFall = Player.TestFall + Player.Speed * 2
  CASE ELSE
   EXIT SUB
 END SELECT
 IF Player.TestMove = 16 THEN
  Player.Action = 0
  Player.TestMove = 0
  Map(Player.MapX, Player.MapY).Ahib = FALSE
  SELECT CASE Player.Dir
   CASE 1
    IF CheckPlayerXY THEN Player.MapY = Player.MapY - 1
   CASE 2
    IF CheckPlayerXY THEN Player.MapY = Player.MapY + 1
   CASE 3
    IF CheckPlayerXY THEN Player.MapX = Player.MapX - 1
   CASE 4
    IF CheckPlayerXY THEN Player.MapX = Player.MapX + 1
  END SELECT
  Map(Player.MapX, Player.MapY).Ahib = TRUE
  Player.X = FNC(Player.MapX)
  Player.Y = FNC(Player.MapY)
 END IF
 IF Player.TestFall = 16 THEN
  Player.Action = 0
  Player.TestFall = 0
  Map(Player.MapX, Player.MapY).Ahib = FALSE
  Player.MapY = Player.MapY + 1
  Map(Player.MapX, Player.MapY).Ahib = TRUE
  Player.Y = FNC(Player.MapY)
 END IF
END SUB

SUB Pause (Time)
 IF Time <= 1 THEN
  SLEEP 0.025
 ELSE
  dur! = (65 - Time) * 0.03
  IF dur! > 0 THEN SLEEP dur!
 END IF
END SUB

SUB PlayerLose (Level)
 FOR Y = Player.MapY TO 11
  FOR X = 0 TO 15 STEP 2
   PutNothing Player.MapX, Y
   PutAhib FNC(Player.MapX), FNC(Y) + X, 15
   Pause 1
  NEXT X
  PutNothing Player.MapX, Y
 NEXT Y
 IF Game.SoundOn THEN PLAY Snd(5)
 Player.Health = 10
 IF NOT Player.InfiniteLives THEN Player.Lives = Player.Lives - 1
 CLS
 COLOR 15
 I$ = "LEVEL " + FNTrim$(Level)
 Center I$, 13
 IF Game.SoundOn THEN PLAY Snd(7)
 PutAhib 153, 80, 15
 COLOR 41
 Center "Failed", 14
 WaitKey
 SOUND 0, 0
END SUB

SUB PlayerWin (Level)
 FOR I = 0 TO 1
  PutAhib Player.X, Player.Y, 10 + I
  SOUND 0, 0
  Pause 60
 NEXT I
 SOUND 0, 0
 Pause 60
 CLS
 COLOR 15
 I$ = "LEVEL " + FNTrim$(Level)
 Center I$, 13
 IF Game.SoundOn THEN PLAY Snd(4)
 COLOR 48
 Center "Completed", 14
 PutAhib 153, 80, 11
 IF Level MOD 10 = 0 THEN
  IF Player.Lives < 10 THEN Player.Lives = Player.Lives + 1
 END IF
 FOR I = 1 TO INT(RND * 3) + 1
  IF Player.Health < 10 THEN Player.Health = Player.Health + 1
 NEXT I
 WaitKey
 SOUND 0, 0
END SUB

SUB PutAhib (X, Y, Z)
 IF Z > -1 THEN
  PUT (X, Y), Ahib(Z * 66), PSET
 ELSE
  PUT (X, Y), Nothing, PSET
 END IF
END SUB

SUB PutEnemy (X, Y, Z)
 IF Z > -1 THEN
  PUT (X, Y), Enemy(Z * 66), PSET
 ELSE
  PUT (X, Y), Nothing, PSET
 END IF
END SUB

SUB PutNothing (IX, IY)
 SELECT CASE Map(IX, IY).Object
  CASE 0
   PutObject FNC(IX), FNC(IY), -1
  CASE 3
   PutObject FNC(IX), FNC(IY), 2
  CASE 4
   PutObject FNC(IX), FNC(IY), 3
  CASE 6
   PutObject FNC(IX), FNC(IY), 11
 END SELECT
END SUB

SUB PutObject (X, Y, Z)
 IF Z > -1 THEN
  PUT (X, Y), Object(Z * 66), PSET
 ELSE
  PUT (X, Y), Nothing, PSET
 END IF
END SUB

SUB RandomMap (Level)
 FOR Y = 1 TO 12
  FOR X = 1 TO 20
   Map(X, Y).Element = " "
 NEXT X, Y
 FOR I = 1 TO INT(RND * 15) + 1
  IX = INT(RND * 20) + 1
  IY = INT(RND * 8) + 5
  IF Map(IX, IY).Element = " " THEN Map(IX, IY).Element = "±"
  IF I MOD 3 = 0 THEN IF IX > 1 THEN Map(IX - 1, IY).Element = "="
 NEXT I
 FOR I = 1 TO 30
  IX = INT(RND * 17) + 1
  IY = INT(RND * 11) + 2
  IF IY < 12 THEN
   IF Map(IX, IY + 1).Element = " " AND Map(IX + 1, IY + 1).Element = " " AND Map(IX + 2, IY + 1).Element = " " AND Map(IX, IY - 1).Element = " " AND Map(IX + 1, IY - 1).Element = " " AND Map(IX + 2, IY - 1).Element = " " THEN
    FOR J = 0 TO INT(RND * 4)
     IF IY + 1 < 12 AND (IX + J) <= 20 THEN Map(IX + J, IY + 1).Element = "Û"
    NEXT J
   END IF
  END IF
  K = INT(RND * 2) + 1
  SELECT CASE K
   CASE 1
    Y = IY
    DO UNTIL Map(IX, Y).Element = "Û" OR Y = 12
     Y = Y + 1
     IF IX > 1 THEN Map(IX - 1, Y).Element = "="
    LOOP
   CASE 2
    Y = IY
    DO UNTIL Map(IX, Y).Element = "Û" OR Y = 12
     Y = Y + 1
     nj = IX + J - 1: IF nj >= 1 AND nj <= 20 THEN Map(nj, Y).Element = "="
    LOOP
  END SELECT
 NEXT I
 FOR I = 1 TO INT(RND * 20) + 1
  IX = INT(RND * 20) + 1
  IY = INT(RND * 11) + 2
  IF Map(IX, IY).Element = " " THEN Map(IX, IY).Element = "Û"
 NEXT I
 FOR I = 1 TO 50
  IX = INT(RND * 20) + 1
  IY = INT(RND * 12) + 1
  IF Map(IX, IY).Element = " " OR Map(IX, IY).Element = "Û" THEN Map(IX, IY).Element = "x"
 NEXT I
 FOR I = 1 TO INT(RND * 15) + 1
  IX = INT(RND * 20) + 1
  IY = INT(RND * 12) + 1
  IF Map(IX, IY).Element = " " OR Map(IX, IY).Element = "Û" THEN Map(IX, IY).Element = "þ"
 NEXT I
 FOR I = 1 TO 20
  Map(I, 12).Element = "Û"
 NEXT I
 FOR I = 1 TO INT(RND * 10) + 1
  Map(INT(RND * 20) + 1, INT(RND * 11) + 1).Element = "E"
 NEXT I
 IX = INT(RND * 20) + 1
 IY = 5 + INT(RND * 6) + 1
 Map(IX, IY).Element = "A"
 FOR I = 1 TO 30
  IX = INT(RND * 20) + 1
  IY = INT(RND * 12) + 1
  IF Map(IX, IY).Element = " " OR Map(IX, IY).Element = "Û" THEN Map(IX, IY).Element = "="
 NEXT I
 Map(INT(RND * 8) + 5, INT(RND * 8) + 5).Element = "±"
END SUB

SUB ReadMap (Level)
 ResetMap
 IF NOT Exist("bt" + Zero$(Level, 3) + ".map") THEN
  RandomMap Level
 ELSE
  OPEN "bt" + Zero$(Level, 3) + ".map" FOR INPUT AS #1
   FOR Y = 1 TO 12
    LINE INPUT #1, I$
    FOR X = 1 TO 20
     Map(X, Y).Element = MID$(I$, X, 1)
   NEXT X, Y
  CLOSE #1
 END IF
END SUB

SUB ResetMap
 FOR Y = 1 TO 12
  FOR X = 1 TO 20
   Map(X, Y).Object = 0
   Map(X, Y).Enemy = FALSE
   Map(X, Y).EnemyNumber = 0
   Map(X, Y).Ahib = FALSE
   Map(X, Y).Element = " "
 NEXT X, Y
 FOR I = 1 TO 10
  Bomb(I).Exist = FALSE
 NEXT I
END SUB

FUNCTION SetEnemyFrame (EnemyNumber)
 SELECT CASE BadGuy(EnemyNumber).Dir
  CASE 1, 2
   IF BadGuy(EnemyNumber).TestMove = 0 THEN
    SetEnemyFrame = 10
   ELSE
    SELECT CASE INT(BadGuy(EnemyNumber).TestMove / 4)
     CASE 0, 2
      SetEnemyFrame = 8
     CASE 1, 3
      SetEnemyFrame = 9
    END SELECT
   END IF
  CASE 3, 4
   IF Game.MoveBackward THEN
    IF BadGuy(EnemyNumber).Dir = 4 THEN I = 3
    IF BadGuy(EnemyNumber).Dir = 3 THEN I = 4
   ELSE
    I = BadGuy(EnemyNumber).Dir
   END IF
   SetEnemyFrame = ((I - 3) * 4) + INT(BadGuy(EnemyNumber).TestMove / 4)
 END SELECT
END FUNCTION

FUNCTION SetPlayerFrame
 IF Player.JustHit THEN
  IF Player.JustHitFrame = 2 THEN
   SetPlayerFrame = -1
   Player.JustHitFrame = 1
   EXIT FUNCTION
  ELSE
   Player.JustHitFrame = 2
  END IF
 END IF
 SELECT CASE Player.Dir
  CASE 1, 2
   IF Player.TestMove = 0 THEN
    IF Player.Dir = 1 THEN
     SetPlayerFrame = 8
    ELSE
     IF NOT Player.Moving THEN
      SetPlayerFrame = 9
     ELSE
      SetPlayerFrame = 8
     END IF
    END IF
   ELSEIF Player.TestMove <= 4 THEN
    IF Player.MapY < 12 AND Player.Dir = 2 THEN
     IF Map(Player.MapX, Player.MapY).Object = 0 AND Map(Player.MapX, Player.MapY + 1).Object = 3 THEN
      SetPlayerFrame = 14
     ELSE
      GOTO GetFrame
     END IF
    ELSE
     GOTO GetFrame
    END IF
   ELSEIF Player.TestMove >= 12 THEN
    IF Player.MapY > 1 AND Player.Dir = 1 THEN
     IF Map(Player.MapX, Player.MapY).Object = 3 AND Map(Player.MapX, Player.MapY - 1).Object = 0 THEN
      SetPlayerFrame = 14
     ELSE
      GOTO GetFrame
     END IF
    ELSE
     GOTO GetFrame
    END IF
   ELSE
    GOTO GetFrame
   END IF
  CASE 3, 4
   IF Game.MoveBackward THEN
    IF Player.Dir = 4 THEN I = 3
    IF Player.Dir = 3 THEN I = 4
   ELSE
    I = Player.Dir
   END IF
   SetPlayerFrame = ((I - 3) * 4) + INT(Player.TestMove / 4)
 END SELECT
 EXIT FUNCTION
GetFrame:
 SELECT CASE INT(Player.TestMove / 4)
  CASE 0, 2
   IF Player.Moving THEN
    SetPlayerFrame = 12
   ELSE
    IF Player.Dir = 1 THEN
     SetPlayerFrame = 8
    ELSE
     SetPlayerFrame = 9
    END IF
   END IF
  CASE 1, 3
   IF Player.Moving THEN
    SetPlayerFrame = 13
   ELSE
    IF Player.Dir = 1 THEN
     SetPlayerFrame = 8
    ELSE
     SetPlayerFrame = 9
    END IF
   END IF
 END SELECT
END FUNCTION

SUB WaitKey
 WHILE INKEY$ <> ""
  SLEEP 0.01
 WEND
 DO
  IF INKEY$ <> "" THEN EXIT SUB
  IF INP(96) <> 0 THEN EXIT SUB
  SLEEP 0.02
 LOOP
END SUB

FUNCTION Zero$ (Number, Length)
  IF LEN(FNTrim$(Number)) <= Length THEN
    Zero$ = STRING$(Length - LEN(FNTrim$(Number)), "0") + FNTrim$(Number)
  ELSE
    Zero$ = STRING$(Length, "0")
  END IF
END FUNCTION

