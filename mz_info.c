#include <stdio.h>
#include <stdint.h>

#pragma pack(push, 1)
typedef struct {
    uint16_t e_magic;    // 0x5A4D "MZ"
    uint16_t e_cblp;     // Bytes on last page of file
    uint16_t e_cp;       // Pages in file
    uint16_t e_crlc;     // Relocations
    uint16_t e_cparhdr;  // Size of header in paragraphs
    uint16_t e_minalloc; // Minimum extra paragraphs needed
    uint16_t e_maxalloc; // Maximum extra paragraphs needed
    uint16_t e_ss;       // Initial (relative) SS value
    uint16_t e_sp;       // Initial SP value
    uint16_t e_csum;     // Checksum
    uint16_t e_ip;       // Initial IP value
    uint16_t e_cs;       // Initial (relative) CS value
    uint16_t e_lfarlc;   // File address of relocation table
    uint16_t e_ovno;     // Overlay number
} DOS_MZ_HEADER;
#pragma pack(pop)

int main(int argc, char* argv[]) {
    const char* filename = argc > 1 ? argv[1] : "QBASIC.EXE";
    FILE* f = fopen(filename, "rb");
    if (!f) {
        perror("fopen");
        return 1;
    }
    DOS_MZ_HEADER hdr;
    if (fread(&hdr, sizeof(hdr), 1, f) != 1) {
        fprintf(stderr, "Failed to read header\n");
        fclose(f);
        return 1;
    }
    printf("=== DOS MZ Header Analysis: %s ===\n", filename);
    printf("Magic:              0x%04X ('%c%c')\n", hdr.e_magic, (char)(hdr.e_magic & 0xFF), (char)(hdr.e_magic >> 8));
    printf("Bytes on last page: 0x%04X (%u)\n", hdr.e_cblp, hdr.e_cblp);
    printf("512-byte pages:     %u (Calculated size: %u bytes)\n", hdr.e_cp, (hdr.e_cp - 1) * 512 + hdr.e_cblp);
    printf("Relocations:        %u\n", hdr.e_crlc);
    printf("Header paragraphs:  %u (0x%X bytes)\n", hdr.e_cparhdr, hdr.e_cparhdr * 16);
    printf("Initial SS:SP:      %04X:%04X\n", hdr.e_ss, hdr.e_sp);
    printf("Initial CS:IP:      %04X:%04X (Entry Point)\n", hdr.e_cs, hdr.e_ip);
    printf("Reloc table offset: 0x%04X\n", hdr.e_lfarlc);

    // Read following bytes
    char sig[64] = {0};
    fread(sig, 1, sizeof(sig) - 1, f);
    printf("Signature string:   %.48s\n", sig);
    fclose(f);
    return 0;
}
