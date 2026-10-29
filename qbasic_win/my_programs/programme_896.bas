' ========================================================
' programme_896.bas
' Créé dans QBasic Studio
' ========================================================

CLS
DECLARE FUNCTION ConvBool(B AS Boolean) AS STRING

REM Exercice 3 - Partie A
A = 12
B = 5
C = 20
Ch1 = "bac"
Ch2 = "Bac"

ex1 = not (A > B) or (C \ B = 4) and not (B = 5)
PRINT "Expression 1 : " ; ConvBool(ex1)

ex2 = (Ch1 <> Ch2) and (INSTR("Abc", "a") <> 0)
PRINT "Expression 2 : " ; ConvBool(ex2)

ex3 = not ((A MOD 2 = 0) or (B > 10)) and (C >= A+B)
PRINT "Expression 3 : " ; ConvBool(ex3)

ex4 = (Ch1 > Ch2) or not(A-B <= 7)
PRINT "Expression 4 : " ; ConvBool(ex4)

ex5 = not ("A" <= "B" and "B" <= "Z") or (B MOD 2 <> 0)
PRINT "Expression 5 : " ; ConvBool(ex5)

REM Exercice 5 - Partie A
REM Question 1
INPUT "Donner votre âge : "; age
PRINT "L'année prochaine vous aurez : "; age + 1

REM Question 2
INPUT "Donner le premier nombre : "; a
INPUT "Donner le deuxième nombre : "; b
res = a + b
PRINT "Le double de la somme est : "; res * 2

REM Question 3
INPUT "Votre taille en mètres : "; taille
msg = "Votre taille est " + STR$(taille) + " m"
PRINT msg

REM Test
print "[" + str$(15.5) + "]"

END

FUNCTION ConvBool(B AS Boolean) AS STRING
  IF B THEN ConvBool = "True" ELSE ConvBool = "False"
END FUNCTION