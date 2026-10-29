# Documentation & Aide QBasic (QBASIC.HLP Décompilé)

Ce dossier contient la décompilation intégrale du fichier d'aide officiel de Microsoft QuickHelp **`QBASIC.HLP`** (MS-DOS QBasic 1.1) sous la forme d'un **site web moderne, interactif, 100% hors-ligne et autonome**.

---

## 🚀 Comment l'utiliser

### 1. En local (sans aucun serveur web)
Double-cliquez simplement sur :
- **[`open_help.bat`](file:///c:/xampp-school/htdocs/MesProjets/QBasic/open_help.bat)** à la racine du projet
ou
- **[`index.html`](file:///c:/xampp-school/htdocs/MesProjets/QBasic/qbasic_hlp/index.html)** dans le dossier `qbasic_hlp`

Le site fonctionne immédiatement dans n'importe quel navigateur (Chrome, Firefox, Edge, Safari, Brave...) sans configuration ni restriction CORS.

### 2. Depuis QBasic Studio (IDE Web Monaco)
- Cliquez sur le bouton **❓ Aide (F1)** dans la barre d'outils supérieure de QBasic Studio.
- Ou placez votre curseur sur n'importe quel mot-clé (`PRINT`, `CIRCLE`, `MID$`, `SCREEN`, `PAINT`...) et appuyez sur **`F1`** : l'aide s'ouvre directement sur la page de documentation de ce mot-clé !

### 3. Via un serveur local (Apache / XAMPP / Node.js)
- **Node.js (QBasic Studio)** : `http://localhost:3000/help/`
- **Apache (XAMPP)** : `http://localhost/MesProjets/QBasic/qbasic_hlp/`

---

## ✨ Fonctionnalités du Site Web

1. **366 Sujets Complets & 517 Contextes Indexés** :
   - Guide de survie, utilisation de l'aide, sommaire, index A-Z complet.
   - Toutes les instructions, fonctions, opérateurs et métacommandes du BASIC.
   - Tables de référence : Codes ASCII (0-255), Scan Codes clavier, Codes d'erreur d'exécution.
2. **Navigation Structurée en Onglets** :
   - 📑 **Sommaire** : Vue hiérarchique officielle (Orientation, Raccourcis, Environnement, Tables de référence).
   - 🔤 **Index Alphabétique (A-Z)** : Filtres rapides par lettre (`[A] [B] [C]...`) et badges visuels colorés (*Statement*, *Function*, *Operator*, *Metacommand*, *Keyword*).
   - 📂 **Catégories par Tâche** : 11 catégories thématiques (Graphismes, Chaînes, Fichiers, Mathématiques, E/S écran/clavier, Contrôle de flux, Mémoire, Événements & Erreurs, Son & Musique...).
   - 🔍 **Moteur de Recherche Instantané** : Recherche instantanée plein texte et mots-clés avec surbrillance (`Ctrl+K` ou `/`).
3. **Triple Thème Graphique** :
   - 🎮 **MS-DOS QBasic Rétro (Défaut)** : Le bleu royal classique (`#0000a8`), texte blanc/jaune et bordures cyan de l'IDE d'origine.
   - 🌙 **Dark Studio** : Thème moderne sombre contrasté inspiré de VS Code.
   - ☀️ **Clair Documentation** : Thème épuré style manuel papier.
4. **Productivité & Accessibilité** :
   - **Copier le code** : Bouton 1-clic pour copier les blocs d'exemples de code dans le presse-papier.
   - **Historique fluide (SPA)** : Navigation Précédent/Suivant sans rechargement de page tout en conservant l'historique de l'URL (`#T004E`, `#CIRCLE`, `#PRINT`).
   - **Taille de texte ajustable** (`A-` / `A+`).
   - **Fichiers HTML autonomes** : Chaque fichier `T00xx.html` peut également être ouvert individuellement avec sa barre de retour intégrée.

---

## 🛠 Outils de Décompilation Inclus

- **`utils/helpconvert.exe`** : Utilitaire natif Windows compilé pour décompiler n'importe quel fichier Microsoft QuickHelp (`.HLP`) en HTML + JSON (compatible avec `HELP.HLP`, `MEMMAKER.HLP`, etc.).
- **`generate_portal.js`** : Script Node.js générant les métadonnées de navigation, l'indexation par catégories et l'intégration universelle.

