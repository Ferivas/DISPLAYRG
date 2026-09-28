#include "display.h"
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <string.h>

uint8_t bufframr[BUFF_SIZE];
uint8_t bufframg[BUFF_SIZE];
char text_buffer[TEXT_BUF_SIZE];
uint8_t color;
uint8_t scroll_enabled;
uint16_t scroll_offset;
volatile uint8_t newseg_flag;

volatile uint8_t timer0_tick;
volatile uint8_t newseg_tick;
volatile uint8_t cntr_col;
uint8_t test_mode;
uint8_t test_col;

static const uint16_t Tbl_col[16] PROGMEM = {
    0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080,
    0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000, 0x8000
};

#define EEPROM_MAGIC 0xA5
#define EE_MAGIC_ADDR ((uint8_t *)0)
#define EE_COLOR_ADDR ((uint8_t *)1)
#define EE_SCROLL_ADDR ((uint8_t *)2)
#define EE_TEXT_ADDR ((uint8_t *)3)

void display_init(void) {
    uint8_t i;

    DDRB |= (1 << DATOS_PIN) | (1 << SCK_PIN);
    DDRD |= (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7);
    DDRC |= (1 << LED_PIN);

    PORTD |= (1 << 3) | (1 << 5) | (1 << 7);
    PORTC |= (1 << LED_PIN);

    for (i = 0; i < BUFF_SIZE; i++) {
        bufframr[i] = 0;
        bufframg[i] = 0;
    }

    text_buffer[0] = '\0';
    color = COLOR_RED;
    scroll_enabled = 0;
    scroll_offset = 0;
    test_mode = 0;
    test_col = 0;
    newseg_flag = 0;
    timer0_tick = 0;
    newseg_tick = 0;
    cntr_col = 0;
}

void shift_msb16(uint16_t value) {
    uint8_t hi = (uint8_t)(value >> 8);
    uint8_t lo = (uint8_t)value;
    uint8_t sh = 0;
    uint8_t zero = 0;
    uint8_t i;

#pragma GCC unroll 8
    for (i = 0; i < 8; i++) {
        __asm__ volatile (
            "lsl %[val]\n\t"
            "andi %[sh], 0xFC\n\t"
            "adc %[sh], %[z]\n\t"
            "out %[port], %[sh]\n\t"
            "ori %[sh], 0x02\n\t"
            "out %[port], %[sh]"
            : [sh] "+r" (sh), [val] "+r" (hi)
            : [z] "r" (zero), [port] "I" (_SFR_IO_ADDR(PORTB))
            : "cc");
    }
#pragma GCC unroll 8
    for (i = 0; i < 8; i++) {
        __asm__ volatile (
            "lsl %[val]\n\t"
            "andi %[sh], 0xFC\n\t"
            "adc %[sh], %[z]\n\t"
            "out %[port], %[sh]\n\t"
            "ori %[sh], 0x02\n\t"
            "out %[port], %[sh]"
            : [sh] "+r" (sh), [val] "+r" (lo)
            : [z] "r" (zero), [port] "I" (_SFR_IO_ADDR(PORTB))
            : "cc");
    }
    PORTB &= ~(1 << SCK_PIN);
}

void shift_lsb8(uint8_t value) {
    uint8_t sh = 0;
    uint8_t zero = 0;
    uint8_t i;

#pragma GCC unroll 8
    for (i = 0; i < 8; i++) {
        __asm__ volatile (
            "lsr %[val]\n\t"
            "andi %[sh], 0xFC\n\t"
            "adc %[sh], %[z]\n\t"
            "out %[port], %[sh]\n\t"
            "ori %[sh], 0x02\n\t"
            "out %[port], %[sh]"
            : [sh] "+r" (sh), [val] "+r" (value)
            : [z] "r" (zero), [port] "I" (_SFR_IO_ADDR(PORTB))
            : "cc");
    }
    PORTB &= ~(1 << SCK_PIN);
}

static inline void latch_enable(uint8_t latch_pin, uint8_t oe_pin) {
    PORTD |= (1 << latch_pin);
    PORTD &= ~(1 << latch_pin);
    PORTD &= ~(1 << oe_pin);
}

static inline void disable_outputs(void) {
    PORTD |= (1 << 3) | (1 << 5) | (1 << 7);
}

/* Panel rows are wired bottom-up: mirror 7-row glyphs vertically (bit r <-> bit 6-r). */
static uint8_t flip_rows(uint8_t b) {
    b = ((b & 0xAA) >> 1) | ((b & 0x55) << 1);
    b = ((b & 0xCC) >> 2) | ((b & 0x33) << 2);
    b = ((b & 0xF0) >> 4) | ((b & 0x0F) << 4);
    return b >> 1;
}

void display_col_scan(void) {
    uint8_t col = cntr_col;
    uint16_t col_select;
    uint8_t red_a, green_a, red_b, green_b;

    disable_outputs();

    col_select = pgm_read_word(&Tbl_col[col]);
    shift_msb16(col_select);
    latch_enable(2, 3);

    if (test_mode == 0) {
        red_a = bufframr[col];
        green_a = bufframg[col];
        red_b = bufframr[col + 16];
        green_b = bufframg[col + 16];
    } else if (test_mode == 1) {
        red_a = 0xFF; green_a = 0x00;
        red_b = 0xFF; green_b = 0x00;
    } else if (test_mode == 2) {
        red_a = 0x00; green_a = 0xFF;
        red_b = 0x00; green_b = 0xFF;
    } else if (test_mode == 3) {
        red_a = (col == (uint8_t)(15 - test_col)) ? 0xFF : 0x00;
        green_a = 0x00;
        red_b = (col == (uint8_t)(15 - test_col)) ? 0xFF : 0x00;
        green_b = 0x00;
    } else {
        red_a = 0x00; green_a = 0xFF;
        red_b = 0xFF; green_b = 0x00;
    }

    shift_lsb8(red_a);
    shift_lsb8(green_a);
    latch_enable(6, 7);

    shift_lsb8(red_b);
    shift_lsb8(green_b);
    latch_enable(4, 5);

    cntr_col = (cntr_col + 1) % 16;
}

void display_set_test(uint8_t m) {
    if (m > 4) m = 0;
    test_mode = m;
    test_col = 0;
}

static uint8_t get_char_width(const char *s) {
    uint8_t len = strlen(s);
    if (len > 6) len = 6;
    const uint8_t pos_table[] = {12, 12, 9, 6, 3, 0};
    uint8_t pos;
    if (len > 0 && len <= 6) {
        pos = pos_table[len - 1];
    } else {
        pos = 0;
    }
    return pos;
}

void display_render(void) {
    uint8_t i, j;
    const char *s = text_buffer;
    uint8_t len = strlen(s);
    uint16_t offset = 0;
    uint8_t base = 0;
    static uint8_t shadow_r[BUFF_SIZE];
    static uint8_t shadow_g[BUFF_SIZE];

    if (len == 0) {
        display_clear();
        return;
    }

    for (i = 0; i < BUFF_SIZE; i++) {
        shadow_r[i] = 0;
        shadow_g[i] = 0;
    }

    if (scroll_enabled) {
        offset = scroll_offset;
    } else {
        base = get_char_width(s);
    }

    for (j = 0; j < len; j++) {
        uint8_t idx = char_to_index((uint8_t)s[j]);
        uint16_t strip = (uint16_t)base + (uint16_t)j * 6u;

        for (i = 0; i < FONT_WIDTH; i++) {
            uint8_t font_byte = 0;
            int16_t pos;
            uint8_t col;
            if (idx < NUM_CHARS) {
                font_byte = flip_rows(pgm_read_byte(&font[idx][i]));
            }
            pos = (int16_t)(strip + i) - (int16_t)offset;
            if (pos < 0 || pos >= 32) continue;
            col = 31 - (uint8_t)pos;
            if (color == COLOR_RED || color == COLOR_YELLOW) {
                shadow_r[col] = font_byte;
            } else {
                shadow_r[col] = 0;
            }
            if (color == COLOR_GREEN || color == COLOR_YELLOW) {
                shadow_g[col] = font_byte;
            } else {
                shadow_g[col] = 0;
            }
        }
    }

    cli();
    for (i = 0; i < BUFF_SIZE; i++) {
        bufframr[i] = shadow_r[i];
        bufframg[i] = shadow_g[i];
    }
    sei();
}

void display_scroll_text(void) {
    uint8_t len;
    uint16_t total;
    if (!scroll_enabled) return;
    if (text_buffer[0] == '\0') return;

    len = strlen(text_buffer);
    total = (uint16_t)len * 6u + 32u;

    scroll_offset++;
    if (scroll_offset >= total) {
        scroll_offset = 0;
    }

    display_render();
}

void display_set_text(const char *text, uint8_t text_color) {
    uint8_t i;
    for (i = 0; i < TEXT_BUF_SIZE - 1 && text[i] != '\0'; i++) {
        text_buffer[i] = text[i];
    }
    text_buffer[i] = '\0';
    color = text_color;
    scroll_offset = 0;
    display_render();
    config_save();
}

void display_set_color(uint8_t text_color) {
    if (text_color > 0 && text_color <= 3) {
        color = text_color;
        display_render();
        config_save();
    }
}

void display_set_scroll(uint8_t enable) {
    scroll_enabled = enable ? 1 : 0;
    scroll_offset = 0;
    display_render();
    config_save();
}

void display_clear(void) {
    uint8_t i;
    for (i = 0; i < BUFF_SIZE; i++) {
        bufframr[i] = 0;
        bufframg[i] = 0;
    }
}

void config_save(void) {
    eeprom_update_byte(EE_MAGIC_ADDR, EEPROM_MAGIC);
    eeprom_update_byte(EE_COLOR_ADDR, color);
    eeprom_update_byte(EE_SCROLL_ADDR, scroll_enabled);
    eeprom_update_block(text_buffer, EE_TEXT_ADDR, strlen(text_buffer) + 1);
}

void config_load(void) {
    uint8_t c, s;
    if (eeprom_read_byte(EE_MAGIC_ADDR) != EEPROM_MAGIC) {
        display_set_text("Bienvenidos a su gimnasio", COLOR_GREEN);
        display_set_scroll(1);
        return;
    }
    eeprom_read_block(text_buffer, EE_TEXT_ADDR, TEXT_BUF_SIZE);
    text_buffer[TEXT_BUF_SIZE - 1] = '\0';
    c = eeprom_read_byte(EE_COLOR_ADDR);
    s = eeprom_read_byte(EE_SCROLL_ADDR);
    color = (c >= COLOR_RED && c <= COLOR_YELLOW) ? c : COLOR_GREEN;
    scroll_enabled = s ? 1 : 0;
    scroll_offset = 0;
    display_render();
}
