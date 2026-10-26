#define SDL_MAIN_HANDLED
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <SDL.h>

#define SCREEN_W 640
#define SCREEN_H 350 // EGA Screen 9 (ou 480 pour VGA Screen 12)
#define BYTES_PER_ROW (SCREEN_W / 8) // 80 octets par ligne

// Palette standard EGA/VGA 16 couleurs (Format 0x00RRGGBB)
static const uint32_t EGA_PALETTE[16] = {
    0xFF000000, // 0: Noir
    0xFF0000AA, // 1: Bleu
    0xFF00AA00, // 2: Vert
    0xFF00AAAA, // 3: Cyan
    0xFFAA0000, // 4: Rouge
    0xFFAA00AA, // 5: Magenta
    0xFFAA5500, // 6: Brun / Marron
    0xFFAAAAAA, // 7: Gris clair
    0xFF555555, // 8: Gris fonc
    0xFF5555FF, // 9: Bleu clair
    0xFF55FF55, // 10: Vert clair
    0xFF55FFFF, // 11: Cyan clair
    0xFFFF5555, // 12: Rouge clair
    0xFFFF55FF, // 13: Magenta clair
    0xFFFFFF55, // 14: Jaune
    0xFFFFFFFF  // 15: Blanc clatant
};

// Donnes des 4 plans de bits (Bitplanes)
typedef struct {
    uint8_t *data[4];      // 0: BLU, 1: GRN, 2: RED, 3: INT
    size_t size[4];
} EgaImage;

// Charge un fichier BSAVE QBasic (7 octets d'en-tte: 0xFD, seg, off, len)
static bool load_bsave_plane(const char *path, uint8_t **out_data, size_t *out_size) {
    FILE *f = fopen(path, "rb");
    if (!f) return false;

    uint8_t hdr[7];
    if (fread(hdr, 1, 7, f) != 7 || hdr[0] != 0xFD) {
        fclose(f);
        return false;
    }

    uint16_t len = (uint16_t)(hdr[5] | (hdr[6] << 8));
    uint8_t *buf = (uint8_t*)malloc(len);
    if (!buf) { fclose(f); return false; }

    size_t read_bytes = fread(buf, 1, len, f);
    fclose(f);

    *out_data = buf;
    *out_size = read_bytes;
    return true;
}

// Reconstruit le Framebuffer RGBA depuis les bitplanes activs (mask: 1=B, 2=G, 4=R, 8=I)
static void decode_bitplanes_to_framebuffer(const EgaImage *img, int active_plane_mask, uint32_t *framebuffer) {
    // Rinitialiser le framebuffer  noir
    for (int i = 0; i < SCREEN_W * SCREEN_H; i++) {
        framebuffer[i] = EGA_PALETTE[0];
    }

    // VRAM 8 bits par pixel (indice 0..15)
    static uint8_t vram[SCREEN_W * SCREEN_H];
    memset(vram, 0, sizeof(vram));

    for (int p = 0; p < 4; p++) {
        if (!(active_plane_mask & (1 << p))) continue;
        if (!img->data[p]) continue;

        const uint8_t *plane_buf = img->data[p];
        size_t plane_len = img->size[p];

        for (size_t i = 0; i < plane_len; i++) {
            int row = (int)(i / BYTES_PER_ROW);
            int col_byte = (int)(i % BYTES_PER_ROW);
            if (row >= SCREEN_H) break;

            uint8_t bval = plane_buf[i];
            for (int b = 0; b < 8; b++) {
                int col = col_byte * 8 + b;
                if (col >= SCREEN_W) continue;

                int bit = (bval >> (7 - b)) & 1;
                int pix_idx = row * SCREEN_W + col;
                if (bit) {
                    vram[pix_idx] |= (1 << p);
                } else {
                    vram[pix_idx] &= ~(1 << p);
                }
            }
        }
    }

    // Convertir les indices de palette VRAM (0..15) en couleurs 32-bit ARGB
    for (int y = 0; y < SCREEN_H; y++) {
        for (int x = 0; x < SCREEN_W; x++) {
            int pix_idx = y * SCREEN_W + x;
            uint8_t col_idx = vram[pix_idx] & 0x0F;
            framebuffer[pix_idx] = EGA_PALETTE[col_idx];
        }
    }
}

static void load_image_set(const char *name, EgaImage *img) {
    const char *exts[4] = { ".BLU", ".GRN", ".RED", ".INT" };
    for (int p = 0; p < 4; p++) {
        if (img->data[p]) { free(img->data[p]); img->data[p] = NULL; }
        char path[256];
        snprintf(path, sizeof(path), "%s%s", name, exts[p]);
        if (!load_bsave_plane(path, &img->data[p], &img->size[p])) {
            snprintf(path, sizeof(path), "D5000/%s%s", name, exts[p]);
            load_bsave_plane(path, &img->data[p], &img->size[p]);
        }
    }
}

int main(int argc, char *argv[]) {
    (void)argc; (void)argv;
    printf("====================================================================\n");
    printf(" Simulation SDL du Framebuffer EGA/VGA Planar (4 Bitplanes)        \n");
    printf(" Code QBasic : OUT &H3C4, 2: OUT &H3C5, mask: BLOAD 'File.xxx', 0  \n");
    printf("====================================================================\n");

    const char *names[2] = { "FD5000", "Des6" };
    int cur_image_idx = 0;

    EgaImage img = {0};
    load_image_set(names[cur_image_idx], &img);

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "Erreur SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window *win = SDL_CreateWindow(
        "Simulation SDL Framebuffer EGA/VGA (4 Bitplanes) - [FD5000]",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        SCREEN_W * 2, SCREEN_H * 2,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );

    SDL_Renderer *ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    SDL_Texture *tex = SDL_CreateTexture(
        ren,
        SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING,
        SCREEN_W, SCREEN_H
    );

    uint32_t *framebuffer = (uint32_t*)malloc(SCREEN_W * SCREEN_H * sizeof(uint32_t));

    int step = 4; // 1: BLU, 2: BLU+GRN, 3: BLU+GRN+RED, 4: TOUT (16 couleurs)
    bool running = true;

    printf("\nControles interactifs dans la fenetre SDL :\n");
    printf(" [1] : Afficher Plan 0 seul (BLU, mask=1)\n");
    printf(" [2] : Afficher Plan 0 + 1 (BLU+GRN, mask=3)\n");
    printf(" [3] : Afficher Plan 0 + 1 + 2 (BLU+GRN+RED, mask=7)\n");
    printf(" [4] : Afficher Tous les plans (BLU+GRN+RED+INT, mask=15 = 16 couleurs)\n");
    printf(" [ESPACE] : Avancer etape par etape (animation progressive)\n");
    printf(" [T]      : Basculer d'image (FD5000 <-> Des6)\n");
    printf(" [ECHAP]  : Quitter\n\n");

    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) {
                running = false;
            } else if (e.type == SDL_KEYDOWN) {
                if (e.key.keysym.sym == SDLK_ESCAPE) running = false;
                else if (e.key.keysym.sym == SDLK_1) step = 1;
                else if (e.key.keysym.sym == SDLK_2) step = 2;
                else if (e.key.keysym.sym == SDLK_3) step = 3;
                else if (e.key.keysym.sym == SDLK_4) step = 4;
                else if (e.key.keysym.sym == SDLK_SPACE) {
                    step = (step % 4) + 1;
                } else if (e.key.keysym.sym == SDLK_t) {
                    cur_image_idx = 1 - cur_image_idx;
                    load_image_set(names[cur_image_idx], &img);
                    char title[128];
                    snprintf(title, sizeof(title), "Simulation SDL Framebuffer EGA/VGA (4 Bitplanes) - [%s]", names[cur_image_idx]);
                    SDL_SetWindowTitle(win, title);
                }
            }
        }

        int mask = (1 << step) - 1; // 1->1, 2->3, 3->7, 4->15
        decode_bitplanes_to_framebuffer(&img, mask, framebuffer);

        SDL_UpdateTexture(tex, NULL, framebuffer, SCREEN_W * sizeof(uint32_t));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, NULL, NULL);
        SDL_RenderPresent(ren);

        SDL_Delay(16);
    }

    free(framebuffer);
    for (int p = 0; p < 4; p++) {
        if (img.data[p]) free(img.data[p]);
    }
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();

    return 0;
}
