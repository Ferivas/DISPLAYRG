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

### Compilar y grabar por USBASP

```bash
cd display
make              # compila entorno atmega328
make upload       # graba ATmega328 por USBASP
make upload328p   # graba ATmega328P por USBASP
pio device monitor   # monitor serie a 9600 baud (recordar el $ delante)
```

Comandos `avrdude` equivalentes (esta tarjeta 328 necesita SCK lento `-B 100`):

```bash
# Comprobar conexión y firma (ATmega328 = 1E 95 14; la P es 1E 95 0F)
avrdude -p atmega328 -c usbasp -B 100

# Grabar firmware y verificar (imprescindible: sin verificación no hay SUCCESS válido)
avrdude -p atmega328 -c usbasp -B 100 -U flash:w:.pio/build/atmega328/firmware.hex:i
avrdude -p atmega328 -c usbasp -B 100 -U flash:v:.pio/build/atmega328/firmware.hex:i

# Fusibles sin bootloader (arranque en 0x0000, cristal externo, SPIEN)
avrdude -p atmega328 -c usbasp -B 100 -U hfuse:w:0xD9:m -U lfuse:w:0xF7:m -U efuse:w:0xFD:m
```

Notas de grabación:
- Un `verification error` indica escritura corrupta (reintentar / revisar conexión USBASP).
- Con `HFUSE=0xDE` (bootloader) el micro arranca en la sección de boot y el programa nunca corre.
- La grabación por USBASP hace chip-erase y **borra la EEPROM**: al primer arranque se restauran los valores de inicio ("Bienvenidos a su gimnasio", verde, scroll 1).

## Bootloader (`bootloader/`)

Optiboot compilado con el toolchain AVR de PlatformIO (LED en PC2, 3 parpadeos al arrancar, protocolo STK500v1 a **38400 baud**):

```bash
cd bootloader
make                    # bootloader ATmega328 (498 bytes)
make TARGET=atmega328p  # variante ATmega328P
make upload / make upload328p   # graba bootloader + fusibles por USBASP
```

Salida: `bootloader/build/optiboot_atmega328.hex` (ignorado por git).

Fusibles con bootloader: `HFUSE=0xDE` (BOOTRST, sección de 512 B), `LFUSE=0xF7`, `EFUSE=0xFD`.

### Grabar la aplicación por serie (con bootloader instalado)

Una vez grabado Optiboot, el firmware de `display/` se puede actualizar por el puerto serie sin USBASP (el bootloader se activa al resetear; hay ~1 s para iniciar la subida):

```bash
cd display
pio run   # o make, genera .pio/build/atmega328/firmware.hex

avrdude -p atmega328 -c arduino -b 38400 -P /dev/ttyUSB0 \
  -U flash:w:.pio/build/atmega328/firmware.hex:i
```

Notas:
- Ajustar `-P` al puerto real (`/dev/ttyUSB0`, `COM3`, …).
- La subida por bootloader **no borra la EEPROM**: se conservan el último texto, color y scroll guardados.
- Si el micro no responde, pulsar reset justo antes del comando (o usar USBASP para regrabar bootloader + fusibles).

## Historial de cambios

- Puerto del firmware BASCOM a C (`display/`, PlatformIO + avr-gcc).
- Barrido Timer2 a 240 Hz de frame (el original a 60 Hz parpadeaba); Timer0 a 100 Hz (LED PC2 + scroll).
- Protocolo serie enmarcado `$`…ENTER con `SETTXT`/`SETCOL`/`SETSCR`/`SETTST`.
- Fuente 5×7 de 64 caracteres (glifo `E` corregido, minúsculas `a-z` añadidas).
- Rotación de texto 180° (panel cableado invertido en ambos ejes); tests 3/4 compensados.
- Persistencia de texto/color/scroll en EEPROM (`config_load`/`config_save`).
- Texto de inicio: "Bienvenidos a su gimnasio", verde, scroll activado.
- Bootloader Optiboot a 38400 baud con LED en PC2.
