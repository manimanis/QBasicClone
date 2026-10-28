' =====================================================================
' L'HYMNE A LA JOIE (ODE AN DIE FREUDE)
' Ludwig van Beethoven - Symphonie No. 9 en Re majeur, Op. 125
' Poeme : Friedrich von Schiller (1785) - Hymne Europeen
' Adaptation QBasic pour Synthetiseur MML PC Speaker
' =====================================================================

CLS
COLOR 14, 1
LOCATE 2, 1
PRINT " +------------------------------------------------------------------+ "
PRINT " |            LUDWIG VAN BEETHOVEN - L'HYMNE A LA JOIE              | "
PRINT " |             Symphonie No. 9 en Re Majeur, Op. 125                | "
PRINT " +------------------------------------------------------------------+ "

COLOR 11, 1
LOCATE 6, 2: PRINT "Allegro assai vivace (T136) - Re Majeur - Mode Normal (MN)"
COLOR 15, 1
LOCATE 7, 2: PRINT "--- PREMIERE STROPHE : PAROLES & TRADUCTIONS INDIVIDUELLES ---"

' Affichage initial de chaque ligne avec sa traduction a part
COLOR 7, 1
LOCATE 8,  2: PRINT "  [DE] 1. Freude, schoner Gotterfunken, Tochter aus Elysium,"
COLOR 10, 1
LOCATE 9,  2: PRINT "     [FR] Joie, belle etincelle divine, fille de l'Elysee,"

COLOR 7, 1
LOCATE 11, 2: PRINT "  [DE] 2. Wir betreten feuertrunken, Himmlische, dein Heiligtum!"
COLOR 10, 1
LOCATE 12, 2: PRINT "     [FR] Nous entrons, ivres de feu, celeste, dans ton sanctuaire !"

COLOR 7, 1
LOCATE 14, 2: PRINT "  [DE] 3. Deine Zauber binden wieder, was die Mode streng geteilt;"
COLOR 10, 1
LOCATE 15, 2: PRINT "     [FR] Tes charmes unissent a nouveau ce que la coutume a separe ;"

COLOR 7, 1
LOCATE 17, 2: PRINT "  [DE] 4. Alle Menschen werden Bruder, wo dein sanfter Flugel weilt."
COLOR 10, 1
LOCATE 18, 2: PRINT "     [FR] Tous les hommes deviennent freres sous ton aile tutelaire."

COLOR 13, 1
LOCATE 20, 2: PRINT "Lecture en cours... Suivez les paroles et leurs traductions :"
COLOR 7, 0

' ---------------------------------------------------------------------
' EXECUTION MUSICALE SYNCHRONISEE - STROPHE 1
' ---------------------------------------------------------------------

' --- Ligne 1 ---
COLOR 14, 1: LOCATE 8, 2:  PRINT "> [DE] 1. Freude, schoner Gotterfunken, Tochter aus Elysium,"
COLOR 11, 1: LOCATE 9, 2:  PRINT "  >  [FR] Joie, belle etincelle divine, fille de l'Elysee,"
PLAY "T136 MN O4 L4 f# f# g a a g f# e d d e f# f#. e8 e2"

' --- Ligne 2 ---
COLOR 15, 1: LOCATE 8, 2:  PRINT "  [DE] 1. Freude, schoner Gotterfunken, Tochter aus Elysium,"
COLOR 10, 1: LOCATE 9, 2:  PRINT "     [FR] Joie, belle etincelle divine, fille de l'Elysee,"
COLOR 14, 1: LOCATE 11, 2: PRINT "> [DE] 2. Wir betreten feuertrunken, Himmlische, dein Heiligtum!"
COLOR 11, 1: LOCATE 12, 2: PRINT "  >  [FR] Nous entrons, ivres de feu, celeste, dans ton sanctuaire !"
PLAY "f# f# g a a g f# e d d e f# e. d8 d2"

' --- Ligne 3 ---
COLOR 15, 1: LOCATE 11, 2: PRINT "  [DE] 2. Wir betreten feuertrunken, Himmlische, dein Heiligtum!"
COLOR 10, 1: LOCATE 12, 2: PRINT "     [FR] Nous entrons, ivres de feu, celeste, dans ton sanctuaire !"
COLOR 14, 1: LOCATE 14, 2: PRINT "> [DE] 3. Deine Zauber binden wieder, was die Mode streng geteilt;"
COLOR 11, 1: LOCATE 15, 2: PRINT "  >  [FR] Tes charmes unissent a nouveau ce que la coutume a separe ;"
PLAY "e e f# d e f#8 g8 f# d e f#8 g8 f# e d e <a2>"

' --- Ligne 4 ---
COLOR 15, 1: LOCATE 14, 2: PRINT "  [DE] 3. Deine Zauber binden wieder, was die Mode streng geteilt;"
COLOR 10, 1: LOCATE 15, 2: PRINT "     [FR] Tes charmes unissent a nouveau ce que la coutume a separe ;"
COLOR 14, 1: LOCATE 17, 2: PRINT "> [DE] 4. Alle Menschen werden Bruder, wo dein sanfter Flugel weilt."
COLOR 11, 1: LOCATE 18, 2: PRINT "  >  [FR] Tous les hommes deviennent freres sous ton aile tutelaire."
PLAY ">f# f# g a a g f# e d d e f# e. d8 d2 p2"

COLOR 15, 1: LOCATE 17, 2: PRINT "  [DE] 4. Alle Menschen werden Bruder, wo dein sanfter Flugel weilt."
COLOR 10, 1: LOCATE 18, 2: PRINT "     [FR] Tous les hommes deviennent freres sous ton aile tutelaire."

' ---------------------------------------------------------------------
' DEUXIEME STROPHE - SCHILLER (Reprise a l'octave superieure O5)
' ---------------------------------------------------------------------
LOCATE 7, 2:  PRINT "--- DEUXIEME STROPHE : PAROLES & TRADUCTIONS INDIVIDUELLES ---   "

' Ligne 5
COLOR 7, 1:  LOCATE 8, 2:  PRINT "  [DE] 5. Wem der grosse Wurf gelungen, eines Freundes Freund zu sein,"
COLOR 10, 1: LOCATE 9, 2:  PRINT "     [FR] Celui qui a eu le bonheur de devenir l'ami d'un ami,        "
' Ligne 6
COLOR 7, 1:  LOCATE 11, 2: PRINT "  [DE] 6. Wer ein holdes Weib errungen, mische seinen Jubel ein!     "
COLOR 10, 1: LOCATE 12, 2: PRINT "     [FR] Qui a conquis une douce compagne, qu'il joigne sa liesse !  "
' Ligne 7
COLOR 7, 1:  LOCATE 14, 2: PRINT "  [DE] 7. Ja, wer auch nur eine Seele sein nennt auf dem Erdenrund!  "
COLOR 10, 1: LOCATE 15, 2: PRINT "     [FR] Oui, meme celui qui ne possede qu'une seule ame sur terre ! "
' Ligne 8
COLOR 7, 1:  LOCATE 17, 2: PRINT "  [DE] 8. Und wer's nie gekonnt, der stehle weinend sich aus diesem! "
COLOR 10, 1: LOCATE 18, 2: PRINT "     [FR] Et que celui qui n'a pu le faire s'eloigne en pleurant !    "

' --- Ligne 5 (Mesures 17-20 : Staccato vif O5) ---
COLOR 14, 1: LOCATE 8, 2:  PRINT "> [DE] 5. Wem der grosse Wurf gelungen, eines Freundes Freund zu sein,"
COLOR 11, 1: LOCATE 9, 2:  PRINT "  >  [FR] Celui qui a eu le bonheur de devenir l'ami d'un ami,        "
PLAY "T144 MS O5 L4 f# f# g a a g f# e d d e f# MN f#. e8 e2"

' --- Ligne 6 (Mesures 21-24) ---
COLOR 15, 1: LOCATE 8, 2:  PRINT "  [DE] 5. Wem der grosse Wurf gelungen, eines Freundes Freund zu sein,"
COLOR 10, 1: LOCATE 9, 2:  PRINT "     [FR] Celui qui a eu le bonheur de devenir l'ami d'un ami,        "
COLOR 14, 1: LOCATE 11, 2: PRINT "> [DE] 6. Wer ein holdes Weib errungen, mische seinen Jubel ein!     "
COLOR 11, 1: LOCATE 12, 2: PRINT "  >  [FR] Qui a conquis une douce compagne, qu'il joigne sa liesse !  "
PLAY "f# f# g a a g f# e d d e f# e. d8 d2"

' --- Ligne 7 (Mesures 25-28 : Legato expressif) ---
COLOR 15, 1: LOCATE 11, 2: PRINT "  [DE] 6. Wer ein holdes Weib errungen, mische seinen Jubel ein!     "
COLOR 10, 1: LOCATE 12, 2: PRINT "     [FR] Qui a conquis une douce compagne, qu'il joigne sa liesse !  "
COLOR 14, 1: LOCATE 14, 2: PRINT "> [DE] 7. Ja, wer auch nur eine Seele sein nennt auf dem Erdenrund!  "
COLOR 11, 1: LOCATE 15, 2: PRINT "  >  [FR] Oui, meme celui qui ne possede qu'une seule ame sur terre ! "
PLAY "ML e e f# d e f#8 g8 f# d e f#8 g8 f# e MN d e <a2>"

' --- Ligne 8 (Mesures 29-32 : Resolution & Apogee) ---
COLOR 15, 1: LOCATE 14, 2: PRINT "  [DE] 7. Ja, wer auch nur eine Seele sein nennt auf dem Erdenrund!  "
COLOR 10, 1: LOCATE 15, 2: PRINT "     [FR] Oui, meme celui qui ne possede qu'une seule ame sur terre ! "
COLOR 14, 1: LOCATE 17, 2: PRINT "> [DE] 8. Und wer's nie gekonnt, der stehle weinend sich aus diesem! "
COLOR 11, 1: LOCATE 18, 2: PRINT "  >  [FR] Et que celui qui n'a pu le faire s'eloigne en pleurant !    "
PLAY ">f# f# g a a g f# e d d e f# e. d8 d2"

COLOR 15, 1: LOCATE 17, 2: PRINT "  [DE] 8. Und wer's nie gekonnt, der stehle weinend sich aus diesem! "
COLOR 10, 1: LOCATE 18, 2: PRINT "     [FR] Et que celui qui n'a pu le faire s'eloigne en pleurant !    "

' Coda triomphale
COLOR 14, 1
LOCATE 20, 2: PRINT "Coda triomphale et finale en Re Majeur...                      "
PLAY "L8 d e f# g L4 a >d <a f# d2."

COLOR 10, 1
LOCATE 21, 2
PRINT "Execution terminee avec succes ! Musique de Ludwig van Beethoven."
COLOR 7, 0
LOCATE 23, 1
PRINT ""
END
