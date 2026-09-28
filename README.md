# Display SAC-A (DISPLAYRG)

Controlador de display LED RG de 8×32 píxeles basado en **ATmega328** (también compatible con ATmega328P), cristal externo de **7.3728 MHz**.

## Estructura del repositorio

| Directorio | Contenido |
|---|---|
| `BASCOM/` | Firmware original en BASCOM-AVR (`DISPLAYSACA_main.bas` + `DISPLAYSACA_archivos.bas`, bootloader XMODEM). Referencia del protocolo y del barrido. |
| `SCH/` | Proyecto Altium Designer (esquemáticos, PCB, salidas generadas). |
| `display/` | Firmware actual en C (PlatformIO + avr-gcc). Maneja el display, serie y LED indicador. |
| `bootloader/` | Bootloader Optiboot para ATmega328 (PlatformIO/Makefile, grabación por USBASP). |

## Firmware `display/`

Puerto a C del firmware BASCOM. Matriz RG multiplexada por registros de desplazamiento de 16 bits (datos `PB0`, reloj `PB1`, todos comparten bus):

- **Columnas** (16 posiciones, cada una cubre 2 columnas físicas 0–15 y 16–31): latch `PD2`, habilitación `PD3`
- **Filas mitad izquierda** (byte rojo + byte verde): latch `PD6`, habilitación `PD7`
- **Filas mitad derecha**: latch `PD4`, habilitación `PD5`
- **LED de señalización**: `PC2` en alto, 100 ms encendido / 900 ms apagado (Timer0 a 100 Hz)

### Temporización

- **Timer2**: barrido de columnas a ~3840 Hz (`TCNT2=226`, prescaler 64) → frame completo de 16 columnas a **240 Hz** (el original BASCOM iba a 960 Hz / 60 Hz y parpadeaba).
- **Timer0**: tick a 100 Hz (`TCNT0=184`, prescaler 1024) para el LED PC2 y el avance de scroll/texto (cada 100 ms).

### Protocolo serie (9600 baud, 8N1)

Trama: **`$` + mensaje + ENTER (`\r`)**. Todo byte fuera de una trama `$`…ENTER se descarta (resincroniza tras ruido). Comandos:

| Comando | Ejemplo | Descripción |
|---|---|---|
| `SETTXT,<texto>,<color>` | `$SETTXT,HOLA,2` | Texto (máx. 48 cars.), color 1=rojo, 2=verde, 3=amarillo |
| `SETCOL,<color>` | `$SETCOL,3` | Cambia color del texto actual |
| `SETSCR,<0\|1>` | `$SETSCR,1` | Scroll on/off (1 columna / 100 ms) |
| `SETTST,<0-4>` | `$SETTST,1` | 0=normal, 1=todo rojo, 2=todo verde, 3=barrido de columna, 4=mitad izq. roja / der. verde |

Respuestas: `OK` o `ERR n`. Comandos sin `$` se ignoran.

### Fuente 5×7

64 caracteres en flash: `0-9`, `A-Z`, **`a-z`**, espacio y punto. Glifo `E` corregido (la última columna era `0x07` en vez de `0x49`).

### Persistencia (EEPROM)

Texto, color y scroll se guardan en EEPROM (magic `0xA5` en addr 0, color en 1, scroll en 2, texto en 3–50) cada vez que llega `SETTXT`/`SETCOL`/`SETSCR`, usando `eeprom_update_*` (solo escribe bytes cambiados). Al arrancar se restauran; si la EEPROM está virgen se usan los valores de inicio ("Bienvenidos a su gimnasio", verde, scroll 1) y se guardan.

### Orientación

El panel está cableado invertido en ambos ejes, así que `display_render()` rota el texto 180°: voltea las filas del glifo (bit r ↔ 6-r) y escribe la columna `31 - pos`. Los modos `SETTST` 3 (barrido) y 4 (mitades) están compensados para mantener su sentido físico.

### Compilar y grabar (USBASP)

```bash
cd display
make              # compila entorno atmega328
make upload       # graba ATmega328
make upload328p   # graba ATmega328P
pio device monitor   # monitor serie a 9600 baud (recordar el $ delante)
```

Notas de grabación:
- Esta tarjeta 328 necesita SCK lento: `upload_flags = -B 100` ya está en `platformio.ini`. Sin verificación no hay `SUCCESS` válido: un `verification error` indica escritura corrupta (reintentar / revisar conexión USBASP).
- Firma ATmega328 = `1E 95 14` (la P es `1E 95 0F`).
- Fusibles sin bootloader: `HFUSE=0xD9` (arranque en `0x0000`), `LFUSE=0xF7` (cristal externo), `EFUSE=0xFD`. Con `HFUSE=0xDE` (bootloader) el micro arranca en la sección de boot y el programa nunca corre.

## Bootloader (`bootloader/`)

Optiboot compilado con el toolchain AVR de PlatformIO:

```bash
cd bootloader
make                    # bootloader ATmega328 (498 bytes)
make TARGET=atmega328p  # variante ATmega328P
make upload / make upload328p
```

Fusibles con bootloader: `HFUSE=0xDE, LFUSE=0xF7, EFUSE=0xFD`. Salida: `bootloader/build/optiboot_atmega328.hex` (ignorado por git).
