// app.js - Logique cliente de QBasic Studio
(function() {
    let editor = null;
    let openTabs = []; // { path, name, model, isDirty }
    let activeTabPath = null;
    let eventSource = null;
    let currentTheme = 'qbasic-dark';

    // 1. Initialisation de Monaco Editor
    function initMonaco() {
        require.config({ paths: { vs: '/vs' } });

        require(['vs/editor/editor.main'], function() {
            // Enregistrement du langage QBasic
            monaco.languages.register({
                id: 'qbasic',
                extensions: ['.bas'],
                aliases: ['QBasic', 'QuickBASIC', 'basic']
            });

            // Tokenizer Monarch & Configuration
            monaco.languages.setMonarchTokensProvider('qbasic', window.qbasicLanguageDefinition);
            monaco.languages.setLanguageConfiguration('qbasic', window.qbasicLanguageConfiguration);

            // Thème Moderne Sombre (Pro Dark)
            monaco.editor.defineTheme('qbasic-dark', {
                base: 'vs-dark',
                inherit: true,
                rules: [
                    { token: 'keyword', foreground: 'e5c07b', fontStyle: 'bold' },
                    { token: 'keyword.control', foreground: 'c678dd', fontStyle: 'bold' },
                    { token: 'support.function', foreground: '61afef' },
                    { token: 'string', foreground: '98c379' },
                    { token: 'comment', foreground: '5c6370', fontStyle: 'italic' },
                    { token: 'number', foreground: 'd19a66' },
                    { token: 'number.hex', foreground: 'd19a66', fontStyle: 'bold' },
                    { token: 'operator', foreground: '56b6c2' },
                    { token: 'identifier', foreground: 'abb2bf' },
                    { token: 'type', foreground: 'e06c75' }
                ],
                colors: {
                    'editor.background': '#1b1b22',
                    'editor.foreground': '#f3f4f6',
                    'editorLineNumber.foreground': '#4b5563',
                    'editorLineNumber.activeForeground': '#93c5fd',
                    'editorCursor.foreground': '#60a5fa',
                    'editor.selectionBackground': '#3b82f640'
                }
            });

            // Thème Rétro MS-DOS QBasic Authentique (Bleu royal classique)
            monaco.editor.defineTheme('qbasic-retro', {
                base: 'vs-dark',
                inherit: false,
                rules: [
                    { token: 'keyword', foreground: 'ffff55', fontStyle: 'bold' },
                    { token: 'keyword.control', foreground: 'ffff55', fontStyle: 'bold' },
                    { token: 'support.function', foreground: '55ffff' },
                    { token: 'string', foreground: '55ff55' },
                    { token: 'comment', foreground: '55ffff', fontStyle: 'italic' },
                    { token: 'number', foreground: 'ff55ff' },
                    { token: 'operator', foreground: 'ffffff' },
                    { token: 'identifier', foreground: 'ffffff' },
                    { token: 'type', foreground: '00ffaa' }
                ],
                colors: {
                    'editor.background': '#0000aa',
                    'editor.foreground': '#ffffff',
                    'editorLineNumber.foreground': '#5555ff',
                    'editorLineNumber.activeForeground': '#ffffff',
                    'editorCursor.foreground': '#ffffff',
                    'editor.selectionBackground': '#ffffff40'
                }
            });

            // Fournisseurs d'IntelliSense & d'infobulles
            if (window.registerQBasicProviders) {
                window.registerQBasicProviders(monaco);
            }

            // Création de l'instance de l'éditeur
            editor = monaco.editor.create(document.getElementById('monaco-container'), {
                theme: currentTheme,
                fontFamily: "'Cascadia Code', 'Fira Code', Consolas, 'Courier New', monospace",
                fontSize: 14,
                lineHeight: 22,
                automaticLayout: true,
                minimap: { enabled: true },
                scrollBeyondLastLine: false,
                renderWhitespace: 'selection',
                tabSize: 4,
                detectIndentation: false,
                insertSpaces: true
            });

            // Mise à jour de la position du curseur dans la barre de statut
            editor.onDidChangeCursorPosition(e => {
                const pos = e.position;
                document.getElementById('cursor-pos').textContent = `Ln ${pos.lineNumber}, Col ${pos.column}`;
            });

            // Détection des modifications pour marquer l'onglet dirty
            editor.onDidChangeModelContent(() => {
                const tab = openTabs.find(t => t.path === activeTabPath);
                if (tab && !tab.isDirty) {
                    tab.isDirty = true;
                    renderTabs();
                }
            });

            // Raccourcis clavier globaux dans Monaco
            editor.addCommand(monaco.KeyCode.F5, () => runCurrentProgram());
            editor.addCommand(monaco.KeyMod.Shift | monaco.KeyCode.F5, () => stopExecution());
            editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, () => saveCurrentFile());

            // Charger l'arborescence des fichiers et ouvrir le fichier initial
            loadFiles();
        });
    }

    // 2. Gestion des Fichiers et de l'Explorateur
    async function loadFiles() {
        try {
            const res = await fetch('/api/files');
            const data = await res.json();
            if (data.success) {
                renderFileTree(data.tree);
                // Ouvrir my_programs/test05.bas par défaut s'il existe
                if (openTabs.length === 0) {
                    openFile('my_programs/test05.bas');
                }
            }
        } catch (err) {
            console.error("Erreur de chargement des fichiers :", err);
        }
    }

    function renderFileTree(tree) {
        const container = document.getElementById('file-tree');
        container.innerHTML = '';

        function renderNode(node, depth = 0) {
            const el = document.createElement('div');
            if (node.isDir) {
                el.className = 'tree-folder';
                const title = document.createElement('div');
                title.className = 'folder-title';
                title.style.paddingLeft = (10 + depth * 12) + 'px';
                title.innerHTML = `<span>📁</span> <span>${node.name}</span>`;
                el.appendChild(title);

                const childrenEl = document.createElement('div');
                childrenEl.className = 'folder-children';
                if (node.children) {
                    node.children.forEach(child => {
                        childrenEl.appendChild(renderNode(child, depth + 1));
                    });
                }
                el.appendChild(childrenEl);

                title.onclick = () => {
                    const isHidden = childrenEl.style.display === 'none';
                    childrenEl.style.display = isHidden ? 'block' : 'none';
                    title.querySelector('span').textContent = isHidden ? '📁' : '📂';
                };
            } else {
                el.className = 'tree-item' + (activeTabPath === node.path ? ' active' : '');
                el.style.paddingLeft = (20 + depth * 12) + 'px';
                el.innerHTML = `<span>📜</span> <span>${node.name}</span>`;
                el.onclick = () => openFile(node.path);
            }
            return el;
        }

        tree.forEach(folder => {
            container.appendChild(renderNode(folder, 0));
        });
    }

    async function openFile(relPath) {
        // Vérifier si l'onglet est déjà ouvert
        const existing = openTabs.find(t => t.path === relPath);
        if (existing) {
            setActiveTab(relPath);
            return;
        }

        try {
            const res = await fetch(`/api/file?path=${encodeURIComponent(relPath)}`);
            const data = await res.json();
            if (data.success) {
                const model = monaco.editor.createModel(data.content, 'qbasic', monaco.Uri.parse(`file:///${relPath}`));
                openTabs.push({
                    path: relPath,
                    name: relPath.split('/').pop(),
                    model: model,
                    isDirty: false
                });
                setActiveTab(relPath);
            }
        } catch (err) {
            appendConsole(`Erreur d'ouverture du fichier ${relPath} : ${err.message}`, 'stderr');
        }
    }

    function setActiveTab(relPath) {
        activeTabPath = relPath;
        const tab = openTabs.find(t => t.path === relPath);
        if (tab && editor) {
            editor.setModel(tab.model);
            editor.focus();
        }
        renderTabs();
        highlightActiveInTree();
    }

    function renderTabs() {
        const container = document.getElementById('tabs-bar');
        container.innerHTML = '';

        openTabs.forEach(tab => {
            const el = document.createElement('div');
            el.className = 'tab' + (tab.path === activeTabPath ? ' active' : '');
            
            const titleSpan = document.createElement('span');
            titleSpan.textContent = tab.name;
            el.appendChild(titleSpan);

            if (tab.isDirty) {
                const dirtySpan = document.createElement('span');
                dirtySpan.className = 'tab-dirty';
                el.appendChild(dirtySpan);
            }

            const closeSpan = document.createElement('span');
            closeSpan.className = 'tab-close';
            closeSpan.textContent = '×';
            closeSpan.title = 'Fermer l\'onglet';
            closeSpan.onclick = (e) => {
                e.stopPropagation();
                closeTab(tab.path);
            };
            el.appendChild(closeSpan);

            el.onclick = () => setActiveTab(tab.path);
            container.appendChild(el);
        });
    }

    function closeTab(relPath) {
        const index = openTabs.findIndex(t => t.path === relPath);
        if (index === -1) return;
        const tab = openTabs[index];
        tab.model.dispose();
        openTabs.splice(index, 1);

        if (activeTabPath === relPath) {
            if (openTabs.length > 0) {
                const nextTab = openTabs[Math.max(0, index - 1)];
                setActiveTab(nextTab.path);
            } else {
                activeTabPath = null;
                editor.setModel(null);
                renderTabs();
            }
        } else {
            renderTabs();
        }
    }

    function highlightActiveInTree() {
        document.querySelectorAll('.tree-item').forEach(el => {
            el.classList.remove('active');
            if (el.textContent.includes(activeTabPath ? activeTabPath.split('/').pop() : '')) {
                el.classList.add('active');
            }
        });
    }

    async function saveCurrentFile() {
        const tab = openTabs.find(t => t.path === activeTabPath);
        if (!tab) return;
        const content = tab.model.getValue();

        try {
            const res = await fetch('/api/file', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path: tab.path, content })
            });
            const data = await res.json();
            if (data.success) {
                tab.isDirty = false;
                renderTabs();
                appendConsole(`[Sauvegardé] ${tab.path} (${new Date().toLocaleTimeString()})`, 'system');
            }
        } catch (err) {
            appendConsole(`Erreur d'enregistrement : ${err.message}`, 'stderr');
        }
    }

    // 3. Exécution QBasic (Fenêtre terminal dédiée & Streaming SSE)
    async function runCurrentProgram() {
        if (!activeTabPath) {
            appendConsole("Aucun fichier sélectionné pour exécution.", 'stderr');
            return;
        }

        // Sauvegarder d'abord si modifié
        const tab = openTabs.find(t => t.path === activeTabPath);
        if (tab && tab.isDirty) {
            await saveCurrentFile();
        }

        stopExecution(); // Arrêter toute exécution précédente

        clearConsole();
        setProcessStatus('Terminal actif...', true);
        appendConsole(`=== Lancement de ${activeTabPath} dans une fenêtre terminal séparée ===\n`, 'system');

        const inputBar = document.getElementById('console-input');
        inputBar.disabled = true;
        inputBar.placeholder = "L'interaction (INPUT, etc.) s'effectue directement dans la fenêtre terminal Windows...";

        const sseUrl = `/api/run-stream?file=${encodeURIComponent(activeTabPath)}&mode=terminal`;
        eventSource = new EventSource(sseUrl);

        eventSource.addEventListener('start', e => {
            const data = JSON.parse(e.data);
            appendConsole(`[Info] Fenêtre terminal ouverte pour : ${data.name || data.file}\n`, 'system');
        });

        eventSource.addEventListener('stdout', e => {
            const data = JSON.parse(e.data);
            appendConsole(data.text, 'stdout');
        });

        eventSource.addEventListener('stderr', e => {
            const data = JSON.parse(e.data);
            appendConsole(data.text, 'stderr');
        });

        eventSource.addEventListener('exit', e => {
            const data = JSON.parse(e.data);
            appendConsole(`\n[Processus terminé dans le terminal - Code ${data.code}]`, data.code === 0 ? 'success' : 'stderr');
            stopExecution();
        });

        eventSource.addEventListener('error', e => {
            stopExecution();
        });
    }

    function stopExecution() {
        if (eventSource) {
            eventSource.close();
            eventSource = null;
        }
        fetch('/api/kill', { method: 'POST' }).catch(() => {});
        setProcessStatus('Prêt', false);
        const inputBar = document.getElementById('console-input');
        inputBar.disabled = true;
        inputBar.placeholder = "Les entrées (INPUT) s'effectuent directement dans la fenêtre terminal séparée.";
        inputBar.value = '';
    }

    function setProcessStatus(text, isRunning) {
        document.getElementById('proc-status').textContent = text;
        const ind = document.getElementById('status-indicator');
        const btnRun = document.getElementById('btn-run');
        const btnStop = document.getElementById('btn-stop');

        if (isRunning) {
            ind.className = 'status-indicator busy';
            btnRun.disabled = true;
            btnStop.disabled = false;
        } else {
            ind.className = 'status-indicator stopped';
            btnRun.disabled = false;
            btnStop.disabled = true;
        }
    }

    function appendConsole(text, type = 'stdout') {
        const out = document.getElementById('console-output');
        const span = document.createElement('span');
        span.className = `log-${type}`;
        span.textContent = text;
        out.appendChild(span);
        out.scrollTop = out.scrollHeight;
    }

    function clearConsole() {
        document.getElementById('console-output').innerHTML = '';
    }

    // Envoi de données vers INPUT du programme
    async function sendConsoleInput() {
        const inputEl = document.getElementById('console-input');
        const val = inputEl.value;
        appendConsole(val + '\n', 'system');
        inputEl.value = '';

        try {
            await fetch('/api/input', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text: val })
            });
        } catch (err) {
            console.error("Erreur envoi input :", err);
        }
    }

    // 4. Modal Nouveau Fichier
    function showNewFileModal() {
        const modal = document.getElementById('new-file-modal');
        const input = document.getElementById('new-filename-input');
        input.value = 'programme_' + Math.floor(Math.random() * 1000) + '.bas';
        modal.style.display = 'flex';
        input.focus();
        input.select();
    }

    function hideNewFileModal() {
        document.getElementById('new-file-modal').style.display = 'none';
    }

    async function createNewFile() {
        const input = document.getElementById('new-filename-input');
        const name = input.value.trim();
        if (!name) return;

        try {
            const res = await fetch('/api/new-file', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ folder: 'my_programs', filename: name })
            });
            const data = await res.json();
            if (data.success) {
                hideNewFileModal();
                await loadFiles();
                openFile(data.path);
            } else {
                alert(data.error);
            }
        } catch (err) {
            alert("Erreur création : " + err.message);
        }
    }

    // 5. Thème et Retaillage
    function toggleTheme() {
        const isRetro = document.body.classList.toggle('theme-qbasic-retro');
        currentTheme = isRetro ? 'qbasic-retro' : 'qbasic-dark';
        if (editor) {
            monaco.editor.setTheme(currentTheme);
        }
    }

    // 6. Attachement des Événements du DOM
    document.getElementById('btn-run').onclick = runCurrentProgram;
    document.getElementById('btn-stop').onclick = stopExecution;
    document.getElementById('btn-save').onclick = saveCurrentFile;
    document.getElementById('btn-new').onclick = showNewFileModal;
    document.getElementById('btn-new-in-folder').onclick = showNewFileModal;
    document.getElementById('btn-refresh-files').onclick = loadFiles;
    document.getElementById('btn-clear-console').onclick = clearConsole;
    document.getElementById('btn-theme').onclick = toggleTheme;

    document.getElementById('btn-cancel-modal').onclick = hideNewFileModal;
    document.getElementById('btn-create-modal').onclick = createNewFile;
    document.getElementById('new-filename-input').onkeydown = e => {
        if (e.key === 'Enter') createNewFile();
        if (e.key === 'Escape') hideNewFileModal();
    };

    document.getElementById('console-input').onkeydown = e => {
        if (e.key === 'Enter') sendConsoleInput();
    };

    // Raccourcis clavier globaux de la fenêtre
    window.addEventListener('keydown', e => {
        if (e.key === 'F5' && !e.shiftKey) {
            e.preventDefault();
            runCurrentProgram();
        } else if (e.key === 'F5' && e.shiftKey) {
            e.preventDefault();
            stopExecution();
        } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
            e.preventDefault();
            saveCurrentFile();
        } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'n') {
            e.preventDefault();
            showNewFileModal();
        }
    });

    // Démarrage
    window.onload = initMonaco;
})();
