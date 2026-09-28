# AGENTS.md

## Project Overview

This is an electronics/hardware project for a **Display SAC-A** controller board based on the **ATMEGA328** microcontroller. It contains four categories of files:

- **`BASCOM/`** — Firmware source code written in BASCOM-AVR BASIC
- **`SCH/`** — Altium Designer schematic (.SchDoc), PCB (.PcbDoc), and project (.PrjPCB) files
- **`bootloader/`** — PlatformIO-based Optiboot bootloader project for ATMEGA328

## Repository Structure

- `BASCOM/DISPLAYSACA_main.bas` — Main firmware entrypoint. Handles serial command processing, display driving, timer interrupts. Targets ATMEGA328 at 7.3728 MHz crystal, 9600 baud serial.
- `BASCOM/DISPLAYSACA_archivos.bas` — Include file with subroutines, variables, lookup tables (character fonts, column patterns, error messages). Marked `$nocompile`.
- `BASCOM/BootLoaderATMEGA328p_Leds_PC2.bas` — XMODEM bootloader for ATMEGA328. Uses serial at 38400 baud.
- `bootloader/` — Optiboot bootloader project (PlatformIO/Makefile). Compiled with avr-gcc via PlatformIO toolchain. Flashed via USBASP, then used for serial firmware updates.
- `display/` — PlatformIO project for 8×32 RG LED matrix driver. Timer2 column scanning ISR (~960Hz), Timer0 100Hz tick, UART 9600 baud serial commands (SETTXT, SETCOL, SETSCR), two 32-byte buffers, 48-char text buffer, PC2 LED 100ms/900ms blink, 5×7 fonts (0-9, A-Z, space, period). Build: `make` or `pio run`. Flash: `make upload` (USBASP).
- `SCH/` — Altium Designer project files (schematics for ATMEGA, DRVLED, POWER, RS485, Display_SACA; PCB layout; output jobs).

## Key Technical Details

- **Microcontroller**: ATMEGA328 ($regfile = "m328pdef.dat")
- **Crystal**: 7372800 Hz
- **Display**: Multiplexed LED display driven via shift registers (74HC595-style, using `Shiftout` on PORTB pins)
- **Serial**: UART at 9600 baud for command/data input
- **Command protocol**: Text commands sent via serial (e.g., `LEEVFW`, `SETLED`, `SETBUR`, `SETVAL`, `SETPES`, `SETTST`, etc.)
- **Firmware build tool**: BASCOM-AVR IDE (not a standard build system). There are no Makefiles, no CI, no test suite.
- **Display project** (`display/`): C/PlatformIO implementation of the display driver, based on BASCOM firmware analysis
  - 8×32 pixel RG LED matrix, multiplexed via shift registers
  - Timer2 column scanning ISR (~960Hz), Timer0 100Hz tick for LED blink + display refresh
  - UART at 9600 baud for serial commands. Framed protocol: `$` + message + ENTER (`\r`), e.g. `$SETTXT,HOLA,2`, `$SETCOL,3`, `$SETSCR,1`, `$SETTST,2`. Bytes outside `$`…ENTER are discarded (noise resync). Color: 1=red, 2=green (red channel off), 3=yellow
  - Two 32-byte buffers (red/green), 48-character text buffer
  - PC2 LED blinks 100ms on / 900ms off per second
  - Fonts: 5×7 pixel, alphanumeric characters only (0-9, A-Z, space, period)
  - Orientation: panel wiring is inverted on both axes — `display_render()` rotates text 180° (glyph row flip r↔6-r, column `31-pos`); test modes 3/4 compensated in `display_col_scan()`
  - Build: `make` or `pio run` | Flash: `make upload` (ATMEGA328 via USBASP) | `make upload328p` (ATMEGA328P via USBASP)
  - Two environments in platformio.ini: `atmega328` and `atmega328p`, both @ 7.3728 MHz
  - Fuse settings (no bootloader): HFUSE=0xD9, LFUSE=0xFF, EFUSE=0xFD

## Bootloader

The `bootloader/` directory contains an Optiboot bootloader project:
- **Build**: `make` in `bootloader/` directory (uses PlatformIO AVR toolchain at `~/.platformio/packages/toolchain-atmelavr`)
- **Flash via USBASP**: `make upload` (ATMEGA328) or `make upload328p` (ATMEGA328P)
- **Build output**: `bootloader/build/optiboot_atmega328.hex`
- **platformio.ini**: Two environments — `atmega328` and `atmega328p`, both @ 7.3728 MHz
- **Fuses**: HFUSE=0xDE, LFUSE=0xF7, EFUSE=0xFD (512-byte boot section, external crystal, SPIEN enabled)

## Important Conventions

- `.bas` files use `$include` to pull in `DISPLAYSACA_archivos.bas` from `DISPLAYSACA_main.bas`. The included file has `$nocompile` directive.
- The bootloader and main firmware have different crystal/baud settings — don't mix them.
- `bootloader/` uses the PlatformIO AVR toolchain (`atmelavr` platform, `328p8m` board) for avr-gcc, but the actual build is done by the Optiboot Makefile.
- `SCH/Project Outputs for Display_SACA/` contains generated artifacts (Job1.PDF, BOM spreadsheet). These are listed in `.gitignore` alongside `*.Zip`, `*.LOG`, and DRC output files.
- Altium project file `SCH/Display_SACA.PrjPCB` defines the project structure; document order matters (ATMega=1, RS485=2, etc.).
- The `bootloader/` directory is git-ignored (`.gitignore` in bootloader/) because build artifacts are generated.

## What This Repo Is NOT

- Not a software project with build/test/lint tooling in the traditional sense
- No `package.json`, no traditional `Makefile` in root, no CI workflows, no `opencode.json`
- No automated verification — verification requires physical hardware or Altium Designer
- `display/` has two environments in `platformio.ini`: `atmega328` and `atmega328p`, both @ 7.3728 MHz
- `display/` uses `upload_protocol = usbasp` for direct flash (no bootloader)
- `display/` fuse settings (no bootloader): HFUSE=0xD9, LFUSE=0xFF, EFUSE=0xFD
- `display/` MCU override: `board_build.mcu = atmega328` or `atmega328p` via `board = 328p8m`
- `bootloader/` has `platformio.ini` with two environments (`atmega328`, `atmega328p`) but PlatformIO build has `optiboot_version` linking issue — use `make` for bootloader builds
- `bootloader/` Makefile has `make TARGET=atmega328p` for ATMEGA328P bootloader build (Optiboot's `atmega328` target handles both chips)
