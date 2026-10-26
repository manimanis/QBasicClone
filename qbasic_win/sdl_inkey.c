/**
 * sdl_inkey.c - Implémentation complète et fidèle de la fonction INKEY$ de QBasic en SDL2
 */

#include "sdl_inkey.h"
#include <string.h>
#include <ctype.h>

typedef struct {
    char ch1;
    char ch2;
    int len;
} InkeyEntry;

#define INKEY_QUEUE_CAPACITY 256
static InkeyEntry s_queue[INKEY_QUEUE_CAPACITY];
static int s_head = 0;
static int s_tail = 0;

void sdl_inkey_init(void) {
    s_head = 0;
    s_tail = 0;
    if (!SDL_IsTextInputActive()) {
        SDL_StartTextInput();
    }
    const char *seq = getenv("QB_INKEY_SEQUENCE");
    if (seq && *seq) {
        const char *p = seq;
        while (*p) {
            if (*p == '{') {
                if (strncmp(p, "{UP}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_UP, 2); p += 4; }
                else if (strncmp(p, "{DOWN}", 6) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_DOWN, 2); p += 6; }
                else if (strncmp(p, "{LEFT}", 6) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_LEFT, 2); p += 6; }
                else if (strncmp(p, "{RIGHT}", 7) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_RIGHT, 2); p += 7; }
                else if (strncmp(p, "{HOME}", 6) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_HOME, 2); p += 6; }
                else if (strncmp(p, "{END}", 5) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_END, 2); p += 5; }
                else if (strncmp(p, "{PGUP}", 6) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_PAGEUP, 2); p += 6; }
                else if (strncmp(p, "{PGDN}", 6) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_PAGEDOWN, 2); p += 6; }
                else if (strncmp(p, "{INS}", 5) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_INSERT, 2); p += 5; }
                else if (strncmp(p, "{DEL}", 5) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_DELETE, 2); p += 5; }
                else if (strncmp(p, "{ENTER}", 7) == 0) { sdl_inkey_enqueue('\r', 0, 1); p += 7; }
                else if (strncmp(p, "{ESC}", 5) == 0) { sdl_inkey_enqueue(27, 0, 1); p += 5; }
                else if (strncmp(p, "{TAB}", 5) == 0) { sdl_inkey_enqueue('\t', 0, 1); p += 5; }
                else if (strncmp(p, "{BACKSPACE}", 11) == 0) { sdl_inkey_enqueue('\b', 0, 1); p += 11; }
                else if (strncmp(p, "{F1}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F1, 2); p += 4; }
                else if (strncmp(p, "{F2}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F2, 2); p += 4; }
                else if (strncmp(p, "{F3}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F3, 2); p += 4; }
                else if (strncmp(p, "{F4}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F4, 2); p += 4; }
                else if (strncmp(p, "{F5}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F5, 2); p += 4; }
                else if (strncmp(p, "{F6}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F6, 2); p += 4; }
                else if (strncmp(p, "{F7}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F7, 2); p += 4; }
                else if (strncmp(p, "{F8}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F8, 2); p += 4; }
                else if (strncmp(p, "{F9}", 4) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F9, 2); p += 4; }
                else if (strncmp(p, "{F10}", 5) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F10, 2); p += 5; }
                else if (strncmp(p, "{F11}", 5) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F11, 2); p += 5; }
                else if (strncmp(p, "{F12}", 5) == 0) { sdl_inkey_enqueue(0, DOS_SCAN_F12, 2); p += 5; }
                else {
                    sdl_inkey_enqueue(*p++, 0, 1);
                }
            } else {
                sdl_inkey_enqueue(*p++, 0, 1);
            }
        }
    }
}

void sdl_inkey_clear(void) {
    s_head = 0;
    s_tail = 0;
}

void sdl_inkey_enqueue(char ch1, char ch2, int len) {
    int next_tail = (s_tail + 1) % INKEY_QUEUE_CAPACITY;
    if (next_tail != s_head) {
        s_queue[s_tail].ch1 = ch1;
        s_queue[s_tail].ch2 = ch2;
        s_queue[s_tail].len = len;
        s_tail = next_tail;
    }
}

bool sdl_inkey_peek(char *out_ch1, char *out_ch2, int *out_len) {
    if (s_head == s_tail) return false;
    if (out_ch1) *out_ch1 = s_queue[s_head].ch1;
    if (out_ch2) *out_ch2 = s_queue[s_head].ch2;
    if (out_len) *out_len = s_queue[s_head].len;
    return true;
}

void sdl_inkey_pop(void) {
    if (s_head != s_tail) {
        s_head = (s_head + 1) % INKEY_QUEUE_CAPACITY;
    }
}

unsigned char sdl_utf8_to_cp437(const unsigned char *s, int *bytes_consumed) {
    if (!s || !*s) {
        if (bytes_consumed) *bytes_consumed = 0;
        return 0;
    }

    // Caractère ASCII standard 7-bit (0x00 à 0x7F)
    if (s[0] < 0x80) {
        if (bytes_consumed) *bytes_consumed = 1;
        return s[0];
    }

    // Séquence UTF-8 sur 2 octets (0xC0..0xDF)
    if ((s[0] & 0xE0) == 0xC0 && s[1] != '\0') {
        if (bytes_consumed) *bytes_consumed = 2;
        unsigned int cp = ((s[0] & 0x1F) << 6) | (s[1] & 0x3F);
        switch (cp) {
            case 0x00C7: return 0x80; // Ç
            case 0x00FC: return 0x81; // ü
            case 0x00E9: return 0x82; // é
            case 0x00E2: return 0x83; // â
            case 0x00E4: return 0x84; // ä
            case 0x00E0: return 0x85; // à
            case 0x00E5: return 0x86; // å
            case 0x00E7: return 0x87; // ç
            case 0x00EA: return 0x88; // ê
            case 0x00EB: return 0x89; // ë
            case 0x00E8: return 0x8A; // è
            case 0x00EF: return 0x8B; // ï
            case 0x00EE: return 0x8C; // î
            case 0x00EC: return 0x8D; // ì
            case 0x00C4: return 0x8E; // Ä
            case 0x00C5: return 0x8F; // Å
            case 0x00C9: return 0x90; // É
            case 0x00E6: return 0x91; // æ
            case 0x00C6: return 0x92; // Æ
            case 0x00F4: return 0x93; // ô
            case 0x00F6: return 0x94; // ö
            case 0x00F2: return 0x95; // ò
            case 0x00FB: return 0x96; // û
            case 0x00F9: return 0x97; // ù
            case 0x00FF: return 0x98; // ÿ
            case 0x00D6: return 0x99; // Ö
            case 0x00DC: return 0x9A; // Ü
            case 0x00A3: return 0x9C; // £
            case 0x00A5: return 0x9D; // ¥
            case 0x00E1: return 0xA0; // á
            case 0x00ED: return 0xA1; // í
            case 0x00F3: return 0xA2; // ó
            case 0x00FA: return 0xA3; // ú
            case 0x00F1: return 0xA4; // ñ
            case 0x00D1: return 0xA5; // Ñ
            case 0x00AA: return 0xA6; // ª
            case 0x00BA: return 0xA7; // º
            case 0x00BF: return 0xA8; // ¿
            case 0x00AC: return 0xAA; // ¬
            case 0x00BD: return 0xAB; // ½
            case 0x00BC: return 0xAC; // ¼
            case 0x00A1: return 0xAD; // ¡
            case 0x00AB: return 0xAE; // «
            case 0x00BB: return 0xAF; // »
            case 0x00B0: return 0xF8; // °
            case 0x00B7: return 0xFA; // ·
            case 0x00B2: return 0xFD; // ²
            case 0x00A7: return 0x15; // §
            case 0x00B5: return 0xE6; // µ
            case 0x00B1: return 0xF1; // ±
            default:     return (unsigned char)'?';
        }
    }

    // Séquence UTF-8 sur 3 octets (0xE0..0xEF)
    if ((s[0] & 0xF0) == 0xE0 && s[1] != '\0' && s[2] != '\0') {
        if (bytes_consumed) *bytes_consumed = 3;
        unsigned int cp = ((s[0] & 0x0F) << 12) | ((s[1] & 0x3F) << 6) | (s[2] & 0x3F);
        if (cp == 0x20AC) return 'E'; // Euro (€)
        return '?';
    }

    if (bytes_consumed) *bytes_consumed = 1;
    return s[0];
}

bool sdl_inkey_process_event(const SDL_Event *event) {
    if (!event) return false;

    // 1. Événements de saisie de texte (AZERTY, QWERTY, accents, AltGr, symboles)
    if (event->type == SDL_TEXTINPUT) {
        const unsigned char *p = (const unsigned char*)event->text.text;
        while (*p) {
            int consumed = 0;
            unsigned char cp = sdl_utf8_to_cp437(p, &consumed);
            if (cp != 0) {
                sdl_inkey_enqueue((char)cp, 0, 1);
            }
            p += (consumed > 0 ? consumed : 1);
        }
        return true;
    }

    // 2. Événements d'appui sur une touche (KEYDOWN) pour touches de contrôle et étendues
    if (event->type == SDL_KEYDOWN) {
        SDL_Keycode sym = event->key.keysym.sym;
        Uint16 mod = event->key.keysym.mod;
        bool is_ctrl = (mod & KMOD_CTRL) != 0;
        bool is_alt  = (mod & KMOD_ALT) != 0;
        bool is_shift = (mod & KMOD_SHIFT) != 0;
        bool is_num = (mod & KMOD_NUM) != 0;

        // Combinaisons Ctrl+Lettre (ex: Ctrl+A = 1, Ctrl+C = 3, etc.)
        if (is_ctrl && !is_alt && sym >= SDLK_a && sym <= SDLK_z) {
            char ctrl_ch = (char)(sym - SDLK_a + 1);
            sdl_inkey_enqueue(ctrl_ch, 0, 1);
            return true;
        }

        // Touches de contrôle standard (qui n'émettent pas de SDL_TEXTINPUT)
        switch (sym) {
            case SDLK_RETURN:
            case SDLK_KP_ENTER:
                sdl_inkey_enqueue('\r', 0, 1);
                return true;

            case SDLK_BACKSPACE:
                sdl_inkey_enqueue('\b', 0, 1);
                return true;

            case SDLK_TAB:
                sdl_inkey_enqueue('\t', 0, 1);
                return true;

            case SDLK_ESCAPE:
                sdl_inkey_enqueue(27, 0, 1);
                return true;

            default:
                break;
        }

        // Combinaisons Ctrl + Navigation
        if (is_ctrl && !is_alt) {
            switch (sym) {
                case SDLK_LEFT:     sdl_inkey_enqueue(0, DOS_SCAN_CTRL_LEFT, 2); return true;
                case SDLK_RIGHT:    sdl_inkey_enqueue(0, DOS_SCAN_CTRL_RIGHT, 2); return true;
                case SDLK_END:      sdl_inkey_enqueue(0, DOS_SCAN_CTRL_END, 2); return true;
                case SDLK_PAGEDOWN: sdl_inkey_enqueue(0, DOS_SCAN_CTRL_PGDN, 2); return true;
                case SDLK_HOME:     sdl_inkey_enqueue(0, DOS_SCAN_CTRL_HOME, 2); return true;
                case SDLK_PAGEUP:   sdl_inkey_enqueue(0, DOS_SCAN_CTRL_PGUP, 2); return true;
                default: break;
            }
        }

        // Touches de fonctions F1..F12
        if (sym >= SDLK_F1 && sym <= SDLK_F10) {
            int idx = sym - SDLK_F1;
            char sc = DOS_SCAN_F1 + idx;
            if (is_shift) sc = DOS_SCAN_SHIFT_F1 + idx;
            else if (is_ctrl) sc = DOS_SCAN_CTRL_F1 + idx;
            else if (is_alt) sc = DOS_SCAN_ALT_F1 + idx;
            sdl_inkey_enqueue(0, sc, 2);
            return true;
        }
        if (sym == SDLK_F11) {
            sdl_inkey_enqueue(0, DOS_SCAN_F11, 2);
            return true;
        }
        if (sym == SDLK_F12) {
            sdl_inkey_enqueue(0, DOS_SCAN_F12, 2);
            return true;
        }

        // Touches de navigation fléchées et curseur
        switch (sym) {
            case SDLK_UP:       sdl_inkey_enqueue(0, DOS_SCAN_UP, 2); return true;
            case SDLK_DOWN:     sdl_inkey_enqueue(0, DOS_SCAN_DOWN, 2); return true;
            case SDLK_LEFT:     sdl_inkey_enqueue(0, DOS_SCAN_LEFT, 2); return true;
            case SDLK_RIGHT:    sdl_inkey_enqueue(0, DOS_SCAN_RIGHT, 2); return true;
            case SDLK_HOME:     sdl_inkey_enqueue(0, DOS_SCAN_HOME, 2); return true;
            case SDLK_END:      sdl_inkey_enqueue(0, DOS_SCAN_END, 2); return true;
            case SDLK_PAGEUP:   sdl_inkey_enqueue(0, DOS_SCAN_PAGEUP, 2); return true;
            case SDLK_PAGEDOWN: sdl_inkey_enqueue(0, DOS_SCAN_PAGEDOWN, 2); return true;
            case SDLK_INSERT:   sdl_inkey_enqueue(0, DOS_SCAN_INSERT, 2); return true;
            case SDLK_DELETE:   sdl_inkey_enqueue(0, DOS_SCAN_DELETE, 2); return true;
            default: break;
        }

        // Pavé numérique lorsque VerrNum (NumLock) est désactivé
        if (!is_num) {
            switch (sym) {
                case SDLK_KP_8:      sdl_inkey_enqueue(0, DOS_SCAN_UP, 2); return true;
                case SDLK_KP_2:      sdl_inkey_enqueue(0, DOS_SCAN_DOWN, 2); return true;
                case SDLK_KP_4:      sdl_inkey_enqueue(0, DOS_SCAN_LEFT, 2); return true;
                case SDLK_KP_6:      sdl_inkey_enqueue(0, DOS_SCAN_RIGHT, 2); return true;
                case SDLK_KP_7:      sdl_inkey_enqueue(0, DOS_SCAN_HOME, 2); return true;
                case SDLK_KP_1:      sdl_inkey_enqueue(0, DOS_SCAN_END, 2); return true;
                case SDLK_KP_9:      sdl_inkey_enqueue(0, DOS_SCAN_PAGEUP, 2); return true;
                case SDLK_KP_3:      sdl_inkey_enqueue(0, DOS_SCAN_PAGEDOWN, 2); return true;
                case SDLK_KP_0:      sdl_inkey_enqueue(0, DOS_SCAN_INSERT, 2); return true;
                case SDLK_KP_PERIOD: sdl_inkey_enqueue(0, DOS_SCAN_DELETE, 2); return true;
                case SDLK_KP_5:      sdl_inkey_enqueue(0, DOS_SCAN_CENTER_5, 2); return true;
                default: break;
            }
        }
    }

    return false;
}

const char* sdl_inkey_ex(int *out_len) {
    static char buf[4];
    memset(buf, 0, sizeof(buf));

    if (s_head == s_tail) {
        if (out_len) *out_len = 0;
        return "";
    }

    InkeyEntry entry = s_queue[s_head];
    s_head = (s_head + 1) % INKEY_QUEUE_CAPACITY;

    if (entry.len == 1) {
        buf[0] = entry.ch1;
        buf[1] = '\0';
        buf[2] = '\0';
        if (out_len) *out_len = 1;
    } else if (entry.len == 2) {
        buf[0] = '\0';
        buf[1] = entry.ch2;
        buf[2] = '\0';
        if (out_len) *out_len = 2;
    } else {
        if (out_len) *out_len = 0;
        return "";
    }

    return buf;
}

const char* sdl_inkey(void) {
    int dummy = 0;
    return sdl_inkey_ex(&dummy);
}
