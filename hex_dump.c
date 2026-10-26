#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
    const char* filename = argc > 1 ? argv[1] : "QBASIC.EXE";
    long offset = argc > 2 ? strtol(argv[2], NULL, 0) : 0;
    long length = argc > 3 ? strtol(argv[3], NULL, 0) : 256;

    FILE *f = fopen(filename, "rb");
    if (!f) {
        perror("fopen");
        return 1;
    }
    if (fseek(f, offset, SEEK_SET) != 0) {
        perror("fseek");
        fclose(f);
        return 1;
    }

    unsigned char b[16];
    long remaining = length;
    long cur_offset = offset;

    while (remaining > 0) {
        size_t to_read = remaining > 16 ? 16 : remaining;
        size_t n = fread(b, 1, to_read, f);
        if (n == 0) break;

        printf("%06lX: ", cur_offset);
        for (size_t j = 0; j < 16; j++) {
            if (j < n) printf("%02X ", b[j]);
            else printf("   ");
        }
        printf(" | ");
        for (size_t j = 0; j < 16; j++) {
            if (j < n) {
                unsigned char c = b[j];
                printf("%c", (c >= 32 && c < 127) ? c : '.');
            }
        }
        printf("\n");
        cur_offset += n;
        remaining -= n;
    }

    fclose(f);
    return 0;
}
