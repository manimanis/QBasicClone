#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

int main(int argc, char* argv[]) {
    const char* filename = argc > 1 ? argv[1] : "QBASIC_UNPACKED.EXE";
    FILE* f = fopen(filename, "rb");
    if (!f) {
        perror("fopen");
        return 1;
    }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    uint8_t* data = (uint8_t*)malloc(size);
    if (!data) return 1;
    fread(data, 1, size, f);
    fclose(f);

    printf("=== Binary Scan of %s (%ld bytes) ===\n", filename, size);

    // Count interrupts: 0xCD <int_num>
    int int21_count = 0;
    int int10_count = 0;
    int int16_count = 0;
    int int33_count = 0;
    int other_int_count = 0;

    // Count function prologues: push bp (0x55), mov bp, sp (0x8B 0xEC)
    int func_prologues = 0;

    for (long i = 0x200; i < size - 2; i++) {
        if (data[i] == 0x55 && data[i+1] == 0x8B && data[i+2] == 0xEC) {
            func_prologues++;
        }
        if (data[i] == 0xCD) {
            uint8_t int_no = data[i+1];
            if (int_no == 0x21) int21_count++;
            else if (int_no == 0x10) int10_count++;
            else if (int_no == 0x16) int16_count++;
            else if (int_no == 0x33) int33_count++;
            else other_int_count++;
        }
    }

    printf("Detected Function Prologues (push bp; mov bp, sp): %d\n", func_prologues);
    printf("Interrupts detected:\n");
    printf("  INT 21h (DOS Kernel Services):  %d calls\n", int21_count);
    printf("  INT 10h (BIOS Video Services):   %d calls\n", int10_count);
    printf("  INT 16h (BIOS Keyboard):         %d calls\n", int16_count);
    printf("  INT 33h (DOS Mouse Driver):      %d calls\n", int33_count);
    printf("  Other Interrupts:                %d calls\n", other_int_count);

    free(data);
    return 0;
}
