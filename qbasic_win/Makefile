CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11 -IC:/msys64/ucrt64/include/SDL2
LDFLAGS = -static -lSDL2 -lm -lkernel32 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lversion -luuid -ladvapi32 -lsetupapi -lshell32 -ldinput8

SRC = main.c win_compat.c qb_types.c qb_interp.c sdl_inkey.c qb_compiler.c
OBJ = $(SRC:.c=.o)
TARGET = qbasic_win.exe

all: $(TARGET)

simu: simu_bitplanes_sdl.exe

simu_bitplanes_sdl.exe: simu_bitplanes_sdl.c
	$(CC) $(CFLAGS) -DSDL_MAIN_HANDLED $< -o $@ $(LDFLAGS)

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $(TARGET) $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	cmd /c del /f /q $(OBJ) $(TARGET) simu_bitplanes_sdl.exe 2>nul || exit 0

.PHONY: all clean simu
