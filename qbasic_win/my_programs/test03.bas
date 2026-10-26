let xa = 5 : xb = 50
let ya = 3 : yb = 8

for i = xa to xb
 for j = ya to yb
'   PRINT i, j, i = xa or i = xb or j = ya or j = yb
  if i = xa or i = xb or j = ya or j = yb then
    COLOR 2 : LOCATE j, i : print "*";
    ' print i, j, "outside"
  else
    COLOR 1 : LOCATE j, i : print "+";
    ' print i, j, "inside"
  end if
 next j
next i

SLEEP 3

END