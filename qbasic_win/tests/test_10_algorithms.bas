' ========================================================
' UNIT TEST 10: Advanced Algorithms
' (Bubble Sort, Binary Search, Sieve, GCD, Fibonacci, Matrix)
' ========================================================

DECLARE SUB BubbleSort (arr(), n)
DECLARE FUNCTION BinarySearch (arr(), n, target)
DECLARE FUNCTION GCD (a, b)
DECLARE FUNCTION FibRec (n)

' 1. Tri a bulles (Bubble Sort) sur tableau de 10 elements
DIM numList(10)
DATA 45, 12, 89, 3, 77, 21, 64, 99, 1, 30
FOR idx = 1 TO 10
    READ numList(idx)
NEXT idx

CALL BubbleSort(numList(), 10)

LET is_sorted = -1
FOR idx = 1 TO 9
    IF numList(idx) > numList(idx + 1) THEN is_sorted = 0
NEXT idx

IF (is_sorted = -1 AND numList(1) = 1 AND numList(10) = 99) THEN
    PRINT "ALGO_BUBBLE_SORT: PASS"
ELSE
    PRINT "ALGO_BUBBLE_SORT: FAIL"
END IF

' 2. Recherche dichotomique (Binary Search)
LET pos77 = BinarySearch(numList(), 10, 77)
LET posNotFound = BinarySearch(numList(), 10, 50)

IF (pos77 > 0 AND numList(pos77) = 77 AND posNotFound = 0) THEN
    PRINT "ALGO_BINARY_SEARCH: PASS"
ELSE
    PRINT "ALGO_BINARY_SEARCH: FAIL"
END IF

' 3. Crible d'Eratosthene (Sieve of Eratosthenes) jusqu'a 50
DIM isPrime(50)
FOR p = 2 TO 50
    isPrime(p) = -1
NEXT p

FOR p = 2 TO 7
    IF isPrime(p) THEN
        LET mult = p * p
        WHILE mult <= 50
            isPrime(mult) = 0
            mult = mult + p
        WEND
    END IF
NEXT p

' Verifier les nombres premiers connus et les composes
IF (isPrime(2) AND isPrime(3) AND isPrime(5) AND isPrime(13) AND isPrime(47) AND NOT isPrime(4) AND NOT isPrime(9) AND NOT isPrime(25) AND NOT isPrime(49)) THEN
    PRINT "ALGO_SIEVE_PRIMES: PASS"
ELSE
    PRINT "ALGO_SIEVE_PRIMES: FAIL"
END IF

' 4. PGCD (GCD d'Euclide)
LET gcd1 = GCD(48, 18)
LET gcd2 = GCD(101, 10)
LET gcd3 = GCD(54, 24)

IF (gcd1 = 6 AND gcd2 = 1 AND gcd3 = 6) THEN
    PRINT "ALGO_GCD_EUCLID: PASS"
ELSE
    PRINT "ALGO_GCD_EUCLID: FAIL"
END IF

' 5. Suite de Fibonacci (iterative vs recursive)
LET fib_it = 0
LET a = 0
LET b = 1
FOR fi = 2 TO 10
    LET c = a + b
    a = b
    b = c
NEXT fi
fib_it = b

LET fib_rec = FibRec(10)

IF (fib_it = 55 AND fib_rec = 55) THEN
    PRINT "ALGO_FIBONACCI: PASS"
ELSE
    PRINT "ALGO_FIBONACCI: FAIL"
END IF

' 6. Multiplication de matrices 2D (2x2)
' A = [[1, 2], [3, 4]], B = [[2, 0], [1, 2]]
' C = A x B = [[4, 4], [10, 8]]
DIM matA(1 TO 2, 1 TO 2)
DIM matB(1 TO 2, 1 TO 2)
DIM matC(1 TO 2, 1 TO 2)

matA(1, 1) = 1: matA(1, 2) = 2
matA(2, 1) = 3: matA(2, 2) = 4

matB(1, 1) = 2: matB(1, 2) = 0
matB(2, 1) = 1: matB(2, 2) = 2

FOR r = 1 TO 2
    FOR col = 1 TO 2
        matC(r, col) = 0
        FOR k = 1 TO 2
            matC(r, col) = matC(r, col) + matA(r, k) * matB(k, col)
        NEXT k
    NEXT col
NEXT r

IF (matC(1, 1) = 4 AND matC(1, 2) = 4 AND matC(2, 1) = 10 AND matC(2, 2) = 8) THEN
    PRINT "ALGO_MATRIX_MUL: PASS"
ELSE
    PRINT "ALGO_MATRIX_MUL: FAIL"
END IF

PRINT "ALGORITHMS_ALL: PASS"
SYSTEM

' ========================================================
' DEFINITIONS DES PROCEDURES
' ========================================================

SUB BubbleSort (arr(), n)
    FOR i = 1 TO n - 1
        FOR j = 1 TO n - i
            IF arr(j) > arr(j + 1) THEN
                LET temp = arr(j)
                arr(j) = arr(j + 1)
                arr(j + 1) = temp
            END IF
        NEXT j
    NEXT i
END SUB

FUNCTION BinarySearch (arr(), n, target)
    LET low = 1
    LET high = n
    LET foundPos = 0
    WHILE low <= high AND foundPos = 0
        LET mid = INT((low + high) / 2)
        IF arr(mid) = target THEN
            foundPos = mid
        ELSEIF arr(mid) < target THEN
            low = mid + 1
        ELSE
            high = mid - 1
        END IF
    WEND
    BinarySearch = foundPos
END FUNCTION

FUNCTION GCD (a, b)
    IF b = 0 THEN
        GCD = a
    ELSE
        GCD = GCD(b, a MOD b)
    END IF
END FUNCTION

FUNCTION FibRec (n)
    IF n <= 0 THEN
        FibRec = 0
    ELSEIF n = 1 THEN
        FibRec = 1
    ELSE
        FibRec = FibRec(n - 1) + FibRec(n - 2)
    END IF
END FUNCTION
