// qbasic-lang.js - Définition Monarch du langage QBasic pour Monaco Editor
(function() {
    window.qbasicLanguageDefinition = {
        defaultToken: '',
        tokenPostfix: '.basic',
        ignoreCase: true,

        keywords: [
            'AS', 'BEEP', 'BLOAD', 'BSAVE', 'CALL', 'CASE', 'CHDIR', 'CIRCLE', 'CLEAR',
            'CLOSE', 'CLS', 'COLOR', 'COM', 'COMMON', 'CONST', 'DATA', 'DECLARE', 'DEF',
            'DEFDBL', 'DEFINT', 'DEFLNG', 'DEFSNG', 'DEFSTR', 'DEF SEG', 'DIM', 'DO',
            'DOUBLE', 'DRAW', 'ELSE', 'ELSEIF', 'END', 'END IF', 'END SELECT', 'END SUB',
            'END FUNCTION', 'END TYPE', 'ENVIRON', 'ERASE', 'ERDEV', 'ERL', 'ERR',
            'ERROR', 'EXIT', 'FIELD', 'FILES', 'FOR', 'FUNCTION', 'GET', 'GOSUB',
            'GOTO', 'IF', 'INPUT', 'INTEGER', 'IS', 'KEY', 'KILL', 'LET', 'LINE',
            'LINE INPUT', 'LOCATE', 'LOCK', 'LONG', 'LOOP', 'LPRINT', 'LSET', 'MKDIR',
            'NAME', 'NEXT', 'ON', 'ON ERROR GOTO', 'OPEN', 'OPTION', 'OPTION BASE',
            'OUT', 'OUTPUT', 'PAINT', 'PALETTE', 'PCOPY', 'PEEK', 'PEN', 'PLAY',
            'PMAP', 'POINT', 'POKE', 'POS', 'PRESET', 'PRINT', 'PRINT USING', 'PSET',
            'PUT', 'RANDOM', 'RANDOMIZE', 'READ', 'REDIM', 'REM', 'RESET', 'RESTORE',
            'RESUME', 'RETURN', 'RMDIR', 'RSET', 'RUN', 'SCREEN', 'SEEK', 'SELECT',
            'SELECT CASE', 'SHARED', 'SHELL', 'SINGLE', 'SLEEP', 'SOUND', 'STATIC',
            'STEP', 'STICK', 'STOP', 'STRIG', 'STRING', 'SUB', 'SWAP', 'SYSTEM',
            'TAB', 'THEN', 'TIMER', 'TO', 'TROFF', 'TRON', 'TYPE', 'UNLOCK', 'UNTIL',
            'USING', 'VIEW', 'WAIT', 'WEND', 'WHILE', 'WIDTH', 'WINDOW', 'WRITE'
        ],

        builtinFunctions: [
            'ABS', 'ASC', 'ATN', 'CDBL', 'CHR$', 'UCHR$', '_UCHR$', 'CINT', 'CLNG',
            'COS', 'CSNG', 'CSRLIN', 'CVD', 'CVDMBF', 'CVI', 'CVL', 'CVS', 'CVSMBF',
            'DATE$', 'ENVIRON$', 'EOF', 'EXP', 'FILEATTR', 'FIX', 'FRE', 'FREEFILE',
            'HEX$', 'INKEY$', 'INP', 'INPUT$', 'INSTR', 'INT', 'IOCTL$', 'LCASE$',
            'LEFT$', 'LEFT', 'LEN', 'LOC', 'LOF', 'LOG', 'LPOS', 'LTRIM$', 'LTRIM', 'MID$', 'MID', 'MKD$',
            'MKDMBF$', 'MKI$', 'MKL$', 'MKS$', 'MKSMBF$', 'OCT$', 'PEEK', 'PEN',
            'POINT', 'POS', 'RIGHT$', 'RIGHT', 'RND', 'RTRIM$', 'RTRIM', 'SADD', 'SCREEN', 'SEEK',
            'SGN', 'SIN', 'SPACE$', 'SPC', 'SQR', 'STICK', 'STR$', 'STR', 'STRIG', 'STRING$',
            'TAB', 'TAN', 'TIME$', 'TIMER', 'TRIM$', 'TRIM', 'UCASE$', 'UCASE', 'UCODE', '_UCODE', 'VAL', 'VARPTR',
            'VARPTR$', 'VARSEG'
        ],

        typeKeywords: [
            'INTEGER', 'LONG', 'SINGLE', 'DOUBLE', 'STRING', 'ANY'
        ],

        operators: [
            '+', '-', '*', '/', '\\', '^', '=', '<>', '<', '>', '<=', '>=',
            'MOD', 'AND', 'OR', 'XOR', 'NOT', 'EQV', 'IMP'
        ],

        brackets: [
            { open: '(', close: ')', token: 'delimiter.parenthesis' }
        ],

        tokenizer: {
            root: [
                // Commentaires commençant par '
                [/'(.*)$/, 'comment'],

                // Commentaires avec REM
                [/\bREM\b(.*)$/i, 'comment'],

                // Chaînes de caractères
                [/"([^"\\]|\\.)*"/, 'string'],

                // Mots-clés composés
                [/\b(END\s+(IF|SELECT|SUB|FUNCTION|TYPE))\b/i, 'keyword.control'],
                [/\b(SELECT\s+CASE)\b/i, 'keyword.control'],
                [/\b(LINE\s+INPUT)\b/i, 'keyword'],
                [/\b(DEF\s+SEG)\b/i, 'keyword'],
                [/\b(ON\s+ERROR\s+GOTO)\b/i, 'keyword'],

                // Nombres hexadécimaux et octaux (&H..., &O...)
                [/&H[0-9a-fA-F]+/i, 'number.hex'],
                [/&O[0-7]+/i, 'number.octal'],

                // Nombres décimaux / flottants
                [/\d+(\.\d+)?([eE][\-+]?\d+)?([!#%&])?/, 'number'],

                // Labels de ligne (numéros ou identifiants suivis de :)
                [/^[ \t]*[a-zA-Z_][a-zA-Z0-9_]*:/, 'type.identifier'],
                [/^[ \t]*\d+/, 'number.label'],

                // Identifiants et mots-clés
                [/[a-zA-Z_][a-zA-Z0-9_]*[$%&!#]?/, {
                    cases: {
                        '@keywords': 'keyword',
                        '@builtinFunctions': 'support.function',
                        '@typeKeywords': 'type',
                        '@operators': 'operator',
                        '@default': 'identifier'
                    }
                }],

                // Opérateurs
                [/[+\-*/\\^=<>]/, 'operator'],

                // Délimiteurs
                [/[(),:;]/, 'delimiter'],

                // Espaces
                [/[ \t\r\n]+/, 'white']
            ]
        }
    };

    // Configuration du langage (commentaires, auto-fermeture)
    window.qbasicLanguageConfiguration = {
        comments: {
            lineComment: "'"
        },
        brackets: [
            ['(', ')']
        ],
        autoClosingPairs: [
            { open: '(', close: ')' },
            { open: '"', close: '"' }
        ],
        surroundingPairs: [
            { open: '(', close: ')' },
            { open: '"', close: '"' }
        ]
    };
})();
