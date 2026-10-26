' =========================================================================
' UNIT TEST 19: Graph Algorithms & Grid Pathfinding
' (Dijkstra, BFS Maze, Kahn's Topological Sort, Warshall Cycle Detection, Flood Fill)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 19 : GRAPHES ET RECHERCHE DE CHEMINS"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. ALGORITHME DE DIJKSTRA (PLUS COURT CHEMIN PONDÉRÉ)
' -------------------------------------------------------------------------
' 6 sommets (1 à 6). Matrice d'adjacence avec poids
LET INF = 999999
DIM adj(6, 6)
FOR u = 1 TO 6
    FOR v = 1 TO 6
        adj(u, v) = INF
    NEXT v
    adj(u, u) = 0
NEXT u

' Aretes orientees
adj(1, 2) = 4: adj(1, 3) = 2
adj(2, 3) = 5: adj(2, 4) = 10
adj(3, 5) = 3
adj(5, 4) = 4
adj(4, 6) = 10: adj(5, 6) = 16

DIM dist(6)
DIM prev_node(6)
DIM visited(6)

FOR i = 1 TO 6
    dist(i) = INF
    prev_node(i) = 0
    visited(i) = 0
NEXT i
dist(1) = 0

FOR step_k = 1 TO 6
    ' Trouver sommet non visite avec dist min
    u_min = 0
    min_d = INF
    FOR i = 1 TO 6
        IF visited(i) = 0 AND dist(i) < min_d THEN
            min_d = dist(i)
            u_min = i
        END IF
    NEXT i
    
    IF u_min <> 0 THEN
        visited(u_min) = 1
        ' Relaxation des voisins
        FOR v = 1 TO 6
            IF visited(v) = 0 AND adj(u_min, v) < INF THEN
                IF dist(u_min) + adj(u_min, v) < dist(v) THEN
                    dist(v) = dist(u_min) + adj(u_min, v)
                    prev_node(v) = u_min
                END IF
            END IF
        NEXT v
    END IF
NEXT step_k

' Verification des distances calculées:
' dist(1)=0, dist(2)=4, dist(3)=2, dist(4)=9, dist(5)=5, dist(6)=19
LET dijk_ok = -1
IF (dist(1) <> 0 OR dist(2) <> 4 OR dist(3) <> 2 OR dist(4) <> 9 OR dist(5) <> 5 OR dist(6) <> 19) THEN
    dijk_ok = 0
END IF

' Reconstruction du chemin de 1 a 6: doit etre 6 <- 4 <- 5 <- 3 <- 1
DIM path_rev(6)
curr = 6
plen = 0
WHILE curr <> 0
    plen = plen + 1
    path_rev(plen) = curr
    curr = prev_node(curr)
WEND

IF (plen <> 5 OR path_rev(1) <> 6 OR path_rev(2) <> 4 OR path_rev(3) <> 5 OR path_rev(4) <> 3 OR path_rev(5) <> 1) THEN
    dijk_ok = 0
END IF

IF dijk_ok = -1 THEN
    PRINT "GRAPH_DIJKSTRA_SHORTEST_PATH: PASS"
ELSE
    PRINT "GRAPH_DIJKSTRA_SHORTEST_PATH: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. PARCOURS EN LARGEUR (BFS) DANS UN LABYRINTHE 6x6
' -------------------------------------------------------------------------
' 0 = libre, 1 = mur
DIM maze(6, 6)
DATA 0, 0, 1, 0, 0, 0
DATA 1, 0, 1, 0, 1, 0
DATA 0, 0, 0, 0, 1, 0
DATA 0, 1, 1, 0, 0, 0
DATA 0, 0, 1, 1, 1, 0
DATA 1, 0, 0, 0, 0, 0

FOR r = 1 TO 6
    FOR c = 1 TO 6
        READ cell
        maze(r, c) = cell
    NEXT c
NEXT r

' File FIFO pour BFS stockant les coordonnees (row * 10 + col)
DIM q_maze(100)
DIM m_dist(6, 6)
FOR r = 1 TO 6
    FOR c = 1 TO 6
        m_dist(r, c) = -1
    NEXT c
NEXT r

LET q_front = 1
LET q_back = 1
q_maze(q_back) = 11 ' (1, 1)
m_dist(1, 1) = 0

' Deplacements: Haut, Bas, Gauche, Droite
DIM dr(4)
DIM dc(4)
dr(1) = -1: dc(1) = 0
dr(2) = 1:  dc(2) = 0
dr(3) = 0:  dc(3) = -1
dr(4) = 0:  dc(4) = 1

WHILE q_front <= q_back
    curr_pos = q_maze(q_front)
    q_front = q_front + 1
    
    cr = INT(curr_pos / 10)
    cc = curr_pos MOD 10
    
    FOR dir = 1 TO 4
        nr = cr + dr(dir)
        nc = cc + dc(dir)
        IF nr >= 1 AND nr <= 6 AND nc >= 1 AND nc <= 6 THEN
            IF maze(nr, nc) = 0 AND m_dist(nr, nc) = -1 THEN
                m_dist(nr, nc) = m_dist(cr, cc) + 1
                q_back = q_back + 1
                q_maze(q_back) = nr * 10 + nc
            END IF
        END IF
    NEXT dir
WEND

' Distance minimale de (1, 1) a (6, 6) = 10 pas
LET maze_dist = m_dist(6, 6)
IF maze_dist = 10 THEN
    PRINT "GRAPH_GRID_BFS_MAZE: PASS"
ELSE
    PRINT "GRAPH_GRID_BFS_MAZE: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. TRI TOPOLOGIQUE D'UN DAG (ALGORITHME DE KAHN)
' -------------------------------------------------------------------------
' 6 taches: 1..6
' 1 -> 3, 1 -> 4
' 2 -> 4, 2 -> 5
' 3 -> 6
' 4 -> 3, 4 -> 6
' 5 -> 6
DIM dag(6, 6)
DIM in_degree(6)
FOR u = 1 TO 6
    in_degree(u) = 0
    FOR v = 1 TO 6
        dag(u, v) = 0
    NEXT v
NEXT u

DATA 1, 3,  1, 4
DATA 2, 4,  2, 5
DATA 3, 6
DATA 4, 3,  4, 6
DATA 5, 6
FOR e = 1 TO 8
    READ u, v
    dag(u, v) = 1
    in_degree(v) = in_degree(v) + 1
NEXT e

' File des sommets de degre entrant 0
DIM topo_q(6)
DIM topo_order(6)
LET tq_head = 1
LET tq_tail = 0

FOR u = 1 TO 6
    IF in_degree(u) = 0 THEN
        tq_tail = tq_tail + 1
        topo_q(tq_tail) = u
    END IF
NEXT u

LET topo_cnt = 0
WHILE tq_head <= tq_tail
    curr_u = topo_q(tq_head)
    tq_head = tq_head + 1
    topo_cnt = topo_cnt + 1
    topo_order(topo_cnt) = curr_u
    
    FOR v = 1 TO 6
        IF dag(curr_u, v) = 1 THEN
            in_degree(v) = in_degree(v) - 1
            IF in_degree(v) = 0 THEN
                tq_tail = tq_tail + 1
                topo_q(tq_tail) = v
            END IF
        END IF
    NEXT v
WEND

' Verifier la validite du tri topologique: pour chaque arete u->v, pos(u) < pos(v)
DIM pos_in_order(6)
FOR i = 1 TO 6
    pos_in_order(topo_order(i)) = i
NEXT i

LET topo_valid = -1
IF topo_cnt <> 6 THEN topo_valid = 0

IF (pos_in_order(1) >= pos_in_order(3) OR pos_in_order(1) >= pos_in_order(4)) THEN topo_valid = 0
IF (pos_in_order(2) >= pos_in_order(4) OR pos_in_order(2) >= pos_in_order(5)) THEN topo_valid = 0
IF (pos_in_order(4) >= pos_in_order(3) OR pos_in_order(4) >= pos_in_order(6)) THEN topo_valid = 0
IF (pos_in_order(3) >= pos_in_order(6) OR pos_in_order(5) >= pos_in_order(6)) THEN topo_valid = 0

IF topo_valid = -1 THEN
    PRINT "GRAPH_TOPOLOGICAL_SORT: PASS"
ELSE
    PRINT "GRAPH_TOPOLOGICAL_SORT: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. FERMETURE TRANSITIVE DE WARSHALL & DÉTECTION DE CYCLES
' -------------------------------------------------------------------------
' Graphe cyclique (4 sommets): 1->2, 2->3, 3->4, 4->2
DIM tc_cyc(4, 4)
FOR i = 1 TO 4: FOR j = 1 TO 4: tc_cyc(i, j) = 0: NEXT j: NEXT i
tc_cyc(1, 2) = 1: tc_cyc(2, 3) = 1: tc_cyc(3, 4) = 1: tc_cyc(4, 2) = 1

FOR k = 1 TO 4
    FOR i = 1 TO 4
        FOR j = 1 TO 4
            IF tc_cyc(i, k) = 1 AND tc_cyc(k, j) = 1 THEN tc_cyc(i, j) = 1
        NEXT j
    NEXT i
NEXT k

LET has_cycle_cyc = 0
FOR i = 1 TO 4
    IF tc_cyc(i, i) = 1 THEN has_cycle_cyc = 1
NEXT i

' Graphe acyclique (4 sommets): 1->2, 1->3, 2->4, 3->4
DIM tc_acyc(4, 4)
FOR i = 1 TO 4: FOR j = 1 TO 4: tc_acyc(i, j) = 0: NEXT j: NEXT i
tc_acyc(1, 2) = 1: tc_acyc(1, 3) = 1: tc_acyc(2, 4) = 1: tc_acyc(3, 4) = 1

FOR k = 1 TO 4
    FOR i = 1 TO 4
        FOR j = 1 TO 4
            IF tc_acyc(i, k) = 1 AND tc_acyc(k, j) = 1 THEN tc_acyc(i, j) = 1
        NEXT j
    NEXT i
NEXT k

LET has_cycle_acyc = 0
FOR i = 1 TO 4
    IF tc_acyc(i, i) = 1 THEN has_cycle_acyc = 1
NEXT i

IF (has_cycle_cyc = 1 AND has_cycle_acyc = 0) THEN
    PRINT "GRAPH_WARSHALL_CYCLE_DETECTION: PASS"
ELSE
    PRINT "GRAPH_WARSHALL_CYCLE_DETECTION: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. COMPOSANTES CONNEXES & ÉTIQUETAGE DE RÉGIONS (CONNECTED COMPONENTS)
' -------------------------------------------------------------------------
' Grille 5x5 avec 3 iles distinctes de 1
DIM grid(5, 5)
DIM label(5, 5)
DATA 1, 1, 0, 0, 1
DATA 1, 0, 0, 0, 1
DATA 0, 0, 1, 0, 0
DATA 0, 1, 1, 1, 0
DATA 0, 0, 1, 0, 0

FOR r = 1 TO 5
    FOR c = 1 TO 5
        READ v
        grid(r, c) = v
        label(r, c) = 0
    NEXT c
NEXT r

LET current_label = 0
DIM fq(50)

FOR r = 1 TO 5
    FOR c = 1 TO 5
        IF grid(r, c) = 1 AND label(r, c) = 0 THEN
            current_label = current_label + 1
            ' Flood fill BFS
            fq_head = 1
            fq_tail = 1
            fq(1) = r * 10 + c
            label(r, c) = current_label
            
            WHILE fq_head <= fq_tail
                pos_val = fq(fq_head)
                fq_head = fq_head + 1
                cr = INT(pos_val / 10)
                cc = pos_val MOD 10
                
                ' 4 directions
                FOR d = 1 TO 4
                    nr = cr + dr(d)
                    nc = cc + dc(d)
                    IF nr >= 1 AND nr <= 5 AND nc >= 1 AND nc <= 5 THEN
                        IF grid(nr, nc) = 1 AND label(nr, nc) = 0 THEN
                            label(nr, nc) = current_label
                            fq_tail = fq_tail + 1
                            fq(fq_tail) = nr * 10 + nc
                        END IF
                    END IF
                NEXT d
            WEND
        END IF
    NEXT c
NEXT r

' Compter la taille de chaque composante
DIM comp_size(10)
FOR r = 1 TO 5
    FOR c = 1 TO 5
        IF label(r, c) > 0 THEN
            lbl = label(r, c)
            comp_size(lbl) = comp_size(lbl) + 1
        END IF
    NEXT c
NEXT r

' Il y a exactement 3 iles:
' Ile 1 en haut a gauche (taille 3)
' Ile 2 en haut a droite (taille 2)
' Ile 3 en croix au centre-bas (taille 5)
IF (current_label = 3 AND comp_size(1) = 3 AND comp_size(2) = 2 AND comp_size(3) = 5) THEN
    PRINT "GRAPH_CONNECTED_COMPONENTS: PASS"
ELSE
    PRINT "GRAPH_CONNECTED_COMPONENTS: FAIL"
END IF

PRINT "GRAPH_PATHFINDING_ALL: PASS"
SYSTEM
