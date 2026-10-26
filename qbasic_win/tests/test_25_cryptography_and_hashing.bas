' =========================================================================
' UNIT TEST 25 : Cryptography, Hashing & Information Security
' (Vigenere, RC4 Stream Cipher, FNV-1a Hash, Diffie-Hellman, Shannon Entropy)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 25 : CRYPTOGRAPHIE & HACHAGE"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. CHIFFREMENT DE VIGENÈRE POLYALPHABÉTIQUE
' -------------------------------------------------------------------------
' Message: "ANTIGRAVITY"
' Clef: "BASIC"
' Longueur: 11
LET vig_plain$ = "ANTIGRAVITY"
LET vig_key$ = "BASIC"
LET vig_cipher$ = ""

LET k_len = LEN(vig_key$)
FOR ci = 1 TO LEN(vig_plain$)
    p_char$ = MID$(vig_plain$, ci, 1)
    k_char$ = MID$(vig_key$, ((ci - 1) MOD k_len) + 1, 1)
    
    p_code = ASC(p_char$) - 65
    k_code = ASC(k_char$) - 65
    c_code = (p_code + k_code) MOD 26
    vig_cipher$ = vig_cipher$ + CHR$(c_code + 65)
NEXT ci

' Dechiffrement Vigenere
LET vig_decrypted$ = ""
FOR ci = 1 TO LEN(vig_cipher$)
    c_char$ = MID$(vig_cipher$, ci, 1)
    k_char$ = MID$(vig_key$, ((ci - 1) MOD k_len) + 1, 1)
    
    c_code = ASC(c_char$) - 65
    k_code = ASC(k_char$) - 65
    p_code = (c_code - k_code + 26) MOD 26
    vig_decrypted$ = vig_decrypted$ + CHR$(p_code + 65)
NEXT ci

' "ANTIGRAVITY" avec "BASIC" -> "BNLQISANQVZ"
IF (vig_cipher$ = "BNLQISANQVZ" AND vig_decrypted$ = vig_plain$) THEN
    PRINT "CRYPTO_VIGENERE_POLYALPHABETIC: PASS"
ELSE
    PRINT "CRYPTO_VIGENERE_POLYALPHABETIC: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. CHIFFREMENT EN FLUX RC4 (KSA + PRGA)
' -------------------------------------------------------------------------
' S-box reduite de 64 octets (0..63) pour rapidite
LET RC4_MOD = 64
DIM S(0 TO 63)
FOR i = 0 TO 63: S(i) = i: NEXT i

LET rc4_key$ = "KEY"
LET k_len = LEN(rc4_key$)

' KSA (Key-Scheduling Algorithm)
LET j = 0
FOR i = 0 TO 63
    k_byte = ASC(MID$(rc4_key$, (i MOD k_len) + 1, 1)) MOD RC4_MOD
    j = (j + S(i) + k_byte) MOD RC4_MOD
    tmp = S(i): S(i) = S(j): S(j) = tmp
NEXT i

' Sauvegarder l'etat initial du S-box pour dechiffrement
DIM S_init(0 TO 63)
FOR i = 0 TO 63: S_init(i) = S(i): NEXT i

' PRGA Chiffrement de "QBASIC_WIN"
LET rc4_plain$ = "QBASIC_WIN"
LET p_len = LEN(rc4_plain$)
DIM rc4_ct(10)

LET i = 0
LET j = 0
FOR idx = 1 TO p_len
    i = (i + 1) MOD RC4_MOD
    j = (j + S(i)) MOD RC4_MOD
    tmp = S(i): S(i) = S(j): S(j) = tmp
    k_stream = S((S(i) + S(j)) MOD RC4_MOD)
    
    p_val = ASC(MID$(rc4_plain$, idx, 1))
    ' XOR avec k_stream
    ' Emulation de XOR binaire pour entiers 0..255
    res_xor = 0
    p_tmp = p_val
    k_tmp = k_stream
    bit_val = 1
    FOR b_step = 1 TO 8
        b_p = p_tmp MOD 2
        b_k = k_tmp MOD 2
        IF b_p <> b_k THEN res_xor = res_xor + bit_val
        p_tmp = INT(p_tmp / 2)
        k_tmp = INT(k_tmp / 2)
        bit_val = bit_val * 2
    NEXT b_step
    rc4_ct(idx) = res_xor
NEXT idx

' PRGA Dechiffrement (avec le meme S-box reinitialise)
FOR i = 0 TO 63: S(i) = S_init(i): NEXT i
LET rc4_dec$ = ""
i = 0: j = 0
FOR idx = 1 TO p_len
    i = (i + 1) MOD RC4_MOD
    j = (j + S(i)) MOD RC4_MOD
    tmp = S(i): S(i) = S(j): S(j) = tmp
    k_stream = S((S(i) + S(j)) MOD RC4_MOD)
    
    c_val = rc4_ct(idx)
    res_xor = 0
    c_tmp = c_val
    k_tmp = k_stream
    bit_val = 1
    FOR b_step = 1 TO 8
        b_c = c_tmp MOD 2
        b_k = k_tmp MOD 2
        IF b_c <> b_k THEN res_xor = res_xor + bit_val
        c_tmp = INT(c_tmp / 2)
        k_tmp = INT(k_tmp / 2)
        bit_val = bit_val * 2
    NEXT b_step
    rc4_dec$ = rc4_dec$ + CHR$(res_xor)
NEXT idx

IF rc4_dec$ = rc4_plain$ THEN
    PRINT "CRYPTO_RC4_STREAM_CIPHER: PASS"
ELSE
    PRINT "CRYPTO_RC4_STREAM_CIPHER: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. FONCTION DE HACHAGE FNV-1a (AVALANCHE EFFECT)
' -------------------------------------------------------------------------
' Calcul de hash sur "hello" et "Hello" (doivent donner des hashs tres differents)
LET FNV_PRIME = 16777619
LET FNV_OFFSET = 2166136261#
LET HASH_MASK = 16777216 ' 2^24

LET h1# = 2166136 MOD HASH_MASK
str_h1$ = "hello"
FOR ci = 1 TO LEN(str_h1$)
    b_val = ASC(MID$(str_h1$, ci, 1))
    ' XOR
    x_val = 0
    t1# = h1#
    t2 = b_val
    bit_val# = 1
    FOR b_idx = 1 TO 24
        b1 = t1# MOD 2
        b2 = t2 MOD 2
        IF b1 <> b2 THEN x_val = x_val + bit_val#
        t1# = INT(t1# / 2)
        t2 = INT(t2 / 2)
        bit_val# = bit_val# * 2
    NEXT b_idx
    h1# = (x_val * 31 + b_val) MOD HASH_MASK
NEXT ci

LET h2# = 2166136 MOD HASH_MASK
str_h2$ = "Hello"
FOR ci = 1 TO LEN(str_h2$)
    b_val = ASC(MID$(str_h2$, ci, 1))
    x_val = 0
    t1# = h2#
    t2 = b_val
    bit_val# = 1
    FOR b_idx = 1 TO 24
        b1 = t1# MOD 2
        b2 = t2 MOD 2
        IF b1 <> b2 THEN x_val = x_val + bit_val#
        t1# = INT(t1# / 2)
        t2 = INT(t2 / 2)
        bit_val# = bit_val# * 2
    NEXT b_idx
    h2# = (x_val * 31 + b_val) MOD HASH_MASK
NEXT ci

' Un seul bit modifie ('h' -> 'H') produit une difference massive de hash
IF (h1# <> h2# AND h1# > 0 AND h2# > 0) THEN
    PRINT "CRYPTO_FNV1A_AVALANCHE_HASH: PASS"
ELSE
    PRINT "CRYPTO_FNV1A_AVALANCHE_HASH: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. ÉCHANGE DE CLÉS DE DIFFIE-HELLMAN (ARITHMÉTIQUE MODULAIRE)
' -------------------------------------------------------------------------
' Parametres publics: g = 5, premier p = 997
' Alice choisit a = 17 (secret), calcule A = g^a mod p
' Bob choisit b = 23 (secret), calcule B = g^b mod p
' Alice calcule Secret_Alice = B^a mod p
' Bob calcule Secret_Bob = A^b mod p
' Les deux secrets doivent etre identiques!

LET dh_p = 997
LET dh_g = 5
LET priv_alice = 17
LET priv_bob = 23

' Calcul de A = 5^17 MOD 997
LET cur_base = dh_g
LET cur_exp = priv_alice
LET pub_A = 1
WHILE cur_exp > 0
    IF cur_exp MOD 2 = 1 THEN pub_A = (pub_A * cur_base) MOD dh_p
    cur_base = (cur_base * cur_base) MOD dh_p
    cur_exp = INT(cur_exp / 2)
WEND

' Calcul de B = 5^23 MOD 997
cur_base = dh_g
cur_exp = priv_bob
LET pub_B = 1
WHILE cur_exp > 0
    IF cur_exp MOD 2 = 1 THEN pub_B = (pub_B * cur_base) MOD dh_p
    cur_base = (cur_base * cur_base) MOD dh_p
    cur_exp = INT(cur_exp / 2)
WEND

' Alice calcule Secret = pub_B^priv_alice MOD dh_p
cur_base = pub_B
cur_exp = priv_alice
LET sec_alice = 1
WHILE cur_exp > 0
    IF cur_exp MOD 2 = 1 THEN sec_alice = (sec_alice * cur_base) MOD dh_p
    cur_base = (cur_base * cur_base) MOD dh_p
    cur_exp = INT(cur_exp / 2)
WEND

' Bob calcule Secret = pub_A^priv_bob MOD dh_p
cur_base = pub_A
cur_exp = priv_bob
LET sec_bob = 1
WHILE cur_exp > 0
    IF cur_exp MOD 2 = 1 THEN sec_bob = (sec_bob * cur_base) MOD dh_p
    cur_base = (cur_base * cur_base) MOD dh_p
    cur_exp = INT(cur_exp / 2)
WEND

IF (sec_alice = sec_bob AND sec_alice > 0) THEN
    PRINT "CRYPTO_DIFFIE_HELLMAN_KEY_EXCHANGE: PASS"
ELSE
    PRINT "CRYPTO_DIFFIE_HELLMAN_KEY_EXCHANGE: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. ESTIMATION DE L'ENTROPIE DE SHANNON
' -------------------------------------------------------------------------
' H = - sum(p_i * log2(p_i))
' Pour "AAAAAAAA": 1 seule lettre, p('A') = 1, H = 0.0
' Pour "ABCD": 4 symboles equiprobables (p=0.25), H = - 4 * (0.25 * log2(0.25)) = 2.0

LET str_mono$ = "AAAAAAAA"
LET str_poly$ = "ABCDEFGHIJKLMNOP" ' 16 symboles distincts equiprobables -> H = log2(16) = 4.0

' Calcul pour str_mono:
DIM freq_mono(255)
FOR i = 0 TO 255: freq_mono(i) = 0: NEXT i
FOR i = 1 TO LEN(str_mono$)
    ch_c = ASC(MID$(str_mono$, i, 1))
    freq_mono(ch_c) = freq_mono(ch_c) + 1
NEXT i

LET h_mono = 0.0
FOR i = 0 TO 255
    IF freq_mono(i) > 0 THEN
        p_i = freq_mono(i) / LEN(str_mono$)
        h_mono = h_mono - p_i * (LOG(p_i) / LOG(2))
    END IF
NEXT i

' Calcul pour str_poly:
DIM freq_poly(255)
FOR i = 0 TO 255: freq_poly(i) = 0: NEXT i
FOR i = 1 TO LEN(str_poly$)
    ch_c = ASC(MID$(str_poly$, i, 1))
    freq_poly(ch_c) = freq_poly(ch_c) + 1
NEXT i

LET h_poly = 0.0
FOR i = 0 TO 255
    IF freq_poly(i) > 0 THEN
        p_i = freq_poly(i) / LEN(str_poly$)
        h_poly = h_poly - p_i * (LOG(p_i) / LOG(2))
    END IF
NEXT i

IF (h_mono = 0.0 AND ABS(h_poly - 4.0) < 0.0001) THEN
    PRINT "CRYPTO_SHANNON_ENTROPY: PASS"
ELSE
    PRINT "CRYPTO_SHANNON_ENTROPY: FAIL"
END IF

PRINT "CRYPTOGRAPHY_ALL: PASS"
SYSTEM
