// qbasic-completions.js - Autocomplétion et documentation interactive (IntelliSense) pour QBasic
(function() {
    const DOCS = {
        'PRINT': {
            detail: 'Instruction d\'affichage',
            doc: 'Affiche du texte ou des valeurs numériques à l\'écran.\n\n**Syntaxe :** `PRINT [#num,] [expr1 [{;|,}] [expr2] ...]`\n\n- `;` : continue sur la même ligne sans espace.\n- `,` : saute à la tabulation suivante (toutes les 14 colonnes).\n- `PRINT USING fmt$; ...` : affichage avec formatage.'
        },
        'INPUT': {
            detail: 'Saisie utilisateur au clavier',
            doc: 'Lit des valeurs saisies par l\'utilisateur au clavier ou depuis un fichier.\n\n**Syntaxe :** `INPUT [;] ["Invite" {;|,}] var1 [, var2 ...]`'
        },
        'LINE INPUT': {
            detail: 'Saisie d\'une ligne complète',
            doc: 'Lit une ligne de texte entière (y compris les virgules et guillemets) jusqu\'au retour chariot.\n\n**Syntaxe :** `LINE INPUT [;] ["Invite";] var$`'
        },
        'CLS': {
            detail: 'Effacement d\'écran',
            doc: 'Efface l\'écran texte ou graphique et replace le curseur en haut à gauche (1, 1).\n\n**Syntaxe :** `CLS`'
        },
        'SCREEN': {
            detail: 'Configuration du mode vidéo',
            doc: 'Définit le mode d\'affichage de l\'écran.\n\n**Syntaxe :** `SCREEN mode`\n\n- `0` : Texte 80x25, 16 couleurs.\n- `1` : Graphique 320x200, 4 couleurs CGA.\n- `2` : Graphique 640x200, 2 couleurs CGA.\n- `7` : Graphique 320x200, 16 couleurs EGA.\n- `12` : Graphique 640x480, 16 couleurs VGA.\n- `13` : Graphique 320x200, 256 couleurs VGA.'
        },
        'COLOR': {
            detail: 'Sélection des couleurs',
            doc: 'Définit la couleur d\'avant-plan et d\'arrière-plan.\n\n**Syntaxe :** `COLOR [avant_plan] [, arriere_plan]`'
        },
        'LOCATE': {
            detail: 'Positionnement du curseur',
            doc: 'Déplace le curseur texte sur la ligne et colonne indiquées.\n\n**Syntaxe :** `LOCATE [ligne] [, colonne]` (1-indexé : ligne 1..25, colonne 1..80).'
        },
        'PSET': {
            detail: 'Tracé d\'un point pixel',
            doc: 'Allume un pixel à la coordonnée `(x, y)` avec la couleur spécifiée.\n\n**Syntaxe :** `PSET (x, y) [, couleur]`'
        },
        'LINE': {
            detail: 'Tracé de ligne ou rectangle',
            doc: 'Trace une ligne ou un rectangle entre deux coordonnées.\n\n**Syntaxe :** `LINE (x1, y1)-(x2, y2) [, couleur] [, [B|BF]]`\n\n- `B` : Rectangle creux (Box).\n- `BF` : Rectangle plein rempli (Box Filled).'
        },
        'CIRCLE': {
            detail: 'Tracé de cercle ou d\'ellipse',
            doc: 'Trace un cercle, une ellipse ou un arc géométrique.\n\n**Syntaxe :** `CIRCLE (x, y), rayon [, couleur] [, debut, fin [, aspect]]`'
        },
        'PAINT': {
            detail: 'Remplissage par diffusion',
            doc: 'Remplit une zone fermée à partir d\'un point `(x, y)` avec une couleur de remplissage.\n\n**Syntaxe :** `PAINT (x, y) [, couleur_fond [, couleur_bordure]]`'
        },
        'DRAW': {
            detail: 'Dessin graphique orienté commandes (Turtle)',
            doc: 'Exécute une chaîne de commandes graphiques de tracé.\n\n**Syntaxe :** `DRAW cmd$`\n\nCommandes : `U` (haut), `D` (bas), `L` (gauche), `R` (droite), `M x,y`, `C couleur`.'
        },
        'PLAY': {
            detail: 'Synthèse musicale Music Macro Language (MML)',
            doc: 'Joue une mélodie musicale sur le haut-parleur PC Speaker.\n\n**Syntaxe :** `PLAY mml$`\n\nNotes : `A-G`, altérations `#` / `-`, octaves `O0..O6`, tempos `T32..T255`, longueurs `L1..L64`.'
        },
        'SOUND': {
            detail: 'Émission d\'une onde sonore pure',
            doc: 'Joue une fréquence sonore pendant une durée donnée.\n\n**Syntaxe :** `SOUND frequence_hz, duree`'
        },
        'BEEP': {
            detail: 'Bip sonore système',
            doc: 'Émet un bip standard d\'avertissement sonore (750 Hz pendant 250 ms).\n\n**Syntaxe :** `BEEP`'
        },
        'SLEEP': {
            detail: 'Pause temporisée',
            doc: 'Suspend l\'exécution du programme pendant le nombre de secondes indiqué ou jusqu\'à l\'appui d\'une touche.\n\n**Syntaxe :** `SLEEP [secondes]`'
        },
        'RANDOMIZE': {
            detail: 'Initialisation du générateur aléatoire',
            doc: 'Réinitialise le générateur pseudo-aléatoire `RND`.\n\n**Syntaxe :** `RANDOMIZE [graine]`\n\nAstuce : Utilisez `RANDOMIZE` ou `RANDOMIZE TIMER` pour obtenir un tirage unique et imprévisible.'
        },
        'RND': {
            detail: 'Nombre pseudo-aléatoire',
            doc: 'Renvoie un nombre flottant en simple précision compris dans l\'intervalle `[0, 1[`.\n\n**Syntaxe :** `RND [(n)]`\n\nExemple : `de = INT(RND * 6) + 1` pour simuler un dé de 1 à 6.'
        },
        'MID$': {
            detail: 'Extraction ou remplacement de sous-chaîne',
            doc: 'Renvoie une sous-chaîne extraite d\'une chaîne source.\n\n**Syntaxe :** `MID$(chaine$, depart [, longueur])`\n\n- `depart` : position du 1er caractère (1-indexé).\n- `longueur` : nombre de caractères à extraire.'
        },
        'LEFT$': {
            detail: 'Caractères gauches d\'une chaîne',
            doc: 'Renvoie les `n` premiers caractères d\'une chaîne.\n\n**Syntaxe :** `LEFT$(chaine$, n)`'
        },
        'RIGHT$': {
            detail: 'Caractères droits d\'une chaîne',
            doc: 'Renvoie les `n` derniers caractères d\'une chaîne.\n\n**Syntaxe :** `RIGHT$(chaine$, n)`'
        },
        'LTRIM$': {
            detail: 'Suppression des espaces initiaux (gauche)',
            doc: 'Supprime tous les espaces et tabulations en tête d\'une chaîne ou de la conversion d\'un nombre.\n\n**Syntaxe :** `LTRIM$(chaine$)`\n\nExemple courant : `LTRIM$(STR$(x))` supprime l\'espace de signe initial.'
        },
        'RTRIM$': {
            detail: 'Suppression des espaces finaux (droite)',
            doc: 'Supprime tous les espaces et tabulations en fin de chaîne.\n\n**Syntaxe :** `RTRIM$(chaine$)`\n\nExemple : `RTRIM$("Bonjour   ")` -> `"Bonjour"`'
        },
        'TRIM$': {
            detail: 'Suppression des espaces aux deux extrémités',
            doc: 'Supprime tous les espaces et tabulations au début et à la fin d\'une chaîne.\n\n**Syntaxe :** `TRIM$(chaine$)` ou `LTRIM$(RTRIM$(chaine$))`\n\nExemple : `TRIM$("  42  ")` -> `"42"`'
        },
        'LEN': {
            detail: 'Longueur d\'une chaîne',
            doc: 'Renvoie le nombre de caractères d\'une chaîne.\n\n**Syntaxe :** `LEN(chaine$)`'
        },
        'UCASE$': {
            detail: 'Conversion en majuscules (Support Unicode)',
            doc: 'Convertit tous les caractères d\'une chaîne en majuscules (y compris les caractères accentués).\n\n**Syntaxe :** `UCASE$(chaine$)`'
        },
        'LCASE$': {
            detail: 'Conversion en minuscules (Support Unicode)',
            doc: 'Convertit tous les caractères d\'une chaîne en minuscules (y compris les caractères accentués).\n\n**Syntaxe :** `LCASE$(chaine$)`'
        },
        'INSTR': {
            detail: 'Recherche de sous-chaîne',
            doc: 'Recherche la première occurrence d\'une sous-chaîne dans un texte.\n\n**Syntaxe :** `INSTR([depart,] texte$, recherche$)`\n\nRenvoie 0 si non trouvée, ou la position 1-indexée.'
        },
        'CHR$': {
            detail: 'Caractère correspondant à un code',
            doc: 'Renvoie le caractère correspondant au code ASCII ou code point Unicode indiqué.\n\n**Syntaxe :** `CHR$(code)`'
        },
        'UCHR$': {
            detail: 'Caractère Unicode UTF-8',
            doc: 'Génère la chaîne UTF-8 correspondant au code point Unicode spécifié.\n\n**Syntaxe :** `UCHR$(codepoint)`\n\nExemple : `UCHR$(8364)` pour l\'euro (€).'
        },
        'ASC': {
            detail: 'Code du premier caractère',
            doc: 'Renvoie le code point Unicode ou code ASCII du premier caractère d\'une chaîne.\n\n**Syntaxe :** `ASC(chaine$)`'
        },
        'UCODE': {
            detail: 'Code point Unicode',
            doc: 'Renvoie le code point Unicode (décimal) du premier caractère de la chaîne.\n\n**Syntaxe :** `UCODE(chaine$)`'
        },
        'STR$': {
            detail: 'Conversion nombre vers chaîne',
            doc: 'Convertit une valeur numérique en représentation textuelle.\n\n**Syntaxe :** `STR$(nombre)`'
        },
        'VAL': {
            detail: 'Conversion chaîne vers nombre',
            doc: 'Convertit une chaîne de caractères en nombre flottant.\n\n**Syntaxe :** `VAL(chaine$)`'
        },
        'INKEY$': {
            detail: 'Lecture non-bloquante du clavier',
            doc: 'Lit la touche pressée sans bloquer l\'exécution.\n\n**Syntaxe :** `k$ = INKEY$`\n\n- Renvoie `""` si aucune touche.\n- Renvoie 1 caractère pour les touches ASCII standard.\n- Renvoie 2 caractères `CHR$(0) + scancode` pour les touches étendues (flèches, F1..F12).'
        },
        'DIM': {
            detail: 'Déclaration de variables ou tableaux',
            doc: 'Déclare et alloue de la mémoire pour des variables ou des tableaux multi-dimensionnels.\n\n**Syntaxe :** `DIM [SHARED] variable [(dim1 [, dim2])] [AS Type]`'
        },
        'OPEN': {
            detail: 'Ouverture de fichier',
            doc: 'Ouvre un fichier pour les opérations d\'entrées/sorties.\n\n**Syntaxe :** `OPEN fichier$ FOR {INPUT|OUTPUT|APPEND|BINARY|RANDOM} AS #num [LEN = reclen]`'
        },
        'CLOSE': {
            detail: 'Fermeture de fichier',
            doc: 'Ferme un ou tous les fichiers ouverts.\n\n**Syntaxe :** `CLOSE [#num1 [, #num2 ...]]`'
        },
        'TIMER': {
            detail: 'Horloge système haute résolution',
            doc: 'Renvoie le nombre de secondes écoulées depuis minuit sous forme de nombre flottant en double précision.\n\n**Syntaxe :** `TIMER`'
        }
    };

    const SNIPPETS = [
        {
            label: 'sub',
            detail: 'Procédure SUB ... END SUB',
            insertText: 'SUB ${1:NomProcedure} (${2:parametres})\n    ${0:\' Instructions}\nEND SUB',
            documentation: 'Définit une procédure SUB sans valeur de retour'
        },
        {
            label: 'function',
            detail: 'Fonction FUNCTION ... END FUNCTION',
            insertText: 'FUNCTION ${1:NomFonction} (${2:parametres}) AS ${3:INTEGER}\n    ${0:\' Instructions}\n    ${1:NomFonction} = ${4:valeur}\nEND FUNCTION',
            documentation: 'Définit une fonction avec valeur de retour'
        },
        {
            label: 'for',
            detail: 'Boucle FOR ... NEXT',
            insertText: 'FOR ${1:i} = ${2:1} TO ${3:10}\n    ${0:PRINT $1}\nNEXT ${1:i}',
            documentation: 'Boucle itérative avec compteur'
        },
        {
            label: 'if',
            detail: 'Condition IF ... THEN ... END IF',
            insertText: 'IF ${1:condition} THEN\n    ${0:\' Instructions}\nEND IF',
            documentation: 'Structure conditionnelle'
        },
        {
            label: 'ifelse',
            detail: 'Condition IF ... THEN ... ELSE ... END IF',
            insertText: 'IF ${1:condition} THEN\n    ${2:\' Si vrai}\nELSE\n    ${0:\' Si faux}\nEND IF',
            documentation: 'Structure conditionnelle avec branche alternative'
        },
        {
            label: 'select',
            detail: 'Structure SELECT CASE ... END SELECT',
            insertText: 'SELECT CASE ${1:variable}\n    CASE ${2:1}\n        ${3:\' Cas 1}\n    CASE ELSE\n        ${0:\' Cas par défaut}\nEND SELECT',
            documentation: 'Aiguillage selon la valeur d\'une variable'
        },
        {
            label: 'do_while',
            detail: 'Boucle DO WHILE ... LOOP',
            insertText: 'DO WHILE ${1:condition}\n    ${0:\' Instructions}\nLOOP',
            documentation: 'Boucle tant que la condition est vraie'
        },
        {
            label: 'do_until',
            detail: 'Boucle DO ... LOOP UNTIL',
            insertText: 'DO\n    ${0:\' Instructions}\nLOOP UNTIL ${1:INKEY$ <> ""}',
            documentation: 'Boucle jusqu\'à ce que la condition devienne vraie'
        },
        {
            label: 'type',
            detail: 'Définition d\'une structure TYPE ... END TYPE',
            insertText: 'TYPE ${1:TypeUtilisateur}\n    ${2:nom} AS STRING * ${3:20}\n    ${4:age} AS INTEGER\nEND TYPE',
            documentation: 'Définit un type de données structuré personnalisé'
        },
        {
            label: 'screen12',
            detail: 'Initialisation graphique VGA 640x480 (SCREEN 12)',
            insertText: 'SCREEN 12\nCOLOR 14\nCLS\n\nPRINT "Mode Graphique VGA 640x480"\nLINE (50, 50)-(590, 430), 10, B\nCIRCLE (320, 240), 100, 12\n\nSLEEP\nSCREEN 0\nCLS',
            documentation: 'Prépare un canevas graphique VGA 640x480 16 couleurs'
        },
        {
            label: 'file_write',
            detail: 'Écriture dans un fichier texte',
            insertText: 'OPEN "${1:fichier.txt}" FOR OUTPUT AS #${2:1}\nPRINT #$2, "${0:Contenu du fichier}"\nCLOSE #$2',
            documentation: 'Crée ou écrase un fichier pour y écrire du texte'
        },
        {
            label: 'file_read',
            detail: 'Lecture ligne par ligne d\'un fichier',
            insertText: 'OPEN "${1:fichier.txt}" FOR INPUT AS #${2:1}\nDO WHILE NOT EOF($2)\n    LINE INPUT #$2, ligne$\n    PRINT ligne$\nLOOP\nCLOSE #$2',
            documentation: 'Ouvre un fichier et lit toutes ses lignes'
        }
    ];

    window.registerQBasicProviders = function(monaco) {
        // 1. Fournisseur d'Autocomplétion (IntelliSense)
        monaco.languages.registerCompletionItemProvider('qbasic', {
            provideCompletionItems: function(model, position) {
                const word = model.getWordUntilPosition(position);
                const range = {
                    startLineNumber: position.lineNumber,
                    endLineNumber: position.lineNumber,
                    startColumn: word.startColumn,
                    endColumn: word.endColumn
                };

                const suggestions = [];

                // A. Snippets
                for (const snip of SNIPPETS) {
                    suggestions.push({
                        label: snip.label,
                        kind: monaco.languages.CompletionItemKind.Snippet,
                        insertText: snip.insertText,
                        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                        detail: snip.detail,
                        documentation: snip.documentation,
                        range: range
                    });
                }

                // B. Mots-clés et instructions documentés
                for (const [kw, info] of Object.entries(DOCS)) {
                    suggestions.push({
                        label: kw,
                        kind: monaco.languages.CompletionItemKind.Keyword,
                        insertText: kw,
                        detail: info.detail,
                        documentation: { value: info.doc },
                        range: range
                    });
                }

                // C. Mots-clés QBasic supplémentaires
                const def = window.qbasicLanguageDefinition;
                if (def && def.keywords) {
                    for (const kw of def.keywords) {
                        if (!DOCS[kw]) {
                            suggestions.push({
                                label: kw,
                                kind: monaco.languages.CompletionItemKind.Keyword,
                                insertText: kw,
                                range: range
                            });
                        }
                    }
                }

                // D. Fonctions intégrées
                if (def && def.builtinFunctions) {
                    for (const fn of def.builtinFunctions) {
                        if (!DOCS[fn]) {
                            suggestions.push({
                                label: fn,
                                kind: monaco.languages.CompletionItemKind.Function,
                                insertText: fn,
                                range: range
                            });
                        }
                    }
                }

                // E. Analyse dynamique des variables et SUB du document en cours
                const text = model.getValue();
                const subMatches = text.matchAll(/\b(?:SUB|FUNCTION)\s+([a-zA-Z_][a-zA-Z0-9_]*)/gi);
                for (const m of subMatches) {
                    suggestions.push({
                        label: m[1],
                        kind: monaco.languages.CompletionItemKind.Method,
                        insertText: m[1],
                        detail: 'Procédure locale',
                        range: range
                    });
                }

                return { suggestions };
            }
        });

        // 2. Fournisseur de documentation au survol (Hover Provider)
        monaco.languages.registerHoverProvider('qbasic', {
            provideHover: function(model, position) {
                const word = model.getWordAtPosition(position);
                if (!word) return null;
                const upper = word.word.toUpperCase();
                const info = DOCS[upper];
                if (info) {
                    return {
                        range: new monaco.Range(position.lineNumber, word.startColumn, position.lineNumber, word.endColumn),
                        contents: [
                            { value: `**QBasic : ${upper}** — *${info.detail}*` },
                            { value: info.doc }
                        ]
                    };
                }
                return null;
            }
        });
    };
})();
