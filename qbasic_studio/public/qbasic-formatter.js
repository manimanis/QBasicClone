// qbasic-formatter.js - Formateur de code QBasic professionnel pour Monaco Editor
// Indentation intelligente, normalisation de la casse des mots-clés et espacement
(function() {
    // 1. Liste exhaustive des mots-clés et fonctions intrinsèques officielles QBasic / QuickBASIC
    const KEYWORDS = new Set([
        'ABS', 'ACCESS', 'AND', 'ANY', 'APPEND', 'AS', 'ASC', 'ATN', 'BASE', 'BEEP',
        'BINARY', 'BLOAD', 'BOOLEAN', 'BSAVE', 'BYVAL', 'CALL', 'CALLS', 'CASE',
        'CDBL', 'CDECL', 'CHAIN', 'CHDIR', 'CHR$', 'UCHR$', '_UCHR$', 'CINT', 'CIRCLE',
        'CLEAR', 'CLNG', 'CLOSE', 'CLS', 'COLOR', 'COM', 'COMMAND$', 'COMMON', 'CONST',
        'COS', 'CSNG', 'CSRLIN', 'CVD', 'CVDMBF', 'CVI', 'CVL', 'CVS', 'CVSMBF', 'DATA',
        'DATE$', 'DECLARE', 'DEF', 'DEFDBL', 'DEFINT', 'DEFLNG', 'DEFSNG', 'DEFSTR',
        'DEF SEG', 'DIM', 'DO', 'DOUBLE', 'DRAW', 'ELSE', 'ELSEIF', 'END', 'END DEF',
        'END FUNCTION', 'END IF', 'END SELECT', 'END SUB', 'END TYPE', 'ENVIRON', 'ENVIRON$',
        'EOF', 'EQV', 'ERASE', 'ERDEV', 'ERDEV$', 'ERL', 'ERR', 'ERROR', '_ERROR$',
        '_ERRORMESSAGE$', 'EXIT', 'EXP', 'FIELD', 'FILEATTR', 'FILES', 'FIX', 'FN',
        'FOR', 'FRE', 'FREEFILE', 'FUNCTION', 'GET', 'GOSUB', 'GOTO', 'HEX$', 'IF',
        'IMP', 'INKEY$', 'INP', 'INPUT', 'INPUT$', 'INSTR', 'INT', 'INTEGER', 'IOCTL',
        'IOCTL$', 'IS', 'KEY', 'KILL', 'LBOUND', 'LCASE$', 'LEFT$', 'LEFT', 'LEN',
        'LET', 'LINE', 'LINE INPUT', 'LOC', 'LOCATE', 'LOCK', 'LOF', 'LOG', 'LONG',
        'LOOP', 'LPOS', 'LPRINT', 'LSET', 'LTRIM$', 'LTRIM', 'MID$', 'MID', 'MKD$',
        'MKDMBF$', 'MKDIR', 'MKI$', 'MKL$', 'MKS$', 'MKSMBF$', 'MOD', 'NAME', 'NEXT',
        'NOT', 'OCT$', 'OFF', 'ON', 'ON ERROR GOTO', 'ON TIMER', 'ON KEY', 'ON PLAY',
        'OPEN', 'OPTION', 'OPTION BASE', 'OR', 'OUT', 'OUTPUT', 'PAINT', 'PALETTE',
        'PCOPY', 'PEEK', 'PEN', 'PLAY', 'PMAP', 'POINT', 'POKE', 'POS', 'PRESET',
        'PRINT', 'PRINT USING', 'PSET', 'PUT', 'RANDOM', 'RANDOMIZE', 'READ', 'REDIM',
        'REM', 'RESET', 'RESTORE', 'RESUME', 'RETURN', 'RIGHT$', 'RIGHT', 'RMDIR',
        'RND', 'RSET', 'RTRIM$', 'RTRIM', 'RUN', 'SADD', 'SCREEN', 'SEEK', 'SELECT',
        'SELECT CASE', 'SETMEM', 'SGN', 'SHARED', 'SHELL', 'SIN', 'SINGLE', 'SLEEP',
        'SOUND', 'SPACE$', 'SPC', 'SQR', 'STATIC', 'STEP', 'STICK', 'STOP', 'STR$',
        'STR', 'STRIG', 'STRING', 'STRING$', 'SUB', 'SWAP', 'SYSTEM', 'TAB', 'TAN',
        'THEN', 'TIME$', 'TIMER', 'TO', 'TRIM$', 'TRIM', 'TROFF', 'TRON', 'TYPE',
        'UBOUND', 'UCASE$', 'UCASE', 'UCODE', '_UCODE', 'UNLOCK', 'UNTIL', 'USING',
        'VAL', 'VARPTR', 'VARPTR$', 'VARSEG', 'VIEW', 'WAIT', 'WEND', 'WHILE', 'WIDTH',
        'WINDOW', 'WRITE', 'XOR'
    ]);

    // Mots-clés composés à préserver sous forme normalisée avec un seul espace
    const COMPOUND_KEYWORDS = [
        { pattern: /\bEND\s+IF\b/gi, canonical: 'END IF' },
        { pattern: /\bEND\s+SUB\b/gi, canonical: 'END SUB' },
        { pattern: /\bEND\s+FUNCTION\b/gi, canonical: 'END FUNCTION' },
        { pattern: /\bEND\s+SELECT\b/gi, canonical: 'END SELECT' },
        { pattern: /\bEND\s+TYPE\b/gi, canonical: 'END TYPE' },
        { pattern: /\bEND\s+DEF\b/gi, canonical: 'END DEF' },
        { pattern: /\bSELECT\s+CASE\b/gi, canonical: 'SELECT CASE' },
        { pattern: /\bLINE\s+INPUT\b/gi, canonical: 'LINE INPUT' },
        { pattern: /\bDEF\s+SEG\b/gi, canonical: 'DEF SEG' },
        { pattern: /\bON\s+ERROR\s+GOTO\b/gi, canonical: 'ON ERROR GOTO' },
        { pattern: /\bOPTION\s+BASE\b/gi, canonical: 'OPTION BASE' },
        { pattern: /\bCASE\s+ELSE\b/gi, canonical: 'CASE ELSE' },
        { pattern: /\bCASE\s+IS\b/gi, canonical: 'CASE IS' },
        { pattern: /\bPRINT\s+USING\b/gi, canonical: 'PRINT USING' },
        { pattern: /\bRESUME\s+NEXT\b/gi, canonical: 'RESUME NEXT' },
        { pattern: /\bDO\s+WHILE\b/gi, canonical: 'DO WHILE' },
        { pattern: /\bDO\s+UNTIL\b/gi, canonical: 'DO UNTIL' },
        { pattern: /\bLOOP\s+WHILE\b/gi, canonical: 'LOOP WHILE' },
        { pattern: /\bLOOP\s+UNTIL\b/gi, canonical: 'LOOP UNTIL' },
        { pattern: /\bEXIT\s+FOR\b/gi, canonical: 'EXIT FOR' },
        { pattern: /\bEXIT\s+DO\b/gi, canonical: 'EXIT DO' },
        { pattern: /\bEXIT\s+SUB\b/gi, canonical: 'EXIT SUB' },
        { pattern: /\bEXIT\s+FUNCTION\b/gi, canonical: 'EXIT FUNCTION' },
        { pattern: /\bEXIT\s+WHILE\b/gi, canonical: 'EXIT WHILE' }
    ];

    /**
     * Découpe une ligne en segments : chaînes, commentaires et code BASIC
     */
    function splitLineSegments(line) {
        const segments = [];
        let i = 0;
        let currentCode = '';

        while (i < line.length) {
            const ch = line[i];

            // 1. Chaîne de caractères entre guillemets
            if (ch === '"') {
                if (currentCode) {
                    segments.push({ type: 'code', text: currentCode });
                    currentCode = '';
                }
                let str = '"';
                i++;
                while (i < line.length && line[i] !== '"') {
                    str += line[i++];
                }
                if (i < line.length && line[i] === '"') {
                    str += '"';
                    i++;
                }
                segments.push({ type: 'string', text: str });
                continue;
            }

            // 2. Commentaire (') ou (REM)
            if (ch === '\'' || ((ch === 'R' || ch === 'r') && line.substr(i, 4).toUpperCase() === 'REM ' && (i === 0 || /\s|:/.test(line[i - 1])))) {
                if (currentCode) {
                    segments.push({ type: 'code', text: currentCode });
                    currentCode = '';
                }
                let commentText = line.substring(i);
                if (/^rem /i.test(commentText)) {
                    commentText = 'REM ' + commentText.substring(4);
                }
                segments.push({ type: 'comment', text: commentText });
                break;
            }

            currentCode += ch;
            i++;
        }

        if (currentCode) {
            segments.push({ type: 'code', text: currentCode });
        }

        return segments;
    }

    /**
     * Normalise les mots-clés et l'espacement dans la portion de code d'une ligne
     */
    function formatCodeSegment(code) {
        let text = code;

        // 1. Remplacement des mots-clés composés
        for (const compound of COMPOUND_KEYWORDS) {
            text = text.replace(compound.pattern, compound.canonical);
        }

        // 2. Normalisation des mots-clés simples et fonctions
        // On cible les identifiants ou mots simples
        text = text.replace(/\b([A-Za-z_][A-Za-z0-9_]*[$%&!#]?)\b/g, (match, word) => {
            const upper = word.toUpperCase();
            if (KEYWORDS.has(upper)) {
                return upper;
            }
            return word;
        });

        // 3. Normalisation des séparateurs et opérateurs
        // Deux points ':' (séparateur d'instructions) -> pas d'espace avant, espace après
        text = text.replace(/\s*:\s*/g, ': ');

        // Virgules ',' -> pas d'espace avant, espace après
        text = text.replace(/\s*,\s*/g, ', ');

        // Point-virgule ';' -> pas d'espace avant, espace après si suivi d'un mot ou guillemet
        text = text.replace(/\s*;\s*/g, '; ');

        // Opérateurs de comparaison et d'assignation
        text = text.replace(/\s*(<=|>=|<>)\s*/g, ' $1 ');
        text = text.replace(/(?<!<|>|=|!)\s*=\s*(?!=)/g, ' = ');
        text = text.replace(/(?<!<)\s*<\s*(?!>|=)/g, ' < ');
        text = text.replace(/(?<!<|>)\s*>\s*(?!=)/g, ' > ');
        text = text.replace(/<\s*>/g, '<>');
        text = text.replace(/<\s*=/g, '<=');
        text = text.replace(/>\s*=/g, '>=');

        // Opérateurs arithmétiques binaires (+, *, /, \, ^)
        // Attention à '+' et '-' unaires : ne pas espacer si en tête d'expression ou après '(', ',', '=', etc.
        text = text.replace(/\s*(\*|\/|\\|\^)\s*/g, ' $1 ');

        // Addition binaire
        text = text.replace(/([A-Za-z0-9_\)"])\s*\+\s*([A-Za-z0-9_\("])/g, '$1 + $2');

        // Soustraction binaire
        text = text.replace(/([A-Za-z0-9_\)"])\s*-\s*([A-Za-z0-9_\("])/g, '$1 - $2');

        // Réduire les espaces multiples à un seul
        text = text.replace(/[ \t]{2,}/g, ' ');

        // Normalisation parenthèses : coller le nom de fonction/tableau ou retirer espaces internes
        text = text.replace(/\(\s+/g, '(');
        text = text.replace(/\s+\)/g, ')');

        // Espacement après mots-clés de contrôle (IF, FOR, WHILE, UNTIL, CASE, RETURN, THEN, TO, STEP)
        text = text.replace(/\b(IF|FOR|WHILE|UNTIL|CASE|THEN|TO|STEP|GOTO|GOSUB|NEXT|OPEN|AS|LEN|FIELD)\s*\(/gi, '$1 (');

        return text;
    }

    /**
     * Reconstitue la ligne formatée à partir de ses segments
     */
    function assembleFormattedLine(segments) {
        let result = '';
        for (const seg of segments) {
            if (seg.type === 'code') {
                result += formatCodeSegment(seg.text);
            } else if (seg.type === 'string') {
                result += seg.text; // Chaîne préservée telle quelle
            } else if (seg.type === 'comment') {
                // Commentaire précédé d'un espace si non vide
                if (result.length > 0 && !result.endsWith(' ')) {
                    result += ' ';
                }
                result += seg.text;
            }
        }
        return result.trim();
    }

    /**
     * Formate un document QBasic complet avec indentation hiérarchique
     * @param {string} sourceCode Le texte source BASIC complet
     * @param {object} options { tabSize: 4, insertSpaces: true }
     * @returns {string} Le code source formaté
     */
    function formatQBasicDocument(sourceCode, options) {
        if (!sourceCode) return '';

        const tabSize = (options && options.tabSize) || 4;
        const indentUnit = (options && options.insertSpaces === false) ? '\t' : ' '.repeat(tabSize);

        const rawLines = sourceCode.split(/\r?\n/);
        const formattedLines = [];

        let currentIndent = 0;
        let selectCaseDepth = 0; // Pour gérer l'indentation spécifique sous SELECT CASE
        let prevLineWasEmpty = false;

        for (let idx = 0; idx < rawLines.length; idx++) {
            const rawLine = rawLines[idx];
            const trimmedRaw = rawLine.trim();

            // Gestion des lignes vides (compression des lignes vides successives)
            if (!trimmedRaw) {
                if (!prevLineWasEmpty && formattedLines.length > 0) {
                    formattedLines.push('');
                    prevLineWasEmpty = true;
                }
                continue;
            }
            prevLineWasEmpty = false;

            // Découpage et formatage de la ligne
            const segments = splitLineSegments(rawLine);
            const lineText = assembleFormattedLine(segments);
            if (!lineText) continue;

            const upperLine = lineText.toUpperCase();

            // ================================================================
            // ANALYSE DU DÉCALAGE PRÉ-LIGNE (Dédentation avant d'écrire la ligne)
            // ================================================================
            let lineIndent = currentIndent;

            // Dédentation pour les fins de blocs majeures
            if (/^(END\s+(IF|SUB|FUNCTION|TYPE|DEF))\b/i.test(upperLine)) {
                currentIndent = Math.max(0, currentIndent - 1);
                lineIndent = currentIndent;
            } else if (/^END\s+SELECT\b/i.test(upperLine)) {
                // END SELECT ferme à la fois le SELECT CASE et les éventuels CASE imbriqués
                currentIndent = Math.max(0, currentIndent - 2);
                lineIndent = currentIndent;
                if (selectCaseDepth > 0) selectCaseDepth--;
            } else if (/^(NEXT|WEND|LOOP(\s+(WHILE|UNTIL)\b)?)\b/i.test(upperLine)) {
                currentIndent = Math.max(0, currentIndent - 1);
                lineIndent = currentIndent;
            } else if (/^(ELSE|ELSEIF\b)/i.test(upperLine)) {
                // ELSE et ELSEIF s'alignent avec le IF parent
                lineIndent = Math.max(0, currentIndent - 1);
            } else if (/^CASE\b/i.test(upperLine)) {
                // Un nouveau CASE se place au niveau SELECT + 1 (donc dédenté de 1 si le corps précédent était à SELECT + 2)
                lineIndent = Math.max(0, currentIndent - 1);
            } else if (/^([A-Za-z_][A-Za-z0-9_]*:|\d+\b)/i.test(upperLine) && !/^(SUB|FUNCTION|DECLARE|TYPE)\b/i.test(upperLine)) {
                // Les étiquettes et numéros de ligne sont placés en colonne 0 ou dédentés pour être clairement visibles
                lineIndent = Math.max(0, currentIndent - 1);
            }

            // Indentation finale de la ligne courante
            const indentedLine = indentUnit.repeat(Math.max(0, lineIndent)) + lineText;
            formattedLines.push(indentedLine);

            // ================================================================
            // ANALYSE DU DÉCALAGE POST-LIGNE (Indentation pour les lignes suivantes)
            // ================================================================

            // 1. SUB / FUNCTION / TYPE (hors DECLARE)
            if (/^(SUB|FUNCTION)\b/i.test(upperLine) && !/^(DECLARE\s+(SUB|FUNCTION)|END\s+(SUB|FUNCTION))\b/i.test(upperLine)) {
                currentIndent++;
            } else if (/^TYPE\b/i.test(upperLine) && !/^(END\s+TYPE)\b/i.test(upperLine) && !/\bAS\s+TYPE\b/i.test(upperLine)) {
                currentIndent++;
            }

            // 2. Multi-ligne IF ... THEN (où rien ne suit THEN sauf un commentaire éventuel)
            else if (/\bIF\b.*?\bTHEN\b/i.test(upperLine) && !/^(END\s+IF)\b/i.test(upperLine)) {
                // Extraire ce qui suit THEN hors commentaire
                const thenIdx = upperLine.indexOf('THEN');
                const afterThen = lineText.substring(thenIdx + 4).trim();
                const isMultiLine = (!afterThen || afterThen.startsWith('\'') || afterThen.toUpperCase().startsWith('REM '));
                if (isMultiLine) {
                    currentIndent++;
                }
            }

            // 3. ELSE / ELSEIF dans un bloc multi-ligne
            else if (/^(ELSE|ELSEIF\b)/i.test(upperLine)) {
                // Si on avait dédenté temporairement, la ligne suivante reprend au niveau indenté du corps
                // Pas de modification nette de currentIndent (reste indenté pour le corps du ELSE)
            }

            // 4. SELECT CASE et CASE
            else if (/^SELECT\s+CASE\b/i.test(upperLine)) {
                currentIndent += 2; // SELECT (0) -> CASE (1) -> Instructions (2)
                selectCaseDepth++;
            } else if (/^CASE\b/i.test(upperLine)) {
                // Le corps sous le CASE sera à currentIndent
            }

            // 5. Boucles FOR, WHILE, DO
            else if (/^FOR\b/i.test(upperLine) && /\bTO\b/i.test(upperLine)) {
                currentIndent++;
            } else if (/^WHILE\b/i.test(upperLine)) {
                currentIndent++;
            } else if (/^DO(\s+(WHILE|UNTIL)\b)?/i.test(upperLine) && !/\bLOOP\b/i.test(upperLine)) {
                currentIndent++;
            }
        }

        return formattedLines.join('\n');
    }

    // Exposer la fonction globale
    window.qbasicFormat = formatQBasicDocument;

    /**
     * Enregistre le formateur de documents QBasic auprès de l'API Monaco Editor
     * @param {object} monacoInstance 
     */
    window.registerQBasicFormatter = function(monacoInstance) {
        if (!monacoInstance || !monacoInstance.languages) return;

        // 1. Fournisseur de formatage de document complet (Shift+Alt+F / Maj+Alt+F)
        monacoInstance.languages.registerDocumentFormattingEditProvider('qbasic', {
            provideDocumentFormattingEdits: function(model, options) {
                const text = model.getValue();
                const formatted = formatQBasicDocument(text, options);
                return [{
                    range: model.getFullModelRange(),
                    text: formatted
                }];
            }
        });

        // 2. Fournisseur de formatage d'une sélection de lignes (Ctrl+K, Ctrl+F)
        monacoInstance.languages.registerDocumentRangeFormattingEditProvider('qbasic', {
            provideDocumentRangeFormattingEdits: function(model, range, options) {
                // Pour une sélection, formater l'ensemble du document garantit la cohérence des blocs
                const text = model.getValue();
                const formatted = formatQBasicDocument(text, options);
                return [{
                    range: model.getFullModelRange(),
                    text: formatted
                }];
            }
        });
    };
})();
