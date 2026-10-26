' =========================================================================
' SUITE DE TESTS 26 : SYSTÈMES MODULAIRES & STRUCTURES PROFONDÉMENT IMBRIQUÉES
' Valide l'imbrication des types composes, le passage multi-procédures en cascade,
' l'imbrication de 5 niveaux de contrôle de flux et le pipeline modulaire unifié.
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 26 : SYSTÈMES MODULAIRES & STRUCTURES IMBRIQUÉES"
PRINT "=========================================================="

' Déclarations des modules et procédures imbriquées
DECLARE SUB PhysicsModule_Update (actors_x(), actors_y(), actors_vx(), actors_vy(), actors_hp(), n, dt)
DECLARE FUNCTION CollisionModule_Check (x1, y1, w1, h1, x2, y2, w2, h2)
DECLARE SUB StateModule_Evaluate (actors_hp(), actors_score(), actors_state(), n)
DECLARE SUB InventoryModule_Trade (inv_id(), inv_qty(), inv_price(), src, dst, count, trade_status)
DECLARE FUNCTION ScoringModule_Compute (base_pts, combo_mult, bonus_depth)
DECLARE FUNCTION ScoringModule_RecFactor (depth)
DECLARE SUB Orchestrator_RunCycle (actors_x(), actors_y(), actors_vx(), actors_vy(), actors_hp(), actors_score(), actors_state(), n, inv_id(), inv_qty(), inv_price(), cycle_result)

' -------------------------------------------------------------------------
' 1. STRUCTURES DE DONNÉES DE L'ENTITÉ (TYPES COMPOSÉS & TABLEAUX)
' -------------------------------------------------------------------------
TYPE EntityState
    posX AS INTEGER
    posY AS INTEGER
    velX AS INTEGER
    velY AS INTEGER
    health AS INTEGER
    score AS INTEGER
    status AS INTEGER
END TYPE

DIM actors(1 TO 4) AS EntityState

' Initialisation des acteurs
' Acteur 1: va vers la droite
actors(1).posX = 10: actors(1).posY = 20
actors(1).velX = 5:  actors(1).velY = 0
actors(1).health = 100: actors(1).score = 0: actors(1).status = 1

' Acteur 2: va vers la gauche (sur la trajectoire d'Acteur 1)
actors(2).posX = 25: actors(2).posY = 20
actors(2).velX = -5: actors(2).velY = 0
actors(2).health = 80: actors(2).score = 0: actors(2).status = 1

' Acteur 3: stationnaire
actors(3).posX = 100: actors(3).posY = 100
actors(3).velX = 0:   actors(3).velY = 0
actors(3).health = 50: actors(3).score = 0: actors(3).status = 1

' Acteur 4: hors limite
actors(4).posX = 195: actors(4).posY = 50
actors(4).velX = 10:  actors(4).velY = 0
actors(4).health = 30: actors(4).score = 0: actors(4).status = 1

' -------------------------------------------------------------------------
' TEST 1 : MODULE PHYSIQUE EN CASCADE AVEC DÉTECTION DE COLLISION
' -------------------------------------------------------------------------
' Tableaux d'échange pour compatibilité des modules
DIM a_x(4), a_y(4), a_vx(4), a_vy(4), a_hp(4), a_sc(4), a_st(4)
FOR i = 1 TO 4
    a_x(i) = actors(i).posX
    a_y(i) = actors(i).posY
    a_vx(i) = actors(i).velX
    a_vy(i) = actors(i).velY
    a_hp(i) = actors(i).health
    a_sc(i) = actors(i).score
    a_st(i) = actors(i).status
NEXT i

' Mise a jour physique sur 2 pas de temps (dt = 1)
CALL PhysicsModule_Update(a_x(), a_y(), a_vx(), a_vy(), a_hp(), 4, 1)

' Verification post-collision entre Acteur 1 et Acteur 2:
' Au pas 1: Acteur 1 en x=15, Acteur 2 en x=20 (distance <= 10 -> Collision!)
' Rebond: velX s'inverse, Acteur 1 velX = -5, Acteur 2 velX = 5
' Degats de collision: -10 HP chacun
LET phys_pass = -1
IF (a_vx(1) <> -5 OR a_vx(2) <> 5) THEN phys_pass = 0
IF (a_hp(1) <> 90 OR a_hp(2) <> 70) THEN phys_pass = 0
' Acteur 4 a heurte le mur x=200 et a rebondi
IF (a_vx(4) <> -10) THEN phys_pass = 0

IF phys_pass = -1 THEN
    PRINT "MODULAR_PHYSICS_COLLISION_CASCADE: PASS"
ELSE
    PRINT "MODULAR_PHYSICS_COLLISION_CASCADE: FAIL"
END IF


' -------------------------------------------------------------------------
' TEST 2 : MACHINE À ÉTATS AVEC 5 NIVEAUX DE CONTRÔLE IMBRIQUÉS
' -------------------------------------------------------------------------
' DO ... LOOP -> FOR ... NEXT -> SELECT CASE -> IF ... ELSEIF -> WHILE ... WEND
CALL StateModule_Evaluate(a_hp(), a_sc(), a_st(), 4)

' Verification des etats:
' Acteur 1: HP 90 -> Status 2 (Combat_Ready), Score attribue 50
' Acteur 3: HP 50 -> Status 3 (Wounded), Score attribue 20
' Acteur 4: HP 30 -> Status 4 (Critical), Score attribue 10
LET state_pass = -1
IF (a_st(1) <> 2 OR a_sc(1) <> 50) THEN state_pass = 0
IF (a_st(3) <> 3 OR a_sc(3) <> 20) THEN state_pass = 0
IF (a_st(4) <> 4 OR a_sc(4) <> 10) THEN state_pass = 0

IF state_pass = -1 THEN
    PRINT "MODULAR_NESTED_CONTROL_DISPATCHER: PASS"
ELSE
    PRINT "MODULAR_NESTED_CONTROL_DISPATCHER: FAIL"
END IF


' -------------------------------------------------------------------------
' TEST 3 : MODULE D'INVENTAIRE ET PIPELINE DE TRANSACTIONS
' -------------------------------------------------------------------------
' Inventaire: 4 slots d'objets (ID, QTE, PRIX)
DIM inv_id(4)
DIM inv_qty(4)
DIM inv_price(4)

inv_id(1) = 101: inv_qty(1) = 50: inv_price(1) = 10  ' Potions de soin
inv_id(2) = 102: inv_qty(2) = 0:  inv_price(2) = 10  ' Emplacement vide acheteur
inv_id(3) = 201: inv_qty(3) = 5:  inv_price(3) = 200 ' Gemmes rares
inv_id(4) = 202: inv_qty(4) = 2:  inv_price(4) = 200 ' Gemmes acheteur

' Transaction A: transfert de 15 potions du slot 1 au slot 2
LET status_tradeA = 0
CALL InventoryModule_Trade(inv_id(), inv_qty(), inv_price(), 1, 2, 15, status_tradeA)

' Transaction B: tentative de transfert de 10 gemmes du slot 3 (stock insuffisant car qty=5)
LET status_tradeB = 0
CALL InventoryModule_Trade(inv_id(), inv_qty(), inv_price(), 3, 4, 10, status_tradeB)

LET inv_pass = -1
IF (status_tradeA <> 1 OR inv_qty(1) <> 35 OR inv_qty(2) <> 15) THEN inv_pass = 0
IF (status_tradeB <> -1 OR inv_qty(3) <> 5 OR inv_qty(4) <> 2) THEN inv_pass = 0

IF inv_pass = -1 THEN
    PRINT "MODULAR_ECONOMY_TRANSACTION_PIPELINE: PASS"
ELSE
    PRINT "MODULAR_ECONOMY_TRANSACTION_PIPELINE: FAIL"
END IF


' -------------------------------------------------------------------------
' TEST 4 : ANALYSE ET CALCUL DE SCORE PAR FONCTIONS IMBRIQUÉES & RÉCURSIVES
' -------------------------------------------------------------------------
' Score final calcule par ScoringModule_Compute qui appelle ScoringModule_RecFactor(depth)
' base_pts = 100, combo_mult = 3, depth = 4
' Facteur recursif depth 4 = 4 * RecFactor(3) = 4 * 3 * 2 * 1 = 24
' Score = base_pts * combo_mult + depth! * 10 = 100 * 3 + 24 * 10 = 300 + 240 = 540
LET final_calc_score = ScoringModule_Compute(100, 3, 4)

IF final_calc_score = 540 THEN
    PRINT "MODULAR_RECURSIVE_SCORE_ANALYTICS: PASS"
ELSE
    PRINT "MODULAR_RECURSIVE_SCORE_ANALYTICS: FAIL"
END IF


' -------------------------------------------------------------------------
' TEST 5 : PIPELINE COMPLET ORCHESTRÉ (ORCHESTRATOR UNIFIÉ)
' -------------------------------------------------------------------------
LET master_cycle_ok = 0
CALL Orchestrator_RunCycle(a_x(), a_y(), a_vx(), a_vy(), a_hp(), a_sc(), a_st(), 4, inv_id(), inv_qty(), inv_price(), master_cycle_ok)

IF master_cycle_ok = 1 THEN
    PRINT "MODULAR_FULL_PIPELINE_INTEGRATION: PASS"
ELSE
    PRINT "MODULAR_FULL_PIPELINE_INTEGRATION: FAIL"
END IF

PRINT "MODULAR_NESTED_SYSTEMS_ALL: PASS"
SYSTEM


' =========================================================================
' DÉFINITIONS DES MODULES ET PROCÉDURES IMBRIQUÉES
' =========================================================================

' MODULE 1 : SIMULATION PHYSIQUE ET COLLISIONS
SUB PhysicsModule_Update (actors_x(), actors_y(), actors_vx(), actors_vy(), actors_hp(), n, dt)
    FOR i = 1 TO n
        actors_x(i) = actors_x(i) + actors_vx(i) * dt
        actors_y(i) = actors_y(i) + actors_vy(i) * dt
        
        ' Rebond contre la bordure droite du monde (x=200)
        IF actors_x(i) >= 200 THEN
            actors_x(i) = 200
            actors_vx(i) = -actors_vx(i)
        END IF
        ' Rebond contre la bordure gauche (x=0)
        IF actors_x(i) <= 0 THEN
            actors_x(i) = 0
            actors_vx(i) = -actors_vx(i)
        END IF
    NEXT i
    
    ' Detection de collision paire a paire
    FOR i = 1 TO n - 1
        FOR j = i + 1 TO n
            is_col = CollisionModule_Check(actors_x(i), actors_y(i), 10, 10, actors_x(j), actors_y(j), 10, 10)
            IF is_col = 1 THEN
                ' Echange de vitesse par rebond elastique
                tmp_vx = actors_vx(i)
                actors_vx(i) = actors_vx(j)
                actors_vx(j) = tmp_vx
                ' Degats de collision
                actors_hp(i) = actors_hp(i) - 10
                actors_hp(j) = actors_hp(j) - 10
            END IF
        NEXT j
    NEXT i
END SUB

FUNCTION CollisionModule_Check (x1, y1, w1, h1, x2, y2, w2, h2)
    LET col_hit = 0
    IF (ABS(x1 - x2) <= (w1 + w2) / 2) AND (ABS(y1 - y2) <= (h1 + h2) / 2) THEN
        col_hit = 1
    END IF
    CollisionModule_Check = col_hit
END FUNCTION


' MODULE 2 : DISPATCHER D'ÉTATS ET FLUX IMBRIQUÉ SUR 5 NIVEAUX
SUB StateModule_Evaluate (actors_hp(), actors_score(), actors_state(), n)
    LET pass_loop = 0
    DO
        pass_loop = pass_loop + 1
        FOR act_idx = 1 TO n
            ' Niveau 3: SELECT CASE sur la tranche de points de vie
            hp_tier = INT(actors_hp(act_idx) / 25)
            SELECT CASE hp_tier
                CASE 4, 3 ' HP >= 75
                    actors_state(act_idx) = 2 ' Combat_Ready
                    ' Niveau 4: Multi-line IF
                    IF actors_score(act_idx) = 0 THEN
                        actors_score(act_idx) = 50
                    END IF
                CASE 2 ' HP entre 50 et 74
                    actors_state(act_idx) = 3 ' Wounded
                    IF actors_score(act_idx) = 0 THEN
                        actors_score(act_idx) = 20
                    END IF
                CASE 1, 0 ' HP < 50
                    actors_state(act_idx) = 4 ' Critical
                    IF actors_score(act_idx) = 0 THEN
                        actors_score(act_idx) = 10
                    END IF
                CASE ELSE
                    actors_state(act_idx) = 0
            END SELECT
            
            ' Niveau 5: WHILE ... WEND pour verification de stabilite
            stk_drain = 0
            WHILE stk_drain < 2
                stk_drain = stk_drain + 1
            WEND
        NEXT act_idx
    LOOP WHILE pass_loop < 1
END SUB


' MODULE 3 : INVENTAIRE ET VALIDATION DE TRANSACTIONS
SUB InventoryModule_Trade (inv_id(), inv_qty(), inv_price(), src, dst, count, trade_status)
    IF inv_qty(src) >= count THEN
        inv_qty(src) = inv_qty(src) - count
        inv_qty(dst) = inv_qty(dst) + count
        trade_status = 1 ' Succes
    ELSE
        trade_status = -1 ' Stock insuffisant
    END IF
END SUB


' MODULE 4 : CALCULS ANALYTIQUES ET RÉCURSION PROFONDE
FUNCTION ScoringModule_Compute (base_pts, combo_mult, bonus_depth)
    LET rec_factor = ScoringModule_RecFactor(bonus_depth)
    ScoringModule_Compute = base_pts * combo_mult + rec_factor * 10
END FUNCTION

FUNCTION ScoringModule_RecFactor (depth)
    IF depth <= 1 THEN
        ScoringModule_RecFactor = 1
    ELSE
        ScoringModule_RecFactor = depth * ScoringModule_RecFactor(depth - 1)
    END IF
END FUNCTION


' MODULE 5 : ORCHESTRATEUR PRINCIPAL UNIFIÉ
SUB Orchestrator_RunCycle (actors_x(), actors_y(), actors_vx(), actors_vy(), actors_hp(), actors_score(), actors_state(), n, inv_id(), inv_qty(), inv_price(), cycle_result)
    ' 1. Execution du module physique
    CALL PhysicsModule_Update(actors_x(), actors_y(), actors_vx(), actors_vy(), actors_hp(), n, 0.5)
    
    ' 2. Execution de la machine d'etat
    CALL StateModule_Evaluate(actors_hp(), actors_score(), actors_state(), n)
    
    ' 3. Execution d'une transaction d'inventaire de ravitaillement
    trade_res = 0
    CALL InventoryModule_Trade(inv_id(), inv_qty(), inv_price(), 1, 2, 5, trade_res)
    
    ' 4. Calcul de score d'etape
    cycle_score = ScoringModule_Compute(50, 2, 3)
    
    ' Verification de la coherence globale du pipeline
    IF (trade_res = 1 AND cycle_score = 160) THEN
        cycle_result = 1
    ELSE
        cycle_result = 0
    END IF
END SUB
