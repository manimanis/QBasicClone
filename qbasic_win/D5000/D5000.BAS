DECLARE SUB ChargGraphDes ()
DECLARE SUB CombienDeJoueur ()
DECLARE SUB InscriptionJoueur ()
DECLARE SUB JFondEcran5000 ()
DECLARE SUB LanceDes ()
DECLARE SUB WCalcul ()
DECLARE SUB XJoueur ()
DECLARE SUB YDepassement5000 ()
DECLARE SUB ZBravo5000Juste ()

SCREEN 9
CLS

DIM Des1(408), Des2(408), Des3(408), Des4(408), Des5(408), Des6(408)
DIM Nom1(130), Nom2(130), Nom3(130), Nom4(130)
DIM Nom5(130), Nom6(130), Nom7(130), Nom8(130)
DIM EffDes1(440), EffDes2(440), EffDes3(440)

ChargGraphDes
CombienDeJoueur
InscriptionJoueur
'----------------------------------------------------
L = 0: M = 0
  GET (200 - L, 295 + M)-(262 - L, 349 + M), EffDes1
  GET (300, 245 + M)-(362, 299 + M), EffDes2
  GET (400 + L, 295 + M)-(462 + L, 349 + M), EffDes3
'---------------------------------<  D E B U T  >----

Taux = 0: Total = 0: Tals = 0: NJ = N: N = 1
COD$ = "P E R D U": Compt = 0: Game$ = "OFF": U$ = "OFF"
Score1 = 0: Score2 = 0: Score3 = 0: Score4 = 0
Score5 = 0: Score6 = 0: Score7 = 0: Score8 = 0
RANDOMIZE TIMER
DO
   D1 = 0: D2 = 0: D3 = 0
   D1 = INT(RND * 6) + 1
   D2 = INT(RND * 6) + 1
   D3 = INT(RND * 6) + 1
   LOCATE 1, 37: PRINT D1; D2; D3
   IF Game$ = "ON" THEN
      IF D1 <> 0 THEN LanceDes
      WCalcul
      XJoueur
      LOCATE 11, 37: PRINT USING "  ####   "; Taux
      LOCATE 12, 37: PRINT USING "+ ####   "; Total
      IF Tals <> 0 THEN LOCATE 14, 37: PRINT USING "  ####   "; Tals
      ZBravo5000Juste
      YDepassement5000
      IF Total = 0 THEN
         Taux = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$
         IF N = 1 THEN LOCATE 16, 21: PRINT USING "####"; Score1
         IF N = 2 THEN LOCATE 18, 21: PRINT USING "####"; Score2
         IF N = 3 THEN LOCATE 20, 21: PRINT USING "####"; Score3
         IF N = 4 THEN LOCATE 22, 21: PRINT USING "####"; Score4
         IF N = 5 THEN LOCATE 16, 58: PRINT USING "####"; Score5
         IF N = 6 THEN LOCATE 18, 58: PRINT USING "####"; Score6
         IF N = 7 THEN LOCATE 20, 58: PRINT USING "####"; Score7
         IF N = 8 THEN LOCATE 22, 58: PRINT USING "####"; Score8
         COLOR 15
         N = N + 1
         IF N > NJ THEN N = 1
      END IF
   END IF
   U$ = "OFF"
   DO
      A$ = INKEY$
      IF A$ = CHR$(27) THEN END
      IF A$ = CHR$(13) THEN Game$ = "ON": U$ = "ON"
      IF A$ = CHR$(32) AND (D1 <> D2 OR D1 <> D3) THEN
         IF N = 1 THEN Score1 = Score1 + Tals: LOCATE 16, 21: PRINT USING "####"; Score1
         IF N = 2 THEN Score2 = Score2 + Tals: LOCATE 18, 21: PRINT USING "####"; Score2
         IF N = 3 THEN Score3 = Score3 + Tals: LOCATE 20, 21: PRINT USING "####"; Score3
         IF N = 4 THEN Score4 = Score4 + Tals: LOCATE 22, 21: PRINT USING "####"; Score4
         IF N = 5 THEN Score5 = Score5 + Tals: LOCATE 16, 58: PRINT USING "####"; Score5
         IF N = 6 THEN Score6 = Score6 + Tals: LOCATE 18, 58: PRINT USING "####"; Score6
         IF N = 7 THEN Score7 = Score7 + Tals: LOCATE 20, 58: PRINT USING "####"; Score7
         IF N = 8 THEN Score8 = Score8 + Tals: LOCATE 22, 58: PRINT USING "####"; Score8
         Taux = 0: Total = 0: Tals = 0
         N = N + 1
         IF N > NJ THEN N = 1
         U$ = "ON"
      END IF
   LOOP WHILE U$ = "OFF"
   B$ = INKEY$
   c$ = INKEY$
   PUT (200 - L, 295 + M), EffDes1, PSET
   PUT (300, 245 + M), EffDes2, PSET
   PUT (400 + L, 295 + M), EffDes3, PSET
LOOP
END
'*** FIN ***

SUB ChargGraphDes
SHARED Des1(), Des2(), Des3(), Des4(), Des5(), Des6()

File$ = "Des6"
DEF SEG = &HA000
OUT &H3C4, 2: OUT &H3C5, 1: BLOAD File$ + ".BLU", 0 'bitplane 0
OUT &H3C4, 2: OUT &H3C5, 2: BLOAD File$ + ".GRN", 0 'bitplane 1
OUT &H3C4, 2: OUT &H3C5, 4: BLOAD File$ + ".RED", 0 'bitplane 2
OUT &H3C4, 2: OUT &H3C5, 8: BLOAD File$ + ".INT", 0 'bitplane 3
OUT &H3C4, 2: OUT &H3C5, 16
DEF SEG

GET (20, 9)-(79, 59), Des1: GET (120, 9)-(179, 59), Des2
GET (220, 9)-(279, 59), Des3: GET (320, 9)-(379, 59), Des4
GET (420, 9)-(479, 59), Des5: GET (520, 9)-(579, 59), Des6

END SUB

SUB CombienDeJoueur
SHARED NJ
CLS
LOCATE 4, 20: PRINT "Nombre de Joueur: "
LOCATE 5, 20: PRINT "Confirmer avec la touche [ENTER]"
x = 0
DO
    DO
        Choix$ = INKEY$
        IF Oo = 0 THEN O = 45
        IF Oo = 10000 THEN O = 95
        IF Oo > 20000 THEN Oo = -20
        LOCATE 4, 38 + x: PRINT CHR$(O)
        Oo = Oo + 1
    LOOP WHILE Choix$ = ""
  
    IF LEN(Choix$) = 1 THEN
        SELECT CASE ASC(Choix$)
            CASE 13
                EXIT DO
            CASE 27
                END
            CASE 49 TO 56
                LOCATE 4, 20: PRINT "Nombre de Joueur: "; Choix$
                J = ASC(Choix$)
                x = 1
            CASE ELSE
               Choix$ = ""
        END SELECT
    END IF
LOOP
NJ = J - 48

END SUB

SUB InscriptionJoueur
SHARED N, NJ
SHARED Nom1(), Nom2(), Nom3(), Nom4(), Nom5(), Nom6(), Nom7(), Nom8()

N = NJ
FOR Nom = 1 TO N
   LOCATE 5 + Nom, 20: PRINT "Inscrire le nom du joueur #"; Nom; ": ........"
   Car = 0
   DO
      A$ = INKEY$
      IF A$ = CHR$(27) THEN END
      IF A$ = CHR$(13) THEN LOCATE 5 + Nom, 52 + Car: PRINT STRING$(8 - Car, 46); : EXIT DO
      IF A$ = CHR$(32) THEN
         Car = Car + 1
         IF Car > 8 THEN Car = 8
         LOCATE 5 + Nom, 52 + Car: A$ = ""
      END IF
      IF A$ = CHR$(8) THEN
         Car = Car - 1
         IF Car < 0 THEN Car = 0
         LOCATE 5 + Nom, 52 + Car: PRINT ".": A$ = ""
      END IF
      IF A$ <> "" AND Car < 8 THEN
         Car = Car + 1
         LOCATE 5 + Nom, 51 + Car: PRINT UCASE$(A$);
      END IF
   LOOP
NEXT
FOR x = 404 TO 472 STEP 1: FOR y = 69 TO 182
   IF POINT(x, y) = 0 THEN PSET (x, y), 9
NEXT: NEXT
FOR x = 404 TO 472: FOR y = 69 TO 182
   IF POINT(x, y) = 15 THEN PSET (x - 2, y - 2), 15: PSET (x - 1, y - 1), 8: PSET (x, y), 0
NEXT: NEXT

GET (404, 69)-(472, 82), Nom1: GET (404, 83)-(472, 96), Nom2
GET (404, 97)-(472, 110), Nom3: GET (404, 111)-(472, 124), Nom4
GET (404, 125)-(472, 138), Nom5: GET (404, 139)-(472, 152), Nom6
GET (404, 153)-(472, 166), Nom7: GET (404, 167)-(472, 180), Nom8

JFondEcran5000 ' Afficher le Fond Ecran avec les Joueurs r`ajouter.

PUT (44, 210), Nom1, PSET: PUT (44, 238), Nom2, PSET
PUT (44, 266), Nom3, PSET: PUT (44, 294), Nom4, PSET
PUT (533, 210), Nom5, PSET: PUT (533, 238), Nom6, PSET
PUT (533, 266), Nom7, PSET: PUT (533, 294), Nom8, PSET

END SUB

SUB JFondEcran5000

File$ = "FD5000"
DEF SEG = &HA000
OUT &H3C4, 2: OUT &H3C5, 1: BLOAD File$ + ".BLU", 0 'bitplane 0
OUT &H3C4, 2: OUT &H3C5, 2: BLOAD File$ + ".GRN", 0 'bitplane 1
OUT &H3C4, 2: OUT &H3C5, 4: BLOAD File$ + ".RED", 0 'bitplane 2
OUT &H3C4, 2: OUT &H3C5, 8: BLOAD File$ + ".INT", 0 'bitplane 3
OUT &H3C4, 2: OUT &H3C5, 16
DEF SEG

END SUB

SUB LanceDes
SHARED D1, D2, D3, EffDes1(), EffDes2(), EffDes3(), L, M
SHARED Des1(), Des2(), Des3(), Des4(), Des5(), Des6()
      
         M = 0: L = -30
         D4 = INT(RND * 6) + 1
         D5 = INT(RND * 6) + 1
         D6 = INT(RND * 6) + 1
       
         FOR t = 0 TO 3
            DZ = INT(RND * 40) + 1
            L = L + DZ
            GET (200 - L, 295 + M)-(262 - L, 349 + M), EffDes1
            GET (300, 245 + M)-(362, 299 + M), EffDes2
            GET (400 + L, 295 + M)-(462 + L, 349 + M), EffDes3
         
            IF D4 = 1 THEN PUT (200 - L, 295 + M), Des1, PSET
            IF D4 = 2 THEN PUT (200 - L, 295 + M), Des2, PSET
            IF D4 = 3 THEN PUT (200 - L, 295 + M), Des3, PSET
            IF D4 = 4 THEN PUT (200 - L, 295 + M), Des4, PSET
            IF D4 = 5 THEN PUT (200 - L, 295 + M), Des5, PSET
            IF D4 = 6 THEN PUT (200 - L, 295 + M), Des6, PSET
     
            IF D5 = 1 THEN PUT (300, 245 + M), Des1, PSET
            IF D5 = 2 THEN PUT (300, 245 + M), Des2, PSET
            IF D5 = 3 THEN PUT (300, 245 + M), Des3, PSET
            IF D5 = 4 THEN PUT (300, 245 + M), Des4, PSET
            IF D5 = 5 THEN PUT (300, 245 + M), Des5, PSET
            IF D5 = 6 THEN PUT (300, 245 + M), Des6, PSET

            IF D6 = 1 THEN PUT (400 + L, 295 + M), Des1, PSET
            IF D6 = 2 THEN PUT (400 + L, 295 + M), Des2, PSET
            IF D6 = 3 THEN PUT (400 + L, 295 + M), Des3, PSET
            IF D6 = 4 THEN PUT (400 + L, 295 + M), Des4, PSET
            IF D6 = 5 THEN PUT (400 + L, 295 + M), Des5, PSET
            IF D6 = 6 THEN PUT (400 + L, 295 + M), Des6, PSET

                        FOR t2 = 0 TO 8000 STEP .5: NEXT t2
            PUT (200 - L, 295 + M), EffDes1, PSET
            PUT (300, 245 + M), EffDes2, PSET
            PUT (400 + L, 295 + M), EffDes3, PSET
            
            M = M - 55
         NEXT
            GET (200 - L, 295 + M)-(262 - L, 349 + M), EffDes1
            GET (300, 245 + M)-(362, 299 + M), EffDes2
            GET (400 + L, 295 + M)-(462 + L, 349 + M), EffDes3

         LINE (1, 348)-(638, 348), 0
         IF D1 = 1 THEN PUT (200 - L, 295 + M), Des1, PSET
         IF D1 = 2 THEN PUT (200 - L, 295 + M), Des2, PSET
         IF D1 = 3 THEN PUT (200 - L, 295 + M), Des3, PSET
         IF D1 = 4 THEN PUT (200 - L, 295 + M), Des4, PSET
         IF D1 = 5 THEN PUT (200 - L, 295 + M), Des5, PSET
         IF D1 = 6 THEN PUT (200 - L, 295 + M), Des6, PSET
      
         IF D2 = 1 THEN PUT (300, 245 + M), Des1, PSET
         IF D2 = 2 THEN PUT (300, 245 + M), Des2, PSET
         IF D2 = 3 THEN PUT (300, 245 + M), Des3, PSET
         IF D2 = 4 THEN PUT (300, 245 + M), Des4, PSET
         IF D2 = 5 THEN PUT (300, 245 + M), Des5, PSET
         IF D2 = 6 THEN PUT (300, 245 + M), Des6, PSET

         IF D3 = 1 THEN PUT (400 + L, 295 + M), Des1, PSET
         IF D3 = 2 THEN PUT (400 + L, 295 + M), Des2, PSET
         IF D3 = 3 THEN PUT (400 + L, 295 + M), Des3, PSET
         IF D3 = 4 THEN PUT (400 + L, 295 + M), Des4, PSET
         IF D3 = 5 THEN PUT (400 + L, 295 + M), Des5, PSET
         IF D3 = 6 THEN PUT (400 + L, 295 + M), Des6, PSET

END SUB

SUB WCalcul
SHARED Taux, Total, Tals, D1, D2, D3, Go
   Taux = Taux + Total
   IF D1 = 2 AND D2 = 2 AND D3 = 2 THEN Total = 200: Go = 1
   IF D1 = 3 AND D2 = 3 AND D3 = 3 THEN Total = 300: Go = 1
   IF D1 = 4 AND D2 = 4 AND D3 = 4 THEN Total = 400: Go = 1
   IF D1 = 5 AND D2 = 5 AND D3 = 5 THEN Total = 500: Go = 1
   IF D1 = 6 AND D2 = 6 AND D3 = 6 THEN Total = 600: Go = 1
   IF D1 = 1 AND D2 = 1 AND D3 = 1 THEN Total = 1000: Go = 1
   IF D1 <> 1 THEN
      IF D1 <> 5 THEN
         IF Go = 0 THEN D1 = 0
      END IF
   END IF
   IF D2 <> 1 THEN
      IF D2 <> 5 THEN
         IF Go = 0 THEN D2 = 0
      END IF
   END IF
   IF D3 <> 1 THEN
      IF D3 <> 5 THEN
         IF Go = 0 THEN D3 = 0
      END IF
   END IF
   IF D1 = 0 AND D2 = 0 AND D3 = 0 AND Go = 0 THEN Taux = 0: Total = 0: Tals = 0
   IF Go = 0 THEN
      IF D1 = 5 THEN D1 = 50
      IF D1 = 1 THEN D1 = 100
      IF D2 = 5 THEN D2 = 50
      IF D2 = 1 THEN D2 = 100
      IF D3 = 5 THEN D3 = 50
      IF D3 = 1 THEN D3 = 100
   END IF
   IF Go = 0 THEN Tals = Tals + (D1 + D2 + D3): Total = (D1 + D2 + D3)
   IF Go = 1 THEN Tals = Tals + Total
   IF Total = 0 THEN Tals = 0: Taux = 0
   Go = 0

END SUB

SUB XJoueur
SHARED N
SHARED Nom1(), Nom2(), Nom3(), Nom4(), Nom5(), Nom6(), Nom7(), Nom8()
SHARED Score1, Score2, Score3, Score4, Score5, Score6, Score7, Score8

IF N = 1 THEN PUT (290, 111), Nom1, PSET: COLOR 10: LOCATE 16, 21: PRINT USING "####"; Score1: COLOR 15
IF N = 2 THEN PUT (290, 111), Nom2, PSET: COLOR 10: LOCATE 18, 21: PRINT USING "####"; Score2: COLOR 15
IF N = 3 THEN PUT (290, 111), Nom3, PSET: COLOR 10: LOCATE 20, 21: PRINT USING "####"; Score3: COLOR 15
IF N = 4 THEN PUT (290, 111), Nom4, PSET: COLOR 10: LOCATE 22, 21: PRINT USING "####"; Score4: COLOR 15
IF N = 5 THEN PUT (290, 111), Nom5, PSET: COLOR 10: LOCATE 16, 58: PRINT USING "####"; Score5: COLOR 15
IF N = 6 THEN PUT (290, 111), Nom6, PSET: COLOR 10: LOCATE 18, 58: PRINT USING "####"; Score6: COLOR 15
IF N = 7 THEN PUT (290, 111), Nom7, PSET: COLOR 10: LOCATE 20, 58: PRINT USING "####"; Score7: COLOR 15
IF N = 8 THEN PUT (290, 111), Nom8, PSET: COLOR 10: LOCATE 22, 58: PRINT USING "####"; Score8: COLOR 15

END SUB

SUB YDepassement5000
SHARED Score1, Score2, Score3, Score4, Score5, Score6, Score7, Score8
SHARED N, NJ, Taux, Total, Tals, COD$

   IF N = 8 AND Score8 + Tals > 5000 THEN
      Score8 = Score8 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 22, 58: PRINT USING "####"; Score8
   END IF
   IF N = 7 AND Score7 + Tals > 5000 THEN
      Score7 = Score7 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 20, 58: PRINT USING "####"; Score7
   END IF
   IF N = 6 AND Score6 + Tals > 5000 THEN
      Score6 = Score6 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 18, 58: PRINT USING "####"; Score6
   END IF
   IF N = 5 AND Score5 + Tals > 5000 THEN
      Score5 = Score5 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 16, 58: PRINT USING "####"; Score5
   END IF
   IF N = 4 AND Score4 + Tals > 5000 THEN
      Score4 = Score4 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 22, 21: PRINT USING "####"; Score4
   END IF
   IF N = 3 AND Score3 + Tals > 5000 THEN
      Score3 = Score3 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 20, 21: PRINT USING "####"; Score3
   END IF
   IF N = 2 AND Score2 + Tals > 5000 THEN
      Score2 = Score2 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 18, 21: PRINT USING "####"; Score2
   END IF
   IF N = 1 AND Score1 + Tals > 5000 THEN
      Score1 = Score1 - Tals
         Taux = 0: Total = 0: Tals = 0
         LOCATE 11, 37: PRINT USING "  ####   "; Taux
         COLOR 12: LOCATE 14, 37: PRINT COD$: COLOR 15
         LOCATE 16, 21: PRINT USING "####"; Score1
   END IF

END SUB

SUB ZBravo5000Juste
SHARED Score1, Score2, Score3, Score4, Score5, Score6, Score7, Score8
SHARED L, M, N, NJ, Taux, Total, Tals, EffDes1(), EffDes2(), EffDes3()

Terminer = 0
   IF N = 8 AND Score8 + Tals = 5000 THEN
      Score8 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 22, 58: PRINT USING "####"; Score8
         Terminer = 1
   END IF
   IF N = 7 AND Score7 + Tals = 5000 THEN
      Score7 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 20, 58: PRINT USING "####"; Score7
         Terminer = 1
   END IF
   IF N = 6 AND Score6 + Tals = 5000 THEN
      Score6 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 18, 58: PRINT USING "####"; Score6
         Terminer = 1
   END IF
   IF N = 5 AND Score5 + Tals = 5000 THEN
      Score5 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 16, 58: PRINT USING "####"; Score5
         Terminer = 1
   END IF
   IF N = 4 AND Score4 + Tals = 5000 THEN
      Score4 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 22, 21: PRINT USING "####"; Score4
         Terminer = 1
   END IF
   IF N = 3 AND Score3 + Tals = 5000 THEN
      Score3 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 20, 21: PRINT USING "####"; Score3
         Terminer = 1
   END IF
   IF N = 2 AND Score2 + Tals = 5000 THEN
      Score2 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 18, 21: PRINT USING "####"; Score2
         Terminer = 1
   END IF
   IF N = 1 AND Score1 + Tals = 5000 THEN
      Score1 = 5000
         Taux = 0: Total = 0: Tals = 0
         LOCATE 16, 21: PRINT USING "####"; Score1
         Terminer = 1
   END IF
IF Terminer = 1 THEN
   PUT (200 - L, 295 + M), EffDes1, PSET
   PUT (300, 245 + M), EffDes2, PSET
   PUT (400 + L, 295 + M), EffDes3, PSET

   FOR td = 0 TO 600 STEP 1
      t = 0 + INT(RND * 106)
      c = c + 1: IF c > 8 THEN c = 0
      LINE (216 + t, 90 + t)-(430 - t, 314 - t), c, B
      c = c + 1: IF c > 8 THEN c = 0
      LINE (217 + t, 91 + t)-(429 - t, 313 - t), c + 7, BF
   NEXT td
   COLOR 1
   LOCATE 10, 38: PRINT " F I N "
   LOCATE 11, 36: PRINT "    D E    "
   LOCATE 12, 34: PRINT "  P A R T I E  "
   LOCATE 18, 37: PRINT " G A M E "
   LOCATE 19, 37: PRINT " O V E R "
   FOR x = 225 TO 425
      FOR y = 100 TO 300
         c = POINT(x, y)
         IF c = 0 THEN PSET (x, y), 10
   NEXT: NEXT
   LINE (216, 90)-(430, 314), 0, B
   LOCATE 23, 34: COLOR 15: PRINT "ESC pour finir"
   DO: LOOP WHILE INKEY$ <> CHR$(27)
   CLS : END
END IF
END SUB

