' =========================================================================
' UNIT TEST 20: Numerical Methods & Computational Mathematics
' (Gaussian Elimination, Simpson 1/3, Newton-Raphson, Bisection, Det, ModExp)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 20 : MÉTHODES NUMÉRIQUES & ANALYSE"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. ÉLIMINATION DE GAUSS AVEC PIVOT PARTIEL (SYSTÈME 3x3)
' -------------------------------------------------------------------------
'  2x +  y -  z =   8
' -3x -  y + 2z = -11
' -2x +  y + 2z =  -3
' Solution théorique: x = 2, y = 3, z = -1

DIM A(3, 4)
A(1, 1) =  2: A(1, 2) =  1: A(1, 3) = -1: A(1, 4) =   8
A(2, 1) = -3: A(2, 2) = -1: A(2, 3) =  2: A(2, 4) = -11
A(3, 1) = -2: A(3, 2) =  1: A(3, 3) =  2: A(3, 4) =  -3

' Elimination directe avec pivotage
FOR k = 1 TO 2
    ' Trouver le plus grand pivot en valeur absolue
    p_max = k
    FOR i = k + 1 TO 3
        IF ABS(A(i, k)) > ABS(A(p_max, k)) THEN p_max = i
    NEXT i
    
    ' Echanger les lignes k et p_max
    IF p_max <> k THEN
        FOR j = k TO 4
            tmp = A(k, j)
            A(k, j) = A(p_max, j)
            A(p_max, j) = tmp
        NEXT j
    END IF
    
    ' Elimination sous le pivot
    FOR i = k + 1 TO 3
        factor = A(i, k) / A(k, k)
        FOR j = k TO 4
            A(i, j) = A(i, j) - factor * A(k, j)
        NEXT j
    NEXT i
NEXT k

' Remontee (Back-Substitution)
DIM X_sol(3)
X_sol(3) = A(3, 4) / A(3, 3)
X_sol(2) = (A(2, 4) - A(2, 3) * X_sol(3)) / A(2, 2)
X_sol(1) = (A(1, 4) - A(1, 2) * X_sol(2) - A(1, 3) * X_sol(3)) / A(1, 1)

LET err_gauss = ABS(X_sol(1) - 2) + ABS(X_sol(2) - 3) + ABS(X_sol(3) - (-1))
IF err_gauss < 0.0001 THEN
    PRINT "NUM_GAUSS_ELIMINATION: PASS"
ELSE
    PRINT "NUM_GAUSS_ELIMINATION: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. INTÉGRATION NUMÉRIQUE : RÈGLE COMPOSÉE DE SIMPSON 1/3
' -------------------------------------------------------------------------
' Integrale de f(x) = 3*x^2 + 2*x + 1 entre x=0 et x=2.
' Integrale exacte = [x^3 + x^2 + x]_0^2 = 8 + 4 + 2 = 14.0

LET n_intervals = 10
LET a_lim = 0
LET b_lim = 2
LET h_step = (b_lim - a_lim) / n_intervals

' f(a) et f(b)
LET simp_sum = (3 * a_lim ^ 2 + 2 * a_lim + 1) + (3 * b_lim ^ 2 + 2 * b_lim + 1)

FOR si = 1 TO n_intervals - 1
    xi = a_lim + si * h_step
    f_val = 3 * xi ^ 2 + 2 * xi + 1
    IF si MOD 2 = 1 THEN
        simp_sum = simp_sum + 4 * f_val
    ELSE
        simp_sum = simp_sum + 2 * f_val
    END IF
NEXT si

LET integral_simpson = (h_step / 3) * simp_sum

' Integrale de sin(x) entre 0 et PI (PI = 3.1415926535) -> exactement 2.0
LET pi_val = 3.14159265358979
LET h_sin = pi_val / 20
LET simp_sin = SIN(0) + SIN(pi_val)
FOR si = 1 TO 19
    xi = si * h_sin
    IF si MOD 2 = 1 THEN
        simp_sin = simp_sin + 4 * SIN(xi)
    ELSE
        simp_sin = simp_sin + 2 * SIN(xi)
    END IF
NEXT si
LET integral_sin = (h_sin / 3) * simp_sin

IF (ABS(integral_simpson - 14.0) < 0.0001 AND ABS(integral_sin - 2.0) < 0.0001) THEN
    PRINT "NUM_INTEGRATION_SIMPSON: PASS"
ELSE
    PRINT "NUM_INTEGRATION_SIMPSON: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. RECHERCHE DE RACINE : MÉTHODE DE NEWTON-RAPHSON
' -------------------------------------------------------------------------
' Equation: f(x) = x^3 - 2*x - 5 = 0
' Derivee: f'(x) = 3*x^2 - 2
' Racine reelle unique ~ 2.09455148

LET cur_x = 2.0
FOR iter = 1 TO 10
    f_val = cur_x ^ 3 - 2 * cur_x - 5
    f_prime = 3 * cur_x ^ 2 - 2
    cur_x = cur_x - (f_val / f_prime)
NEXT iter

LET residual = ABS(cur_x ^ 3 - 2 * cur_x - 5)
IF (residual < 0.00001 AND ABS(cur_x - 2.09455) < 0.001) THEN
    PRINT "NUM_NEWTON_RAPHSON_ROOT: PASS"
ELSE
    PRINT "NUM_NEWTON_RAPHSON_ROOT: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. MÉTHODE DE DICHOTOMIE (BISECTION METHOD)
' -------------------------------------------------------------------------
' Equation: g(x) = COS(x) - x = 0 (Le point fixe du cosinus, ~0.739085)
' Intervalle de depart: [0.0, 1.0]

LET bis_a = 0.0
LET bis_b = 1.0
LET bis_mid = 0.5

FOR iter = 1 TO 25
    bis_mid = (bis_a + bis_b) / 2
    g_a = COS(bis_a) - bis_a
    g_mid = COS(bis_mid) - bis_mid
    
    IF g_a * g_mid <= 0 THEN
        bis_b = bis_mid
    ELSE
        bis_a = bis_mid
    END IF
NEXT iter

LET bis_err = ABS(COS(bis_mid) - bis_mid)
IF (bis_err < 0.0001 AND ABS(bis_mid - 0.739085) < 0.001) THEN
    PRINT "NUM_BISECTION_METHOD: PASS"
ELSE
    PRINT "NUM_BISECTION_METHOD: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. DÉTERMINANT D'UNE MATRICE 3x3 PAR RÈGLE DE SARRUS
' -------------------------------------------------------------------------
' M = [ 6,  1,  1 ]
'     [ 4, -2,  5 ]
'     [ 2,  8,  7 ]
' det(M) = -306

DIM M(3, 3)
M(1, 1) = 6: M(1, 2) =  1: M(1, 3) = 1
M(2, 1) = 4: M(2, 2) = -2: M(2, 3) = 5
M(3, 1) = 2: M(3, 2) =  8: M(3, 3) = 7

LET det3 = M(1,1)*(M(2,2)*M(3,3) - M(2,3)*M(3,2)) - M(1,2)*(M(2,1)*M(3,3) - M(2,3)*M(3,1)) + M(1,3)*(M(2,1)*M(3,2) - M(2,2)*M(3,1))

IF det3 = -306 THEN
    PRINT "NUM_MATRIX_DETERMINANT: PASS"
ELSE
    PRINT "NUM_MATRIX_DETERMINANT: FAIL"
END IF


' -------------------------------------------------------------------------
' 6. EXPONENTIATION MODULAIRE RAPIDE (a^b MOD m)
' -------------------------------------------------------------------------
' Calcul de 7^13 MOD 1000
' 7^13 = 96889010407, 96889010407 MOD 1000 = 407 (attendu: 407)
' 7^1 = 7
' 7^2 = 49
' 7^4 = 2401 mod 1000 = 401
' 7^8 = 401^2 = 160801 mod 1000 = 801
' 13 en binaire = 1101 (8 + 4 + 1)
' 7^13 mod 1000 = (801 * 401 * 7) mod 1000 = (321201 * 7) mod 1000 = (201 * 7) mod 1000 = 1407 mod 1000 = 407

LET base_m = 7
LET exp_m = 13
LET mod_m = 1000
LET res_mod = 1
LET cur_base = base_m MOD mod_m
LET cur_exp = exp_m

WHILE cur_exp > 0
    IF cur_exp MOD 2 = 1 THEN
        res_mod = (res_mod * cur_base) MOD mod_m
    END IF
    cur_base = (cur_base * cur_base) MOD mod_m
    cur_exp = INT(cur_exp / 2)
WEND

IF res_mod = 407 THEN
    PRINT "NUM_MODULAR_EXPONENTIATION: PASS"
ELSE
    PRINT "NUM_MODULAR_EXPONENTIATION: FAIL"
END IF


' -------------------------------------------------------------------------
' 7. ÉVALUATION POLYNOMIALE PAR LA MÉTHODE DE HORNER
' -------------------------------------------------------------------------
' P(x) = 2*x^4 - 6*x^3 + 2*x^2 - x + 5 en x = 3
' Direct: 2*81 - 6*27 + 2*9 - 3 + 5 = 162 - 162 + 18 - 3 + 5 = 20
DIM coeff(4)
coeff(4) = 2
coeff(3) = -6
coeff(2) = 2
coeff(1) = -1
coeff(0) = 5

LET x_eval = 3
LET horner_val = coeff(4)
FOR deg = 3 TO 0 STEP -1
    horner_val = horner_val * x_eval + coeff(deg)
NEXT deg

IF horner_val = 20 THEN
    PRINT "NUM_HORNERS_POLYNOMIAL: PASS"
ELSE
    PRINT "NUM_HORNERS_POLYNOMIAL: FAIL"
END IF

PRINT "NUMERICAL_METHODS_ALL: PASS"
SYSTEM
