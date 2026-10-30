#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "win_compat.h"
#include "qb_interp.h"
#include "qb_compiler.h"

static void print_usage(const char *prog_name) {
    fprintf(stderr, "===============================================================\n");
    fprintf(stderr, " QBasic for Windows - Interpreteur & Compilateur autonome Win64\n");
    fprintf(stderr, "===============================================================\n\n");
    fprintf(stderr, "Mode Interpreteur :\n");
    fprintf(stderr, "  %s -r <source.bas> [args...]       Executer un fichier Basic\n", prog_name);
    fprintf(stderr, "  %s <source.bas> [args...]          Executer directement un fichier Basic\n", prog_name);
    fprintf(stderr, "  %s -c <\"commande\"> [args...]       Executer une instruction Basic en ligne\n", prog_name);
    fprintf(stderr, "\nMode Compilateur (.EXE autonome) :\n");
    fprintf(stderr, "  %s -b <source.bas> [-o sortie.exe] Compiler en executable autonome .EXE\n", prog_name);
    fprintf(stderr, "  %s --make <source.bas>             Alias de compilation (syntaxe QuickBasic)\n", prog_name);
    fprintf(stderr, "  %s -b <source.bas> --c [-o code.c] Exporter le code source C intermediaire\n", prog_name);
    fprintf(stderr, "  %s -b <source.bas> --native        Compilation native via GCC (si installe)\n", prog_name);
    fprintf(stderr, "\nOptions generales :\n");
    fprintf(stderr, "  -o, --output <fichier>             Chemin du fichier genere\n");
    fprintf(stderr, "  -v, --verbose                      Mode verbeux / diagnostics detailles\n");
    fprintf(stderr, "  -h, --help                         Afficher cette aide\n\n");
}

int main(int argc, char *argv[]) {
    // 1. Decodage UTF-8 complet de la ligne de commande Windows
    int wargc = 0;
    LPWSTR *wargv = CommandLineToArgvW(GetCommandLineW(), &wargc);
    if (wargv && wargc > 0) {
        char **utf8_argv = (char**)calloc(wargc, sizeof(char*));
        for (int i = 0; i < wargc; i++) {
            int ulen = WideCharToMultiByte(CP_UTF8, 0, wargv[i], -1, NULL, 0, NULL, NULL);
            if (ulen > 0) {
                utf8_argv[i] = (char*)malloc(ulen);
                WideCharToMultiByte(CP_UTF8, 0, wargv[i], -1, utf8_argv[i], ulen, NULL, NULL);
            } else {
                utf8_argv[i] = strdup("");
            }
        }
        argc = wargc;
        argv = utf8_argv;
    }

    // 2. Verification si cet executable est un binaire autonome avec code encapsule
    if (qb_check_embedded_executable(argc, argv)) {
        return 0;
    }

    qb_compat_init();

    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    const char *target_file = NULL;
    const char *inline_cmd = NULL;
    const char *output_file = NULL;
    bool compile_mode = false;
    bool emit_c = false;
    bool native_mode = false;
    bool verbose = false;

    char extra_args[4096] = {0};
    size_t extra_cur = 0;

    for (int i = 1; i < argc; i++) {
        // Switches de compilation
        if (strcasecmp(argv[i], "-b") == 0 || strcasecmp(argv[i], "--build") == 0 ||
            strcasecmp(argv[i], "/b") == 0 || strcasecmp(argv[i], "/build") == 0 ||
            strcasecmp(argv[i], "-m") == 0 || strcasecmp(argv[i], "--make") == 0 ||
            strcasecmp(argv[i], "/m") == 0 || strcasecmp(argv[i], "/make") == 0 ||
            strcasecmp(argv[i], "-compile") == 0 || strcasecmp(argv[i], "--compile") == 0) {
            compile_mode = true;
            if (i + 1 < argc && argv[i + 1][0] != '-' && argv[i + 1][0] != '/') {
                target_file = argv[++i];
            }
        } else if (strcasecmp(argv[i], "-o") == 0 || strcasecmp(argv[i], "--output") == 0 ||
                   strcasecmp(argv[i], "/o") == 0 || strcasecmp(argv[i], "/output") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Erreur: L'option '%s' necessite un nom de fichier.\n\n", argv[i]);
                print_usage(argv[0]);
                return 1;
            }
            output_file = argv[++i];
        } else if (strcasecmp(argv[i], "--c") == 0 || strcasecmp(argv[i], "--emit-c") == 0 ||
                   strcasecmp(argv[i], "-c-src") == 0 || strcasecmp(argv[i], "/c-src") == 0) {
            emit_c = true;
            compile_mode = true;
        } else if (strcasecmp(argv[i], "--native") == 0 || strcasecmp(argv[i], "/native") == 0) {
            native_mode = true;
            compile_mode = true;
        } else if (strcasecmp(argv[i], "-v") == 0 || strcasecmp(argv[i], "--verbose") == 0 ||
                   strcasecmp(argv[i], "/v") == 0 || strcasecmp(argv[i], "/verbose") == 0) {
            verbose = true;
        } else if (strcasecmp(argv[i], "-r") == 0 || strcasecmp(argv[i], "--run") == 0 ||
                   strcasecmp(argv[i], "/r") == 0 || strcasecmp(argv[i], "/run") == 0) {
            if (i + 1 >= argc || argv[i + 1][0] == '-' || argv[i + 1][0] == '/') {
                fprintf(stderr, "Erreur: L'option '%s' necessite le chemin d'un fichier Basic.\n\n", argv[i]);
                print_usage(argv[0]);
                return 1;
            }
            target_file = argv[++i];
        } else if (strcasecmp(argv[i], "-c") == 0 || strcasecmp(argv[i], "--cmd") == 0 ||
                   strcasecmp(argv[i], "/c") == 0 || strcasecmp(argv[i], "/cmd") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Erreur: L'option '%s' necessite une commande Basic entre guillemets.\n\n", argv[i]);
                print_usage(argv[0]);
                return 1;
            }
            inline_cmd = argv[++i];
        } else if (strcasecmp(argv[i], "-h") == 0 || strcasecmp(argv[i], "--help") == 0 ||
                   strcasecmp(argv[i], "/h") == 0 || strcasecmp(argv[i], "/?") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (argv[i][0] == '-' || argv[i][0] == '/') {
            fprintf(stderr, "Erreur: Switch inconnu '%s'.\n\n", argv[i]);
            print_usage(argv[0]);
            return 1;
        } else {
            // Argument positionnel
            if (!target_file && !inline_cmd) {
                target_file = argv[i];
            } else {
                // Argument complementaire pour COMMAND$
                if (extra_cur > 0 && extra_cur < sizeof(extra_args) - 1) {
                    extra_args[extra_cur++] = ' ';
                }
                size_t alen = strlen(argv[i]);
                if (extra_cur + alen >= sizeof(extra_args)) alen = sizeof(extra_args) - extra_cur - 1;
                memcpy(extra_args + extra_cur, argv[i], alen);
                extra_cur += alen;
                extra_args[extra_cur] = '\0';
            }
        }
    }

    // Transmission des arguments de la ligne de commande a COMMAND$
    qb_set_command_string(extra_args);

    // 1. Mode Compilation
    if (compile_mode) {
        if (!target_file) {
            fprintf(stderr, "Erreur: Aucun fichier source specifie pour la compilation.\n\n");
            print_usage(argv[0]);
            return 1;
        }
        QB_CompilerOptions opts;
        memset(&opts, 0, sizeof(opts));
        opts.source_path = target_file;
        opts.output_path = output_file;
        opts.emit_c = emit_c;
        opts.native_mode = native_mode;
        opts.verbose = verbose;
        return qb_compile(&opts);
    }

    // 2. Mode Execution directe de commande (-c)
    if (inline_cmd) {
        QB_Program *prog = qb_program_create();
        QB_Interpreter *interp = qb_interp_create(prog);
        qb_interp_exec_immediate(interp, inline_cmd);
        qb_play_wait_finished();
        qb_interp_free(interp);
        qb_program_free(prog);
        return 0;
    }

    // 3. Mode Execution de fichier source (-r ou direct)
    if (target_file) {
        QB_Program *prog = qb_program_create();
        if (!qb_program_load_file(prog, target_file)) {
            fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier QBasic '%s'\n", target_file);
            qb_program_free(prog);
            return 1;
        }
        QB_Interpreter *interp = qb_interp_create(prog);
        qb_interp_run(interp);
        qb_play_wait_finished();
        qb_interp_free(interp);
        qb_program_free(prog);
        return 0;
    }

    print_usage(argv[0]);
    return 1;
}
