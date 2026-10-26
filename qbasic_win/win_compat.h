#ifndef WIN_COMPAT_H
#define WIN_COMPAT_H

#include <windows.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Initialise la console Windows (UTF-8, mode ANSI/VT, gestion du buffer)
void qb_compat_init(void);

// CLS : Efface l'écran console
void qb_cls(void);

// Dump framebuffer to BMP file for testing / screenshots
void qb_dump_screen_bmp(const char *filename);

// LOCATE row, col (1-indexé comme en QBasic : row 1..25, col 1..80)
void qb_locate(int row, int col);

// COLOR foreground, background (0..15 palette standard DOS/Win32)
void qb_color(int fg, int bg);

// BEEP : Émet un signal sonore (750 Hz pendant 250 ms)
void qb_beep(void);

// SOUND freq, duration (durée en millisecondes ou cycles d'horloge)
void qb_sound(int freq, int duration_ms);

// SLEEP seconds (temps d'attente en secondes, supporte les décimales)
void qb_sleep(double seconds);

// INKEY$ : Renvoie la touche pressée sans bloquer, ou NULL/chaîne vide si aucune touche
const char* qb_inkey(void);
const char* qb_inkey_ex(int *out_len);
void qb_clear_keyboard(void);

// Saisie d'une ligne de texte au clavier (LINE INPUT / INPUT) avec écho et curseur interactif
char* qb_console_read_line(char *buf, int max_len);

// TIMER : Renvoie le nombre de secondes écoulées depuis minuit (double précision)
double qb_timer(void);

// Affiche une chaîne à la position courante avec retour chariot
void qb_print_line(const char *text);

// Affiche une chaîne à la position courante sans retour chariot
void qb_print_string(const char *text);

// PALETTE attr, hw_color (reprogrammation de palette EGA/VGA)
void qb_palette_set(int attr, int hw_color);

// SCREEN mode (0 = texte 80x25, 12 = 640x480, 13 = 320x200)
void qb_screen(int mode);

// PSET (x, y), color
void qb_pset(int x, int y, int color);

// LINE (x1, y1)-(x2, y2), color [, B|BF]
void qb_line(int x1, int y1, int x2, int y2, int color, bool box, bool fill);

// CIRCLE (x, y), radius, color
void qb_circle(int cx, int cy, int radius, int color);

// CIRCLE avec support d'arc (angles en radians, ratio d'aspect)
void qb_circle_arc(int cx, int cy, int radius, int color, double start_ang, double end_ang, double aspect);

// POINT(x, y) : Renvoie la couleur de palette (0..15) du pixel graphique
int qb_point(int x, int y);

// PAINT (x, y), fill_color [, border_color] : Remplissage par diffusion
void qb_paint(int x, int y, int fill_color, int border_color);

// GET (x1, y1)-(x2, y2), arr_name [(offset)] : Capture de zone graphique dans un tableau
void qb_gfx_get(int x1, int y1, int x2, int y2, void *env, const char *arr_name, int offset);

// PUT (x, y), arr_name [(offset)], mode : Affichage de sprite (PSET ou XOR)
void qb_gfx_put(int x, int y, void *env, const char *arr_name, int offset, const char *mode);

// PLAY "..." : Interpréteur Music Macro Language (MML)
void qb_play(const char *mml);
int qb_play_get_notes_remaining(void);

// DRAW "..." : Interpréteur de commandes graphiques Turtle/Graphics
void qb_draw(const char *cmd_str);

// Port I/O (EGA/VGA Sequencer & Graphics registers, Keyboard)
void qb_out_port(int port, int val);
int qb_inp_port(int port);

// DEF SEG [= expr]
void qb_def_seg(int seg);

// BLOAD filename$ [, offset]
void qb_bload(const char *filename, int offset);

// Répertoire du programme en cours d'exécution
void qb_set_program_dir(const char *dir);
const char* qb_get_program_dir(void);
extern int g_title_done;

#ifdef __cplusplus
}
#endif

#endif // WIN_COMPAT_H
