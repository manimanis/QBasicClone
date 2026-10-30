#ifndef QB_COMPILER_H
#define QB_COMPILER_H

#include <stdbool.h>
#include <stddef.h>

// Signature magique placée en fin de binaire encapsulé (8 octets)
#define QB_EMBED_MAGIC "QB_EMBED"
#define QB_EMBED_MAGIC_LEN 8

// Options de compilation
typedef struct {
    const char *source_path;    // Chemin du fichier source .BAS
    const char *output_path;    // Chemin du fichier de sortie (.exe ou .c)
    bool emit_c;                // Si vrai, génère du code source C intermédiaire
    bool native_mode;           // Si vrai, compile via GCC natif
    bool verbose;               // Mode verbeux
} QB_CompilerOptions;

// Vérifie si l'exécutable courant contient du code QBasic encapsulé (mode autonome).
// Si oui, initialise COMMAND$, charge et exécute le programme, puis retourne true.
// Si non, retourne false (l'exécutable agit alors comme compilateur/interpréteur standard).
bool qb_check_embedded_executable(int argc, char *argv[]);

// Compile un fichier source QBasic selon les options spécifiées.
// Retourne 0 en cas de succès, un code non nul en cas d'erreur.
int qb_compile(const QB_CompilerOptions *options);

// Génère du code source C autonome contenant le programme QBasic encapsulé
bool qb_emit_c_source(const char *source_text, size_t source_len, const char *output_c_path);

#endif // QB_COMPILER_H

