# Display SAC-A — Optiboot Bootloader Build System
# ATMEGA328 / ATMEGA328P @ 7.3728 MHz, LED on PC2 (active high)
# Upload via USBASP
#
# Targets:
#   make              - Build for ATMEGA328 (default)
#   make TARGET=atmega328p - Build for ATMEGA328P
#   make upload       - Flash via USBASP (ATMEGA328)
#   make upload328p   - Flash via USBASP (ATMEGA328P)
#   make pio          - Flash via PlatformIO (ATMEGA328, requires bootloader already flashed)
#   make pio328p      - Flash via PlatformIO (ATMEGA328P, requires bootloader already flashed)
#   make clean        - Clean build artifacts
#   make info         - Show build info

# PlatformIO AVR toolchain
TOOLCHAIN_DIR = $(shell find $(HOME)/.platformio/packages/toolchain-atmelavr -maxdepth 1 -type d 2>/dev/null | head -1)
ifeq ($(TOOLCHAIN_DIR),)
TOOLCHAIN_DIR = $(shell dirname $(shell which avr-gcc 2>/dev/null))
endif
export PATH := $(TOOLCHAIN_DIR)/bin:$(PATH)

# Optiboot source directory
OPTIBOOT_DIR = /tmp/opencode/optiboot/optiboot/bootloaders/optiboot

# Default target
TARGET ?= atmega328
MCU_TARGET ?= atmega328
AVR_FREQ = 7372800L
LED = C2
LED_START_FLASHES = 3
BIGBOOT = 0
BAUD_RATE = 38400

# Output
PROGRAM = optiboot
BUILD_DIR = build
HEX_FILE = $(BUILD_DIR)/optiboot_$(TARGET).hex
ELF_FILE = $(BUILD_DIR)/optiboot_$(TARGET).elf
LST_FILE = $(BUILD_DIR)/optiboot_$(TARGET).lst

# Default target
all: $(HEX_FILE)

# Build optiboot using Optiboot Makefile
# Note: Atmega328 target in Optiboot Makefile already builds for ATMEGA328P (MCU_TARGET=atmega328p)
# TARGET=atmega328p is aliased to atmega328 since Optiboot handles both chips
OPTIBOOT_TARGET := $(if $(filter atmega328p,$(TARGET)),atmega328,$(TARGET))
$(HEX_FILE):
	@mkdir -p $(BUILD_DIR)
	cd $(OPTIBOOT_DIR) && make $(OPTIBOOT_TARGET) MCU_TARGET=$(MCU_TARGET) AVR_FREQ=$(AVR_FREQ) LED=$(LED) BAUD_RATE=$(BAUD_RATE) LED_START_FLASHES=$(LED_START_FLASHES) BIGBOOT=$(BIGBOOT) 2>&1
	@cp $(OPTIBOOT_DIR)/$(PROGRAM)_$(OPTIBOOT_TARGET).hex $(HEX_FILE)
	@cp $(OPTIBOOT_DIR)/$(PROGRAM)_$(OPTIBOOT_TARGET).elf $(ELF_FILE) 2>/dev/null || true
	@cp $(OPTIBOOT_DIR)/$(PROGRAM)_$(OPTIBOOT_TARGET).lst $(LST_FILE) 2>/dev/null || true
	@echo ""
	@echo "=== Bootloader Build Complete ==="
	@echo "  Target:    $(TARGET)"
	@echo "  MCU:       $(MCU_TARGET) @ $(AVR_FREQ) Hz"
	@echo "  LED:       PC2 (active high)"
	@echo "  Protocol:  STK500v1/XMODEM @ $(BAUD_RATE) baud"
	@echo "  Boot size: 512 bytes"
	@echo "  Hex file:  $(HEX_FILE)"
	@echo "======================================"

# Flash via USBASP using avrdude (default ATMEGA328)
MCU_UPLOAD ?= atmega328
upload: $(HEX_FILE)
	avrdude -p $(MCU_UPLOAD) -c usbasp -U flash:w:$(HEX_FILE):i -U hfuse:w:0xDE:m -U lfuse:w:0xF7:m -U efuse:w:0xFD:m
	@echo "Bootloader flashed via USBASP!"

# Flash via USBASP using avrdude (ATMEGA328P)
upload328p: $(HEX_FILE)
	avrdude -p atmega328p -c usbasp -U flash:w:$(HEX_FILE):i -U hfuse:w:0xDE:m -U lfuse:w:0xF7:m -U efuse:w:0xFD:m
	@echo "Bootloader flashed via USBASP!"

# Clean
clean:
	@rm -rf $(BUILD_DIR)
	@cd $(OPTIBOOT_DIR) && make clean 2>/dev/null || true
	@echo "Clean complete."

# Info
info:
	@echo "=== ATMEGA328/ATMEGA328P Optiboot Bootloader ==="
	@echo "  Crystal:   7.3728 MHz"
	@echo "  LED:       PC2 (active high)"
	@echo "  UART:      38400 baud (XMODEM)"
	@echo "  Boot size: 512 bytes"
	@echo "  Protocol:  STK500v1"
	@echo "  Fuses:     HFUSE=0xDE LFUSE=0xF7 EFUSE=0xFD"
	@echo "=============================================="

.PHONY: all upload upload328p pio pio328p clean info