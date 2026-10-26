/**
 * sdl_inkey.h - Implémentation de la fonction INKEY$ de QBasic / QuickBASIC en SDL2
 *
 * Sémantique exacte de QBasic / QuickBASIC :
 * - Non-bloquante : renvoie immédiatement une chaîne vide "" si aucune touche n'est pressée.
 * - Pas d'écho à l'écran : n'affiche rien sur la sortie vidéo.
 * - Touches standard (ASCII / Code Page 437) : chaîne de 1 octet (ex: Entrée = CHR$(13), Échap = CHR$(27)).
 * - Touches étendues (Flèches, F1..F12, Inser, Suppr, etc.) : chaîne de 2 octets :
 *     1er octet = '\0' (CHR$(0))
 *     2ème octet = ScanCode BIOS DOS (ex: Flèche Haut = 72, Flèche Bas = 80).
 * - Support complet des dispositions internationales (AZERTY français, QWERTY, etc.)
 *   via SDL_TEXTINPUT et conversion UTF-8 -> CP437.
 * - Prise en charge du pavé numérique avec ou sans VerrNum (NumLock).
 */

#ifndef SDL_INKEY_H
#define SDL_INKEY_H

#include <SDL.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ScanCodes BIOS DOS pour les touches étendues QBasic (CHR$(0) + ScanCode) */
#define DOS_SCAN_F1          59
#define DOS_SCAN_F2          60
#define DOS_SCAN_F3          61
#define DOS_SCAN_F4          62
#define DOS_SCAN_F5          63
#define DOS_SCAN_F6          64
#define DOS_SCAN_F7          65
#define DOS_SCAN_F8          66
#define DOS_SCAN_F9          67
#define DOS_SCAN_F10         68
#define DOS_SCAN_HOME        71
#define DOS_SCAN_UP          72
#define DOS_SCAN_PAGEUP      73
#define DOS_SCAN_LEFT        75
#define DOS_SCAN_CENTER_5    76
#define DOS_SCAN_RIGHT       77
#define DOS_SCAN_END         79
#define DOS_SCAN_DOWN        80
#define DOS_SCAN_PAGEDOWN    81
#define DOS_SCAN_INSERT      82
#define DOS_SCAN_DELETE      83
#define DOS_SCAN_SHIFT_F1    84
#define DOS_SCAN_SHIFT_F2    85
#define DOS_SCAN_SHIFT_F3    86
#define DOS_SCAN_SHIFT_F4    87
#define DOS_SCAN_SHIFT_F5    88
#define DOS_SCAN_SHIFT_F6    89
#define DOS_SCAN_SHIFT_F7    90
#define DOS_SCAN_SHIFT_F8    91
#define DOS_SCAN_SHIFT_F9    92
#define DOS_SCAN_SHIFT_F10   93
#define DOS_SCAN_CTRL_F1     94
#define DOS_SCAN_CTRL_F2     95
#define DOS_SCAN_CTRL_F3     96
#define DOS_SCAN_CTRL_F4     97
#define DOS_SCAN_CTRL_F5     98
#define DOS_SCAN_CTRL_F6     99
#define DOS_SCAN_CTRL_F7     100
#define DOS_SCAN_CTRL_F8     101
#define DOS_SCAN_CTRL_F9     102
#define DOS_SCAN_CTRL_F10    103
#define DOS_SCAN_ALT_F1      104
#define DOS_SCAN_ALT_F2      105
#define DOS_SCAN_ALT_F3      106
#define DOS_SCAN_ALT_F4      107
#define DOS_SCAN_ALT_F5      108
#define DOS_SCAN_ALT_F6      109
#define DOS_SCAN_ALT_F7      110
#define DOS_SCAN_ALT_F8      111
#define DOS_SCAN_ALT_F9      112
#define DOS_SCAN_ALT_F10     113
#define DOS_SCAN_CTRL_LEFT   115
#define DOS_SCAN_CTRL_RIGHT  116
#define DOS_SCAN_CTRL_END    117
#define DOS_SCAN_CTRL_PGDN   118
#define DOS_SCAN_CTRL_HOME   119
#define DOS_SCAN_CTRL_PGUP   132
#define DOS_SCAN_F11         133
#define DOS_SCAN_F12         134

/**
 * Initialise le module INKEY$ et active la saisie de texte SDL (SDL_StartTextInput).
 */
void sdl_inkey_init(void);

/**
 * Vide la file d'attente clavier (équivalent de WHILE INKEY$ <> "": WEND en QBasic).
 */
void sdl_inkey_clear(void);

/**
 * Injecte / traite un événement SDL dans le gestionnaire INKEY$.
 * À appeler dans la boucle d'événements SDL (SDL_PollEvent).
 *
 * @param event Pointeur vers l'événement SDL.
 * @return true si l'événement clavier a été capturé, false sinon.
 */
bool sdl_inkey_process_event(const SDL_Event *event);

/**
 * Enfile manuellement une touche dans le buffer INKEY$.
 * @param ch1 Premier octet (ASCII ou '\0' pour touche étendue).
 * @param ch2 Deuxième octet (0 ou ScanCode DOS si ch1 == '\0').
 * @param len Longueur (1 ou 2).
 */
void sdl_inkey_enqueue(char ch1, char ch2, int len);

/**
 * Implémentation principale de INKEY$ :
 * - Renvoie immédiatement "" si aucune touche n'est disponible (non-bloquante).
 * - Renvoie un pointeur vers un buffer statique contenant :
 *     - Pour une touche ASCII : { c, '\0' } (taille 1).
 *     - Pour une touche étendue : { '\0', scancode, '\0' } (taille 2).
 * - N'effectue aucun écho graphique ni affichage console (non-echoing).
 */
const char* sdl_inkey(void);

/**
 * Variante retournant la longueur exacte de la touche (utile en C pour détecter '\0').
 * @param out_len Pointeur recevant 0, 1 ou 2.
 */
const char* sdl_inkey_ex(int *out_len);

/**
 * Convertit une séquence UTF-8 en octet Code Page 437 DOS (pour les claviers français / européens).
 */
unsigned char sdl_utf8_to_cp437(const unsigned char *s, int *bytes_consumed);

/**
 * Consulte la prochaine touche dans la file sans la consommer.
 */
bool sdl_inkey_peek(char *out_ch1, char *out_ch2, int *out_len);

/**
 * Consomme la première touche de la file d'attente.
 */
void sdl_inkey_pop(void);

#ifdef __cplusplus
}
#endif

#endif /* SDL_INKEY_H */
