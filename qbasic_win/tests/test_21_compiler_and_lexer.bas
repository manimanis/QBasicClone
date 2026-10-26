' =========================================================================
' UNIT TEST 21: Compiler Theory, Lexers & Text Encodings
' (Lexer, Shunting-Yard Infix to RPN, RPN Evaluator, RLE, Base64, DFA)
' =========================================================================

PRINT "=========================================================="
PRINT "  SUITE 21 : THÉORIE DES COMPILATEURS & ENCODAGES"
PRINT "=========================================================="

' -------------------------------------------------------------------------
' 1. ANALYSEUR LEXICAL (TOKENIZER)
' -------------------------------------------------------------------------
' Entree: "LET score = ( bonus * 10 ) + 250"
LET src$ = "LET score = ( bonus * 10 ) + 250"
DIM tok_type$(20)
DIM tok_str$(20)
LET tok_cnt = 0

LET pos_src = 1
LET src_len = LEN(src$)

WHILE pos_src <= src_len
    ch$ = MID$(src$, pos_src, 1)
    
    ' Saut des espaces
    IF ch$ = " " THEN
        pos_src = pos_src + 1
    ELSEIF ch$ = "(" OR ch$ = ")" OR ch$ = "=" OR ch$ = "+" OR ch$ = "*" THEN
        tok_cnt = tok_cnt + 1
        tok_str$(tok_cnt) = ch$
        IF ch$ = "(" THEN tok_type$(tok_cnt) = "LPAREN"
        IF ch$ = ")" THEN tok_type$(tok_cnt) = "RPAREN"
        IF ch$ = "=" THEN tok_type$(tok_cnt) = "OP_ASSIGN"
        IF ch$ = "+" THEN tok_type$(tok_cnt) = "OP_ADD"
        IF ch$ = "*" THEN tok_type$(tok_cnt) = "OP_MUL"
        pos_src = pos_src + 1
    ELSEIF ch$ >= "0" AND ch$ <= "9" THEN
        num$ = ""
        WHILE pos_src <= src_len AND (MID$(src$, pos_src, 1) >= "0" AND MID$(src$, pos_src, 1) <= "9")
            num$ = num$ + MID$(src$, pos_src, 1)
            pos_src = pos_src + 1
        WEND
        tok_cnt = tok_cnt + 1
        tok_type$(tok_cnt) = "NUMBER"
        tok_str$(tok_cnt) = num$
    ELSEIF (ch$ >= "A" AND ch$ <= "Z") OR (ch$ >= "a" AND ch$ <= "z") THEN
        id$ = ""
        WHILE pos_src <= src_len AND ((MID$(src$, pos_src, 1) >= "A" AND MID$(src$, pos_src, 1) <= "Z") OR (MID$(src$, pos_src, 1) >= "a" AND MID$(src$, pos_src, 1) <= "z"))
            id$ = id$ + MID$(src$, pos_src, 1)
            pos_src = pos_src + 1
        WEND
        tok_cnt = tok_cnt + 1
        IF UCASE$(id$) = "LET" THEN
            tok_type$(tok_cnt) = "KW_LET"
        ELSE
            tok_type$(tok_cnt) = "IDENT"
        END IF
        tok_str$(tok_cnt) = id$
    ELSE
        pos_src = pos_src + 1
    END IF
WEND

' Verifier les 10 tokens:
' LET (KW_LET), score (IDENT), = (OP_ASSIGN), ( (LPAREN), bonus (IDENT), * (OP_MUL), 10 (NUMBER), ) (RPAREN), + (OP_ADD), 250 (NUMBER)
LET lex_ok = -1
IF tok_cnt <> 10 THEN lex_ok = 0
IF tok_type$(1) <> "KW_LET" OR tok_type$(2) <> "IDENT" OR tok_str$(2) <> "score" THEN lex_ok = 0
IF tok_type$(7) <> "NUMBER" OR tok_str$(7) <> "10" THEN lex_ok = 0
IF tok_type$(10) <> "NUMBER" OR tok_str$(10) <> "250" THEN lex_ok = 0

IF lex_ok = -1 THEN
    PRINT "COMPILER_LEXER_TOKENIZER: PASS"
ELSE
    PRINT "COMPILER_LEXER_TOKENIZER: FAIL"
END IF


' -------------------------------------------------------------------------
' 2. ALGORITHME SHUNTING-YARD DE DIJKSTRA (INFIXE VERS POSTFIXE / RPN)
' -------------------------------------------------------------------------
' Infixe: 3 + 4 * 2 / ( 1 - 5 ) ^ 2
' Tokens: 13
DIM inf_tok$(13)
DATA "3", "+", "4", "*", "2", "/", "(", "1", "-", "5", ")", "^", "2"
FOR ti = 1 TO 13: READ inf_tok$(ti): NEXT ti

DIM out_queue$(20)
DIM op_stack$(20)
LET out_tail = 0
LET op_sp = 0

FOR ti = 1 TO 13
    t$ = inf_tok$(ti)
    IF t$ >= "0" AND t$ <= "9" THEN
        out_tail = out_tail + 1
        out_queue$(out_tail) = t$
    ELSEIF t$ = "^" OR t$ = "*" OR t$ = "/" OR t$ = "+" OR t$ = "-" THEN
        p_cur = 0
        IF t$ = "^" THEN p_cur = 4
        IF t$ = "*" OR t$ = "/" THEN p_cur = 3
        IF t$ = "+" OR t$ = "-" THEN p_cur = 2
        
        WHILE op_sp > 0 AND op_stack$(op_sp) <> "("
            top_op$ = op_stack$(op_sp)
            p_top = 0
            IF top_op$ = "^" THEN p_top = 4
            IF top_op$ = "*" OR top_op$ = "/" THEN p_top = 3
            IF top_op$ = "+" OR top_op$ = "-" THEN p_top = 2
            
            ' Pour associativite gauche: p_top >= p_cur, pour droite (^): p_top > p_cur
            pop_cond = 0
            IF t$ = "^" THEN
                IF p_top > p_cur THEN pop_cond = 1
            ELSE
                IF p_top >= p_cur THEN pop_cond = 1
            END IF
            
            IF pop_cond = 1 THEN
                out_tail = out_tail + 1
                out_queue$(out_tail) = top_op$
                op_sp = op_sp - 1
            ELSE
                EXIT WHILE
            END IF
        WEND
        op_sp = op_sp + 1
        op_stack$(op_sp) = t$
    ELSEIF t$ = "(" THEN
        op_sp = op_sp + 1
        op_stack$(op_sp) = t$
    ELSEIF t$ = ")" THEN
        WHILE op_sp > 0 AND op_stack$(op_sp) <> "("
            out_tail = out_tail + 1
            out_queue$(out_tail) = op_stack$(op_sp)
            op_sp = op_sp - 1
        WEND
        IF op_sp > 0 AND op_stack$(op_sp) = "(" THEN op_sp = op_sp - 1
    END IF
NEXT ti

WHILE op_sp > 0
    out_tail = out_tail + 1
    out_queue$(out_tail) = op_stack$(op_sp)
    op_sp = op_sp - 1
WEND

' Postfix attendu: 3 4 2 * 1 5 - 2 ^ / +
LET rpn_str$ = ""
FOR oi = 1 TO out_tail
    rpn_str$ = rpn_str$ + out_queue$(oi) + " "
NEXT oi

IF RTRIM$(rpn_str$) = "3 4 2 * 1 5 - 2 ^ / +" THEN
    PRINT "COMPILER_SHUNTING_YARD_RPN: PASS"
ELSE
    PRINT "COMPILER_SHUNTING_YARD_RPN: FAIL"
END IF


' -------------------------------------------------------------------------
' 3. ÉVALUATEUR DE PILE RPN
' -------------------------------------------------------------------------
DIM eval_stk(20)
LET esp = 0

FOR oi = 1 TO out_tail
    item$ = out_queue$(oi)
    IF item$ >= "0" AND item$ <= "9" THEN
        esp = esp + 1
        eval_stk(esp) = VAL(item$)
    ELSE
        b_val = eval_stk(esp): esp = esp - 1
        a_val = eval_stk(esp): esp = esp - 1
        
        IF item$ = "+" THEN res_val = a_val + b_val
        IF item$ = "-" THEN res_val = a_val - b_val
        IF item$ = "*" THEN res_val = a_val * b_val
        IF item$ = "/" THEN res_val = a_val / b_val
        IF item$ = "^" THEN res_val = a_val ^ b_val
        
        esp = esp + 1
        eval_stk(esp) = res_val
    END IF
NEXT oi

LET final_rpn_val = eval_stk(1)
' 3 + 4 * 2 / (1 - 5)^2 = 3 + 8 / 16 = 3 + 0.5 = 3.5
IF (final_rpn_val = 3.5 AND esp = 1) THEN
    PRINT "COMPILER_RPN_EVALUATOR: PASS"
ELSE
    PRINT "COMPILER_RPN_EVALUATOR: FAIL"
END IF


' -------------------------------------------------------------------------
' 4. COMPRESSION ET DÉCOMPRESSION RLE (RUN-LENGTH ENCODING)
' -------------------------------------------------------------------------
LET rle_orig$ = "AAAAAABBBCCCCDDDDDDDD"
LET rle_enc$ = ""

LET p_rle = 1
LET rlen = LEN(rle_orig$)
WHILE p_rle <= rlen
    cur_ch$ = MID$(rle_orig$, p_rle, 1)
    run_len = 0
    WHILE p_rle <= rlen AND MID$(rle_orig$, p_rle, 1) = cur_ch$
        run_len = run_len + 1
        p_rle = p_rle + 1
    WEND
    rle_enc$ = rle_enc$ + LTRIM$(STR$(run_len)) + cur_ch$
WEND

' Compression: "6A3B4C8D"
' Decompression
LET rle_dec$ = ""
LET p_dec = 1
LET rle_enc_len = LEN(rle_enc$)
WHILE p_dec <= rle_enc_len
    num_str$ = ""
    WHILE p_dec <= rle_enc_len AND (MID$(rle_enc$, p_dec, 1) >= "0" AND MID$(rle_enc$, p_dec, 1) <= "9")
        num_str$ = num_str$ + MID$(rle_enc$, p_dec, 1)
        p_dec = p_dec + 1
    WEND
    ch_dec$ = MID$(rle_enc$, p_dec, 1)
    p_dec = p_dec + 1
    
    count_dec = VAL(num_str$)
    FOR rep = 1 TO count_dec
        rle_dec$ = rle_dec$ + ch_dec$
    NEXT rep
WEND

IF (rle_enc$ = "6A3B4C8D" AND rle_dec$ = rle_orig$) THEN
    PRINT "COMPILER_RLE_COMPRESSION: PASS"
ELSE
    PRINT "COMPILER_RLE_COMPRESSION: FAIL"
END IF


' -------------------------------------------------------------------------
' 5. ENCODEUR & DÉCODEUR BASE64
' -------------------------------------------------------------------------
' "QBasic" -> "UUJhc2lj"
LET b64_chars$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
LET plain$ = "QBasic"
LET b64_encoded$ = ""

' 6 octets = deux blocs de 3 octets (Q, B, a) et (s, i, c)
FOR blk = 1 TO 2
    b1 = ASC(MID$(plain$, (blk - 1) * 3 + 1, 1))
    b2 = ASC(MID$(plain$, (blk - 1) * 3 + 2, 1))
    b3 = ASC(MID$(plain$, (blk - 1) * 3 + 3, 1))
    
    ' 24 bits = b1*65536 + b2*256 + b3
    w24# = b1 * 65536 + b2 * 256 + b3
    
    c1 = INT(w24# / 262144) MOD 64
    c2 = INT(w24# / 4096) MOD 64
    c3 = INT(w24# / 64) MOD 64
    c4 = w24# MOD 64
    
    b64_encoded$ = b64_encoded$ + MID$(b64_chars$, c1 + 1, 1) + MID$(b64_chars$, c2 + 1, 1) + MID$(b64_chars$, c3 + 1, 1) + MID$(b64_chars$, c4 + 1, 1)
NEXT blk

' Decodage Base64
LET b64_decoded$ = ""
FOR blk = 1 TO 2
    c1$ = MID$(b64_encoded$, (blk - 1) * 4 + 1, 1)
    c2$ = MID$(b64_encoded$, (blk - 1) * 4 + 2, 1)
    c3$ = MID$(b64_encoded$, (blk - 1) * 4 + 3, 1)
    c4$ = MID$(b64_encoded$, (blk - 1) * 4 + 4, 1)
    
    v1 = INSTR(b64_chars$, c1$) - 1
    v2 = INSTR(b64_chars$, c2$) - 1
    v3 = INSTR(b64_chars$, c3$) - 1
    v4 = INSTR(b64_chars$, c4$) - 1
    
    w24# = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
    
    b1 = INT(w24# / 65536) MOD 256
    b2 = INT(w24# / 256) MOD 256
    b3 = w24# MOD 256
    
    b64_decoded$ = b64_decoded$ + CHR$(b1) + CHR$(b2) + CHR$(b3)
NEXT blk

IF (b64_encoded$ = "UUJhc2lj" AND b64_decoded$ = "QBasic") THEN
    PRINT "COMPILER_BASE64_ROUNDTRIP: PASS"
ELSE
    PRINT "COMPILER_BASE64_ROUNDTRIP: FAIL"
END IF


' -------------------------------------------------------------------------
' 6. AUTOMATE DÉTERMINISTE À ÉTATS FINIS (DFA RECONNAISSANCE DE FLOATS)
' -------------------------------------------------------------------------
' Etats: 1=Start, 2=IntPart, 3=Dot, 4=FracPart (Accepting), 5=Error
' Test sur "123.45" (Valide) et "12.34.5" (Invalide)

LET test_str1$ = "123.45"
LET state = 1
FOR ci = 1 TO LEN(test_str1$)
    ch$ = MID$(test_str1$, ci, 1)
    SELECT CASE state
        CASE 1
            IF ch$ >= "0" AND ch$ <= "9" THEN state = 2 ELSE state = 5
        CASE 2
            IF ch$ >= "0" AND ch$ <= "9" THEN
                state = 2
            ELSEIF ch$ = "." THEN
                state = 3
            ELSE
                state = 5
            END IF
        CASE 3
            IF ch$ >= "0" AND ch$ <= "9" THEN state = 4 ELSE state = 5
        CASE 4
            IF ch$ >= "0" AND ch$ <= "9" THEN state = 4 ELSE state = 5
        CASE 5
            EXIT FOR
    END SELECT
NEXT ci
LET acc1 = (state = 4)

LET test_str2$ = "12.34.5"
LET state = 1
FOR ci = 1 TO LEN(test_str2$)
    ch$ = MID$(test_str2$, ci, 1)
    SELECT CASE state
        CASE 1
            IF ch$ >= "0" AND ch$ <= "9" THEN state = 2 ELSE state = 5
        CASE 2
            IF ch$ >= "0" AND ch$ <= "9" THEN
                state = 2
            ELSEIF ch$ = "." THEN
                state = 3
            ELSE
                state = 5
            END IF
        CASE 3
            IF ch$ >= "0" AND ch$ <= "9" THEN state = 4 ELSE state = 5
        CASE 4
            IF ch$ >= "0" AND ch$ <= "9" THEN
                state = 4
            ELSEIF ch$ = "." THEN
                state = 5
            ELSE
                state = 5
            END IF
        CASE 5
            EXIT FOR
    END SELECT
NEXT ci
LET acc2 = (state = 4)

IF (acc1 = -1 AND acc2 = 0) THEN
    PRINT "COMPILER_DFA_STATE_MACHINE: PASS"
ELSE
    PRINT "COMPILER_DFA_STATE_MACHINE: FAIL"
END IF

PRINT "COMPILER_LEXER_ALL: PASS"
SYSTEM
