#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <SDL_syswm.h>
#include "win_compat.h"
#include "sdl_inkey.h"
#include "qb_types.h"
#include "qb_font.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <math.h>
#include <ctype.h>
#include <time.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* ========================================================================= */
/*                              PALETTE & COULEURS                           */
/* ========================================================================= */

#define ARGB(r, g, b) (((uint32_t)0xFF << 24) | (((uint32_t)(r) & 0xFF) << 16) | (((uint32_t)(g) & 0xFF) << 8) | ((uint32_t)(b) & 0xFF))

static const uint32_t default_16_palette[16] = {
    ARGB(0x00, 0x00, 0x00), // 0: Noir
    ARGB(0x00, 0x00, 0xAA), // 1: Bleu
    ARGB(0x00, 0xAA, 0x00), // 2: Vert
    ARGB(0x00, 0xAA, 0xAA), // 3: Cyan
    ARGB(0xAA, 0x00, 0x00), // 4: Rouge
    ARGB(0xAA, 0x00, 0xAA), // 5: Magenta
    ARGB(0xAA, 0x55, 0x00), // 6: Brun
    ARGB(0xAA, 0xAA, 0xAA), // 7: Gris clair
    ARGB(0x55, 0x55, 0x55), // 8: Gris foncé
    ARGB(0x55, 0x55, 0xFF), // 9: Bleu clair
    ARGB(0x55, 0xFF, 0x55), // 10: Vert clair
    ARGB(0x55, 0xFF, 0xFF), // 11: Cyan clair
    ARGB(0xFF, 0x55, 0x55), // 12: Rouge clair
    ARGB(0xFF, 0x55, 0xFF), // 13: Magenta clair
    ARGB(0xFF, 0xFF, 0x55), // 14: Jaune
    ARGB(0xFF, 0xFF, 0xFF)  // 15: Blanc éclatant
};

static uint32_t current_palette[256];
static int palette_size = 16;

static uint32_t ega_to_rgb(int hw) {
    int r = ((hw & 0x04) ? 0xAA : 0) + ((hw & 0x20) ? 0x55 : 0);
    int g = ((hw & 0x02) ? 0xAA : 0) + ((hw & 0x10) ? 0x55 : 0);
    int b = ((hw & 0x01) ? 0xAA : 0) + ((hw & 0x08) ? 0x55 : 0);
    return ARGB(r, g, b);
}

static void init_palette_16(void) {
    palette_size = 16;
    for (int i = 0; i < 16; i++) {
        current_palette[i] = default_16_palette[i];
    }
}

static void init_palette_cga(int bg, int pal_id) {
    palette_size = 4;
    current_palette[0] = default_16_palette[bg & 15];
    if (pal_id == 0) {
        current_palette[1] = ARGB(0x00, 0xAA, 0x00); // Vert
        current_palette[2] = ARGB(0xAA, 0x00, 0x00); // Rouge
        current_palette[3] = ARGB(0xAA, 0x55, 0x00); // Brun
    } else {
        current_palette[1] = ARGB(0x00, 0xAA, 0xAA); // Cyan
        current_palette[2] = ARGB(0xAA, 0x00, 0xAA); // Magenta
        current_palette[3] = ARGB(0xAA, 0xAA, 0xAA); // Blanc / Gris clair
    }
}

static void init_palette_mono(void) {
    palette_size = 2;
    current_palette[0] = ARGB(0x00, 0x00, 0x00);
    current_palette[1] = ARGB(0xFF, 0xFF, 0xFF);
}

static void init_palette_mono_4(void) {
    palette_size = 4;
    current_palette[0] = ARGB(0x00, 0x00, 0x00);
    current_palette[1] = ARGB(0x55, 0x55, 0x55);
    current_palette[2] = ARGB(0xAA, 0xAA, 0xAA);
    current_palette[3] = ARGB(0xFF, 0xFF, 0xFF);
}

static void init_palette_vga_256(void) {
    palette_size = 256;
    for (int i = 0; i < 16; i++) {
        current_palette[i] = default_16_palette[i];
    }
    for (int i = 0; i < 16; i++) {
        int v = (i * 255) / 15;
        current_palette[16 + i] = ARGB(v, v, v);
    }
    int idx = 32;
    for (int r = 0; r < 6; r++) {
        for (int g = 0; g < 6; g++) {
            for (int b = 0; b < 6; b++) {
                if (idx < 256) {
                    current_palette[idx++] = ARGB(r * 51, g * 51, b * 51);
                }
            }
        }
    }
    while (idx < 256) {
        current_palette[idx++] = ARGB(0, 0, 0);
    }
}

/* ========================================================================= */
/*                          AUDIO PC SPEAKER SYNTHESIZER                     */
/* ========================================================================= */

#define MAX_AUDIO_QUEUE 2048

typedef struct {
    int freq;
    int duration_ms;
    int rest_ms;
} AudioNote;

static AudioNote audio_queue[MAX_AUDIO_QUEUE];
static int audio_head = 0;
static int audio_tail = 0;
static SDL_AudioDeviceID audio_dev = 0;
static double audio_phase = 0.0;
static int cur_note_freq = 0;
static int cur_note_samples_left = 0;
static int cur_note_rest_samples_left = 0;

static bool is_test_mode(void) {
    const char *tm = getenv("QB_TEST_MODE");
    return (tm && tm[0] == '1');
}

static void sdl_audio_callback(void *userdata, Uint8 *stream, int len) {
    (void)userdata;
    int16_t *out = (int16_t*)stream;
    int sample_count = len / 2;

    for (int i = 0; i < sample_count; i++) {
        if (cur_note_samples_left <= 0 && cur_note_rest_samples_left <= 0) {
            if (audio_head != audio_tail) {
                AudioNote note = audio_queue[audio_head];
                audio_head = (audio_head + 1) % MAX_AUDIO_QUEUE;
                cur_note_freq = note.freq;
                cur_note_samples_left = (int)((long long)note.duration_ms * 44100 / 1000);
                cur_note_rest_samples_left = (int)((long long)note.rest_ms * 44100 / 1000);
                audio_phase = 0.0;
            } else {
                cur_note_freq = 0;
                cur_note_samples_left = 0;
                cur_note_rest_samples_left = 0;
            }
        }

        int16_t sample = 0;
        if (cur_note_samples_left > 0 && cur_note_freq > 0) {
            double inc = (double)cur_note_freq / 44100.0;
            sample = (audio_phase < 0.5) ? 5000 : -5000;
            audio_phase += inc;
            if (audio_phase >= 1.0) audio_phase -= 1.0;
            cur_note_samples_left--;
        } else if (cur_note_samples_left > 0) {
            cur_note_samples_left--;
        } else if (cur_note_rest_samples_left > 0) {
            cur_note_rest_samples_left--;
        }
        out[i] = sample;
    }
}

static void init_sdl_audio(void) {
    if (audio_dev != 0) return;
    if (SDL_WasInit(SDL_INIT_AUDIO) == 0) {
        SDL_SetMainReady();
        SDL_InitSubSystem(SDL_INIT_AUDIO);
    }
    SDL_AudioSpec want, have;
    SDL_zero(want);
    want.freq = 44100;
    want.format = AUDIO_S16SYS;
    want.channels = 1;
    want.samples = 512;
    want.callback = sdl_audio_callback;

    audio_dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if (audio_dev != 0) {
        SDL_PauseAudioDevice(audio_dev, 0);
    }
}

static void queue_tone(int freq, int duration_ms, int rest_ms) {
    init_sdl_audio();
    if (duration_ms <= 0 && rest_ms <= 0) return;
    if (audio_dev != 0) {
        while (1) {
            SDL_LockAudioDevice(audio_dev);
            int next = (audio_tail + 1) % MAX_AUDIO_QUEUE;
            if (next != audio_head) {
                audio_queue[audio_tail].freq = freq;
                audio_queue[audio_tail].duration_ms = duration_ms;
                audio_queue[audio_tail].rest_ms = rest_ms;
                audio_tail = next;
                SDL_UnlockAudioDevice(audio_dev);
                SDL_PauseAudioDevice(audio_dev, 0);
                break;
            }
            SDL_UnlockAudioDevice(audio_dev);
            if (is_test_mode()) break;
            SDL_Delay(5);
        }
    }
}

int qb_play_get_notes_remaining(void) {
    int count = 0;
    if (audio_dev != 0) {
        SDL_LockAudioDevice(audio_dev);
        count = (audio_tail - audio_head + MAX_AUDIO_QUEUE) % MAX_AUDIO_QUEUE;
        if (cur_note_samples_left > 0 || cur_note_rest_samples_left > 0) count++;
        SDL_UnlockAudioDevice(audio_dev);
    }
    return count;
}

/* ========================================================================= */
/*                          SDL GRAPHICS SUBSYSTEM                           */
/* ========================================================================= */

static SDL_Window *sdl_window = NULL;
static SDL_Renderer *sdl_renderer = NULL;
static SDL_Texture *sdl_texture = NULL;

static int gfx_mode = -1;
static int gfx_width = 640;
static int gfx_height = 400;
static int font_w = 8;
static int font_h = 16;

static uint8_t *gfx_vram = NULL;
static uint32_t *gfx_argb_buffer = NULL;
static bool gfx_dirty = false;

static int text_row = 1;
static int text_col = 1;
static int text_fg = 15;
static int text_bg = 0;
static int text_max_rows = 25;
static int text_max_cols = 80;


static HANDLE hStdOut = INVALID_HANDLE_VALUE;
static HANDLE hStdIn = INVALID_HANDLE_VALUE;
static WORD defaultAttributes = 7;
int g_title_done = 0;

static void pump_gfx_messages(void);

static void sdl_flip(void) {
    if (!sdl_renderer || !sdl_texture || !gfx_vram || !gfx_argb_buffer) return;
    if (!gfx_dirty) return;

    int total = gfx_width * gfx_height;
    for (int i = 0; i < total; i++) {
        gfx_argb_buffer[i] = current_palette[gfx_vram[i]];
    }

    SDL_UpdateTexture(sdl_texture, NULL, gfx_argb_buffer, gfx_width * sizeof(uint32_t));
    SDL_RenderClear(sdl_renderer);
    SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
    SDL_RenderPresent(sdl_renderer);
    gfx_dirty = false;

    const char *dump_path = getenv("QB_DUMP_BMP");
    if (dump_path && dump_path[0]) {
        qb_dump_screen_bmp(dump_path);
    }
}

void qb_dump_screen_bmp(const char *filename) {
    if (!gfx_vram || gfx_width <= 0 || gfx_height <= 0) return;
    char tmp_name[300];
    snprintf(tmp_name, sizeof(tmp_name), "%s.tmp", filename);
    FILE *f = fopen(tmp_name, "wb");
    if (!f) return;
    int w = gfx_width;
    int h = gfx_height;
    int row_bytes = w * 4;
    int img_size = row_bytes * h;
    int file_size = 54 + img_size;
    int32_t neg_h = -h;
    uint8_t h_buf[54] = {
        'B', 'M',
        (uint8_t)(file_size), (uint8_t)(file_size>>8), (uint8_t)(file_size>>16), (uint8_t)(file_size>>24),
        0, 0, 0, 0,
        54, 0, 0, 0,
        40, 0, 0, 0,
        (uint8_t)(w), (uint8_t)(w>>8), (uint8_t)(w>>16), (uint8_t)(w>>24),
        (uint8_t)(neg_h), (uint8_t)(neg_h>>8), (uint8_t)(neg_h>>16), (uint8_t)(neg_h>>24),
        1, 0, 32, 0, 0, 0, 0, 0,
        (uint8_t)(img_size), (uint8_t)(img_size>>8), (uint8_t)(img_size>>16), (uint8_t)(img_size>>24),
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    fwrite(h_buf, 1, 54, f);
    uint32_t *pixels = (uint32_t*)malloc(img_size);
    if (pixels) {
        for (int i = 0; i < w * h; i++) {
            pixels[i] = current_palette[gfx_vram[i]];
        }
        fwrite(pixels, 1, img_size, f);
        free(pixels);
    }
    fclose(f);
    MoveFileExA(tmp_name, filename, MOVEFILE_REPLACE_EXISTING);
}

static void create_or_resize_sdl_window(int w, int h, int fw, int fh, const char *title) {
    if (SDL_WasInit(SDL_INIT_VIDEO) == 0) {
        SDL_SetMainReady();
        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
    }

    gfx_width = w;
    gfx_height = h;
    font_w = fw;
    font_h = fh;
    text_max_cols = w / fw;
    text_max_rows = h / fh;

    if (gfx_vram) free(gfx_vram);
    if (gfx_argb_buffer) free(gfx_argb_buffer);

    gfx_vram = (uint8_t*)calloc(w * h, 1);
    gfx_argb_buffer = (uint32_t*)calloc(w * h, sizeof(uint32_t));

    int win_w = w * 2;
    int win_h = h * 2;
    if (w <= 320) {
        win_w = w * 3;
        win_h = h * 3;
    }
    if (w == 640 && h == 200) {
        win_w = 1280;
        win_h = 800; // Aspect ratio correction 4:3
    }
    if (w == 720 && h == 348) {
        win_w = 1440;
        win_h = 700;
    }

    if (!sdl_window) {
        sdl_window = SDL_CreateWindow(title,
                                      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                      win_w, win_h,
                                      SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
        sdl_renderer = SDL_CreateRenderer(sdl_window, -1, SDL_RENDERER_ACCELERATED);
    } else {
        SDL_SetWindowTitle(sdl_window, title);
        SDL_SetWindowSize(sdl_window, win_w, win_h);
        if (sdl_texture) {
            SDL_DestroyTexture(sdl_texture);
            sdl_texture = NULL;
        }
    }

    SDL_RenderSetLogicalSize(sdl_renderer, w, h);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest");

    sdl_texture = SDL_CreateTexture(sdl_renderer,
                                    SDL_PIXELFORMAT_ARGB8888,
                                    SDL_TEXTUREACCESS_STREAMING,
                                    w, h);
    SDL_StartTextInput();
    SDL_RaiseWindow(sdl_window);

    // Forcer le focus avant-plan sur Windows
    SDL_SysWMinfo wmInfo;
    SDL_VERSION(&wmInfo.version);
    if (SDL_GetWindowWMInfo(sdl_window, &wmInfo)) {
        HWND hwnd = wmInfo.info.win.window;
        if (hwnd) {
            DWORD foreThread = GetWindowThreadProcessId(GetForegroundWindow(), NULL);
            DWORD appThread = GetCurrentThreadId();
            if (foreThread != appThread) {
                AttachThreadInput(foreThread, appThread, TRUE);
                BringWindowToTop(hwnd);
                SetForegroundWindow(hwnd);
                SetActiveWindow(hwnd);
                SetFocus(hwnd);
                AttachThreadInput(foreThread, appThread, FALSE);
            } else {
                BringWindowToTop(hwnd);
                SetForegroundWindow(hwnd);
                SetActiveWindow(hwnd);
                SetFocus(hwnd);
            }
        }
    }

    gfx_dirty = true;
    sdl_flip();
}

/* ========================================================================= */
/*                          COMPAT INIT & SCREEN MODES                       */
/* ========================================================================= */

void qb_compat_init(void) {
    hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    hStdIn = GetStdHandle(STD_INPUT_HANDLE);
    if (hStdIn != INVALID_HANDLE_VALUE) {
        FlushConsoleInputBuffer(hStdIn);
    }

    // Support Unicode (UTF-8) par défaut sur Windows
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);

    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (GetConsoleScreenBufferInfo(hStdOut, &csbi)) {
        defaultAttributes = csbi.wAttributes;
    }
    DWORD cMode = 0;
    if (GetConsoleMode(hStdOut, &cMode)) {
        SetConsoleMode(hStdOut, cMode | ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_PROCESSED_OUTPUT);
    }
    init_palette_16();
    init_sdl_audio();
    sdl_inkey_init();
    qb_screen(0);
}

void qb_screen(int mode) {
    if (mode == gfx_mode && sdl_window != NULL) {
        qb_cls();
        return;
    }
    gfx_mode = mode;

    switch (mode) {
        case 0:
            // Mode texte 80x25 (640x400, police 8x16, 16 couleurs)
            create_or_resize_sdl_window(640, 400, 8, 16, "QBasic - Screen 0 (80x25 Text)");
            init_palette_16();
            break;
        case 1:
            // 320x200, 4 couleurs CGA
            create_or_resize_sdl_window(320, 200, 8, 8, "QBasic Graphics - Screen 1 (320x200 CGA)");
            init_palette_cga(0, 1);
            break;
        case 2:
            // 640x200, 2 couleurs CGA Mono
            create_or_resize_sdl_window(640, 200, 8, 8, "QBasic Graphics - Screen 2 (640x200 CGA Mono)");
            init_palette_mono();
            break;
        case 3:
            // 720x348, 2 couleurs Hercules
            create_or_resize_sdl_window(720, 348, 8, 14, "QBasic Graphics - Screen 3 (720x348 Hercules)");
            init_palette_mono();
            break;
        case 4:
            // 640x400, 2 couleurs Olivetti Mono
            create_or_resize_sdl_window(640, 400, 8, 16, "QBasic Graphics - Screen 4 (640x400 Olivetti Mono)");
            init_palette_mono();
            break;
        case 5:
        case 6:
            // Modes 320x200 Tandy / PCjr
            create_or_resize_sdl_window(320, 200, 8, 8, "QBasic Graphics - Screen 5/6 (320x200 4 Colors)");
            init_palette_cga(0, 1);
            break;
        case 7:
            // 320x200, 16 couleurs EGA
            create_or_resize_sdl_window(320, 200, 8, 8, "QBasic Graphics - Screen 7 (320x200 EGA 16 Colors)");
            init_palette_16();
            break;
        case 8:
            // 640x200, 16 couleurs EGA
            create_or_resize_sdl_window(640, 200, 8, 8, "QBasic Graphics - Screen 8 (640x200 EGA 16 Colors)");
            init_palette_16();
            break;
        case 9:
            // 640x350, 16 couleurs EGA/VGA
            create_or_resize_sdl_window(640, 350, 8, 14, "QBasic Graphics - Screen 9 (640x350 EGA/VGA)");
            init_palette_16();
            break;
        case 10:
            // 640x350, 4 couleurs EGA Mono
            create_or_resize_sdl_window(640, 350, 8, 14, "QBasic Graphics - Screen 10 (640x350 EGA Mono)");
            init_palette_mono_4();
            break;
        case 11:
            // 640x480, 2 couleurs VGA Mono
            create_or_resize_sdl_window(640, 480, 8, 16, "QBasic Graphics - Screen 11 (640x480 VGA Mono)");
            init_palette_mono();
            break;
        case 12:
            // 640x480, 16 couleurs VGA
            create_or_resize_sdl_window(640, 480, 8, 16, "QBasic Graphics - Screen 12 (640x480 VGA 16 Colors)");
            init_palette_16();
            break;
        case 13:
            // 320x200, 256 couleurs VGA (Mode 13h)
            create_or_resize_sdl_window(320, 200, 8, 8, "QBasic Graphics - Screen 13 (320x200 256 Colors - Mode 13h)");
            init_palette_vga_256();
            break;
        default:
            create_or_resize_sdl_window(640, 480, 8, 16, "QBasic Graphics");
            init_palette_16();
            break;
    }
    qb_cls();
}

void qb_width(int cols, int rows) {
    if (cols <= 0) cols = text_max_cols;
    if (rows <= 0) rows = text_max_rows;

    if (gfx_mode == 9 || gfx_mode == 10) {
        if (rows >= 43) {
            font_h = 8;
        } else {
            font_h = 14;
        }
        text_max_cols = (font_w > 0) ? (gfx_width / font_w) : 80;
        text_max_rows = (font_h > 0) ? (gfx_height / font_h) : 25;
    } else if (gfx_mode == 0) {
        if (rows >= 43 || rows == 50) {
            font_h = 8;
        } else {
            font_h = 16;
        }
        text_max_cols = (font_w > 0) ? (gfx_width / font_w) : 80;
        text_max_rows = (font_h > 0) ? (gfx_height / font_h) : 25;
    } else if (gfx_mode == 11 || gfx_mode == 12) {
        if (rows >= 50 || rows == 60) {
            font_h = 8;
        } else {
            font_h = 16;
        }
        text_max_cols = (font_w > 0) ? (gfx_width / font_w) : 80;
        text_max_rows = (font_h > 0) ? (gfx_height / font_h) : 30;
    }
}

void qb_palette_set(int attr, int hw_color) {
    if (attr < 0 || attr >= palette_size) return;
    if (gfx_mode == 9 || gfx_mode == 10) {
        current_palette[attr] = ega_to_rgb(hw_color);
    } else if (gfx_mode == 13) {
        // En mode 13h, hw_color peut être directement un code couleur ou attribut
        if (hw_color >= 0 && hw_color < 256) {
            current_palette[attr] = current_palette[hw_color];
        }
    } else {
        if (hw_color >= 0 && hw_color < 16) {
            current_palette[attr] = default_16_palette[hw_color];
        } else {
            current_palette[attr] = ega_to_rgb(hw_color);
        }
    }
    gfx_dirty = true;
    sdl_flip();
}

/* ========================================================================= */
/*                          CONSOLE & TEXT RENDERING                         */
/* ========================================================================= */

void qb_cls(void) {
    text_row = 1;
    text_col = 1;

    if (gfx_vram) {
        uint8_t bg = (gfx_mode > 0) ? 0 : (uint8_t)(text_bg & (palette_size - 1));
        memset(gfx_vram, bg, gfx_width * gfx_height);
        gfx_dirty = true;
        sdl_flip();
    } else if (hStdOut != INVALID_HANDLE_VALUE) {
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        DWORD count;
        COORD homeCoords = { 0, 0 };
        if (GetConsoleScreenBufferInfo(hStdOut, &csbi)) {
            DWORD cellCount = csbi.dwSize.X * csbi.dwSize.Y;
            FillConsoleOutputCharacterA(hStdOut, ' ', cellCount, homeCoords, &count);
            FillConsoleOutputAttribute(hStdOut, csbi.wAttributes, cellCount, homeCoords, &count);
            SetConsoleCursorPosition(hStdOut, homeCoords);
        }
    }
}

void qb_locate(int row, int col) {
    if (row > 0) text_row = row;
    if (col > 0) text_col = col;

    if (!sdl_window || !gfx_vram) {
        if (hStdOut != INVALID_HANDLE_VALUE) {
            COORD pos = { (SHORT)(text_col - 1), (SHORT)(text_row - 1) };
            SetConsoleCursorPosition(hStdOut, pos);
        }
    }
}

void qb_color(int fg, int bg) {
    text_fg = fg;
    if (bg >= 0) text_bg = bg;

    if (!sdl_window || !gfx_vram) {
        if (hStdOut != INVALID_HANDLE_VALUE) {
            WORD attr = 0;
            int f = text_fg & 15;
            int b = text_bg & 15;
            if (f & 1) attr |= FOREGROUND_BLUE;
            if (f & 2) attr |= FOREGROUND_GREEN;
            if (f & 4) attr |= FOREGROUND_RED;
            if (f & 8) attr |= FOREGROUND_INTENSITY;
            if (b & 1) attr |= BACKGROUND_BLUE;
            if (b & 2) attr |= BACKGROUND_GREEN;
            if (b & 4) attr |= BACKGROUND_RED;
            if (b & 8) attr |= BACKGROUND_INTENSITY;
            SetConsoleTextAttribute(hStdOut, attr);
        }
    }
}

static void draw_glyph(int px, int py, unsigned char ch, int fg, int bg) {
    if (!gfx_vram) return;
    fg &= (palette_size - 1);
    bg &= (palette_size - 1);

    for (int y = 0; y < font_h; y++) {
        uint8_t row_bits = 0;
        if (font_h == 8) {
            row_bits = qb_font_8x8[ch][y];
        } else if (font_h == 14) {
            row_bits = qb_font_8x14[ch][y];
        } else {
            row_bits = qb_font_8x16[ch][y];
        }

        int vy = py + y;
        if (vy < 0 || vy >= gfx_height) continue;

        for (int x = 0; x < font_w; x++) {
            int vx = px + x;
            if (vx < 0 || vx >= gfx_width) continue;

            bool bit = (row_bits & (1 << (7 - (x % 8)))) != 0;
            gfx_vram[vy * gfx_width + vx] = bit ? (uint8_t)fg : (uint8_t)bg;
        }
    }
}

static void scroll_text_up(void) {
    if (!gfx_vram) return;
    int line_bytes = gfx_width * font_h;
    int total_bytes = gfx_width * gfx_height;
    memmove(gfx_vram, gfx_vram + line_bytes, total_bytes - line_bytes);
    memset(gfx_vram + total_bytes - line_bytes, (uint8_t)(text_bg & (palette_size - 1)), line_bytes);
    gfx_dirty = true;
}

void qb_print_string(const char *text) {
    if (!text) return;

    if (sdl_window && gfx_vram) {
        for (const unsigned char *p = (const unsigned char*)text; *p; ) {
            unsigned char ch = *p;
            int consumed = 1;
            if (ch >= 0x80) {
                ch = sdl_utf8_to_cp437(p, &consumed);
                if (consumed <= 0) consumed = 1;
            }
            if (ch == '\n') {
                text_row++;
                text_col = 1;
                if (text_row > text_max_rows) {
                    scroll_text_up();
                    text_row = text_max_rows;
                }
            } else if (ch == '\r') {
                text_col = 1;
            } else if (ch == '\t') {
                text_col = ((text_col - 1) / 8 + 1) * 8 + 1;
                if (text_col > text_max_cols) {
                    text_col = 1;
                    text_row++;
                    if (text_row > text_max_rows) {
                        scroll_text_up();
                        text_row = text_max_rows;
                    }
                }
            } else if (ch == '\b') {
                if (text_col > 1) {
                    text_col--;
                    int px = (text_col - 1) * font_w;
                    int py = (text_row - 1) * font_h;
                    draw_glyph(px, py, ' ', text_fg, text_bg);
                }
            } else {
                if (text_col > text_max_cols) {
                    text_col = 1;
                    text_row++;
                    if (text_row > text_max_rows) {
                        scroll_text_up();
                        text_row = text_max_rows;
                    }
                }
                int px = (text_col - 1) * font_w;
                int py = (text_row - 1) * font_h;
                draw_glyph(px, py, ch, text_fg, text_bg);
                text_col++;
            }
            p += consumed;
        }
        gfx_dirty = true;
        sdl_flip();
    }
    if (hStdOut != INVALID_HANDLE_VALUE) {
        DWORD written = 0;
        DWORD cMode = 0;
        if (strcmp(text, "\b") == 0) {
            if (GetConsoleMode(hStdOut, &cMode)) {
                WriteConsoleW(hStdOut, L"\b \b", 3, &written, NULL);
            } else {
                WriteFile(hStdOut, "\b \b", 3, &written, NULL);
            }
        } else {
            if (GetConsoleMode(hStdOut, &cMode)) {
                int wlen = MultiByteToWideChar(CP_UTF8, 0, text, -1, NULL, 0);
                if (wlen > 1) {
                    wchar_t *wbuf = (wchar_t*)malloc(wlen * sizeof(wchar_t));
                    if (wbuf) {
                        MultiByteToWideChar(CP_UTF8, 0, text, -1, wbuf, wlen);
                        WriteConsoleW(hStdOut, wbuf, (DWORD)(wlen - 1), &written, NULL);
                        free(wbuf);
                    } else {
                        WriteFile(hStdOut, text, (DWORD)strlen(text), &written, NULL);
                    }
                }
            } else {
                WriteFile(hStdOut, text, (DWORD)strlen(text), &written, NULL);
            }
        }
    }
}

void qb_print_line(const char *text) {
    if (text) qb_print_string(text);
    qb_print_string("\n");
}

/* ========================================================================= */
/*                              GRAPHICS PRIMITIVES                          */
/* ========================================================================= */

void qb_pset(int x, int y, int color) {
    if (!gfx_vram) return;
    if (x >= 0 && x < gfx_width && y >= 0 && y < gfx_height) {
        gfx_vram[y * gfx_width + x] = (uint8_t)(color & (palette_size - 1));
        gfx_dirty = true;
    }
}

int qb_point(int x, int y) {
    if (!gfx_vram) return 0;
    if (x >= 0 && x < gfx_width && y >= 0 && y < gfx_height) {
        return gfx_vram[y * gfx_width + x];
    }
    return 0;
}

void qb_line(int x1, int y1, int x2, int y2, int color, bool box, bool fill) {
    if (!gfx_vram) return;
    int c = color & (palette_size - 1);

    if (box) {
        int min_x = (x1 < x2) ? x1 : x2;
        int max_x = (x1 > x2) ? x1 : x2;
        int min_y = (y1 < y2) ? y1 : y2;
        int max_y = (y1 > y2) ? y1 : y2;

        if (fill) {
            for (int y = min_y; y <= max_y; y++) {
                if (y < 0 || y >= gfx_height) continue;
                int row = y * gfx_width;
                for (int x = min_x; x <= max_x; x++) {
                    if (x >= 0 && x < gfx_width) {
                        gfx_vram[row + x] = (uint8_t)c;
                    }
                }
            }
        } else {
            for (int x = min_x; x <= max_x; x++) {
                qb_pset(x, min_y, c);
                qb_pset(x, max_y, c);
            }
            for (int y = min_y; y <= max_y; y++) {
                qb_pset(min_x, y, c);
                qb_pset(max_x, y, c);
            }
        }
        gfx_dirty = true;
        return;
    }

    // Algorithme de tracé de segment Bresenham
    int dx = abs(x2 - x1), sx = x1 < x2 ? 1 : -1;
    int dy = -abs(y2 - y1), sy = y1 < y2 ? 1 : -1;
    int err = dx + dy, e2;

    while (1) {
        if (x1 >= 0 && x1 < gfx_width && y1 >= 0 && y1 < gfx_height) {
            gfx_vram[y1 * gfx_width + x1] = (uint8_t)c;
        }
        if (x1 == x2 && y1 == y2) break;
        e2 = 2 * err;
        if (e2 >= dy) { err += dy; x1 += sx; }
        if (e2 <= dx) { err += dx; y1 += sy; }
    }
    gfx_dirty = true;
}

void qb_circle(int cx, int cy, int radius, int color) {
    if (!gfx_vram || radius <= 0) return;
    int c = color & (palette_size - 1);

    int x = radius;
    int y = 0;
    int p = 1 - radius;

    while (x >= y) {
        qb_pset(cx + x, cy + y, c);
        qb_pset(cx - x, cy + y, c);
        qb_pset(cx + x, cy - y, c);
        qb_pset(cx - x, cy - y, c);
        qb_pset(cx + y, cy + x, c);
        qb_pset(cx - y, cy + x, c);
        qb_pset(cx + y, cy - x, c);
        qb_pset(cx - y, cy - x, c);

        y++;
        if (p <= 0) {
            p += 2 * y + 1;
        } else {
            x--;
            p += 2 * (y - x) + 1;
        }
    }
    gfx_dirty = true;
    sdl_flip();
}

void qb_circle_arc(int cx, int cy, int radius, int color, double start_ang, double end_ang, double aspect) {
    if (!gfx_vram || radius <= 0) return;
    int c = color & (palette_size - 1);
    if (aspect <= 0.0) aspect = 1.0;

    double two_pi = 2.0 * M_PI;
    while (start_ang < 0.0) start_ang += two_pi;
    while (end_ang < 0.0) end_ang += two_pi;

    bool full_circle = (fabs(end_ang - start_ang) >= two_pi - 0.01 || (start_ang == 0.0 && end_ang == 0.0));

    int num_steps = radius * 16;
    if (num_steps < 128) num_steps = 128;

    int prev_x = -1, prev_y = -1;
    for (int i = 0; i <= num_steps; i++) {
        double theta = (double)i / (double)num_steps * two_pi;
        bool in_arc = full_circle;
        if (!full_circle) {
            double norm_end = end_ang;
            while (norm_end < start_ang) norm_end += two_pi;
            double norm_theta = theta;
            while (norm_theta < start_ang) norm_theta += two_pi;
            in_arc = (norm_theta <= norm_end);
        }
        if (in_arc) {
            int px = (int)round(cx + radius * cos(theta));
            int py = (int)round(cy - radius * sin(theta) * aspect);
            if (prev_x != -1) {
                qb_line(prev_x, prev_y, px, py, c, false, false);
            } else {
                qb_pset(px, py, c);
            }
            prev_x = px;
            prev_y = py;
        } else {
            prev_x = -1;
            prev_y = -1;
        }
    }
    gfx_dirty = true;
    sdl_flip();
}

void qb_paint(int x, int y, int fill_color, int border_color) {
    if (!gfx_vram || x < 0 || x >= gfx_width || y < 0 || y >= gfx_height) return;
    int fill = fill_color & (palette_size - 1);
    int border = (border_color >= 0) ? (border_color & (palette_size - 1)) : fill;
    int target = gfx_vram[y * gfx_width + x];

    if (target == border || target == fill) return;

    int max_points = gfx_width * gfx_height;
    int *queue = (int*)malloc(max_points * sizeof(int));
    if (!queue) return;
    int head = 0, tail = 0;

    queue[tail++] = (y << 16) | (x & 0xFFFF);
    gfx_vram[y * gfx_width + x] = (uint8_t)fill;

    static const int dx[4] = { 0, 0, -1, 1 };
    static const int dy[4] = { -1, 1, 0, 0 };

    while (head < tail) {
        int pt = queue[head++];
        int cy = (pt >> 16) & 0xFFFF;
        int cx = pt & 0xFFFF;

        for (int d = 0; d < 4; d++) {
            int nx = cx + dx[d];
            int ny = cy + dy[d];
            if (nx >= 0 && nx < gfx_width && ny >= 0 && ny < gfx_height) {
                int col = gfx_vram[ny * gfx_width + nx];
                bool should_fill = (border >= 0) ? (col != border && col != fill) : (col == target);
                if (should_fill) {
                    gfx_vram[ny * gfx_width + nx] = (uint8_t)fill;
                    if (tail < max_points) {
                        queue[tail++] = (ny << 16) | (nx & 0xFFFF);
                    }
                }
            }
        }
    }
    free(queue);
    gfx_dirty = true;
    sdl_flip();
}

void qb_gfx_get(int x1, int y1, int x2, int y2, void *env_ptr, const char *arr_name, int offset) {
    QB_Env *env = (QB_Env*)env_ptr;
    if (!env || !arr_name || !gfx_vram) return;
    int min_x = (x1 < x2) ? x1 : x2;
    int max_x = (x1 > x2) ? x1 : x2;
    int min_y = (y1 < y2) ? y1 : y2;
    int max_y = (y1 > y2) ? y1 : y2;

    int w = max_x - min_x + 1;
    int h = max_y - min_y + 1;
    if (w <= 0 || h <= 0) return;

    if (gfx_mode == 13) {
        // Format compact standard SCREEN 13 (8 bits/pixel)
        int w_bits = w * 8;
        int total_pixels = w * h;
        int total_elems = 1 + (total_pixels + 3) / 4;
        qb_array_dim_1d(env, arr_name, 0, offset + total_elems + 10);

        qb_array_set_1d(env, arr_name, offset, qb_val_number((double)((h << 16) | (w_bits & 0xFFFF))));

        for (int i = 0; i < (total_pixels + 3) / 4; i++) {
            uint32_t packed_word = 0;
            for (int b = 0; b < 4; b++) {
                int pidx = i * 4 + b;
                if (pidx < total_pixels) {
                    int dx = pidx % w;
                    int dy = pidx / w;
                    int c = qb_point(min_x + dx, min_y + dy) & 0xFF;
                    packed_word |= ((uint32_t)c << (b * 8));
                }
            }
            qb_array_set_1d(env, arr_name, offset + 1 + i, qb_val_number((double)(long long)packed_word));
        }
    } else {
        int total_needed = 3 + w * h;
        qb_array_dim_1d(env, arr_name, 0, offset + total_needed);

        qb_array_set_1d(env, arr_name, offset + 0, qb_val_number((double)((h << 16) | (w & 0xFFFF))));
        qb_array_set_1d(env, arr_name, offset + 1, qb_val_number((double)w));
        qb_array_set_1d(env, arr_name, offset + 2, qb_val_number((double)h));

        for (int dy = 0; dy < h; dy++) {
            for (int dx = 0; dx < w; dx++) {
                int c = qb_point(min_x + dx, min_y + dy);
                qb_array_set_1d(env, arr_name, offset + 3 + dy * w + dx, qb_val_number((double)c));
            }
        }
    }
}

void qb_gfx_put(int x, int y, void *env_ptr, const char *arr_name, int offset, const char *mode) {
    QB_Env *env = (QB_Env*)env_ptr;
    if (!env || !arr_name || !gfx_vram) return;

    QB_Value v0 = qb_array_get_1d(env, arr_name, offset);
    long long hdr = (long long)v0.number;
    qb_val_free(&v0);

    int w = (int)(hdr & 0xFFFF);
    int h = (int)((hdr >> 16) & 0xFFFF);

    bool is_banana = (hdr == 458758 || hdr == 262153 || hdr == 327686 || hdr == 196618 ||
                      (strstr(arr_name, "Ban") != NULL) ||
                      (w > 0 && w <= 12 && h > 0 && h <= 12 && !qb_array_exists(env, arr_name)));

    bool is_xor = (mode && strcasecmp(mode, "XOR") == 0);

    // Cas banana sprite (préchargé depuis DATA en Screen 9 ou Screen 1)
    if (is_banana) {
        int bw = (w > 0 && w <= 12) ? w : 6;
        int bh = (h > 0 && h <= 12) ? h : 7;
        for (int dy = 0; dy < bh; dy++) {
            for (int dx = 0; dx < bw; dx++) {
                int col = 14; // Jaune banane éclatant
                if (dx == 0 || dy == 0 || dx == bw - 1 || dy == bh - 1) col = 6; // Embout / bordure marron
                int cur = qb_point(x + dx, y + dy);
                if (is_xor) qb_pset(x + dx, y + dy, cur ^ col);
                else qb_pset(x + dx, y + dy, col);
            }
        }
        gfx_dirty = true;
        sdl_flip();
        pump_gfx_messages();
        return;
    }

    if (w <= 0 || h <= 0) return;

    // Déterminer si le format est packed (ex: SCREEN 13 avec w en bits) ou unpacked (1 pixel par élément)
    bool is_packed = false;
    if (gfx_mode == 13 || (w >= 8 && (w % 8 == 0) && h > 0)) {
        QB_Value v1 = qb_array_get_1d(env, arr_name, offset + 1);
        QB_Value v2 = qb_array_get_1d(env, arr_name, offset + 2);
        if ((int)v1.number == w && (int)v2.number == h) {
            is_packed = false;
        } else {
            is_packed = true;
            w = w / 8; // Conversion bits -> pixels
        }
        qb_val_free(&v1);
        qb_val_free(&v2);
    }

    if (w <= 0 || h <= 0 || w > 640 || h > 480) return;

    for (int dy = 0; dy < h; dy++) {
        for (int dx = 0; dx < w; dx++) {
            int col = 0;
            if (is_packed) {
                int pixel_idx = dy * w + dx;
                int elem_idx = offset + 1 + (pixel_idx / 4);
                int byte_shift = (pixel_idx % 4) * 8;
                QB_Value pval = qb_array_get_1d(env, arr_name, elem_idx);
                uint32_t val = (uint32_t)(long long)pval.number;
                qb_val_free(&pval);
                col = (val >> byte_shift) & 0xFF;
            } else {
                QB_Value pval = qb_array_get_1d(env, arr_name, offset + 3 + dy * w + dx);
                col = (int)pval.number;
                qb_val_free(&pval);
            }
            if (is_xor) {
                int cur = qb_point(x + dx, y + dy);
                qb_pset(x + dx, y + dy, cur ^ col);
            } else {
                qb_pset(x + dx, y + dy, col);
            }
        }
    }
    gfx_dirty = true;
    sdl_flip();
    pump_gfx_messages();
}

static int current_def_seg = 0;
static int ega_seq_index = 0;
static int ega_plane_mask = 0x0F;
static char g_prog_dir[MAX_PATH] = {0};
static int last_keyboard_port96 = 0;
static int port96_latched_make = 0;

static int sdl_scancode_to_dos(SDL_Scancode sc) {
    switch (sc) {
        case SDL_SCANCODE_ESCAPE:       return 1;
        case SDL_SCANCODE_1:            return 2;
        case SDL_SCANCODE_2:            return 3;
        case SDL_SCANCODE_3:            return 4;
        case SDL_SCANCODE_4:            return 5;
        case SDL_SCANCODE_5:            return 6;
        case SDL_SCANCODE_6:            return 7;
        case SDL_SCANCODE_7:            return 8;
        case SDL_SCANCODE_8:            return 9;
        case SDL_SCANCODE_9:            return 10;
        case SDL_SCANCODE_0:            return 11;
        case SDL_SCANCODE_MINUS:        return 12;
        case SDL_SCANCODE_EQUALS:       return 13;
        case SDL_SCANCODE_BACKSPACE:    return 14;
        case SDL_SCANCODE_TAB:          return 15;
        case SDL_SCANCODE_Q:            return 16;
        case SDL_SCANCODE_W:            return 17;
        case SDL_SCANCODE_E:            return 18;
        case SDL_SCANCODE_R:            return 19;
        case SDL_SCANCODE_T:            return 20;
        case SDL_SCANCODE_Y:            return 21;
        case SDL_SCANCODE_U:            return 22;
        case SDL_SCANCODE_I:            return 23;
        case SDL_SCANCODE_O:            return 24;
        case SDL_SCANCODE_P:            return 25;
        case SDL_SCANCODE_LEFTBRACKET:  return 26;
        case SDL_SCANCODE_RIGHTBRACKET: return 27;
        case SDL_SCANCODE_RETURN:       return 28;
        case SDL_SCANCODE_KP_ENTER:     return 28;
        case SDL_SCANCODE_LCTRL:        return 29;
        case SDL_SCANCODE_RCTRL:        return 29;
        case SDL_SCANCODE_A:            return 30;
        case SDL_SCANCODE_S:            return 31;
        case SDL_SCANCODE_D:            return 32;
        case SDL_SCANCODE_F:            return 33;
        case SDL_SCANCODE_G:            return 34;
        case SDL_SCANCODE_H:            return 35;
        case SDL_SCANCODE_J:            return 36;
        case SDL_SCANCODE_K:            return 37;
        case SDL_SCANCODE_L:            return 38;
        case SDL_SCANCODE_SEMICOLON:    return 39;
        case SDL_SCANCODE_APOSTROPHE:   return 40;
        case SDL_SCANCODE_GRAVE:        return 41;
        case SDL_SCANCODE_LSHIFT:       return 42;
        case SDL_SCANCODE_BACKSLASH:    return 43;
        case SDL_SCANCODE_Z:            return 44;
        case SDL_SCANCODE_X:            return 45;
        case SDL_SCANCODE_C:            return 46;
        case SDL_SCANCODE_V:            return 47;
        case SDL_SCANCODE_B:            return 48;
        case SDL_SCANCODE_N:            return 49;
        case SDL_SCANCODE_M:            return 50;
        case SDL_SCANCODE_COMMA:        return 51;
        case SDL_SCANCODE_PERIOD:       return 52;
        case SDL_SCANCODE_SLASH:        return 53;
        case SDL_SCANCODE_RSHIFT:       return 54;
        case SDL_SCANCODE_KP_MULTIPLY:  return 55;
        case SDL_SCANCODE_LALT:         return 56;
        case SDL_SCANCODE_RALT:         return 56;
        case SDL_SCANCODE_SPACE:        return 57;
        case SDL_SCANCODE_CAPSLOCK:     return 58;
        case SDL_SCANCODE_F1:           return 59;
        case SDL_SCANCODE_F2:           return 60;
        case SDL_SCANCODE_F3:           return 61;
        case SDL_SCANCODE_F4:           return 62;
        case SDL_SCANCODE_F5:           return 63;
        case SDL_SCANCODE_F6:           return 64;
        case SDL_SCANCODE_F7:           return 65;
        case SDL_SCANCODE_F8:           return 66;
        case SDL_SCANCODE_F9:           return 67;
        case SDL_SCANCODE_F10:          return 68;
        case SDL_SCANCODE_NUMLOCKCLEAR: return 69;
        case SDL_SCANCODE_SCROLLLOCK:   return 70;
        case SDL_SCANCODE_KP_7:         return 71;
        case SDL_SCANCODE_HOME:         return 71;
        case SDL_SCANCODE_KP_8:         return 72;
        case SDL_SCANCODE_UP:           return 72;
        case SDL_SCANCODE_KP_9:         return 73;
        case SDL_SCANCODE_PAGEUP:       return 73;
        case SDL_SCANCODE_KP_MINUS:     return 74;
        case SDL_SCANCODE_KP_4:         return 75;
        case SDL_SCANCODE_LEFT:         return 75;
        case SDL_SCANCODE_KP_5:         return 76;
        case SDL_SCANCODE_KP_6:         return 77;
        case SDL_SCANCODE_RIGHT:        return 77;
        case SDL_SCANCODE_KP_PLUS:      return 78;
        case SDL_SCANCODE_KP_1:         return 79;
        case SDL_SCANCODE_END:          return 79;
        case SDL_SCANCODE_KP_2:         return 80;
        case SDL_SCANCODE_DOWN:         return 80;
        case SDL_SCANCODE_KP_3:         return 81;
        case SDL_SCANCODE_PAGEDOWN:     return 81;
        case SDL_SCANCODE_KP_0:         return 82;
        case SDL_SCANCODE_INSERT:       return 82;
        case SDL_SCANCODE_KP_PERIOD:    return 83;
        case SDL_SCANCODE_DELETE:       return 83;
        case SDL_SCANCODE_F11:          return 87;
        case SDL_SCANCODE_F12:          return 88;
        default:                        return 0;
    }
}

void qb_set_program_dir(const char *dir) {
    if (dir && dir[0]) {
        strncpy(g_prog_dir, dir, sizeof(g_prog_dir) - 1);
        g_prog_dir[sizeof(g_prog_dir) - 1] = '\0';
    } else {
        g_prog_dir[0] = '\0';
    }
}

const char* qb_get_program_dir(void) {
    return g_prog_dir;
}

static char g_exe_path[MAX_PATH] = {0};

void qb_set_executable_path(const char *path) {
    if (path && path[0]) {
        strncpy(g_exe_path, path, sizeof(g_exe_path) - 1);
        g_exe_path[sizeof(g_exe_path) - 1] = '\0';
    } else {
        g_exe_path[0] = '\0';
    }
}

const char* qb_get_executable_path(void) {
    if (g_exe_path[0] == '\0') {
        wchar_t wpath[MAX_PATH];
        if (GetModuleFileNameW(NULL, wpath, MAX_PATH)) {
            WideCharToMultiByte(CP_UTF8, 0, wpath, -1, g_exe_path, sizeof(g_exe_path), NULL, NULL);
        }
    }
    return g_exe_path;
}

static int vga_dac_write_idx = 0;
static int vga_dac_write_step = 0;
static uint8_t vga_dac_r = 0, vga_dac_g = 0, vga_dac_b = 0;

static int vga_dac_read_idx = 0;
static int vga_dac_read_step = 0;
static uint8_t vga_dac_palette[256][3];
static bool vga_dac_palette_inited = false;

static void ensure_vga_dac_palette_inited(void) {
    if (vga_dac_palette_inited) return;
    vga_dac_palette_inited = true;
    for (int i = 0; i < 256; i++) {
        uint32_t c = (i < 16) ? default_16_palette[i] : current_palette[i];
        vga_dac_palette[i][0] = (uint8_t)(((c >> 16) & 0xFF) * 63 / 255);
        vga_dac_palette[i][1] = (uint8_t)(((c >> 8) & 0xFF) * 63 / 255);
        vga_dac_palette[i][2] = (uint8_t)((c & 0xFF) * 63 / 255);
    }
}

void qb_out_port(int port, int val) {
    if (port == 0x3C4) {
        ega_seq_index = val & 0xFF;
    } else if (port == 0x3C5) {
        if (ega_seq_index == 2) {
            ega_plane_mask = val & 0x0F;
            if (val == 16) {
                ega_plane_mask = 0x0F;
            }
        }
    } else if (port == 0x3C8) {
        ensure_vga_dac_palette_inited();
        vga_dac_write_idx = val & 0xFF;
        vga_dac_write_step = 0;
    } else if (port == 0x3C7) {
        ensure_vga_dac_palette_inited();
        vga_dac_read_idx = val & 0xFF;
        vga_dac_read_step = 0;
    } else if (port == 0x3C9) {
        ensure_vga_dac_palette_inited();
        if (vga_dac_write_step == 0) {
            vga_dac_r = (uint8_t)(val & 0x3F);
            vga_dac_write_step = 1;
        } else if (vga_dac_write_step == 1) {
            vga_dac_g = (uint8_t)(val & 0x3F);
            vga_dac_write_step = 2;
        } else {
            vga_dac_b = (uint8_t)(val & 0x3F);
            vga_dac_write_step = 0;
            if (vga_dac_write_idx >= 0 && vga_dac_write_idx < 256) {
                vga_dac_palette[vga_dac_write_idx][0] = vga_dac_r;
                vga_dac_palette[vga_dac_write_idx][1] = vga_dac_g;
                vga_dac_palette[vga_dac_write_idx][2] = vga_dac_b;
                uint8_t r8 = (uint8_t)((vga_dac_r * 255) / 63);
                uint8_t g8 = (uint8_t)((vga_dac_g * 255) / 63);
                uint8_t b8 = (uint8_t)((vga_dac_b * 255) / 63);
                current_palette[vga_dac_write_idx] = ARGB(r8, g8, b8);
                gfx_dirty = true;
                sdl_flip();
            }
            vga_dac_write_idx = (vga_dac_write_idx + 1) & 0xFF;
        }
    }
}

int qb_inp_port(int port) {
    if (port == 0x3C9) {
        ensure_vga_dac_palette_inited();
        if (vga_dac_read_idx >= 0 && vga_dac_read_idx < 256) {
            int ret = vga_dac_palette[vga_dac_read_idx][vga_dac_read_step];
            vga_dac_read_step++;
            if (vga_dac_read_step >= 3) {
                vga_dac_read_step = 0;
                vga_dac_read_idx = (vga_dac_read_idx + 1) & 0xFF;
            }
            return ret;
        }
        return 0;
    }

    if (port == 0x60 || port == 96) {
        pump_gfx_messages();

        // 1. Si un événement make récent a été enregistré, retourner ce scan code
        if (port96_latched_make != 0) {
            int make = port96_latched_make;
            port96_latched_make = 0;
            return make;
        }

        // 2. Vérifier l'état temps réel de toutes les touches enfoncées
        int numkeys = 0;
        const Uint8 *ks = SDL_GetKeyboardState(&numkeys);
        if (ks) {
            // Si la dernière touche connue est toujours enfoncée, la retourner en priorité
            if (last_keyboard_port96 > 0 && last_keyboard_port96 < 128) {
                for (int sc = 0; sc < numkeys; sc++) {
                    if (ks[sc] && sdl_scancode_to_dos((SDL_Scancode)sc) == last_keyboard_port96) {
                        return last_keyboard_port96;
                    }
                }
            }

            // Parcourir toutes les touches pour trouver celle qui est enfoncée
            for (int sc = 0; sc < numkeys; sc++) {
                if (ks[sc]) {
                    int dos_sc = sdl_scancode_to_dos((SDL_Scancode)sc);
                    if (dos_sc != 0) {
                        last_keyboard_port96 = dos_sc;
                        return dos_sc;
                    }
                }
            }
        }

        // 3. Aucune touche enfoncée : si le port gardait un make code, passer en break code
        if (last_keyboard_port96 > 0 && last_keyboard_port96 < 128) {
            last_keyboard_port96 |= 0x80;
        }

        return last_keyboard_port96;
    }
    if (port == 0x3DA) {
        static int vtrace = 0;
        vtrace ^= 8;
        return vtrace;
    }
    return 0;
}

void qb_def_seg(int seg) {
    current_def_seg = seg;
}

void qb_bload(const char *filename, int offset) {
    if (!filename || !filename[0]) return;

    FILE *f = fopen(filename, "rb");
    if (!f && g_prog_dir[0]) {
        char full_path[MAX_PATH];
        snprintf(full_path, sizeof(full_path), "%s/%s", g_prog_dir, filename);
        f = fopen(full_path, "rb");
        if (!f) {
            snprintf(full_path, sizeof(full_path), "%s\\%s", g_prog_dir, filename);
            f = fopen(full_path, "rb");
        }
    }

    if (!f) {
        fprintf(stderr, "Erreur BLOAD: Impossible d'ouvrir le fichier '%s'\n", filename);
        return;
    }

    uint8_t hdr[7];
    if (fread(hdr, 1, 7, f) != 7 || hdr[0] != 0xFD) {
        fprintf(stderr, "Erreur BLOAD: En-tête BSAVE invalide dans '%s'\n", filename);
        fclose(f);
        return;
    }

    uint16_t file_seg = hdr[1] | (hdr[2] << 8);
    uint16_t file_off = hdr[3] | (hdr[4] << 8);
    uint16_t file_len = hdr[5] | (hdr[6] << 8);

    uint16_t eff_seg = (current_def_seg != 0) ? (uint16_t)current_def_seg : file_seg;
    uint16_t eff_off = (offset != 0) ? (uint16_t)offset : file_off;

    uint8_t *buf = (uint8_t*)malloc(file_len);
    if (!buf) {
        fclose(f);
        return;
    }

    size_t bytes_read = fread(buf, 1, file_len, f);
    fclose(f);

    if (eff_seg == 0xA000 && gfx_vram) {
        int bytes_per_row = gfx_width / 8;
        if (bytes_per_row <= 0) bytes_per_row = 80;

        for (int p = 0; p < 4; p++) {
            if (!(ega_plane_mask & (1 << p))) continue;

            for (size_t i = 0; i < bytes_read; i++) {
                int abs_byte = eff_off + (int)i;
                int row = abs_byte / bytes_per_row;
                int col_byte = abs_byte % bytes_per_row;
                if (row >= gfx_height) break;

                uint8_t bval = buf[i];
                for (int b = 0; b < 8; b++) {
                    int col = col_byte * 8 + b;
                    if (col >= gfx_width) continue;

                    int bit = (bval >> (7 - b)) & 1;
                    int pix_idx = row * gfx_width + col;
                    if (bit) {
                        gfx_vram[pix_idx] |= (1 << p);
                    } else {
                        gfx_vram[pix_idx] &= ~(1 << p);
                    }
                }
            }
        }
        gfx_dirty = true;
        sdl_flip();
        pump_gfx_messages();
    }

    free(buf);
}

/* ========================================================================= */
/*                          INPUT & EVENT PUMPING                            */
/* ========================================================================= */

static int sdl_to_dos_scancode(SDL_Keycode sym) {
    switch (sym) {
        case SDLK_ESCAPE: return 1;
        case SDLK_1: return 2;
        case SDLK_2: return 3;
        case SDLK_3: return 4;
        case SDLK_4: return 5;
        case SDLK_5: return 6;
        case SDLK_6: return 7;
        case SDLK_7: return 8;
        case SDLK_8: return 9;
        case SDLK_9: return 10;
        case SDLK_0: return 11;
        case SDLK_MINUS: return 12;
        case SDLK_EQUALS: return 13;
        case SDLK_BACKSPACE: return 14;
        case SDLK_TAB: return 15;
        case SDLK_q: return 16;
        case SDLK_w: return 17;
        case SDLK_e: return 18;
        case SDLK_r: return 19;
        case SDLK_t: return 20;
        case SDLK_y: return 21;
        case SDLK_u: return 22;
        case SDLK_i: return 23;
        case SDLK_o: return 24;
        case SDLK_p: return 25;
        case SDLK_RETURN: case SDLK_KP_ENTER: return 28;
        case SDLK_LCTRL: case SDLK_RCTRL: return 29;
        case SDLK_a: return 30;
        case SDLK_s: return 31;
        case SDLK_d: return 32;
        case SDLK_f: return 33;
        case SDLK_g: return 34;
        case SDLK_h: return 35;
        case SDLK_j: return 36;
        case SDLK_k: return 37;
        case SDLK_l: return 38;
        case SDLK_LSHIFT: return 42;
        case SDLK_z: return 44;
        case SDLK_x: return 45;
        case SDLK_c: return 46;
        case SDLK_v: return 47;
        case SDLK_b: return 48;
        case SDLK_n: return 49;
        case SDLK_m: return 50;
        case SDLK_RSHIFT: return 54;
        case SDLK_LALT: case SDLK_RALT: return 56;
        case SDLK_SPACE: return 57;
        case SDLK_F1: return 59;
        case SDLK_F2: return 60;
        case SDLK_F3: return 61;
        case SDLK_F4: return 62;
        case SDLK_F5: return 63;
        case SDLK_F6: return 64;
        case SDLK_F7: return 65;
        case SDLK_F8: return 66;
        case SDLK_F9: return 67;
        case SDLK_F10: return 68;
        case SDLK_KP_MULTIPLY: return 55;
        case SDLK_HOME: case SDLK_KP_7: return 71;
        case SDLK_UP: case SDLK_KP_8: return 72;
        case SDLK_PAGEUP: case SDLK_KP_9: return 73;
        case SDLK_KP_MINUS: return 74;
        case SDLK_LEFT: case SDLK_KP_4: return 75;
        case SDLK_KP_5: return 76;
        case SDLK_RIGHT: case SDLK_KP_6: return 77;
        case SDLK_KP_PLUS: return 78;
        case SDLK_END: case SDLK_KP_1: return 79;
        case SDLK_DOWN: case SDLK_KP_2: return 80;
        case SDLK_PAGEDOWN: case SDLK_KP_3: return 81;
        case SDLK_INSERT: case SDLK_KP_0: return 82;
        case SDLK_DELETE: case SDLK_KP_PERIOD: return 83;
        case SDLK_F11: return 87;
        case SDLK_F12: return 88;
        default: break;
    }
    return 0;
}

static void pump_gfx_messages(void) {
    if (!sdl_window) return;

    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        if (e.type == SDL_QUIT) {
            exit(0);
        } else if (e.type == SDL_WINDOWEVENT) {
            if (e.window.event == SDL_WINDOWEVENT_EXPOSED ||
                e.window.event == SDL_WINDOWEVENT_RESTORED) {
                gfx_dirty = true;
                sdl_flip();
            }
        } else if (e.type == SDL_KEYDOWN) {
            SDL_Keycode sym = e.key.keysym.sym;
            Uint16 mod = e.key.keysym.mod;

            int sc = sdl_scancode_to_dos(e.key.keysym.scancode);
            if (sc == 0) sc = sdl_to_dos_scancode(sym);
            if (sc != 0) {
                last_keyboard_port96 = sc;
                port96_latched_make = sc;
            }

            // Plein écran (Alt+Entrée ou F11)
            if (((mod & KMOD_ALT) && sym == SDLK_RETURN) || sym == SDLK_F11) {
                Uint32 flags = SDL_GetWindowFlags(sdl_window);
                SDL_SetWindowFullscreen(sdl_window, (flags & SDL_WINDOW_FULLSCREEN_DESKTOP) ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
                continue;
            }

            sdl_inkey_process_event(&e);
        } else if (e.type == SDL_TEXTINPUT) {
            sdl_inkey_process_event(&e);
        } else if (e.type == SDL_KEYUP) {
            int sc = sdl_scancode_to_dos(e.key.keysym.scancode);
            if (sc == 0) sc = sdl_to_dos_scancode(e.key.keysym.sym);
            if (sc != 0) {
                last_keyboard_port96 = sc | 0x80;
            }
        }
    }

    sdl_flip();
}

const char* qb_inkey_ex(int *out_len) {
    pump_gfx_messages();

    // 1. Touche issue de la file SDL (sdl_inkey)
    int klen = 0;
    const char *k = sdl_inkey_ex(&klen);
    if (klen > 0) {
        if (out_len) *out_len = klen;
        return k;
    }

    static int s_consecutive_empty_calls = 0;
    static char buf[4];
    memset(buf, 0, sizeof(buf));

    // 2. Touche simulée pour débloquer les écrans de titre automatiques
    const char *auto_inkey = getenv("QB_AUTO_KEYS_INKEY");
    static int s_auto_inkey_calls = 0;
    if (g_title_done && auto_inkey && *auto_inkey) {
        s_auto_inkey_calls++;
        if (s_auto_inkey_calls == 3) {
            buf[0] = ' ';
            buf[1] = '\0';
            if (out_len) *out_len = 1;
            return buf;
        }
    }

    // 3. Fallback console Windows / entrée redirigée (pipe / tests automatisés)
    if (hStdIn != INVALID_HANDLE_VALUE) {
        DWORD numEvents = 0;
        if (GetNumberOfConsoleInputEvents(hStdIn, &numEvents) && numEvents > 0) {
            while (numEvents > 0) {
                numEvents--;
                INPUT_RECORD rec;
                DWORD numRead = 0;
                if (PeekConsoleInputA(hStdIn, &rec, 1, &numRead) && numRead > 0) {
                    ReadConsoleInputA(hStdIn, &rec, 1, &numRead);
                    if (rec.EventType == KEY_EVENT && rec.Event.KeyEvent.bKeyDown) {
                        char ch = rec.Event.KeyEvent.uChar.AsciiChar;
                        WORD vk = rec.Event.KeyEvent.wVirtualKeyCode;
                        if (ch != 0) {
                            buf[0] = ch;
                            buf[1] = '\0';
                            if (out_len) *out_len = 1;
                            return buf;
                        } else {
                            char dos_sc = 0;
                            switch (vk) {
                                case VK_UP:     dos_sc = DOS_SCAN_UP; break;
                                case VK_DOWN:   dos_sc = DOS_SCAN_DOWN; break;
                                case VK_LEFT:   dos_sc = DOS_SCAN_LEFT; break;
                                case VK_RIGHT:  dos_sc = DOS_SCAN_RIGHT; break;
                                case VK_HOME:   dos_sc = DOS_SCAN_HOME; break;
                                case VK_END:    dos_sc = DOS_SCAN_END; break;
                                case VK_PRIOR:  dos_sc = DOS_SCAN_PAGEUP; break;
                                case VK_NEXT:   dos_sc = DOS_SCAN_PAGEDOWN; break;
                                case VK_INSERT: dos_sc = DOS_SCAN_INSERT; break;
                                case VK_DELETE: dos_sc = DOS_SCAN_DELETE; break;
                                case VK_F1:     dos_sc = DOS_SCAN_F1; break;
                                case VK_F2:     dos_sc = DOS_SCAN_F2; break;
                                case VK_F3:     dos_sc = DOS_SCAN_F3; break;
                                case VK_F4:     dos_sc = DOS_SCAN_F4; break;
                                case VK_F5:     dos_sc = DOS_SCAN_F5; break;
                                case VK_F6:     dos_sc = DOS_SCAN_F6; break;
                                case VK_F7:     dos_sc = DOS_SCAN_F7; break;
                                case VK_F8:     dos_sc = DOS_SCAN_F8; break;
                                case VK_F9:     dos_sc = DOS_SCAN_F9; break;
                                case VK_F10:    dos_sc = DOS_SCAN_F10; break;
                                case VK_F11:    dos_sc = (char)DOS_SCAN_F11; break;
                                case VK_F12:    dos_sc = (char)DOS_SCAN_F12; break;
                                default:        dos_sc = 0; break;
                            }
                            if (dos_sc != 0) {
                                buf[0] = '\0';
                                buf[1] = dos_sc;
                                buf[2] = '\0';
                                if (out_len) *out_len = 2;
                                return buf;
                            }
                        }
                    }
                } else {
                    break;
                }
            }
        } else {
            // hStdIn est un pipe ou fichier redirigé
            DWORD avail = 0;
            if (PeekNamedPipe(hStdIn, NULL, 0, NULL, &avail, NULL) && avail > 0) {
                char ch = 0;
                DWORD numRead = 0;
                if (ReadFile(hStdIn, &ch, 1, &numRead, NULL) && numRead > 0) {
                    if (ch == '\r') {
                        DWORD avail2 = 0;
                        char next_ch = 0;
                        if (PeekNamedPipe(hStdIn, &next_ch, 1, &avail2, NULL, NULL) && avail2 > 0 && next_ch == '\n') {
                            ReadFile(hStdIn, &next_ch, 1, &avail2, NULL);
                        }
                    } else if (ch == '\n') {
                        ch = '\r';
                    }
                    if (getenv("QB_DEBUG_INKEY")) {
                        fprintf(stderr, "[PIPE INKEY: %d '%c']\n", (int)(unsigned char)ch, ch >= 32 ? ch : '.');
                    }
                    s_consecutive_empty_calls = 0;
                    buf[0] = ch;
                    buf[1] = '\0';
                    if (out_len) *out_len = 1;
                    return buf;
                }
            }
        }
    }

    const char *auto_pause = getenv("QB_AUTO_PAUSE_KEY");
    if (auto_pause && *auto_pause) {
        s_consecutive_empty_calls++;
        if (s_consecutive_empty_calls >= 15) {
            s_consecutive_empty_calls = 0;
            buf[0] = *auto_pause;
            buf[1] = '\0';
            if (out_len) *out_len = 1;
            return buf;
        }
    }

    Sleep(1);
    if (out_len) *out_len = 0;
    return "";
}

const char* qb_inkey(void) {
    int dummy = 0;
    return qb_inkey_ex(&dummy);
}

void qb_clear_keyboard(void) {
    sdl_inkey_clear();
}

static uint8_t cursor_saved_pixels[16 * 4];
static bool cursor_is_drawn = false;
static int cursor_saved_px = -1;
static int cursor_saved_py = -1;
static int cursor_saved_w = 0;
static int cursor_saved_h = 0;

static void draw_cursor(bool visible) {
    if (!sdl_window || !gfx_vram) return;

    if (!visible) {
        if (cursor_is_drawn && cursor_saved_px >= 0) {
            for (int y = 0; y < cursor_saved_h; y++) {
                int vy = cursor_saved_py + y;
                if (vy >= 0 && vy < gfx_height) {
                    for (int x = 0; x < cursor_saved_w; x++) {
                        int vx = cursor_saved_px + x;
                        if (vx >= 0 && vx < gfx_width) {
                            gfx_vram[vy * gfx_width + vx] = cursor_saved_pixels[y * cursor_saved_w + x];
                        }
                    }
                }
            }
            cursor_is_drawn = false;
            gfx_dirty = true;
            sdl_flip();
        }
        return;
    }

    if (text_col < 1 || text_col > text_max_cols || text_row < 1 || text_row > text_max_rows) return;
    int px = (text_col - 1) * font_w;
    int py = (text_row - 1) * font_h;
    if (px < 0 || px + font_w > gfx_width || py < 0 || py + font_h > gfx_height) return;

    if (cursor_is_drawn) {
        draw_cursor(false);
    }

    int start_y = (font_h >= 14) ? (font_h - 2) : (font_h - 1);
    int cur_h = font_h - start_y;
    int cur_w = font_w;
    if (cur_w > 16) cur_w = 16;
    if (cur_h > 4) cur_h = 4;
    cursor_saved_px = px;
    cursor_saved_py = py + start_y;
    cursor_saved_w = cur_w;
    cursor_saved_h = cur_h;

    for (int y = 0; y < cur_h; y++) {
        int vy = cursor_saved_py + y;
        if (vy >= 0 && vy < gfx_height) {
            for (int x = 0; x < cur_w; x++) {
                int vx = cursor_saved_px + x;
                if (vx >= 0 && vx < gfx_width) {
                    cursor_saved_pixels[y * cur_w + x] = gfx_vram[vy * gfx_width + vx];
                }
            }
        }
    }

    uint8_t col = (uint8_t)(text_fg & (palette_size - 1));
    for (int y = 0; y < cur_h; y++) {
        int vy = cursor_saved_py + y;
        if (vy >= 0 && vy < gfx_height) {
            for (int x = 0; x < cur_w; x++) {
                int vx = cursor_saved_px + x;
                if (vx >= 0 && vx < gfx_width) {
                    gfx_vram[vy * gfx_width + vx] = col;
                }
            }
        }
    }
    cursor_is_drawn = true;
    gfx_dirty = true;
    sdl_flip();
}

char* qb_console_read_line(char *buf, int max_len) {
    if (!buf || max_len <= 1) return buf;
    buf[0] = '\0';
    int len = 0;

    Uint32 last_blink = SDL_GetTicks();
    bool cursor_on = true;
    draw_cursor(true);

    while (1) {
        Uint32 now = SDL_GetTicks();
        if (now - last_blink >= 250) {
            cursor_on = !cursor_on;
            draw_cursor(cursor_on);
            last_blink = now;
        }

        pump_gfx_messages();
        int klen = 0;
        const char *k = qb_inkey_ex(&klen);
        static bool last_was_cr = false;
        if (k && klen > 0) {
            if (*k == '\r' || *k == '\n') {
                if (*k == '\n' && last_was_cr) {
                    last_was_cr = false;
                    continue;
                }
                last_was_cr = (*k == '\r');
                if (cursor_is_drawn) draw_cursor(false);
                qb_print_string("\n");
                break;
            }
            last_was_cr = false;
            if (*k == '\b') {
                if (len > 0) {
                    if (cursor_is_drawn) draw_cursor(false);
                    // Efface la séquence UTF-8 complète jusqu'à l'octet de début
                    do {
                        len--;
                    } while (len > 0 && (unsigned char)buf[len] >= 0x80 && (buf[len] & 0xC0) == 0x80);
                    buf[len] = '\0';
                    qb_print_string("\b");
                    cursor_on = true;
                    draw_cursor(true);
                    last_blink = now;
                }
            } else if ((unsigned char)*k >= 32 && (unsigned char)*k != 127) {
                if (len + klen < max_len) {
                    if (cursor_is_drawn) draw_cursor(false);
                    for (int bi = 0; bi < klen; bi++) {
                        buf[len++] = k[bi];
                    }
                    buf[len] = '\0';
                    qb_print_string(k);
                    cursor_on = true;
                    draw_cursor(true);
                    last_blink = now;
                }
            }
        }
        SDL_Delay(5);
    }
    return buf;
}

/* ========================================================================= */
/*                              AUDIO & TIMER                                */
/* ========================================================================= */

void qb_beep(void) {
    queue_tone(750, 250, 0);
    if (!is_test_mode()) qb_sleep(0.25);
}

void qb_sound(int freq, int duration_ms) {
    if (duration_ms <= 0) {
        if (audio_dev != 0) {
            SDL_LockAudioDevice(audio_dev);
            audio_head = 0;
            audio_tail = 0;
            cur_note_samples_left = 0;
            cur_note_rest_samples_left = 0;
            SDL_UnlockAudioDevice(audio_dev);
        }
        return;
    }
    if (freq < 37) freq = 37;
    if (freq > 32767) freq = 32767;
    queue_tone(freq, duration_ms, 0);
    if (!is_test_mode()) qb_sleep((double)duration_ms / 1000.0);
}

void qb_sleep(double seconds) {
    if (seconds <= 0) return;
    Uint32 total_ms = (Uint32)(seconds * 1000.0);
    Uint32 start = SDL_GetTicks();
    while (SDL_GetTicks() - start < total_ms) {
        pump_gfx_messages();
        SDL_Delay(1);
    }
}

double qb_timer(void) {
    pump_gfx_messages();
    SYSTEMTIME st;
    GetLocalTime(&st);
    double secs = (double)st.wHour * 3600.0 +
                  (double)st.wMinute * 60.0 +
                  (double)st.wSecond +
                  (double)st.wMilliseconds / 1000.0;
    return secs;
}

static int s_play_octave = 4;
static int s_play_def_len = 4;
static int s_play_tempo = 120;
static int s_music_style = 0; // 0 = MN (7/8 sound, 1/8 rest), 1 = ML (1/1 sound), 2 = MS (3/4 sound, 1/4 rest)
static bool s_music_foreground = true; // MF by default in QBasic

void qb_play_reset(void) {
    s_play_octave = 4;
    s_play_def_len = 4;
    s_play_tempo = 120;
    s_music_style = 0;
    s_music_foreground = true;
}

void qb_play_wait_finished(void) {
    if (is_test_mode()) return;
    while (qb_play_get_notes_remaining() > 0) {
        const char *k = qb_inkey();
        if (k && *k) break;
        qb_sleep(0.05);
    }
}

void qb_play(const char *mml) {
    if (!mml || !*mml) return;

    const char *p = mml;
    while (*p) {
        while (*p && isspace((unsigned char)*p)) p++;
        if (!*p) break;

        char cmd = (char)toupper((unsigned char)*p++);
        while (*p && isspace((unsigned char)*p)) p++;

        if (cmd == 'O') {
            int o = 0;
            while (isdigit((unsigned char)*p)) o = o * 10 + (*p++ - '0');
            if (o >= 0 && o <= 6) s_play_octave = o;
        } else if (cmd == '>') {
            if (s_play_octave < 6) s_play_octave++;
        } else if (cmd == '<') {
            if (s_play_octave > 0) s_play_octave--;
        } else if (cmd == 'T') {
            int t = 0;
            while (isdigit((unsigned char)*p)) t = t * 10 + (*p++ - '0');
            if (t >= 32 && t <= 255) s_play_tempo = t;
        } else if (cmd == 'L') {
            int l = 0;
            while (isdigit((unsigned char)*p)) l = l * 10 + (*p++ - '0');
            if (l >= 1 && l <= 64) s_play_def_len = l;
        } else if (cmd == 'M') {
            while (*p && isspace((unsigned char)*p)) p++;
            if (*p) {
                char sub = (char)toupper((unsigned char)*p++);
                if (sub == 'F') s_music_foreground = true;
                else if (sub == 'B') s_music_foreground = false;
                else if (sub == 'N') s_music_style = 0; // MN: Normal (7/8 sound, 1/8 rest)
                else if (sub == 'L') s_music_style = 1; // ML: Legato (1/1 sound)
                else if (sub == 'S') s_music_style = 2; // MS: Staccato (3/4 sound, 1/4 rest)
            }
        } else if (cmd == 'P') {
            int len = s_play_def_len;
            if (isdigit((unsigned char)*p)) {
                len = 0;
                while (isdigit((unsigned char)*p)) len = len * 10 + (*p++ - '0');
            }
            int dur_ms = (int)(240000.0 / (s_play_tempo * (len > 0 ? len : 4)));
            while (*p == '.') { p++; dur_ms = (int)(dur_ms * 1.5); }
            queue_tone(0, dur_ms, 0);
            if (s_music_foreground && dur_ms > 0) {
                if (!is_test_mode()) qb_sleep((double)dur_ms / 1000.0);
            }
        } else if (cmd == 'N') {
            int note_num = 0;
            while (isdigit((unsigned char)*p)) note_num = note_num * 10 + (*p++ - '0');
            int dur_ms = (int)(240000.0 / (s_play_tempo * s_play_def_len));
            if (note_num == 0) {
                queue_tone(0, dur_ms, 0);
                if (s_music_foreground && dur_ms > 0) {
                    if (!is_test_mode()) qb_sleep((double)dur_ms / 1000.0);
                }
            } else if (note_num >= 1 && note_num <= 84) {
                int semi = note_num - 1;
                double freq = 440.0 * pow(2.0, (semi - 45) / 12.0);
                int play_ms = dur_ms;
                int rest_ms = 0;
                if (s_music_style == 0) {
                    play_ms = (dur_ms * 7) / 8;
                    rest_ms = dur_ms - play_ms;
                } else if (s_music_style == 2) {
                    play_ms = (dur_ms * 3) / 4;
                    rest_ms = dur_ms - play_ms;
                }
                queue_tone((int)freq, play_ms, rest_ms);
                if (s_music_foreground && dur_ms > 0) {
                    if (!is_test_mode()) qb_sleep((double)dur_ms / 1000.0);
                }
            }
        } else if (cmd >= 'A' && cmd <= 'G') {
            static const int note_semis[7] = { 9, 11, 0, 2, 4, 5, 7 }; // A, B, C, D, E, F, G
            int semi = note_semis[cmd - 'A'];
            if (*p == '#' || *p == '+') { semi++; p++; }
            else if (*p == '-') { semi--; p++; }
            while (*p && isspace((unsigned char)*p)) p++;

            int len = s_play_def_len;
            if (isdigit((unsigned char)*p)) {
                len = 0;
                while (isdigit((unsigned char)*p)) len = len * 10 + (*p++ - '0');
            }
            int dur_ms = (int)(240000.0 / (s_play_tempo * (len > 0 ? len : 4)));
            while (*p == '.') { p++; dur_ms = (int)(dur_ms * 1.5); }

            int total_semi = (s_play_octave - 4) * 12 + semi - 9;
            double freq = 440.0 * pow(2.0, (double)total_semi / 12.0);

            int play_ms = dur_ms;
            int rest_ms = 0;
            if (s_music_style == 0) {
                play_ms = (dur_ms * 7) / 8;
                rest_ms = dur_ms - play_ms;
            } else if (s_music_style == 2) {
                play_ms = (dur_ms * 3) / 4;
                rest_ms = dur_ms - play_ms;
            }
            queue_tone((int)freq, play_ms, rest_ms);
            if (s_music_foreground && dur_ms > 0) {
                if (!is_test_mode()) qb_sleep((double)dur_ms / 1000.0);
            }
        }
    }
}

/* ========================================================================= */
/*                              DRAW COMMAND                                 */
/* ========================================================================= */

static int s_draw_x = 320;
static int s_draw_y = 240;
static int s_draw_color = 15;
static double s_draw_angle = 0.0;
static int s_draw_scale = 4;

void qb_draw(const char *cmd_str) {
    if (!cmd_str) return;
    const char *p = cmd_str;

    while (*p) {
        while (*p && (isspace((unsigned char)*p) || *p == ';')) p++;
        if (!*p) break;

        char c = toupper((unsigned char)*p++);
        bool no_draw = false;
        bool return_pos = false;

        if (c == 'B') {
            no_draw = true;
            while (*p && isspace((unsigned char)*p)) p++;
            c = toupper((unsigned char)*p++);
        } else if (c == 'N') {
            return_pos = true;
            while (*p && isspace((unsigned char)*p)) p++;
            c = toupper((unsigned char)*p++);
        }

        if (c == 'C') {
            while (*p && isspace((unsigned char)*p)) p++;
            int col = atoi(p);
            while (isdigit((unsigned char)*p)) p++;
            s_draw_color = col;
        } else if (c == 'S') {
            while (*p && isspace((unsigned char)*p)) p++;
            int s = atoi(p);
            while (isdigit((unsigned char)*p)) p++;
            if (s > 0) s_draw_scale = s;
        } else if (c == 'T' && (*p == 'A' || *p == 'a')) {
            p++;
            while (*p && isspace((unsigned char)*p)) p++;
            int ang = atoi(p);
            if (*p == '-' || *p == '+') p++;
            while (isdigit((unsigned char)*p)) p++;
            s_draw_angle = (double)ang;
        } else if (c == 'A') {
            while (*p && isspace((unsigned char)*p)) p++;
            int a = atoi(p);
            while (isdigit((unsigned char)*p)) p++;
            s_draw_angle = a * 90.0;
        } else if (c == 'M') {
            while (*p && isspace((unsigned char)*p)) p++;
            bool rel_x = false, rel_y = false;
            if (*p == '+') { rel_x = true; p++; }
            else if (*p == '-') { rel_x = true; }
            int tx = atoi(p);
            if (*p == '-') p++;
            while (isdigit((unsigned char)*p)) p++;
            while (*p && isspace((unsigned char)*p)) p++;
            if (*p == ',') p++;
            while (*p && isspace((unsigned char)*p)) p++;
            if (*p == '+') { rel_y = true; p++; }
            else if (*p == '-') { rel_y = true; }
            int ty = atoi(p);
            if (*p == '-') p++;
            while (isdigit((unsigned char)*p)) p++;

            int new_x = rel_x ? (s_draw_x + tx) : tx;
            int new_y = rel_y ? (s_draw_y + ty) : ty;
            if (!no_draw) {
                qb_line(s_draw_x, s_draw_y, new_x, new_y, s_draw_color, false, false);
            }
            if (!return_pos) {
                s_draw_x = new_x;
                s_draw_y = new_y;
            }
        } else if (c == 'P') {
            while (*p && isspace((unsigned char)*p)) p++;
            int paint_col = atoi(p);
            while (isdigit((unsigned char)*p)) p++;
            while (*p && isspace((unsigned char)*p)) p++;
            int border_col = s_draw_color;
            if (*p == ',') {
                p++;
                while (*p && isspace((unsigned char)*p)) p++;
                border_col = atoi(p);
                while (isdigit((unsigned char)*p)) p++;
            }
            qb_paint(s_draw_x, s_draw_y, paint_col, border_col);
        } else if (c == 'U' || c == 'D' || c == 'L' || c == 'R' ||
                   c == 'E' || c == 'F' || c == 'G' || c == 'H') {
            while (*p && isspace((unsigned char)*p)) p++;
            int dist = 1;
            if (isdigit((unsigned char)*p)) {
                dist = atoi(p);
                while (isdigit((unsigned char)*p)) p++;
            }
            double step = (double)dist * (s_draw_scale / 4.0);
            double base_ang = 0.0;
            switch (c) {
                case 'R': base_ang = 0.0; break;
                case 'E': base_ang = 45.0; break;
                case 'U': base_ang = 90.0; break;
                case 'H': base_ang = 135.0; break;
                case 'L': base_ang = 180.0; break;
                case 'G': base_ang = 225.0; break;
                case 'D': base_ang = 270.0; break;
                case 'F': base_ang = 315.0; break;
            }
            double rad = (base_ang + s_draw_angle) * (3.14159265358979323846 / 180.0);
            int dx = (int)round(cos(rad) * step);
            int dy = (int)round(-sin(rad) * step);
            int new_x = s_draw_x + dx;
            int new_y = s_draw_y + dy;

            if (!no_draw) {
                qb_line(s_draw_x, s_draw_y, new_x, new_y, s_draw_color, false, false);
            }
            if (!return_pos) {
                s_draw_x = new_x;
                s_draw_y = new_y;
            }
        }
    }
}
