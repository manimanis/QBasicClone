// qbasic-linter.js - Analyseur syntaxique et sémantique en temps réel pour QBasic Studio
// Détecte les erreurs officielles Microsoft QBasic (Codes 1 à 76)
(function() {
    // Table officielle des codes d'erreur Microsoft QBasic
    const ERROR_MESSAGES = {
        1: "NEXT without FOR",
        2: "Syntax error",
        3: "RETURN without GOSUB",
        4: "Out of DATA",
        5: "Illegal function call",
        6: "Overflow",
        7: "Out of memory",
        8: "Label not defined",
        9: "Subscript out of range",
        10: "Duplicate definition",
        11: "Division by zero",
        12: "Illegal in direct mode",
        13: "Type mismatch",
        14: "Out of string space",
        16: "String formula too complex",
        17: "Cannot continue",
        18: "Function not defined",
        19: "No RESUME",
        20: "RESUME without error",
        24: "Device timeout",
        25: "Device fault",
        26: "FOR without NEXT",
        27: "Out of paper",
        29: "WHILE without WEND",
        30: "WEND without WHILE",
        33: "Duplicate label",
        35: "Subprogram not defined",
        37: "Argument-count mismatch",
        38: "Array not defined",
        40: "Variable required",
        50: "FIELD overflow",
        51: "Internal error",
        52: "Bad file name or number",
        53: "File not found",
        54: "Bad file mode",
        55: "File already open",
        56: "FIELD statement active",
        57: "Device I/O error",
        58: "File already exists",
        59: "Bad record length",
        61: "Disk full",
        62: "Input past end of file",
        63: "Bad record number",
        64: "Bad file name",
        67: "Too many files",
        68: "Device unavailable",
        69: "Communication-buffer overflow",
        70: "Permission denied",
        71: "Disk not ready",
        72: "Disk-media error",
        73: "Feature unavailable",
        74: "Rename across disks",
        75: "Path/File access error",
        76: "Path not found"
    };

    /**
     * Analyse le texte du modèle QBasic et retourne les marqueurs Monaco
     * @param {string} text Le code source BASIC
     * @returns {Array} Liste des marqueurs d'erreurs Monaco
     */
    function lintQBasic(text) {
        if (!text) return [];

        const lines = text.split(/\r?\n/);
        const markers = [];

        function addMarker(code, lineNum, startCol, endCol, extra) {
            const baseMsg = ERROR_MESSAGES[code] || "QBasic error";
            const fullMsg = extra ? `${baseMsg}: ${extra}` : baseMsg;
            markers.push({
                severity: monaco.MarkerSeverity.Error,
                message: `[Erreur ${code}] ${fullMsg}`,
                startLineNumber: lineNum,
                startColumn: Math.max(1, startCol),
                endLineNumber: lineNum,
                endColumn: Math.max(startCol + 1, endCol),
                source: 'QBasic Linter'
            });
        }

        // Nettoyage de ligne pour garder le texte hors chaînes et commentaires
        // Tout en préservant les positions exactes de colonnes
        function maskStringsAndComments(line) {
            let inString = false;
            let masked = '';
            for (let i = 0; i < line.length; i++) {
                const ch = line[i];
                if (!inString) {
                    if (ch === '"') {
                        inString = true;
                        masked += '"';
                    } else if (ch === '\'' || (ch === 'R' || ch === 'r') && line.substr(i, 4).toUpperCase() === 'REM ' && (i === 0 || /\s/.test(line[i - 1]))) {
                        // Reste de la ligne est commentaire
                        masked += ' '.repeat(line.length - i);
                        break;
                    } else {
                        masked += ch;
                    }
                } else {
                    if (ch === '"') {
                        inString = false;
                        masked += '"';
                    } else {
                        masked += ' '; // Remplacer le contenu de la chaîne par des espaces
                    }
                }
            }
            return masked;
        }

        // ====================================================================
        // PASSE 1 : Collecte des étiquettes, numéros de lignes, SUB et FUNCTION
        // ====================================================================
        const labels = new Map(); // label_upper -> { lineNum, startCol, endCol }
        const declaredSubs = new Map(); // sub_upper -> { paramCount, lineNum }
        const definedSubs = new Map();   // sub_upper -> { paramCount, lineNum }
        const definedFunctions = new Map();
        const dimArrays = new Map();     // arr_upper -> lineNum
        let hasGosub = false;
        let hasOnError = false;

        for (let idx = 0; idx < lines.length; idx++) {
            const lineNum = idx + 1;
            const rawLine = lines[idx];
            const masked = maskStringsAndComments(rawLine);
            const trimmed = masked.trim();
            if (!trimmed) continue;

            // Détection GOSUB / ON ERROR dans le code
            if (/\bGOSUB\b/i.test(masked)) hasGosub = true;
            if (/\bON\s+ERROR\s+GOTO\b/i.test(masked)) hasOnError = true;

            // Numéro de ligne numérique en tête (ex: 100 PRINT "ok")
            const numLineMatch = masked.match(/^(\s*)(\d+)\b/);
            if (numLineMatch) {
                const labelStr = numLineMatch[2];
                const startCol = numLineMatch[1].length + 1;
                const endCol = startCol + labelStr.length;
                if (labels.has(labelStr)) {
                    addMarker(33, lineNum, startCol, endCol, `Line number ${labelStr} already defined`);
                } else {
                    labels.set(labelStr, { lineNum, startCol, endCol });
                }
            }

            // Étiquette alphanumérique (ex: MyLabel:)
            const textLabelMatch = masked.match(/^(\s*)([A-Za-z_][A-Za-z0-9_]*):/);
            if (textLabelMatch) {
                const labelStr = textLabelMatch[2].toUpperCase();
                const startCol = textLabelMatch[1].length + 1;
                const endCol = startCol + textLabelMatch[2].length + 1;
                if (labels.has(labelStr)) {
                    addMarker(33, lineNum, startCol, endCol, `Label '${textLabelMatch[2]}' already defined`);
                } else {
                    labels.set(labelStr, { lineNum, startCol, endCol });
                }
            }

            // Détection DECLARE SUB / FUNCTION
            const declMatch = masked.match(/\bDECLARE\s+(SUB|FUNCTION)\s+([A-Za-z_][A-Za-z0-9_]*[$%&!#]?)\s*(\(([^)]*)\))?/i);
            if (declMatch) {
                const isSub = declMatch[1].toUpperCase() === 'SUB';
                const name = declMatch[2].toUpperCase();
                const rawParams = declMatch[4] ? declMatch[4].trim() : '';
                const paramCount = rawParams.length === 0 ? 0 : rawParams.split(',').length;
                if (isSub) {
                    declaredSubs.set(name, { paramCount, lineNum });
                }
            }

            // Détection SUB definition (ex: SUB MySub (a, b))
            const subMatch = masked.match(/^(\s*)SUB\s+([A-Za-z_][A-Za-z0-9_]*[$%&!#]?)\s*(\(([^)]*)\))?/i);
            if (subMatch) {
                const name = subMatch[2].toUpperCase();
                const rawParams = subMatch[4] ? subMatch[4].trim() : '';
                const paramCount = rawParams.length === 0 ? 0 : rawParams.split(',').length;
                definedSubs.set(name, { paramCount, lineNum });
            }

            // Détection FUNCTION definition
            const fnMatch = masked.match(/^(\s*)FUNCTION\s+([A-Za-z_][A-Za-z0-9_]*[$%&!#]?)\s*(\(([^)]*)\))?/i);
            if (fnMatch) {
                const name = fnMatch[2].toUpperCase();
                const rawParams = fnMatch[4] ? fnMatch[4].trim() : '';
                const paramCount = rawParams.length === 0 ? 0 : rawParams.split(',').length;
                definedFunctions.set(name, { paramCount, lineNum });
            }
        }

        // ====================================================================
        // PASSE 2 : Blocs imbriqués, structures de contrôle et expressions
        // ====================================================================
        const forStack = [];    // { var, lineNum, col }
        const whileStack = [];  // { lineNum, col }
        const doStack = [];     // { lineNum, col }
        const ifStack = [];     // { lineNum, col }
        const selectStack = []; // { lineNum, col }

        let insideProc = false;

        for (let idx = 0; idx < lines.length; idx++) {
            const lineNum = idx + 1;
            const rawLine = lines[idx];
            const masked = maskStringsAndComments(rawLine);
            const trimmed = masked.trim();
            if (!trimmed) continue;

            // Suivi des frontières SUB / FUNCTION
            if (/^\s*(SUB|FUNCTION)\b/i.test(masked)) {
                insideProc = true;
            }
            if (/^\s*END\s+(SUB|FUNCTION)\b/i.test(masked)) {
                // Vérifier si des boucles non fermées restent dans la procédure
                while (forStack.length > 0) {
                    const top = forStack.pop();
                    addMarker(26, top.lineNum, top.col, top.col + 3, `Unclosed FOR statement`);
                }
                while (whileStack.length > 0) {
                    const top = whileStack.pop();
                    addMarker(29, top.lineNum, top.col, top.col + 5, `Unclosed WHILE statement`);
                }
                insideProc = false;
            }

            // 1. Détection FOR / NEXT
            const forMatch = masked.match(/\bFOR\s+([A-Za-z_][A-Za-z0-9_]*[$%&!#]?)\s*=/i);
            if (forMatch) {
                const varName = forMatch[1].toUpperCase();
                const col = masked.indexOf(forMatch[0]) + 1;
                forStack.push({ var: varName, lineNum, col });
            }

            const nextMatch = masked.match(/\bNEXT(\s+([A-Za-z_][A-Za-z0-9_]*[$%&!#]?))?\b/i);
            if (nextMatch && !/\bRESUME\s+NEXT\b/i.test(masked)) {
                const col = masked.indexOf(nextMatch[0]) + 1;
                const nextVar = nextMatch[2] ? nextMatch[2].toUpperCase() : null;

                if (forStack.length === 0) {
                    addMarker(1, lineNum, col, col + nextMatch[0].length, nextVar ? `Variable ${nextVar}` : null);
                } else {
                    const topFor = forStack.pop();
                    if (nextVar && topFor.var && nextVar !== topFor.var) {
                        addMarker(1, lineNum, col, col + nextMatch[0].length, `Found NEXT ${nextVar}, expected NEXT ${topFor.var}`);
                    }
                }
            }

            // 2. Détection WHILE / WEND
            const whileMatch = masked.match(/^\s*WHILE\b/i);
            if (whileMatch) {
                const col = masked.search(/\bWHILE\b/i) + 1;
                whileStack.push({ lineNum, col });
            }

            const wendMatch = masked.match(/\bWEND\b/i);
            if (wendMatch) {
                const col = masked.indexOf(wendMatch[0]) + 1;
                if (whileStack.length === 0) {
                    addMarker(30, lineNum, col, col + 4);
                } else {
                    whileStack.pop();
                }
            }

            // 3. Détection DO / LOOP
            const doMatch = masked.match(/^\s*DO(\s+(WHILE|UNTIL)\b)?/i);
            if (doMatch && !/\bLOOP\b/i.test(masked)) {
                const col = masked.search(/\bDO\b/i) + 1;
                doStack.push({ lineNum, col });
            }

            const loopMatch = masked.match(/\bLOOP(\s+(WHILE|UNTIL)\b)?/i);
            if (loopMatch) {
                const col = masked.indexOf(loopMatch[0]) + 1;
                if (doStack.length === 0) {
                    addMarker(2, lineNum, col, col + 4, "LOOP without DO");
                } else {
                    doStack.pop();
                }
            }

            // 4. Détection IF multi-lignes vs mono-ligne
            // Un IF multi-ligne se termine par THEN suivi d'éventuels espaces
            const ifBlockMatch = masked.match(/\bIF\b.*?\bTHEN\s*$/i);
            if (ifBlockMatch && !/^\s*ELSEIF\b/i.test(masked)) {
                const col = masked.search(/\bIF\b/i) + 1;
                ifStack.push({ lineNum, col });
            }
            if (/\bEND\s+IF\b/i.test(masked)) {
                if (ifStack.length > 0) {
                    ifStack.pop();
                }
            }

            // 5. Détection SELECT CASE
            if (/\bSELECT\s+CASE\b/i.test(masked)) {
                const col = masked.search(/\bSELECT\s+CASE\b/i) + 1;
                selectStack.push({ lineNum, col });
            }
            if (/\bEND\s+SELECT\b/i.test(masked)) {
                if (selectStack.length > 0) {
                    selectStack.pop();
                }
            }

            // 6. Détection RETURN sans GOSUB
            if (/\bRETURN\b/i.test(masked) && !hasGosub && !insideProc) {
                const col = masked.search(/\bRETURN\b/i) + 1;
                addMarker(3, lineNum, col, col + 6);
            }

            // 7. Détection RESUME sans ON ERROR
            if (/\bRESUME\b/i.test(masked) && !hasOnError) {
                const col = masked.search(/\bRESUME\b/i) + 1;
                addMarker(20, lineNum, col, col + 6);
            }

            // 8. Cibles GOTO, GOSUB, ON ERROR GOTO (Error 8: Label not defined)
            const gotoMatch = masked.match(/\b(GOTO|GOSUB|ON\s+ERROR\s+GOTO)\s+([A-Za-z0-9_]+)\b/i);
            if (gotoMatch) {
                const kw = gotoMatch[1].toUpperCase();
                const target = gotoMatch[2].toUpperCase();
                // "ON ERROR GOTO 0" est valide pour désactiver le gestionnaire
                if (!(kw === 'ON ERROR GOTO' && target === '0')) {
                    if (!labels.has(target)) {
                        const targetIdx = masked.indexOf(gotoMatch[2], masked.indexOf(gotoMatch[1]));
                        addMarker(8, lineNum, targetIdx + 1, targetIdx + 1 + target.length, `Label '${gotoMatch[2]}' is not defined`);
                    }
                }
            }

            // 9. Détection CALL (Error 35: Subprogram not defined, Error 37: Argument-count mismatch)
            const callMatch = masked.match(/\bCALL\s+([A-Za-z_][A-Za-z0-9_]*)\s*(\(([^)]*)\))?/i);
            if (callMatch) {
                const subName = callMatch[1].toUpperCase();
                const rawArgs = callMatch[3] ? callMatch[3].trim() : '';
                const argCount = rawArgs.length === 0 ? 0 : rawArgs.split(',').length;
                const callIdx = masked.indexOf(callMatch[1], masked.indexOf(callMatch[0]));

                const knownSub = definedSubs.get(subName) || declaredSubs.get(subName);
                if (!knownSub) {
                    addMarker(35, lineNum, callIdx + 1, callIdx + 1 + subName.length, `Subprogram '${callMatch[1]}' not defined`);
                } else if (knownSub.paramCount !== argCount) {
                    addMarker(37, lineNum, callIdx + 1, callIdx + 1 + subName.length, `Expected ${knownSub.paramCount} arguments, but got ${argCount}`);
                }
            }

            // 10. Détection Division par zéro statique (Error 11)
            const divZeroMatch = masked.match(/(\/|\\|\bMOD\b)\s*0(\.0*)?(\b|(?=[^0-9]))/i);
            if (divZeroMatch) {
                const col = masked.indexOf(divZeroMatch[0]) + 1;
                addMarker(11, lineNum, col, col + divZeroMatch[0].length);
            }

            // 11. Détection DIM en double au niveau module (Error 10)
            if (!insideProc) {
                const dimMatch = masked.match(/\bDIM\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/i);
                if (dimMatch && !/\bREDIM\b/i.test(masked)) {
                    const arrName = dimMatch[1].toUpperCase();
                    const col = masked.indexOf(dimMatch[1], masked.indexOf(dimMatch[0])) + 1;
                    if (dimArrays.has(arrName)) {
                        addMarker(10, lineNum, col, col + arrName.length, `Array '${dimMatch[1]}' already dimensioned in line ${dimArrays.get(arrName)}`);
                    } else {
                        dimArrays.set(arrName, lineNum);
                    }
                }
            }

            // 12. Détection Variable required (Error 40)
            const swapLitMatch = masked.match(/\bSWAP\s+([0-9.]+|"[^"]*")\s*,/i);
            if (swapLitMatch) {
                const col = masked.indexOf(swapLitMatch[1]) + 1;
                addMarker(40, lineNum, col, col + swapLitMatch[1].length, `Variable required in SWAP`);
            }
            const readLitMatch = masked.match(/\bREAD\s+([0-9.]+|"[^"]*")/i);
            if (readLitMatch) {
                const col = masked.indexOf(readLitMatch[1]) + 1;
                addMarker(40, lineNum, col, col + readLitMatch[1].length, `Variable required in READ`);
            }

            // 13. Vérification des parenthèses non équilibrées
            let parenCount = 0;
            for (let i = 0; i < masked.length; i++) {
                if (masked[i] === '(') parenCount++;
                else if (masked[i] === ')') parenCount--;
            }
            if (parenCount !== 0) {
                addMarker(2, lineNum, 1, masked.length + 1, parenCount > 0 ? "Missing closing parenthesis" : "Unmatched closing parenthesis");
            }
        }

        // ====================================================================
        // VÉRIFICATIONS DE FIN DE FICHIER
        // ====================================================================
        // Boucles FOR non fermées (Error 26)
        while (forStack.length > 0) {
            const top = forStack.pop();
            addMarker(26, top.lineNum, top.col, top.col + 3, `Unclosed FOR statement`);
        }

        // Boucles WHILE non fermées (Error 29)
        while (whileStack.length > 0) {
            const top = whileStack.pop();
            addMarker(29, top.lineNum, top.col, top.col + 5, `Unclosed WHILE statement`);
        }

        // Blocs IF non fermés
        while (ifStack.length > 0) {
            const top = ifStack.pop();
            addMarker(2, top.lineNum, top.col, top.col + 2, `Block IF without END IF`);
        }

        // Blocs SELECT non fermés
        while (selectStack.length > 0) {
            const top = selectStack.pop();
            addMarker(2, top.lineNum, top.col, top.col + 6, `SELECT without END SELECT`);
        }

        return markers;
    }

    // Exposer l'API globale
    window.qbasicLint = lintQBasic;
    window.qbasicErrorMessages = ERROR_MESSAGES;

    /**
     * Lance le linter sur un modèle Monaco donné et applique les marqueurs visuels
     * @param {monaco.editor.ITextModel} model 
     */
    window.runQBasicLinterOnModel = function(model) {
        if (!model || model.isDisposed()) return;
        const text = model.getValue();
        const markers = lintQBasic(text);
        monaco.editor.setModelMarkers(model, 'qbasic-linter', markers);

        // Mettre à jour l'indicateur d'erreurs dans la barre de statut si présent
        const statusEl = document.getElementById('linter-status');
        if (statusEl) {
            if (markers.length === 0) {
                statusEl.textContent = '✓ 0 erreur';
                statusEl.className = 'status-badge success';
                statusEl.title = 'Code sans erreur de syntaxe détectée';
            } else {
                statusEl.textContent = `⚠ ${markers.length} erreur${markers.length > 1 ? 's' : ''}`;
                statusEl.className = 'status-badge error';
                statusEl.title = markers.map(m => `Ligne ${m.startLineNumber}: ${m.message}`).join('\n');
            }
        }
    };
})();

