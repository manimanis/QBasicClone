const express = require('express');
const path = require('path');
const fs = require('fs');
const { spawn, exec } = require('child_process');

const app = express();
const PORT = process.env.PORT || 3000;

const ROOT_DIR = path.resolve(__dirname, '..');
const QBASIC_DIR = path.resolve(ROOT_DIR, 'qbasic_win');
const EXE_PATH = path.resolve(QBASIC_DIR, 'qbasic_win.exe');
const RUNNER_BAT = path.resolve(__dirname, 'run_program.bat');

app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));
app.use('/help', express.static(path.join(ROOT_DIR, 'qbasic_hlp')));
app.use('/vs', express.static(path.join(__dirname, 'node_modules', 'monaco-editor', 'min', 'vs')));

// Gestion du processus QBasic en cours d'exécution
let activeProcess = null;
let activeSseRes = null;

// Helper: Lister récursivement les fichiers .bas
function getBasFiles(dir, baseDir = dir) {
    let results = [];
    if (!fs.existsSync(dir)) return results;
    const list = fs.readdirSync(dir, { withFileTypes: true });
    for (const item of list) {
        const fullPath = path.join(dir, item.name);
        const relPath = path.relative(baseDir, fullPath).replace(/\\/g, '/');
        if (item.isDirectory()) {
            if (item.name === 'node_modules' || item.name === '.git') continue;
            results.push({
                name: item.name,
                path: relPath,
                fullPath,
                isDir: true,
                children: getBasFiles(fullPath, baseDir)
            });
        } else if (item.name.toLowerCase().endsWith('.bas')) {
            results.push({
                name: item.name,
                path: relPath,
                fullPath,
                isDir: false,
                size: fs.statSync(fullPath).size
            });
        }
    }
    return results;
}

// 1. Lister les fichiers des dossiers my_programs, tests, games
app.get('/api/files', (req, res) => {
    try {
        const myPrograms = {
            name: "my_programs",
            path: "qbasic_win/my_programs",
            isDir: true,
            children: getBasFiles(path.join(QBASIC_DIR, 'my_programs'), QBASIC_DIR)
        };
        const tests = {
            name: "tests",
            path: "qbasic_win/tests",
            isDir: true,
            children: getBasFiles(path.join(QBASIC_DIR, 'tests'), QBASIC_DIR)
        };
        const games = {
            name: "games",
            path: "qbasic_win/games",
            isDir: true,
            children: getBasFiles(path.join(QBASIC_DIR, 'games'), QBASIC_DIR)
        };
        res.json({ success: true, tree: [myPrograms, tests, games] });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 2. Lire le contenu d'un fichier .bas
app.get('/api/file', (req, res) => {
    const relPath = req.query.path;
    if (!relPath) return res.status(400).json({ error: "Missing path" });
    const fullPath = path.resolve(QBASIC_DIR, relPath);
    if (!fullPath.startsWith(ROOT_DIR)) {
        return res.status(403).json({ error: "Access denied" });
    }
    if (!fs.existsSync(fullPath)) {
        return res.status(404).json({ error: "File not found" });
    }
    try {
        const content = fs.readFileSync(fullPath, 'utf8');
        res.json({ success: true, path: relPath, content });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 3. Sauvegarder un fichier
app.post('/api/file', (req, res) => {
    const { path: relPath, content } = req.body;
    if (!relPath) return res.status(400).json({ error: "Missing path" });
    const fullPath = path.resolve(QBASIC_DIR, relPath);
    if (!fullPath.startsWith(ROOT_DIR)) {
        return res.status(403).json({ error: "Access denied" });
    }
    try {
        fs.mkdirSync(path.dirname(fullPath), { recursive: true });
        fs.writeFileSync(fullPath, content, 'utf8');
        res.json({ success: true, path: relPath, savedAt: new Date().toISOString() });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 4. Créer un nouveau fichier
app.post('/api/new-file', (req, res) => {
    const { folder, filename } = req.body;
    if (!filename) return res.status(400).json({ error: "Missing filename" });
    const safeName = filename.toLowerCase().endsWith('.bas') ? filename : filename + '.bas';
    const targetDir = folder ? path.resolve(QBASIC_DIR, folder) : path.join(QBASIC_DIR, 'my_programs');
    const fullPath = path.join(targetDir, safeName);
    
    if (fs.existsSync(fullPath)) {
        return res.status(409).json({ error: "File already exists" });
    }
    try {
        fs.mkdirSync(targetDir, { recursive: true });
        const defaultContent = `' ========================================================\n' ${safeName}\n' Créé dans QBasic Studio\n' ========================================================\n\nCLS\nPRINT "Bonjour depuis QBasic Studio !"\n\nEND\n`;
        fs.writeFileSync(fullPath, defaultContent, 'utf8');
        const relPath = path.relative(QBASIC_DIR, fullPath).replace(/\\/g, '/');
        res.json({ success: true, path: relPath, content: defaultContent });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 5. Supprimer un fichier
app.post('/api/delete-file', (req, res) => {
    const { path: relPath } = req.body;
    if (!relPath) return res.status(400).json({ error: "Missing path" });
    const fullPath = path.resolve(QBASIC_DIR, relPath);
    if (!fullPath.startsWith(ROOT_DIR)) return res.status(403).json({ error: "Access denied" });
    if (!fs.existsSync(fullPath)) return res.status(404).json({ error: "File not found" });
    try {
        fs.unlinkSync(fullPath);
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 6. Exécution dans une fenêtre terminal séparée ou streaming SSE
app.get('/api/run-stream', (req, res) => {
    const targetFile = req.query.file;
    const mode = req.query.mode || 'terminal'; // 'terminal' (défaut, fenêtre séparée) ou 'console' (pipe stdout)

    if (!targetFile) {
        return res.status(400).send("Paramètre file manquant");
    }

    const fullFilePath = path.resolve(QBASIC_DIR, targetFile);
    if (!fs.existsSync(fullFilePath)) {
        return res.status(404).send("Fichier source introuvable");
    }
    if (!fs.existsSync(EXE_PATH)) {
        return res.status(500).send("qbasic_win.exe introuvable");
    }

    // Tuer un ancien processus s'il tourne encore
    if (activeProcess) {
        const oldPid = activeProcess.pid;
        activeProcess = null;
        if (oldPid) {
            try { exec(`taskkill /F /T /PID ${oldPid}`); } catch (e) {}
        }
    }

    res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
    });
    activeSseRes = res;

    const sendEvent = (event, data) => {
        try {
            res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
        } catch (e) {}
    };

    const startTime = Date.now();
    const fileName = path.basename(fullFilePath);

    sendEvent('start', {
        file: targetFile,
        name: fileName,
        mode: mode,
        timestamp: new Date().toISOString()
    });

    if (mode === 'console') {
        // Mode console intégrée de repli (redirection stdout/stderr)
        const proc = spawn(EXE_PATH, ['-r', fullFilePath], {
            cwd: path.dirname(fullFilePath),
            env: { ...process.env, PYTHONIOENCODING: 'utf-8' }
        });

        activeProcess = proc;

        proc.stdout.on('data', (chunk) => {
            sendEvent('stdout', { text: chunk.toString('utf8') });
        });

        proc.stderr.on('data', (chunk) => {
            sendEvent('stderr', { text: chunk.toString('utf8') });
        });

        proc.on('close', (code) => {
            sendEvent('exit', { code, durationMs: Date.now() - startTime });
            activeProcess = null;
            activeSseRes = null;
            res.end();
        });

        proc.on('error', (err) => {
            sendEvent('error', { message: err.message });
            activeProcess = null;
            activeSseRes = null;
            res.end();
        });

        req.on('close', () => {
            if (activeProcess === proc) {
                try { proc.kill(); } catch (e) {}
                activeProcess = null;
                activeSseRes = null;
            }
        });
    } else {
        // Mode par défaut : Exécution dans une fenêtre terminal Windows séparée
        sendEvent('stdout', {
            text: `[Terminal] Lancement de "${fileName}" dans une fenêtre terminal séparée...\n` +
                  `[Terminal] Interagissez directement au clavier dans la fenêtre Windows ouverte.\n`
        });

        const proc = spawn('cmd.exe', [
            '/c', 'start', `QBasic - ${fileName}`, '/wait', 'cmd.exe', '/c', RUNNER_BAT, fullFilePath
        ]);

        activeProcess = proc;

        proc.on('close', (code) => {
            sendEvent('stdout', {
                text: `[Terminal] Fenêtre fermée (code de sortie : ${code ?? 0})\n`
            });
            sendEvent('exit', {
                code: code ?? 0,
                durationMs: Date.now() - startTime
            });
            activeProcess = null;
            activeSseRes = null;
            res.end();
        });

        proc.on('error', (err) => {
            sendEvent('error', { message: err.message });
            activeProcess = null;
            activeSseRes = null;
            res.end();
        });

        req.on('close', () => {
            if (activeProcess === proc) {
                const pid = proc.pid;
                if (pid) {
                    try { exec(`taskkill /F /T /PID ${pid}`); } catch (e) {}
                }
                activeProcess = null;
                activeSseRes = null;
            }
        });
    }
});

// 7. Envoi d'une saisie utilisateur vers le stdin du processus (INPUT)
app.post('/api/input', (req, res) => {
    const { text } = req.body;
    if (activeProcess && activeProcess.stdin && activeProcess.stdin.writable) {
        try {
            activeProcess.stdin.write((text || '') + '\n');
            res.json({ success: true });
        } catch (err) {
            res.status(500).json({ error: err.message });
        }
    } else {
        res.status(400).json({ error: "Aucun processus en cours d'attente d'entrée console" });
    }
});

// 8. Tuer le processus en cours (y compris la fenêtre terminal)
app.post('/api/kill', (req, res) => {
    if (activeProcess) {
        const pid = activeProcess.pid;
        activeProcess = null;
        if (pid) {
            exec(`taskkill /F /T /PID ${pid}`, () => {
                res.json({ success: true, message: "Fenêtre terminal et processus arrêtés" });
            });
        } else {
            res.json({ success: true, message: "Processus arrêté" });
        }
    } else {
        res.json({ success: true, message: "Aucun processus en cours" });
    }
});

// 9. Statut général
app.get('/api/status', (req, res) => {
    res.json({
        success: true,
        exeExists: fs.existsSync(EXE_PATH),
        exePath: EXE_PATH,
        qbasicDir: QBASIC_DIR,
        running: activeProcess !== null
    });
});

app.listen(PORT, () => {
    console.log(`=======================================================`);
    console.log(`    QBASIC STUDIO - IDE Professionnel pour QBasic`);
    console.log(`    Serveur démarré sur : http://localhost:${PORT}`);
    console.log(`=======================================================`);
});
