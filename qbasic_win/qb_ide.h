#ifndef QB_IDE_H
#define QB_IDE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Démarre l'environnement de développement intégré (IDE) QBasic en mode plein écran TUI
// initial_file peut être NULL ou le chemin d'un fichier .bas à ouvrir
int qb_ide_start(const char *initial_file);

#ifdef __cplusplus
}
#endif

#endif // QB_IDE_H
