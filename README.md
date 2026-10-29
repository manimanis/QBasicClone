# QBasic Win64 — Réimplémentation native et rétro-ingénierie de MS-DOS QBasic

[![Plateforme](https://img.shields.io/badge/Plateforme-Windows%2064--bit-blue.svg)](https://microsoft.com)
[![Langage](https://img.shields.io/badge/Langage-C11%20%2F%20SDL2-orange.svg)](https://en.wikipedia.org/wiki/C11_(C_standard_revision))
[![Tests](https://img.shields.io/badge/Tests-368%2F368%20(100%25)-brightgreen.svg)](tests/test_report.html)
[![Licence](https://img.shields.io/badge/Licence-MIT-green.svg)](LICENSE)

**QBasic Win64** est un portage moderne, autonome et natif 64-bit de l'environnement légendaire **Microsoft QBasic / QuickBASIC 4.5**. 
Ce projet est issu d'une rétro-ingénierie approfondie de l'exécutable DOS 16-bit d'origine (`QBASIC.EXE`), décompressé depuis son archive PKLITE (`depklite`), désassemblé et reconstruit sous forme d'un moteur C11 performant avec rendu graphique et audio matériel via **SDL2**.

---

## Sommaire

- [Fonctionnalités principales](#-fonctionnalités-principales)
- [Architecture du projet](#-architecture-du-projet)
- [Graphismes et Audio](#-graphismes-et-audio)
- [Compatibilité DOS & Matériel](#-compatibilité-dos--matériel)
- [Compilation](#-compilation)
- [Utilisation](#-utilisation)
- [Jeux et programmes inclus](#-jeux-et-programmes-inclus)
- [Batterie de tests automatisée](#-batterie-de-tests-automatisée)

---

## 🚀 Fonctionnalités principales

- **Interpréteur QBasic complet** :
  - Typage complet : `INTEGER %`, `LONG &`, `SINGLE !`, `DOUBLE #`, `STRING $`.
  - Types définis par l'utilisateur : blocs `TYPE ... END TYPE` avec imbrication et accès aux champs (`point.x = 10`).
  - Déclarations globales : `DEFINT`, `DEFLNG`, `DEFSNG`, `DEFDBL`, `DEFSTR`.
  - Tableaux dynamiques et statiques : `DIM`, `REDIM`, `DIM SHARED`, accès multidimensionnel, `ERASE`.
  - Procédures & Portées : `SUB` et `FUNCTION` récursives avec passage par référence ou valeur, `SHARED`, `COMMON SHARED`.
  - Macros & fonctions en ligne : `DEF FN` multi-paramètres avec isolation lexicale de portée.
  - Structures de contrôle : `IF ... THEN ... ELSEIF ... ELSE ... END IF` (mono-ligne et multi-lignes), `SELECT CASE`, `FOR ... TO ... STEP ... NEXT`, `DO WHILE/UNTIL ... LOOP WHILE/UNTIL`, `WHILE ... WEND`, `GOTO`, `GOSUB ... RETURN`.
  - Gestion des erreurs : `ON ERROR GOTO`, `RESUME`, `RESUME NEXT`, variables `ERR` et `ERL`, déclenchement via `ERROR n`.
  - Données statiques : `DATA`, `READ`, `RESTORE`.

- **Système de fichiers complet** :
  - **Séquentiel** : `OPEN ... FOR INPUT / OUTPUT / APPEND AS #n`, `PRINT #n`, `WRITE #n`, `INPUT #n`, `LINE INPUT #n`, `EOF()`, `LOF()`.
  - **Aléatoire (Random Access)** : `OPEN ... FOR RANDOM AS #n LEN = reclen`, `FIELD #n, wid AS var$`, `LSET`, `RSET`, `GET #n, rec`, `PUT #n, rec`.
  - **Binaire direct** : `OPEN ... FOR BINARY AS #n`, lecture/écriture brute, `SEEK #n, pos`, `LOC()`, `LOF()`.
  - Commandes disque : `KILL`, `NAME ... AS ...`, gestion des chemins relatifs et absolus.

---

## 🎨 Graphismes et Audio

L'ensemble des modes vidéo et graphiques DOS est simulé en temps réel via **SDL2** avec palette d'origine et police bitmap CP437 :

| Mode | Résolution | Couleurs | Matériel simulé |
|:---|:---:|:---:|:---|
| `SCREEN 0` | 80x25 / 80x50 | 16 texte | Mode texte DOS couleur (clignotement, pages vidéo) |
| `SCREEN 1` | 320x200 | 4 | CGA 4 couleurs |
| `SCREEN 2` | 640x200 | 2 | CGA haute résolution |
| `SCREEN 7` | 320x200 | 16 | EGA 16 couleurs |
| `SCREEN 8` | 640x200 | 16 | EGA 16 couleurs |
| `SCREEN 9` | 640x350 | 16 | EGA haute résolution (palette personnalisable) |
| `SCREEN 11` | 640x480 | 2 | VGA monochrome |
| `SCREEN 12` | 640x480 | 16 | VGA standard 16 couleurs |
| `SCREEN 13` | 320x200 | 256 | VGA 256 couleurs (Mode 13h) |

### Primitives graphiques supportées :
- `PSET`, `PRESET`, `POINT(x, y)`
- `LINE (x1, y1)-(x2, y2), couleur, [B|BF]`
- `CIRCLE (x, y), rayon, couleur, [start, end, aspect]`
- `PAINT (x, y), couleur, [couleur_bordure]`
- `DRAW "commandes"` (système Turtle Graphics complet : `U`, `D`, `L`, `R`, `E`, `F`, `G`, `H`, `M`, `C`, `A`, `S`)
- `GET` et `PUT` graphiques avec masquage bitplane (`PSET`, `PRESET`, `AND`, `OR`, `XOR`)
- `PALETTE [attrib, couleur]`, `COLOR premier_plan, arriere_plan`, `CLS`, `LOCATE ligne, colonne`

### Synthétiseur Audio & MML :
- `PLAY "chaine_mml"` : support complet de la syntaxe Music Macro Language de Microsoft (`O`ctave, `T`empo, `L`ength, `N`ote, `MS`/`MN`/`ML`, dièses et bémols).
- `BEEP` et `SOUND frequence, duree`.

---

## 💻 Compatibilité DOS & Matériel

- **Ports matériels x86** :
  - `INP(&H3DA)` : émulation de l'oscillation du rafraîchissement vertical VGA (Vertical Retrace bit 3).
  - `INP(&H60)` : lecture des scancodes bruts du contrôleur clavier Intel 8042.
  - `OUT &H3C8, val` : écritures sur les registres de palette et ports matériels sans crash.
- **Mémoire & BIOS** :
  - `DEF SEG = segment`, `PEEK(adresse)`, `POKE adresse, valeur`.
  - Émulation de la zone de données BIOS (0040h / 0x417 pour l'état de `NumLock`, `CapsLock`, `ScrollLock`).
- **Horloge système** :
  - `TIMER` (secondes écoulées depuis minuit avec précision milliseconde).
  - `DATE$` (format `MM-DD-YYYY`) et `TIME$` (format `HH:MM:SS`).
  - `SLEEP secondes` (support des fractions de secondes en temps réel, ex: `SLEEP 0.05`).

---

## 🛠 Compilation

### Prérequis :
- **Windows 64-bit** (10 / 11)
- Environnement GCC MinGW-w64 ou MSYS2 (UCRT64 recommandé)
- Bibliothèque **SDL2** (fichiers d'inclusion et `SDL2.dll`)

### Commandes de compilation :

```powershell
# Avec MSYS2 UCRT64 dans le PATH :
cd qbasic_win
mingw32-make

# Ou directement avec gcc :
gcc -Wall -Wextra -O2 -std=c11 -IC:/msys64/ucrt64/include/SDL2 `
    main.c win_compat.c qb_types.c qb_interp.c sdl_inkey.c `
    -o qbasic_win.exe -static -lSDL2 -lm -lkernel32 -luser32 -lgdi32 `
    -lwinmm -limm32 -lole32 -loleaut32 -lversion -luuid -ladvapi32 -lshell32
```

---

## 📖 Utilisation

L'exécutable `qbasic_win.exe` est un binaire autonome en ligne de commande :

```
Usage:
  qbasic_win.exe -r <fichier.bas>     Exécuter un programme Basic
  qbasic_win.exe -c <"commande">    Exécuter une commande Basic en ligne

Switches disponibles :
  -r, --run <fichier.bas>     Chemin vers le fichier source Basic
  -c, --cmd <"commande">    Instruction QBasic entre guillemets
  -h, --help                 Afficher cette aide
```

### Exemples :

```powershell
# 1. Exécuter un calcul ou un test immédiat
.\qbasic_win.exe -c "PRINT 2^10; ' : OK' : FOR i=1 TO 5 : PRINT i; : NEXT i"

# 2. Lancer un jeu
.\qbasic_win.exe -r tests\games\gorilla.bas

# 3. Lancer Nibbles
.\qbasic_win.exe -r tests\games\nibbles.bas
```

---

## 🎮 Jeux et programmes inclus

Le dossier [`qbasic_win/tests/games`](file:///c:/xampp-school/htdocs/MesProjets/QBasic/qbasic_win/tests/games) inclut les jeux emblématiques de Microsoft et IBM, révisés pour une jouabilité parfaite sous Windows moderne :

1. **Gorillas (`GORILLA.BAS` - IBM 1991)** :
   - Graphismes EGA `SCREEN 9` (640x350, 16 couleurs).
   - Génération de gratte-ciels et calcul de physique balistique sous gravité et vent.
   - **Mode Joueur contre IA (CPU)** intégré : entrez `CPU` au nom du Joueur 2 pour jouer seul contre l'ordinateur !
   - Cadencement moderne via `SLEEP` (suppression du gel temporel de la boucle DOS `MachSpeed`).
   - Quitter à tout moment avec <kbd>Échap</kbd> ou <kbd>Q</kbd>.

2. **Nibbles (`NIBBLES.BAS` - Microsoft 1990)** :
   - Mode texte couleur `SCREEN 0` avec bordures CP437 authentiques.
   - 1 ou 2 joueurs, niveaux 1 à 9 avec vitesse paramétrable.
   - Contrôles réactifs sans saturation du buffer clavier.

3. **Jeux de réflexion et arcade** :
   - `TETRIS.BAS` & `TETRIS_AI.BAS` (moteur Tetris autonome jouant à l'aide d'une IA).
   - `CONX4.BAS` (Puissance 4 complet avec IA Minimax).
   - `TICTAC.BAS` (Morpion interactif).
   - `RBTRIVIA.BAS` (Jeu de quiz et culture générale).

---

## 🧪 Batterie de tests automatisée

Le projet intègre une suite d'intégration continue complète exécutée par Node.js :

```powershell
node tests/run_all_tests.js
```

### Bilan global des tests :
- **30 suites de tests unitaires du noyau** (344 assertions validées) :
  - Mathématiques, chaînes de caractères, types et tableaux, structures de contrôle, procédures, I/O fichiers, émulation matérielle, graphismes, cryptographie, tri, physique, etc.
- **21 programmes réels QBasic du patrimoine** (`FIBONUM`, `PRIME1`, `BWDATE`, `BUBBLE`, `SHELL`, `SONG`, `TETRIS`, etc.).
- **3 jeux complets en conditions réelles** (`DEMO.BAS`, `GORILLA.BAS`, `NIBBLES.BAS`).
- **Résultat : 368 / 368 vérifications réussies (100.0% de succès, 0 échec)**.
- Des rapports détaillés [JSON](file:///c:/xampp-school/htdocs/MesProjets/QBasic/qbasic_win/tests/test_results.json) et [HTML interactif](file:///c:/xampp-school/htdocs/MesProjets/QBasic/qbasic_win/tests/test_report.html) sont automatiquement générés.

---

## 📚 Documentation & Aide QBasic Décompilée (QBASIC.HLP)

Le fichier d'aide original MS-DOS **`QBASIC.HLP`** a été intégralement décompilé sous la forme d'un **site web moderne et autonome** :

- **Accès direct hors-ligne** : Double-cliquez sur [`open_help.bat`](file:///c:/xampp-school/htdocs/MesProjets/QBasic/open_help.bat) ou ouvrez [`qbasic_hlp/index.html`](file:///c:/xampp-school/htdocs/MesProjets/QBasic/qbasic_hlp/index.html).
- **Intégration QBasic Studio** : Bouton `❓ Aide (F1)` dans la barre d'outils, ou touche `F1` sur n'importe quel mot-clé dans Monaco Editor.
- **366 rubriques & 517 contextes** : Guide de survie, sommaire, index A-Z, 11 catégories de programmation, tables ASCII/ScanCodes/erreurs.
- **3 Thèmes** : Rétro MS-DOS (Bleu QBasic `#0000a8`), Dark Studio moderne et Clair Documentation.
- **Moteur de recherche instantané** plein texte avec surbrillance (`Ctrl+K` ou `/`).
- **Bouton Copier** sur tous les exemples de code.

---

## 📂 Structure du dépôt

```
QBasic/
├── QBASIC.EXE               # Exécutable MS-DOS 16-bit d'origine
├── QBASIC.HLP               # Fichier d'aide QuickHelp binaire officiel
├── open_help.bat            # Lanceur en un clic du site web d'aide
├── qbasic_hlp/              # Site web d'aide QBasic complet décompilé
│   ├── index.html           # Portail SPA d'aide interactif avec recherche & thèmes
│   ├── app.js               # Moteur de navigation, recherche plein texte et hash router
│   ├── style.css            # Feuilles de style (Rétro DOS, Sombre, Clair)
│   ├── topics.js / .json    # 366 rubriques avec HTML et texte intégral
│   ├── contexts.js / .json  # 517 contextes et mots-clés indexés
│   ├── navigation.js / .json# Sommaire, index A-Z et 11 catégories thématiques
│   └── T0000.html..T016D.html # 366 pages HTML individuelles stylisées
├── qbasic_studio/           # IDE QBasic professionnel basé sur Monaco Editor
├── qbasic_win/              # Interpréteur natif Windows 64-bit (SDL2/C11)
├── utils/                   # Outils de décompilation et rétro-ingénierie
│   └── helpconvert.exe      # Décompilateur Microsoft QuickHelp (.HLP -> HTML/JSON)
├── README.md                # Documentation générale
└── ...
```

---

## 📜 Licence

Ce projet est sous licence MIT. Le code d'origine de Gorilla et Nibbles est Copyright (C) 1990-1991 Microsoft Corporation / IBM Corporation.
