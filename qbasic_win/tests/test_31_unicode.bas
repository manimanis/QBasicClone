' ========================================================
' UNIT TEST 31: Support Unicode & UTF-8 par défaut
' ========================================================

' 1. Littéraux et chaînes avec accents français et internationaux
LET u1$ = "Bonjour le monde: é, à, ç, è, ê, î, ô, û, ü, ñ"
IF (u1$ = "Bonjour le monde: é, à, ç, è, ê, î, ô, û, ü, ñ") THEN PRINT "UNICODE_LITERAL: PASS" ELSE PRINT "UNICODE_LITERAL: FAIL"

' 2. Caractères et symboles spéciaux (monnaie, géométrie, icônes)
LET sym$ = "Symboles: € ★ ♥ ✓ ♫ α β"
IF (sym$ = "Symboles: € ★ ♥ ✓ ♫ α β") THEN PRINT "UNICODE_SYMBOLS: PASS" ELSE PRINT "UNICODE_SYMBOLS: FAIL"

' 3. Concaténation de chaînes Unicode
LET a$ = "Été "
LET b$ = "ensoleillé ★"
LET c$ = a$ + b$
IF (c$ = "Été ensoleillé ★") THEN PRINT "UNICODE_CONCAT: PASS" ELSE PRINT "UNICODE_CONCAT: FAIL"

' 4. Comparaisons d'égalité et d'inégalité
IF ("café" = "café") THEN PRINT "UNICODE_EQ: PASS" ELSE PRINT "UNICODE_EQ: FAIL"
IF ("café" <> "thé") THEN PRINT "UNICODE_NEQ: PASS" ELSE PRINT "UNICODE_NEQ: FAIL"
IF ("café" < "cafétéria") THEN PRINT "UNICODE_LT: PASS" ELSE PRINT "UNICODE_LT: FAIL"
IF ("théâtre" > "thé") THEN PRINT "UNICODE_GT: PASS" ELSE PRINT "UNICODE_GT: FAIL"

' 5. Conversion de casse UCASE$ et LCASE$ sur caractères accentués
IF (UCASE$("café") = "CAFÉ") THEN PRINT "UNICODE_UCASE: PASS" ELSE PRINT "UNICODE_UCASE: FAIL"
IF (UCASE$("élève") = "ÉLÈVE") THEN PRINT "UNICODE_UCASE_ACCENTS: PASS" ELSE PRINT "UNICODE_UCASE_ACCENTS: FAIL"
IF (LCASE$("CAFÉ") = "café") THEN PRINT "UNICODE_LCASE: PASS" ELSE PRINT "UNICODE_LCASE: FAIL"
IF (LCASE$("ÉLÈVE") = "élève") THEN PRINT "UNICODE_LCASE_ACCENTS: PASS" ELSE PRINT "UNICODE_LCASE_ACCENTS: FAIL"
IF (UCASE$("espagnol: niño") = "ESPAGNOL: NIÑO") THEN PRINT "UNICODE_UCASE_NINO: PASS" ELSE PRINT "UNICODE_UCASE_NINO: FAIL"

' 6. Extraction de code point Unicode via ASC / UCODE
IF (ASC("A") = 65) THEN PRINT "UNICODE_ASC_ASCII: PASS" ELSE PRINT "UNICODE_ASC_ASCII: FAIL"
IF (ASC("é") = 233) THEN PRINT "UNICODE_ASC_EACUTE: PASS" ELSE PRINT "UNICODE_ASC_EACUTE: FAIL"
IF (ASC("€") = 8364) THEN PRINT "UNICODE_ASC_EURO: PASS" ELSE PRINT "UNICODE_ASC_EURO: FAIL"
IF (ASC("★") = 9733) THEN PRINT "UNICODE_ASC_STAR: PASS" ELSE PRINT "UNICODE_ASC_STAR: FAIL"
IF (UCODE("é") = 233) THEN PRINT "UNICODE_UCODE_EACUTE: PASS" ELSE PRINT "UNICODE_UCODE_EACUTE: FAIL"
IF (UCODE("€") = 8364) THEN PRINT "UNICODE_UCODE_EURO: PASS" ELSE PRINT "UNICODE_UCODE_EURO: FAIL"

' 7. Génération de caractères Unicode via CHR$ (code > 255) et UCHR$
IF (CHR$(8364) = "€") THEN PRINT "UNICODE_CHR_EURO: PASS" ELSE PRINT "UNICODE_CHR_EURO: FAIL"
IF (CHR$(9733) = "★") THEN PRINT "UNICODE_CHR_STAR: PASS" ELSE PRINT "UNICODE_CHR_STAR: FAIL"
IF (UCHR$(233) = "é") THEN PRINT "UNICODE_UCHR_EACUTE: PASS" ELSE PRINT "UNICODE_UCHR_EACUTE: FAIL"
IF (UCHR$(8364) = "€") THEN PRINT "UNICODE_UCHR_EURO: PASS" ELSE PRINT "UNICODE_UCHR_EURO: FAIL"
IF (CHR$(ASC("★")) = "★") THEN PRINT "UNICODE_ROUNDTRIP: PASS" ELSE PRINT "UNICODE_ROUNDTRIP: FAIL"

' 8. Recherche INSTR dans chaînes Unicode
IF (INSTR("Café élégant", "élégant") > 0) THEN PRINT "UNICODE_INSTR_ACCENT: PASS" ELSE PRINT "UNICODE_INSTR_ACCENT: FAIL"
IF (INSTR("Étoile ★ Polaire", "★") > 0) THEN PRINT "UNICODE_INSTR_SYMBOL: PASS" ELSE PRINT "UNICODE_INSTR_SYMBOL: FAIL"

' 9. Entrées/Sorties de fichiers UTF-8 avec accents
OPEN "test_fich_accents.tmp" FOR OUTPUT AS #1
PRINT #1, "Hôtel de l'Étoile ★ - Prix: 99 €"
PRINT #1, "Deuxième ligne: forêt enchantée"
CLOSE #1

OPEN "test_fich_accents.tmp" FOR INPUT AS #1
LINE INPUT #1, l1$
LINE INPUT #1, l2$
CLOSE #1
KILL "test_fich_accents.tmp"

IF (l1$ = "Hôtel de l'Étoile ★ - Prix: 99 €") THEN PRINT "UNICODE_FILE_IO_L1: PASS" ELSE PRINT "UNICODE_FILE_IO_L1: FAIL"
IF (l2$ = "Deuxième ligne: forêt enchantée") THEN PRINT "UNICODE_FILE_IO_L2: PASS" ELSE PRINT "UNICODE_FILE_IO_L2: FAIL"
