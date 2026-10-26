#ifndef QB_INTERP_H
#define QB_INTERP_H

#include "qb_types.h"
#include "win_compat.h"

typedef struct {
    char **lines;
    int line_count;
    int capacity;
} QB_Program;

typedef struct {
    char **items;
    int *line_numbers;
    int count;
    int capacity;
    int current_idx;
} QB_DataPool;

typedef enum {
    QB_FILE_MODE_NONE = 0,
    QB_FILE_MODE_INPUT,
    QB_FILE_MODE_OUTPUT,
    QB_FILE_MODE_APPEND,
    QB_FILE_MODE_BINARY,
    QB_FILE_MODE_RANDOM
} QB_FileMode;

#define QB_MAX_FIELD_VARS 32

typedef struct {
    int count;
    struct {
        char var_name[64];
        int offset;
        int width;
    } fields[QB_MAX_FIELD_VARS];
} QB_FileFieldDef;

typedef struct {
    QB_Program *program;
    QB_Env *env;
    int pc; // Program Counter
    bool running;
    bool exit_requested;

    // Fichiers ouverts (1..255)
    FILE *files[256];
    char file_buf[256][2048];
    int file_buf_pos[256];
    QB_FileMode file_modes[256];
    int file_record_lens[256];
    long file_current_record[256];
    long file_last_pos[256];
    char file_random_buffers[256][4096];
    QB_FileFieldDef file_fields[256];

    // Association variable -> nom de type pour les instances de TYPE
    struct {
        char var_name[64];
        char type_name[64];
    } var_types[128];
    int var_type_count;

    // Pool de DATA / READ / RESTORE
    QB_DataPool data_pool;

    // Pile d'appels pour GOSUB/RETURN
    int gosub_stack[128];
    int gosub_sp;

    // Pile de boucles FOR/NEXT
    struct {
        char var_name[64];
        double end_val;
        double step_val;
        int loop_pc; // Ligne suivant le FOR
    } for_stack[64];
    int for_sp;

    // Pile de boucles WHILE/WEND
    int while_stack[64];
    int while_sp;

    // Pile de boucles DO/LOOP
    struct {
        int do_pc;
    } do_stack[64];
    int do_sp;

    // Pile pour SELECT CASE
    struct {
        QB_Value test_val;
        bool case_matched;
        int end_select_pc;
    } select_stack[32];
    int select_sp;

    // Pile pour les blocs IF multi-lignes
    struct {
        bool branch_taken;
        int end_if_pc;
    } if_stack[64];
    int if_sp;

    // Définitions de SUB et FUNCTION
    struct {
        char name[64];
        int start_pc;
        int param_count;
        char params[16][64];
        bool is_function;
    } procs[64];
    int proc_count;

    // Pile d'appels SUB / FUNCTION
    struct {
        int return_pc;
        char proc_name[64];
        bool is_function;
        int saved_var_count;
        char saved_var_names[16][64];
        QB_Value saved_var_values[16];
        char ref_var_names[16][64];
        int alias_count;
        char alias_names[32][64];
        int saved_do_sp;
        int saved_for_sp;
        int saved_while_sp;
        int saved_select_sp;
        int saved_if_sp;
        int saved_gosub_sp;
        int saved_on_error_pc;
        int saved_on_error_call_sp;
    } call_stack[64];
    int call_sp;

    // Gestion des erreurs (ON ERROR GOTO / RESUME / ERR / ERL)
    int on_error_pc;       // PC de destination du handler ON ERROR (-1 si inactif)
    int on_error_call_sp;  // Niveau d'appel (call_sp) où le handler a été défini
    int err_code;          // Code de la dernière erreur (ERR)
    int err_line;          // Numéro de ligne de l'instruction fautive (ERL)
    int err_pc;            // PC de l'instruction qui a déclenché l'erreur
    bool in_error_handler; // Vrai si on est dans l'exécution d'un gestionnaire d'erreur

    // Événements matériels (ON KEY / ON TIMER / ON PLAY)
    bool in_event_handler;
    int key_trap_pc[32];
    int key_state[32];    // 0=OFF, 1=ON, 2=STOP
    bool key_pending[32];
    char key_defs[32][64];

    int timer_trap_pc;
    double timer_interval;
    double timer_last_sec;
    int timer_state;      // 0=OFF, 1=ON, 2=STOP
    bool timer_pending;

    int play_trap_pc;
    int play_threshold;
    int play_state;       // 0=OFF, 1=ON, 2=STOP
    bool play_pending;
    bool play_fired;

    // Définitions de types utilisateur (TYPE ... END TYPE)
    struct {
        char name[64];
        int field_count;
        struct {
            char name[64];
            char type_name[32];
        } fields[32];
    } type_defs[32];
    int type_def_count;

    // Fonctions simples définies par DEF FN
    struct {
        char name[64];
        char param[64];
        char expr[256];
    } def_fns[16];
    int def_fn_count;

    // Variables et tableaux partagés (COMMON SHARED, DIM SHARED, SHARED)
    char shared_vars[512][64];
    int shared_var_count;

} QB_Interpreter;

// Gestion du programme
QB_Program* qb_program_create(void);
void qb_program_free(QB_Program *prog);
void qb_program_add_line(QB_Program *prog, const char *line);
bool qb_program_load_file(QB_Program *prog, const char *filename);

// Interpréteur
QB_Interpreter* qb_interp_create(QB_Program *prog);
void qb_interp_free(QB_Interpreter *interp);
void qb_interp_run(QB_Interpreter *interp);
void qb_interp_step(QB_Interpreter *interp);
bool qb_interp_exec_immediate(QB_Interpreter *interp, const char *line);
void qb_trigger_error(QB_Interpreter *interp, int code);
void qb_interp_trigger_key_event(QB_Interpreter *interp, int kn);

// Évaluateur d'expressions
QB_Value qb_eval_expression(QB_Env *env, const char **expr_ptr);

#endif // QB_INTERP_H
