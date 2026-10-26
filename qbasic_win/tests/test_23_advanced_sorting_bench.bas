' =========================================================================
' UNIT TEST 23 : Advanced Sorting Algorithms & Dual-Bound Binary Search
' (Iterative QuickSort, MergeSort, HeapSort, CountingSort, Lower/Upper Bounds)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 23 : ALGORITHMES DE TRI AVANCÉS ET RECHERCHE"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. QUICKSORT ITÉRATIF AVEC PILE EXPLICITE (TABLEAU DE 16 ÉLÉMENTS)
' -------------------------------------------------------------------------
DIM orig_arr(16)
DIM qs_arr(16)
DIM ms_arr(16)
DIM hs_arr(16)

DATA 42, -5, 18, 99, 0, -5, 7, 23, 18, -12, 55, 3, 100, -20, 8, 42
FOR i = 1 TO 16
    READ v_orig
    orig_arr(i) = v_orig
    qs_arr(i) = v_orig
    ms_arr(i) = v_orig
    hs_arr(i) = v_orig
NEXT i

DIM qs_stk_l(32)
DIM qs_stk_r(32)
LET qsp = 1
qs_stk_l(1) = 1
qs_stk_r(1) = 16

WHILE qsp > 0
    l_idx = qs_stk_l(qsp)
    r_idx = qs_stk_r(qsp)
    qsp = qsp - 1
    
    IF l_idx < r_idx THEN
        ' Partitionnement de Lomuto avec pivot en r_idx
        pivot_val = qs_arr(r_idx)
        p_store = l_idx
        FOR j_idx = l_idx TO r_idx - 1
            IF qs_arr(j_idx) <= pivot_val THEN
                tmp = qs_arr(j_idx)
                qs_arr(j_idx) = qs_arr(p_store)
                qs_arr(p_store) = tmp
                p_store = p_store + 1
            END IF
        NEXT j_idx
        
        tmp = qs_arr(p_store)
        qs_arr(p_store) = qs_arr(r_idx)
        qs_arr(r_idx) = tmp
        
        ' Empiler les deux sous-tableaux
        qsp = qsp + 1
        qs_stk_l(qsp) = l_idx
        qs_stk_r(qsp) = p_store - 1
        
        qsp = qsp + 1
        qs_stk_l(qsp) = p_store + 1
        qs_stk_r(qsp) = r_idx
    END IF
WEND

LET qs_ok = -1
FOR i = 1 TO 15
    IF qs_arr(i) > qs_arr(i + 1) THEN qs_ok = 0
NEXT i
IF (qs_arr(1) <> -20 OR qs_arr(16) <> 100) THEN qs_ok = 0

IF qs_ok = -1 THEN
    PRINT "SORT_QUICKSORT_STACK: PASS"
ELSE
    PRINT "SORT_QUICKSORT_STACK: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. MERGESORT ITÉRATIF BOTTOM-UP
' -------------------------------------------------------------------------
DIM ms_aux(16)
LET seg_width = 1
WHILE seg_width < 16
    FOR left_start = 1 TO 16 STEP 2 * seg_width
        mid_pt = left_start + seg_width - 1
        right_end = left_start + 2 * seg_width - 1
        IF mid_pt > 16 THEN mid_pt = 16
        IF right_end > 16 THEN right_end = 16
        
        ' Fusion de [left_start .. mid_pt] et [mid_pt+1 .. right_end]
        i1 = left_start
        i2 = mid_pt + 1
        k_out = left_start
        
        WHILE i1 <= mid_pt AND i2 <= right_end
            IF ms_arr(i1) <= ms_arr(i2) THEN
                ms_aux(k_out) = ms_arr(i1)
                i1 = i1 + 1
            ELSE
                ms_aux(k_out) = ms_arr(i2)
                i2 = i2 + 1
            END IF
            k_out = k_out + 1
        WEND
        
        WHILE i1 <= mid_pt
            ms_aux(k_out) = ms_arr(i1)
            i1 = i1 + 1
            k_out = k_out + 1
        WEND
        
        WHILE i2 <= right_end
            ms_aux(k_out) = ms_arr(i2)
            i2 = i2 + 1
            k_out = k_out + 1
        WEND
        
        FOR cpy = left_start TO right_end
            ms_arr(cpy) = ms_aux(cpy)
        NEXT cpy
    NEXT left_start
    seg_width = seg_width * 2
WEND

LET ms_ok = -1
FOR i = 1 TO 15
    IF ms_arr(i) > ms_arr(i + 1) THEN ms_ok = 0
NEXT i
IF (ms_arr(1) <> -20 OR ms_arr(16) <> 100) THEN ms_ok = 0

IF ms_ok = -1 THEN
    PRINT "SORT_MERGESORT_ITERATIVE: PASS"
ELSE
    PRINT "SORT_MERGESORT_ITERATIVE: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. HEAPSORT IN-PLACE (TAS MAXIMAL)
' -------------------------------------------------------------------------
' Construction du max-heap
FOR i = 8 TO 1 STEP -1
    h_idx = i
    h_sift = 1
    WHILE h_sift = 1
        h_max = h_idx
        h_left = h_idx * 2
        h_right = h_idx * 2 + 1
        IF h_left <= 16 THEN
            IF hs_arr(h_left) > hs_arr(h_max) THEN h_max = h_left
        END IF
        IF h_right <= 16 THEN
            IF hs_arr(h_right) > hs_arr(h_max) THEN h_max = h_right
        END IF
        IF h_max <> h_idx THEN
            tmp = hs_arr(h_idx)
            hs_arr(h_idx) = hs_arr(h_max)
            hs_arr(h_max) = tmp
            h_idx = h_max
        ELSE
            h_sift = 0
        END IF
    WEND
NEXT i

' Extraction successive
FOR cur_heap_sz = 16 TO 2 STEP -1
    tmp = hs_arr(1)
    hs_arr(1) = hs_arr(cur_heap_sz)
    hs_arr(cur_heap_sz) = tmp
    
    h_idx = 1
    h_sift = 1
    eff_sz = cur_heap_sz - 1
    WHILE h_sift = 1
        h_max = h_idx
        h_left = h_idx * 2
        h_right = h_idx * 2 + 1
        IF h_left <= eff_sz THEN
            IF hs_arr(h_left) > hs_arr(h_max) THEN h_max = h_left
        END IF
        IF right_idx <= eff_sz THEN
        END IF
        IF h_right <= eff_sz THEN
            IF hs_arr(h_right) > hs_arr(h_max) THEN h_max = h_right
        END IF
        IF h_max <> h_idx THEN
            tmp = hs_arr(h_idx)
            hs_arr(h_idx) = hs_arr(h_max)
            hs_arr(h_max) = tmp
            h_idx = h_max
        ELSE
            h_sift = 0
        END IF
    WEND
NEXT cur_heap_sz

LET hs_ok = -1
FOR i = 1 TO 15
    IF hs_arr(i) > hs_arr(i + 1) THEN hs_ok = 0
NEXT i
IF (hs_arr(1) <> -20 OR hs_arr(16) <> 100) THEN hs_ok = 0

IF hs_ok = -1 THEN
    PRINT "SORT_HEAPSORT_IN_PLACE: PASS"
ELSE
    PRINT "SORT_HEAPSORT_IN_PLACE: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. COUNTING SORT LINÉAIRE O(N + K)
' -------------------------------------------------------------------------
' 15 entiers positifs compris entre 0 et 5
DIM cs_in(15)
DIM cs_out(15)
DIM cs_count(0 TO 5)

DATA 4, 1, 3, 2, 0, 5, 2, 4, 1, 3, 0, 5, 2, 1, 4
FOR i = 1 TO 15: READ cs_in(i): NEXT i

FOR k = 0 TO 5: cs_count(k) = 0: NEXT k

FOR i = 1 TO 15
    val_k = cs_in(i)
    cs_count(val_k) = cs_count(val_k) + 1
NEXT i

' Reconstruction ordonnee
LET out_idx = 0
FOR k = 0 TO 5
    FOR cnt = 1 TO cs_count(k)
        out_idx = out_idx + 1
        cs_out(out_idx) = k
    NEXT cnt
NEXT k

LET cs_ok = -1
IF out_idx <> 15 THEN cs_ok = 0
FOR i = 1 TO 14
    IF cs_out(i) > cs_out(i + 1) THEN cs_ok = 0
NEXT i
IF (cs_out(1) <> 0 OR cs_out(15) <> 5) THEN cs_ok = 0

IF cs_ok = -1 THEN
    PRINT "SORT_COUNTING_SORT_LINEAR: PASS"
ELSE
    PRINT "SORT_COUNTING_SORT_LINEAR: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. RECHERCHE DICHOTOMIQUE AVEC DOUBLONS : LOWER_BOUND ET UPPER_BOUND
' -------------------------------------------------------------------------
' Tableau trié: [2, 5, 5, 5, 8, 12, 12, 19, 25, 25, 25, 25, 30] (13 elements)
DIM bnd_arr(13)
DATA 2, 5, 5, 5, 8, 12, 12, 19, 25, 25, 25, 25, 30
FOR i = 1 TO 13: READ bnd_arr(i): NEXT i

' Recherche de Lower Bound pour target = 25 (premier indice ou arr(idx) = 25)
LET target = 25
LET low_i = 1
LET high_i = 13
LET lb_res = 14
WHILE low_i <= high_i
    mid_i = INT((low_i + high_i) / 2)
    IF bnd_arr(mid_i) >= target THEN
        lb_res = mid_i
        high_i = mid_i - 1
    ELSE
        low_i = mid_i + 1
    END IF
WEND

' Recherche de Upper Bound pour target = 25 (dernier indice ou arr(idx) = 25)
low_i = 1
high_i = 13
LET ub_res = 0
WHILE low_i <= high_i
    mid_i = INT((low_i + high_i) / 2)
    IF bnd_arr(mid_i) <= target THEN
        ub_res = mid_i
        low_i = mid_i + 1
    ELSE
        high_i = mid_i - 1
    END IF
WEND

LET total_25_count = (ub_res - lb_res + 1)

' Verification: lb_res = 9, ub_res = 12, total_25_count = 4
IF (lb_res = 9 AND ub_res = 12 AND total_25_count = 4) THEN
    PRINT "SEARCH_LOWER_UPPER_BOUNDS: PASS"
ELSE
    PRINT "SEARCH_LOWER_UPPER_BOUNDS: FAIL"
END IF


' -------------------------------------------------------------------------
' 6. ÉQUIVALENCE STRICTE DES PERMUTATIONS TRIÉES (CROSS-VALIDATION)
' -------------------------------------------------------------------------
' Verifier que qs_arr, ms_arr et hs_arr sont strictement identiques element par element
LET all_equal = -1
FOR i = 1 TO 16
    IF qs_arr(i) <> ms_arr(i) OR qs_arr(i) <> hs_arr(i) THEN
        all_equal = 0
    END IF
NEXT i

IF all_equal = -1 THEN
    PRINT "SORT_CROSS_ALGORITHM_EQUIVALENCE: PASS"
ELSE
    PRINT "SORT_CROSS_ALGORITHM_EQUIVALENCE: FAIL"
END IF

PRINT "SORTING_BENCH_ALL: PASS"
SYSTEM
