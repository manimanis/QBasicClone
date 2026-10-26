#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "win_compat.h"
#include "qb_interp.h"

static void print_usage(const char *prog_name) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "  %s -r <fichier.bas>     Exécuter un programme Basic\n", prog_name);
    fprintf(stderr, "  %s -c <\"commande\">    Exécuter une commande Basic en ligne\n", prog_name);
    fprintf(stderr, "\nSwitches obligatoires :\n");
    fprintf(stderr, "  -r, --run <fichier.bas>     Chemin vers le fichier source Basic\n");
    fprintf(stderr, "  -c, --cmd <\"commande\">    Instruction QBasic entre guillemets\n");
    fprintf(stderr, "  -h, --help                 Afficher cette aide\n");
}

int main(int argc, char *argv[]) {
    qb_compat_init();

    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    const char *target_file = NULL;
    const char *inline_cmd = NULL;

    for (int i = 1; i < argc; i++) {
        if (argv[i][0] != '-' && argv[i][0] != '/') {
            fprintf(stderr, "Erreur: Argument inattendu '%s' sans switch.\n\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        }

        if (strcasecmp(argv[i], "-r") == 0 || strcasecmp(argv[i], "--run") == 0 ||
            strcasecmp(argv[i], "/r") == 0 || strcasecmp(argv[i], "/run") == 0) {
            if (i + 1 >= argc || argv[i + 1][0] == '-' || argv[i + 1][0] == '/') {
                fprintf(stderr, "Erreur: L'option '%s' nécessite le chemin d'un fichier Basic.\n\n", argv[i]);
                print_usage(argv[0]);
                return 1;
            }
            target_file = argv[++i];
        } else if (strcasecmp(argv[i], "-c") == 0 || strcasecmp(argv[i], "--cmd") == 0 ||
                   strcasecmp(argv[i], "/c") == 0 || strcasecmp(argv[i], "/cmd") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Erreur: L'option '%s' nécessite une commande Basic entre guillemets.\n\n", argv[i]);
                print_usage(argv[0]);
                return 1;
            }
            inline_cmd = argv[++i];
        } else if (strcasecmp(argv[i], "-h") == 0 || strcasecmp(argv[i], "--help") == 0 ||
                   strcasecmp(argv[i], "/h") == 0 || strcasecmp(argv[i], "/?") == 0) {
            print_usage(argv[0]);
            return 0;
        } else {
            fprintf(stderr, "Erreur: Switch inconnu '%s'.\n\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        }
    }

    // 1. Exécution d'une commande passée via le switch -c
    if (inline_cmd) {
        QB_Program *prog = qb_program_create();
        QB_Interpreter *interp = qb_interp_create(prog);
        qb_interp_exec_immediate(interp, inline_cmd);
        qb_interp_free(interp);
        qb_program_free(prog);
        return 0;
    }

    // 2. Exécution d'un programme Basic passé via le switch -r
    if (target_file) {
        QB_Program *prog = qb_program_create();
        if (!qb_program_load_file(prog, target_file)) {
            fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier QBasic '%s'\n", target_file);
            qb_program_free(prog);
            return 1;
        }
        QB_Interpreter *interp = qb_interp_create(prog);
        qb_interp_run(interp);
        qb_interp_free(interp);
        qb_program_free(prog);
        return 0;
    }

    print_usage(argv[0]);
    return 1;
}
