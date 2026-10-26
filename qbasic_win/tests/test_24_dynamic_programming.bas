' =========================================================================
' UNIT TEST 24 : Dynamic Programming & Combinatorial Optimization
' (0/1 Knapsack, Longest Common Subsequence, Levenshtein, Matrix Chain, Coin Change)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 24 : PROGRAMMATION DYNAMIQUE & OPTIMISATION"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. SAC À DOS 0/1 (0/1 KNAPSACK PROBLEM) AVEC RECONSTRUCTION
' -------------------------------------------------------------------------
' 4 objets: Poids = [2, 3, 4, 5], Valeurs = [3, 4, 5, 8]
' Capacite du sac W = 8
DIM item_wt(4)
DIM item_val(4)
DATA 2, 3, 4, 5
FOR i = 1 TO 4: READ item_wt(i): NEXT i
DATA 3, 4, 5, 8
FOR i = 1 TO 4: READ item_val(i): NEXT i

DIM dp_kp(0 TO 4, 0 TO 8)
FOR i = 0 TO 4: FOR w = 0 TO 8: dp_kp(i, w) = 0: NEXT w: NEXT i

FOR i = 1 TO 4
    wt = item_wt(i)
    v = item_val(i)
    FOR w = 0 TO 8
        IF wt <= w THEN
            val_with = dp_kp(i - 1, w - wt) + v
            val_without = dp_kp(i - 1, w)
            IF val_with > val_without THEN
                dp_kp(i, w) = val_with
            ELSE
                dp_kp(i, w) = val_without
            END IF
        ELSE
            dp_kp(i, w) = dp_kp(i - 1, w)
        END IF
    NEXT w
NEXT i

LET max_knapsack_val = dp_kp(4, 8)

' Reconstruction des objets choisis
DIM chosen(4)
FOR i = 1 TO 4: chosen(i) = 0: NEXT i
cur_w = 8
FOR i = 4 TO 1 STEP -1
    IF dp_kp(i, cur_w) <> dp_kp(i - 1, cur_w) THEN
        chosen(i) = 1
        cur_w = cur_w - item_wt(i)
    END IF
NEXT i

' Doit choisir l'objet 2 (wt 3, val 4) et l'objet 4 (wt 5, val 8) -> Poids total = 8, Valeur = 12
LET kp_ok = -1
IF max_knapsack_val <> 12 THEN kp_ok = 0
IF (chosen(2) <> 1 OR chosen(4) <> 1 OR chosen(1) <> 0 OR chosen(3) <> 0) THEN kp_ok = 0

IF kp_ok = -1 THEN
    PRINT "DP_01_KNAPSACK: PASS"
ELSE
    PRINT "DP_01_KNAPSACK: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. PLUS LONGUE SOUS-SÉQUENCE COMMUNE (LONGEST COMMON SUBSEQUENCE - LCS)
' -------------------------------------------------------------------------
' Chaine 1: "QBASIC"      (longueur 6)
' Chaine 2: "QUICKBASIC"  (longueur 10)
' LCS: "QBASIC" (longueur 6)
LET str1$ = "QBASIC"
LET str2$ = "QUICKBASIC"
LET len1 = LEN(str1$)
LET len2 = LEN(str2$)

DIM dp_lcs(0 TO 6, 0 TO 10)
FOR i = 0 TO len1: FOR j = 0 TO len2: dp_lcs(i, j) = 0: NEXT j: NEXT i

FOR i = 1 TO len1
    ch1$ = MID$(str1$, i, 1)
    FOR j = 1 TO len2
        ch2$ = MID$(str2$, j, 1)
        IF ch1$ = ch2$ THEN
            dp_lcs(i, j) = dp_lcs(i - 1, j - 1) + 1
        ELSE
            v1 = dp_lcs(i - 1, j)
            v2 = dp_lcs(i, j - 1)
            IF v1 > v2 THEN dp_lcs(i, j) = v1 ELSE dp_lcs(i, j) = v2
        END IF
    NEXT j
NEXT i

LET lcs_len = dp_lcs(len1, len2)

' Reconstruction du mot LCS
LET lcs_word$ = ""
i = len1
j = len2
WHILE i > 0 AND j > 0
    IF MID$(str1$, i, 1) = MID$(str2$, j, 1) THEN
        lcs_word$ = MID$(str1$, i, 1) + lcs_word$
        i = i - 1
        j = j - 1
    ELSEIF dp_lcs(i - 1, j) > dp_lcs(i, j - 1) THEN
        i = i - 1
    ELSE
        j = j - 1
    END IF
WEND

IF (lcs_len = 6 AND lcs_word$ = "QBASIC") THEN
    PRINT "DP_LONGEST_COMMON_SUBSEQUENCE: PASS"
ELSE
    PRINT "DP_LONGEST_COMMON_SUBSEQUENCE: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. DISTANCE D'ÉDITION DE LEVENSHTEIN
' -------------------------------------------------------------------------
' "KITTEN" vers "SITTING" -> distance = 3
LET wordA$ = "KITTEN"
LET wordB$ = "SITTING"
LET nA = LEN(wordA$)
LET nB = LEN(wordB$)

DIM dp_lev(0 TO 6, 0 TO 7)
FOR i = 0 TO nA: dp_lev(i, 0) = i: NEXT i
FOR j = 0 TO nB: dp_lev(0, j) = j: NEXT j

FOR i = 1 TO nA
    cA$ = MID$(wordA$, i, 1)
    FOR j = 1 TO nB
        cB$ = MID$(wordB$, j, 1)
        IF cA$ = cB$ THEN
            cost = 0
        ELSE
            cost = 1
        END IF
        
        del_cost = dp_lev(i - 1, j) + 1
        ins_cost = dp_lev(i, j - 1) + 1
        sub_cost = dp_lev(i - 1, j - 1) + cost
        
        min_c = del_cost
        IF ins_cost < min_c THEN min_c = ins_cost
        IF sub_cost < min_c THEN min_c = sub_cost
        
        dp_lev(i, j) = min_c
    NEXT j
NEXT i

LET lev_dist = dp_lev(nA, nB)
IF lev_dist = 3 THEN
    PRINT "DP_LEVENSHTEIN_DISTANCE: PASS"
ELSE
    PRINT "DP_LEVENSHTEIN_DISTANCE: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. MULTIPLICATION EN CHAÎNE DE MATRICES (MATRIX CHAIN MULTIPLICATION)
' -------------------------------------------------------------------------
' 4 matrices: A1(10x30), A2(30x5), A3(5x60), A4(60x8)
' Dimensions p = [10, 30, 5, 60, 8]
DIM p_dims(0 TO 4)
p_dims(0) = 10
p_dims(1) = 30
p_dims(2) = 5
p_dims(3) = 60
p_dims(4) = 8

DIM m_chain(1 TO 4, 1 TO 4)
FOR i = 1 TO 4: FOR j = 1 TO 4: m_chain(i, j) = 0: NEXT j: NEXT i

FOR chain_len = 2 TO 4
    FOR i = 1 TO 4 - chain_len + 1
        j = i + chain_len - 1
        m_chain(i, j) = 9999999
        FOR k = i TO j - 1
            cost_mul = m_chain(i, k) + m_chain(k + 1, j) + p_dims(i - 1) * p_dims(k) * p_dims(j)
            IF cost_mul < m_chain(i, j) THEN
                m_chain(i, j) = cost_mul
            END IF
        NEXT k
    NEXT i
NEXT chain_len

LET min_matrix_mult = m_chain(1, 4)

IF min_matrix_mult = 4300 THEN
    PRINT "DP_MATRIX_CHAIN_MULTIPLICATION: PASS"
ELSE
    PRINT "DP_MATRIX_CHAIN_MULTIPLICATION: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. RENDU DE MONNAIE (COIN CHANGE : MINIMUM DE PIÈCES & TOTAL COMBINAISONS)
' -------------------------------------------------------------------------
' Pieces disponibles: 1, 2, 5
' Montant cible: 11
' Minimum de pieces = 5 + 5 + 1 = 3 pieces
' Nombre de combinaisons uniques = 11

' Partie A: Nombre minimum de pieces
DIM min_coins(0 TO 11)
min_coins(0) = 0
FOR m = 1 TO 11: min_coins(m) = 999: NEXT m

DIM coin_val(3)
coin_val(1) = 1: coin_val(2) = 2: coin_val(3) = 5

FOR ci = 1 TO 3
    c_val = coin_val(ci)
    FOR m = c_val TO 11
        IF min_coins(m - c_val) + 1 < min_coins(m) THEN
            min_coins(m) = min_coins(m - c_val) + 1
        END IF
    NEXT m
NEXT ci

' Partie B: Nombre de combinaisons uniques
DIM ways(0 TO 11)
ways(0) = 1
FOR m = 1 TO 11: ways(m) = 0: NEXT m

FOR ci = 1 TO 3
    c_val = coin_val(ci)
    FOR m = c_val TO 11
        ways(m) = ways(m) + ways(m - c_val)
    NEXT m
NEXT ci

IF (min_coins(11) = 3 AND ways(11) = 11) THEN
    PRINT "DP_COIN_CHANGE_MIN_AND_WAYS: PASS"
ELSE
    PRINT "DP_COIN_CHANGE_MIN_AND_WAYS: FAIL"
END IF

PRINT "DYNAMIC_PROGRAMMING_ALL: PASS"
SYSTEM
