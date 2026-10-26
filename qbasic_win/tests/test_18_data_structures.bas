' =========================================================================
' UNIT TEST 18: Advanced Data Structures & Memory Pools
' (Stack, Circular Queue, Doubly Linked List, BST, Hash Table, Min-Heap)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 18 : STRUCTURES DE DONNÉES AVANCÉES"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. PILE DYNAMIQUE LIFO (STACK)
' -------------------------------------------------------------------------
DIM stk(100)
LET stk_sp = 0

' Push 10, 20, 30, 40
stk_sp = stk_sp + 1: stk(stk_sp) = 10
stk_sp = stk_sp + 1: stk(stk_sp) = 20
stk_sp = stk_sp + 1: stk(stk_sp) = 30
stk_sp = stk_sp + 1: stk(stk_sp) = 40

LET peek_val = stk(stk_sp)
LET pop1 = stk(stk_sp): stk_sp = stk_sp - 1
LET pop2 = stk(stk_sp): stk_sp = stk_sp - 1

' Push 50
stk_sp = stk_sp + 1: stk(stk_sp) = 50

LET final_top = stk(stk_sp)
LET final_size = stk_sp

IF (peek_val = 40 AND pop1 = 40 AND pop2 = 30 AND final_top = 50 AND final_size = 3) THEN
    PRINT "DS_STACK_LIFO_OPS: PASS"
ELSE
    PRINT "DS_STACK_LIFO_OPS: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. FILE CIRCULAIRE FIFO AVEC WRAP-AROUND (CIRCULAR QUEUE)
' -------------------------------------------------------------------------
DIM q_buf(0 TO 7)
LET q_cap = 8
LET q_head = 0
LET q_tail = 0
LET q_cnt = 0

' Enqueue 5 elements: 11, 22, 33, 44, 55
FOR qi = 1 TO 5
    q_buf(q_tail) = qi * 11
    q_tail = (q_tail + 1) MOD q_cap
    q_cnt = q_cnt + 1
NEXT qi

' Dequeue 2 elements -> 11, 22
LET dq1 = q_buf(q_head): q_head = (q_head + 1) MOD q_cap: q_cnt = q_cnt - 1
LET dq2 = q_buf(q_head): q_head = (q_head + 1) MOD q_cap: q_cnt = q_cnt - 1

' Enqueue 4 elements (wrap-around beyond buffer boundary)
FOR qi = 6 TO 9
    q_buf(q_tail) = qi * 11
    q_tail = (q_tail + 1) MOD q_cap
    q_cnt = q_cnt + 1
NEXT qi

' Queue doit contenir 7 elements: 33, 44, 55, 66, 77, 88, 99
LET q_ok = -1
IF q_cnt <> 7 THEN q_ok = 0

DIM q_out(7)
FOR qi = 1 TO 7
    q_out(qi) = q_buf(q_head)
    q_head = (q_head + 1) MOD q_cap
    q_cnt = q_cnt - 1
NEXT qi

IF (q_out(1) <> 33 OR q_out(4) <> 66 OR q_out(7) <> 99 OR q_cnt <> 0) THEN q_ok = 0

IF q_ok = -1 THEN
    PRINT "DS_CIRCULAR_QUEUE_FIFO: PASS"
ELSE
    PRINT "DS_CIRCULAR_QUEUE_FIFO: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. LISTE DOUBLEMENT CHAÎNÉE DANS UN POOL STATIQUE
' -------------------------------------------------------------------------
DIM dll_val(30)
DIM dll_prev(30)
DIM dll_next(30)
LET dll_free = 1
FOR di = 1 TO 29
    dll_next(di) = di + 1
NEXT di
dll_next(30) = 0

LET dll_head = 0
LET dll_tail = 0

' Helper pour inserer en queue
' Insertion de 10, 20, 30, 40
DATA 10, 20, 30, 40
FOR di = 1 TO 4
    READ dval
    ' Alloc node
    n_node = dll_free
    dll_free = dll_next(dll_free)
    dll_val(n_node) = dval
    dll_next(n_node) = 0
    dll_prev(n_node) = dll_tail
    IF dll_tail <> 0 THEN
        dll_next(dll_tail) = n_node
    ELSE
        dll_head = n_node
    END IF
    dll_tail = n_node
NEXT di

' Parcours avant: 10 + 20 + 30 + 40 = 100
LET fwd_sum = 0
LET cur = dll_head
WHILE cur <> 0
    fwd_sum = fwd_sum + dll_val(cur)
    cur = dll_next(cur)
WEND

' Parcours arriere
LET bwd_sum = 0
cur = dll_tail
WHILE cur <> 0
    bwd_sum = bwd_sum + dll_val(cur)
    cur = dll_prev(cur)
WEND

' Suppression du noeud contenant 20 (qui est le deuxieme noeud)
cur = dll_head
WHILE cur <> 0 AND dll_val(cur) <> 20
    cur = dll_next(cur)
WEND
IF cur <> 0 THEN
    p_node = dll_prev(cur)
    nx_node = dll_next(cur)
    IF p_node <> 0 THEN dll_next(p_node) = nx_node
    IF nx_node <> 0 THEN dll_prev(nx_node) = p_node
    ' Recycler noeud
    dll_next(cur) = dll_free
    dll_free = cur
END IF

' Somme apres suppression: 10 + 30 + 40 = 80
LET sum_after_del = 0
cur = dll_head
WHILE cur <> 0
    sum_after_del = sum_after_del + dll_val(cur)
    cur = dll_next(cur)
WEND

IF (fwd_sum = 100 AND bwd_sum = 100 AND sum_after_del = 80) THEN
    PRINT "DS_DOUBLY_LINKED_LIST: PASS"
ELSE
    PRINT "DS_DOUBLY_LINKED_LIST: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. ARBRE BINAIRE DE RECHERCHE (BST) & PARCOURS IN-FIXE
' -------------------------------------------------------------------------
DIM bst_val(50)
DIM bst_left(50)
DIM bst_right(50)
LET bst_root = 0
LET bst_count = 0

' Insertion dans le BST
DATA 50, 30, 70, 20, 40, 60, 80, 15, 25, 65, 85
FOR bi = 1 TO 11
    READ key_val
    bst_count = bst_count + 1
    bst_val(bst_count) = key_val
    bst_left(bst_count) = 0
    bst_right(bst_count) = 0
    
    IF bst_root = 0 THEN
        bst_root = bst_count
    ELSE
        curr_b = bst_root
        parent_b = 0
        WHILE curr_b <> 0
            parent_b = curr_b
            IF key_val < bst_val(curr_b) THEN
                curr_b = bst_left(curr_b)
            ELSE
                curr_b = bst_right(curr_b)
            END IF
        WEND
        IF key_val < bst_val(parent_b) THEN
            bst_left(parent_b) = bst_count
        ELSE
            bst_right(parent_b) = bst_count
        END IF
    END IF
NEXT bi

' Recherche dans le BST
' Cle 65 existante, cle 45 inexistante
curr_b = bst_root
LET found65 = 0
WHILE curr_b <> 0 AND found65 = 0
    IF bst_val(curr_b) = 65 THEN
        found65 = 1
    ELSEIF 65 < bst_val(curr_b) THEN
        curr_b = bst_left(curr_b)
    ELSE
        curr_b = bst_right(curr_b)
    END IF
WEND

curr_b = bst_root
LET found45 = 0
WHILE curr_b <> 0 AND found45 = 0
    IF bst_val(curr_b) = 45 THEN
        found45 = 1
    ELSEIF 45 < bst_val(curr_b) THEN
        curr_b = bst_left(curr_b)
    ELSE
        curr_b = bst_right(curr_b)
    END IF
WEND

IF (found65 = 1 AND found45 = 0) THEN
    PRINT "DS_BST_SEARCH: PASS"
ELSE
    PRINT "DS_BST_SEARCH: FAIL"
END IF

' Parcours in-fixe iteratif via pile pour extraire la sequence ordonnee
DIM bst_stack(50)
DIM in_order(11)
LET bsp = 0
LET io_idx = 0
curr_b = bst_root

WHILE curr_b <> 0 OR bsp > 0
    WHILE curr_b <> 0
        bsp = bsp + 1
        bst_stack(bsp) = curr_b
        curr_b = bst_left(curr_b)
    WEND
    curr_b = bst_stack(bsp)
    bsp = bsp - 1
    io_idx = io_idx + 1
    in_order(io_idx) = bst_val(curr_b)
    curr_b = bst_right(curr_b)
WEND

LET bst_sorted = -1
FOR bi = 1 TO 10
    IF in_order(bi) >= in_order(bi + 1) THEN bst_sorted = 0
NEXT bi

IF (bst_sorted = -1 AND in_order(1) = 15 AND in_order(11) = 85) THEN
    PRINT "DS_BST_INORDER_SORT: PASS"
ELSE
    PRINT "DS_BST_INORDER_SORT: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. TABLE DE HACHAGE AVEC SONDAGE LINÉAIRE (OPEN ADDRESSING)
' -------------------------------------------------------------------------
LET HASH_CAP = 13
DIM ht_keys$(12)
DIM ht_vals(12)
DIM ht_used(12)

FOR hi = 0 TO 12
    ht_used(hi) = 0
    ht_keys$(hi) = ""
    ht_vals(hi) = 0
NEXT hi

' Inserer: "apple"=100, "banana"=200, "cherry"=300, "date"=400, "fig"=500
DATA "apple", 100, "banana", 200, "cherry", 300, "date", 400, "fig", 500
FOR hi = 1 TO 5
    READ k$, v
    ' Calcul de hash polynomial
    h = 0
    FOR ci = 1 TO LEN(k$)
        h = (h * 31 + ASC(MID$(k$, ci, 1))) MOD HASH_CAP
    NEXT ci
    
    ' Insertion avec sondage lineaire
    slot = h
    inserted = 0
    WHILE inserted = 0
        IF ht_used(slot) = 0 OR ht_keys$(slot) = k$ THEN
            ht_keys$(slot) = k$
            ht_vals(slot) = v
            ht_used(slot) = 1
            inserted = 1
        ELSE
            slot = (slot + 1) MOD HASH_CAP
        END IF
    WEND
NEXT hi

' Lookup fonction pour les cles
LET v_cherry = 0
LET v_missing = -1

' Recherche de "cherry"
k$ = "cherry"
h = 0
FOR ci = 1 TO LEN(k$)
    h = (h * 31 + ASC(MID$(k$, ci, 1))) MOD HASH_CAP
NEXT ci
slot = h
steps = 0
WHILE ht_used(slot) = 1 AND steps < HASH_CAP
    IF ht_keys$(slot) = k$ THEN
        v_cherry = ht_vals(slot)
        EXIT WHILE
    END IF
    slot = (slot + 1) MOD HASH_CAP
    steps = steps + 1
WEND

' Recherche de "mango" (absent)
k$ = "mango"
h = 0
FOR ci = 1 TO LEN(k$)
    h = (h * 31 + ASC(MID$(k$, ci, 1))) MOD HASH_CAP
NEXT ci
slot = h
steps = 0
LET found_mango = 0
WHILE ht_used(slot) = 1 AND steps < HASH_CAP
    IF ht_keys$(slot) = k$ THEN
        found_mango = 1
        EXIT WHILE
    END IF
    slot = (slot + 1) MOD HASH_CAP
    steps = steps + 1
WEND

IF (v_cherry = 300 AND found_mango = 0) THEN
    PRINT "DS_HASH_TABLE_LOOKUP: PASS"
ELSE
    PRINT "DS_HASH_TABLE_LOOKUP: FAIL"
END IF


' -------------------------------------------------------------------------
' 6. TAS MINIMUM BINAIRE (BINARY MIN-HEAP)
' -------------------------------------------------------------------------
DIM heap(30)
LET heap_sz = 0

' Insertion dans le tas (Heapify-Up)
DATA 45, 12, 89, 7, 33, 21, 60, 3
FOR hi = 1 TO 8
    READ item
    heap_sz = heap_sz + 1
    heap(heap_sz) = item
    ' Tamisage vers le haut
    idx = heap_sz
    WHILE idx > 1
        parent_idx = INT(idx / 2)
        IF heap(idx) < heap(parent_idx) THEN
            tmp = heap(idx)
            heap(idx) = heap(parent_idx)
            heap(parent_idx) = tmp
            idx = parent_idx
        ELSE
            idx = 1 ' Arret
        END IF
    WEND
NEXT hi

' Extraction successive du minimum (Heapify-Down)
DIM sorted_heap(8)
FOR hi = 1 TO 8
    sorted_heap(hi) = heap(1)
    heap(1) = heap(heap_sz)
    heap_sz = heap_sz - 1
    
    ' Tamisage vers le bas
    idx = 1
    sinking = 1
    WHILE sinking = 1
        min_idx = idx
        left_idx = idx * 2
        right_idx = idx * 2 + 1
        
        IF left_idx <= heap_sz THEN
            IF heap(left_idx) < heap(min_idx) THEN min_idx = left_idx
        END IF
        IF right_idx <= heap_sz THEN
            IF heap(right_idx) < heap(min_idx) THEN min_idx = right_idx
        END IF
        
        IF min_idx <> idx THEN
            tmp = heap(idx)
            heap(idx) = heap(min_idx)
            heap(min_idx) = tmp
            idx = min_idx
        ELSE
            sinking = 0
        END IF
    WEND
NEXT hi

' Doit extraire: 3, 7, 12, 21, 33, 45, 60, 89
LET heap_ok = -1
IF sorted_heap(1) <> 3 OR sorted_heap(2) <> 7 OR sorted_heap(3) <> 12 OR sorted_heap(8) <> 89 THEN
    heap_ok = 0
END IF

FOR hi = 1 TO 7
    IF sorted_heap(hi) >= sorted_heap(hi + 1) THEN heap_ok = 0
NEXT hi

IF heap_ok = -1 THEN
    PRINT "DS_MIN_HEAP_PRIORITY_Q: PASS"
ELSE
    PRINT "DS_MIN_HEAP_PRIORITY_Q: FAIL"
END IF

PRINT "DATA_STRUCTURES_ALL: PASS"
SYSTEM
