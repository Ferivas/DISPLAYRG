all:
	pio run

upload:
	pio run --target upload

upload328p:
	pio run --target upload --environment atmega328p

clean:
	rm -rf .pio build *.hex *.elf *.lst *.o *.obj *.map *.sym *.lss *.eep *.srec *.bin *.cof *.a *.txt

help:
	@echo "Commands:"
	@echo "  make          - Build the project"
	@echo "  make upload   - Flash ATMEGA328 via USBASP"
	@echo "  make upload328p - Flash ATMEGA328P via USBASP"
	@echo "  make clean    - Clean build artifacts"
