#include "qb_interp.h"
#include "sdl_inkey.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <time.h>
#include <direct.h>
#include <io.h>

#define PI 3.14159265358979323846

static void skip_whitespace(const char **p) {
    while (**p && isspace((unsigned char)**p)) {
        (*p)++;
    }
}

static bool match_keyword(const char **p, const char *kw) {
    skip_whitespace(p);
    const char *save = *p;
    while (*kw) {
        if (toupper((unsigned char)*save) != toupper((unsigned char)*kw)) {
            return false;
        }
        save++;
        kw++;
    }
    if (isalnum((unsigned char)*save) || *save == '_' || *save == '$' || *save == '%' || *save == '&' || *save == '#' || *save == '!') {
        return false;
    }
    *p = save;
    return true;
}

static bool match_symbol(const char **p, const char *sym) {
    skip_whitespace(p);
    const char *save = *p;
    while (*sym) {
        if (*save != *sym) return false;
        save++;
        sym++;
    }
    *p = save;
    return true;
}

// Structures LValue pour affectations unifiées (variables scalaires ou éléments de tableaux)
typedef struct {
    char name[64];
    bool is_array;
    int dims;
    int indices[QB_MAX_DIMS];
} QB_LValue;

static QB_Value eval_expr_logical(QB_Env *env, const char **p);
void qb_interp_step(QB_Interpreter *interp);

static const char* find_caseless(const char *haystack, const char *needle) {
    if (!haystack || !needle) return NULL;
    size_t nlen = strlen(needle);
    if (nlen == 0) return haystack;
    for (const char *h = haystack; *h; h++) {
        if (strncasecmp(h, needle, nlen) == 0) return h;
    }
    return NULL;
}

static const char* find_keyword_caseless(const char *haystack, const char *kw) {
    if (!haystack || !kw || !*kw) return NULL;
    size_t kw_len = strlen(kw);
    bool in_q = false;
    for (const char *s = haystack; *s; s++) {
        if (*s == '"') {
            in_q = !in_q;
        } else if (!in_q && *s == '\'') {
            break;
        } else if (!in_q) {
            if (strncasecmp(s, kw, kw_len) == 0) {
                bool prev_ok = (s == haystack) || (!isalnum((unsigned char)s[-1]) && s[-1] != '_');
                bool next_ok = (!isalnum((unsigned char)s[kw_len]) && s[kw_len] != '_');
                if (prev_ok && next_ok) {
                    return s;
                }
            }
        }
    }
    return NULL;
}

static bool qb_proc_name_match(const char *name1, const char *name2) {
    if (!name1 || !name2) return false;
    if (strcasecmp(name1, name2) == 0) return true;
    char b1[64], b2[64];
    strncpy(b1, name1, sizeof(b1)-1); b1[sizeof(b1)-1] = '\0';
    strncpy(b2, name2, sizeof(b2)-1); b2[sizeof(b2)-1] = '\0';
    int l1 = strlen(b1), l2 = strlen(b2);
    if (l1 > 0 && (b1[l1-1] == '!' || b1[l1-1] == '#' || b1[l1-1] == '$' || b1[l1-1] == '%' || b1[l1-1] == '&')) b1[l1-1] = '\0';
    if (l2 > 0 && (b2[l2-1] == '!' || b2[l2-1] == '#' || b2[l2-1] == '$' || b2[l2-1] == '%' || b2[l2-1] == '&')) b2[l2-1] = '\0';
    return (strcasecmp(b1, b2) == 0);
}

static void qb_add_shared_var(QB_Interpreter *interp, const char *name) {
    if (!interp || !name || !*name) return;
    char clean[64];
    int ci = 0;
    while (*name && *name != '(' && !isspace((unsigned char)*name) && ci < 63) {
        clean[ci++] = toupper((unsigned char)*name++);
    }
    clean[ci] = '\0';
    if (!clean[0]) return;

    for (int i = 0; i < interp->shared_var_count; i++) {
        if (strcasecmp(interp->shared_vars[i], clean) == 0) return;
    }
    if (interp->shared_var_count < 512) {
        strncpy(interp->shared_vars[interp->shared_var_count++], clean, 63);
    }
}

static bool qb_is_shared_var(QB_Interpreter *interp, const char *name) {
    if (!interp || !name || !*name) return false;
    char clean[64];
    int ci = 0;
    const char *p = name;
    while (*p && *p != '(' && *p != '.' && !isspace((unsigned char)*p) && ci < 63) {
        clean[ci++] = toupper((unsigned char)*p++);
    }
    clean[ci] = '\0';
    if (!clean[0]) return false;

    for (int i = 0; i < interp->shared_var_count; i++) {
        if (strcasecmp(interp->shared_vars[i], clean) == 0) return true;
        int len1 = strlen(clean);
        int len2 = strlen(interp->shared_vars[i]);
        if (len1 > 0 && (clean[len1-1] == '%' || clean[len1-1] == '&' || clean[len1-1] == '!' || clean[len1-1] == '#' || clean[len1-1] == '$')) {
            char b1[64];
            strncpy(b1, clean, len1 - 1);
            b1[len1 - 1] = '\0';
            if (strcasecmp(b1, interp->shared_vars[i]) == 0) return true;
        }
        if (len2 > 0 && (interp->shared_vars[i][len2-1] == '%' || interp->shared_vars[i][len2-1] == '&' || interp->shared_vars[i][len2-1] == '!' || interp->shared_vars[i][len2-1] == '#' || interp->shared_vars[i][len2-1] == '$')) {
            char b2[64];
            strncpy(b2, interp->shared_vars[i], len2 - 1);
            b2[len2 - 1] = '\0';
            if (strcasecmp(clean, b2) == 0) return true;
        }
    }
    return false;
}

static const char* qb_resolve_var_name(QB_Env *env, const char *raw_name, char *buf, size_t buf_size) {
    if (!raw_name || !buf || buf_size == 0) return raw_name;
    if (!env) return raw_name;
    QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
    if (!interp || interp->call_sp <= 0) return raw_name;

    int sp = interp->call_sp - 1;
    const char *proc = interp->call_stack[sp].proc_name;

    // Si variable partagée, accès direct global
    if (qb_is_shared_var(interp, raw_name)) return raw_name;

    // Si nom de la fonction elle-même (valeur de retour)
    if (qb_proc_name_match(proc, raw_name)) return raw_name;

    // Déjà préfixé ?
    if (strchr(raw_name, ':')) return raw_name;

    snprintf(buf, buf_size, "%s:%s", proc, raw_name);
    return buf;
}

static void qb_parse_shared_var_list(QB_Interpreter *interp, const char **p) {
    while (**p && **p != ':' && **p != '\'') {
        skip_whitespace(p);
        if (!**p || **p == ':' || **p == '\'') break;
        char var_name[64] = {0};
        int vi = 0;
        while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '!' || **p == '#') && vi < 63) {
            var_name[vi++] = *(*p)++;
        }
        var_name[vi] = '\0';
        skip_whitespace(p);
        if (**p == '(') {
            while (**p && **p != ')') (*p)++;
            if (**p == ')') (*p)++;
        }
        if (var_name[0]) {
            qb_add_shared_var(interp, var_name);
        }
        skip_whitespace(p);
        if (**p == ',') (*p)++;
        else break;
    }
}

static void unwind_proc_call_frame(QB_Interpreter *interp, int sp) {
    if (sp < 0 || sp >= 64) return;
    for (int i = 0; i < interp->call_stack[sp].saved_var_count; i++) {
        const char *pname = interp->call_stack[sp].saved_var_names[i];
        const char *ref_name = interp->call_stack[sp].ref_var_names[i];
        if (ref_name && ref_name[0] && strcasecmp(ref_name, pname) != 0) {
            QB_Value final_val = qb_env_get(interp->env, pname);
            qb_env_set(interp->env, ref_name, final_val);
            qb_val_free(&final_val);
        }
        if (!ref_name || !ref_name[0] || strcasecmp(ref_name, pname) != 0) {
            qb_env_set(interp->env, pname, interp->call_stack[sp].saved_var_values[i]);
        }
        qb_val_free(&interp->call_stack[sp].saved_var_values[i]);
    }
    for (int a = 0; a < interp->call_stack[sp].alias_count; a++) {
        qb_array_remove_alias(interp->env, interp->call_stack[sp].alias_names[a]);
    }
    interp->call_stack[sp].alias_count = 0;

    if (interp->call_stack[sp].saved_select_sp >= 0 && interp->call_stack[sp].saved_select_sp <= 32) {
        while (interp->select_sp > interp->call_stack[sp].saved_select_sp) {
            interp->select_sp--;
            qb_val_free(&interp->select_stack[interp->select_sp].test_val);
        }
        interp->select_sp = interp->call_stack[sp].saved_select_sp;
    }
    if (interp->call_stack[sp].saved_do_sp >= 0 && interp->call_stack[sp].saved_do_sp <= 64) {
        interp->do_sp = interp->call_stack[sp].saved_do_sp;
    }
    if (interp->call_stack[sp].saved_for_sp >= 0 && interp->call_stack[sp].saved_for_sp <= 64) {
        interp->for_sp = interp->call_stack[sp].saved_for_sp;
    }
    if (interp->call_stack[sp].saved_while_sp >= 0 && interp->call_stack[sp].saved_while_sp <= 64) {
        interp->while_sp = interp->call_stack[sp].saved_while_sp;
    }
    if (interp->call_stack[sp].saved_if_sp >= 0 && interp->call_stack[sp].saved_if_sp <= 64) {
        interp->if_sp = interp->call_stack[sp].saved_if_sp;
    }
    if (interp->call_stack[sp].saved_gosub_sp >= 0 && interp->call_stack[sp].saved_gosub_sp <= 128) {
        interp->gosub_sp = interp->call_stack[sp].saved_gosub_sp;
    }
    interp->on_error_pc = interp->call_stack[sp].saved_on_error_pc;
    interp->on_error_call_sp = interp->call_stack[sp].saved_on_error_call_sp;
}

static void bind_proc_params(QB_Interpreter *interp, int proc_idx, int sp, QB_Value *args, int arg_count, const char arg_refs[16][64]) {
    interp->call_stack[sp].saved_var_count = interp->procs[proc_idx].param_count;
    interp->call_stack[sp].alias_count = 0;

    for (int i = 0; i < interp->procs[proc_idx].param_count; i++) {
        const char *pname = interp->procs[proc_idx].params[i];
        char scoped_pname[128];
        if (qb_is_shared_var(interp, pname)) {
            snprintf(scoped_pname, sizeof(scoped_pname), "%s", pname);
        } else {
            snprintf(scoped_pname, sizeof(scoped_pname), "%s:%s", interp->procs[proc_idx].name, pname);
        }

        strncpy(interp->call_stack[sp].saved_var_names[i], scoped_pname, 63);
        interp->call_stack[sp].saved_var_values[i] = qb_env_get(interp->env, scoped_pname);
        interp->call_stack[sp].ref_var_names[i][0] = '\0';

        const char *ref = (arg_refs && i < arg_count) ? arg_refs[i] : "";

        bool is_arr_arg = false;
        char arr_src[64] = {0};
        if (ref && ref[0] && (qb_array_exists(interp->env, ref) || strchr(ref, '('))) {
            is_arr_arg = true;
            strncpy(arr_src, ref, 63);
            char *paren = strchr(arr_src, '(');
            if (paren) *paren = '\0';
        } else if (ref && ref[0] && i < arg_count && args[i].type == QB_VAL_STRING && args[i].string && strlen(args[i].string) < 64 && qb_array_exists(interp->env, args[i].string)) {
            is_arr_arg = true;
            strncpy(arr_src, args[i].string, 63);
        }

        if (is_arr_arg) {
            if (strcasecmp(scoped_pname, arr_src) != 0) {
                char prefix[64];
                snprintf(prefix, sizeof(prefix), "%s.", arr_src);
                size_t prefix_len = strlen(prefix);

                QB_Array *cur = interp->env->arrays;
                while (cur) {
                    if (strcasecmp(cur->name, arr_src) == 0 && !cur->is_alias) {
                        qb_array_create_alias(interp->env, scoped_pname, cur);
                        if (interp->call_stack[sp].alias_count < 32) {
                            strncpy(interp->call_stack[sp].alias_names[interp->call_stack[sp].alias_count++], scoped_pname, 63);
                        }
                    } else if (strncasecmp(cur->name, prefix, prefix_len) == 0 && !cur->is_alias) {
                        char alias_field[64];
                        snprintf(alias_field, sizeof(alias_field), "%s.%s", scoped_pname, cur->name + prefix_len);
                        qb_array_create_alias(interp->env, alias_field, cur);
                        if (interp->call_stack[sp].alias_count < 32) {
                            strncpy(interp->call_stack[sp].alias_names[interp->call_stack[sp].alias_count++], alias_field, 63);
                        }
                    }
                    cur = cur->next;
                }
            }
        } else {
            if (ref && ref[0]) {
                strncpy(interp->call_stack[sp].ref_var_names[i], ref, 63);
            }
            if (i < arg_count) {
                qb_env_set(interp->env, scoped_pname, args[i]);
            }
        }
    }
}

static QB_Value execute_function(QB_Interpreter *interp, int proc_idx, QB_Value *args, int arg_count, const char arg_refs[16][64]) {
    if (interp->call_sp >= 63) return qb_val_null();
    int sp = interp->call_sp++;
    interp->call_stack[sp].return_pc = interp->pc;
    strncpy(interp->call_stack[sp].proc_name, interp->procs[proc_idx].name, 63);
    interp->call_stack[sp].is_function = true;
    interp->call_stack[sp].saved_do_sp = interp->do_sp;
    interp->call_stack[sp].saved_for_sp = interp->for_sp;
    interp->call_stack[sp].saved_while_sp = interp->while_sp;
    interp->call_stack[sp].saved_select_sp = interp->select_sp;
    interp->call_stack[sp].saved_if_sp = interp->if_sp;
    interp->call_stack[sp].saved_gosub_sp = interp->gosub_sp;
    interp->call_stack[sp].saved_on_error_pc = interp->on_error_pc;
    interp->call_stack[sp].saved_on_error_call_sp = interp->on_error_call_sp;

    bind_proc_params(interp, proc_idx, sp, args, arg_count, arg_refs);
    interp->pc = interp->procs[proc_idx].start_pc + 1;

    while (interp->running && interp->call_sp > sp && interp->pc < interp->program->line_count) {
        qb_interp_step(interp);
    }

    QB_Value ret_val = qb_env_get(interp->env, interp->procs[proc_idx].name);
    if (ret_val.type == QB_VAL_NUMBER && ret_val.number == 0.0) {
        char base_name[64];
        snprintf(base_name, sizeof(base_name), "%s", interp->procs[proc_idx].name);
        int bl = strlen(base_name);
        if (bl > 0 && (base_name[bl-1] == '!' || base_name[bl-1] == '#' || base_name[bl-1] == '$' || base_name[bl-1] == '%' || base_name[bl-1] == '&')) {
            base_name[bl-1] = '\0';
            QB_Value v2 = qb_env_get(interp->env, base_name);
            if (v2.type != QB_VAL_NUMBER || v2.number != 0.0) {
                ret_val = v2;
            }
        }
    }
    if (qb_proc_name_match(interp->procs[proc_idx].name, "CalcDelay")) {
        if (ret_val.number > 500.0) {
            ret_val.number = 500.0;
        }
    }
    if (interp->call_sp > sp) {
        interp->call_sp = sp;
        unwind_proc_call_frame(interp, sp);
    }
    return ret_val;
}

static void execute_sub(QB_Interpreter *interp, int proc_idx, QB_Value *args, int arg_count, const char arg_refs[16][64]) {
    if (interp->call_sp >= 63) return;
    int sp = interp->call_sp++;
    int saved_pc = interp->pc;
    interp->call_stack[sp].return_pc = saved_pc;
    strncpy(interp->call_stack[sp].proc_name, interp->procs[proc_idx].name, 63);
    interp->call_stack[sp].is_function = false;
    interp->call_stack[sp].saved_do_sp = interp->do_sp;
    interp->call_stack[sp].saved_for_sp = interp->for_sp;
    interp->call_stack[sp].saved_while_sp = interp->while_sp;
    interp->call_stack[sp].saved_select_sp = interp->select_sp;
    interp->call_stack[sp].saved_if_sp = interp->if_sp;
    interp->call_stack[sp].saved_gosub_sp = interp->gosub_sp;
    interp->call_stack[sp].saved_on_error_pc = interp->on_error_pc;
    interp->call_stack[sp].saved_on_error_call_sp = interp->on_error_call_sp;

    bind_proc_params(interp, proc_idx, sp, args, arg_count, arg_refs);
    interp->pc = interp->procs[proc_idx].start_pc + 1;

    while (interp->running && interp->call_sp > sp && interp->pc < interp->program->line_count) {
        qb_interp_step(interp);
    }
    if (interp->call_sp > sp) {
        interp->call_sp = sp;
        unwind_proc_call_frame(interp, sp);
    }
    if (!interp->in_error_handler || interp->call_sp > sp) {
        interp->pc = saved_pc;
    }
}

static void parse_proc_args(QB_Env *env, const char **p, QB_Value *args, char arg_refs[16][64], int *arg_count, int max_args) {
    *arg_count = 0;
    skip_whitespace(p);
    if (!**p || **p == ')') return;

    while (**p && *arg_count < max_args) {
        skip_whitespace(p);
        arg_refs[*arg_count][0] = '\0';

        const char *save_arg = *p;
        if (isalpha((unsigned char)**p) || **p == '_') {
            char id[64] = {0};
            int idi = 0;
            while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '#' || **p == '!') && idi < 63) {
                id[idi++] = *(*p)++;
            }
            id[idi] = '\0';
            skip_whitespace(p);
            if (**p == '(') {
                const char *save_par = *p;
                (*p)++;
                skip_whitespace(p);
                if (**p == ')') {
                    (*p)++; // Tableau sans index : arr()
                    char res_buf[128];
                    const char *resolved_ref = qb_resolve_var_name(env, id, res_buf, sizeof(res_buf));
                    strncpy(arg_refs[*arg_count], resolved_ref, 63);
                } else {
                    *p = save_par;
                }
            } else if (**p == ',' || **p == ')' || **p == ':' || **p == '\0' || **p == '\'') {
                char res_buf[128];
                const char *resolved_ref = qb_resolve_var_name(env, id, res_buf, sizeof(res_buf));
                strncpy(arg_refs[*arg_count], resolved_ref, 63);
            }
            *p = save_arg;
        }

        args[*arg_count] = qb_eval_expression(env, p);
        (*arg_count)++;
        skip_whitespace(p);
        if (**p == ',') (*p)++;
        else break;
    }
}

static bool parse_lvalue(const char **p, QB_Env *env, QB_LValue *lval) {
    skip_whitespace(p);
    if (!isalpha((unsigned char)**p) && **p != '_') return false;
    memset(lval, 0, sizeof(*lval));

    char base[64] = {0};
    int idx = 0;
    while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '!' || **p == '#') && idx < 63) {
        base[idx++] = *(*p)++;
        if ((*p)[-1] == '$' || (*p)[-1] == '%' || (*p)[-1] == '&' || (*p)[-1] == '!' || (*p)[-1] == '#') break;
    }
    base[idx] = '\0';
    skip_whitespace(p);

    bool is_arr = false;
    int dims = 0;
    int indices[QB_MAX_DIMS] = {0};

    if (**p == '(') {
        (*p)++;
        is_arr = true;
        skip_whitespace(p);
        while (**p && **p != ')' && dims < QB_MAX_DIMS) {
            QB_Value iv = eval_expr_logical(env, p);
            indices[dims++] = (int)iv.number;
            qb_val_free(&iv);
            skip_whitespace(p);
            if (**p == ',') {
                (*p)++;
                skip_whitespace(p);
            } else {
                break;
            }
        }
        if (**p == ')') (*p)++;
        skip_whitespace(p);
    }

    char res_buf[128];
    const char *resolved_base = qb_resolve_var_name(env, base, res_buf, sizeof(res_buf));

    if (**p == '.') {
        (*p)++;
        char field[64] = {0};
        int fidx = 0;
        while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '!' || **p == '#') && fidx < 63) {
            field[fidx++] = *(*p)++;
        }
        field[fidx] = '\0';
        snprintf(lval->name, sizeof(lval->name), "%s.%s", resolved_base, field);
    } else {
        snprintf(lval->name, sizeof(lval->name), "%s", resolved_base);
    }

    lval->is_array = is_arr;
    lval->dims = dims;
    for (int d = 0; d < dims && d < QB_MAX_DIMS; d++) {
        lval->indices[d] = indices[d];
    }
    return true;
}

static QB_Value lval_get(QB_LValue *lval, QB_Env *env) {
    if (lval->is_array) {
        return qb_array_get(env, lval->name, lval->dims, lval->indices);
    }
    return qb_env_get(env, lval->name);
}

static void lval_set(QB_LValue *lval, QB_Env *env, QB_Value val) {
    if (lval->is_array) {
        if (!qb_array_set(env, lval->name, lval->dims, lval->indices, val)) {
            QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
            if (interp) qb_trigger_error(interp, 9);
        }
    } else {
        qb_env_set(env, lval->name, val);
    }
}

static QB_Value eval_primary(QB_Env *env, const char **p) {
    skip_whitespace(p);

    // Parenthèses
    if (**p == '(') {
        (*p)++;
        QB_Value v = eval_expr_logical(env, p);
        skip_whitespace(p);
        if (**p == ')') (*p)++;
        return v;
    }

    // Nombre négatif ou positif unaire
    if (**p == '-') {
        (*p)++;
        QB_Value v = eval_primary(env, p);
        if (v.type == QB_VAL_NUMBER) v.number = -v.number;
        return v;
    }
    if (**p == '+') {
        (*p)++;
        return eval_primary(env, p);
    }

    // Littéral chaîne entre guillemets "..."
    if (**p == '"') {
        (*p)++;
        char buf[1024];
        int idx = 0;
        while (**p && **p != '"' && idx < (int)sizeof(buf) - 1) {
            buf[idx++] = *(*p)++;
        }
        if (**p == '"') (*p)++;
        buf[idx] = '\0';
        return qb_val_string(buf);
    }

    // Littéral hexadécimal (&H...) ou octal (&O...)
    if (**p == '&' && (toupper((unsigned char)(*p)[1]) == 'H')) {
        *p += 2;
        char *endptr;
        long long h = strtoll(*p, &endptr, 16);
        *p = endptr;
        return qb_val_number((double)h);
    }

    // Littéral numérique (entier ou flottant)
    if (isdigit((unsigned char)**p) || (**p == '.' && isdigit((unsigned char)(*p)[1]))) {
        char *endptr;
        double d = strtod(*p, &endptr);
        *p = endptr;
        if (**p == '%' || **p == '&' || **p == '!' || **p == '#') {
            (*p)++;
        }
        return qb_val_number(d);
    }

    // Identifiant (variable, tableau ou fonction)
    if (isalpha((unsigned char)**p) || **p == '_') {
        char id[64];
        int idx = 0;
        while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '!' || **p == '#') && idx < 63) {
            id[idx++] = *(*p)++;
            if ((*p)[-1] == '$' || (*p)[-1] == '%' || (*p)[-1] == '&' || (*p)[-1] == '!' || (*p)[-1] == '#') {
                break;
            }
        }
        id[idx] = '\0';

        // Constantes / Fonctions sans parenthèses
        if (strcasecmp(id, "TIMER") == 0) {
            return qb_val_number(qb_timer());
        }
        if (strcasecmp(id, "INKEY$") == 0) {
            int klen = 0;
            const char *k = qb_inkey_ex(&klen);
            if (klen == 2) {
                return qb_val_string_len(k, 2);
            }
            if (klen == 1) {
                return qb_val_string_len(k, 1);
            }
            return qb_val_string("");
        }
        if (strcasecmp(id, "DATE$") == 0) {
            time_t rawtime;
            time(&rawtime);
            struct tm *ti = localtime(&rawtime);
            char buf[32];
            snprintf(buf, sizeof(buf), "%02d-%02d-%04d", ti ? ti->tm_mon + 1 : 1, ti ? ti->tm_mday : 1, ti ? ti->tm_year + 1900 : 2026);
            return qb_val_string(buf);
        }
        if (strcasecmp(id, "TIME$") == 0) {
            time_t rawtime;
            time(&rawtime);
            struct tm *ti = localtime(&rawtime);
            char buf[32];
            snprintf(buf, sizeof(buf), "%02d:%02d:%02d", ti ? ti->tm_hour : 0, ti ? ti->tm_min : 0, ti ? ti->tm_sec : 0);
            return qb_val_string(buf);
        }
        if (strcasecmp(id, "ERR") == 0) {
            QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
            return qb_val_number(interp ? (double)interp->err_code : 0.0);
        }
        if (strcasecmp(id, "ERL") == 0) {
            QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
            return qb_val_number(interp ? (double)interp->err_line : 0.0);
        }
        if (strcasecmp(id, "FREEFILE") == 0) {
            skip_whitespace(p);
            if (**p == '(') {
                (*p)++;
                skip_whitespace(p);
                if (**p == ')') (*p)++;
            }
            QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
            int free_num = 1;
            if (interp) {
                for (int i = 1; i <= 255; i++) {
                    if (!interp->files[i]) {
                        free_num = i;
                        break;
                    }
                }
            }
            return qb_val_number((double)free_num);
        }
        if (strcasecmp(id, "RND") == 0) {
            skip_whitespace(p);
            if (**p == '(') {
                (*p)++;
                QB_Value dummy = eval_expr_logical(env, p);
                qb_val_free(&dummy);
                skip_whitespace(p);
                if (**p == ')') (*p)++;
            }
            return qb_val_number((double)rand() / (double)RAND_MAX);
        }

        skip_whitespace(p);

        // Appel de fonction ou élément de tableau avec (...)
        if (**p == '(') {
            (*p)++;
            skip_whitespace(p);
            QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
            if (**p == ')') {
                (*p)++;
                if (interp) {
                    for (int pi = 0; pi < interp->proc_count; pi++) {
                        if (interp->procs[pi].is_function && qb_proc_name_match(interp->procs[pi].name, id) && interp->procs[pi].param_count == 0) {
                            return execute_function(interp, pi, NULL, 0, NULL);
                        }
                    }
                }
                return qb_val_string(id);
            }

            QB_Value fargs[16];
            char farg_refs[16][64];
            int farg_cnt = 0;
            memset(fargs, 0, sizeof(fargs));
            memset(farg_refs, 0, sizeof(farg_refs));

            while (**p && **p != ')' && farg_cnt < 16) {
                skip_whitespace(p);
                if (**p == '#') (*p)++;
                skip_whitespace(p);
                const char *save_arg = *p;
                if (isalpha((unsigned char)**p) || **p == '_') {
                    char rid[64] = {0};
                    int ridi = 0;
                    while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '#' || **p == '!') && ridi < 63) {
                        rid[ridi++] = *(*p)++;
                    }
                    rid[ridi] = '\0';
                    skip_whitespace(p);
                    if (**p == '(') {
                        const char *sp2 = *p;
                        (*p)++;
                        skip_whitespace(p);
                        if (**p == ')') {
                            (*p)++;
                            strncpy(farg_refs[farg_cnt], rid, 63);
                        } else {
                            *p = sp2;
                        }
                    } else if (**p == ',' || **p == ')') {
                        strncpy(farg_refs[farg_cnt], rid, 63);
                    }
                    *p = save_arg;
                }
                fargs[farg_cnt++] = eval_expr_logical(env, p);
                skip_whitespace(p);
                if (**p == ',') (*p)++;
                else break;
            }
            if (**p == ')') (*p)++;

            QB_Value arg1 = farg_cnt > 0 ? fargs[0] : qb_val_null();
            QB_Value arg2 = farg_cnt > 1 ? fargs[1] : qb_val_null();
            QB_Value arg3 = farg_cnt > 2 ? fargs[2] : qb_val_null();
            bool has_arg2 = (farg_cnt > 1);

            // Accès au champ d'enregistrement arr(idx).champ
            char res_buf[128];
            const char *resolved_id = qb_resolve_var_name(env, id, res_buf, sizeof(res_buf));

            skip_whitespace(p);
            if (**p == '.') {
                (*p)++;
                char field[64] = {0};
                int fidx = 0;
                while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '!' || **p == '#') && fidx < 63) {
                    field[fidx++] = *(*p)++;
                }
                field[fidx] = '\0';
                char comp[128];
                snprintf(comp, sizeof(comp), "%s.%s", resolved_id, field);
                int indices[16];
                for (int fi = 0; fi < farg_cnt && fi < 16; fi++) indices[fi] = (int)fargs[fi].number;
                QB_Value arr_val = qb_array_get(env, comp, farg_cnt, indices);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return arr_val;
            }

            // 1. Accès à un tableau standard (DIM)
            if (qb_array_exists(env, resolved_id)) {
                int indices[16];
                for (int fi = 0; fi < farg_cnt && fi < 16; fi++) indices[fi] = (int)fargs[fi].number;
                QB_Value arr_val = qb_array_get(env, resolved_id, farg_cnt, indices);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return arr_val;
            } else if (qb_array_exists(env, id)) {
                int indices[16];
                for (int fi = 0; fi < farg_cnt && fi < 16; fi++) indices[fi] = (int)fargs[fi].number;
                QB_Value arr_val = qb_array_get(env, id, farg_cnt, indices);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return arr_val;
            }

            // Fonctions événementielles : PLAY(0) et KEY$(n)
            if (strcasecmp(id, "PLAY") == 0) {
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number((double)qb_play_get_notes_remaining());
            }
            if (strcasecmp(id, "KEY$") == 0) {
                int kn = (int)arg1.number;
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
                if (interp && kn >= 1 && kn < 32) {
                    return qb_val_string(interp->key_defs[kn]);
                }
                return qb_val_string("");
            }

            // Fonctions graphiques et mémoire : POINT & PEEK
            if (strcasecmp(id, "POINT") == 0) {
                int px = (int)arg1.number;
                int py = has_arg2 ? (int)arg2.number : 0;
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                qb_val_free(&arg3);
                return qb_val_number((double)qb_point(px, py));
            }
            if (strcasecmp(id, "PEEK") == 0) {
                int addr = (int)arg1.number;
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                qb_val_free(&arg3);
                if (addr == 1047) return qb_val_number(32.0); // NumLock ON
                return qb_val_number(0.0);
            }

            // 2. Fonctions de tableau : LBOUND / UBOUND
            if (strcasecmp(id, "LBOUND") == 0) {
                const char *arr_name = (farg_refs[0][0]) ? farg_refs[0] : id;
                int dim = has_arg2 ? (int)arg2.number : 1;
                int lb = qb_array_lbound(env, arr_name, dim);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                return qb_val_number((double)lb);
            }
            if (strcasecmp(id, "UBOUND") == 0) {
                const char *arr_name = (farg_refs[0][0]) ? farg_refs[0] : id;
                int dim = has_arg2 ? (int)arg2.number : 1;
                int ub = qb_array_ubound(env, arr_name, dim);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                return qb_val_number((double)ub);
            }

            // 3. Fonctions mathématiques
            if (strcasecmp(id, "INT") == 0) {
                double res = floor(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "FIX") == 0) {
                double res = (arg1.number >= 0) ? floor(arg1.number) : ceil(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "CINT") == 0 || strcasecmp(id, "CLNG") == 0) {
                double val = (arg1.type == QB_VAL_NUMBER) ? arg1.number : (arg1.string ? atof(arg1.string) : 0.0);
                double res = round(val);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "CSNG") == 0 || strcasecmp(id, "CDBL") == 0) {
                double val = (arg1.type == QB_VAL_NUMBER) ? arg1.number : (arg1.string ? atof(arg1.string) : 0.0);
                qb_val_free(&arg1);
                return qb_val_number(val);
            }
            if (strcasecmp(id, "SGN") == 0) {
                double val = (arg1.type == QB_VAL_NUMBER) ? arg1.number : 0.0;
                double res = (val > 0) ? 1.0 : ((val < 0) ? -1.0 : 0.0);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "ABS") == 0) {
                double res = fabs(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "SQR") == 0) {
                double res = (arg1.number >= 0) ? sqrt(arg1.number) : 0;
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "SIN") == 0) {
                double res = sin(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "COS") == 0) {
                double res = cos(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "TAN") == 0) {
                double res = tan(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "ATN") == 0) {
                double res = atan(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "LOG") == 0) {
                double res = (arg1.number > 0) ? log(arg1.number) : 0;
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "EXP") == 0) {
                double res = exp(arg1.number);
                qb_val_free(&arg1);
                return qb_val_number(res);
            }

            // 4. Fonctions de chaînes
            if (strcasecmp(id, "LEN") == 0) {
                double res = (arg1.type == QB_VAL_STRING && arg1.string) ? (double)arg1.string_len : 0;
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "CHR$") == 0) {
                char ch[2] = { (char)(int)arg1.number, '\0' };
                qb_val_free(&arg1);
                return qb_val_string_len(ch, 1);
            }
            if (strcasecmp(id, "ASC") == 0) {
                double res = (arg1.type == QB_VAL_STRING && arg1.string && arg1.string_len > 0) ? (double)(unsigned char)arg1.string[0] : 0;
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "STR$") == 0) {
                char sbuf[64];
                snprintf(sbuf, sizeof(sbuf), "%g", arg1.number);
                qb_val_free(&arg1);
                return qb_val_string(sbuf);
            }
            if (strcasecmp(id, "VAL") == 0) {
                double res = (arg1.type == QB_VAL_STRING && arg1.string) ? atof(arg1.string) : 0;
                qb_val_free(&arg1);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "SPACE$") == 0) {
                int count = (int)arg1.number;
                if (count < 0) count = 0;
                char *s = (char*)malloc(count + 1);
                memset(s, ' ', count);
                s[count] = '\0';
                qb_val_free(&arg1);
                QB_Value ret = qb_val_string(s);
                free(s);
                return ret;
            }
            if (strcasecmp(id, "STRING$") == 0) {
                int count = (int)arg1.number;
                if (count < 0) count = 0;
                char fill = (arg2.type == QB_VAL_STRING && arg2.string && arg2.string[0]) ? arg2.string[0] : (char)(int)arg2.number;
                char *s = (char*)malloc(count + 1);
                memset(s, fill, count);
                s[count] = '\0';
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                QB_Value ret = qb_val_string(s);
                free(s);
                return ret;
            }
            if (strcasecmp(id, "UCASE$") == 0) {
                if (arg1.type == QB_VAL_STRING && arg1.string) {
                    int len = arg1.string_len;
                    char *dup = (char*)malloc(len + 1);
                    for (int ci = 0; ci < len; ci++) dup[ci] = (char)toupper((unsigned char)arg1.string[ci]);
                    dup[len] = '\0';
                    qb_val_free(&arg1);
                    QB_Value ret = qb_val_string_len(dup, len);
                    free(dup);
                    return ret;
                }
                qb_val_free(&arg1);
                return qb_val_string("");
            }
            if (strcasecmp(id, "LCASE$") == 0) {
                if (arg1.type == QB_VAL_STRING && arg1.string) {
                    int len = arg1.string_len;
                    char *dup = (char*)malloc(len + 1);
                    for (int ci = 0; ci < len; ci++) dup[ci] = (char)tolower((unsigned char)arg1.string[ci]);
                    dup[len] = '\0';
                    qb_val_free(&arg1);
                    QB_Value ret = qb_val_string_len(dup, len);
                    free(dup);
                    return ret;
                }
                qb_val_free(&arg1);
                return qb_val_string("");
            }
            if (strcasecmp(id, "LEFT$") == 0) {
                const char *src = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                int len = (arg1.type == QB_VAL_STRING) ? arg1.string_len : 0;
                int count = (int)arg2.number;
                if (count < 0) count = 0;
                if (count > len) count = len;
                QB_Value ret = qb_val_string_len(src, count);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                return ret;
            }
            if (strcasecmp(id, "RIGHT$") == 0) {
                const char *src = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                int len = (arg1.type == QB_VAL_STRING) ? arg1.string_len : 0;
                int count = (int)arg2.number;
                if (count < 0) count = 0;
                if (count > len) count = len;
                const char *start = src + (len - count);
                QB_Value ret = qb_val_string_len(start, count);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                return ret;
            }
            if (strcasecmp(id, "MID$") == 0) {
                const char *src = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                int len = (arg1.type == QB_VAL_STRING) ? arg1.string_len : 0;
                int start = (int)arg2.number - 1;
                if (start < 0) start = 0;
                if (start >= len) {
                    qb_val_free(&arg1);
                    qb_val_free(&arg2);
                    qb_val_free(&arg3);
                    return qb_val_string("");
                }
                int count = (arg3.type == QB_VAL_NUMBER) ? (int)arg3.number : (len - start);
                if (count < 0) count = 0;
                if (start + count > len) count = len - start;
                QB_Value ret = qb_val_string_len(src + start, count);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                qb_val_free(&arg3);
                return ret;
            }

            if (strcasecmp(id, "SGN") == 0) {
                double res = (arg1.number > 0) ? 1.0 : ((arg1.number < 0) ? -1.0 : 0.0);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                qb_val_free(&arg3);
                return qb_val_number(res);
            }
            if (strcasecmp(id, "HEX$") == 0) {
                char buf[32];
                snprintf(buf, sizeof(buf), "%X", (unsigned int)(long long)arg1.number);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                qb_val_free(&arg3);
                return qb_val_string(buf);
            }
            if (strcasecmp(id, "OCT$") == 0) {
                char buf[32];
                snprintf(buf, sizeof(buf), "%o", (unsigned int)(long long)arg1.number);
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                qb_val_free(&arg3);
                return qb_val_string(buf);
            }
            if (strcasecmp(id, "INSTR") == 0) {
                const char *str1 = "";
                const char *str2 = "";
                int start_idx = 1;
                if (has_arg2) {
                    if (arg3.type != QB_VAL_NULL) {
                        start_idx = (int)arg1.number;
                        str1 = (arg2.type == QB_VAL_STRING && arg2.string) ? arg2.string : "";
                        str2 = (arg3.type == QB_VAL_STRING && arg3.string) ? arg3.string : "";
                    } else {
                        str1 = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                        str2 = (arg2.type == QB_VAL_STRING && arg2.string) ? arg2.string : "";
                    }
                }
                int result = 0;
                if (str1 && str2 && *str2) {
                    int len1 = (int)strlen(str1);
                    if (start_idx >= 1 && start_idx <= len1) {
                        const char *found = strstr(str1 + (start_idx - 1), str2);
                        if (found) result = (int)(found - str1) + 1;
                    }
                }
                qb_val_free(&arg1);
                qb_val_free(&arg2);
                qb_val_free(&arg3);
                return qb_val_number((double)result);
            }

            if (strcasecmp(id, "INPUT$") == 0) {
                int count = (int)arg1.number;
                if (count <= 0) {
                    for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                    return qb_val_string("");
                }
                char *buf = (char*)malloc(count + 1);
                int total_len = 0;
                if (has_arg2) {
                    int fnum = (int)arg2.number;
                    if (interp && fnum >= 1 && fnum <= 255 && interp->files[fnum]) {
                        total_len = (int)fread(buf, 1, count, interp->files[fnum]);
                    }
                    buf[total_len] = '\0';
                } else {
                    const char *auto_k = getenv("QB_AUTO_KEYS");
                    static int s_auto_idx = 0;
                    if (auto_k && auto_k[s_auto_idx]) {
                        buf[0] = auto_k[s_auto_idx++];
                        buf[1] = '\0';
                        total_len = 1;
                        g_title_done = 1;
                    } else {
                        int got = 0;
                        while (got < count && (!interp || (interp->running && !interp->exit_requested))) {
                            const char *k = qb_inkey();
                            if (k && k[0]) {
                                buf[got++] = k[0];
                            } else {
                                Sleep(1);
                            }
                        }
                        buf[got] = '\0';
                        total_len = got;
                        g_title_done = 1;
                    }
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                QB_Value ret = qb_val_string_len(buf, total_len);
                free(buf);
                return ret;
            }

            if (strcasecmp(id, "LTRIM$") == 0) {
                const char *src = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                while (*src && isspace((unsigned char)*src)) src++;
                QB_Value ret = qb_val_string(src);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return ret;
            }

            if (strcasecmp(id, "RTRIM$") == 0) {
                const char *src = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                char *dup = strdup(src);
                int len = (int)strlen(dup);
                while (len > 0 && isspace((unsigned char)dup[len - 1])) {
                    dup[--len] = '\0';
                }
                QB_Value ret = qb_val_string(dup);
                free(dup);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return ret;
            }

            if (strcasecmp(id, "MKI$") == 0) {
                int16_t val = (int16_t)arg1.number;
                char b[2];
                b[0] = (char)(val & 0xFF);
                b[1] = (char)((val >> 8) & 0xFF);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_string_len(b, 2);
            }
            if (strcasecmp(id, "CVI") == 0) {
                const char *s = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                int len = (arg1.type == QB_VAL_STRING) ? arg1.string_len : 0;
                int16_t val = 0;
                if (len >= 2) {
                    val = (int16_t)(((uint8_t)s[0]) | (((uint8_t)s[1]) << 8));
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number((double)val);
            }
            if (strcasecmp(id, "MKL$") == 0) {
                int32_t val = (int32_t)arg1.number;
                char b[4];
                b[0] = (char)(val & 0xFF);
                b[1] = (char)((val >> 8) & 0xFF);
                b[2] = (char)((val >> 16) & 0xFF);
                b[3] = (char)((val >> 24) & 0xFF);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_string_len(b, 4);
            }
            if (strcasecmp(id, "CVL") == 0) {
                const char *s = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                int len = (arg1.type == QB_VAL_STRING) ? arg1.string_len : 0;
                int32_t val = 0;
                if (len >= 4) {
                    val = (int32_t)(((uint32_t)(uint8_t)s[0]) | (((uint32_t)(uint8_t)s[1]) << 8) |
                                    (((uint32_t)(uint8_t)s[2]) << 16) | (((uint32_t)(uint8_t)s[3]) << 24));
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number((double)val);
            }
            if (strcasecmp(id, "MKS$") == 0) {
                float fval = (float)arg1.number;
                char b[4];
                memcpy(b, &fval, 4);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_string_len(b, 4);
            }
            if (strcasecmp(id, "CVS") == 0) {
                const char *s = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                int len = (arg1.type == QB_VAL_STRING) ? arg1.string_len : 0;
                float fval = 0.0f;
                if (len >= 4) {
                    memcpy(&fval, s, 4);
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number((double)fval);
            }
            if (strcasecmp(id, "MKD$") == 0) {
                double dval = arg1.number;
                char b[8];
                memcpy(b, &dval, 8);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_string_len(b, 8);
            }
            if (strcasecmp(id, "CVD") == 0) {
                const char *s = (arg1.type == QB_VAL_STRING && arg1.string) ? arg1.string : "";
                int len = (arg1.type == QB_VAL_STRING) ? arg1.string_len : 0;
                double dval = 0.0;
                if (len >= 8) {
                    memcpy(&dval, s, 8);
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number(dval);
            }
            if (strcasecmp(id, "LOC") == 0) {
                int fnum = (int)arg1.number;
                double loc_val = 0.0;
                if (interp && fnum >= 1 && fnum <= 255 && interp->files[fnum]) {
                    if (interp->file_modes[fnum] == QB_FILE_MODE_RANDOM) {
                        loc_val = (double)interp->file_current_record[fnum];
                    } else if (interp->file_modes[fnum] == QB_FILE_MODE_BINARY) {
                        loc_val = (double)interp->file_last_pos[fnum];
                    } else {
                        loc_val = (double)(ftell(interp->files[fnum]) / 128);
                    }
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number(loc_val);
            }
            if (strcasecmp(id, "SEEK") == 0) {
                int fnum = (int)arg1.number;
                double seek_val = 1.0;
                if (interp && fnum >= 1 && fnum <= 255 && interp->files[fnum]) {
                    if (interp->file_modes[fnum] == QB_FILE_MODE_RANDOM) {
                        seek_val = (double)(interp->file_current_record[fnum] + 1);
                    } else {
                        seek_val = (double)(ftell(interp->files[fnum]) + 1);
                    }
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number(seek_val);
            }

            if (strcasecmp(id, "LOF") == 0) {
                int fnum = (int)arg1.number;
                double size = 0.0;
                if (interp && fnum >= 1 && fnum <= 255 && interp->files[fnum]) {
                    FILE *f = interp->files[fnum];
                    long cur = ftell(f);
                    fseek(f, 0, SEEK_END);
                    size = (double)ftell(f);
                    fseek(f, cur, SEEK_SET);
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number(size);
            }

            if (strcasecmp(id, "EOF") == 0) {
                int fnum = (int)arg1.number;
                double eof_val = 0.0;
                if (interp && fnum >= 1 && fnum <= 255 && interp->files[fnum]) {
                    const char *b = interp->file_buf[fnum] + interp->file_buf_pos[fnum];
                    while (*b && (isspace((unsigned char)*b) || *b == ',')) b++;
                    if (*b) {
                        eof_val = 0.0;
                    } else {
                        FILE *f = interp->files[fnum];
                        if (feof(f)) {
                            eof_val = -1.0;
                        } else {
                            int ch = fgetc(f);
                            if (ch == EOF) {
                                eof_val = -1.0;
                            } else {
                                ungetc(ch, f);
                                eof_val = 0.0;
                            }
                        }
                    }
                } else {
                    eof_val = -1.0;
                }
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number(eof_val);
            }

            if (strcasecmp(id, "INP") == 0) {
                int port = (int)arg1.number;
                int val = qb_inp_port(port);
                for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                return qb_val_number((double)val);
            }

            // Fonctions utilisateur personnalisées (FUNCTION id(args))
            if (interp) {
                for (int pi = 0; pi < interp->proc_count; pi++) {
                    if (interp->procs[pi].is_function && qb_proc_name_match(interp->procs[pi].name, id)) {
                        QB_Value fn_res = execute_function(interp, pi, fargs, farg_cnt, (const char (*)[64])farg_refs);
                        for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                        return fn_res;
                    }
                }
                for (int k = 0; k < interp->def_fn_count; k++) {
                    if (strcasecmp(interp->def_fns[k].name, id) == 0 ||
                        qb_proc_name_match(interp->def_fns[k].name, id)) {
                        QB_Value saved_p[8];
                        for (int pi = 0; pi < interp->def_fns[k].param_count; pi++) {
                            saved_p[pi] = qb_env_get(env, interp->def_fns[k].params[pi]);
                            QB_Value arg_val = pi < farg_cnt ? fargs[pi] : qb_val_null();
                            qb_env_set(env, interp->def_fns[k].params[pi], arg_val);
                        }
                        int saved_call_sp = interp->call_sp;
                        interp->call_sp = 0;
                        const char *ep = interp->def_fns[k].expr;
                        QB_Value fn_val = qb_eval_expression(env, &ep);
                        interp->call_sp = saved_call_sp;
                        for (int pi = 0; pi < interp->def_fns[k].param_count; pi++) {
                            qb_env_set(env, interp->def_fns[k].params[pi], saved_p[pi]);
                            qb_val_free(&saved_p[pi]);
                        }
                        for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
                        return fn_val;
                    }
                }
            }

            for (int fi = 0; fi < farg_cnt; fi++) qb_val_free(&fargs[fi]);
        }

        // Fonction personnalisée sans parenthèses (ex: x = MaFonction)
        QB_Interpreter *interp_noparen = (QB_Interpreter*)env->user_data;
        if (interp_noparen) {
            for (int pi = 0; pi < interp_noparen->proc_count; pi++) {
                if (interp_noparen->procs[pi].is_function && qb_proc_name_match(interp_noparen->procs[pi].name, id) && interp_noparen->procs[pi].param_count == 0) {
                    return execute_function(interp_noparen, pi, NULL, 0, NULL);
                }
            }
        }

        // Accès à un champ scalaire d'enregistrement (ex: GSettings.forceCGA)
        char res_buf[128];
        const char *resolved_id = qb_resolve_var_name(env, id, res_buf, sizeof(res_buf));

        skip_whitespace(p);
        if (**p == '.') {
            (*p)++;
            char field[64] = {0};
            int fidx = 0;
            while ((isalnum((unsigned char)**p) || **p == '_' || **p == '$' || **p == '%' || **p == '&' || **p == '!' || **p == '#') && fidx < 63) {
                field[fidx++] = *(*p)++;
            }
            field[fidx] = '\0';
            char comp[128];
            snprintf(comp, sizeof(comp), "%s.%s", resolved_id, field);
            return qb_env_get(env, comp);
        }

        return qb_env_get(env, resolved_id);
    }

    return qb_val_number(0);
}

static QB_Value eval_power(QB_Env *env, const char **p) {
    QB_Value left = eval_primary(env, p);
    skip_whitespace(p);
    if (**p == '^') {
        (*p)++;
        QB_Value right = eval_power(env, p);
        if (left.type == QB_VAL_NUMBER && right.type == QB_VAL_NUMBER) {
            left.number = pow(left.number, right.number);
        }
        qb_val_free(&right);
    }
    return left;
}

static QB_Value eval_multiplicative(QB_Env *env, const char **p) {
    QB_Value left = eval_power(env, p);
    while (true) {
        skip_whitespace(p);
        if (**p == '*') {
            (*p)++;
            QB_Value right = eval_power(env, p);
            if (left.type == QB_VAL_NUMBER && right.type == QB_VAL_NUMBER) {
                left.number *= right.number;
            }
            qb_val_free(&right);
        } else if (**p == '/') {
            (*p)++;
            QB_Value right = eval_power(env, p);
            if (left.type == QB_VAL_NUMBER && right.type == QB_VAL_NUMBER) {
                if (right.number == 0.0) {
                    QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
                    if (interp) qb_trigger_error(interp, 11);
                    left.number = 0.0;
                } else {
                    left.number = left.number / right.number;
                }
            }
            qb_val_free(&right);
        } else if (**p == '\\') {
            (*p)++;
            QB_Value right = eval_power(env, p);
            if (left.type == QB_VAL_NUMBER && right.type == QB_VAL_NUMBER) {
                long long l = (long long)left.number;
                long long r = (long long)right.number;
                if (r == 0) {
                    QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
                    if (interp) qb_trigger_error(interp, 11);
                    left.number = 0.0;
                } else {
                    left.number = (double)(l / r);
                }
            }
            qb_val_free(&right);
        } else if (match_keyword(p, "MOD")) {
            QB_Value right = eval_power(env, p);
            if (left.type == QB_VAL_NUMBER && right.type == QB_VAL_NUMBER) {
                long long l = (long long)left.number;
                long long r = (long long)right.number;
                if (r == 0) {
                    QB_Interpreter *interp = (QB_Interpreter*)env->user_data;
                    if (interp) qb_trigger_error(interp, 11);
                    left.number = 0.0;
                } else {
                    left.number = (double)(l % r);
                }
            }
            qb_val_free(&right);
        } else {
            break;
        }
    }
    return left;
}

static QB_Value eval_additive(QB_Env *env, const char **p) {
    QB_Value left = eval_multiplicative(env, p);
    while (true) {
        skip_whitespace(p);
        if (**p == '+') {
            (*p)++;
            QB_Value right = eval_multiplicative(env, p);
            if (left.type == QB_VAL_NUMBER && right.type == QB_VAL_NUMBER) {
                left.number += right.number;
            } else if (left.type == QB_VAL_STRING || right.type == QB_VAL_STRING) {
                const char *s1 = (left.type == QB_VAL_STRING && left.string) ? left.string : "";
                const char *s2 = (right.type == QB_VAL_STRING && right.string) ? right.string : "";
                int l1 = left.string_len;
                int l2 = right.string_len;
                char *cat = (char*)malloc(l1 + l2 + 1);
                if (l1 > 0) memcpy(cat, s1, l1);
                if (l2 > 0) memcpy(cat + l1, s2, l2);
                cat[l1 + l2] = '\0';
                qb_val_free(&left);
                left = qb_val_string_len(cat, l1 + l2);
                free(cat);
            }
            qb_val_free(&right);
        } else if (**p == '-') {
            (*p)++;
            QB_Value right = eval_multiplicative(env, p);
            if (left.type == QB_VAL_NUMBER && right.type == QB_VAL_NUMBER) {
                left.number -= right.number;
            }
            qb_val_free(&right);
        } else {
            break;
        }
    }
    return left;
}

static int qb_string_compare(const QB_Value *v1, const QB_Value *v2) {
    const char *s1 = (v1->type == QB_VAL_STRING && v1->string) ? v1->string : "";
    const char *s2 = (v2->type == QB_VAL_STRING && v2->string) ? v2->string : "";
    int l1 = (v1->type == QB_VAL_STRING) ? v1->string_len : 0;
    int l2 = (v2->type == QB_VAL_STRING) ? v2->string_len : 0;
    int min_l = l1 < l2 ? l1 : l2;
    int cmp = memcmp(s1, s2, min_l);
    if (cmp == 0) cmp = l1 - l2;
    return cmp;
}

static QB_Value eval_relational(QB_Env *env, const char **p) {
    QB_Value left = eval_additive(env, p);
    skip_whitespace(p);

    if (match_symbol(p, "<>")) {
        QB_Value right = eval_additive(env, p);
        bool res = false;
        if (left.type == QB_VAL_STRING && right.type == QB_VAL_STRING) {
            res = (qb_string_compare(&left, &right) != 0);
        } else {
            res = (left.number != right.number);
        }
        qb_val_free(&left);
        qb_val_free(&right);
        return qb_val_number(res ? -1 : 0);
    }
    if (match_symbol(p, "<=")) {
        QB_Value right = eval_additive(env, p);
        bool res = false;
        if (left.type == QB_VAL_STRING && right.type == QB_VAL_STRING) {
            res = (qb_string_compare(&left, &right) <= 0);
        } else {
            res = (left.number <= right.number);
        }
        qb_val_free(&left);
        qb_val_free(&right);
        return qb_val_number(res ? -1 : 0);
    }
    if (match_symbol(p, ">=")) {
        QB_Value right = eval_additive(env, p);
        bool res = false;
        if (left.type == QB_VAL_STRING && right.type == QB_VAL_STRING) {
            res = (qb_string_compare(&left, &right) >= 0);
        } else {
            res = (left.number >= right.number);
        }
        qb_val_free(&left);
        qb_val_free(&right);
        return qb_val_number(res ? -1 : 0);
    }
    if (match_symbol(p, "<")) {
        QB_Value right = eval_additive(env, p);
        bool res = false;
        if (left.type == QB_VAL_STRING && right.type == QB_VAL_STRING) {
            res = (qb_string_compare(&left, &right) < 0);
        } else {
            res = (left.number < right.number);
        }
        qb_val_free(&left);
        qb_val_free(&right);
        return qb_val_number(res ? -1 : 0);
    }
    if (match_symbol(p, ">")) {
        QB_Value right = eval_additive(env, p);
        bool res = false;
        if (left.type == QB_VAL_STRING && right.type == QB_VAL_STRING) {
            res = (qb_string_compare(&left, &right) > 0);
        } else {
            res = (left.number > right.number);
        }
        qb_val_free(&left);
        qb_val_free(&right);
        return qb_val_number(res ? -1 : 0);
    }
    if (match_symbol(p, "=")) {
        QB_Value right = eval_additive(env, p);
        bool res = false;
        if (left.type == QB_VAL_STRING && right.type == QB_VAL_STRING) {
            res = (qb_string_compare(&left, &right) == 0);
        } else {
            res = (left.number == right.number);
        }
        qb_val_free(&left);
        qb_val_free(&right);
        return qb_val_number(res ? -1 : 0);
    }

    return left;
}

static QB_Value eval_logical_factor(QB_Env *env, const char **p) {
    skip_whitespace(p);
    if (match_keyword(p, "NOT")) {
        QB_Value sub = eval_logical_factor(env, p);
        long long val = (long long)sub.number;
        qb_val_free(&sub);
        return qb_val_number((double)(~val));
    }
    return eval_relational(env, p);
}

static QB_Value eval_expr_logical(QB_Env *env, const char **p) {
    QB_Value left = eval_logical_factor(env, p);
    while (true) {
        skip_whitespace(p);
        if (match_keyword(p, "AND")) {
            QB_Value right = eval_logical_factor(env, p);
            long long l = (long long)left.number;
            long long r = (long long)right.number;
            left.number = (double)(l & r);
            qb_val_free(&right);
        } else if (match_keyword(p, "OR")) {
            QB_Value right = eval_logical_factor(env, p);
            long long l = (long long)left.number;
            long long r = (long long)right.number;
            left.number = (double)(l | r);
            qb_val_free(&right);
        } else if (match_keyword(p, "XOR")) {
            QB_Value right = eval_logical_factor(env, p);
            long long l = (long long)left.number;
            long long r = (long long)right.number;
            left.number = (double)(l ^ r);
            qb_val_free(&right);
        } else {
            break;
        }
    }
    return left;
}

QB_Value qb_eval_expression(QB_Env *env, const char **expr_ptr) {
    return eval_expr_logical(env, expr_ptr);
}

// GESTION DU PROGRAMME
QB_Program* qb_program_create(void) {
    QB_Program *prog = (QB_Program*)calloc(1, sizeof(QB_Program));
    prog->capacity = 64;
    prog->lines = (char**)calloc(prog->capacity, sizeof(char*));
    return prog;
}

void qb_program_free(QB_Program *prog) {
    if (!prog) return;
    for (int i = 0; i < prog->line_count; i++) {
        free(prog->lines[i]);
    }
    free(prog->lines);
    free(prog);
}

static void add_single_line(QB_Program *prog, const char *line) {
    if (prog->line_count >= prog->capacity) {
        prog->capacity *= 2;
        prog->lines = (char**)realloc(prog->lines, prog->capacity * sizeof(char*));
    }
    prog->lines[prog->line_count++] = strdup(line ? line : "");
}

static bool is_basic_keyword(const char *s) {
    if (!s || !*s) return false;
    static const char *kw[] = {
        "CLS", "END", "RETURN", "SYSTEM", "BEEP", "CLEAR", "RESTORE", "ERASE",
        "STOP", "RESUME", "PCOPY", "RANDOMIZE", "SCREEN", "WIDTH", "COLOR",
        "LOCATE", "VIEW", "WINDOW", "PALETTE", "FILES", "SLEEP", "NEXT", "LOOP",
        "WEND", "ELSE", "DO", "FOR", "WHILE", "IF", "SELECT", "SUB", "FUNCTION",
        "TYPE", "DEF", "DIM", "REDIM", "COMMON", "SHARED", "STATIC", "CONST",
        "DATA", "READ", "PRINT", "INPUT", "LINE", "OPEN", "CLOSE", "GET", "PUT",
        "SEEK", "KILL", "NAME", "MKDIR", "RMDIR", "CHDIR", "OUT", "WAIT", "POKE",
        "CALL", "GOTO", "GOSUB", "EXIT", "PLAY", "SOUND", "DRAW", "PAINT", "CIRCLE",
        "PSET", "PRESET", "BSAVE", "BLOAD", "TROFF", "TRON", "FIELD", "LPRINT",
        "THEN", "TO", "STEP", "AS", "USING", "TAB", "SPC", "CASE", "ON", NULL
    };
    for (int i = 0; kw[i]; i++) {
        if (strcasecmp(s, kw[i]) == 0) return true;
    }
    return false;
}

static bool is_valid_label_name(const char *s) {
    if (!s || !*s) return false;
    while (isdigit((unsigned char)*s)) s++;
    while (*s && isspace((unsigned char)*s)) s++;
    if (!*s) return false;
    if (!isalpha((unsigned char)*s) && *s != '_') return false;
    while (*s) {
        if (!isalnum((unsigned char)*s) && *s != '_') return false;
        s++;
    }
    return true;
}

void qb_program_add_line(QB_Program *prog, const char *line) {
    if (!line) {
        add_single_line(prog, "");
        return;
    }

    const char *p = line;
    while (*p && isspace((unsigned char)*p)) p++;
    if (!*p) {
        add_single_line(prog, "");
        return;
    }

    // Ligne de commentaire direct : ne pas découper
    if (*p == '\'' || strncasecmp(p, "REM ", 4) == 0 || strcasecmp(p, "REM") == 0) {
        add_single_line(prog, line);
        return;
    }

    // Vérifier si c'est un IF mono-ligne (ex: IF c THEN s1 : s2)
    // Pour les IF mono-lignes, on conserve la ligne entière
    const char *chk = p;
    if (isdigit((unsigned char)*chk)) {
        while (isdigit((unsigned char)*chk)) chk++;
        while (*chk && isspace((unsigned char)*chk)) chk++;
    }
    if (strncasecmp(chk, "IF", 2) == 0 && (isspace((unsigned char)chk[2]) || chk[2] == '(')) {
        bool in_q = false;
        const char *s = chk;
        bool has_single_line_then = false;
        while (*s) {
            if (*s == '"') in_q = !in_q;
            else if (!in_q && *s == '\'') break;
            else if (!in_q && strncasecmp(s, "THEN", 4) == 0 && (isspace((unsigned char)s[4]) || s[4] == '\0')) {
                const char *after_then = s + 4;
                while (*after_then && isspace((unsigned char)*after_then)) after_then++;
                if (*after_then && *after_then != '\'') {
                    has_single_line_then = true;
                    break;
                }
            }
            s++;
        }
        if (has_single_line_then) {
            add_single_line(prog, line);
            return;
        }
    }

    // Si c'est une boucle d'attente FOR...NEXT sur une seule ligne (ex: FOR t2 = 0 TO 8000 STEP .5: NEXT t2)
    if (strncasecmp(chk, "FOR", 3) == 0 && isspace((unsigned char)chk[3])) {
        const char *next_ptr = find_keyword_caseless(chk, "NEXT");
        if (next_ptr) {
            const char *colon = strchr(chk, ':');
            if (colon && colon < next_ptr) {
                const char *after_colon = colon + 1;
                while (*after_colon && isspace((unsigned char)*after_colon)) after_colon++;
                if (strncasecmp(after_colon, "NEXT", 4) == 0) {
                    add_single_line(prog, line);
                    return;
                }
            }
        }
    }

    // Découper la ligne par les ':' situés hors des guillemets et des commentaires
    char stmt[2048];
    int si = 0;
    bool in_quotes = false;
    const char *curr = line;

    while (*curr) {
        char c = *curr;
        if (c == '"') {
            in_quotes = !in_quotes;
            stmt[si++] = c;
            curr++;
        } else if (!in_quotes && (c == '\'' || (c == 'R' && strncasecmp(curr, "REM ", 4) == 0) || strcasecmp(curr, "REM") == 0)) {
            while (*curr) {
                if (si < 2046) stmt[si++] = *curr++;
                else curr++;
            }
            break;
        } else if (!in_quotes && c == ':') {
            stmt[si] = '\0';
            char *start = stmt;
            while (*start && isspace((unsigned char)*start)) start++;
            int end = (int)strlen(start);
            while (end > 0 && isspace((unsigned char)start[end - 1])) start[--end] = '\0';

            if (end > 0) {
                if (is_valid_label_name(start) && !is_basic_keyword(start)) {
                    char lbl[256];
                    snprintf(lbl, sizeof(lbl), "%s:", start);
                    add_single_line(prog, lbl);
                } else {
                    add_single_line(prog, start);
                }
            }
            si = 0;
            curr++;
        } else {
            if (si < 2046) stmt[si++] = c;
            curr++;
        }
    }

    stmt[si] = '\0';
    char *start = stmt;
    while (*start && isspace((unsigned char)*start)) start++;
    int end = (int)strlen(start);
    while (end > 0 && isspace((unsigned char)start[end - 1])) start[--end] = '\0';

    if (end > 0) {
        add_single_line(prog, start);
    }
}

bool qb_program_load_file(QB_Program *prog, const char *filename) {
    char dir[MAX_PATH] = {0};
    const char *last_slash = strrchr(filename, '/');
    const char *last_backslash = strrchr(filename, '\\');
    const char *sep = (last_slash > last_backslash) ? last_slash : last_backslash;
    if (sep) {
        size_t dirlen = sep - filename;
        strncpy(dir, filename, dirlen);
        dir[dirlen] = '\0';
    }
    qb_set_program_dir(dir);

    FILE *f = fopen(filename, "r");
    if (!f) return false;
    char buffer[2048];
    while (fgets(buffer, sizeof(buffer), f)) {
        char *nl = strchr(buffer, '\n');
        if (nl) *nl = '\0';
        nl = strchr(buffer, '\r');
        if (nl) *nl = '\0';
        qb_program_add_line(prog, buffer);
    }
    fclose(f);
    return true;
}

static void init_data_pool(QB_Interpreter *interp) {
    interp->data_pool.capacity = 128;
    interp->data_pool.count = 0;
    interp->data_pool.current_idx = 0;
    interp->data_pool.items = (char**)calloc(interp->data_pool.capacity, sizeof(char*));
    interp->data_pool.line_numbers = (int*)calloc(interp->data_pool.capacity, sizeof(int));

    if (!interp->program) return;

    for (int i = 0; i < interp->program->line_count; i++) {
        const char *p = interp->program->lines[i];
        skip_whitespace(&p);
        if (isdigit((unsigned char)*p)) {
            while (isdigit((unsigned char)*p)) p++;
            skip_whitespace(&p);
        }
        if (match_keyword(&p, "DATA")) {
            while (*p) {
                skip_whitespace(&p);
                if (!*p) break;

                char item_buf[256];
                int idx = 0;
                if (*p == '"') {
                    p++;
                    while (*p && *p != '"' && idx < 250) item_buf[idx++] = *p++;
                    if (*p == '"') p++;
                } else {
                    while (*p && *p != ',' && *p != ':' && idx < 250) {
                        item_buf[idx++] = *p++;
                    }
                    while (idx > 0 && isspace((unsigned char)item_buf[idx - 1])) idx--;
                }
                item_buf[idx] = '\0';

                if (interp->data_pool.count >= interp->data_pool.capacity) {
                    interp->data_pool.capacity *= 2;
                    interp->data_pool.items = (char**)realloc(interp->data_pool.items, interp->data_pool.capacity * sizeof(char*));
                    interp->data_pool.line_numbers = (int*)realloc(interp->data_pool.line_numbers, interp->data_pool.capacity * sizeof(int));
                }
                interp->data_pool.line_numbers[interp->data_pool.count] = i;
                interp->data_pool.items[interp->data_pool.count++] = strdup(item_buf);

                skip_whitespace(&p);
                if (*p == ',') p++;
                else break;
            }
        }
    }
}

QB_Interpreter* qb_interp_create(QB_Program *prog) {
    QB_Interpreter *interp = (QB_Interpreter*)calloc(1, sizeof(QB_Interpreter));
    interp->program = prog;
    interp->env = qb_env_create();
    interp->env->user_data = interp;
    interp->pc = 0;
    interp->running = true;
    interp->on_error_pc = -1;
    interp->on_error_call_sp = -1;
    interp->err_code = 0;
    interp->err_line = 0;
    interp->err_pc = 0;
    interp->in_error_handler = false;
    interp->in_event_handler = false;
    for (int k = 0; k < 32; k++) {
        interp->key_trap_pc[k] = -1;
        interp->key_state[k] = 0;
        interp->key_pending[k] = false;
        interp->key_defs[k][0] = '\0';
    }
    interp->timer_trap_pc = -1;
    interp->timer_interval = 1.0;
    interp->timer_last_sec = 0.0;
    interp->timer_state = 0;
    interp->timer_pending = false;

    interp->play_trap_pc = -1;
    interp->play_threshold = 1;
    interp->play_state = 0;
    interp->play_pending = false;
    interp->play_fired = false;
    for (int i = 0; i < 256; i++) {
        interp->file_modes[i] = QB_FILE_MODE_NONE;
        interp->file_record_lens[i] = 128;
        interp->file_current_record[i] = 0;
        interp->file_last_pos[i] = 0;
        interp->file_fields[i].count = 0;
    }
    interp->var_type_count = 0;
    init_data_pool(interp);

    // Pré-analyse des variables partagées (COMMON SHARED et DIM SHARED)
    for (int i = 0; i < prog->line_count; i++) {
        const char *lp = prog->lines[i];
        skip_whitespace(&lp);
        if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
        if (match_keyword(&lp, "COMMON")) {
            match_keyword(&lp, "SHARED");
            qb_parse_shared_var_list(interp, &lp);
        } else if (match_keyword(&lp, "DIM")) {
            if (match_keyword(&lp, "SHARED")) {
                qb_parse_shared_var_list(interp, &lp);
            }
        }
    }

    // Détection des procédures SUB et FUNCTION
    for (int i = 0; i < prog->line_count; i++) {
        const char *lp = prog->lines[i];
        skip_whitespace(&lp);
        if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
        bool is_sub = match_keyword(&lp, "SUB");
        bool is_fn = !is_sub && match_keyword(&lp, "FUNCTION");
        if ((is_sub || is_fn) && interp->proc_count < 64) {
            skip_whitespace(&lp);
            char proc_name[64] = {0};
            int pni = 0;
            while ((isalnum((unsigned char)*lp) || *lp == '_' || *lp == '$' || *lp == '%' || *lp == '&' || *lp == '#' || *lp == '!') && pni < 63) {
                proc_name[pni++] = *lp++;
            }
            proc_name[pni] = '\0';

            int pidx = interp->proc_count++;
            snprintf(interp->procs[pidx].name, sizeof(interp->procs[pidx].name), "%s", proc_name);
            interp->procs[pidx].start_pc = i;
            interp->procs[pidx].is_function = is_fn;
            interp->procs[pidx].param_count = 0;

            skip_whitespace(&lp);
            if (*lp == '(') {
                lp++;
                while (*lp && *lp != ')') {
                    skip_whitespace(&lp);
                    char param[64] = {0};
                    int pri = 0;
                    while ((isalnum((unsigned char)*lp) || *lp == '_' || *lp == '$' || *lp == '%' || *lp == '&' || *lp == '#' || *lp == '!') && pri < 63) {
                        param[pri++] = *lp++;
                    }
                    param[pri] = '\0';
                    if (param[0] && interp->procs[pidx].param_count < 16) {
                        snprintf(interp->procs[pidx].params[interp->procs[pidx].param_count++], sizeof(interp->procs[pidx].params[0]), "%s", param);
                    }
                    skip_whitespace(&lp);
                    if (*lp == '(') {
                        while (*lp && *lp != ')') lp++;
                        if (*lp == ')') lp++;
                    }
                    skip_whitespace(&lp);
                    if (match_keyword(&lp, "AS")) {
                        skip_whitespace(&lp);
                        while (*lp && *lp != ',' && *lp != ')') lp++;
                    }
                    skip_whitespace(&lp);
                    if (*lp == ',') lp++;
                }
                if (*lp == ')') lp++;
            }
        }
    }

    return interp;
}

void qb_interp_free(QB_Interpreter *interp) {
    if (!interp) return;

    for (int i = 0; i < 256; i++) {
        if (interp->files[i]) {
            fclose(interp->files[i]);
            interp->files[i] = NULL;
        }
    }

    for (int i = 0; i < interp->data_pool.count; i++) {
        free(interp->data_pool.items[i]);
    }
    free(interp->data_pool.items);
    if (interp->data_pool.line_numbers) free(interp->data_pool.line_numbers);

    qb_env_free(interp->env);
    free(interp);
}

static int find_label_or_linenum(QB_Program *prog, const char *target) {
    for (int i = 0; i < prog->line_count; i++) {
        const char *p = prog->lines[i];
        skip_whitespace(&p);
        char token[64];
        int idx = 0;
        while (*p && !isspace((unsigned char)*p) && *p != ':' && idx < 63) {
            token[idx++] = *p++;
        }
        token[idx] = '\0';
        if (strcasecmp(token, target) == 0) {
            return i;
        }
    }
    return -1;
}

void qb_trigger_error(QB_Interpreter *interp, int code) {
    if (!interp || !interp->program) return;

    // Extraire le numéro de ligne de la ligne courante pour ERL
    int line_num = 0;
    if (interp->pc >= 0 && interp->pc < interp->program->line_count) {
        const char *lp = interp->program->lines[interp->pc];
        while (*lp && isspace((unsigned char)*lp)) lp++;
        if (isdigit((unsigned char)*lp)) {
            line_num = atoi(lp);
        }
    }

    interp->err_code = code;
    interp->err_line = line_num;
    interp->err_pc = interp->pc;

    if (interp->on_error_pc >= 0 && !interp->in_error_handler) {
        // Dérouler les frames de SUB/FUNCTION si le handler appartient à un appelant
        while (interp->call_sp > interp->on_error_call_sp && interp->call_sp > 0) {
            int sp = --interp->call_sp;
            interp->err_pc = interp->call_stack[sp].return_pc;
            unwind_proc_call_frame(interp, sp);
        }
        interp->in_error_handler = true;
        interp->in_event_handler = false;
        interp->pc = interp->on_error_pc;
        return;
    }

    fprintf(stderr, "Erreur QBasic non gérée : code %d (ligne %d, PC %d) -> '%s'\n", code, line_num, interp->pc + 1, (interp->program && interp->pc >= 0 && interp->pc < interp->program->line_count) ? interp->program->lines[interp->pc] : "");
    interp->running = false;
}

static bool qb_parse_on_statement(QB_Interpreter *interp, const char **p_ptr) {
    const char *p = *p_ptr;
    if (!match_keyword(&p, "ON")) return false;

    if (match_keyword(&p, "ERROR")) {
        match_keyword(&p, "GOTO");
        skip_whitespace(&p);
        char target[64] = {0};
        int ti = 0;
        while (*p && !isspace((unsigned char)*p) && *p != ':' && *p != '\'' && ti < 63) {
            target[ti++] = *p++;
        }
        target[ti] = '\0';
        if (strcmp(target, "0") == 0) {
            interp->on_error_pc = -1;
            interp->on_error_call_sp = -1;
        } else {
            int target_pc = find_label_or_linenum(interp->program, target);
            if (target_pc >= 0) {
                interp->on_error_pc = target_pc;
                interp->on_error_call_sp = interp->call_sp;
            } else {
                fprintf(stderr, "Erreur QBasic: Label ON ERROR introuvable '%s'\n", target);
            }
        }
        *p_ptr = p;
        return true;
    }

    if (match_keyword(&p, "KEY")) {
        skip_whitespace(&p);
        if (*p == '(') {
            p++;
            QB_Value kv = qb_eval_expression(interp->env, &p);
            int kn = (int)kv.number;
            qb_val_free(&kv);
            skip_whitespace(&p);
            if (*p == ')') p++;
            if (match_keyword(&p, "GOSUB")) {
                skip_whitespace(&p);
                char target[64] = {0};
                int ti = 0;
                while (*p && !isspace((unsigned char)*p) && *p != ':' && *p != '\'' && ti < 63) {
                    target[ti++] = *p++;
                }
                target[ti] = '\0';
                if (kn >= 1 && kn < 32) {
                    if (strcmp(target, "0") == 0) {
                        interp->key_trap_pc[kn] = -1;
                    } else {
                        int target_pc = find_label_or_linenum(interp->program, target);
                        if (target_pc >= 0) {
                            interp->key_trap_pc[kn] = target_pc;
                        } else {
                            fprintf(stderr, "Erreur QBasic: Label ON KEY introuvable '%s'\n", target);
                        }
                    }
                }
            }
        }
        *p_ptr = p;
        return true;
    }

    if (match_keyword(&p, "TIMER")) {
        skip_whitespace(&p);
        if (*p == '(') {
            p++;
            QB_Value tv = qb_eval_expression(interp->env, &p);
            double tint = tv.number;
            qb_val_free(&tv);
            skip_whitespace(&p);
            if (*p == ')') p++;
            if (match_keyword(&p, "GOSUB")) {
                skip_whitespace(&p);
                char target[64] = {0};
                int ti = 0;
                while (*p && !isspace((unsigned char)*p) && *p != ':' && *p != '\'' && ti < 63) {
                    target[ti++] = *p++;
                }
                target[ti] = '\0';
                if (strcmp(target, "0") == 0) {
                    interp->timer_trap_pc = -1;
                } else {
                    int target_pc = find_label_or_linenum(interp->program, target);
                    if (target_pc >= 0) {
                        interp->timer_trap_pc = target_pc;
                        interp->timer_interval = (tint > 0.0) ? tint : 1.0;
                        interp->timer_last_sec = qb_timer();
                    } else {
                        fprintf(stderr, "Erreur QBasic: Label ON TIMER introuvable '%s'\n", target);
                    }
                }
            }
        }
        *p_ptr = p;
        return true;
    }

    if (match_keyword(&p, "PLAY")) {
        skip_whitespace(&p);
        if (*p == '(') {
            p++;
            QB_Value pv = qb_eval_expression(interp->env, &p);
            int pnum = (int)pv.number;
            qb_val_free(&pv);
            skip_whitespace(&p);
            if (*p == ')') p++;
            if (match_keyword(&p, "GOSUB")) {
                skip_whitespace(&p);
                char target[64] = {0};
                int ti = 0;
                while (*p && !isspace((unsigned char)*p) && *p != ':' && *p != '\'' && ti < 63) {
                    target[ti++] = *p++;
                }
                target[ti] = '\0';
                if (strcmp(target, "0") == 0) {
                    interp->play_trap_pc = -1;
                } else {
                    int target_pc = find_label_or_linenum(interp->program, target);
                    if (target_pc >= 0) {
                        interp->play_trap_pc = target_pc;
                        interp->play_threshold = (pnum > 0) ? pnum : 1;
                        interp->play_fired = false;
                    } else {
                        fprintf(stderr, "Erreur QBasic: Label ON PLAY introuvable '%s'\n", target);
                    }
                }
            }
        }
        *p_ptr = p;
        return true;
    }

    return false;
}

// Helpers pour structures de contrôle multi-lignes
static int find_matching_end_if(QB_Program *prog, int start_pc) {
    int depth = 1;
    for (int i = start_pc; i < prog->line_count; i++) {
        const char *lp = prog->lines[i];
        skip_whitespace(&lp);
        if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
        if (match_keyword(&lp, "IF")) {
            const char *th = find_keyword_caseless(lp, "THEN");
            if (th) {
                th += 4;
                skip_whitespace(&th);
                if (!*th || *th == '\'') depth++;
            }
        } else if (match_keyword(&lp, "END") && match_keyword(&lp, "IF")) {
            depth--;
            if (depth == 0) return i;
        }
    }
    return prog->line_count;
}

static int find_next_if_branch(QB_Program *prog, int start_pc) {
    int depth = 1;
    for (int i = start_pc; i < prog->line_count; i++) {
        const char *lp = prog->lines[i];
        skip_whitespace(&lp);
        if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
        if (match_keyword(&lp, "IF")) {
            const char *th = find_keyword_caseless(lp, "THEN");
            if (th) {
                th += 4;
                skip_whitespace(&th);
                if (!*th || *th == '\'') depth++;
            }
        } else if (match_keyword(&lp, "END") && match_keyword(&lp, "IF")) {
            depth--;
            if (depth == 0) return i;
        } else if (depth == 1 && (match_keyword(&lp, "ELSEIF") || match_keyword(&lp, "ELSE"))) {
            return i;
        }
    }
    return prog->line_count;
}

static int find_matching_end_select(QB_Program *prog, int start_pc) {
    int depth = 1;
    for (int i = start_pc; i < prog->line_count; i++) {
        const char *lp = prog->lines[i];
        skip_whitespace(&lp);
        if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
        if (match_keyword(&lp, "SELECT") && match_keyword(&lp, "CASE")) {
            depth++;
        } else if (match_keyword(&lp, "END") && match_keyword(&lp, "SELECT")) {
            depth--;
            if (depth == 0) return i;
        }
    }
    return prog->line_count;
}

static int find_next_case_branch(QB_Program *prog, int start_pc) {
    int depth = 1;
    for (int i = start_pc; i < prog->line_count; i++) {
        const char *lp = prog->lines[i];
        skip_whitespace(&lp);
        if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
        if (match_keyword(&lp, "SELECT") && match_keyword(&lp, "CASE")) {
            depth++;
        } else if (match_keyword(&lp, "END") && match_keyword(&lp, "SELECT")) {
            depth--;
            if (depth == 0) return i;
        } else if (depth == 1 && match_keyword(&lp, "CASE")) {
            return i;
        }
    }
    return prog->line_count;
}

static int find_matching_end_proc(QB_Program *prog, int start_pc, const char *kind) {
    for (int i = start_pc; i < prog->line_count; i++) {
        const char *lp = prog->lines[i];
        skip_whitespace(&lp);
        if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
        if (match_keyword(&lp, "END") && match_keyword(&lp, kind)) {
            return i;
        }
    }
    return prog->line_count - 1;
}

static void do_exit_do(QB_Interpreter *interp) {
    if (interp->do_sp > 0) {
        interp->do_sp--;
        int depth = 1;
        int cur = interp->pc + 1;
        while (cur < interp->program->line_count) {
            const char *lp = interp->program->lines[cur];
            skip_whitespace(&lp);
            if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
            if (match_keyword(&lp, "DO")) depth++;
            else if (match_keyword(&lp, "LOOP")) {
                depth--;
                if (depth == 0) {
                    while (interp->select_sp > 0 && interp->select_stack[interp->select_sp - 1].end_select_pc <= cur) {
                        interp->select_sp--;
                        qb_val_free(&interp->select_stack[interp->select_sp].test_val);
                    }
                    while (interp->if_sp > 0 && interp->if_stack[interp->if_sp - 1].end_if_pc <= cur) {
                        interp->if_sp--;
                    }
                    interp->pc = cur + 1;
                    return;
                }
            }
            cur++;
        }
    }
}

static void do_exit_for(QB_Interpreter *interp) {
    if (interp->for_sp > 0) {
        interp->for_sp--;
        int depth = 1;
        int cur = interp->pc + 1;
        while (cur < interp->program->line_count) {
            const char *lp = interp->program->lines[cur];
            skip_whitespace(&lp);
            if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
            if (match_keyword(&lp, "FOR")) depth++;
            else if (match_keyword(&lp, "NEXT")) {
                depth--;
                if (depth == 0) {
                    while (interp->select_sp > 0 && interp->select_stack[interp->select_sp - 1].end_select_pc <= cur) {
                        interp->select_sp--;
                        qb_val_free(&interp->select_stack[interp->select_sp].test_val);
                    }
                    while (interp->if_sp > 0 && interp->if_stack[interp->if_sp - 1].end_if_pc <= cur) {
                        interp->if_sp--;
                    }
                    interp->pc = cur + 1;
                    return;
                }
            }
            cur++;
        }
    }
}

static void qb_format_using(const char *fmt, QB_Value val, char *out, size_t out_max) {
    if (!out || out_max == 0) return;
    out[0] = '\0';
    if (!fmt) return;

    if (val.type == QB_VAL_STRING) {
        const char *s = val.string ? val.string : "";
        strncpy(out, s, out_max - 1);
        out[out_max - 1] = '\0';
        return;
    }

    size_t oi = 0;
    const char *p = fmt;

    while (*p && oi < out_max - 1) {
        if (*p == '#') {
            int whole_hashes = 0;
            while (*p == '#') {
                whole_hashes++;
                p++;
            }
            int frac_hashes = 0;
            if (*p == '.') {
                p++;
                while (*p == '#') {
                    frac_hashes++;
                    p++;
                }
            }
            char num_str[64];
            int total_width = whole_hashes + (frac_hashes > 0 ? (1 + frac_hashes) : 0);
            if (frac_hashes > 0) {
                snprintf(num_str, sizeof(num_str), "%*.*f", total_width, frac_hashes, val.number);
            } else {
                long long iv = (long long)round(val.number);
                snprintf(num_str, sizeof(num_str), "%*lld", total_width, iv);
            }
            for (char *c = num_str; *c && oi < out_max - 1; c++) {
                out[oi++] = *c;
            }
        } else if (*p == '+' && p[1] == '#') {
            p++;
            int whole_hashes = 0;
            while (*p == '#') {
                whole_hashes++;
                p++;
            }
            int frac_hashes = 0;
            if (*p == '.') {
                p++;
                while (*p == '#') {
                    frac_hashes++;
                    p++;
                }
            }
            char num_str[64];
            int total_width = whole_hashes + (frac_hashes > 0 ? (1 + frac_hashes) : 0);
            if (frac_hashes > 0) {
                snprintf(num_str, sizeof(num_str), "%+*.*f", total_width, frac_hashes, val.number);
            } else {
                long long iv = (long long)round(val.number);
                snprintf(num_str, sizeof(num_str), "%+*lld", total_width, iv);
            }
            for (char *c = num_str; *c && oi < out_max - 1; c++) {
                out[oi++] = *c;
            }
        } else {
            out[oi++] = *p++;
        }
    }
    out[oi] = '\0';
}

static FILE *qb_fopen_helper(const char *filename, const char *mode) {
    if (!filename || !filename[0]) return NULL;
    const char *fn = filename;
    bool was_floppy_a = ((filename[0] == 'A' || filename[0] == 'a') && filename[1] == ':');
    if (was_floppy_a) {
        fn += 2;
        while (*fn == '/' || *fn == '\\') fn++;
    }

    const char *base = strrchr(fn, '/');
    const char *base2 = strrchr(fn, '\\');
    if (base2 && (!base || base2 > base)) base = base2;
    const char *actual_name = base ? base + 1 : fn;

    char full_path[512] = {0};
    const char *pdir = qb_get_program_dir();
    FILE *f = NULL;

    if (was_floppy_a && pdir && pdir[0]) {
        snprintf(full_path, sizeof(full_path), "%s/%s", pdir, actual_name);
        f = fopen(full_path, mode);
    }
    if (!f) {
        f = fopen(fn, mode);
    }
    if (!f && pdir && pdir[0] && !was_floppy_a) {
        snprintf(full_path, sizeof(full_path), "%s/%s", pdir, actual_name);
        f = fopen(full_path, mode);
    }
    if (!f && strcmp(mode, "rb+") == 0) {
        if (full_path[0]) f = fopen(full_path, "wb+");
        if (!f) f = fopen(fn, "wb+");
    }
    return f;
}

static bool qb_read_file_token(QB_Interpreter *interp, int fnum, char *out_tok, int max_len) {
    if (!interp || fnum < 1 || fnum > 255 || !interp->files[fnum] || !out_tok || max_len <= 0) {
        return false;
    }
    out_tok[0] = '\0';
    FILE *f = interp->files[fnum];
    char *buf = interp->file_buf[fnum];
    int *pos = &interp->file_buf_pos[fnum];

    while (1) {
        while (buf[*pos] && (isspace((unsigned char)buf[*pos]) || buf[*pos] == ',')) {
            (*pos)++;
        }
        if (buf[*pos] != '\0') {
            break;
        }
        if (!fgets(buf, sizeof(interp->file_buf[0]), f)) {
            buf[0] = '\0';
            *pos = 0;
            return false;
        }
        char *nl = strchr(buf, '\n');
        if (nl) *nl = '\0';
        nl = strchr(buf, '\r');
        if (nl) *nl = '\0';
        *pos = 0;
    }

    int oi = 0;
    if (buf[*pos] == '"') {
        (*pos)++;
        while (buf[*pos] && buf[*pos] != '"' && oi < max_len - 1) {
            out_tok[oi++] = buf[(*pos)++];
        }
        if (buf[*pos] == '"') (*pos)++;
    } else {
        while (buf[*pos] && buf[*pos] != ',' && oi < max_len - 1) {
            out_tok[oi++] = buf[(*pos)++];
        }
        while (oi > 0 && isspace((unsigned char)out_tok[oi - 1])) {
            oi--;
        }
    }
    out_tok[oi] = '\0';

    while (buf[*pos] && isspace((unsigned char)buf[*pos])) (*pos)++;
    if (buf[*pos] == ',') (*pos)++;

    return true;
}

static int find_var_type_idx(QB_Interpreter *interp, const char *var_name) {
    if (!interp || !var_name || !var_name[0]) return -1;
    if (strchr(var_name, '$') || strchr(var_name, '%') || strchr(var_name, '&') ||
        strchr(var_name, '!') || strchr(var_name, '#')) {
        return -1;
    }
    for (int i = 0; i < interp->var_type_count; i++) {
        if (strcasecmp(interp->var_types[i].var_name, var_name) == 0) {
            for (int t = 0; t < interp->type_def_count; t++) {
                if (strcasecmp(interp->type_defs[t].name, interp->var_types[i].type_name) == 0) {
                    return t;
                }
            }
        }
    }
    return -1;
}

static void qb_write_var_to_file(QB_Interpreter *interp, FILE *f, const char *var_name, int rlen) {
    if (!interp || !f || !var_name || !var_name[0]) return;

    int type_idx = find_var_type_idx(interp, var_name);
    if (type_idx >= 0) {
        int bytes_written = 0;
        for (int fi = 0; fi < interp->type_defs[type_idx].field_count; fi++) {
            char comp[128];
            snprintf(comp, sizeof(comp), "%s.%s", var_name, interp->type_defs[type_idx].fields[fi].name);
            const char *ftype = interp->type_defs[type_idx].fields[fi].type_name;
            skip_whitespace(&ftype);

            if (strncasecmp(ftype, "STRING", 6) == 0) {
                int wid = 0;
                const char *star = strchr(ftype, '*');
                if (star) wid = atoi(star + 1);
                if (wid <= 0) wid = 16;
                QB_Value val = qb_env_get(interp->env, comp);
                const char *s = (val.type == QB_VAL_STRING && val.string) ? val.string : "";
                int slen = (val.type == QB_VAL_STRING) ? val.string_len : 0;
                char *buf = (char*)malloc(wid);
                memset(buf, ' ', wid);
                int copy_len = slen < wid ? slen : wid;
                if (copy_len > 0) memcpy(buf, s, copy_len);
                fwrite(buf, 1, wid, f);
                free(buf);
                qb_val_free(&val);
                bytes_written += wid;
            } else if (strcasecmp(ftype, "INTEGER") == 0 || strchr(comp, '%')) {
                QB_Value val = qb_env_get(interp->env, comp);
                int16_t num = (int16_t)val.number;
                fwrite(&num, sizeof(num), 1, f);
                qb_val_free(&val);
                bytes_written += sizeof(num);
            } else if (strcasecmp(ftype, "LONG") == 0 || strchr(comp, '&')) {
                QB_Value val = qb_env_get(interp->env, comp);
                int32_t num = (int32_t)val.number;
                fwrite(&num, sizeof(num), 1, f);
                qb_val_free(&val);
                bytes_written += sizeof(num);
            } else if (strcasecmp(ftype, "SINGLE") == 0 || strchr(comp, '!')) {
                QB_Value val = qb_env_get(interp->env, comp);
                float num = (float)val.number;
                fwrite(&num, sizeof(num), 1, f);
                qb_val_free(&val);
                bytes_written += sizeof(num);
            } else if (strcasecmp(ftype, "DOUBLE") == 0 || strchr(comp, '#')) {
                QB_Value val = qb_env_get(interp->env, comp);
                double num = val.number;
                fwrite(&num, sizeof(num), 1, f);
                qb_val_free(&val);
                bytes_written += sizeof(num);
            } else {
                QB_Value val = qb_env_get(interp->env, comp);
                float num = (float)val.number;
                fwrite(&num, sizeof(num), 1, f);
                qb_val_free(&val);
                bytes_written += sizeof(num);
            }
        }
        if (rlen > bytes_written) {
            int pad = rlen - bytes_written;
            char *zeros = (char*)calloc(pad, 1);
            fwrite(zeros, 1, pad, f);
            free(zeros);
        }
        return;
    }

    if (strchr(var_name, '$')) {
        QB_Value val = qb_env_get(interp->env, var_name);
        const char *s = (val.type == QB_VAL_STRING && val.string) ? val.string : "";
        int len = (val.type == QB_VAL_STRING) ? val.string_len : 0;
        if (len > 0) fwrite(s, 1, len, f);
        qb_val_free(&val);
    } else if (strchr(var_name, '%')) {
        QB_Value val = qb_env_get(interp->env, var_name);
        int16_t num = (int16_t)val.number;
        fwrite(&num, sizeof(num), 1, f);
        qb_val_free(&val);
    } else if (strchr(var_name, '&')) {
        QB_Value val = qb_env_get(interp->env, var_name);
        int32_t num = (int32_t)val.number;
        fwrite(&num, sizeof(num), 1, f);
        qb_val_free(&val);
    } else if (strchr(var_name, '!')) {
        QB_Value val = qb_env_get(interp->env, var_name);
        float num = (float)val.number;
        fwrite(&num, sizeof(num), 1, f);
        qb_val_free(&val);
    } else if (strchr(var_name, '#')) {
        QB_Value val = qb_env_get(interp->env, var_name);
        double num = val.number;
        fwrite(&num, sizeof(num), 1, f);
        qb_val_free(&val);
    } else {
        QB_Value val = qb_env_get(interp->env, var_name);
        float num = (float)val.number;
        fwrite(&num, sizeof(num), 1, f);
        qb_val_free(&val);
    }
}

static void qb_read_var_from_file(QB_Interpreter *interp, FILE *f, const char *var_name, int rlen) {
    if (!interp || !f || !var_name || !var_name[0]) return;

    int type_idx = find_var_type_idx(interp, var_name);
    if (type_idx >= 0) {
        int bytes_read = 0;
        for (int fi = 0; fi < interp->type_defs[type_idx].field_count; fi++) {
            char comp[128];
            snprintf(comp, sizeof(comp), "%s.%s", var_name, interp->type_defs[type_idx].fields[fi].name);
            const char *ftype = interp->type_defs[type_idx].fields[fi].type_name;
            skip_whitespace(&ftype);

            if (strncasecmp(ftype, "STRING", 6) == 0) {
                int wid = 0;
                const char *star = strchr(ftype, '*');
                if (star) wid = atoi(star + 1);
                if (wid <= 0) wid = 16;
                char *buf = (char*)malloc(wid + 1);
                memset(buf, ' ', wid);
                fread(buf, 1, wid, f);
                buf[wid] = '\0';
                qb_env_set(interp->env, comp, qb_val_string_len(buf, wid));
                free(buf);
                bytes_read += wid;
            } else if (strcasecmp(ftype, "INTEGER") == 0 || strchr(comp, '%')) {
                int16_t num = 0;
                fread(&num, sizeof(num), 1, f);
                qb_env_set(interp->env, comp, qb_val_number((double)num));
                bytes_read += sizeof(num);
            } else if (strcasecmp(ftype, "LONG") == 0 || strchr(comp, '&')) {
                int32_t num = 0;
                fread(&num, sizeof(num), 1, f);
                qb_env_set(interp->env, comp, qb_val_number((double)num));
                bytes_read += sizeof(num);
            } else if (strcasecmp(ftype, "SINGLE") == 0 || strchr(comp, '!')) {
                float num = 0.0f;
                fread(&num, sizeof(num), 1, f);
                qb_env_set(interp->env, comp, qb_val_number((double)num));
                bytes_read += sizeof(num);
            } else if (strcasecmp(ftype, "DOUBLE") == 0 || strchr(comp, '#')) {
                double num = 0.0;
                fread(&num, sizeof(num), 1, f);
                qb_env_set(interp->env, comp, qb_val_number(num));
                bytes_read += sizeof(num);
            } else {
                float num = 0.0f;
                fread(&num, sizeof(num), 1, f);
                qb_env_set(interp->env, comp, qb_val_number((double)num));
                bytes_read += sizeof(num);
            }
        }
        if (rlen > bytes_read) {
            fseek(f, rlen - bytes_read, SEEK_CUR);
        }
        return;
    }

    if (strchr(var_name, '$')) {
        QB_Value cur = qb_env_get(interp->env, var_name);
        int len = (cur.type == QB_VAL_STRING) ? cur.string_len : 0;
        qb_val_free(&cur);
        if (len <= 0 && rlen > 0) len = rlen;
        if (len <= 0) len = 1;
        char *buf = (char*)malloc(len + 1);
        memset(buf, 0, len + 1);
        long cur_tell = ftell(f);
        int nread = (int)fread(buf, 1, len, f);
        qb_env_set(interp->env, var_name, qb_val_string_len(buf, nread));
        free(buf);
    } else if (strchr(var_name, '%')) {
        int16_t num = 0;
        fread(&num, sizeof(num), 1, f);
        qb_env_set(interp->env, var_name, qb_val_number((double)num));
    } else if (strchr(var_name, '&')) {
        int32_t num = 0;
        fread(&num, sizeof(num), 1, f);
        qb_env_set(interp->env, var_name, qb_val_number((double)num));
    } else if (strchr(var_name, '!')) {
        float num = 0.0f;
        fread(&num, sizeof(num), 1, f);
        qb_env_set(interp->env, var_name, qb_val_number((double)num));
    } else if (strchr(var_name, '#')) {
        double num = 0.0;
        fread(&num, sizeof(num), 1, f);
        qb_env_set(interp->env, var_name, qb_val_number(num));
    } else {
        float num = 0.0f;
        fread(&num, sizeof(num), 1, f);
        qb_env_set(interp->env, var_name, qb_val_number((double)num));
    }
}

static void qb_file_put(QB_Interpreter *interp, int fnum, long rec_or_pos, bool has_rec, const char *var_name, bool is_direct_val, QB_Value direct_val) {
    if (!interp || fnum < 1 || fnum > 255 || !interp->files[fnum]) {
        qb_trigger_error(interp, 52); // Bad file number
        return;
    }
    FILE *f = interp->files[fnum];
    QB_FileMode mode = interp->file_modes[fnum];

    if (mode == QB_FILE_MODE_RANDOM) {
        long rec = has_rec ? rec_or_pos : (interp->file_current_record[fnum] + 1);
        if (rec <= 0) rec = 1;
        interp->file_current_record[fnum] = rec;
        int rlen = interp->file_record_lens[fnum];
        if (rlen <= 0) rlen = 128;
        fseek(f, (rec - 1) * (long)rlen, SEEK_SET);

        if (is_direct_val) {
            if (direct_val.type == QB_VAL_STRING && direct_val.string) {
                fwrite(direct_val.string, 1, direct_val.string_len, f);
            } else {
                float fv = (float)direct_val.number;
                fwrite(&fv, sizeof(fv), 1, f);
            }
        } else if (var_name && var_name[0]) {
            qb_write_var_to_file(interp, f, var_name, rlen);
        } else {
            fwrite(interp->file_random_buffers[fnum], 1, rlen, f);
        }
        interp->file_last_pos[fnum] = rec;
        fflush(f);
    } else if (mode == QB_FILE_MODE_BINARY) {
        if (has_rec && rec_or_pos > 0) {
            fseek(f, rec_or_pos - 1, SEEK_SET);
        }
        if (is_direct_val) {
            if (direct_val.type == QB_VAL_STRING && direct_val.string) {
                fwrite(direct_val.string, 1, direct_val.string_len, f);
            } else {
                float fv = (float)direct_val.number;
                fwrite(&fv, sizeof(fv), 1, f);
            }
        } else if (var_name && var_name[0]) {
            qb_write_var_to_file(interp, f, var_name, 0);
        }
        interp->file_last_pos[fnum] = ftell(f) + 1;
        fflush(f);
    } else {
        qb_trigger_error(interp, 54);
    }
}

static void qb_file_get(QB_Interpreter *interp, int fnum, long rec_or_pos, bool has_rec, const char *var_name) {
    if (!interp || fnum < 1 || fnum > 255 || !interp->files[fnum]) {
        qb_trigger_error(interp, 52); // Bad file number
        return;
    }
    FILE *f = interp->files[fnum];
    QB_FileMode mode = interp->file_modes[fnum];

    if (mode == QB_FILE_MODE_RANDOM) {
        long rec = has_rec ? rec_or_pos : (interp->file_current_record[fnum] + 1);
        if (rec <= 0) rec = 1;
        interp->file_current_record[fnum] = rec;
        int rlen = interp->file_record_lens[fnum];
        if (rlen <= 0) rlen = 128;
        fseek(f, (rec - 1) * (long)rlen, SEEK_SET);

        if (var_name && var_name[0]) {
            qb_read_var_from_file(interp, f, var_name, rlen);
        } else {
            memset(interp->file_random_buffers[fnum], ' ', rlen);
            size_t nread = fread(interp->file_random_buffers[fnum], 1, rlen, f);
            (void)nread;
            for (int fi = 0; fi < interp->file_fields[fnum].count; fi++) {
                int off = interp->file_fields[fnum].fields[fi].offset;
                int wid = interp->file_fields[fnum].fields[fi].width;
                const char *vname = interp->file_fields[fnum].fields[fi].var_name;
                qb_env_set(interp->env, vname, qb_val_string_len(interp->file_random_buffers[fnum] + off, wid));
            }
        }
        interp->file_last_pos[fnum] = rec;
    } else if (mode == QB_FILE_MODE_BINARY) {
        if (has_rec && rec_or_pos > 0) {
            fseek(f, rec_or_pos - 1, SEEK_SET);
        }
        interp->file_last_pos[fnum] = ftell(f) + 1;
        if (var_name && var_name[0]) {
            qb_read_var_from_file(interp, f, var_name, 0);
        }
    } else {
        qb_trigger_error(interp, 54);
    }
}

static void qb_apply_lset_rset(QB_Interpreter *interp, const char *var_name, const char *src_str, int src_len, bool is_rset) {
    if (!interp || !var_name || !var_name[0]) return;
    QB_Value cur = qb_env_get(interp->env, var_name);
    int dest_len = (cur.type == QB_VAL_STRING && cur.string) ? cur.string_len : 0;
    qb_val_free(&cur);

    int found_fnum = 0;
    int found_off = 0;
    int found_wid = 0;
    for (int f = 1; f < 256; f++) {
        if (interp->files[f] && interp->file_modes[f] == QB_FILE_MODE_RANDOM) {
            for (int i = 0; i < interp->file_fields[f].count; i++) {
                if (strcasecmp(interp->file_fields[f].fields[i].var_name, var_name) == 0) {
                    found_fnum = f;
                    found_off = interp->file_fields[f].fields[i].offset;
                    found_wid = interp->file_fields[f].fields[i].width;
                    break;
                }
            }
            if (found_fnum) break;
        }
    }

    if (found_fnum && dest_len == 0) {
        dest_len = found_wid;
    }
    if (dest_len <= 0) {
        dest_len = (src_len > 0) ? src_len : 1;
    }

    char *buf = (char*)malloc(dest_len + 1);
    if (!buf) return;
    memset(buf, ' ', dest_len);
    if (src_len > dest_len) {
        memcpy(buf, src_str, dest_len);
    } else {
        if (is_rset) {
            memcpy(buf + (dest_len - src_len), src_str, src_len);
        } else {
            memcpy(buf, src_str, src_len);
        }
    }
    buf[dest_len] = '\0';

    qb_env_set(interp->env, var_name, qb_val_string_len(buf, dest_len));

    if (found_fnum) {
        if (found_off + found_wid <= (int)sizeof(interp->file_random_buffers[found_fnum])) {
            int copy_len = (dest_len < found_wid) ? dest_len : found_wid;
            memcpy(interp->file_random_buffers[found_fnum] + found_off, buf, copy_len);
        }
    }
    free(buf);
}

static void qb_register_def_fn(QB_Interpreter *interp, const char *p) {
    char fn_name[64] = {0};
    int fni = 0;
    while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '!' || *p == '#') && fni < 63) {
        fn_name[fni++] = *p++;
    }
    fn_name[fni] = '\0';
    skip_whitespace(&p);
    char params[8][64] = {{0}};
    int param_count = 0;
    if (*p == '(') {
        p++;
        while (*p && *p != ')') {
            skip_whitespace(&p);
            char param_name[64] = {0};
            int pni = 0;
            while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '!' || *p == '#') && pni < 63) {
                param_name[pni++] = *p++;
            }
            param_name[pni] = '\0';
            if (param_name[0] && param_count < 8) {
                strncpy(params[param_count++], param_name, 63);
            }
            skip_whitespace(&p);
            if (*p == ',') p++;
        }
        if (*p == ')') p++;
    }
    skip_whitespace(&p);
    if (*p == '=') {
        p++;
        skip_whitespace(&p);
        int idx = -1;
        for (int k = 0; k < interp->def_fn_count; k++) {
            if (strcasecmp(interp->def_fns[k].name, fn_name) == 0) {
                idx = k;
                break;
            }
        }
        if (idx == -1 && interp->def_fn_count < 16) {
            idx = interp->def_fn_count++;
        }
        if (idx >= 0) {
            strncpy(interp->def_fns[idx].name, fn_name, 63);
            interp->def_fns[idx].param_count = param_count;
            for (int pi = 0; pi < param_count; pi++) {
                strncpy(interp->def_fns[idx].params[pi], params[pi], 63);
            }
            strncpy(interp->def_fns[idx].expr, p, 255);
        }
    }
}

bool qb_interp_exec_immediate(QB_Interpreter *interp, const char *line) {
    const char *p = line;
    skip_whitespace(&p);

    if (!*p || *p == '\'' || match_keyword(&p, "REM")) {
        return true;
    }

    if (isdigit((unsigned char)*p)) {
        while (isdigit((unsigned char)*p)) p++;
        skip_whitespace(&p);
    }

    // Boucle FOR ... : NEXT sur une seule ligne (ex: FOR a# = 1 TO curSpeed: NEXT a#)
    const char *for_p = p;
    if (match_keyword(&for_p, "FOR")) {
        skip_whitespace(&for_p);
        char var_name[64] = {0};
        int vni = 0;
        while ((isalnum((unsigned char)*for_p) || *for_p == '_' || *for_p == '#' || *for_p == '!' || *for_p == '%' || *for_p == '&') && vni < 63) {
            var_name[vni++] = *for_p++;
        }
        var_name[vni] = '\0';
        skip_whitespace(&for_p);
        if (*for_p == '=') {
            for_p++;
            QB_Value start_val = qb_eval_expression(interp->env, &for_p);
            if (match_keyword(&for_p, "TO")) {
                QB_Value end_val = qb_eval_expression(interp->env, &for_p);
                double step_val = 1.0;
                if (match_keyword(&for_p, "STEP")) {
                    QB_Value s = qb_eval_expression(interp->env, &for_p);
                    step_val = s.number;
                    qb_val_free(&s);
                }
                (void)step_val;
                skip_whitespace(&for_p);
                if (*for_p == ':') for_p++;
                skip_whitespace(&for_p);
                if (match_keyword(&for_p, "NEXT")) {
                    skip_whitespace(&for_p);
                    while (isalnum((unsigned char)*for_p) || *for_p == '_' || *for_p == '#' || *for_p == '!' || *for_p == '%' || *for_p == '&') for_p++;
                    if (strcasecmp(var_name, "a#") == 0 || strcasecmp(var_name, "a") == 0) {
                        double delay_ms = end_val.number * 0.05;
                        if (delay_ms > 150.0) delay_ms = 150.0;
                        if (delay_ms < 10.0) delay_ms = 10.0;
                        qb_sleep(delay_ms / 1000.0);
                    } else {
                        qb_sleep(0.08); // 80ms pour animation (ex: dés qui roulent)
                    }
                    qb_env_set(interp->env, var_name, end_val);
                    qb_val_free(&start_val);
                    qb_val_free(&end_val);
                    return true;
                }
                qb_val_free(&end_val);
            }
            qb_val_free(&start_val);
        }
    }

    // Découpage récursif si plusieurs instructions sont séparées par ':' (hors chaînes et hors instruction IF principale)
    if (strncasecmp(p, "IF", 2) != 0 || (!isspace((unsigned char)p[2]) && p[2] != '(')) {
        bool in_q = false;
        const char *s = p;
        bool has_colon = false;
        while (*s) {
            if (*s == '"') in_q = !in_q;
            else if (!in_q && *s == '\'') break;
            else if (!in_q && *s == ':') { has_colon = true; break; }
            s++;
        }
        if (has_colon) {
            char part[1024];
            int pi = 0;
            in_q = false;
            const char *c = p;
            while (*c) {
                if (*c == '"') { in_q = !in_q; if (pi < 1022) part[pi++] = *c++; else c++; }
                else if (!in_q && *c == '\'') break;
                else if (!in_q && *c == ':') {
                    part[pi] = '\0';
                    int pc_before = interp ? interp->pc : 0;
                    qb_interp_exec_immediate(interp, part);
                    if (interp && (!interp->running || interp->pc != pc_before)) {
                        return true;
                    }
                    pi = 0;
                    c++;
                } else {
                    if (pi < 1022) part[pi++] = *c++;
                    else c++;
                }
            }
            part[pi] = '\0';
            return qb_interp_exec_immediate(interp, part);
        }
    }

    // GOTO target
    if (match_keyword(&p, "GOTO")) {
        skip_whitespace(&p);
        char target[64] = {0};
        sscanf(p, "%63s", target);
        if (interp && interp->program) {
            int target_pc = find_label_or_linenum(interp->program, target);
            if (target_pc >= 0) {
                interp->pc = target_pc;
                return true;
            } else {
                fprintf(stderr, "Erreur QBasic: Ligne ou label introuvable '%s'\n", target);
                interp->running = false;
                return true;
            }
        }
        return true;
    }

    // GOSUB target
    if (match_keyword(&p, "GOSUB")) {
        skip_whitespace(&p);
        char target[64] = {0};
        sscanf(p, "%63s", target);
        if (interp && interp->program) {
            int target_pc = find_label_or_linenum(interp->program, target);
            if (target_pc >= 0 && interp->gosub_sp < 127) {
                interp->gosub_stack[interp->gosub_sp++] = interp->pc + 1;
                interp->pc = target_pc;
                return true;
            }
        }
        return true;
    }

    // RETURN
    if (match_keyword(&p, "RETURN")) {
        if (interp && interp->gosub_sp > 0) {
            interp->pc = interp->gosub_stack[--interp->gosub_sp];
            interp->in_event_handler = false;
            return true;
        }
        return true;
    }

    // END [SYSTEM]
    if (match_keyword(&p, "END")) {
        skip_whitespace(&p);
        if (!*p || *p == '\'' || match_keyword(&p, "SYSTEM")) {
            if (interp) {
                interp->running = false;
                interp->exit_requested = true;
            }
            return true;
        }
    }

    // CONST name = expr [, name2 = expr2 ...]
    if (match_keyword(&p, "CONST")) {
        while (*p) {
            skip_whitespace(&p);
            char const_name[64] = {0};
            int cni = 0;
            while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '!' || *p == '#') && cni < 63) {
                const_name[cni++] = *p++;
            }
            const_name[cni] = '\0';
            skip_whitespace(&p);
            if (*p == '=') {
                p++;
                QB_Value val = qb_eval_expression(interp->env, &p);
                qb_env_set(interp->env, const_name, val);
                qb_add_shared_var(interp, const_name);
                qb_val_free(&val);
            }
            skip_whitespace(&p);
            if (*p == ',') p++;
            else break;
        }
        return true;
    }

    // PLAY ON | OFF | STOP | "mml"
    if (match_keyword(&p, "PLAY")) {
        skip_whitespace(&p);
        if (match_keyword(&p, "ON")) {
            interp->play_state = 1;
            if (qb_play_get_notes_remaining() < interp->play_threshold) {
                interp->play_pending = true;
                interp->play_fired = true;
            }
            return true;
        } else if (match_keyword(&p, "OFF")) {
            interp->play_state = 0;
            interp->play_pending = false;
            interp->play_fired = false;
            return true;
        } else if (match_keyword(&p, "STOP")) {
            interp->play_state = 2;
            return true;
        }
        QB_Value mml = qb_eval_expression(interp->env, &p);
        if (mml.type == QB_VAL_STRING && mml.string) {
            qb_play(mml.string);
        }
        qb_val_free(&mml);
        return true;
    }

    // TIMER ON | OFF | STOP
    if (match_keyword(&p, "TIMER")) {
        skip_whitespace(&p);
        if (match_keyword(&p, "ON")) {
            interp->timer_state = 1;
            if (interp->timer_last_sec <= 0.0) {
                interp->timer_last_sec = qb_timer();
            }
            return true;
        } else if (match_keyword(&p, "OFF")) {
            interp->timer_state = 0;
            interp->timer_pending = false;
            return true;
        } else if (match_keyword(&p, "STOP")) {
            interp->timer_state = 2;
            return true;
        }
    }

    // KEY(n) ON | OFF | STOP  ou  KEY n, str$  ou  KEY ON | OFF
    if (match_keyword(&p, "KEY")) {
        skip_whitespace(&p);
        if (*p == '(') {
            p++;
            QB_Value kv = qb_eval_expression(interp->env, &p);
            int kn = (int)kv.number;
            qb_val_free(&kv);
            skip_whitespace(&p);
            if (*p == ')') p++;
            skip_whitespace(&p);
            if (match_keyword(&p, "ON")) {
                if (kn >= 1 && kn < 32) interp->key_state[kn] = 1;
            } else if (match_keyword(&p, "OFF")) {
                if (kn >= 1 && kn < 32) {
                    interp->key_state[kn] = 0;
                    interp->key_pending[kn] = false;
                }
            } else if (match_keyword(&p, "STOP")) {
                if (kn >= 1 && kn < 32) interp->key_state[kn] = 2;
            }
            return true;
        } else if (match_keyword(&p, "ON") || match_keyword(&p, "OFF") || match_keyword(&p, "LIST")) {
            return true;
        } else {
            QB_Value kn_val = qb_eval_expression(interp->env, &p);
            int kn = (int)kn_val.number;
            qb_val_free(&kn_val);
            skip_whitespace(&p);
            if (*p == ',') p++;
            QB_Value s_val = qb_eval_expression(interp->env, &p);
            if (kn >= 1 && kn < 32) {
                if (s_val.type == QB_VAL_STRING && s_val.string) {
                    strncpy(interp->key_defs[kn], s_val.string, 63);
                    interp->key_defs[kn][63] = '\0';
                } else {
                    interp->key_defs[kn][0] = '\0';
                }
            }
            qb_val_free(&s_val);
            return true;
        }
    }

    // _EVENT_KEY n / _KEYPRESS n (déclencheur pour tests)
    if (match_keyword(&p, "_EVENT_KEY") || match_keyword(&p, "_KEYPRESS")) {
        QB_Value kv = qb_eval_expression(interp->env, &p);
        int kn = (int)kv.number;
        qb_val_free(&kv);
        qb_interp_trigger_key_event(interp, kn);
        return true;
    }

    // Directives et déclarations ignorées (no-ops)
    if (match_keyword(&p, "DEFINT") || match_keyword(&p, "DEFLNG") ||
        match_keyword(&p, "DEFSNG") || match_keyword(&p, "DEFDBL") ||
        match_keyword(&p, "DEFSTR") || match_keyword(&p, "VIEW") ||
        match_keyword(&p, "WIDTH") ||
        match_keyword(&p, "'$DYNAMIC") || match_keyword(&p, "'$STATIC")) {
        return true;
    }

    if (match_keyword(&p, "OPTION")) {
        match_keyword(&p, "BASE");
        QB_Value base_v = qb_eval_expression(interp->env, &p);
        qb_val_free(&base_v);
        return true;
    }

    if (match_keyword(&p, "ERASE")) {
        while (*p && *p != ':') {
            skip_whitespace(&p);
            char arr_name[64] = {0};
            int ani = 0;
            while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '!' || *p == '#') && ani < 63) {
                arr_name[ani++] = *p++;
            }
            arr_name[ani] = '\0';
            if (arr_name[0]) {
                char res_buf[128];
                const char *resolved_arr = qb_resolve_var_name(interp->env, arr_name, res_buf, sizeof(res_buf));
                qb_array_erase(interp->env, resolved_arr);
            }
            skip_whitespace(&p);
            if (*p == ',') p++;
            else break;
        }
        return true;
    }

    if (match_keyword(&p, "KILL")) {
        QB_Value file_val = qb_eval_expression(interp->env, &p);
        if (file_val.type == QB_VAL_STRING && file_val.string) {
            if (remove(file_val.string) != 0) {
                const char *pdir = qb_get_program_dir();
                if (pdir && pdir[0] && !strchr(file_val.string, ':') && file_val.string[0] != '/' && file_val.string[0] != '\\') {
                    char full_path[512];
                    snprintf(full_path, sizeof(full_path), "%s/%s", pdir, file_val.string);
                    remove(full_path);
                }
            }
        }
        qb_val_free(&file_val);
        return true;
    }

    if (match_keyword(&p, "DEF")) {
        if (match_keyword(&p, "SEG")) {
            skip_whitespace(&p);
            if (*p == '=') {
                p++;
                QB_Value seg_val = qb_eval_expression(interp->env, &p);
                qb_def_seg((int)seg_val.number);
                qb_val_free(&seg_val);
            } else {
                qb_def_seg(0);
            }
            return true;
        }
        skip_whitespace(&p);
        if (strncasecmp(p, "FN", 2) == 0) {
            qb_register_def_fn(interp, p);
            return true;
        }
    }

    if (match_keyword(&p, "WAIT")) {
        QB_Value port_val = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value and_val = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') {
            p++;
            QB_Value xor_val = qb_eval_expression(interp->env, &p);
            qb_val_free(&xor_val);
        }
        qb_val_free(&port_val);
        qb_val_free(&and_val);
        qb_sleep(0.001);
        return true;
    }

    if (match_keyword(&p, "OUT")) {
        QB_Value port_val = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value data_val = qb_eval_expression(interp->env, &p);
        qb_out_port((int)port_val.number, (int)data_val.number);
        qb_val_free(&port_val);
        qb_val_free(&data_val);
        return true;
    }

    if (match_keyword(&p, "BLOAD")) {
        QB_Value file_val = qb_eval_expression(interp->env, &p);
        const char *fname = (file_val.type == QB_VAL_STRING && file_val.string) ? file_val.string : "";
        skip_whitespace(&p);
        int offset = 0;
        if (*p == ',') {
            p++;
            QB_Value off_val = qb_eval_expression(interp->env, &p);
            offset = (int)off_val.number;
            qb_val_free(&off_val);
        }
        qb_bload(fname, offset);
        qb_val_free(&file_val);
        return true;
    }

    if (match_keyword(&p, "COMMON")) {
        match_keyword(&p, "SHARED");
        qb_parse_shared_var_list(interp, &p);
        return true;
    }

    if (match_keyword(&p, "SHARED")) {
        qb_parse_shared_var_list(interp, &p);
        return true;
    }

    if (match_keyword(&p, "POKE")) {
        return true;
    }

    if (qb_parse_on_statement(interp, &p)) {
        return true;
    }

    if (match_keyword(&p, "RESUME")) {
        skip_whitespace(&p);
        if (match_keyword(&p, "NEXT")) {
            interp->pc = interp->err_pc + 1;
            interp->in_error_handler = false;
            interp->err_code = 0;
            return true;
        }
        char target[64] = {0};
        int ti = 0;
        while (*p && !isspace((unsigned char)*p) && *p != ':' && *p != '\'' && ti < 63) {
            target[ti++] = *p++;
        }
        target[ti] = '\0';
        if (target[0]) {
            int target_pc = find_label_or_linenum(interp->program, target);
            if (target_pc >= 0) {
                interp->pc = target_pc;
                interp->in_error_handler = false;
                interp->err_code = 0;
                return true;
            } else {
                fprintf(stderr, "Erreur QBasic: Label RESUME introuvable '%s'\n", target);
                interp->running = false;
                return true;
            }
        } else {
            interp->pc = interp->err_pc;
            interp->in_error_handler = false;
            interp->err_code = 0;
            return true;
        }
    }

    if (match_keyword(&p, "ERROR")) {
        QB_Value code_v = qb_eval_expression(interp->env, &p);
        int code = (int)code_v.number;
        qb_val_free(&code_v);
        qb_trigger_error(interp, code);
        return true;
    }

    // EXIT SUB / FUNCTION / DO / FOR
    if (match_keyword(&p, "EXIT")) {
        if (match_keyword(&p, "SUB") || match_keyword(&p, "FUNCTION")) {
            if (interp->call_sp > 0) {
                int sp = --interp->call_sp;
                unwind_proc_call_frame(interp, sp);
                interp->pc = interp->call_stack[sp].return_pc;
            }
            return true;
        } else if (match_keyword(&p, "DO")) {
            do_exit_do(interp);
            return true;
        } else if (match_keyword(&p, "FOR")) {
            do_exit_for(interp);
            return true;
        }
    }

    // RANDOMIZE [seed]
    if (match_keyword(&p, "RANDOMIZE")) {
        skip_whitespace(&p);
        if (*p) {
            QB_Value s = qb_eval_expression(interp->env, &p);
            srand((unsigned int)s.number);
            qb_val_free(&s);
        } else {
            srand((unsigned int)time(NULL));
        }
        return true;
    }

    // CLS
    if (match_keyword(&p, "CLS")) {
        qb_cls();
        return true;
    }

    // _SCREENSHOT filename$
    if (match_keyword(&p, "_SCREENSHOT")) {
        QB_Value fn = qb_eval_expression(interp->env, &p);
        if (fn.type == QB_VAL_STRING && fn.string) {
            qb_dump_screen_bmp(fn.string);
        }
        qb_val_free(&fn);
        return true;
    }

    // BEEP
    if (match_keyword(&p, "BEEP")) {
        qb_beep();
        return true;
    }

    // SOUND freq, dur
    if (match_keyword(&p, "SOUND")) {
        QB_Value f = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        int dur = 100;
        if (*p == ',') {
            p++;
            QB_Value d = qb_eval_expression(interp->env, &p);
            dur = (int)d.number;
            qb_val_free(&d);
        }
        qb_sound((int)f.number, dur);
        qb_val_free(&f);
        return true;
    }

    // SLEEP seconds
    if (match_keyword(&p, "SLEEP")) {
        QB_Value s = qb_eval_expression(interp->env, &p);
        qb_sleep(s.number > 0 ? s.number : 1.0);
        qb_val_free(&s);
        return true;
    }

    // LOCATE row, col
    if (match_keyword(&p, "LOCATE")) {
        QB_Value r = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        int col = 1;
        if (*p == ',') {
            p++;
            QB_Value c = qb_eval_expression(interp->env, &p);
            col = (int)c.number;
            qb_val_free(&c);
        }
        qb_locate((int)r.number, col);
        qb_val_free(&r);
        return true;
    }

    // COLOR fg [, bg]
    if (match_keyword(&p, "COLOR")) {
        QB_Value f = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        int bg = -1;
        if (*p == ',') {
            p++;
            QB_Value b = qb_eval_expression(interp->env, &p);
            bg = (int)b.number;
            qb_val_free(&b);
        }
        qb_color((int)f.number, bg);
        qb_val_free(&f);
        return true;
    }

    // SCREEN mode [, colorswitch] [, apage] [, vpage]
    if (match_keyword(&p, "SCREEN")) {
        QB_Value m = qb_eval_expression(interp->env, &p);
        qb_screen((int)m.number);
        qb_val_free(&m);
        while (*p) {
            skip_whitespace(&p);
            if (*p == ',') {
                p++;
                skip_whitespace(&p);
                if (*p && *p != ':' && *p != ',') {
                    QB_Value opt = qb_eval_expression(interp->env, &p);
                    qb_val_free(&opt);
                }
            } else {
                break;
            }
        }
        return true;
    }

    // PALETTE [attr, color]
    if (match_keyword(&p, "PALETTE")) {
        skip_whitespace(&p);
        if (*p && *p != ':') {
            QB_Value va = qb_eval_expression(interp->env, &p);
            skip_whitespace(&p);
            if (*p == ',') {
                p++;
                skip_whitespace(&p);
                QB_Value vc = qb_eval_expression(interp->env, &p);
                qb_palette_set((int)va.number, (int)vc.number);
                qb_val_free(&vc);
            }
            qb_val_free(&va);
        } else {
            qb_palette_set(-1, -1);
        }
        return true;
    }

    // PSET / PRESET (x, y) [, color]
    bool is_preset = false;
    if (match_keyword(&p, "PSET") || (is_preset = match_keyword(&p, "PRESET"))) {
        skip_whitespace(&p);
        if (*p == '(') p++;
        QB_Value vx = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value vy = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ')') p++;
        skip_whitespace(&p);
        int col = is_preset ? 0 : 15;
        if (*p == ',') {
            p++;
            QB_Value vc = qb_eval_expression(interp->env, &p);
            col = (int)vc.number;
            qb_val_free(&vc);
        }
        qb_pset((int)vx.number, (int)vy.number, col);
        qb_val_free(&vx);
        qb_val_free(&vy);
        return true;
    }

    // LINE [(x1, y1)]-(x2, y2) [, col] [, B|BF]
    const char *save_line_stmt = p;
    if (match_keyword(&p, "LINE")) {
        const char *chk = p;
        if (match_keyword(&chk, "INPUT")) {
            p = save_line_stmt; // Laisser l'instruction LINE INPUT traiter la ligne
        } else {
        skip_whitespace(&p);
        int x1 = 0, y1 = 0;
        if (*p == '(') {
            p++;
            QB_Value v = qb_eval_expression(interp->env, &p);
            x1 = (int)v.number;
            qb_val_free(&v);
            skip_whitespace(&p);
            if (*p == ',') p++;
            v = qb_eval_expression(interp->env, &p);
            y1 = (int)v.number;
            qb_val_free(&v);
            skip_whitespace(&p);
            if (*p == ')') p++;
        }
        skip_whitespace(&p);
        if (*p == '-') p++;
        skip_whitespace(&p);
        int x2 = 0, y2 = 0;
        if (*p == '(') {
            p++;
            QB_Value v = qb_eval_expression(interp->env, &p);
            x2 = (int)v.number;
            qb_val_free(&v);
            skip_whitespace(&p);
            if (*p == ',') p++;
            v = qb_eval_expression(interp->env, &p);
            y2 = (int)v.number;
            qb_val_free(&v);
            skip_whitespace(&p);
            if (*p == ')') p++;
        }
        skip_whitespace(&p);
        int col = 15;
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (*p != ',') {
                QB_Value vc = qb_eval_expression(interp->env, &p);
                col = (int)vc.number;
                qb_val_free(&vc);
            }
        }
        skip_whitespace(&p);
        bool box = false, fill = false;
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (match_keyword(&p, "BF")) { box = true; fill = true; }
            else if (match_keyword(&p, "B")) { box = true; }
        }
        qb_line(x1, y1, x2, y2, col, box, fill);
        return true;
        }
    }

    // CIRCLE (cx, cy), radius [, col [, start [, end [, aspect]]]]
    if (match_keyword(&p, "CIRCLE")) {
        skip_whitespace(&p);
        if (*p == '(') p++;
        QB_Value vx = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value vy = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ')') p++;
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value vr = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        int col = 15;
        double start_ang = 0.0, end_ang = 2.0 * 3.14159265358979323846;
        double aspect = 1.0;
        bool has_arc = false;

        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (*p != ',' && *p != '\0') {
                QB_Value vc = qb_eval_expression(interp->env, &p);
                col = (int)vc.number;
                qb_val_free(&vc);
            }
        }
        skip_whitespace(&p);
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (*p != ',' && *p != '\0') {
                QB_Value vs = qb_eval_expression(interp->env, &p);
                start_ang = vs.number;
                qb_val_free(&vs);
                has_arc = true;
            }
        }
        skip_whitespace(&p);
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (*p != ',' && *p != '\0') {
                QB_Value ve = qb_eval_expression(interp->env, &p);
                end_ang = ve.number;
                qb_val_free(&ve);
                has_arc = true;
            }
        }
        skip_whitespace(&p);
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (*p != ',' && *p != '\0') {
                QB_Value va = qb_eval_expression(interp->env, &p);
                aspect = va.number;
                qb_val_free(&va);
                has_arc = true;
            }
        }
        if (has_arc) {
            qb_circle_arc((int)vx.number, (int)vy.number, (int)vr.number, col, start_ang, end_ang, aspect);
        } else {
            qb_circle((int)vx.number, (int)vy.number, (int)vr.number, col);
        }
        qb_val_free(&vx);
        qb_val_free(&vy);
        qb_val_free(&vr);
        return true;
    }

    // DRAW cmd$
    if (match_keyword(&p, "DRAW")) {
        QB_Value cmd = qb_eval_expression(interp->env, &p);
        if (cmd.type == QB_VAL_STRING && cmd.string) {
            qb_draw(cmd.string);
        }
        qb_val_free(&cmd);
        return true;
    }

    // PAINT (x, y) [, fill_color [, border_color]]
    if (match_keyword(&p, "PAINT")) {
        skip_whitespace(&p);
        if (*p == '(') p++;
        QB_Value vx = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value vy = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ')') p++;
        skip_whitespace(&p);
        int fill_col = 15;
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (*p != ',' && *p != '\0') {
                QB_Value vc = qb_eval_expression(interp->env, &p);
                fill_col = (int)vc.number;
                qb_val_free(&vc);
            }
        }
        skip_whitespace(&p);
        int border_col = fill_col; // En QBasic, la bordure par défaut est égale à la couleur de remplissage
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            if (*p != ',' && *p != '\0') {
                QB_Value vb = qb_eval_expression(interp->env, &p);
                border_col = (int)vb.number;
                qb_val_free(&vb);
            }
        }
        qb_paint((int)vx.number, (int)vy.number, fill_col, border_col);
        qb_val_free(&vx);
        qb_val_free(&vy);
        return true;
    }

    // GET (x1, y1)-(x2, y2), arr_name  OU  GET [#]fnum [, [pos] [, var]]
    if (match_keyword(&p, "GET")) {
        skip_whitespace(&p);
        if (*p != '(') {
            if (*p == '#') p++;
            skip_whitespace(&p);
            QB_Value fv = qb_eval_expression(interp->env, &p);
            int fnum = (int)fv.number;
            qb_val_free(&fv);
            skip_whitespace(&p);

            long rec_or_pos = 0;
            bool has_rec = false;
            char var_name[64] = {0};

            if (*p == ',') {
                p++;
                skip_whitespace(&p);
                if (*p == ',') {
                    // pos omis: GET #1, , var
                    p++;
                    skip_whitespace(&p);
                    int vi = 0;
                    while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!' || *p == '.') && vi < 63) {
                        var_name[vi++] = *p++;
                    }
                    var_name[vi] = '\0';
                } else if (*p != '\0' && *p != ':') {
                    const char *comma_scan = p;
                    int paren_depth = 0;
                    bool has_second_comma = false;
                    while (*comma_scan && *comma_scan != ':' && *comma_scan != '\n') {
                        if (*comma_scan == '(') paren_depth++;
                        else if (*comma_scan == ')') paren_depth--;
                        else if (*comma_scan == ',' && paren_depth == 0) {
                            has_second_comma = true;
                            break;
                        }
                        comma_scan++;
                    }

                    if (has_second_comma) {
                        QB_Value rv = qb_eval_expression(interp->env, &p);
                        rec_or_pos = (long)rv.number;
                        has_rec = true;
                        qb_val_free(&rv);
                        skip_whitespace(&p);
                        if (*p == ',') {
                            p++;
                            skip_whitespace(&p);
                            int vi = 0;
                            while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!' || *p == '.') && vi < 63) {
                                var_name[vi++] = *p++;
                            }
                            var_name[vi] = '\0';
                        }
                    } else {
                        const char *var_scan = p;
                        char candidate_var[64] = {0};
                        int cvi = 0;
                        while ((isalnum((unsigned char)*var_scan) || *var_scan == '_' || *var_scan == '$' || *var_scan == '%' || *var_scan == '&' || *var_scan == '#' || *var_scan == '!' || *var_scan == '.') && cvi < 63) {
                            candidate_var[cvi++] = *var_scan++;
                        }
                        candidate_var[cvi] = '\0';

                        bool is_type_var = (find_var_type_idx(interp, candidate_var) >= 0);
                        if (is_type_var || strchr(candidate_var, '$')) {
                            strcpy(var_name, candidate_var);
                            p = var_scan;
                        } else {
                            QB_Value rv = qb_eval_expression(interp->env, &p);
                            rec_or_pos = (long)rv.number;
                            has_rec = true;
                            qb_val_free(&rv);
                        }
                    }
                }
            }
            qb_file_get(interp, fnum, rec_or_pos, has_rec, var_name);
            return true;
        }

        if (*p == '(') p++;
        QB_Value vx1 = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value vy1 = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ')') p++;
        skip_whitespace(&p);
        if (*p == '-') p++;
        skip_whitespace(&p);
        if (*p == '(') p++;
        QB_Value vx2 = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value vy2 = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ')') p++;
        skip_whitespace(&p);
        if (*p == ',') p++;
        skip_whitespace(&p);
        char arr_name[64] = {0};
        int ani = 0;
        while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!') && ani < 63) {
            arr_name[ani++] = *p++;
        }
        arr_name[ani] = '\0';
        skip_whitespace(&p);
        int arr_offset = 0;
        if (*p == '(') {
            p++;
            QB_Value off_v = qb_eval_expression(interp->env, &p);
            arr_offset = (int)off_v.number;
            qb_val_free(&off_v);
            skip_whitespace(&p);
            if (*p == ')') p++;
        }
        qb_gfx_get((int)vx1.number, (int)vy1.number, (int)vx2.number, (int)vy2.number, interp->env, arr_name, arr_offset);
        qb_val_free(&vx1);
        qb_val_free(&vy1);
        qb_val_free(&vx2);
        qb_val_free(&vy2);
        return true;
    }

    // PUT (x, y), arr_name [(offset)] [, PSET|XOR|OR|AND|PRESET]  OU  PUT [#]fnum [, [pos] [, var_or_expr]]
    if (match_keyword(&p, "PUT")) {
        skip_whitespace(&p);
        if (*p != '(') {
            if (*p == '#') p++;
            skip_whitespace(&p);
            QB_Value fv = qb_eval_expression(interp->env, &p);
            int fnum = (int)fv.number;
            qb_val_free(&fv);
            skip_whitespace(&p);

            long rec_or_pos = 0;
            bool has_rec = false;
            char var_name[64] = {0};
            bool is_direct_val = false;
            QB_Value direct_val = {0};

            if (*p == ',') {
                p++;
                skip_whitespace(&p);
                if (*p == ',') {
                    // pos omis: PUT #1, , var_or_expr
                    p++;
                    skip_whitespace(&p);
                    const char *scan = p;
                    char candidate[64] = {0};
                    int cvi = 0;
                    while ((isalnum((unsigned char)*scan) || *scan == '_' || *scan == '$' || *scan == '%' || *scan == '&' || *scan == '#' || *scan == '!' || *scan == '.') && cvi < 63) {
                        candidate[cvi++] = *scan++;
                    }
                    candidate[cvi] = '\0';
                    const char *temp = scan;
                    skip_whitespace(&temp);
                    bool is_func_or_expr = (*temp == '(' || *temp == '+' || *temp == '-' || *temp == '*' || *temp == '/');

                    if (candidate[0] && !is_func_or_expr) {
                        strcpy(var_name, candidate);
                        p = scan;
                    } else {
                        direct_val = qb_eval_expression(interp->env, &p);
                        is_direct_val = true;
                    }
                } else if (*p != '\0' && *p != ':') {
                    const char *comma_scan = p;
                    int paren_depth = 0;
                    bool has_second_comma = false;
                    while (*comma_scan && *comma_scan != ':' && *comma_scan != '\n') {
                        if (*comma_scan == '(') paren_depth++;
                        else if (*comma_scan == ')') paren_depth--;
                        else if (*comma_scan == ',' && paren_depth == 0) {
                            has_second_comma = true;
                            break;
                        }
                        comma_scan++;
                    }

                    if (has_second_comma) {
                        QB_Value rv = qb_eval_expression(interp->env, &p);
                        rec_or_pos = (long)rv.number;
                        has_rec = true;
                        qb_val_free(&rv);
                        skip_whitespace(&p);
                        if (*p == ',') {
                            p++;
                            skip_whitespace(&p);
                            const char *scan = p;
                            char candidate[64] = {0};
                            int cvi = 0;
                            while ((isalnum((unsigned char)*scan) || *scan == '_' || *scan == '$' || *scan == '%' || *scan == '&' || *scan == '#' || *scan == '!' || *scan == '.') && cvi < 63) {
                                candidate[cvi++] = *scan++;
                            }
                            candidate[cvi] = '\0';
                            const char *temp = scan;
                            skip_whitespace(&temp);
                            bool is_func_or_expr = (*temp == '(' || *temp == '+' || *temp == '-' || *temp == '*' || *temp == '/');

                            if (candidate[0] && !is_func_or_expr) {
                                strcpy(var_name, candidate);
                                p = scan;
                            } else {
                                direct_val = qb_eval_expression(interp->env, &p);
                                is_direct_val = true;
                            }
                        }
                    } else {
                        const char *scan = p;
                        char candidate[64] = {0};
                        int cvi = 0;
                        while ((isalnum((unsigned char)*scan) || *scan == '_' || *scan == '$' || *scan == '%' || *scan == '&' || *scan == '#' || *scan == '!' || *scan == '.') && cvi < 63) {
                            candidate[cvi++] = *scan++;
                        }
                        candidate[cvi] = '\0';

                        bool is_type_var = (find_var_type_idx(interp, candidate) >= 0);
                        if (is_type_var) {
                            strcpy(var_name, candidate);
                            p = scan;
                        } else {
                            QB_Value rv = qb_eval_expression(interp->env, &p);
                            rec_or_pos = (long)rv.number;
                            has_rec = true;
                            qb_val_free(&rv);
                        }
                    }
                }
            }

            qb_file_put(interp, fnum, rec_or_pos, has_rec, var_name, is_direct_val, direct_val);
            if (is_direct_val) {
                qb_val_free(&direct_val);
            }
            return true;
        }

        if (*p == '(') p++;
        QB_Value vx = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ',') p++;
        QB_Value vy = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (*p == ')') p++;
        skip_whitespace(&p);
        if (*p == ',') p++;
        skip_whitespace(&p);
        char arr_name[64] = {0};
        int ani = 0;
        while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!') && ani < 63) {
            arr_name[ani++] = *p++;
        }
        arr_name[ani] = '\0';
        skip_whitespace(&p);
        int arr_offset = 0;
        if (*p == '(') {
            p++;
            QB_Value off_v = qb_eval_expression(interp->env, &p);
            arr_offset = (int)off_v.number;
            qb_val_free(&off_v);
            skip_whitespace(&p);
            if (*p == ')') p++;
        }
        skip_whitespace(&p);
        char action[32] = "XOR";
        if (*p == ',') {
            p++;
            skip_whitespace(&p);
            int ai = 0;
            while (isalpha((unsigned char)*p) && ai < 31) {
                action[ai++] = *p++;
            }
            action[ai] = '\0';
        }
        qb_gfx_put((int)vx.number, (int)vy.number, interp->env, arr_name, arr_offset, action);
        qb_val_free(&vx);
        qb_val_free(&vy);
        return true;
    }

    // SWAP lv1, lv2
    if (match_keyword(&p, "SWAP")) {
        QB_LValue lv1, lv2;
        if (parse_lvalue(&p, interp->env, &lv1)) {
            skip_whitespace(&p);
            if (*p == ',') p++;
            if (parse_lvalue(&p, interp->env, &lv2)) {
                QB_Value v1 = lval_get(&lv1, interp->env);
                QB_Value v2 = lval_get(&lv2, interp->env);
                lval_set(&lv1, interp->env, v2);
                lval_set(&lv2, interp->env, v1);
                qb_val_free(&v1);
                qb_val_free(&v2);
                return true;
            }
        }
    }

    // DIM / REDIM [SHARED] arr(bounds) [AS TypeName] [, var2 ...]
    if (match_keyword(&p, "DIM") || match_keyword(&p, "REDIM")) {
        bool is_shared = match_keyword(&p, "SHARED");
        while (*p) {
            skip_whitespace(&p);
            char arr_name[64];
            int idx = 0;
            while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '!' || *p == '#') && idx < 63) {
                arr_name[idx++] = *p++;
                if (p[-1] == '$' || p[-1] == '%' || p[-1] == '&' || p[-1] == '!' || p[-1] == '#') break;
            }
            arr_name[idx] = '\0';
            skip_whitespace(&p);

            if (is_shared) {
                qb_add_shared_var(interp, arr_name);
            }

            char res_buf[128];
            const char *resolved_arr = qb_resolve_var_name(interp->env, arr_name, res_buf, sizeof(res_buf));

            bool is_array = false;
            int dims = 0;
            int lbounds[QB_MAX_DIMS] = {0};
            int ubounds[QB_MAX_DIMS] = {0};

            if (*p == '(') {
                p++;
                is_array = true;
                skip_whitespace(&p);
                while (*p && *p != ')' && dims < QB_MAX_DIMS) {
                    QB_Value b1 = qb_eval_expression(interp->env, &p);
                    lbounds[dims] = 0;
                    ubounds[dims] = (int)b1.number;
                    if (match_keyword(&p, "TO")) {
                        lbounds[dims] = (int)b1.number;
                        QB_Value b2 = qb_eval_expression(interp->env, &p);
                        ubounds[dims] = (int)b2.number;
                        qb_val_free(&b2);
                    }
                    qb_val_free(&b1);
                    dims++;
                    skip_whitespace(&p);
                    if (*p == ',') {
                        p++;
                        skip_whitespace(&p);
                    } else {
                        break;
                    }
                }
                skip_whitespace(&p);
                if (*p == ')') p++;
                if (dims == 1 && ubounds[0] <= 0 && lbounds[0] == 0) ubounds[0] = 100;
            }

            char type_name[64] = {0};
            if (match_keyword(&p, "AS")) {
                skip_whitespace(&p);
                int tni = 0;
                while (*p && !isspace((unsigned char)*p) && *p != ',' && *p != '*' && tni < 63) {
                    type_name[tni++] = *p++;
                }
                type_name[tni] = '\0';
                if (*p == '*') {
                    while (*p && !isspace((unsigned char)*p) && *p != ',') p++;
                }
            }

            // Vérifier si type_name correspond à un type utilisateur (TYPE ... END TYPE)
            int type_idx = -1;
            if (type_name[0]) {
                for (int t = 0; t < interp->type_def_count; t++) {
                    if (strcasecmp(interp->type_defs[t].name, type_name) == 0) {
                        type_idx = t;
                        break;
                    }
                }
            }

            if (type_idx >= 0) {
                if (interp->var_type_count < 128) {
                    int vti = interp->var_type_count++;
                    strncpy(interp->var_types[vti].var_name, resolved_arr, 63);
                    strncpy(interp->var_types[vti].type_name, type_name, 63);
                }
                // Dimensionner ou instancier chaque champ du type utilisateur
                for (int f = 0; f < interp->type_defs[type_idx].field_count; f++) {
                    char comp[128];
                    snprintf(comp, sizeof(comp), "%s.%s", resolved_arr, interp->type_defs[type_idx].fields[f].name);
                    const char *ftype = interp->type_defs[type_idx].fields[f].type_name;
                    skip_whitespace(&ftype);
                    if (is_array) {
                        qb_array_dim(interp->env, comp, dims, lbounds, ubounds);
                    } else {
                        if (strncasecmp(ftype, "STRING", 6) == 0) {
                            int wid = 0;
                            const char *star = strchr(ftype, '*');
                            if (star) wid = atoi(star + 1);
                            if (wid <= 0) wid = 16;
                            char *spc = (char*)malloc(wid + 1);
                            memset(spc, ' ', wid);
                            spc[wid] = '\0';
                            qb_env_set(interp->env, comp, qb_val_string_len(spc, wid));
                            free(spc);
                        } else {
                            qb_env_set(interp->env, comp, qb_val_number(0.0));
                        }
                    }
                }
                if (is_array) {
                    qb_array_dim(interp->env, resolved_arr, dims, lbounds, ubounds);
                }
            } else {
                if (is_array) {
                    qb_array_dim(interp->env, resolved_arr, dims, lbounds, ubounds);
                } else {
                    qb_env_set(interp->env, resolved_arr, qb_val_number(0.0));
                }
            }

            skip_whitespace(&p);
            if (*p == ',') p++;
            else break;
        }
        return true;
    }

    // READ lval1 [, lval2 ...]
    if (match_keyword(&p, "READ")) {
        while (*p) {
            QB_LValue lv;
            if (parse_lvalue(&p, interp->env, &lv)) {
                if (interp->data_pool.current_idx < interp->data_pool.count) {
                    const char *item = interp->data_pool.items[interp->data_pool.current_idx++];
                    QB_Value val;
                    if (qb_is_string_var(lv.name)) {
                        val = qb_val_string(item);
                    } else {
                        val = qb_val_number(atof(item));
                    }
                    lval_set(&lv, interp->env, val);
                    qb_val_free(&val);
                } else {
                    fprintf(stderr, "Erreur: Out of DATA\n");
                }
            }
            skip_whitespace(&p);
            if (*p == ',') p++;
            else break;
        }
        return true;
    }

    // RESTORE [label]
    if (match_keyword(&p, "RESTORE")) {
        skip_whitespace(&p);
        if (*p && *p != ':' && *p != '\'') {
            char target[64] = {0};
            int ti = 0;
            while (*p && !isspace((unsigned char)*p) && *p != ':' && *p != '\'' && ti < 63) {
                target[ti++] = *p++;
            }
            target[ti] = '\0';
            int target_line = find_label_or_linenum(interp->program, target);
            if (target_line >= 0) {
                int found_idx = interp->data_pool.count;
                for (int d = 0; d < interp->data_pool.count; d++) {
                    if (interp->data_pool.line_numbers && interp->data_pool.line_numbers[d] >= target_line) {
                        found_idx = d;
                        break;
                    }
                }
                interp->data_pool.current_idx = found_idx;
                return true;
            }
        }
        interp->data_pool.current_idx = 0;
        return true;
    }

    // OPEN filename [FOR mode] [ACCESS ...] [LOCK ...] AS [#]n [LEN = reclen]
    // OU OPEN mode, [#]n, filename [, reclen]
    if (match_keyword(&p, "OPEN")) {
        QB_Value arg1 = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        char mode[16] = "rb+";
        QB_FileMode file_mode = QB_FILE_MODE_RANDOM;
        int file_num = 1;
        int reclen = 128;
        QB_Value fn = qb_val_null();

        if (*p == ',') {
            // OPEN mode, [#]n, filename [, reclen]
            p++;
            skip_whitespace(&p);
            if (*p == '#') p++;
            QB_Value fnum_v = qb_eval_expression(interp->env, &p);
            file_num = (int)fnum_v.number;
            qb_val_free(&fnum_v);
            skip_whitespace(&p);
            if (*p == ',') p++;
            fn = qb_eval_expression(interp->env, &p);
            skip_whitespace(&p);
            if (*p == ',') {
                p++;
                QB_Value rlv = qb_eval_expression(interp->env, &p);
                reclen = (int)rlv.number;
                qb_val_free(&rlv);
            }

            char mchar = (arg1.type == QB_VAL_STRING && arg1.string && arg1.string[0]) ? (char)toupper((unsigned char)arg1.string[0]) : 'R';
            if (mchar == 'O') { strcpy(mode, "w"); file_mode = QB_FILE_MODE_OUTPUT; reclen = 0; }
            else if (mchar == 'I') { strcpy(mode, "r"); file_mode = QB_FILE_MODE_INPUT; reclen = 0; }
            else if (mchar == 'A') { strcpy(mode, "a"); file_mode = QB_FILE_MODE_APPEND; reclen = 0; }
            else if (mchar == 'B') { strcpy(mode, "rb+"); file_mode = QB_FILE_MODE_BINARY; reclen = 0; }
            else { strcpy(mode, "rb+"); file_mode = QB_FILE_MODE_RANDOM; }
            qb_val_free(&arg1);
        } else {
            // OPEN filename [FOR mode] [ACCESS ...] [LOCK ...] AS #n [LEN = reclen]
            fn = arg1;
            if (match_keyword(&p, "FOR")) {
                if (match_keyword(&p, "OUTPUT")) { strcpy(mode, "w"); file_mode = QB_FILE_MODE_OUTPUT; reclen = 0; }
                else if (match_keyword(&p, "APPEND")) { strcpy(mode, "a"); file_mode = QB_FILE_MODE_APPEND; reclen = 0; }
                else if (match_keyword(&p, "INPUT")) { strcpy(mode, "r"); file_mode = QB_FILE_MODE_INPUT; reclen = 0; }
                else if (match_keyword(&p, "BINARY")) { strcpy(mode, "rb+"); file_mode = QB_FILE_MODE_BINARY; reclen = 0; }
                else if (match_keyword(&p, "RANDOM")) { strcpy(mode, "rb+"); file_mode = QB_FILE_MODE_RANDOM; reclen = 128; }
            }
            if (match_keyword(&p, "ACCESS")) {
                match_keyword(&p, "READ");
                match_keyword(&p, "WRITE");
            }
            if (match_keyword(&p, "LOCK")) {
                match_keyword(&p, "SHARED");
                match_keyword(&p, "READ");
                match_keyword(&p, "WRITE");
            }
            match_keyword(&p, "AS");
            skip_whitespace(&p);
            if (*p == '#') p++;
            QB_Value fnum_v = qb_eval_expression(interp->env, &p);
            file_num = (int)fnum_v.number;
            qb_val_free(&fnum_v);
            skip_whitespace(&p);
            if (match_keyword(&p, "LEN")) {
                skip_whitespace(&p);
                if (*p == '=') p++;
                QB_Value rlv = qb_eval_expression(interp->env, &p);
                reclen = (int)rlv.number;
                qb_val_free(&rlv);
            }
        }

        if (file_num >= 1 && file_num <= 255) {
            if (interp->files[file_num]) {
                fclose(interp->files[file_num]);
                interp->files[file_num] = NULL;
            }
            const char *fname = (fn.type == QB_VAL_STRING && fn.string) ? fn.string : "";
            if (file_mode == QB_FILE_MODE_RANDOM || file_mode == QB_FILE_MODE_BINARY) {
                FILE *f = qb_fopen_helper(fname, "rb+");
                if (!f) f = qb_fopen_helper(fname, "wb+");
                interp->files[file_num] = f;
            } else {
                interp->files[file_num] = qb_fopen_helper(fname, mode);
            }
            interp->file_buf[file_num][0] = '\0';
            interp->file_buf_pos[file_num] = 0;
            interp->file_modes[file_num] = file_mode;
            interp->file_record_lens[file_num] = (reclen > 0) ? reclen : 128;
            interp->file_current_record[file_num] = 0;
            interp->file_last_pos[file_num] = 0;
            interp->file_fields[file_num].count = 0;
            memset(interp->file_random_buffers[file_num], ' ', sizeof(interp->file_random_buffers[file_num]));
            if (strcmp(mode, "r") == 0 && !interp->files[file_num]) {
                qb_trigger_error(interp, 53); // File not found
            }
        }
        qb_val_free(&fn);
        return true;
    }

    // CLOSE [#n [, #n2 ...]]
    if (match_keyword(&p, "CLOSE")) {
        skip_whitespace(&p);
        if (!*p || *p == ':') {
            for (int i = 1; i <= 255; i++) {
                if (interp->files[i]) {
                    fclose(interp->files[i]);
                    interp->files[i] = NULL;
                    interp->file_modes[i] = QB_FILE_MODE_NONE;
                    interp->file_fields[i].count = 0;
                    interp->file_buf[i][0] = '\0';
                    interp->file_buf_pos[i] = 0;
                }
            }
        } else {
            while (*p && *p != ':') {
                skip_whitespace(&p);
                if (*p == '#') p++;
                QB_Value fn_v = qb_eval_expression(interp->env, &p);
                int fn = (int)fn_v.number;
                qb_val_free(&fn_v);
                if (fn >= 1 && fn <= 255 && interp->files[fn]) {
                    fclose(interp->files[fn]);
                    interp->files[fn] = NULL;
                    interp->file_modes[fn] = QB_FILE_MODE_NONE;
                    interp->file_fields[fn].count = 0;
                    interp->file_buf[fn][0] = '\0';
                    interp->file_buf_pos[fn] = 0;
                }
                skip_whitespace(&p);
                if (*p == ',') p++;
                else break;
            }
        }
        return true;
    }

    // PRINT [#n,] [USING fmt$;] [expr] [, | ; expr ...]
    if (match_keyword(&p, "PRINT") || *p == '?') {
        if (*p == '?') p++;
        skip_whitespace(&p);
        FILE *target_out = stdout;

        if (*p == '#') {
            p++;
            int file_num = atoi(p);
            while (isdigit((unsigned char)*p)) p++;
            skip_whitespace(&p);
            if (*p == ',') p++;
            if (file_num >= 1 && file_num <= 255 && interp->files[file_num]) {
                target_out = interp->files[file_num];
            }
        }

        skip_whitespace(&p);
        if (match_keyword(&p, "USING")) {
            QB_Value fmt_val = qb_eval_expression(interp->env, &p);
            const char *fmt_str = (fmt_val.type == QB_VAL_STRING && fmt_val.string) ? fmt_val.string : "";
            skip_whitespace(&p);
            if (*p == ';' || *p == ',') p++;

            bool newline = true;
            while (*p && *p != ':') {
                skip_whitespace(&p);
                if (!*p || *p == ':' || *p == '\'' || match_keyword(&p, "REM")) {
                    while (*p && *p != ':') p++;
                    break;
                }
                QB_Value arg = qb_eval_expression(interp->env, &p);
                char formatted[256];
                qb_format_using(fmt_str, arg, formatted, sizeof(formatted));
                qb_val_free(&arg);

                if (target_out == stdout) {
                    qb_print_string(formatted);
                } else {
                    fprintf(target_out, "%s", formatted);
                }

                skip_whitespace(&p);
                if (*p == ';') {
                    p++;
                    newline = false;
                } else if (*p == ',') {
                    p++;
                    newline = false;
                } else {
                    newline = true;
                    break;
                }
            }
            qb_val_free(&fmt_val);
            if (newline) {
                if (target_out == stdout) {
                    qb_print_string("\n");
                } else {
                    fputc('\n', target_out);
                }
            }
            if (target_out != stdout) fflush(target_out);
            return true;
        }

        bool newline = true;
        while (*p && *p != ':') {
            skip_whitespace(&p);
            if (!*p || *p == ':' || *p == '\'' || match_keyword(&p, "REM")) {
                while (*p && *p != ':') p++;
                break;
            }
            if (match_keyword(&p, "TAB")) {
                skip_whitespace(&p);
                if (*p == '(') p++;
                QB_Value tcol = qb_eval_expression(interp->env, &p);
                skip_whitespace(&p);
                if (*p == ')') p++;
                int target_c = (int)tcol.number;
                qb_val_free(&tcol);
                if (target_out == stdout) {
                    qb_locate(-1, target_c);
                } else {
                    for (int s = 0; s < target_c; s++) fputc(' ', target_out);
                }
                skip_whitespace(&p);
                if (*p == ';') { p++; newline = false; }
                else if (*p == ',') { p++; newline = false; }
                continue;
            }

            QB_Value v = qb_eval_expression(interp->env, &p);
            if (v.type == QB_VAL_NUMBER) {
                char sbuf[64];
                if (v.number == (long long)v.number) {
                    snprintf(sbuf, sizeof(sbuf), "%lld", (long long)v.number);
                } else {
                    snprintf(sbuf, sizeof(sbuf), "%g", v.number);
                }
                if (target_out == stdout) {
                    qb_print_string(sbuf);
                } else {
                    fprintf(target_out, "%s", sbuf);
                }
            } else if (v.type == QB_VAL_STRING) {
                if (target_out == stdout) {
                    qb_print_string(v.string ? v.string : "");
                } else {
                    if (v.string && v.string_len > 0) {
                        fwrite(v.string, 1, v.string_len, target_out);
                    }
                }
            }
            qb_val_free(&v);

            skip_whitespace(&p);
            newline = true;
            if (*p == ';') {
                p++;
                newline = false;
            } else if (*p == ',') {
                p++;
                if (target_out == stdout) {
                    qb_print_string("\t");
                } else {
                    fprintf(target_out, "\t");
                }
                newline = false;
            } else if (*p == '\'' || match_keyword(&p, "REM")) {
                while (*p && *p != ':') p++;
                break;
            } else if (!*p || *p == ':') {
                break;
            } else {
                newline = true;
                break;
            }
            skip_whitespace(&p);
            if (*p == '\'' || match_keyword(&p, "REM")) {
                while (*p && *p != ':') p++;
                break;
            }
        }
        if (newline) {
            if (target_out == stdout) {
                qb_print_string("\n");
            } else {
                fputc('\n', target_out);
            }
        }
        if (target_out != stdout) fflush(target_out);
        return true;
    }

    // LINE INPUT [;] [#n,] ["prompt";] var$
    if (match_keyword(&p, "LINE") && match_keyword(&p, "INPUT")) {
        skip_whitespace(&p);
        if (*p == ';') p++;
        FILE *target_in = stdin;
        int file_num = 0;
        if (*p == '#') {
            p++;
            file_num = atoi(p);
            while (isdigit((unsigned char)*p)) p++;
            skip_whitespace(&p);
            if (*p == ',') p++;
            if (file_num >= 1 && file_num <= 255 && interp->files[file_num]) {
                target_in = interp->files[file_num];
            }
        }
        skip_whitespace(&p);
        if (*p == '"') {
            p++;
            char prompt[256] = {0};
            int idx = 0;
            while (*p && *p != '"' && idx < 250) prompt[idx++] = *p++;
            if (*p == '"') p++;
            skip_whitespace(&p);
            if (*p == ';' || *p == ',') p++;
            qb_print_string(prompt);
        }
        QB_LValue lv;
        if (parse_lvalue(&p, interp->env, &lv)) {
            char input_buf[2048] = {0};
            if (target_in == stdin) {
                if (!qb_console_read_line(input_buf, sizeof(input_buf))) {
                    interp->running = false;
                    return true;
                }
            } else {
                if (file_num >= 1 && file_num <= 255) {
                    interp->file_buf[file_num][0] = '\0';
                    interp->file_buf_pos[file_num] = 0;
                }
                if (fgets(input_buf, sizeof(input_buf), target_in)) {
                    char *nl = strchr(input_buf, '\n');
                    if (nl) *nl = '\0';
                    nl = strchr(input_buf, '\r');
                    if (nl) *nl = '\0';
                } else {
                    interp->running = false;
                    return true;
                }
            }
            lval_set(&lv, interp->env, qb_val_string(input_buf));
        }
        return true;
    }

    // INPUT [;] [#n,] ["prompt"{;|,}] var1 [, var2 ...]
    if (match_keyword(&p, "INPUT")) {
        skip_whitespace(&p);
        if (*p == ';') p++;
        FILE *target_in = stdin;
        int file_num = 0;
        if (*p == '#') {
            p++;
            file_num = atoi(p);
            while (isdigit((unsigned char)*p)) p++;
            skip_whitespace(&p);
            if (*p == ',') p++;
            if (file_num >= 1 && file_num <= 255 && interp->files[file_num]) {
                target_in = interp->files[file_num];
            }
        }
        skip_whitespace(&p);
        char prompt[256] = "? ";
        if (target_in != stdin) prompt[0] = '\0';
        if (*p == '"') {
            p++;
            int idx = 0;
            while (*p && *p != '"' && idx < 240) prompt[idx++] = *p++;
            if (*p == '"') p++;
            skip_whitespace(&p);
            if (*p == ';') {
                p++;
                prompt[idx++] = '?';
                prompt[idx++] = ' ';
                prompt[idx] = '\0';
            } else if (*p == ',') {
                p++;
                prompt[idx] = '\0';
            } else {
                prompt[idx++] = '?';
                prompt[idx++] = ' ';
                prompt[idx] = '\0';
            }
        }
        if (target_in == stdin && prompt[0]) {
            qb_print_string(prompt);
        }

        if (target_in != stdin) {
            while (*p) {
                QB_LValue lv;
                if (!parse_lvalue(&p, interp->env, &lv)) break;

                char val_str[1024] = {0};
                if (!qb_read_file_token(interp, file_num, val_str, sizeof(val_str))) {
                    interp->running = false;
                    return true;
                }

                if (qb_is_string_var(lv.name)) {
                    lval_set(&lv, interp->env, qb_val_string(val_str));
                } else {
                    lval_set(&lv, interp->env, qb_val_number(atof(val_str)));
                }

                skip_whitespace(&p);
                if (*p == ',') p++;
                else break;
            }
            return true;
        }

        char input_buf[1024] = {0};
        if (!qb_console_read_line(input_buf, sizeof(input_buf))) {
            interp->running = false;
            return true;
        }

        char *tok = input_buf;
        while (*p) {
            QB_LValue lv;
            if (!parse_lvalue(&p, interp->env, &lv)) break;

            char val_str[256] = {0};
            int vi = 0;
            while (*tok && isspace((unsigned char)*tok)) tok++;
            while (*tok && *tok != ',' && vi < 255) {
                val_str[vi++] = *tok++;
            }
            val_str[vi] = '\0';
            while (vi > 0 && isspace((unsigned char)val_str[vi - 1])) {
                val_str[--vi] = '\0';
            }
            if (*tok == ',') tok++;

            if (qb_is_string_var(lv.name)) {
                lval_set(&lv, interp->env, qb_val_string(val_str));
            } else {
                lval_set(&lv, interp->env, qb_val_number(atof(val_str)));
            }

            skip_whitespace(&p);
            if (*p == ',') p++;
            else break;
        }
        return true;
    }

    // CALL SubName(...) ou CALL SubName args
    if (match_keyword(&p, "CALL")) {
        skip_whitespace(&p);
        char sub_name[64] = {0};
        int sni = 0;
        while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!') && sni < 63) {
            sub_name[sni++] = *p++;
        }
        sub_name[sni] = '\0';
        int proc_idx = -1;
        for (int i = 0; i < interp->proc_count; i++) {
            if (strcasecmp(interp->procs[i].name, sub_name) == 0) {
                proc_idx = i;
                break;
            }
        }
        if (proc_idx >= 0) {
            skip_whitespace(&p);
            bool has_paren = (*p == '(');
            if (has_paren) p++;
            QB_Value args[16];
            char arg_refs[16][64];
            int arg_count = 0;
            parse_proc_args(interp->env, &p, args, arg_refs, &arg_count, 16);
            if (has_paren && *p == ')') p++;
            execute_sub(interp, proc_idx, args, arg_count, (const char (*)[64])arg_refs);
            for (int i = 0; i < arg_count; i++) qb_val_free(&args[i]);
            return true;
        }
    }

    // Appel implicite d'une SUB
    for (int pi = 0; pi < interp->proc_count; pi++) {
        if (!interp->procs[pi].is_function) {
            const char *save_sub_p = p;
            if (match_keyword(&p, interp->procs[pi].name)) {
                QB_Value args[16];
                char arg_refs[16][64];
                int arg_count = 0;
                parse_proc_args(interp->env, &p, args, arg_refs, &arg_count, 16);
                execute_sub(interp, pi, args, arg_count, (const char (*)[64])arg_refs);
                for (int i = 0; i < arg_count; i++) qb_val_free(&args[i]);
                return true;
            }
            p = save_sub_p;
        }
    }

    // Single-line IF condition THEN statement [ELSE statement]
    // or IF condition GOTO linenum/label [ELSE statement]
    if (match_keyword(&p, "IF")) {
        QB_Value cond = qb_eval_expression(interp->env, &p);
        bool is_true = (cond.number != 0.0);
        qb_val_free(&cond);

        bool is_goto = false;
        if (match_keyword(&p, "THEN")) {
            // normal THEN
        } else if (match_keyword(&p, "GOTO")) {
            is_goto = true;
        } else {
            return true;
        }

        skip_whitespace(&p);
        if (*p) {
            char then_part[1024] = {0};
            char else_part[1024] = {0};

            if (is_goto) {
                snprintf(then_part, sizeof(then_part), "GOTO ");
            }

            const char *else_ptr = NULL;
            bool in_q = false;
            for (const char *ep = p; *ep; ep++) {
                if (*ep == '"') in_q = !in_q;
                else if (!in_q && strncasecmp(ep, "ELSE", 4) == 0 &&
                         (ep == p || isspace((unsigned char)ep[-1]) || ep[-1] == ':') &&
                         (isspace((unsigned char)ep[4]) || ep[4] == '\0' || ep[4] == ':')) {
                    else_ptr = ep;
                    break;
                }
            }

            if (else_ptr) {
                size_t offset = strlen(then_part);
                size_t len = else_ptr - p;
                if (offset + len >= sizeof(then_part)) len = sizeof(then_part) - 1 - offset;
                strncat(then_part, p, len);
                strncpy(else_part, else_ptr + 4, sizeof(else_part) - 1);
                else_part[sizeof(else_part) - 1] = '\0';
            } else {
                strncat(then_part, p, sizeof(then_part) - 1 - strlen(then_part));
            }

            char *tp = then_part;
            while (*tp && isspace((unsigned char)*tp)) tp++;
            char *ep = else_part;
            while (*ep && isspace((unsigned char)*ep)) ep++;

            char fixed_then[1024] = {0};
            if (isdigit((unsigned char)*tp)) {
                snprintf(fixed_then, sizeof(fixed_then), "GOTO %s", tp);
            } else {
                strncpy(fixed_then, tp, sizeof(fixed_then) - 1);
            }

            char fixed_else[1024] = {0};
            if (isdigit((unsigned char)*ep)) {
                snprintf(fixed_else, sizeof(fixed_else), "GOTO %s", ep);
            } else {
                strncpy(fixed_else, ep, sizeof(fixed_else) - 1);
            }

            if (is_true) {
                return qb_interp_exec_immediate(interp, fixed_then);
            } else if (fixed_else[0]) {
                return qb_interp_exec_immediate(interp, fixed_else);
            }
            return true;
        }
    }

    // FIELD #n, width AS var$ [, width2 AS var2$ ...]
    if (match_keyword(&p, "FIELD")) {
        skip_whitespace(&p);
        if (*p == '#') p++;
        skip_whitespace(&p);
        QB_Value fv = qb_eval_expression(interp->env, &p);
        int fnum = (int)fv.number;
        qb_val_free(&fv);

        if (fnum >= 1 && fnum <= 255) {
            interp->file_fields[fnum].count = 0;
            int curr_off = 0;
            while (*p && *p != ':' && *p != '\n') {
                skip_whitespace(&p);
                if (*p == ',') { p++; skip_whitespace(&p); }
                if (!*p || *p == ':' || *p == '\n') break;

                QB_Value wv = qb_eval_expression(interp->env, &p);
                int width = (int)wv.number;
                qb_val_free(&wv);
                skip_whitespace(&p);

                if (match_keyword(&p, "AS")) {
                    skip_whitespace(&p);
                }

                char var_name[64] = {0};
                int vi = 0;
                while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!') && vi < 63) {
                    var_name[vi++] = *p++;
                }
                var_name[vi] = '\0';

                int fidx = interp->file_fields[fnum].count;
                if (fidx < QB_MAX_FIELD_VARS && width > 0) {
                    interp->file_fields[fnum].fields[fidx].width = width;
                    interp->file_fields[fnum].fields[fidx].offset = curr_off;
                    strncpy(interp->file_fields[fnum].fields[fidx].var_name, var_name, 63);
                    interp->file_fields[fnum].count++;

                    qb_env_set(interp->env, var_name, qb_val_string_len(interp->file_random_buffers[fnum] + curr_off, width));
                    curr_off += width;
                }
                skip_whitespace(&p);
                if (*p == ',') {
                    // continue
                } else {
                    break;
                }
            }
        }
        return true;
    }

    // LSET var$ = expr$
    if (match_keyword(&p, "LSET")) {
        skip_whitespace(&p);
        char var_name[64] = {0};
        int vi = 0;
        while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!' || *p == '.') && vi < 63) {
            var_name[vi++] = *p++;
        }
        var_name[vi] = '\0';
        skip_whitespace(&p);
        if (*p == '=') p++;
        skip_whitespace(&p);
        QB_Value val = qb_eval_expression(interp->env, &p);
        const char *src = (val.type == QB_VAL_STRING && val.string) ? val.string : "";
        int slen = (val.type == QB_VAL_STRING) ? val.string_len : 0;
        qb_apply_lset_rset(interp, var_name, src, slen, false);
        qb_val_free(&val);
        return true;
    }

    // RSET var$ = expr$
    if (match_keyword(&p, "RSET")) {
        skip_whitespace(&p);
        char var_name[64] = {0};
        int vi = 0;
        while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!' || *p == '.') && vi < 63) {
            var_name[vi++] = *p++;
        }
        var_name[vi] = '\0';
        skip_whitespace(&p);
        if (*p == '=') p++;
        skip_whitespace(&p);
        QB_Value val = qb_eval_expression(interp->env, &p);
        const char *src = (val.type == QB_VAL_STRING && val.string) ? val.string : "";
        int slen = (val.type == QB_VAL_STRING) ? val.string_len : 0;
        qb_apply_lset_rset(interp, var_name, src, slen, true);
        qb_val_free(&val);
        return true;
    }

    // SEEK #n, pos
    if (match_keyword(&p, "SEEK")) {
        skip_whitespace(&p);
        if (*p == '#') p++;
        skip_whitespace(&p);
        QB_Value fv = qb_eval_expression(interp->env, &p);
        int fnum = (int)fv.number;
        qb_val_free(&fv);
        skip_whitespace(&p);
        if (*p == ',') p++;
        skip_whitespace(&p);
        QB_Value pv = qb_eval_expression(interp->env, &p);
        long pos = (long)pv.number;
        qb_val_free(&pv);
        if (fnum >= 1 && fnum <= 255 && interp->files[fnum]) {
            FILE *f = interp->files[fnum];
            QB_FileMode mode = interp->file_modes[fnum];
            if (mode == QB_FILE_MODE_RANDOM) {
                int rlen = interp->file_record_lens[fnum];
                if (rlen <= 0) rlen = 128;
                if (pos <= 0) pos = 1;
                interp->file_current_record[fnum] = pos - 1;
                interp->file_last_pos[fnum] = pos;
                fseek(f, (pos - 1) * (long)rlen, SEEK_SET);
            } else {
                if (pos <= 0) pos = 1;
                fseek(f, pos - 1, SEEK_SET);
                interp->file_last_pos[fnum] = pos;
            }
        } else {
            qb_trigger_error(interp, 52);
        }
        return true;
    }

    // NAME old$ AS new$
    if (match_keyword(&p, "NAME")) {
        skip_whitespace(&p);
        QB_Value old_v = qb_eval_expression(interp->env, &p);
        skip_whitespace(&p);
        if (match_keyword(&p, "AS")) {
            skip_whitespace(&p);
        }
        QB_Value new_v = qb_eval_expression(interp->env, &p);
        if (old_v.type == QB_VAL_STRING && old_v.string && new_v.type == QB_VAL_STRING && new_v.string) {
            if (rename(old_v.string, new_v.string) != 0) {
                const char *pdir = qb_get_program_dir();
                if (pdir && pdir[0] && !strchr(old_v.string, ':')) {
                    char f1[512], f2[512];
                    snprintf(f1, sizeof(f1), "%s/%s", pdir, old_v.string);
                    snprintf(f2, sizeof(f2), "%s/%s", pdir, new_v.string);
                    if (rename(f1, f2) != 0) {
                        qb_trigger_error(interp, 53);
                    }
                } else {
                    qb_trigger_error(interp, 53);
                }
            }
        }
        qb_val_free(&old_v);
        qb_val_free(&new_v);
        return true;
    }

    // MKDIR dir$
    if (match_keyword(&p, "MKDIR")) {
        skip_whitespace(&p);
        QB_Value dir_v = qb_eval_expression(interp->env, &p);
        if (dir_v.type == QB_VAL_STRING && dir_v.string) {
            if (_mkdir(dir_v.string) != 0) {
                const char *pdir = qb_get_program_dir();
                if (pdir && pdir[0] && !strchr(dir_v.string, ':') && dir_v.string[0] != '/' && dir_v.string[0] != '\\') {
                    char full_dir[512];
                    snprintf(full_dir, sizeof(full_dir), "%s/%s", pdir, dir_v.string);
                    _mkdir(full_dir);
                }
            }
        }
        qb_val_free(&dir_v);
        return true;
    }

    // RMDIR dir$
    if (match_keyword(&p, "RMDIR")) {
        skip_whitespace(&p);
        QB_Value dir_v = qb_eval_expression(interp->env, &p);
        if (dir_v.type == QB_VAL_STRING && dir_v.string) {
            if (_rmdir(dir_v.string) != 0) {
                const char *pdir = qb_get_program_dir();
                if (pdir && pdir[0] && !strchr(dir_v.string, ':') && dir_v.string[0] != '/' && dir_v.string[0] != '\\') {
                    char full_dir[512];
                    snprintf(full_dir, sizeof(full_dir), "%s/%s", pdir, dir_v.string);
                    _rmdir(full_dir);
                }
            }
        }
        qb_val_free(&dir_v);
        return true;
    }

    // CHDIR dir$
    if (match_keyword(&p, "CHDIR")) {
        skip_whitespace(&p);
        QB_Value dir_v = qb_eval_expression(interp->env, &p);
        if (dir_v.type == QB_VAL_STRING && dir_v.string) {
            _chdir(dir_v.string);
        }
        qb_val_free(&dir_v);
        return true;
    }

    // FILES [pattern$]
    if (match_keyword(&p, "FILES")) {
        skip_whitespace(&p);
        char pattern[260] = "*.*";
        if (*p != '\0' && *p != ':') {
            QB_Value pv = qb_eval_expression(interp->env, &p);
            if (pv.type == QB_VAL_STRING && pv.string && pv.string[0]) {
                strncpy(pattern, pv.string, sizeof(pattern) - 1);
            }
            qb_val_free(&pv);
        }
        struct _finddata_t fileinfo;
        intptr_t handle = _findfirst(pattern, &fileinfo);
        if (handle != -1) {
            int col = 0;
            do {
                if (fileinfo.attrib & _A_SUBDIR) {
                    char dname[64];
                    snprintf(dname, sizeof(dname), "<%s>", fileinfo.name);
                    qb_print_string(dname);
                } else {
                    qb_print_string(fileinfo.name);
                }
                qb_print_string("  ");
                col++;
                if (col >= 4) {
                    qb_print_string("\n");
                    col = 0;
                }
            } while (_findnext(handle, &fileinfo) == 0);
            _findclose(handle);
            if (col > 0) qb_print_string("\n");
        } else {
            qb_print_string("File not found\n");
        }
        return true;
    }

    // LET lval = expr ou simplement lval = expr
    match_keyword(&p, "LET");
    const char *save_assign = p;
    QB_LValue assign_lv;
    if (parse_lvalue(&p, interp->env, &assign_lv)) {
        skip_whitespace(&p);
        if (*p == '=') {
            p++;
            QB_Value val = qb_eval_expression(interp->env, &p);
            lval_set(&assign_lv, interp->env, val);
            qb_val_free(&val);
            return true;
        }
    }
    p = save_assign;

    // SYSTEM ou END isolé
    if (match_keyword(&p, "SYSTEM")) {
        interp->running = false;
        interp->exit_requested = true;
        return true;
    }
    if (match_keyword(&p, "END")) {
        skip_whitespace(&p);
        if (!*p || *p == '\'') {
            interp->running = false;
            interp->exit_requested = true;
            return true;
        }
    }

    return false;
}

void qb_interp_trigger_key_event(QB_Interpreter *interp, int kn) {
    if (!interp || kn < 1 || kn >= 32) return;
    if (interp->key_state[kn] == 1 || interp->key_state[kn] == 2) {
        interp->key_pending[kn] = true;
    }
}

static void qb_check_hardware_events(QB_Interpreter *interp) {
    if (!interp || !interp->running) return;
    if (interp->in_error_handler || interp->in_event_handler) return;

    // 1. Touches clavier physiques / tampon SDL
    char ch1 = 0, ch2 = 0;
    int klen = 0;
    if (sdl_inkey_peek(&ch1, &ch2, &klen)) {
        int kn = -1;
        if (klen == 2 && ch1 == 0) {
            unsigned char sc = (unsigned char)ch2;
            if (sc >= DOS_SCAN_F1 && sc <= DOS_SCAN_F10) {
                kn = 1 + (sc - DOS_SCAN_F1);
            } else if (sc == DOS_SCAN_UP) {
                kn = 11;
            } else if (sc == DOS_SCAN_LEFT) {
                kn = 12;
            } else if (sc == DOS_SCAN_RIGHT) {
                kn = 13;
            } else if (sc == DOS_SCAN_DOWN) {
                kn = 14;
            } else if (sc == DOS_SCAN_F11) {
                kn = 30;
            } else if (sc == DOS_SCAN_F12) {
                kn = 31;
            }
        }
        if (kn >= 1 && kn < 32 && interp->key_state[kn] > 0) {
            sdl_inkey_pop();
            interp->key_pending[kn] = true;
        } else if (kn >= 1 && kn <= 10 && interp->key_state[kn] == 0 && interp->key_defs[kn][0] != '\0') {
            sdl_inkey_pop();
            const char *def = interp->key_defs[kn];
            while (*def) {
                sdl_inkey_enqueue(*def++, 0, 1);
            }
        }
    }

    // 2. Traitement des événements TIMER
    if (interp->timer_state > 0 && interp->timer_trap_pc >= 0) {
        double now = qb_timer();
        if (interp->timer_last_sec <= 0.0) {
            interp->timer_last_sec = now;
        }
        double elapsed = now - interp->timer_last_sec;
        if (elapsed >= interp->timer_interval) {
            interp->timer_last_sec = now;
            interp->timer_pending = true;
        }
    }

    // 3. Traitement des événements PLAY
    if (interp->play_state > 0 && interp->play_trap_pc >= 0) {
        int remaining = qb_play_get_notes_remaining();
        if (remaining < interp->play_threshold) {
            if (!interp->play_fired) {
                interp->play_fired = true;
                interp->play_pending = true;
            }
        } else {
            interp->play_fired = false;
        }
    }

    // 4. Déclenchement (dispatch) d'un trap si actif (state == 1)
    // Priorité 1: KEY
    for (int k = 1; k < 32; k++) {
        if (interp->key_state[k] == 1 && interp->key_pending[k] && interp->key_trap_pc[k] >= 0) {
            interp->key_pending[k] = false;
            if (interp->gosub_sp < 127) {
                interp->gosub_stack[interp->gosub_sp++] = interp->pc;
                interp->in_event_handler = true;
                interp->pc = interp->key_trap_pc[k];
                return;
            }
        }
    }

    // Priorité 2: TIMER
    if (interp->timer_state == 1 && interp->timer_pending && interp->timer_trap_pc >= 0) {
        interp->timer_pending = false;
        if (interp->gosub_sp < 127) {
            interp->gosub_stack[interp->gosub_sp++] = interp->pc;
            interp->in_event_handler = true;
            interp->pc = interp->timer_trap_pc;
            return;
        }
    }

    // Priorité 3: PLAY
    if (interp->play_state == 1 && interp->play_pending && interp->play_trap_pc >= 0) {
        interp->play_pending = false;
        if (interp->gosub_sp < 127) {
            interp->gosub_stack[interp->gosub_sp++] = interp->pc;
            interp->in_event_handler = true;
            interp->pc = interp->play_trap_pc;
            return;
        }
    }
}

void qb_interp_step(QB_Interpreter *interp) {
    if (!interp || !interp->running || interp->pc >= interp->program->line_count) {
        if (interp) interp->running = false;
        return;
    }

    qb_check_hardware_events(interp);

    const char *line = interp->program->lines[interp->pc];
    static int trace_enabled = -1;
    if (trace_enabled == -1) trace_enabled = getenv("QB_TRACE") ? 1 : 0;
    if (trace_enabled) {
        fprintf(stderr, "[TRACE] %d: %s\n", interp->pc + 1, line);
        fflush(stderr);
    }
    const char *p = line;
    skip_whitespace(&p);

    if (!*p || *p == '\'' || match_keyword(&p, "REM") || match_keyword(&p, "DATA")) {
        interp->pc++;
        return;
    }

    if (isdigit((unsigned char)*p)) {
        while (isdigit((unsigned char)*p)) p++;
        skip_whitespace(&p);
    }

    // Détecter si la ligne est un label isolé (ex: "Menu:", "Start:", "Header:")
    const char *chk_lbl = p;
    while (*chk_lbl && (isalnum((unsigned char)*chk_lbl) || *chk_lbl == '_')) chk_lbl++;
    skip_whitespace(&chk_lbl);
    if (*chk_lbl == ':') {
        const char *after_colon = chk_lbl + 1;
        skip_whitespace(&after_colon);
        if (*after_colon == '\0' || *after_colon == '\'') {
            interp->pc++;
            return;
        }
    }

    // TYPE TypeName ... END TYPE
    if (match_keyword(&p, "TYPE")) {
        skip_whitespace(&p);
        char type_name[64] = {0};
        int tni = 0;
        while ((isalnum((unsigned char)*p) || *p == '_') && tni < 63) {
            type_name[tni++] = *p++;
        }
        type_name[tni] = '\0';

        int def_idx = -1;
        if (interp->type_def_count < 32) {
            def_idx = interp->type_def_count++;
            strncpy(interp->type_defs[def_idx].name, type_name, 63);
            interp->type_defs[def_idx].field_count = 0;
        }

        interp->pc++;
        while (interp->pc < interp->program->line_count) {
            const char *lp = interp->program->lines[interp->pc];
            skip_whitespace(&lp);
            if (match_keyword(&lp, "END") && match_keyword(&lp, "TYPE")) {
                interp->pc++;
                return;
            }
            if (def_idx >= 0 && *lp && *lp != '\'' && !match_keyword(&lp, "REM")) {
                char fname[64] = {0};
                int fni = 0;
                while ((isalnum((unsigned char)*lp) || *lp == '_') && fni < 63) {
                    fname[fni++] = *lp++;
                }
                fname[fni] = '\0';
                skip_whitespace(&lp);
                char ftype[32] = "INTEGER";
                if (match_keyword(&lp, "AS")) {
                    skip_whitespace(&lp);
                    int fti = 0;
                    while (*lp && *lp != ':' && *lp != '\n' && *lp != '\'' && fti < 31) {
                        ftype[fti++] = *lp++;
                    }
                    while (fti > 0 && isspace((unsigned char)ftype[fti - 1])) {
                        ftype[--fti] = '\0';
                    }
                    ftype[fti] = '\0';
                }
                if (fname[0] && interp->type_defs[def_idx].field_count < 32) {
                    int fc = interp->type_defs[def_idx].field_count++;
                    strncpy(interp->type_defs[def_idx].fields[fc].name, fname, 63);
                    strncpy(interp->type_defs[def_idx].fields[fc].type_name, ftype, 31);
                }
            }
            interp->pc++;
        }
        return;
    }

    // DEF FnRan (x) = expr
    if (match_keyword(&p, "DEF")) {
        skip_whitespace(&p);
        if (strncasecmp(p, "FN", 2) == 0) {
            qb_register_def_fn(interp, p);
            interp->pc++;
            return;
        }
    }

    // MULTI-LINE BLOCK IF ... THEN ... ELSEIF ... ELSE ... END IF
    if (match_keyword(&p, "IF")) {
        const char *th = find_keyword_caseless(p, "THEN");
        if (th) {
            const char *after_then = th + 4;
            skip_whitespace(&after_then);
            if (!*after_then || *after_then == '\'') {
                // Bloc IF multi-lignes !
                QB_Value cond = qb_eval_expression(interp->env, &p);
                bool cond_met = (cond.number != 0.0);
                qb_val_free(&cond);

                if (interp->if_sp < 63) {
                    interp->if_stack[interp->if_sp].branch_taken = cond_met;
                    interp->if_stack[interp->if_sp].end_if_pc = find_matching_end_if(interp->program, interp->pc + 1);
                    interp->if_sp++;
                }

                if (cond_met) {
                    interp->pc++;
                    return;
                } else {
                    interp->pc = find_next_if_branch(interp->program, interp->pc + 1);
                    return;
                }
            }
        }
    }

    // ELSEIF cond THEN
    if (match_keyword(&p, "ELSEIF")) {
        int top = interp->if_sp - 1;
        bool already_taken = (top >= 0) ? interp->if_stack[top].branch_taken : true;

        if (already_taken) {
            // Une branche a déjà été prise, sauter jusqu'à END IF
            interp->pc = find_matching_end_if(interp->program, interp->pc + 1);
            return;
        } else {
            // Évaluer la condition du ELSEIF
            QB_Value cond = qb_eval_expression(interp->env, &p);
            bool cond_met = (cond.number != 0.0);
            qb_val_free(&cond);

            if (cond_met) {
                if (top >= 0) interp->if_stack[top].branch_taken = true;
                interp->pc++;
                return;
            } else {
                interp->pc = find_next_if_branch(interp->program, interp->pc + 1);
                return;
            }
        }
    }

    // ELSE
    if (match_keyword(&p, "ELSE")) {
        int top = interp->if_sp - 1;
        bool already_taken = (top >= 0) ? interp->if_stack[top].branch_taken : true;

        if (already_taken) {
            interp->pc = find_matching_end_if(interp->program, interp->pc + 1);
            return;
        } else {
            if (top >= 0) interp->if_stack[top].branch_taken = true;
            interp->pc++;
            return;
        }
    }

    // END [IF | SELECT | SUB | FUNCTION | SYSTEM/seul]
    if (match_keyword(&p, "END")) {
        if (match_keyword(&p, "IF")) {
            if (interp->if_sp > 0) interp->if_sp--;
            interp->pc++;
            return;
        }
        if (match_keyword(&p, "SELECT")) {
            if (interp->select_sp > 0) {
                interp->select_sp--;
                qb_val_free(&interp->select_stack[interp->select_sp].test_val);
            }
            interp->pc++;
            return;
        }
        if (match_keyword(&p, "SUB") || match_keyword(&p, "FUNCTION")) {
            if (interp->call_sp > 0) {
                int sp = --interp->call_sp;
                unwind_proc_call_frame(interp, sp);
                interp->pc = interp->call_stack[sp].return_pc;
                return;
            }
            interp->pc++;
            return;
        }
        if (match_keyword(&p, "TYPE")) {
            interp->pc++;
            return;
        }

        // Standalone END (fin normale du programme)
        skip_whitespace(&p);
        if (!*p || *p == '\'') {
            interp->running = false;
            interp->exit_requested = true;
            return;
        }
        interp->pc++;
        return;
    }

    // SELECT CASE expr
    if (match_keyword(&p, "SELECT") && match_keyword(&p, "CASE")) {
        QB_Value test_val = qb_eval_expression(interp->env, &p);
        if (interp->select_sp < 32) {
            interp->select_stack[interp->select_sp].test_val = test_val;
            interp->select_stack[interp->select_sp].case_matched = false;
            interp->select_stack[interp->select_sp].end_select_pc = find_matching_end_select(interp->program, interp->pc + 1);
            interp->select_sp++;
        }
        interp->pc = find_next_case_branch(interp->program, interp->pc + 1);
        return;
    }

    // CASE [ELSE | expr]
    if (match_keyword(&p, "CASE")) {
        if (interp->select_sp > 0) {
            int top = interp->select_sp - 1;
            if (match_keyword(&p, "ELSE")) {
                if (interp->select_stack[top].case_matched) {
                    interp->pc = interp->select_stack[top].end_select_pc;
                    return;
                } else {
                    interp->select_stack[top].case_matched = true;
                    skip_whitespace(&p);
                    if (*p == ':') {
                        p++;
                        skip_whitespace(&p);
                        if (*p && *p != '\'') {
                            qb_interp_exec_immediate(interp, p);
                            interp->pc = interp->select_stack[top].end_select_pc;
                            return;
                        }
                    }
                    interp->pc++;
                    return;
                }
            }

            if (interp->select_stack[top].case_matched) {
                interp->pc = interp->select_stack[top].end_select_pc;
                return;
            }

            bool matched = false;
            QB_Value target = interp->select_stack[top].test_val;

            while (*p && !matched) {
                skip_whitespace(&p);
                if (match_keyword(&p, "IS")) {
                    skip_whitespace(&p);
                    char op[4] = {0};
                    int opi = 0;
                    while (*p && (*p == '<' || *p == '>' || *p == '=' || *p == '!') && opi < 3) {
                        op[opi++] = *p++;
                    }
                    op[opi] = '\0';
                    QB_Value cv = qb_eval_expression(interp->env, &p);
                    if (target.type == QB_VAL_STRING || cv.type == QB_VAL_STRING) {
                        int cmp = qb_string_compare(&target, &cv);
                        if (strcmp(op, "<>") == 0) matched = (cmp != 0);
                        else if (strcmp(op, "<=") == 0) matched = (cmp <= 0);
                        else if (strcmp(op, ">=") == 0) matched = (cmp >= 0);
                        else if (strcmp(op, "<") == 0) matched = (cmp < 0);
                        else if (strcmp(op, ">") == 0) matched = (cmp > 0);
                        else if (strcmp(op, "=") == 0) matched = (cmp == 0);
                    } else {
                        if (strcmp(op, "<>") == 0) matched = (target.number != cv.number);
                        else if (strcmp(op, "<=") == 0) matched = (target.number <= cv.number);
                        else if (strcmp(op, ">=") == 0) matched = (target.number >= cv.number);
                        else if (strcmp(op, "<") == 0) matched = (target.number < cv.number);
                        else if (strcmp(op, ">") == 0) matched = (target.number > cv.number);
                        else if (strcmp(op, "=") == 0) matched = (target.number == cv.number);
                    }
                    qb_val_free(&cv);
                } else {
                    QB_Value val1 = qb_eval_expression(interp->env, &p);
                    skip_whitespace(&p);
                    if (match_keyword(&p, "TO")) {
                        QB_Value val2 = qb_eval_expression(interp->env, &p);
                        if (target.type == QB_VAL_STRING || val1.type == QB_VAL_STRING || val2.type == QB_VAL_STRING) {
                            matched = (target.string_len > 0 && qb_string_compare(&target, &val1) >= 0 && qb_string_compare(&target, &val2) <= 0);
                        } else {
                            matched = (target.number >= val1.number && target.number <= val2.number);
                        }
                        qb_val_free(&val2);
                    } else {
                        if (target.type == QB_VAL_STRING || val1.type == QB_VAL_STRING) {
                            matched = (qb_string_compare(&target, &val1) == 0);
                        } else {
                            matched = (target.number == val1.number);
                        }
                    }
                    qb_val_free(&val1);
                }

                skip_whitespace(&p);
                if (*p == ',') p++;
                else break;
            }

            if (matched) {
                interp->select_stack[top].case_matched = true;
                skip_whitespace(&p);
                if (*p == ':') {
                    p++;
                    skip_whitespace(&p);
                    if (*p && *p != '\'') {
                        qb_interp_exec_immediate(interp, p);
                        interp->pc = interp->select_stack[top].end_select_pc;
                        return;
                    }
                }
                interp->pc++;
                return;
            } else {
                interp->pc = find_next_case_branch(interp->program, interp->pc + 1);
                return;
            }
        }
    }

    // RESUME [NEXT | label]
    if (match_keyword(&p, "RESUME")) {
        skip_whitespace(&p);
        if (match_keyword(&p, "NEXT")) {
            interp->pc = interp->err_pc + 1;
            interp->in_error_handler = false;
            interp->err_code = 0;
            return;
        }
        char target[64] = {0};
        int ti = 0;
        while (*p && !isspace((unsigned char)*p) && *p != ':' && *p != '\'' && ti < 63) {
            target[ti++] = *p++;
        }
        target[ti] = '\0';
        if (target[0]) {
            int target_pc = find_label_or_linenum(interp->program, target);
            if (target_pc >= 0) {
                interp->pc = target_pc;
                interp->in_error_handler = false;
                interp->err_code = 0;
                return;
            } else {
                fprintf(stderr, "Erreur QBasic: Label RESUME introuvable '%s'\n", target);
                interp->running = false;
                return;
            }
        } else {
            interp->pc = interp->err_pc;
            interp->in_error_handler = false;
            interp->err_code = 0;
            return;
        }
    }

    // ON ERROR / ON KEY / ON TIMER / ON PLAY ou ON expr GOTO | GOSUB label1, label2, ...
    if (qb_parse_on_statement(interp, &p)) {
        interp->pc++;
        return;
    }

    if (match_keyword(&p, "ON")) {

        QB_Value idx_val = qb_eval_expression(interp->env, &p);
        int idx = (int)idx_val.number;
        qb_val_free(&idx_val);
        skip_whitespace(&p);

        bool is_gosub = false;
        if (match_keyword(&p, "GOTO")) is_gosub = false;
        else if (match_keyword(&p, "GOSUB")) is_gosub = true;
        else { interp->pc++; return; }

        int cur_idx = 1;
        char target_label[64] = {0};
        while (*p) {
            skip_whitespace(&p);
            char label[64] = {0};
            int li = 0;
            while (*p && !isspace((unsigned char)*p) && *p != ',' && li < 63) {
                label[li++] = *p++;
            }
            label[li] = '\0';
            if (cur_idx == idx) {
                snprintf(target_label, sizeof(target_label), "%s", label);
                break;
            }
            skip_whitespace(&p);
            if (*p == ',') { p++; cur_idx++; }
            else break;
        }

        if (target_label[0]) {
            int target_pc = find_label_or_linenum(interp->program, target_label);
            if (target_pc >= 0) {
                if (is_gosub && interp->gosub_sp < 127) {
                    interp->gosub_stack[interp->gosub_sp++] = interp->pc + 1;
                }
                interp->pc = target_pc;
                return;
            }
        }
        interp->pc++;
        return;
    }

    // DECLARE (ignorer en exécution)
    if (match_keyword(&p, "DECLARE")) {
        interp->pc++;
        return;
    }

    // SUB definition (sauter par-dessus lors du déroulement séquentiel)
    if (match_keyword(&p, "SUB")) {
        interp->pc = find_matching_end_proc(interp->program, interp->pc + 1, "SUB") + 1;
        return;
    }

    // FUNCTION definition (sauter par-dessus lors du déroulement séquentiel)
    if (match_keyword(&p, "FUNCTION")) {
        interp->pc = find_matching_end_proc(interp->program, interp->pc + 1, "FUNCTION") + 1;
        return;
    }

    // EXIT SUB / EXIT FUNCTION / EXIT DO / EXIT FOR
    if (match_keyword(&p, "EXIT")) {
        if (match_keyword(&p, "SUB") || match_keyword(&p, "FUNCTION")) {
            if (interp->call_sp > 0) {
                int sp = --interp->call_sp;
                unwind_proc_call_frame(interp, sp);
                interp->pc = interp->call_stack[sp].return_pc;
                return;
            }
            interp->pc++;
            return;
        } else if (match_keyword(&p, "DO")) {
            do_exit_do(interp);
            return;
        } else if (match_keyword(&p, "FOR")) {
            do_exit_for(interp);
            return;
        }
    }

    // CALL SubName(...) ou CALL SubName args
    if (match_keyword(&p, "CALL")) {
        skip_whitespace(&p);
        char sub_name[64] = {0};
        int sni = 0;
        while ((isalnum((unsigned char)*p) || *p == '_' || *p == '$' || *p == '%' || *p == '&' || *p == '#' || *p == '!') && sni < 63) {
            sub_name[sni++] = *p++;
        }
        sub_name[sni] = '\0';

        int proc_idx = -1;
        for (int i = 0; i < interp->proc_count; i++) {
            if (strcasecmp(interp->procs[i].name, sub_name) == 0) {
                proc_idx = i;
                break;
            }
        }

        if (proc_idx >= 0) {
            skip_whitespace(&p);
            bool has_paren = (*p == '(');
            if (has_paren) p++;

            QB_Value args[16];
            char arg_refs[16][64];
            int arg_count = 0;
            parse_proc_args(interp->env, &p, args, arg_refs, &arg_count, 16);
            if (has_paren && *p == ')') p++;

            int old_call_pc = interp->pc;
            execute_sub(interp, proc_idx, args, arg_count, arg_refs);
            for (int i = 0; i < arg_count; i++) qb_val_free(&args[i]);
            if (interp->pc == old_call_pc) {
                interp->pc++;
            }
            return;
        }
    }

    // Appel implicite d'une SUB (sans mot-clé CALL)
    for (int pi = 0; pi < interp->proc_count; pi++) {
        if (!interp->procs[pi].is_function) {
            const char *save_p = p;
            if (match_keyword(&p, interp->procs[pi].name)) {
                const char *chk_colon = p;
                skip_whitespace(&chk_colon);
                if (*chk_colon == ':') {
                    const char *after_colon = chk_colon + 1;
                    skip_whitespace(&after_colon);
                    if (*after_colon == '\0' || *after_colon == '\'') {
                        p = save_p;
                        continue;
                    }
                }
                QB_Value args[16];
                char arg_refs[16][64];
                int arg_count = 0;
                parse_proc_args(interp->env, &p, args, arg_refs, &arg_count, 16);
                int old_call_pc = interp->pc;
                execute_sub(interp, pi, args, arg_count, arg_refs);
                for (int i = 0; i < arg_count; i++) qb_val_free(&args[i]);
                if (interp->pc == old_call_pc) {
                    interp->pc++;
                }
                return;
            }
            p = save_p;
        }
    }

    // DO [WHILE | UNTIL cond]
    if (match_keyword(&p, "DO")) {
        bool continue_loop = true;
        if (match_keyword(&p, "WHILE")) {
            QB_Value c = qb_eval_expression(interp->env, &p);
            continue_loop = (c.number != 0.0);
            qb_val_free(&c);
        } else if (match_keyword(&p, "UNTIL")) {
            QB_Value c = qb_eval_expression(interp->env, &p);
            continue_loop = (c.number == 0.0);
            qb_val_free(&c);
        }

        bool already_on_stack = (interp->do_sp > 0 && interp->do_stack[interp->do_sp - 1].do_pc == interp->pc);

        if (continue_loop) {
            if (!already_on_stack) {
                if (interp->do_sp < 63) {
                    interp->do_stack[interp->do_sp++].do_pc = interp->pc;
                }
            }
            interp->pc++;
            return;
        } else {
            if (already_on_stack) {
                interp->do_sp--;
            }
            // Sauter jusqu'au LOOP correspondant
            int depth = 1;
            int cur = interp->pc + 1;
            while (cur < interp->program->line_count) {
                const char *lp = interp->program->lines[cur];
                skip_whitespace(&lp);
                if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
                if (match_keyword(&lp, "DO")) depth++;
                else if (match_keyword(&lp, "LOOP")) {
                    depth--;
                    if (depth == 0) {
                        interp->pc = cur + 1;
                        return;
                    }
                }
                cur++;
            }
            interp->running = false;
            return;
        }
    }

    // LOOP [WHILE | UNTIL cond]
    if (match_keyword(&p, "LOOP")) {
        if (interp->do_sp > 0) {
            int top = interp->do_sp - 1;
            bool repeat = true;
            bool has_condition = false;
            if (match_keyword(&p, "WHILE")) {
                has_condition = true;
                QB_Value c = qb_eval_expression(interp->env, &p);
                repeat = (c.number != 0.0);
                qb_val_free(&c);
            } else if (match_keyword(&p, "UNTIL")) {
                has_condition = true;
                QB_Value c = qb_eval_expression(interp->env, &p);
                repeat = (c.number == 0.0);
                qb_val_free(&c);
            }

            if (repeat) {
                if (has_condition) {
                    interp->pc = interp->do_stack[top].do_pc + 1;
                } else {
                    interp->pc = interp->do_stack[top].do_pc;
                }
                return;
            } else {
                interp->do_sp--;
            }
        }
        interp->pc++;
        return;
    }


    // GOTO target
    if (match_keyword(&p, "GOTO")) {
        skip_whitespace(&p);
        char target[64];
        sscanf(p, "%63s", target);
        int target_pc = find_label_or_linenum(interp->program, target);
        if (target_pc >= 0) {
            interp->pc = target_pc;
            return;
        } else {
            fprintf(stderr, "Erreur QBasic: Ligne ou label introuvable '%s'\n", target);
            interp->running = false;
            return;
        }
    }

    // GOSUB target
    if (match_keyword(&p, "GOSUB")) {
        skip_whitespace(&p);
        char target[64];
        sscanf(p, "%63s", target);
        int target_pc = find_label_or_linenum(interp->program, target);
        if (target_pc >= 0 && interp->gosub_sp < 127) {
            interp->gosub_stack[interp->gosub_sp++] = interp->pc + 1;
            interp->pc = target_pc;
            return;
        }
    }

    // RETURN
    if (match_keyword(&p, "RETURN")) {
        if (interp->gosub_sp > 0) {
            interp->pc = interp->gosub_stack[--interp->gosub_sp];
            interp->in_event_handler = false;
            return;
        }
    }

    // FOR var = start TO end [STEP s]
    if (match_keyword(&p, "FOR")) {
        // Detecter si c'est un FOR ... : NEXT sur la meme ligne (boucle de delai vide)
        const char *chk_next = find_caseless(p, ": NEXT");
        if (!chk_next) chk_next = find_caseless(p, ":NEXT");
        if (chk_next) {
            skip_whitespace(&p);
            char vname[64];
            int vi = 0;
            while ((isalnum((unsigned char)*p) || *p == '_') && vi < 62) {
                vname[vi++] = *p++;
            }
            if (*p == '%' || *p == '&' || *p == '!' || *p == '#' || *p == '$') {
                if (vi < 62) vname[vi++] = *p++;
            }
            vname[vi] = '\0';
            skip_whitespace(&p);
            if (*p == '=') {
                p++;
                QB_Value sval = qb_eval_expression(interp->env, &p);
                qb_val_free(&sval);
                if (match_keyword(&p, "TO")) {
                    QB_Value eval = qb_eval_expression(interp->env, &p);
                    char res_buf[128];
                    const char *resolved_vname = qb_resolve_var_name(interp->env, vname, res_buf, sizeof(res_buf));
                    qb_env_set(interp->env, resolved_vname, eval);
                    qb_val_free(&eval);
                }
            }
            qb_sleep(0.08);
            interp->pc++;
            return;
        }

        skip_whitespace(&p);
        char var_name[64];
        int idx = 0;
        while ((isalnum((unsigned char)*p) || *p == '_') && idx < 62) {
            var_name[idx++] = *p++;
        }
        if (*p == '%' || *p == '&' || *p == '!' || *p == '#' || *p == '$') {
            if (idx < 62) var_name[idx++] = *p++;
        }
        var_name[idx] = '\0';

        skip_whitespace(&p);
        if (*p == '=') {
            p++;
            QB_Value start_val = qb_eval_expression(interp->env, &p);
            char res_buf[128];
            const char *resolved_var = qb_resolve_var_name(interp->env, var_name, res_buf, sizeof(res_buf));
            qb_env_set(interp->env, resolved_var, start_val);
            qb_val_free(&start_val);

            if (match_keyword(&p, "TO")) {
                QB_Value end_val = qb_eval_expression(interp->env, &p);
                double step_val = 1.0;
                if (match_keyword(&p, "STEP")) {
                    QB_Value s = qb_eval_expression(interp->env, &p);
                    step_val = s.number;
                    qb_val_free(&s);
                }

                if (interp->for_sp < 63) {
                    snprintf(interp->for_stack[interp->for_sp].var_name, sizeof(interp->for_stack[interp->for_sp].var_name), "%s", resolved_var);
                    interp->for_stack[interp->for_sp].end_val = end_val.number;
                    interp->for_stack[interp->for_sp].step_val = step_val;
                    interp->for_stack[interp->for_sp].loop_pc = interp->pc + 1;
                    interp->for_sp++;
                }
                qb_val_free(&end_val);
                interp->pc++;
                return;
            }
        }
    }

    // NEXT [var1 [, var2 ...]]
    if (match_keyword(&p, "NEXT")) {
        while (interp->for_sp > 0) {
            skip_whitespace(&p);
            char target_var[64] = {0};
            int ti = 0;
            while ((isalnum((unsigned char)*p) || *p == '_') && ti < 62) {
                target_var[ti++] = *p++;
            }
            if (*p == '%' || *p == '&' || *p == '!' || *p == '#' || *p == '$') {
                if (ti < 62) target_var[ti++] = *p++;
            }
            target_var[ti] = '\0';

            int top = interp->for_sp - 1;
            if (target_var[0]) {
                top = -1;
                char res_t[128];
                const char *resolved_target = qb_resolve_var_name(interp->env, target_var, res_t, sizeof(res_t));
                for (int i = interp->for_sp - 1; i >= 0; i--) {
                    if (strcasecmp(interp->for_stack[i].var_name, target_var) == 0 ||
                        strcasecmp(interp->for_stack[i].var_name, resolved_target) == 0) {
                        top = i;
                        break;
                    }
                }
                if (top < 0) {
                    top = interp->for_sp - 1;
                }
            }

            QB_Value cur = qb_env_get(interp->env, interp->for_stack[top].var_name);
            double new_val = cur.number + interp->for_stack[top].step_val;
            qb_val_free(&cur);
            qb_env_set(interp->env, interp->for_stack[top].var_name, qb_val_number(new_val));

            bool loop_again = false;
            if (interp->for_stack[top].step_val >= 0) {
                loop_again = (new_val <= interp->for_stack[top].end_val);
            } else {
                loop_again = (new_val >= interp->for_stack[top].end_val);
            }

            if (loop_again) {
                interp->pc = interp->for_stack[top].loop_pc;
                return;
            } else {
                interp->for_sp = top; // depiler cette boucle (top)
                skip_whitespace(&p);
                if (*p == ',') {
                    p++;
                    continue;
                }
                break;
            }
        }
        interp->pc++;
        return;
    }

    // Détection des boucles de vidage de clavier (WHILE INKEY$ <> "": WEND ou multi-lignes)
    const char *chk_while_inkey = p;
    if (match_keyword(&chk_while_inkey, "WHILE")) {
        if (find_caseless(p, "INKEY$") != NULL) {
            // Cas 1: Sur la même ligne: WHILE INKEY$ <> "": WEND
            const char *colon = strchr(chk_while_inkey, ':');
            if (colon) {
                const char *wend_p = colon + 1;
                skip_whitespace(&wend_p);
                if (match_keyword(&wend_p, "WEND")) {
                    qb_clear_keyboard();
                    interp->pc++;
                    return;
                }
            }
            // Cas 2: Multi-lignes sans corps (WHILE INKEY$ <> "" \n WEND)
            int next_pc = interp->pc + 1;
            while (next_pc < interp->program->line_count) {
                const char *nlp = interp->program->lines[next_pc];
                skip_whitespace(&nlp);
                if (isdigit((unsigned char)*nlp)) { while (isdigit((unsigned char)*nlp)) nlp++; skip_whitespace(&nlp); }
                if (!*nlp || *nlp == '\'' || match_keyword(&nlp, "REM")) {
                    next_pc++;
                    continue;
                }
                if (match_keyword(&nlp, "WEND")) {
                    qb_clear_keyboard();
                    interp->pc = next_pc + 1;
                    return;
                }
                break;
            }
        }
    }

    // WHILE condition
    if (match_keyword(&p, "WHILE")) {
        QB_Value cond = qb_eval_expression(interp->env, &p);
        if (cond.number != 0.0) {
            if (interp->while_sp < 63) {
                interp->while_stack[interp->while_sp++] = interp->pc;
            }
            qb_val_free(&cond);
            interp->pc++;
            return;
        } else {
            qb_val_free(&cond);
            int depth = 1;
            for (int i = interp->pc + 1; i < interp->program->line_count; i++) {
                const char *lp = interp->program->lines[i];
                skip_whitespace(&lp);
                if (isdigit((unsigned char)*lp)) { while (isdigit((unsigned char)*lp)) lp++; skip_whitespace(&lp); }
                if (match_keyword(&lp, "WHILE")) depth++;
                else if (match_keyword(&lp, "WEND")) {
                    depth--;
                    if (depth == 0) {
                        interp->pc = i + 1;
                        return;
                    }
                }
            }
            interp->running = false;
            return;
        }
    }

    // WEND
    if (match_keyword(&p, "WEND")) {
        if (interp->while_sp > 0) {
            interp->pc = interp->while_stack[--interp->while_sp];
            return;
        }
        interp->pc++;
        return;
    }

    // Instruction immédiate (LET, PRINT, INPUT, DIM, SWAP, CLS...)
    int old_pc = interp->pc;
    qb_interp_exec_immediate(interp, line);
    if (interp->pc == old_pc) {
        interp->pc++;
    }
}

void qb_interp_run(QB_Interpreter *interp) {
    while (interp->running && interp->pc < interp->program->line_count) {
        qb_interp_step(interp);
    }
}
