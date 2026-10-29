const fs = require('fs');
const path = require('path');

const HLP_DIR = path.resolve(__dirname, 'qbasic_hlp');

// 1. Load topics and contexts
function readJsonWithoutBOM(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    if (content.charCodeAt(0) === 0xFEFF) {
        content = content.slice(1);
    }
    return JSON.parse(content);
}

const topics = readJsonWithoutBOM(path.join(HLP_DIR, 'topics.json'));
const contexts = readJsonWithoutBOM(path.join(HLP_DIR, 'contexts.json'));

console.log(`Loaded ${topics.length} topics and ${Object.keys(contexts).length} context strings.`);

// 2. Parse Index from T00B6.html
let indexHtml = fs.readFileSync(path.join(HLP_DIR, 'T00B6.html'), 'utf8');
if (indexHtml.charCodeAt(0) === 0xFEFF) indexHtml = indexHtml.slice(1);
const indexRegex = /<a href="(T[0-9A-F]{4})\.html">([^<]+)<\/a>/g;
let match;
const indexEntries = [];
const seenIndex = new Set();

while ((match = indexRegex.exec(indexHtml)) !== null) {
    const targetId = match[1];
    const fullLabel = match[2].trim();
    if (fullLabel === 'Contents' || fullLabel === 'Index' || fullLabel === 'Back') continue;

    let kind = 'Keyword';
    if (fullLabel.endsWith(' Statement')) kind = 'Statement';
    else if (fullLabel.endsWith(' Function')) kind = 'Function';
    else if (fullLabel.endsWith(' Operator')) kind = 'Operator';
    else if (fullLabel.includes('Metacommand')) kind = 'Metacommand';

    const cleanName = fullLabel.replace(/ (Statement|Function|Keyword|Operator|Metacommand)$/i, '').trim();
    const key = `${cleanName}-${targetId}`;
    if (!seenIndex.has(key)) {
        seenIndex.add(key);
        indexEntries.push({
            id: targetId,
            label: fullLabel,
            name: cleanName,
            kind: kind,
            letter: cleanName[0].toUpperCase()
        });
    }
}

// Group index entries by first letter
indexEntries.sort((a, b) => a.name.localeCompare(b.name));
const indexByLetter = {};
for (const entry of indexEntries) {
    let letGroup = entry.letter;
    if (letGroup === '$') letGroup = '$';
    else if (!/[A-Z]/.test(letGroup)) letGroup = '#';
    if (!indexByLetter[letGroup]) indexByLetter[letGroup] = [];
    indexByLetter[letGroup].push(entry);
}

console.log(`Parsed ${indexEntries.length} index entries across ${Object.keys(indexByLetter).length} letters.`);

// 3. Build Structured Table of Contents (TOC)
const tocStructure = [
    {
        title: "Démarrage & Orientation",
        icon: "🌟",
        items: [
            { id: "T0000", title: "Guide de Survie (Survival Guide)" },
            { id: "T0001", title: "Utilisation de l'Aide (Using Help)" },
            { id: "T0002", title: "Sommaire Général (Table of Contents)" },
            { id: "T00B6", title: "Index Alphabétique Complet (Index)" },
            { id: "T0005", title: "Menus et Commandes" },
            { id: "T0006", title: "Utilisation des Boîtes de Dialogue" },
            { id: "T0004", title: "Conventions de Syntaxe" }
        ]
    },
    {
        title: "Touches & Raccourcis",
        icon: "⌨",
        items: [
            { id: "T0009", title: "Résumé des Raccourcis Clavier" },
            { id: "T000D", title: "Touches d'Édition" },
            { id: "T000A", title: "Touches d'Exécution et Débogage" },
            { id: "T000B", title: "Touches d'Affichage et Recherche" },
            { id: "T000C", title: "Touches d'Aide" }
        ]
    },
    {
        title: "Environnement & Langage",
        icon: "💻",
        items: [
            { id: "T0007", title: "Ligne de Commande QBasic" },
            { id: "T0008", title: "Jeu de Caractères Basic" },
            { id: "T000E", title: "Mots-clés par Tâche de Programmation" },
            { id: "T0013", title: "Limites de l'Environnement QBasic" },
            { id: "T0014", title: "Valeurs Maximales (Limites)" },
            { id: "T0015", title: "Expressions et Mathématiques" },
            { id: "T0016", title: "Instructions et Fonctions" },
            { id: "T000F", title: "Différences de Versions" },
            { id: "T0017", title: "Conversion des Programmes BASICA" },
            { id: "T0018", title: "Au-delà de QBasic (QuickBASIC)" },
            { id: "T0003", title: "Copyrights et Marques" }
        ]
    },
    {
        title: "Tables de Référence",
        icon: "📊",
        items: [
            { id: "T0010", title: "Table des Caractères ASCII (0-255)" },
            { id: "T0011", title: "Codes de Scan Clavier (Scan Codes)" },
            { id: "T0012", title: "Codes d'Erreur d'Exécution" }
        ]
    }
];

// 4. Build Categories from Task list
const rawCategories = [
    {
        name: "Graphismes & Couleurs",
        icon: "🎨",
        keywords: ["CIRCLE", "COLOR", "DRAW", "LINE", "PAINT", "PALETTE", "PCOPY", "PMAP", "POINT", "PRESET", "PSET", "SCREEN", "VIEW", "WINDOW"]
    },
    {
        name: "Chaînes de Caractères",
        icon: "🔤",
        keywords: ["ASC", "CHR$", "HEX$", "INSTR", "LCASE$", "LEFT$", "LEN", "LSET", "LTRIM$", "MID$", "OCT$", "RIGHT$", "RSET", "RTRIM$", "SPACE$", "STR$", "STRING$", "UCASE$", "VAL"]
    },
    {
        name: "Fichiers & Disque",
        icon: "💾",
        keywords: ["OPEN", "CLOSE", "EOF", "FILEATTR", "FREEFILE", "GET", "INPUT", "INPUT$", "LINE INPUT", "LOC", "LOCK", "LOF", "PUT", "SEEK", "UNLOCK", "WRITE", "CHDIR", "KILL", "MKDIR", "NAME", "RMDIR"]
    },
    {
        name: "Mathématiques & Nombres",
        icon: "🧮",
        keywords: ["ABS", "ATN", "CDBL", "CINT", "CLNG", "COS", "CSNG", "CVDMBF", "CVSMBF", "EXP", "FIX", "INT", "LOG", "RANDOMIZE", "RND", "SGN", "SIN", "SQR", "TAN", "TIME$"]
    },
    {
        name: "Entrées / Sorties (Écran, Clavier, Port)",
        icon: "🖥",
        keywords: ["CLS", "CSRLIN", "INKEY$", "INP", "INPUT", "LINE INPUT", "LOCATE", "LPOS", "LPRINT", "LPRINT USING", "OPEN COM", "OUT", "POS", "PRINT", "PRINT USING", "SPC", "TAB", "VIEW PRINT", "WAIT", "WIDTH"]
    },
    {
        name: "Contrôle du Flux & Boucles",
        icon: "🔄",
        keywords: ["DO...LOOP", "END", "EXIT", "FOR...NEXT", "GOSUB...RETURN", "GOTO", "IF...THEN...ELSE", "ON...GOSUB", "ON...GOTO", "SELECT CASE", "STOP", "SYSTEM", "WHILE...WEND"]
    },
    {
        name: "Procédures & Fonctions (SUB/FUNCTION)",
        icon: "📦",
        keywords: ["CALL", "CALL ABSOLUTE", "DECLARE", "FUNCTION", "RUN", "SHARED", "SHELL", "STATIC", "SUB"]
    },
    {
        name: "Déclaration & Types de Données",
        icon: "📐",
        keywords: ["CONST", "DATA", "DIM", "ERASE", "OPTION BASE", "READ", "REDIM", "REM", "RESTORE", "SWAP", "TYPE...END TYPE", "DEFINT", "DEFLNG", "DEFSNG", "DEFDBL", "DEFSTR"]
    },
    {
        name: "Gestion de la Mémoire",
        icon: "🧠",
        keywords: ["CLEAR", "FRE", "PEEK", "POKE", "DEF SEG", "VARPTR", "VARSEG"]
    },
    {
        name: "Gestion des Événements & Erreurs",
        icon: "🚨",
        keywords: ["COM", "ERDEV", "ERDEV$", "ERL", "ERR", "ERROR", "KEY", "ON COM", "ON ERROR", "ON KEY", "ON PEN", "ON PLAY", "ON STRIG", "ON TIMER", "PEN", "PLAY", "RESUME", "RETURN", "STRIG", "TIMER"]
    },
    {
        name: "Son & Musique",
        icon: "🎵",
        keywords: ["BEEP", "PLAY", "SOUND"]
    }
];

// Enrich categories with topic IDs from contexts
const categories = rawCategories.map(cat => {
    const items = [];
    for (const kw of cat.keywords) {
        let topicId = contexts[kw.toUpperCase()];
        if (!topicId) {
            // Try normalized
            const norm = kw.replace(/(\$|\...|Statement|Function)/g, '').trim().toUpperCase();
            topicId = contexts[norm];
        }
        if (!topicId) {
            // Find in topics title
            const found = topics.find(t => t.title && t.title.toUpperCase().startsWith(kw.toUpperCase()));
            if (found) topicId = found.id;
        }
        if (topicId) {
            const topic = topics.find(t => t.id === topicId);
            items.push({
                keyword: kw,
                id: topicId,
                title: topic ? topic.title : kw
            });
        }
    }
    return {
        name: cat.name,
        icon: cat.icon,
        items: items
    };
});

// Save navigation.json and navigation.js
const navData = {
    toc: tocStructure,
    indexLetters: Object.keys(indexByLetter).sort(),
    indexByLetter: indexByLetter,
    indexFlat: indexEntries,
    categories: categories
};

function makeUniversalJs(varName, jsonStr) {
    return `const ${varName} = ${jsonStr};
if (typeof module !== 'undefined' && module.exports) module.exports = ${varName};
if (typeof window !== 'undefined') window.${varName} = ${varName};
`;
}

fs.writeFileSync(path.join(HLP_DIR, 'navigation.json'), JSON.stringify(navData, null, 2), 'utf8');
fs.writeFileSync(path.join(HLP_DIR, 'navigation.js'), makeUniversalJs('QBASIC_HELP_NAV', JSON.stringify(navData)), 'utf8');

// Also update topics.js and contexts.js if needed
function ensureUniversal(fileName, varName) {
    const fPath = path.join(HLP_DIR, fileName);
    let content = fs.readFileSync(fPath, 'utf8');
    if (content.charCodeAt(0) === 0xFEFF) content = content.slice(1);
    if (!content.includes('module.exports')) {
        content += `\nif (typeof module !== 'undefined' && module.exports) module.exports = ${varName};\nif (typeof window !== 'undefined') window.${varName} = ${varName};\n`;
        fs.writeFileSync(fPath, content, 'utf8');
    }
}
ensureUniversal('topics.js', 'QBASIC_HELP_TOPICS');
ensureUniversal('contexts.js', 'QBASIC_HELP_CONTEXTS');

// 5. Enhance standalone HTML files with top banner
const htmlFiles = fs.readdirSync(HLP_DIR).filter(f => f.startsWith('T') && f.endsWith('.html'));
console.log(`Enhancing ${htmlFiles.length} standalone HTML files...`);

for (const file of htmlFiles) {
    const id = file.replace('.html', '');
    const filePath = path.join(HLP_DIR, file);
    let html = fs.readFileSync(filePath, 'utf8');
    if (html.charCodeAt(0) === 0xFEFF) html = html.slice(1);

    // If banner not present, inject it
    if (!html.includes('standalone-nav-bar')) {
        const banner = `
    <div class="standalone-nav-bar">
      <span>🖩 QBasic Help &bull; ${id}</span>
      <a href="index.html#${id}" title="Ouvrir dans l'application web avec recherche et navigation">🚀 Ouvrir dans le portail d'aide complet</a>
    </div>`;

        html = html.replace(/<body[^>]*>/i, `<body class="standalone-body">\n${banner}`);
        fs.writeFileSync(filePath, html, 'utf8');
    }
}

console.log('Navigation metadata and standalone HTML files updated successfully.');
