dim name$(2) as string

name$(0) = "Zouaz"
name$(1) = "Frad"

'input "Entrer un nombre entre 0 et 5 : "; p1
'input "Sélectionner 0 pour Zouaz ou 1 pour Frad : "; choix

randomize
gagne = 0
for i = 1 to 10000
    p1 = int(rnd * 6)
    choix = int(rnd * 2)
    'print "P1 a choisi : " + name$(choix) + ", " + str$(p1)

    p2 = int(rnd * 6)
    'print "P2 a choisi : " + str$(p2)

    total = p1 + p2

    if total mod 2 = choix then
        gagne = gagne + 1
    end if
next i

print "Vous avez gagné : " + str$(gagne) + " fois"
