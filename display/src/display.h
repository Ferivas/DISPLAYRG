#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdint.h>
#include <avr/pgmspace.h>
#include "fonts.h"

#define BUFF_SIZE 32
#define TEXT_BUF_SIZE 48

#define COLOR_RED    1
#define COLOR_GREEN  2
#define COLOR_YELLOW 3

#define LED_DDR      DDRC
#define LED_PIN      PC2

#define DATOS_PIN    PB0
#define SCK_PIN      PB1

extern uint8_t bufframr[BUFF_SIZE];
extern uint8_t bufframg[BUFF_SIZE];
extern char text_buffer[TEXT_BUF_SIZE];
extern uint8_t color;
extern uint8_t scroll_enabled;
extern uint16_t scroll_offset;
extern uint8_t test_mode;
extern uint8_t test_col;
extern volatile uint8_t newseg_flag;
extern volatile uint8_t timer0_tick;
extern volatile uint8_t newseg_tick;
extern volatile uint8_t cntr_col;

void display_init(void);
void display_set_text(const char *text, uint8_t text_color);
void display_set_color(uint8_t text_color);
void display_set_scroll(uint8_t enable);
void display_render(void);
void display_scroll_text(void);
void display_clear(void);
void display_set_test(uint8_t m);
void shift_msb16(uint16_t value);
void shift_lsb8(uint8_t value);
void display_col_scan(void);

#endif
