#ifndef QB_TYPES_H
#define QB_TYPES_H

#include <stdbool.h>
#include <stddef.h>

typedef enum {
    QB_VAL_NULL = 0,
    QB_VAL_NUMBER,
    QB_VAL_STRING
} QB_ValType;

typedef struct {
    QB_ValType type;
    double number;
    char *string;
    int string_len;
} QB_Value;

typedef struct QB_Variable {
    char name[64];
    QB_Value value;
    struct QB_Variable *next;
} QB_Variable;

#define QB_MAX_DIMS 8

typedef struct QB_Array {
    char name[64];
    QB_ValType elem_type;
    int dims; // 1 à 8
    int lbound[QB_MAX_DIMS];
    int ubound[QB_MAX_DIMS];
    int size;
    QB_Value *data;
    bool is_alias;
    struct QB_Array *next;
} QB_Array;

typedef struct {
    QB_Variable *head;
    QB_Array *arrays;
    void *user_data;
} QB_Env;

// Fonctions sur les valeurs
QB_Value qb_val_number(double n);
QB_Value qb_val_string(const char *s);
QB_Value qb_val_string_len(const char *s, int len);
QB_Value qb_val_null(void);
void qb_val_free(QB_Value *val);
void qb_val_copy(QB_Value *dst, const QB_Value *src);
void qb_val_print(const QB_Value *val, bool newline);

// Environnement et variables
QB_Env* qb_env_create(void);
void qb_env_free(QB_Env *env);
void qb_env_set(QB_Env *env, const char *name, QB_Value val);
QB_Value qb_env_get(QB_Env *env, const char *name);
bool qb_is_string_var(const char *name);

// Tableaux (DIM & Accès N-dimensionnels)
bool qb_array_dim(QB_Env *env, const char *name, int dims, const int *lbounds, const int *ubounds);
bool qb_array_dim_1d(QB_Env *env, const char *name, int lbound, int ubound);
bool qb_array_dim_2d(QB_Env *env, const char *name, int lbound1, int ubound1, int lbound2, int ubound2);
bool qb_array_set(QB_Env *env, const char *name, int dims, const int *indices, QB_Value val);
QB_Value qb_array_get(QB_Env *env, const char *name, int dims, const int *indices);
bool qb_array_set_1d(QB_Env *env, const char *name, int idx, QB_Value val);
QB_Value qb_array_get_1d(QB_Env *env, const char *name, int idx);
bool qb_array_set_2d(QB_Env *env, const char *name, int idx1, int idx2, QB_Value val);
QB_Value qb_array_get_2d(QB_Env *env, const char *name, int idx1, int idx2);
bool qb_array_exists(QB_Env *env, const char *name);
QB_Array* qb_array_find(QB_Env *env, const char *name);
QB_Array* qb_array_create_alias(QB_Env *env, const char *alias_name, QB_Array *src);
void qb_array_remove_alias(QB_Env *env, const char *alias_name);
int qb_array_lbound(QB_Env *env, const char *name, int dim);
int qb_array_ubound(QB_Env *env, const char *name, int dim);
bool qb_array_erase(QB_Env *env, const char *name);

#endif // QB_TYPES_H

