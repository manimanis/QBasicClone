# QBasic Studio - IDE Professionnel pour QBasic

**QBasic Studio** est un environnement de développement intégré (IDE) moderne et complet conçu spécifiquement pour l'interpréteur `qbasic_win.exe`.

Propulsé par **Monaco Editor** (le moteur officiel de Visual Studio Code), il offre une expérience de développement de niveau professionnel tout en restant 100% hors-ligne.

---

## Fonctionnalités Principales

### 1. Éditeur de Code Moderne & Puissant (Monaco Editor)
- **Coloration syntaxique complète** pour QBasic (mots-clés, fonctions intégrées, chaînes, commentaires `'` et `REM`, nombres hexadécimaux `&H...` et octaux `&O...`, labels de ligne, types de variables `$`, `%`, `&`, `!`, `#`).
- **Autocomplétion intelligente (IntelliSense)** :
  - Complétion automatique en direct de tous les mots-clés et fonctions QBasic avec description et signature.
  - Détection dynamique des variables, `SUB` et `FUNCTION` définies dans votre programme.
  - Snippets de code prêts à l'emploi (`sub`, `function`, `for`, `if`, `ifelse`, `select`, `type`, `screen12`, `file_read`, `file_write`).
- **Documentation au survol (Hover Tooltips)** :
  - Survolez n'importe quel mot-clé ou fonction (`MID$`, `PRINT`, `RND`, `SCREEN`, `PAINT`, `CIRCLE`, `LINE`, `PLAY`, etc.) pour afficher sa documentation complète, sa syntaxe et ses options.
- **Support complet d'Unicode / UTF-8 par défaut** :
  - Rédigez vos programmes et chaînes de texte avec tous les caractères accentués français, espagnols, symboles (`€`, `★`, `✓`, etc.).

### 2. Double Thème Graphique
- **Thème Sombre Moderne (Dark Pro)** : Interface verre fumé et palette équilibrée inspirée de VS Code One Dark.
- **Thème Rétro MS-DOS QBasic** : Le bleu royal classique (`#0000AA`), texte blanc éclatant et mots-clés jaunes pour une expérience nostalgique authentique.
- Basculement instantané via le bouton **🎨 Thème**.

### 3. Exécution dans une Fenêtre Terminal Séparée (F5)
- **Bouton ▶ Exécuter (F5)** : Sauvegarde automatiquement le fichier en cours et lance l'exécution dans une **fenêtre terminal Windows dédiée et séparée** (`cmd.exe`).
- **Support natif des saisies interactives (`INPUT`, `LINE INPUT`, `INKEY$`)** : L'utilisateur interagit directement au clavier dans le terminal avec gestion des flèches, effacement et encodage UTF-8 Unicode complet.
- **Préservation des sorties** : Lorsque le programme prend fin, le terminal affiche le code de statut et attend l'appui sur une touche avant de se fermer, garantissant que tous les `PRINT` restent lisibles.
- **Bouton ⏹ Arrêter (Maj+F5)** : Permet d'interrompre et fermer instantanément la fenêtre terminal depuis l'IDE en cas de boucle infinie.

### 4. Gestion de Projet & Fichiers
- Explorateur de fichiers à gauche scannant automatiquement :
  - `my_programs/` (vos programmes personnels)
  - `tests/` (suites de tests et benchmarks)
  - `games/` (jeux vintage : Gorillas, Nibbles, etc.)
- Gestion par onglets multiples avec indicateur de modifications non enregistrées (`*`).
- Création de nouveaux fichiers en un clic.

---

## Démarrage Rapide

Double-cliquez simplement sur :
- **[`QBasicStudio.bat`](file:///c:/xampp-school/htdocs/MesProjets/QBasic/QBasicStudio.bat)** (à la racine du projet)
ou
- **[`qbasic_studio.bat`](file:///c:/xampp-school/htdocs/MesProjets/QBasic/qbasic_studio/qbasic_studio.bat)** (dans le dossier `qbasic_studio`)

Le studio démarre le serveur local et s'ouvre automatiquement sous forme d'**application native de bureau sans bordure navigateur**.
