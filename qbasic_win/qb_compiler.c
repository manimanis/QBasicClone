#include "qb_compiler.h"
#include "qb_interp.h"
#include "win_compat.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <windows.h>

static FILE* qb_open_file_utf8(const char *path, const char *mode) {
    if (!path || !mode) return NULL;
    int wpath_len = MultiByteToWideChar(CP_UTF8, 0, path, -1, NULL, 0);
    int wmode_len = MultiByteToWideChar(CP_UTF8, 0, mode, -1, NULL, 0);
    if (wpath_len > 0 && wmode_len > 0) {
        wchar_t *wpath = (wchar_t*)malloc(wpath_len * sizeof(wchar_t));
        wchar_t *wmode = (wchar_t*)malloc(wmode_len * sizeof(wchar_t));
        if (wpath && wmode) {
            MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, wpath_len);
            MultiByteToWideChar(CP_UTF8, 0, mode, -1, wmode, wmode_len);
            FILE *f = _wfopen(wpath, wmode);
            free(wpath);
            free(wmode);
            if (f) return f;
        } else {
            if (wpath) free(wpath);
            if (wmode) free(wmode);
        }
    }
    return fopen(path, mode);
}

bool qb_check_embedded_executable(int argc, char *argv[]) {
    wchar_t exe_path_w[MAX_PATH];
    if (GetModuleFileNameW(NULL, exe_path_w, MAX_PATH) == 0) {
        return false;
    }

    FILE *f = _wfopen(exe_path_w, L"rb");
    if (!f) return false;

    if (fseek(f, 0, SEEK_END) != 0) {
        fclose(f);
        return false;
    }
    long file_size = ftell(f);
    if (file_size < (long)(QB_EMBED_MAGIC_LEN + sizeof(uint32_t))) {
        fclose(f);
        return false;
    }

    if (fseek(f, file_size - (QB_EMBED_MAGIC_LEN + sizeof(uint32_t)), SEEK_SET) != 0) {
        fclose(f);
        return false;
    }

    char magic[QB_EMBED_MAGIC_LEN];
    if (fread(magic, 1, QB_EMBED_MAGIC_LEN, f) != QB_EMBED_MAGIC_LEN) {
        fclose(f);
        return false;
    }

    if (memcmp(magic, QB_EMBED_MAGIC, QB_EMBED_MAGIC_LEN) != 0) {
        fclose(f);
        return false;
    }

    uint32_t payload_len = 0;
    if (fread(&payload_len, sizeof(uint32_t), 1, f) != 1 || payload_len == 0 ||
        payload_len >= (uint32_t)(file_size - (QB_EMBED_MAGIC_LEN + sizeof(uint32_t)))) {
        fclose(f);
        return false;
    }

    if (fseek(f, file_size - (QB_EMBED_MAGIC_LEN + sizeof(uint32_t)) - (long)payload_len, SEEK_SET) != 0) {
        fclose(f);
        return false;
    }

    char *source_text = (char*)malloc(payload_len + 1);
    if (!source_text) {
        fclose(f);
        return false;
    }

    size_t n = fread(source_text, 1, payload_len, f);
    source_text[n] = '\0';
    fclose(f);

    // Initialiser la couche de compatibilité et sous-systèmes
    qb_compat_init();

    // Renseigner les arguments dans COMMAND$
    char cmd_buf[4096] = {0};
    size_t cur = 0;
    for (int i = 1; i < argc; i++) {
        if (i > 1 && cur < sizeof(cmd_buf) - 1) cmd_buf[cur++] = ' ';
        size_t alen = strlen(argv[i]);
        if (cur + alen >= sizeof(cmd_buf)) alen = sizeof(cmd_buf) - cur - 1;
        memcpy(cmd_buf + cur, argv[i], alen);
        cur += alen;
        cmd_buf[cur] = '\0';
    }
    qb_set_command_string(cmd_buf);

    // Définir le répertoire du programme pour les chemins relatifs
    wchar_t *sep = wcsrchr(exe_path_w, L'\\');
    wchar_t *slash = wcsrchr(exe_path_w, L'/');
    if (slash > sep) sep = slash;
    if (sep) {
        *sep = L'\0';
        char dir[MAX_PATH] = {0};
        WideCharToMultiByte(CP_UTF8, 0, exe_path_w, -1, dir, sizeof(dir), NULL, NULL);
        qb_set_program_dir(dir);
    }

    // Charger et exécuter le programme QBasic encapsulé
    QB_Program *prog = qb_program_create();
    qb_program_load_string(prog, source_text);
    free(source_text);

    QB_Interpreter *interp = qb_interp_create(prog);
    qb_interp_run(interp);
    qb_play_wait_finished();
    qb_interp_free(interp);
    qb_program_free(prog);

    return true;
}

bool qb_emit_c_source(const char *source_text, size_t source_len, const char *output_c_path) {
    FILE *f = qb_open_file_utf8(output_c_path, "w");
    if (!f) {
        fprintf(stderr, "Erreur: Impossible de créer le fichier C '%s'\n", output_c_path);
        return false;
    }

    fprintf(f, "/* ========================================================================= */\n");
    fprintf(f, "/* Fichier source C autonome genere par le compilateur QBasic (qbasic_win)   */\n");
    fprintf(f, "/* ========================================================================= */\n\n");
    fprintf(f, "#include <stdio.h>\n");
    fprintf(f, "#include <stdlib.h>\n");
    fprintf(f, "#include <string.h>\n");
    fprintf(f, "#include <windows.h>\n");
    fprintf(f, "#include \"win_compat.h\"\n");
    fprintf(f, "#include \"qb_interp.h\"\n\n");

    fprintf(f, "/* Code source QBasic integre (%zu octets) */\n", source_len);
    fprintf(f, "static const unsigned char qb_embedded_source[] = {\n    ");
    for (size_t i = 0; i < source_len; i++) {
        fprintf(f, "0x%02X%s", (unsigned char)source_text[i], (i + 1 == source_len) ? "" : ", ");
        if ((i + 1) % 16 == 0 && i + 1 < source_len) {
            fprintf(f, "\n    ");
        }
    }
    fprintf(f, "%s0x00\n};\n\n", source_len > 0 ? ", " : "");

    fprintf(f, "int main(int argc, char *argv[]) {\n");
    fprintf(f, "    qb_compat_init();\n\n");
    fprintf(f, "    /* Renseignement de COMMAND$ */\n");
    fprintf(f, "    char cmd_buf[4096] = {0};\n");
    fprintf(f, "    size_t cur = 0;\n");
    fprintf(f, "    for (int i = 1; i < argc; i++) {\n");
    fprintf(f, "        if (i > 1 && cur < sizeof(cmd_buf) - 1) cmd_buf[cur++] = ' ';\n");
    fprintf(f, "        size_t alen = strlen(argv[i]);\n");
    fprintf(f, "        if (cur + alen >= sizeof(cmd_buf)) alen = sizeof(cmd_buf) - cur - 1;\n");
    fprintf(f, "        memcpy(cmd_buf + cur, argv[i], alen);\n");
    fprintf(f, "        cur += alen;\n");
    fprintf(f, "        cmd_buf[cur] = '\\0';\n");
    fprintf(f, "    }\n");
    fprintf(f, "    qb_set_command_string(cmd_buf);\n\n");
    fprintf(f, "    /* Repertoire du binaire pour chemins relatifs */\n");
    fprintf(f, "    wchar_t exe_w[MAX_PATH];\n");
    fprintf(f, "    if (GetModuleFileNameW(NULL, exe_w, MAX_PATH)) {\n");
    fprintf(f, "        wchar_t *sep = wcsrchr(exe_w, L'\\\\');\n");
    fprintf(f, "        wchar_t *slash = wcsrchr(exe_w, L'/');\n");
    fprintf(f, "        if (slash > sep) sep = slash;\n");
    fprintf(f, "        if (sep) {\n");
    fprintf(f, "            *sep = L'\\0';\n");
    fprintf(f, "            char dir[MAX_PATH] = {0};\n");
    fprintf(f, "            WideCharToMultiByte(CP_UTF8, 0, exe_w, -1, dir, sizeof(dir), NULL, NULL);\n");
    fprintf(f, "            qb_set_program_dir(dir);\n");
    fprintf(f, "        }\n");
    fprintf(f, "    }\n\n");
    fprintf(f, "    QB_Program *prog = qb_program_create();\n");
    fprintf(f, "    qb_program_load_string(prog, (const char*)qb_embedded_source);\n");
    fprintf(f, "    QB_Interpreter *interp = qb_interp_create(prog);\n");
    fprintf(f, "    qb_interp_run(interp);\n");
    fprintf(f, "    qb_play_wait_finished();\n");
    fprintf(f, "    qb_interp_free(interp);\n");
    fprintf(f, "    qb_program_free(prog);\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n");

    fclose(f);
    return true;
}

int qb_compile(const QB_CompilerOptions *options) {
    if (!options || !options->source_path) {
        fprintf(stderr, "Erreur: Aucun fichier source QBasic specifie pour la compilation.\n");
        return 1;
    }

    // 1. Lecture du code source Basic
    FILE *src_f = qb_open_file_utf8(options->source_path, "rb");
    if (!src_f) {
        fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier source '%s'\n", options->source_path);
        return 1;
    }
    fseek(src_f, 0, SEEK_END);
    long src_size = ftell(src_f);
    fseek(src_f, 0, SEEK_SET);

    if (src_size < 0) {
        fclose(src_f);
        fprintf(stderr, "Erreur: Fichier source invalide ou vide '%s'\n", options->source_path);
        return 1;
    }

    char *source_text = (char*)malloc(src_size + 1);
    if (!source_text) {
        fclose(src_f);
        fprintf(stderr, "Erreur: Memoire insuffisante pour charger '%s'\n", options->source_path);
        return 1;
    }
    size_t read_bytes = fread(source_text, 1, src_size, src_f);
    source_text[read_bytes] = '\0';
    fclose(src_f);

    // 2. Determination du nom du fichier de sortie
    char out_path[MAX_PATH];
    if (options->output_path && options->output_path[0]) {
        strncpy(out_path, options->output_path, sizeof(out_path) - 1);
        out_path[sizeof(out_path) - 1] = '\0';
    } else {
        strncpy(out_path, options->source_path, sizeof(out_path) - 1);
        out_path[sizeof(out_path) - 1] = '\0';
        char *dot = strrchr(out_path, '.');
        char *slash = strrchr(out_path, '/');
        char *backslash = strrchr(out_path, '\\');
        char *sep = (slash > backslash) ? slash : backslash;
        if (dot && (!sep || dot > sep)) {
            *dot = '\0';
        }
        strncat(out_path, options->emit_c ? ".c" : ".exe", sizeof(out_path) - strlen(out_path) - 1);
    }

    // 3. Option --c / --emit-c : Generation du fichier source C
    if (options->emit_c) {
        if (options->verbose) {
            printf("[QBasic Compiler] Generation du code source C dans '%s'...\n", out_path);
        }
        if (!qb_emit_c_source(source_text, read_bytes, out_path)) {
            free(source_text);
            return 1;
        }
        printf("Export C termine avec succes !\n");
        printf("  Fichier source : %s (%zu octets)\n", options->source_path, read_bytes);
        printf("  Fichier C genéré: %s\n", out_path);
        free(source_text);
        return 0;
    }

    // 4. Mode compilation native GCC (si demande via --native)
    if (options->native_mode) {
        char tmp_c[MAX_PATH];
        snprintf(tmp_c, sizeof(tmp_c), "%s.__tmp_build.c", out_path);
        if (qb_emit_c_source(source_text, read_bytes, tmp_c)) {
            char gcc_cmd[4096];
            snprintf(gcc_cmd, sizeof(gcc_cmd),
                "gcc -O2 \"%s\" -o \"%s\" -static -lSDL2 -lm -lkernel32 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lversion -luuid -ladvapi32 -lshell32 -ldinput8 2>nul",
                tmp_c, out_path);
            if (options->verbose) {
                printf("[QBasic Compiler] Lancement GCC : %s\n", gcc_cmd);
            }
            int ret = system(gcc_cmd);
            if (!options->verbose) {
                remove(tmp_c);
            }
            if (ret == 0) {
                printf("Compilation native GCC terminee avec succes !\n");
                printf("  Fichier binaire : %s\n", out_path);
                free(source_text);
                return 0;
            } else {
                if (options->verbose) {
                    printf("[QBasic Compiler] GCC non disponible ou echec de compilation (code %d). Repli vers le mode autonome overlay...\n", ret);
                }
            }
        }
    }

    // 5. Mode autonome standard (Overlay PE)
    wchar_t self_exe_w[MAX_PATH];
    if (GetModuleFileNameW(NULL, self_exe_w, MAX_PATH) == 0) {
        fprintf(stderr, "Erreur: Impossible d'obtenir le chemin de l'executable hote.\n");
        free(source_text);
        return 1;
    }

    FILE *self_f = _wfopen(self_exe_w, L"rb");
    if (!self_f) {
        fprintf(stderr, "Erreur: Impossible de lire le binaire hote pour packaging.\n");
        free(source_text);
        return 1;
    }

    fseek(self_f, 0, SEEK_END);
    long self_size = ftell(self_f);
    fseek(self_f, 0, SEEK_SET);

    // Si l'hote a deja un overlay, on extrait uniquement la taille du binaire pur
    long base_exe_size = self_size;
    if (self_size >= (long)(QB_EMBED_MAGIC_LEN + sizeof(uint32_t))) {
        fseek(self_f, self_size - (QB_EMBED_MAGIC_LEN + sizeof(uint32_t)), SEEK_SET);
        char chk_magic[QB_EMBED_MAGIC_LEN];
        uint32_t chk_len = 0;
        if (fread(chk_magic, 1, QB_EMBED_MAGIC_LEN, self_f) == QB_EMBED_MAGIC_LEN &&
            fread(&chk_len, sizeof(uint32_t), 1, self_f) == 1) {
            if (memcmp(chk_magic, QB_EMBED_MAGIC, QB_EMBED_MAGIC_LEN) == 0 &&
                chk_len < (uint32_t)(self_size - 12)) {
                base_exe_size = self_size - 12 - (long)chk_len;
            }
        }
    }
    fseek(self_f, 0, SEEK_SET);

    FILE *out_f = qb_open_file_utf8(out_path, "wb");
    if (!out_f) {
        fprintf(stderr, "Erreur: Impossible d'ouvrir le fichier de sortie '%s' en ecriture.\n", out_path);
        fclose(self_f);
        free(source_text);
        return 1;
    }

    if (options->verbose) {
        printf("[QBasic Compiler] Ecriture du runtime (%ld octets)...\n", base_exe_size);
    }

    char copy_buf[65536];
    long remaining = base_exe_size;
    while (remaining > 0) {
        size_t to_read = (remaining > (long)sizeof(copy_buf)) ? sizeof(copy_buf) : (size_t)remaining;
        size_t n = fread(copy_buf, 1, to_read, self_f);
        if (n == 0) break;
        if (fwrite(copy_buf, 1, n, out_f) != n) {
            fprintf(stderr, "Erreur: Echec d'ecriture du runtime dans '%s'\n", out_path);
            fclose(self_f);
            fclose(out_f);
            free(source_text);
            return 1;
        }
        remaining -= (long)n;
    }
    fclose(self_f);

    if (options->verbose) {
        printf("[QBasic Compiler] Injection de la charge utile (%zu octets)...\n", read_bytes);
    }

    if (fwrite(source_text, 1, read_bytes, out_f) != read_bytes) {
        fprintf(stderr, "Erreur: Echec d'injection du code source dans '%s'\n", out_path);
        fclose(out_f);
        free(source_text);
        return 1;
    }

    if (fwrite(QB_EMBED_MAGIC, 1, QB_EMBED_MAGIC_LEN, out_f) != QB_EMBED_MAGIC_LEN) {
        fprintf(stderr, "Erreur: Echec d'ecriture du marqueur d'overlay dans '%s'\n", out_path);
        fclose(out_f);
        free(source_text);
        return 1;
    }

    uint32_t payload_len = (uint32_t)read_bytes;
    if (fwrite(&payload_len, sizeof(uint32_t), 1, out_f) != 1) {
        fprintf(stderr, "Erreur: Echec d'ecriture de la taille d'overlay dans '%s'\n", out_path);
        fclose(out_f);
        free(source_text);
        return 1;
    }

    long total_size = ftell(out_f);
    fclose(out_f);
    free(source_text);

    printf("Compilation terminee avec succes !\n");
    printf("  Fichier source  : %s (%zu octets)\n", options->source_path, read_bytes);
    printf("  Executable cree : %s (%ld octets)\n", out_path, total_size);
    printf("  Format          : Win64 PE autonome (aucun runtime externe requis)\n");

    return 0;
}
