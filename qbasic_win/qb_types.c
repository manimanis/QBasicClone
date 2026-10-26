#include "qb_types.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

static void str_toupper(char *dst, const char *src, size_t max_len) {
    if (!dst || max_len == 0) return;
    size_t i = 0;
    while (*src && i < max_len - 1) {
        dst[i++] = (char)toupper((unsigned char)*src++);
    }
    dst[i] = '\0';
}

QB_Value qb_val_number(double n) {
    QB_Value v;
    v.type = QB_VAL_NUMBER;
    v.number = n;
    v.string = NULL;
    v.string_len = 0;
    return v;
}

QB_Value qb_val_string(const char *s) {
    QB_Value v;
    v.type = QB_VAL_STRING;
    v.number = 0.0;
    if (!s) {
        v.string = strdup("");
        v.string_len = 0;
    } else {
        v.string = strdup(s);
        v.string_len = (int)strlen(s);
    }
    return v;
}

QB_Value qb_val_string_len(const char *s, int len) {
    QB_Value v;
    v.type = QB_VAL_STRING;
    v.number = 0.0;
    if (len < 0) len = 0;
    v.string_len = len;
    v.string = (char*)malloc(len + 1);
    if (s && len > 0) memcpy(v.string, s, len);
    v.string[len] = '\0';
    return v;
}

QB_Value qb_val_null(void) {
    QB_Value v;
    v.type = QB_VAL_NULL;
    v.number = 0.0;
    v.string = NULL;
    v.string_len = 0;
    return v;
}

void qb_val_free(QB_Value *val) {
    if (val && val->type == QB_VAL_STRING && val->string) {
        free(val->string);
        val->string = NULL;
    }
    if (val) {
        val->type = QB_VAL_NULL;
        val->string_len = 0;
    }
}

void qb_val_copy(QB_Value *dst, const QB_Value *src) {
    if (!dst || !src) return;
    qb_val_free(dst);
    dst->type = src->type;
    dst->number = src->number;
    if (src->type == QB_VAL_STRING && src->string) {
        dst->string_len = src->string_len;
        dst->string = (char*)malloc(src->string_len + 1);
        memcpy(dst->string, src->string, src->string_len + 1);
    } else {
        dst->string = NULL;
        dst->string_len = 0;
    }
}

void qb_val_print(const QB_Value *val, bool newline) {
    if (!val) return;
    if (val->type == QB_VAL_NUMBER) {
        if (val->number == (long long)val->number) {
            printf("%lld", (long long)val->number);
        } else {
            printf("%g", val->number);
        }
    } else if (val->type == QB_VAL_STRING) {
        printf("%s", val->string ? val->string : "");
    }
    if (newline) putchar('\n');
}

QB_Env* qb_env_create(void) {
    QB_Env *env = (QB_Env*)calloc(1, sizeof(QB_Env));
    return env;
}

void qb_env_free(QB_Env *env) {
    if (!env) return;

    // Libérer les variables scalaires
    QB_Variable *cur = env->head;
    while (cur) {
        QB_Variable *next = cur->next;
        qb_val_free(&cur->value);
        free(cur);
        cur = next;
    }

    // Libérer les tableaux
    QB_Array *arr = env->arrays;
    while (arr) {
        QB_Array *next_arr = arr->next;
        if (arr->data && !arr->is_alias) {
            for (int i = 0; i < arr->size; i++) {
                qb_val_free(&arr->data[i]);
            }
            free(arr->data);
        }
        free(arr);
        arr = next_arr;
    }

    free(env);
}

bool qb_is_string_var(const char *name) {
    if (!name || !*name) return false;
    size_t len = strlen(name);
    return (name[len - 1] == '$');
}

void qb_env_set(QB_Env *env, const char *name, QB_Value val) {
    if (!env || !name) return;
    char upper_name[64];
    str_toupper(upper_name, name, sizeof(upper_name));

    QB_Variable *cur = env->head;
    while (cur) {
        if (strcmp(cur->name, upper_name) == 0) {
            qb_val_copy(&cur->value, &val);
            return;
        }
        cur = cur->next;
    }

    // Nouvelle variable
    QB_Variable *var = (QB_Variable*)calloc(1, sizeof(QB_Variable));
    snprintf(var->name, sizeof(var->name), "%s", upper_name);
    qb_val_copy(&var->value, &val);
    var->next = env->head;
    env->head = var;
}

QB_Value qb_env_get(QB_Env *env, const char *name) {
    if (!env || !name) return qb_val_number(0);
    char upper_name[64];
    str_toupper(upper_name, name, sizeof(upper_name));

    QB_Variable *cur = env->head;
    while (cur) {
        if (strcmp(cur->name, upper_name) == 0) {
            QB_Value copy = qb_val_null();
            qb_val_copy(&copy, &cur->value);
            return copy;
        }
        cur = cur->next;
    }

    if (qb_is_string_var(upper_name)) {
        return qb_val_string("");
    }
    return qb_val_number(0);
}

// GESTION DES TABLEAUX (DIM)
#define find_array qb_array_find

QB_Array* qb_array_find(QB_Env *env, const char *name) {
    if (!env || !name) return NULL;
    char upper[64];
    str_toupper(upper, name, sizeof(upper));
    QB_Array *cur = env->arrays;
    while (cur) {
        if (strcmp(cur->name, upper) == 0) return cur;
        cur = cur->next;
    }
    return NULL;
}

bool qb_array_exists(QB_Env *env, const char *name) {
    return qb_array_find(env, name) != NULL;
}

bool qb_array_dim(QB_Env *env, const char *name, int dims, const int *lbounds, const int *ubounds) {
    if (!env || !name || dims < 1 || dims > QB_MAX_DIMS) return false;
    for (int d = 0; d < dims; d++) {
        if (ubounds[d] < lbounds[d]) return false;
    }
    char upper[64];
    str_toupper(upper, name, sizeof(upper));

    QB_Array *arr = find_array(env, name);
    if (!arr) {
        arr = (QB_Array*)calloc(1, sizeof(QB_Array));
        snprintf(arr->name, sizeof(arr->name), "%s", upper);
        arr->next = env->arrays;
        env->arrays = arr;
    } else if (arr->data && !arr->is_alias) {
        for (int i = 0; i < arr->size; i++) qb_val_free(&arr->data[i]);
        free(arr->data);
        arr->data = NULL;
    }

    arr->dims = dims;
    int total_size = 1;
    for (int d = 0; d < dims; d++) {
        arr->lbound[d] = lbounds[d];
        arr->ubound[d] = ubounds[d];
        total_size *= (ubounds[d] - lbounds[d] + 1);
    }
    arr->size = total_size;
    arr->elem_type = qb_is_string_var(upper) ? QB_VAL_STRING : QB_VAL_NUMBER;
    arr->data = (QB_Value*)calloc(arr->size, sizeof(QB_Value));

    for (int i = 0; i < arr->size; i++) {
        arr->data[i] = (arr->elem_type == QB_VAL_STRING) ? qb_val_string("") : qb_val_number(0);
    }
    return true;
}

bool qb_array_dim_1d(QB_Env *env, const char *name, int lbound, int ubound) {
    int lbs[1] = { lbound };
    int ubs[1] = { ubound };
    return qb_array_dim(env, name, 1, lbs, ubs);
}

bool qb_array_dim_2d(QB_Env *env, const char *name, int lbound1, int ubound1, int lbound2, int ubound2) {
    int lbs[2] = { lbound1, lbound2 };
    int ubs[2] = { ubound1, ubound2 };
    return qb_array_dim(env, name, 2, lbs, ubs);
}

static int calc_array_offset(const QB_Array *arr, int dims, const int *indices) {
    if (!arr || arr->dims != dims) return -1;
    int offset = 0;
    for (int d = 0; d < dims; d++) {
        if (indices[d] < arr->lbound[d] || indices[d] > arr->ubound[d]) return -1;
        int span = arr->ubound[d] - arr->lbound[d] + 1;
        int o = indices[d] - arr->lbound[d];
        offset = offset * span + o;
    }
    if (offset < 0 || offset >= arr->size) return -1;
    return offset;
}

bool qb_array_set(QB_Env *env, const char *name, int dims, const int *indices, QB_Value val) {
    QB_Array *arr = find_array(env, name);
    if (!arr) {
        int lbs[QB_MAX_DIMS] = {0};
        int ubs[QB_MAX_DIMS] = {0};
        for (int d = 0; d < dims && d < QB_MAX_DIMS; d++) ubs[d] = 10;
        qb_array_dim(env, name, dims, lbs, ubs);
        arr = find_array(env, name);
    }
    if (!arr) return false;
    int offset = calc_array_offset(arr, dims, indices);
    if (offset < 0) return false;
    qb_val_copy(&arr->data[offset], &val);
    return true;
}

QB_Value qb_array_get(QB_Env *env, const char *name, int dims, const int *indices) {
    QB_Array *arr = find_array(env, name);
    if (!arr) {
        int lbs[QB_MAX_DIMS] = {0};
        int ubs[QB_MAX_DIMS] = {0};
        for (int d = 0; d < dims && d < QB_MAX_DIMS; d++) ubs[d] = 10;
        qb_array_dim(env, name, dims, lbs, ubs);
        arr = find_array(env, name);
    }
    if (!arr) return qb_val_number(0);
    int offset = calc_array_offset(arr, dims, indices);
    if (offset < 0) {
        return (arr->elem_type == QB_VAL_STRING) ? qb_val_string("") : qb_val_number(0);
    }
    QB_Value copy = qb_val_null();
    qb_val_copy(&copy, &arr->data[offset]);
    return copy;
}

bool qb_array_set_1d(QB_Env *env, const char *name, int idx, QB_Value val) {
    int indices[1] = { idx };
    return qb_array_set(env, name, 1, indices, val);
}

QB_Value qb_array_get_1d(QB_Env *env, const char *name, int idx) {
    int indices[1] = { idx };
    return qb_array_get(env, name, 1, indices);
}

bool qb_array_set_2d(QB_Env *env, const char *name, int idx1, int idx2, QB_Value val) {
    int indices[2] = { idx1, idx2 };
    return qb_array_set(env, name, 2, indices, val);
}

QB_Value qb_array_get_2d(QB_Env *env, const char *name, int idx1, int idx2) {
    int indices[2] = { idx1, idx2 };
    return qb_array_get(env, name, 2, indices);
}

int qb_array_lbound(QB_Env *env, const char *name, int dim) {
    QB_Array *arr = find_array(env, name);
    if (!arr) return 0;
    int d = (dim > 0 && dim <= arr->dims) ? dim - 1 : 0;
    return arr->lbound[d];
}

int qb_array_ubound(QB_Env *env, const char *name, int dim) {
    QB_Array *arr = find_array(env, name);
    if (!arr) return 0;
    int d = (dim > 0 && dim <= arr->dims) ? dim - 1 : 0;
    return arr->ubound[d];
}

QB_Array* qb_array_create_alias(QB_Env *env, const char *alias_name, QB_Array *src) {
    if (!env || !alias_name || !src) return NULL;
    char upper[64];
    str_toupper(upper, alias_name, sizeof(upper));

    qb_array_remove_alias(env, upper);

    QB_Array *alias = (QB_Array*)calloc(1, sizeof(QB_Array));
    snprintf(alias->name, sizeof(alias->name), "%s", upper);
    alias->elem_type = src->elem_type;
    alias->dims = src->dims;
    for (int d = 0; d < src->dims && d < QB_MAX_DIMS; d++) {
        alias->lbound[d] = src->lbound[d];
        alias->ubound[d] = src->ubound[d];
    }
    alias->size = src->size;
    alias->data = src->data;
    alias->is_alias = true;
    alias->next = env->arrays;
    env->arrays = alias;
    return alias;
}

void qb_array_remove_alias(QB_Env *env, const char *alias_name) {
    if (!env || !alias_name) return;
    char upper[64];
    str_toupper(upper, alias_name, sizeof(upper));

    QB_Array **curr = &env->arrays;
    while (*curr) {
        if (strcmp((*curr)->name, upper) == 0 && (*curr)->is_alias) {
            QB_Array *to_free = *curr;
            *curr = to_free->next;
            free(to_free);
            return;
        }
        curr = &(*curr)->next;
    }
}

bool qb_array_erase(QB_Env *env, const char *name) {
    QB_Array *arr = find_array(env, name);
    if (!arr || !arr->data) return false;
    for (int i = 0; i < arr->size; i++) {
        qb_val_free(&arr->data[i]);
        arr->data[i] = (arr->elem_type == QB_VAL_STRING) ? qb_val_string("") : qb_val_number(0);
    }
    return true;
}


