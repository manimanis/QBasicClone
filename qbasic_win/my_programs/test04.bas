DEF FnRan (x) = INT(RND(1) * x) + 1

FOR i = 1 TO 20
  w = FnRan(100) - 50
  PRINT w
NEXT i