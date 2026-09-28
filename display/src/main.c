#include <avr/io.h>
#include <avr/interrupt.h>
#include <string.h>
#include <stdlib.h>
#include "display.h"

#define UART_RX_SIZE 64
#define F_CPU 7372800UL
#define START_CHAR '$'

static volatile uint8_t uart_rx_buffer[UART_RX_SIZE];
static volatile uint8_t uart_rx_head;
static volatile uint8_t uart_rx_collect;

ISR(TIMER0_OVF_vect) {
    TCNT0 = 184;
    timer0_tick++;
    if (timer0_tick >= 100) timer0_tick = 0;

    if (timer0_tick < 10) {
        PORTC |= (1 << LED_PIN);
    } else {
        PORTC &= ~(1 << LED_PIN);
    }

    newseg_tick++;
    if (newseg_tick >= 10) {
        newseg_tick = 0;
        newseg_flag = 1;
    }
}

ISR(TIMER2_OVF_vect) {
    TCNT2 = 226;
    display_col_scan();
}

ISR(USART_RX_vect) {
    uint8_t c = UDR0;

    if (c == START_CHAR) {
        uart_rx_head = 0;
        uart_rx_collect = 1;
        return;
    }

    if (!uart_rx_collect) {
        return;
    }

    if (c == '\r' || c == '\n') {
        if (uart_rx_collect == 1) {
            uart_rx_collect = 2;
        } else if (uart_rx_collect == 3) {
            uart_rx_collect = 0;
        }
        return;
    }

    if (uart_rx_head < UART_RX_SIZE - 1) {
        uart_rx_buffer[uart_rx_head++] = c;
    } else {
        uart_rx_collect = 3;
    }
}

static void uart_putc(char c) {
    while (!(UCSR0A & _BV(UDRE0)));
    UDR0 = c;
}

static void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

static void parse_and_execute(const char *cmd) {
    char cmd_name[7];
    uint8_t i;

    for (i = 0; i < 6 && cmd[i] != ',' && cmd[i] != '\0'; i++) {
        cmd_name[i] = cmd[i];
    }
    cmd_name[i] = '\0';

    for (uint8_t j = 0; j < i; j++) {
        if (cmd_name[j] >= 'a' && cmd_name[j] <= 'z') {
            cmd_name[j] -= 32;
        }
    }

    if (strcmp_P(cmd_name, PSTR("SETTXT")) == 0) {
        const char *text_start = strchr(cmd, ',');
        if (!text_start) { uart_puts("ERR 2\r\n"); return; }
        text_start++;
        const char *color_str = strchr(text_start, ',');
        if (!color_str) { uart_puts("ERR 2\r\n"); return; }
        char text_buf[49];
        uint8_t text_len = color_str - text_start;
        if (text_len > 48) text_len = 48;
        memcpy(text_buf, text_start, text_len);
        text_buf[text_len] = '\0';
        uint8_t color_val = atoi(color_str + 1);
        if (color_val < 1 || color_val > 3) { uart_puts("ERR 6\r\n"); return; }
        display_set_test(0);
        display_set_text(text_buf, color_val);
        uart_puts("OK\r\n");
    } else if (strcmp_P(cmd_name, PSTR("SETCOL")) == 0) {
        const char *color_str = strchr(cmd, ',');
        if (!color_str) { uart_puts("ERR 2\r\n"); return; }
        uint8_t color_val = atoi(color_str + 1);
        if (color_val < 1 || color_val > 3) { uart_puts("ERR 6\r\n"); return; }
        display_set_color(color_val);
        uart_puts("OK\r\n");
    } else if (strcmp_P(cmd_name, PSTR("SETSCR")) == 0) {
        const char *scroll_str = strchr(cmd, ',');
        if (!scroll_str) { uart_puts("ERR 2\r\n"); return; }
        uint8_t scroll_val = atoi(scroll_str + 1);
        display_set_scroll(scroll_val ? 1 : 0);
        uart_puts("OK\r\n");
    } else if (strcmp_P(cmd_name, PSTR("SETTST")) == 0) {
        const char *tst_str = strchr(cmd, ',');
        if (!tst_str) { uart_puts("ERR 2\r\n"); return; }
        uint8_t tst_val = atoi(tst_str + 1);
        display_set_test(tst_val);
        uart_puts("OK\r\n");
    } else {
        uart_puts("ERR 1\r\n");
    }
}

void display_serial_cmd(void) {
    char buf[UART_RX_SIZE];
    uint8_t i, n;

    if (uart_rx_collect != 2) {
        return;
    }

    cli();
    n = uart_rx_head;
    for (i = 0; i < n && i < sizeof(buf) - 1; i++) {
        buf[i] = uart_rx_buffer[i];
    }
    uart_rx_collect = 0;
    sei();

    buf[i] = '\0';
    if (i > 0) {
        parse_and_execute(buf);
    }
}

int main(void) {
    display_init();

    UCSR0B = (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0);
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
    UBRR0H = (uint8_t)(F_CPU / 16 / 9600 - 1) >> 8;
    UBRR0L = (uint8_t)(F_CPU / 16 / 9600 - 1);

    TCNT0 = 184;
    TIMSK0 |= (1 << TOIE0);
    TCCR0B |= (1 << CS02) | (1 << CS00);

    TCNT2 = 226;
    TIMSK2 |= (1 << TOIE2);
    TCCR2B |= (1 << CS22) | (1 << CS21);

    sei();

    config_load();

    while (1) {
        display_serial_cmd();
        if (test_mode == 3 && newseg_flag) {
            newseg_flag = 0;
            test_col = (test_col + 1) % 16;
        }
        if (test_mode != 0) continue;
        if (scroll_enabled && newseg_flag) {
            newseg_flag = 0;
            display_scroll_text();
        }
    }

    return 0;
}
