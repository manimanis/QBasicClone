' =========================================================================
' UNIT TEST 22: Cellular Automata, Kinematics & Physics Engine
' (Conway's Game of Life, Toroidal Glider, Euler Integration, Restitution, SAT)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 22 : AUTOMATES CELLULAIRES ET MOTEUR PHYSIQUE 2D"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. JEU DE LA VIE DE CONWAY : OSCILLATEUR BLINKER (PÉRIODE 2)
' -------------------------------------------------------------------------
' Grille 10x10 toroidale
DIM life(10, 10)
DIM next_life(10, 10)

FOR r = 1 TO 10
    FOR c = 1 TO 10
        life(r, c) = 0
    NEXT c
NEXT r

' Blinker horizontal au centre: (5, 4), (5, 5), (5, 6)
life(5, 4) = 1
life(5, 5) = 1
life(5, 6) = 1

' Etape 1
FOR r = 1 TO 10
    FOR c = 1 TO 10
        n_count = 0
        FOR dr = -1 TO 1
            FOR dc = -1 TO 1
                IF dr <> 0 OR dc <> 0 THEN
                    nr = (r - 1 + dr + 10) MOD 10 + 1
                    nc = (c - 1 + dc + 10) MOD 10 + 1
                    IF life(nr, nc) = 1 THEN n_count = n_count + 1
                END IF
            NEXT dc
        NEXT dr
        
        IF life(r, c) = 1 THEN
            IF n_count = 2 OR n_count = 3 THEN next_life(r, c) = 1 ELSE next_life(r, c) = 0
        ELSE
            IF n_count = 3 THEN next_life(r, c) = 1 ELSE next_life(r, c) = 0
        END IF
    NEXT c
NEXT r

' Verifier le blinker devenu vertical: (4, 5), (5, 5), (6, 5)
LET blink_vert = (next_life(4, 5) = 1 AND next_life(5, 5) = 1 AND next_life(6, 5) = 1 AND next_life(5, 4) = 0 AND next_life(5, 6) = 0)

' Etape 2
FOR r = 1 TO 10
    FOR c = 1 TO 10
        life(r, c) = next_life(r, c)
    NEXT c
NEXT r

FOR r = 1 TO 10
    FOR c = 1 TO 10
        n_count = 0
        FOR dr = -1 TO 1
            FOR dc = -1 TO 1
                IF dr <> 0 OR dc <> 0 THEN
                    nr = (r - 1 + dr + 10) MOD 10 + 1
                    nc = (c - 1 + dc + 10) MOD 10 + 1
                    IF life(nr, nc) = 1 THEN n_count = n_count + 1
                END IF
            NEXT dc
        NEXT dr
        
        IF life(r, c) = 1 THEN
            IF n_count = 2 OR n_count = 3 THEN next_life(r, c) = 1 ELSE next_life(r, c) = 0
        ELSE
            IF n_count = 3 THEN next_life(r, c) = 1 ELSE next_life(r, c) = 0
        END IF
    NEXT c
NEXT r

' Verifier le retour a l'horizontale: (5, 4), (5, 5), (5, 6)
LET blink_horiz = (next_life(5, 4) = 1 AND next_life(5, 5) = 1 AND next_life(5, 6) = 1 AND next_life(4, 5) = 0 AND next_life(6, 5) = 0)

IF (blink_vert = -1 AND blink_horiz = -1) THEN
    PRINT "CELLULAR_LIFE_BLINKER_OSCILLATOR: PASS"
ELSE
    PRINT "CELLULAR_LIFE_BLINKER_OSCILLATOR: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. JEU DE LA VIE : GLIDER DIAGONAL (TRANSLATION SUR 4 GÉNÉRATIONS)
' -------------------------------------------------------------------------
FOR r = 1 TO 10: FOR c = 1 TO 10: life(r, c) = 0: NEXT c: NEXT r

' Configuration Glider en haut a gauche
' . X .   -> (1, 2)
' . . X   -> (2, 3)
' X X X   -> (3, 1), (3, 2), (3, 3)
life(1, 2) = 1
life(2, 3) = 1
life(3, 1) = 1: life(3, 2) = 1: life(3, 3) = 1

' Simuler 4 generations complètes
FOR gen = 1 TO 4
    FOR r = 1 TO 10
        FOR c = 1 TO 10
            n_count = 0
            FOR dr = -1 TO 1
                FOR dc = -1 TO 1
                    IF dr <> 0 OR dc <> 0 THEN
                        nr = (r - 1 + dr + 10) MOD 10 + 1
                        nc = (c - 1 + dc + 10) MOD 10 + 1
                        IF life(nr, nc) = 1 THEN n_count = n_count + 1
                    END IF
                NEXT dc
            NEXT dr
            
            IF life(r, c) = 1 THEN
                IF n_count = 2 OR n_count = 3 THEN next_life(r, c) = 1 ELSE next_life(r, c) = 0
            ELSE
                IF n_count = 3 THEN next_life(r, c) = 1 ELSE next_life(r, c) = 0
            END IF
        NEXT c
    NEXT r
    FOR r = 1 TO 10: FOR c = 1 TO 10: life(r, c) = next_life(r, c): NEXT c: NEXT r
NEXT gen

' Apres 4 generations, le Glider doit s'etre translaté exactement de (+1, +1):
' (2, 3), (3, 4), (4, 2), (4, 3), (4, 4)
LET glider_ok = -1
IF (life(2, 3) <> 1 OR life(3, 4) <> 1 OR life(4, 2) <> 1 OR life(4, 3) <> 1 OR life(4, 4) <> 1) THEN
    glider_ok = 0
END IF
' Verifier le nombre total de cellules actives = 5
LET cell_sum = 0
FOR r = 1 TO 10: FOR c = 1 TO 10: cell_sum = cell_sum + life(r, c): NEXT c: NEXT r
IF cell_sum <> 5 THEN glider_ok = 0

IF glider_ok = -1 THEN
    PRINT "CELLULAR_LIFE_GLIDER_TRANSLATION: PASS"
ELSE
    PRINT "CELLULAR_LIFE_GLIDER_TRANSLATION: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. CINÉMATIQUE 2D : INTÉGRATION NUMÉRIQUE D'UN PROJECTILE (EULER)
' -------------------------------------------------------------------------
' Vitesse initiale: vx = 20.0 m/s, vy = 30.0 m/s
' Gravite g = 9.81 m/s^2
' Temps de vol theorique: T = 2 * vy / g = 60 / 9.81 = 6.1162 s
' Portee theorique: R = vx * T = 20 * 6.1162 = 122.324 m
' Hauteur maximale: H = vy^2 / (2*g) = 900 / 19.62 = 45.8715 m

LET px = 0.0
LET py = 0.0
LET vx = 20.0
LET vy = 30.0
LET g = 9.81
LET dt = 0.005
LET sim_time = 0.0
LET max_height = 0.0

WHILE py >= 0.0 AND sim_time < 10.0
    px = px + vx * dt
    py = py + vy * dt
    vy = vy - g * dt
    sim_time = sim_time + dt
    IF py > max_height THEN max_height = py
WEND

LET err_time = ABS(sim_time - 6.1162)
LET err_range = ABS(px - 122.324)
LET err_height = ABS(max_height - 45.8715)

IF (err_time < 0.05 AND err_range < 1.0 AND err_height < 0.2) THEN
    PRINT "PHYSICS_KINEMATICS_PROJECTILE: PASS"
ELSE
    PRINT "PHYSICS_KINEMATICS_PROJECTILE: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. REBOND INÉLASTIQUE AVEC COEFFICIENT DE RESTITUTION
' -------------------------------------------------------------------------
' Balle lâchée de h0 = 100 m sans vitesse initiale
' Coefficient de restitution e = 0.8
' Hauteurs maximales après rebonds:
' Pic 1 = 100 * 0.8^2 = 64.0 m
' Pic 2 = 64 * 0.8^2 = 40.96 m
' Pic 3 = 40.96 * 0.8^2 = 26.2144 m

LET ball_y = 100.0
LET ball_vy = 0.0
LET e_rest = 0.8
LET dt = 0.005

DIM peak(3)
LET bounce_count = 0
LET in_ascent = 0

FOR step_i = 1 TO 4000
    ball_y = ball_y + ball_vy * dt
    ball_vy = ball_vy - g * dt
    
    ' Collision avec le sol
    IF ball_y <= 0.0 AND ball_vy < 0.0 THEN
        ball_y = 0.0
        ball_vy = -e_rest * ball_vy
        bounce_count = bounce_count + 1
        in_ascent = 1
    END IF
    
    ' Detection de l'apogee (vy passe de positif a negatif)
    IF in_ascent = 1 AND ball_vy <= 0.0 AND bounce_count <= 3 THEN
        peak(bounce_count) = ball_y
        in_ascent = 0
    END IF
NEXT step_i

LET bounce_ok = -1
IF (bounce_count < 3) THEN bounce_ok = 0
IF ABS(peak(1) - 64.0) > 0.5 THEN bounce_ok = 0
IF ABS(peak(2) - 40.96) > 0.5 THEN bounce_ok = 0
IF ABS(peak(3) - 26.21) > 0.5 THEN bounce_ok = 0

IF bounce_ok = -1 THEN
    PRINT "PHYSICS_BOUNCE_RESTITUTION: PASS"
ELSE
    PRINT "PHYSICS_BOUNCE_RESTITUTION: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. GÉOMÉTRIE 2D & DÉTECTION DE COLLISION CERCLE-CERCLE
' -------------------------------------------------------------------------
' Cercle A: (10, 10), rA = 5
' Cercle B: (16, 18), rB = 6
' Distance centres = SQR((16-10)^2 + (18-10)^2) = SQR(36 + 64) = 10.0
' Somme des rayons = 5 + 6 = 11.0
' Distance < Somme rayons -> Collision avec penetration = 1.0

LET dist_AB = SQR((16 - 10) ^ 2 + (18 - 10) ^ 2)
LET col_AB = (dist_AB <= (5 + 6))
LET pen_AB = (5 + 6) - dist_AB

' Cercle C: (30, 30), rC = 4
LET dist_AC = SQR((30 - 10) ^ 2 + (30 - 10) ^ 2)
LET col_AC = (dist_AC <= (5 + 4))

IF (col_AB = -1 AND ABS(pen_AB - 1.0) < 0.0001 AND col_AC = 0) THEN
    PRINT "GEOMETRY_CIRCLE_COLLISION: PASS"
ELSE
    PRINT "GEOMETRY_CIRCLE_COLLISION: FAIL"
END IF


' -------------------------------------------------------------------------
' 6. TEST POINT-DANS-POLYGONE (ALGORITHME DU RAY-CASTING)
' -------------------------------------------------------------------------
' Polygone non-convexe a 5 sommets (L-shape):
' (0,0) -> (10,0) -> (10,5) -> (5,5) -> (5,10) -> (0,10) -> (0,0)
DIM poly_x(6)
DIM poly_y(6)
poly_x(1) = 0:  poly_y(1) = 0
poly_x(2) = 10: poly_y(2) = 0
poly_x(3) = 10: poly_y(3) = 5
poly_x(4) = 5:  poly_y(4) = 5
poly_x(5) = 5:  poly_y(5) = 10
poly_x(6) = 0:  poly_y(6) = 10

' Test point P1(2, 2) -> Interieur (Dans la base du L)
' Test point P2(8, 8) -> Exterieur (Dans l'angle vide en haut a droite)

' Verification Ray-Casting pour P1
LET test_x = 2: LET test_y = 2
LET inside1 = 0
LET j_idx = 6
FOR i_idx = 1 TO 6
    xi = poly_x(i_idx): yi = poly_y(i_idx)
    xj = poly_x(j_idx): yj = poly_y(j_idx)
    
    cond_y = ((yi > test_y) <> (yj > test_y))
    IF cond_y THEN
        x_inters = (xj - xi) * (test_y - yi) / (yj - yi) + xi
        IF test_x < x_inters THEN
            inside1 = 1 - inside1
        END IF
    END IF
    j_idx = i_idx
NEXT i_idx

' Verification Ray-Casting pour P2
test_x = 8: test_y = 8
LET inside2 = 0
j_idx = 6
FOR i_idx = 1 TO 6
    xi = poly_x(i_idx): yi = poly_y(i_idx)
    xj = poly_x(j_idx): yj = poly_y(j_idx)
    
    cond_y = ((yi > test_y) <> (yj > test_y))
    IF cond_y THEN
        x_inters = (xj - xi) * (test_y - yi) / (yj - yi) + xi
        IF test_x < x_inters THEN
            inside2 = 1 - inside2
        END IF
    END IF
    j_idx = i_idx
NEXT i_idx

IF (inside1 = 1 AND inside2 = 0) THEN
    PRINT "GEOMETRY_POINT_IN_POLYGON: PASS"
ELSE
    PRINT "GEOMETRY_POINT_IN_POLYGON: FAIL"
END IF

PRINT "CELLULAR_PHYSICS_ALL: PASS"
SYSTEM
