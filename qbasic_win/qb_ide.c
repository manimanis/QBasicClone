#include "qb_ide.h"
#include "win_compat.h"
#include "qb_types.h"
#include "qb_interp.h"

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <conio.h>

#define IDE_WIDTH 80
#define IDE_HEIGHT 25

#define EDIT_TOP 2
#define EDIT_BOTTOM 19
#define EDIT_HEIGHT (EDIT_BOTTOM - EDIT_TOP + 1)
#define EDIT_LEFT 1
#define EDIT_WIDTH 78

#define IMMED_TOP 22
#define IMMED_BOTTOM 23

// Couleurs standard QBasic (attributs console Win32)
#define ATTR_MENU_BAR       (BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE)                      // Gris clair (fond 7, texte 0)
#define ATTR_MENU_HOTKEY    (BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE | FOREGROUND_RED)     // Rouge sur gris clair
#define ATTR_MENU_ACTIVE    (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | BACKGROUND_INTENSITY) // Inversé
#define ATTR_EDITOR_BG      (BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY) // Blanc éclatant sur bleu
#define ATTR_EDITOR_BORDER  (BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE)   // Gris sur bleu
#define ATTR_STATUS_BAR     (BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE)                      // Gris clair
#define ATTR_STATUS_KEY     (BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE | FOREGROUND_INTENSITY)
#define ATTR_POPUP_BG       (BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE)                      // Menu déroulant
#define ATTR_POPUP_SEL      (BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY)
#define ATTR_SHADOW         (0) // Noir transparent

// Attributs de Coloration Syntaxique (sur fond bleu classique QBasic)
#define ATTR_SYN_DEFAULT   (BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY) // Blanc éclatant (15) : variables et texte
#define ATTR_SYN_KEYWORD   (BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY)                   // Jaune éclatant (14) : mots-clés
#define ATTR_SYN_STRING    (BACKGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_INTENSITY)                                    // Vert éclatant (10) : chaînes "..."
#define ATTR_SYN_COMMENT   (BACKGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY)                   // Cyan éclatant (11) : commentaires ' et REM
#define ATTR_SYN_NUMBER    (BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_BLUE | FOREGROUND_INTENSITY)                    // Magenta clair (13) : nombres
#define ATTR_SYN_OP        (BACKGROUND_BLUE | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE)                       // Gris clair (7) : opérateurs et séparateurs

typedef struct {
    char **lines;
    int line_count;
    int capacity;
    int cursor_x;
    int cursor_y;
    int scroll_x;
    int scroll_y;
} EditorBuffer;

typedef enum {
    FOCUS_EDITOR,
    FOCUS_IMMEDIATE
} WindowFocus;

typedef struct {
    const char *title;
    int hotkey_idx;
    const char *items[10];
    int item_count;
    int x_pos;
} Menu;

static CHAR_INFO g_screen[IDE_WIDTH * IDE_HEIGHT];
static HANDLE g_hOut = INVALID_HANDLE_VALUE;
static HANDLE g_hIn = INVALID_HANDLE_VALUE;

static EditorBuffer g_edit;
static char g_immed_line[256];
static int g_immed_cursor = 0;

static WindowFocus g_focus = FOCUS_EDITOR;
static char g_filename[MAX_PATH] = "UNTITLED.BAS";
static bool g_modified = false;
static bool g_running_ide = true;

static int g_active_menu = -1; // -1 = aucun menu ouvert, 0..MenuCount-1
static int g_active_menu_item = 0;

static Menu g_menus[] = {
    { "File", 0, { "New", "Open...", "Save", "Save As...", "-", "Exit" }, 6, 2 },
    { "Edit", 0, { "Cut", "Copy", "Paste", "Clear" }, 4, 10 },
    { "Run",  0, { "Start          F5", "Restart    Shift+F5" }, 2, 18 },
    { "Help", 0, { "About QBasic..." }, 1, 26 }
};
static const int g_menu_count = sizeof(g_menus) / sizeof(g_menus[0]);

// Helper dessin dans le buffer double-buffer
static void set_cell(int x, int y, char ch, WORD attr) {
    if (x < 0 || x >= IDE_WIDTH || y < 0 || y >= IDE_HEIGHT) return;
    int idx = y * IDE_WIDTH + x;
    g_screen[idx].Char.AsciiChar = ch;
    g_screen[idx].Attributes = attr;
}

static void draw_text(int x, int y, const char *text, WORD attr) {
    if (y < 0 || y >= IDE_HEIGHT) return;
    while (*text && x < IDE_WIDTH) {
        if (x >= 0) set_cell(x, y, *text, attr);
        x++;
        text++;
    }
}

static void draw_fill_rect(int left, int top, int width, int height, char ch, WORD attr) {
    for (int y = top; y < top + height; y++) {
        for (int x = left; x < left + width; x++) {
            set_cell(x, y, ch, attr);
        }
    }
}

static void draw_box(int left, int top, int width, int height, WORD attr) {
    int right = left + width - 1;
    int bottom = top + height - 1;

    set_cell(left, top, '+', attr);
    set_cell(right, top, '+', attr);
    set_cell(left, bottom, '+', attr);
    set_cell(right, bottom, '+', attr);

    for (int x = left + 1; x < right; x++) {
        set_cell(x, top, '-', attr);
        set_cell(x, bottom, '-', attr);
    }
    for (int y = top + 1; y < bottom; y++) {
        set_cell(left, y, '|', attr);
        set_cell(right, y, '|', attr);
    }
}

// Initialisation et gestion du buffer d'édition
static void editor_init(EditorBuffer *eb) {
    eb->capacity = 128;
    eb->lines = (char**)calloc(eb->capacity, sizeof(char*));
    eb->line_count = 1;
    eb->lines[0] = strdup("");
    eb->cursor_x = 0;
    eb->cursor_y = 0;
    eb->scroll_x = 0;
    eb->scroll_y = 0;
}

static void editor_free(EditorBuffer *eb) {
    for (int i = 0; i < eb->line_count; i++) {
        free(eb->lines[i]);
    }
    free(eb->lines);
    eb->lines = NULL;
    eb->line_count = 0;
}

static void editor_load_file(EditorBuffer *eb, const char *filename) {
    FILE *f = fopen(filename, "r");
    if (!f) return;

    editor_free(eb);
    eb->capacity = 128;
    eb->lines = (char**)calloc(eb->capacity, sizeof(char*));
    eb->line_count = 0;

    char buf[2048];
    while (fgets(buf, sizeof(buf), f)) {
        char *nl = strchr(buf, '\n');
        if (nl) *nl = '\0';
        nl = strchr(buf, '\r');
        if (nl) *nl = '\0';

        if (eb->line_count >= eb->capacity) {
            eb->capacity *= 2;
            eb->lines = (char**)realloc(eb->lines, eb->capacity * sizeof(char*));
        }
        eb->lines[eb->line_count++] = strdup(buf);
    }
    fclose(f);

    if (eb->line_count == 0) {
        eb->lines[0] = strdup("");
        eb->line_count = 1;
    }
    eb->cursor_x = 0;
    eb->cursor_y = 0;
    eb->scroll_x = 0;
    eb->scroll_y = 0;
}

static bool editor_save_file(EditorBuffer *eb, const char *filename) {
    FILE *f = fopen(filename, "w");
    if (!f) return false;
    for (int i = 0; i < eb->line_count; i++) {
        fprintf(f, "%s\n", eb->lines[i]);
    }
    fclose(f);
    g_modified = false;
    return true;
}

static void editor_insert_char(EditorBuffer *eb, char ch) {
    char *line = eb->lines[eb->cursor_y];
    int len = (int)strlen(line);
    if (eb->cursor_x > len) eb->cursor_x = len;

    char *new_line = (char*)malloc(len + 2);
    strncpy(new_line, line, eb->cursor_x);
    new_line[eb->cursor_x] = ch;
    strcpy(new_line + eb->cursor_x + 1, line + eb->cursor_x);

    free(line);
    eb->lines[eb->cursor_y] = new_line;
    eb->cursor_x++;
    g_modified = true;
}

static void editor_newline(EditorBuffer *eb) {
    if (eb->line_count >= eb->capacity) {
        eb->capacity *= 2;
        eb->lines = (char**)realloc(eb->lines, eb->capacity * sizeof(char*));
    }

    char *cur_line = eb->lines[eb->cursor_y];
    int len = (int)strlen(cur_line);
    if (eb->cursor_x > len) eb->cursor_x = len;

    char *next_line = strdup(cur_line + eb->cursor_x);
    cur_line[eb->cursor_x] = '\0';

    // Décaler les lignes suivantes
    for (int i = eb->line_count; i > eb->cursor_y + 1; i--) {
        eb->lines[i] = eb->lines[i - 1];
    }
    eb->lines[eb->cursor_y + 1] = next_line;
    eb->line_count++;

    eb->cursor_y++;
    eb->cursor_x = 0;
    g_modified = true;
}

static void editor_backspace(EditorBuffer *eb) {
    if (eb->cursor_x > 0) {
        char *line = eb->lines[eb->cursor_y];
        int len = (int)strlen(line);
        memmove(line + eb->cursor_x - 1, line + eb->cursor_x, len - eb->cursor_x + 1);
        eb->cursor_x--;
        g_modified = true;
    } else if (eb->cursor_y > 0) {
        // Fusionner avec la ligne précédente
        char *prev_line = eb->lines[eb->cursor_y - 1];
        char *cur_line = eb->lines[eb->cursor_y];
        int prev_len = (int)strlen(prev_line);
        int cur_len = (int)strlen(cur_line);

        char *merged = (char*)malloc(prev_len + cur_len + 1);
        strcpy(merged, prev_line);
        strcat(merged, cur_line);

        free(prev_line);
        free(cur_line);
        eb->lines[eb->cursor_y - 1] = merged;

        for (int i = eb->cursor_y; i < eb->line_count - 1; i++) {
            eb->lines[i] = eb->lines[i + 1];
        }
        eb->line_count--;

        eb->cursor_y--;
        eb->cursor_x = prev_len;
        g_modified = true;
    }
}

static void editor_delete_char(EditorBuffer *eb) {
    char *line = eb->lines[eb->cursor_y];
    int len = (int)strlen(line);
    if (eb->cursor_x < len) {
        memmove(line + eb->cursor_x, line + eb->cursor_x + 1, len - eb->cursor_x);
        g_modified = true;
    } else if (eb->cursor_y < eb->line_count - 1) {
        // Fusionner avec la ligne suivante
        char *next_line = eb->lines[eb->cursor_y + 1];
        int next_len = (int)strlen(next_line);
        char *merged = (char*)malloc(len + next_len + 1);
        strcpy(merged, line);
        strcat(merged, next_line);

        free(line);
        free(next_line);
        eb->lines[eb->cursor_y] = merged;

        for (int i = eb->cursor_y + 1; i < eb->line_count - 1; i++) {
            eb->lines[i] = eb->lines[i + 1];
        }
        eb->line_count--;
        g_modified = true;
    }
}

// Coloration syntaxique du code QBasic
static bool is_qb_keyword(const char *word, int len) {
    static const char *kw[] = {
        "CLS", "PRINT", "INPUT", "LET", "IF", "THEN", "ELSE", "ELSEIF", "END",
        "FOR", "TO", "STEP", "NEXT", "WHILE", "WEND", "DO", "LOOP", "UNTIL",
        "GOTO", "GOSUB", "RETURN", "COLOR", "LOCATE", "BEEP", "SLEEP", "SOUND",
        "SYSTEM", "DIM", "AS", "INTEGER", "LONG", "SINGLE", "DOUBLE", "STRING",
        "SHARED", "STATIC", "SUB", "FUNCTION", "DECLARE", "CONST", "SELECT", "CASE",
        "OPEN", "CLOSE", "OUTPUT", "APPEND", "READ", "WRITE", "DATA", "RESTORE",
        "SWAP", "ERASE", "LINE", "SCREEN", "PSET", "CIRCLE", "PAINT", "ON", "CALL",
        "EXIT", "IS", "SQR", "SIN", "COS", "TAN", "ATN", "INT", "FIX", "ABS", "RND",
        "TIMER", "INKEY$", "DATE$", "TIME$", "HEX$", "OCT$", "SGN", "INSTR",
        "LEN", "MID$", "LEFT$", "RIGHT$", "UCASE$", "LCASE$", "CHR$", "ASC", "STR$", "VAL",
        "AND", "OR", "NOT", "XOR", "MOD", NULL
    };
    for (int i = 0; kw[i]; i++) {
        if ((int)strlen(kw[i]) == len && strncasecmp(kw[i], word, len) == 0) {
            return true;
        }
    }
    return false;
}

static void draw_highlighted_line(int screen_x, int screen_y, const char *line_text, int scroll_x, int width) {
    int len = (int)strlen(line_text);
    if (len == 0) return;

    WORD *attrs = (WORD*)malloc(len * sizeof(WORD));
    for (int i = 0; i < len; i++) attrs[i] = ATTR_SYN_DEFAULT;

    int i = 0;
    while (i < len) {
        char c = line_text[i];

        // 1. Commentaire (' ou REM)
        if (c == '\'' || (i + 3 <= len && strncasecmp(line_text + i, "REM", 3) == 0 && (i + 3 == len || isspace((unsigned char)line_text[i + 3])))) {
            for (int k = i; k < len; k++) attrs[k] = ATTR_SYN_COMMENT;
            break;
        }

        // 2. Chaîne littérale "..."
        if (c == '"') {
            attrs[i++] = ATTR_SYN_STRING;
            while (i < len && line_text[i] != '"') {
                attrs[i++] = ATTR_SYN_STRING;
            }
            if (i < len && line_text[i] == '"') {
                attrs[i++] = ATTR_SYN_STRING;
            }
            continue;
        }

        // 3. Nombres (ex: 42, 3.14, &HFF)
        if (isdigit((unsigned char)c) || (c == '.' && i + 1 < len && isdigit((unsigned char)line_text[i + 1])) || (c == '&' && (line_text[i+1] == 'H' || line_text[i+1] == 'h'))) {
            while (i < len && (isalnum((unsigned char)line_text[i]) || line_text[i] == '.')) {
                attrs[i++] = ATTR_SYN_NUMBER;
            }
            if (i < len && (line_text[i] == '%' || line_text[i] == '&' || line_text[i] == '!' || line_text[i] == '#')) {
                attrs[i++] = ATTR_SYN_NUMBER;
            }
            continue;
        }

        // 4. Identifiants et mots-clés
        if (isalpha((unsigned char)c) || c == '_') {
            int start = i;
            while (i < len && (isalnum((unsigned char)line_text[i]) || line_text[i] == '_' || line_text[i] == '$' || line_text[i] == '%' || line_text[i] == '&' || line_text[i] == '!' || line_text[i] == '#')) {
                i++;
                if (line_text[i - 1] == '$' || line_text[i - 1] == '%' || line_text[i - 1] == '&' || line_text[i - 1] == '!' || line_text[i - 1] == '#') break;
            }
            int word_len = i - start;
            if (is_qb_keyword(line_text + start, word_len)) {
                for (int k = start; k < i; k++) attrs[k] = ATTR_SYN_KEYWORD;
            } else {
                for (int k = start; k < i; k++) attrs[k] = ATTR_SYN_DEFAULT;
            }
            continue;
        }

        // 5. Opérateurs et séparateurs
        if (strchr("+-*/\\^=<>(),;:?#", c)) {
            attrs[i++] = ATTR_SYN_OP;
            continue;
        }

        i++;
    }

    // Affichage des caractères visibles selon scroll_x
    for (int col = 0; col < width; col++) {
        int idx = scroll_x + col;
        if (idx < len) {
            set_cell(screen_x + col, screen_y, line_text[idx], attrs[idx]);
        }
    }

    free(attrs);
}

// Rendu complet de l'interface
static void render_ide(void) {
    // 1. Barre de Menu (Ligne 0)
    draw_fill_rect(0, 0, IDE_WIDTH, 1, ' ', ATTR_MENU_BAR);
    for (int i = 0; i < g_menu_count; i++) {
        WORD attr = (g_active_menu == i) ? ATTR_MENU_ACTIVE : ATTR_MENU_BAR;
        draw_text(g_menus[i].x_pos, 0, g_menus[i].title, attr);
    }

    // 2. Fenêtre Principale de l'Éditeur
    draw_fill_rect(0, 1, IDE_WIDTH, 20, ' ', ATTR_EDITOR_BG);
    draw_box(0, 1, IDE_WIDTH, 20, ATTR_EDITOR_BORDER);

    // Titre de fichier centré dans la bordure supérieure
    char title_buf[MAX_PATH + 32];
    snprintf(title_buf, sizeof(title_buf), " %s%s ", g_filename, g_modified ? " *" : "");
    int title_x = (IDE_WIDTH - (int)strlen(title_buf)) / 2;
    draw_text(title_x, 1, title_buf, ATTR_EDITOR_BG);

    // Lignes de texte de l'éditeur avec coloration syntaxique
    for (int row = 0; row < EDIT_HEIGHT; row++) {
        int line_idx = g_edit.scroll_y + row;
        int screen_y = EDIT_TOP + row;

        if (line_idx < g_edit.line_count) {
            const char *line_text = g_edit.lines[line_idx];
            draw_highlighted_line(EDIT_LEFT, screen_y, line_text, g_edit.scroll_x, EDIT_WIDTH);
        }
    }

    // 3. Fenêtre Immédiate avec coloration syntaxique
    draw_box(0, 20, IDE_WIDTH, 4, ATTR_EDITOR_BORDER);
    draw_text(3, 20, " Immediate ", ATTR_EDITOR_BG);
    draw_fill_rect(1, 21, IDE_WIDTH - 2, 2, ' ', ATTR_EDITOR_BG);
    draw_highlighted_line(2, 21, g_immed_line, 0, IDE_WIDTH - 4);

    // 4. Barre d'état inférieure (Ligne 24)
    draw_fill_rect(0, 24, IDE_WIDTH, 1, ' ', ATTR_STATUS_BAR);
    draw_text(1, 24, "<Shift+F1=Help> <F6=Window> <F5=Run> <Esc=Menu>", ATTR_STATUS_BAR);

    char pos_buf[32];
    snprintf(pos_buf, sizeof(pos_buf), "%05d:%03d", g_edit.cursor_y + 1, g_edit.cursor_x + 1);
    draw_text(IDE_WIDTH - 11, 24, pos_buf, ATTR_STATUS_BAR);

    // 5. Menu déroulant actif éventuel
    if (g_active_menu >= 0 && g_active_menu < g_menu_count) {
        Menu *m = &g_menus[g_active_menu];
        int menu_x = m->x_pos;
        int menu_y = 1;
        int max_w = 0;
        for (int i = 0; i < m->item_count; i++) {
            int len = (int)strlen(m->items[i]);
            if (len > max_w) max_w = len;
        }
        int box_w = max_w + 4;
        int box_h = m->item_count + 2;

        draw_fill_rect(menu_x, menu_y, box_w, box_h, ' ', ATTR_POPUP_BG);
        draw_box(menu_x, menu_y, box_w, box_h, ATTR_POPUP_BG);

        for (int i = 0; i < m->item_count; i++) {
            WORD item_attr = (g_active_menu_item == i) ? ATTR_POPUP_SEL : ATTR_POPUP_BG;
            if (strcmp(m->items[i], "-") == 0) {
                for (int bx = menu_x; bx < menu_x + box_w; bx++) set_cell(bx, menu_y + 1 + i, '-', ATTR_POPUP_BG);
            } else {
                draw_fill_rect(menu_x + 1, menu_y + 1 + i, box_w - 2, 1, ' ', item_attr);
                draw_text(menu_x + 2, menu_y + 1 + i, m->items[i], item_attr);
            }
        }
    }

    // Afficher le buffer complet sur la console Windows
    COORD buf_size = { IDE_WIDTH, IDE_HEIGHT };
    COORD buf_coord = { 0, 0 };
    SMALL_RECT write_region = { 0, 0, IDE_WIDTH - 1, IDE_HEIGHT - 1 };
    WriteConsoleOutputA(g_hOut, g_screen, buf_size, buf_coord, &write_region);

    // Positionner le curseur Windows
    if (g_active_menu < 0) {
        COORD cur_pos;
        if (g_focus == FOCUS_EDITOR) {
            cur_pos.X = (SHORT)(EDIT_LEFT + (g_edit.cursor_x - g_edit.scroll_x));
            cur_pos.Y = (SHORT)(EDIT_TOP + (g_edit.cursor_y - g_edit.scroll_y));
        } else {
            cur_pos.X = (SHORT)(2 + g_immed_cursor);
            cur_pos.Y = 21;
        }
        SetConsoleCursorPosition(g_hOut, cur_pos);
    }
}

// Boîte de dialogue "About QBasic"
static void show_about_dialog(void) {
    int w = 56;
    int h = 9;
    int left = (IDE_WIDTH - w) / 2;
    int top = (IDE_HEIGHT - h) / 2;

    draw_fill_rect(left, top, w, h, ' ', ATTR_POPUP_BG);
    draw_box(left, top, w, h, ATTR_POPUP_BG);

    draw_text(left + 16, top + 1, "Microsoft (R) QBasic", ATTR_POPUP_BG);
    draw_text(left + 21, top + 2, "Version 1.1", ATTR_POPUP_BG);
    draw_text(left + 5, top + 4, "(C) Copyright Microsoft Corporation, 1987-1992.", ATTR_POPUP_BG);
    draw_text(left + 11, top + 5, "Port Natif Windows x64 (MSYS2 GCC)", ATTR_POPUP_BG);

    draw_text(left + 24, top + 7, "<  OK  >", ATTR_POPUP_SEL);

    COORD buf_size = { IDE_WIDTH, IDE_HEIGHT };
    COORD buf_coord = { 0, 0 };
    SMALL_RECT write_region = { 0, 0, IDE_WIDTH - 1, IDE_HEIGHT - 1 };
    WriteConsoleOutputA(g_hOut, g_screen, buf_size, buf_coord, &write_region);

    // Attente touche Entrée ou Échap
    while (true) {
        INPUT_RECORD ir;
        DWORD read_count;
        ReadConsoleInputA(g_hIn, &ir, 1, &read_count);
        if (ir.EventType == KEY_EVENT && ir.Event.KeyEvent.bKeyDown) {
            WORD vk = ir.Event.KeyEvent.wVirtualKeyCode;
            if (vk == VK_RETURN || vk == VK_ESCAPE || vk == VK_SPACE) {
                break;
            }
        }
    }
}

static DWORD g_orig_in_mode = 0;

// Exécution du programme (F5)
static void run_program(void) {
    // 1. Passer en écran de sortie classique (fond noir, texte gris)
    qb_cls();
    qb_color(7, 0);

    // Rétablir le mode console réactif sans blocage de ligne pour le programme exécuté
    DWORD prev_ide_in_mode = 0;
    GetConsoleMode(g_hIn, &prev_ide_in_mode);
    SetConsoleMode(g_hIn, ENABLE_EXTENDED_FLAGS | ENABLE_PROCESSED_INPUT);

    // 2. Construire le programme depuis les lignes de l'éditeur
    QB_Program *prog = qb_program_create();
    for (int i = 0; i < g_edit.line_count; i++) {
        qb_program_add_line(prog, g_edit.lines[i]);
    }

    // 3. Exécuter
    QB_Interpreter *interp = qb_interp_create(prog);
    qb_interp_run(interp);

    // 4. Attente touche de fin
    qb_color(11, 0);
    printf("\n\nAppuyez sur une touche pour revenir a QBasic...");
    fflush(stdout);

    FlushConsoleInputBuffer(g_hIn);
    while (true) {
        const char *k = qb_inkey();
        if (k && k[0] != '\0') {
            break;
        }
        Sleep(20);
    }

    qb_interp_free(interp);
    qb_program_free(prog);

    // 5. Rétablir l'IDE et son mode console
    SetConsoleMode(g_hIn, prev_ide_in_mode);
    qb_cls();
}

int qb_ide_start(const char *initial_file) {
    g_hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    g_hIn = GetStdHandle(STD_INPUT_HANDLE);

    // Configuration console
    GetConsoleMode(g_hIn, &g_orig_in_mode);
    SetConsoleMode(g_hIn, ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS);

    // Définir la taille de la console à 80x25
    SMALL_RECT rect = { 0, 0, IDE_WIDTH - 1, IDE_HEIGHT - 1 };
    COORD coord = { IDE_WIDTH, IDE_HEIGHT };
    SetConsoleScreenBufferSize(g_hOut, coord);
    SetConsoleWindowInfo(g_hOut, TRUE, &rect);

    editor_init(&g_edit);

    if (initial_file && initial_file[0]) {
        strncpy(g_filename, initial_file, sizeof(g_filename) - 1);
        editor_load_file(&g_edit, initial_file);
    } else {
        // Code d'accueil par défaut
        editor_insert_char(&g_edit, '\'');
        const char *welcome = " Bienvenue dans Microsoft QBasic 1.1 pour Windows !";
        for (const char *c = welcome; *c; c++) editor_insert_char(&g_edit, *c);
        editor_newline(&g_edit);
        const char *code1 = "CLS";
        for (const char *c = code1; *c; c++) editor_insert_char(&g_edit, *c);
        editor_newline(&g_edit);
        const char *code2 = "PRINT \"Bonjour depuis l'IDE QBasic natif Windows !\"";
        for (const char *c = code2; *c; c++) editor_insert_char(&g_edit, *c);
        g_edit.cursor_y = 0;
        g_edit.cursor_x = 0;
        g_modified = false;
    }

    g_running_ide = true;

    while (g_running_ide) {
        // Ajuster le scroll
        if (g_edit.cursor_y < g_edit.scroll_y) g_edit.scroll_y = g_edit.cursor_y;
        if (g_edit.cursor_y >= g_edit.scroll_y + EDIT_HEIGHT) g_edit.scroll_y = g_edit.cursor_y - EDIT_HEIGHT + 1;
        if (g_edit.cursor_x < g_edit.scroll_x) g_edit.scroll_x = g_edit.cursor_x;
        if (g_edit.cursor_x >= g_edit.scroll_x + EDIT_WIDTH) g_edit.scroll_x = g_edit.cursor_x - EDIT_WIDTH + 1;

        render_ide();

        INPUT_RECORD ir;
        DWORD read_count;
        if (!ReadConsoleInputA(g_hIn, &ir, 1, &read_count)) continue;

        if (ir.EventType == KEY_EVENT && ir.Event.KeyEvent.bKeyDown) {
            WORD vk = ir.Event.KeyEvent.wVirtualKeyCode;
            char ch = ir.Event.KeyEvent.uChar.AsciiChar;
            DWORD ctrl_state = ir.Event.KeyEvent.dwControlKeyState;
            bool alt_pressed = (ctrl_state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;

            // F5 : Exécuter le code
            if (vk == VK_F5) {
                run_program();
                continue;
            }

            // F6 : Basculer entre Éditeur et Fenêtre Immédiate
            if (vk == VK_F6) {
                g_focus = (g_focus == FOCUS_EDITOR) ? FOCUS_IMMEDIATE : FOCUS_EDITOR;
                continue;
            }

            // Échap : Ouvrir / Fermer le menu
            if (vk == VK_ESCAPE) {
                if (g_active_menu >= 0) {
                    g_active_menu = -1;
                } else {
                    g_active_menu = 0;
                    g_active_menu_item = 0;
                }
                continue;
            }

            // Gestion de la navigation dans les menus
            if (g_active_menu >= 0) {
                if (vk == VK_LEFT) {
                    g_active_menu = (g_active_menu - 1 + g_menu_count) % g_menu_count;
                    g_active_menu_item = 0;
                } else if (vk == VK_RIGHT) {
                    g_active_menu = (g_active_menu + 1) % g_menu_count;
                    g_active_menu_item = 0;
                } else if (vk == VK_UP) {
                    g_active_menu_item = (g_active_menu_item - 1 + g_menus[g_active_menu].item_count) % g_menus[g_active_menu].item_count;
                    if (strcmp(g_menus[g_active_menu].items[g_active_menu_item], "-") == 0) {
                        g_active_menu_item = (g_active_menu_item - 1 + g_menus[g_active_menu].item_count) % g_menus[g_active_menu].item_count;
                    }
                } else if (vk == VK_DOWN) {
                    g_active_menu_item = (g_active_menu_item + 1) % g_menus[g_active_menu].item_count;
                    if (strcmp(g_menus[g_active_menu].items[g_active_menu_item], "-") == 0) {
                        g_active_menu_item = (g_active_menu_item + 1) % g_menus[g_active_menu].item_count;
                    }
                } else if (vk == VK_RETURN) {
                    // Action de menu sélectionnée
                    int m_idx = g_active_menu;
                    int i_idx = g_active_menu_item;
                    g_active_menu = -1;

                    if (m_idx == 0) { // File
                        if (i_idx == 0) { // New
                            editor_free(&g_edit);
                            editor_init(&g_edit);
                            strcpy(g_filename, "UNTITLED.BAS");
                            g_modified = false;
                        } else if (i_idx == 2) { // Save
                            editor_save_file(&g_edit, g_filename);
                        } else if (i_idx == 5) { // Exit
                            g_running_ide = false;
                        }
                    } else if (m_idx == 2) { // Run
                        if (i_idx == 0 || i_idx == 1) { // Start
                            run_program();
                        }
                    } else if (m_idx == 3) { // Help
                        if (i_idx == 0) {
                            show_about_dialog();
                        }
                    }
                }
                continue;
            }

            // Raccourcis Alt+lettre (Alt+F, Alt+R, Alt+H)
            if (alt_pressed) {
                if (vk == 'F') { g_active_menu = 0; g_active_menu_item = 0; continue; }
                if (vk == 'E') { g_active_menu = 1; g_active_menu_item = 0; continue; }
                if (vk == 'R') { g_active_menu = 2; g_active_menu_item = 0; continue; }
                if (vk == 'H') { g_active_menu = 3; g_active_menu_item = 0; continue; }
            }

            // Gestion de l'édition normale
            if (g_focus == FOCUS_EDITOR) {
                if (vk == VK_UP) {
                    if (g_edit.cursor_y > 0) g_edit.cursor_y--;
                } else if (vk == VK_DOWN) {
                    if (g_edit.cursor_y < g_edit.line_count - 1) g_edit.cursor_y++;
                } else if (vk == VK_LEFT) {
                    if (g_edit.cursor_x > 0) g_edit.cursor_x--;
                } else if (vk == VK_RIGHT) {
                    int len = (int)strlen(g_edit.lines[g_edit.cursor_y]);
                    if (g_edit.cursor_x < len) g_edit.cursor_x++;
                } else if (vk == VK_HOME) {
                    g_edit.cursor_x = 0;
                } else if (vk == VK_END) {
                    g_edit.cursor_x = (int)strlen(g_edit.lines[g_edit.cursor_y]);
                } else if (vk == VK_PRIOR) { // Page Up
                    g_edit.cursor_y -= EDIT_HEIGHT;
                    if (g_edit.cursor_y < 0) g_edit.cursor_y = 0;
                } else if (vk == VK_NEXT) { // Page Down
                    g_edit.cursor_y += EDIT_HEIGHT;
                    if (g_edit.cursor_y >= g_edit.line_count) g_edit.cursor_y = g_edit.line_count - 1;
                } else if (vk == VK_RETURN) {
                    editor_newline(&g_edit);
                } else if (vk == VK_BACK) {
                    editor_backspace(&g_edit);
                } else if (vk == VK_DELETE) {
                    editor_delete_char(&g_edit);
                } else if (vk == VK_TAB) {
                    for (int t = 0; t < 4; t++) editor_insert_char(&g_edit, ' ');
                } else if (ch >= 32 && ch <= 126) {
                    editor_insert_char(&g_edit, ch);
                }
            } else if (g_focus == FOCUS_IMMEDIATE) {
                // Saisie dans la fenêtre immédiate
                if (vk == VK_RETURN) {
                    // Exécuter l'instruction immédiate
                    QB_Program *dummy = qb_program_create();
                    QB_Interpreter *immed_interp = qb_interp_create(dummy);
                    qb_cls();
                    qb_color(7, 0);
                    qb_interp_exec_immediate(immed_interp, g_immed_line);
                    printf("\nAppuyez sur une touche...");
                    fflush(stdout);
                    while (true) {
                        INPUT_RECORD ir2;
                        DWORD rc;
                        ReadConsoleInputA(g_hIn, &ir2, 1, &rc);
                        if (ir2.EventType == KEY_EVENT && ir2.Event.KeyEvent.bKeyDown) break;
                    }
                    qb_interp_free(immed_interp);
                    qb_program_free(dummy);
                    g_immed_line[0] = '\0';
                    g_immed_cursor = 0;
                    qb_cls();
                } else if (vk == VK_BACK) {
                    if (g_immed_cursor > 0) {
                        g_immed_line[--g_immed_cursor] = '\0';
                    }
                } else if (ch >= 32 && ch <= 126 && g_immed_cursor < 250) {
                    g_immed_line[g_immed_cursor++] = ch;
                    g_immed_line[g_immed_cursor] = '\0';
                }
            }
        }
    }

    editor_free(&g_edit);
    if (g_orig_in_mode != 0) {
        SetConsoleMode(g_hIn, g_orig_in_mode);
    }
    qb_cls();
    qb_color(7, 0);
    return 0;
}
