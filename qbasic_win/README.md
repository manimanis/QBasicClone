# QBasic Win64 — Interpréteur natif Windows & SDL2

Pour la documentation complète et l'historique du projet de rétro-ingénierie, consultez le [README principal du dépôt](../README.md).

---

## Démarrage rapide

### Compilation
```powershell
mingw32-make
```

### Lancer un jeu
```powershell
# Lancer Gorillas (tapez 'CPU' au Joueur 2 pour jouer contre l'ordinateur) :
.\qbasic_win.exe -r tests\games\gorilla.bas

# Lancer Nibbles :
.\qbasic_win.exe -r tests\games\nibbles.bas
```

### Exécuter les tests (100% pass)
```powershell
node tests\run_all_tests.js
```
