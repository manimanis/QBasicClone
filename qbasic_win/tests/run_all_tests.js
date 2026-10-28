const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

process.env.QB_TEST_MODE = '1';

const exePath = path.join(__dirname, '..', 'qbasic_win.exe');
const testsDir = __dirname;
const vintageDir = path.join(__dirname, 'qbasic-programs', 'qbasic-programs-master');
const gamesDir = path.join(__dirname, 'games');

const colors = {
    reset: "\x1b[0m",
    bright: "\x1b[1m",
    dim: "\x1b[2m",
    green: "\x1b[32m",
    red: "\x1b[31m",
    yellow: "\x1b[33m",
    cyan: "\x1b[36m",
    magenta: "\x1b[35m",
    white: "\x1b[37m",
    bgBlue: "\x1b[44m"
};

const testFiles = fs.readdirSync(testsDir)
    .filter(f => f.startsWith('test_') && f.endsWith('.bas'))
    .sort();

const vintagePrograms = [
    {
        name: "FIBONUM.BAS",
        category: "ALGORITHME (RECURSION)",
        desc: "Calcul récursif du 7e terme de Fibonacci (fact(7) == 13)",
        input: "7\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("13")
    },
    {
        name: "PRIME1.BAS",
        category: "MATHEMATIQUES",
        desc: "Calcul du 10e nombre premier (29) via boucles et GOTO",
        input: "10\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("29")
    },
    {
        name: "TWOS.BAS",
        category: "CHAÎNES & PROGRESSIONS",
        desc: "Comptage des '2' dans 5 suites arithmétiques de 2000 termes",
        input: "1, 2, 3\n2, 4, 6\n10, 20, 30\n1, 3, 5\n5, 10, 15\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("601") && stdout.includes("1300")
    },
    {
        name: "BWDATE.BAS",
        category: "CALCUL DE DATES",
        desc: "Conversion de 100 000 secondes écoulées en date/heure formatée",
        input: "100000\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("Thursday, January2, 2003, 3:46:40 AM")
    },
    {
        name: "IDNUMS.BAS",
        category: "ALGORITHME (SUB & TABLEAUX)",
        desc: "Calcul de clé de contrôle pondérée et recherche de prochains PINs",
        input: "1234567\n2345678\n3456789\n4567890\n5678901\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("1234572") && stdout.includes("2345681")
    },
    {
        name: "HYBRID.BAS",
        category: "GENETIQUE & STATISTIQUES",
        desc: "Calcul des ratios mendéliens de croisements dihybrides",
        input: "2\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("1:2:1:2:4:2:1:2:1")
    },
    {
        name: "7X7GRID.BAS",
        category: "AFFICHAGE (LOCATE/PRINT)",
        desc: "Dessin géométrique d'une grille 7x7 sur la matrice d'écran",
        input: "",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("|") && stdout.includes("_")
    },
    {
        name: "ACSL1BW.BAS",
        category: "ASCII ART & SUBROUTINES",
        desc: "Génération de figures géométriques ACSL (Carrés, Croix, Bandes)",
        input: "S\n3, 1\nS\n2, 2\nH\n3, 1\nL\n3, 1\nB\n2, 2, 1\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("* * *")
    },
    {
        name: "ACSL4BW.BAS",
        category: "THEORIE DES NOMBRES",
        desc: "Test de nombres de Smith, premiers circulaires et tronquables",
        input: "1193\n13\n7\n4\n27\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("Circular") && stdout.includes("Smith")
    },
    {
        name: "BWACSL3.BAS",
        category: "MANIPULATION DE CHAINES",
        desc: "Comptage, inversion par mot et tri alphabétique complet",
        input: "hello world quick basic\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("olleh dlrow kciuq cisab") && stdout.includes("basic")
    },
    {
        name: "BUBBLE.BAS",
        category: "FICHIERS & TRI (BUBBLE SORT)",
        desc: "Tri à bulles de 1000 entiers (NUMBERS.TXT -> bubble.txt)",
        input: "",
        verify: (stdout, exitCode, progDir) => {
            const outPath = path.join(progDir, 'bubble.txt');
            return exitCode === 0 && fs.existsSync(outPath) && fs.readFileSync(outPath, 'utf8').includes("This sorting took");
        }
    },
    {
        name: "SHELL.BAS",
        category: "FICHIERS & TRI (SHELL SORT)",
        desc: "Tri de Shell de 1000 entiers (NUMBERS.TXT -> shell.txt)",
        input: "",
        verify: (stdout, exitCode, progDir) => {
            const outPath = path.join(progDir, 'shell.txt');
            return exitCode === 0 && fs.existsSync(outPath) && fs.readFileSync(outPath, 'utf8').includes("This sorting took");
        }
    },
    {
        name: "RNDNUM.BAS",
        category: "ALEATOIRE & EXPORT FICHIER",
        desc: "Générateur pseudo-aléatoire et écriture dans rndnum.txt",
        input: "10\n50\n5\n",
        verify: (stdout, exitCode, progDir) => {
            const outPath = path.join(progDir, 'rndnum.txt');
            return exitCode === 0 && fs.existsSync(outPath) && fs.readFileSync(outPath, 'utf8').length > 0;
        }
    },
    {
        name: "BWML.BAS",
        category: "FICHIERS CSV (MADLIB)",
        desc: "Analyse lexicale de madlib.txt et composition de l'histoire endlib.txt",
        input: "Alice\nAtlantis\nwizard\nbrave\nknight\nWow\n50\npizza\nhat\ncoder\ndays\nshiny\nmonths\ndark\nrock\ncastle\n10\nleg\n",
        verify: (stdout, exitCode, progDir) => {
            const outPath = path.join(progDir, 'endlib.txt');
            return exitCode === 0 && fs.existsSync(outPath) && fs.readFileSync(outPath, 'utf8').includes("The Story of Xyzzilaus");
        }
    },
    {
        name: "BWFLAG.BAS",
        category: "TURTLE DRAW & MUSIQUE",
        desc: "Drapeau américain (DRAW/PAINT/GET/PUT) et hymne national (PLAY)",
        input: "",
        verify: (stdout, exitCode) => exitCode === 0
    },
    {
        name: "SONG.BAS",
        category: "AUDIO MML (MOZART)",
        desc: "Interprétation poly-octave de Eine Kleine Nachtmusik via PLAY",
        input: "",
        verify: (stdout, exitCode) => exitCode === 0
    },
    {
        name: "TICTAC.BAS",
        category: "JEU INTERACTIF (MORPION)",
        desc: "Partie complète de Morpion 2 joueurs avec détection de victoire",
        input: "Alice\nX\nBob\nO\n1\n1\n4\n2\n5\n3\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("Alice wins!")
    },
    {
        name: "RBTRIVIA.BAS",
        category: "JEU DE CULTURE GENERALE",
        desc: "Quiz interactif de 20 questions à choix multiples avec score final",
        input: "Y\nC\nA\nC\nC\nB\nD\nA\nC\nF\nC\nA\nB\nC\nD\nA\nB\nC\nD\nA\nB\nY\n\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("13correct") && stdout.includes("THE END")
    },
    {
        name: "TETRIS.BAS",
        category: "JEU COMPLET (FUTURE BLOCKS)",
        desc: "Navigation TitleScreen -> Menu interactif -> Sortie propre (Tableaux 3D, VGA DAC)",
        customPath: path.join(__dirname, 'tetris', 'tetris.bas'),
        input: " ".repeat(20) + "6\n",
        verify: (stdout, exitCode) => exitCode === 0
    },
    {
        name: "TETRIS_AI.BAS",
        category: "IA TETRIS AUTONOME",
        desc: "Exécution autonome du mode ordinateur (IA de placement de blocs & heuristique)",
        customPath: path.join(__dirname, 'tetris', 'tetris.bas'),
        input: " ".repeat(16) + "3\x1b 6\n",
        verify: (stdout, exitCode) => exitCode === 0
    },
    {
        name: "CONX4.BAS",
        category: "JEU COMPLET (PUISSANCE 4)",
        desc: "Partie de Puissance 4 à 2 joueurs avec alignement vertical victorieux",
        input: "Alice\nBob\n1\n2\n1\n2\n1\n2\n1\n2\n1\n",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("wins!!")
    }
];

const gamePrograms = [
    {
        name: "DEMO.BAS",
        category: "DÉMONSTRATION DU PORT WIN64",
        desc: "Validation calculs flottants, chaînes, boucles, timer et affichage couleur",
        customPath: path.join(gamesDir, 'demo.bas'),
        input: "",
        verify: (stdout, exitCode) => exitCode === 0 && stdout.includes("Test termine avec succes !")
    },
    {
        name: "GORILLA.BAS",
        category: "JEU VINTAGE DOS (IBM 1991)",
        desc: "Partie de Gorillas (paysage urbain procédural, balistique bananes, explosions, score)",
        customPath: path.join(gamesDir, 'gorilla.bas'),
        input: " Player 1\nPlayer 2\n1\n9.8\nPq\n",
        verify: (stdout, exitCode) => exitCode === 0 && (stdout.includes("G O R I L L A S") || stdout.includes("Angle:") || stdout.includes("GAME OVER!"))
    },
    {
        name: "NIBBLES.BAS",
        category: "JEU VINTAGE DOS (MS 1990)",
        desc: "Partie de Nibbles (arène graphique 80x50, physique serpent, bonus aléatoires, sortie propre)",
        customPath: path.join(gamesDir, 'nibbles.bas'),
        input: " 1\n0\n100\nxN",
        verify: (stdout, exitCode) => exitCode === 0 && (stdout.includes("Nibbles!") || stdout.includes("G A M E   O V E R") || stdout.includes("Level"))
    }
];

console.log(`${colors.bright}${colors.cyan}========================================================================${colors.reset}`);
console.log(`${colors.bright}${colors.white}       BATTERIE DE TESTS AUTOMATISÉE AVANCÉE - QBASIC_WIN.EXE${colors.reset}`);
console.log(`${colors.cyan}========================================================================${colors.reset}\n`);

let grandTotal = 0;
let grandPassed = 0;
let grandFailed = 0;
const resultsByCategory = [];
const overallStartTime = Date.now();

// ============================================================================
// PARTIE 1 : SUITES DE TESTS UNITAIRES DU NOYAU
// ============================================================================
console.log(`${colors.bright}${colors.magenta}--- PARTIE 1 : SUITES DE TESTS UNITAIRES DU NOYAU (${testFiles.length} suites) ---${colors.reset}\n`);

for (const testFile of testFiles) {
    const fullPath = path.join(testsDir, testFile);
    const categoryName = testFile.replace(/^test_\d+_(.*)\.bas$/, '$1').toUpperCase();
    
    const startTime = Date.now();
    let stdout = '';
    let exitCode = 0;
    try {
        stdout = execFileSync(exePath, ['-r', fullPath], {
            cwd: path.join(__dirname, '..'),
            encoding: 'utf8',
            timeout: 15000
        });
    } catch (err) {
        exitCode = err.status || 1;
        stdout = (err.stdout || '') + '\n' + (err.stderr || '');
    }
    const elapsed = Date.now() - startTime;

    const lines = stdout.split(/\r?\n/).map(l => l.trim()).filter(Boolean);
    let suitePass = 0;
    let suiteFail = 0;
    const items = [];

    for (const line of lines) {
        if (line.includes(': PASS')) {
            suitePass++;
            items.push({ name: line.replace(': PASS', '').trim(), status: 'PASS' });
        } else if (line.includes(': FAIL')) {
            suiteFail++;
            items.push({ name: line.replace(': FAIL', '').trim(), status: 'FAIL' });
        }
    }

    grandTotal += (suitePass + suiteFail);
    grandPassed += suitePass;
    grandFailed += suiteFail;

    resultsByCategory.push({
        type: 'unit_suite',
        file: testFile,
        category: categoryName,
        passed: suitePass,
        failed: suiteFail,
        total: suitePass + suiteFail,
        elapsed,
        exitCode,
        items
    });

    const isSuccess = (suiteFail === 0 && exitCode === 0 && (suitePass + suiteFail) > 0);
    const badge = isSuccess ? `${colors.green}[PASS]${colors.reset}` : `${colors.red}[FAIL]${colors.reset}`;
    const fileLabel = `${colors.bright}${testFile.padEnd(28)}${colors.reset}`;
    const catLabel = `${colors.cyan}${categoryName.padEnd(22)}${colors.reset}`;
    const scoreLabel = `${colors.yellow}${suitePass.toString().padStart(2)}/${(suitePass + suiteFail).toString().padEnd(2)} assertions${colors.reset}`;
    const timeLabel = `${colors.dim}(${elapsed} ms)${colors.reset}`;

    console.log(` ${badge}  ${fileLabel}  ${catLabel}  ${scoreLabel}  ${timeLabel}`);
}

// ============================================================================
// PARTIE 2 : PROGRAMMES RÉELS DU DOSSIER tests/qbasic-programs
// ============================================================================
console.log(`\n${colors.bright}${colors.magenta}--- PARTIE 2 : PROGRAMMES DU DOSSIER qbasic-programs (${vintagePrograms.length} programmes) ---${colors.reset}\n`);

const vintageResults = [];

for (const prog of vintagePrograms) {
    const fullPath = prog.customPath || path.join(vintageDir, prog.name);
    const progDir = path.dirname(fullPath);
    const startTime = Date.now();
    let stdout = '';
    let exitCode = 0;
    
    try {
        stdout = execFileSync(exePath, ['-r', fullPath], {
            cwd: progDir,
            input: prog.input || '',
            encoding: 'utf8',
            timeout: 15000
        });
    } catch (err) {
        exitCode = err.status || 1;
        stdout = (err.stdout || '') + '\n' + (err.stderr || '');
    }
    const elapsed = Date.now() - startTime;

    const isPass = prog.verify(stdout, exitCode, progDir);
    grandTotal += 1;
    if (isPass) grandPassed += 1;
    else grandFailed += 1;

    vintageResults.push({
        type: 'vintage_program',
        name: prog.name,
        category: prog.category,
        desc: prog.desc,
        passed: isPass ? 1 : 0,
        failed: isPass ? 0 : 1,
        total: 1,
        elapsed,
        exitCode,
        status: isPass ? 'PASS' : 'FAIL'
    });

    const badge = isPass ? `${colors.green}[PASS]${colors.reset}` : `${colors.red}[FAIL]${colors.reset}`;
    const nameLabel = `${colors.bright}${prog.name.padEnd(16)}${colors.reset}`;
    const catLabel = `${colors.cyan}${prog.category.padEnd(30)}${colors.reset}`;
    const descLabel = `${colors.dim}${prog.desc.padEnd(46)}${colors.reset}`;
    const timeLabel = `${colors.yellow}(${elapsed} ms)${colors.reset}`;

    console.log(` ${badge}  ${nameLabel}  ${catLabel}  ${timeLabel}`);
}

// ============================================================================
// PARTIE 3 : JEUX OFFICIELS DU DOSSIER tests/games (3 jeux)
// ============================================================================
console.log(`\n${colors.bright}${colors.magenta}--- PARTIE 3 : JEUX DU DOSSIER tests/games (${gamePrograms.length} jeux) ---${colors.reset}\n`);

const gameResults = [];

for (const game of gamePrograms) {
    const fullPath = game.customPath || path.join(gamesDir, game.name);
    const gameDir = path.dirname(fullPath);
    const startTime = Date.now();
    let stdout = '';
    let exitCode = 0;
    
    try {
        stdout = execFileSync(exePath, ['-r', fullPath], {
            cwd: path.join(__dirname, '..'),
            input: game.input || '',
            encoding: 'utf8',
            timeout: 20000,
            env: { ...process.env, SDL_VIDEODRIVER: 'dummy' }
        });
    } catch (err) {
        exitCode = err.status || 1;
        stdout = (err.stdout || '') + '\n' + (err.stderr || '');
    }
    const elapsed = Date.now() - startTime;

    const isPass = game.verify(stdout, exitCode, gameDir);
    grandTotal += 1;
    if (isPass) grandPassed += 1;
    else grandFailed += 1;

    gameResults.push({
        type: 'game_program',
        name: game.name,
        category: game.category,
        desc: game.desc,
        passed: isPass ? 1 : 0,
        failed: isPass ? 0 : 1,
        total: 1,
        elapsed,
        exitCode,
        status: isPass ? 'PASS' : 'FAIL'
    });

    const badge = isPass ? `${colors.green}[PASS]${colors.reset}` : `${colors.red}[FAIL]${colors.reset}`;
    const nameLabel = `${colors.bright}${game.name.padEnd(16)}${colors.reset}`;
    const catLabel = `${colors.cyan}${game.category.padEnd(30)}${colors.reset}`;
    const timeLabel = `${colors.yellow}(${elapsed} ms)${colors.reset}`;

    console.log(` ${badge}  ${nameLabel}  ${catLabel}  ${timeLabel}`);
}

const totalElapsed = Date.now() - overallStartTime;
const passRate = grandTotal > 0 ? ((grandPassed / grandTotal) * 100).toFixed(1) : 0;

console.log(`\n${colors.cyan}========================================================================${colors.reset}`);
console.log(`${colors.bright}${colors.white}                         BILAN GLOBAL D'EXÉCUTION${colors.reset}`);
console.log(`${colors.cyan}========================================================================${colors.reset}`);
console.log(`  Suites de tests unitaires : ${colors.bright}${testFiles.length} (${resultsByCategory.reduce((a, s) => a + s.total, 0)} assertions)${colors.reset}`);
console.log(`  Programmes réels exécutés : ${colors.bright}${vintagePrograms.length} (dossier tests/qbasic-programs)${colors.reset}`);
console.log(`  Jeux réels exécutés       : ${colors.bright}${gamePrograms.length} (dossier tests/games)${colors.reset}`);
console.log(`  Total des vérifications   : ${colors.bright}${grandTotal}${colors.reset}`);
console.log(`  Vérifications validées    : ${colors.green}${colors.bright}${grandPassed} (${passRate}%)${colors.reset}`);
console.log(`  Vérifications en échec    : ${grandFailed === 0 ? colors.green : colors.red}${colors.bright}${grandFailed}${colors.reset}`);
console.log(`  Temps global d'exécution  : ${colors.yellow}${colors.bright}${(totalElapsed / 1000).toFixed(2)} secondes${colors.reset}`);
console.log(`${colors.cyan}========================================================================${colors.reset}\n`);

// 1. Sauvegarder les résultats détaillés en JSON
const jsonOutput = {
    timestamp: new Date().toISOString(),
    totalSuites: testFiles.length,
    totalVintagePrograms: vintagePrograms.length,
    totalGames: gamePrograms.length,
    grandTotal,
    grandPassed,
    grandFailed,
    passRate: `${passRate}%`,
    totalElapsedMs: totalElapsed,
    suites: resultsByCategory,
    vintagePrograms: vintageResults,
    games: gameResults
};
fs.writeFileSync(path.join(__dirname, 'test_results.json'), JSON.stringify(jsonOutput, null, 2));
console.log(`Rapport JSON généré : ${colors.bright}tests/test_results.json${colors.reset}`);

// 2. Générer un rapport HTML interactif et moderne
const htmlContent = `<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QBasic Windows Native Port - Rapport de Tests Unitaires & Programmes Réels</title>
    <style>
        :root {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-card: #334155;
            --text-primary: #f8fafc;
            --text-secondary: #94a3b8;
            --accent-green: #10b981;
            --accent-red: #ef4444;
            --accent-cyan: #06b6d4;
            --accent-blue: #3b82f6;
            --accent-purple: #a855f7;
            --border: #475569;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.6;
            padding: 2rem;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        header { margin-bottom: 2rem; border-bottom: 1px solid var(--border); padding-bottom: 1.5rem; }
        h1 { font-size: 2.2rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem; }
        .subtitle { color: var(--text-secondary); font-size: 1.1rem; }
        
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.25rem;
            margin-bottom: 2.5rem;
        }
        .metric-card {
            background-color: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1.5rem;
            display: flex;
            flex-direction: column;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2);
        }
        .metric-title { font-size: 0.875rem; text-transform: uppercase; color: var(--text-secondary); letter-spacing: 0.05em; margin-bottom: 0.5rem; }
        .metric-value { font-size: 2rem; font-weight: 800; color: var(--text-primary); }
        .metric-value.success { color: var(--accent-green); }
        .metric-value.error { color: var(--accent-red); }
        .metric-value.highlight { color: var(--accent-cyan); }
        .metric-value.purple { color: var(--accent-purple); }
        
        .section-header { display: flex; justify-content: space-between; align-items: center; margin-top: 2rem; margin-bottom: 1.25rem; }
        .search-box {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            color: var(--text-primary);
            padding: 0.6rem 1rem;
            border-radius: 8px;
            font-size: 0.95rem;
            width: 280px;
        }
        
        .suite-card {
            background-color: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 10px;
            margin-bottom: 1rem;
            overflow: hidden;
            transition: border-color 0.2s;
        }
        .suite-card:hover { border-color: var(--accent-cyan); }
        .suite-header {
            padding: 1rem 1.5rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
        }
        .suite-info { display: flex; align-items: center; gap: 1rem; }
        .badge {
            font-size: 0.75rem;
            font-weight: 700;
            padding: 0.25rem 0.6rem;
            border-radius: 6px;
            text-transform: uppercase;
        }
        .badge-pass { background-color: rgba(16, 185, 129, 0.2); color: var(--accent-green); border: 1px solid var(--accent-green); }
        .badge-fail { background-color: rgba(239, 68, 68, 0.2); color: var(--accent-red); border: 1px solid var(--accent-red); }
        .suite-name { font-weight: 600; font-size: 1.05rem; }
        .suite-cat { color: var(--text-secondary); font-size: 0.875rem; background: var(--bg-card); padding: 0.2rem 0.5rem; border-radius: 4px; }
        .suite-stats { display: flex; align-items: center; gap: 1.5rem; color: var(--text-secondary); font-size: 0.9rem; }
        
        .suite-content {
            padding: 1rem 1.5rem;
            background-color: rgba(15, 23, 42, 0.6);
            border-top: 1px solid var(--border);
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 0.75rem;
        }
        .assertion-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0.5rem 0.75rem;
            background: var(--bg-secondary);
            border-radius: 6px;
            font-size: 0.875rem;
            border: 1px solid rgba(71, 85, 105, 0.4);
        }
        .assertion-pass { color: var(--accent-green); font-weight: 600; }
        .assertion-fail { color: var(--accent-red); font-weight: 600; }
        .tag-vintage { background: rgba(168, 85, 247, 0.2); color: var(--accent-purple); border: 1px solid var(--accent-purple); }
        .tetris-showcase {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        .screenshot-card {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
            text-align: center;
        }
        .screenshot-card img {
            width: 100%;
            height: auto;
            display: block;
            border-bottom: 1px solid var(--border);
        }
        .screenshot-card .caption {
            padding: 0.75rem 1rem;
            font-size: 0.9rem;
            font-weight: 600;
            color: var(--accent-cyan);
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Batterie de Tests Complète QBasic Port Win32</h1>
            <p class="subtitle">${testFiles.length} suites unitaires, ${vintagePrograms.length} programmes DOS vintage & ${gamePrograms.length} jeux complets (tests/games) intégrés et validés</p>
        </header>

        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-title">Suites Unitaires</div>
                <div class="metric-value highlight">${testFiles.length}</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Programmes Réels</div>
                <div class="metric-value purple">${vintagePrograms.length}</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Jeux tests/games</div>
                <div class="metric-value" style="color: var(--accent-cyan);">${gamePrograms.length}</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Vérifications Validées</div>
                <div class="metric-value success">${grandPassed} / ${grandTotal}</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Taux de Réussite</div>
                <div class="metric-value ${grandFailed === 0 ? 'success' : 'error'}">${passRate}%</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps Total</div>
                <div class="metric-value">${(totalElapsed / 1000).toFixed(2)}s</div>
            </div>
        </div>

        <div class="section-header">
            <h2>Jeux Rétro & Démonstrations (Dossier tests/games)</h2>
        </div>
        <div id="gamesList">
            ${gameResults.map(p => `
                <div class="suite-card" data-name="${p.name} ${p.category} ${p.desc}">
                    <div class="suite-header" style="cursor: default;">
                        <div class="suite-info">
                            <span class="badge ${p.status === 'PASS' ? 'badge-pass' : 'badge-fail'}">${p.status}</span>
                            <span class="badge" style="background-color: rgba(168, 85, 247, 0.2); color: var(--accent-purple); border: 1px solid var(--accent-purple);">JEU DOS</span>
                            <span class="suite-name">${p.name}</span>
                            <span class="suite-cat">${p.category}</span>
                            <span style="color: var(--text-secondary); font-size: 0.875rem;">${p.desc}</span>
                        </div>
                        <div class="suite-stats">
                            <span>${p.elapsed} ms</span>
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>

        <div class="section-header">
            <h2>Showcase Graphique : Jeu Tetris (Future Blocks)</h2>
        </div>
        <div class="tetris-showcase">
            <div class="screenshot-card">
                <img src="tetris/screenshot1.png" alt="Écran Titre Tetris (Screen 12)">
                <div class="caption">Écran Titre 3D (SCREEN 12 & Palette VGA)</div>
            </div>
            <div class="screenshot-card">
                <img src="tetris/screenshot2.png" alt="Menu Principal">
                <div class="caption">Menu Principal Interactif (6 Modes)</div>
            </div>
            <div class="screenshot-card">
                <img src="tetris/screenshot3.png" alt="Partie en Cours / Mode IA">
                <div class="caption">Partie en Cours / Mode Ordinateur (IA Heuristique)</div>
            </div>
        </div>

        <div class="section-header">
            <h2>Programmes Réels QBasic (Vintage & Jeux)</h2>
        </div>
        <div id="vintageList">
            ${vintageResults.map(p => `
                <div class="suite-card" data-name="${p.name} ${p.category} ${p.desc}">
                    <div class="suite-header" style="cursor: default;">
                        <div class="suite-info">
                            <span class="badge ${p.status === 'PASS' ? 'badge-pass' : 'badge-fail'}">${p.status}</span>
                            <span class="badge tag-vintage">PROGRAMME DOS</span>
                            <span class="suite-name">${p.name}</span>
                            <span class="suite-cat">${p.category}</span>
                            <span style="color: var(--text-secondary); font-size: 0.875rem;">${p.desc}</span>
                        </div>
                        <div class="suite-stats">
                            <span>${p.elapsed} ms</span>
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>

        <div class="section-header">
            <h2>Suites de Tests Unitaires du Noyau (${testFiles.length} Suites)</h2>
            <input type="text" id="searchBox" class="search-box" placeholder="Filtrer une suite ou assertion...">
        </div>

        <div id="suitesList">
            ${resultsByCategory.map(s => `
                <div class="suite-card" data-name="${s.file} ${s.category}">
                    <div class="suite-header" onclick="this.nextElementSibling.style.display = (this.nextElementSibling.style.display === 'none' ? 'grid' : 'none')">
                        <div class="suite-info">
                            <span class="badge ${s.failed === 0 ? 'badge-pass' : 'badge-fail'}">${s.failed === 0 ? 'PASS' : 'FAIL'}</span>
                            <span class="suite-name">${s.file}</span>
                            <span class="suite-cat">${s.category}</span>
                        </div>
                        <div class="suite-stats">
                            <span><strong>${s.passed}</strong> / ${s.total} assertions</span>
                            <span>${s.elapsed} ms</span>
                        </div>
                    </div>
                    <div class="suite-content">
                        ${s.items.map(item => `
                            <div class="assertion-item">
                                <span>${item.name}</span>
                                <span class="${item.status === 'PASS' ? 'assertion-pass' : 'assertion-fail'}">${item.status}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `).join('')}
        </div>
    </div>

    <script>
        const searchBox = document.getElementById('searchBox');
        searchBox.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            document.querySelectorAll('#suitesList .suite-card, #vintageList .suite-card, #gamesList .suite-card').forEach(card => {
                const text = card.textContent.toLowerCase();
                card.style.display = text.includes(query) ? 'block' : 'none';
            });
        });
    </script>
</body>
</html>`;

fs.writeFileSync(path.join(__dirname, 'test_report.html'), htmlContent);
console.log(`Rapport HTML interactif généré : ${colors.bright}tests/test_report.html${colors.reset}\n`);
