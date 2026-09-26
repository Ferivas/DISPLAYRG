#ifndef FONTS_H
#define FONTS_H

#include <avr/pgmspace.h>

#define FONT_WIDTH 5
#define NUM_CHARS 64

extern const uint8_t font[][FONT_WIDTH] PROGMEM;

static const uint8_t valid_chars[] = {
    '0','1','2','3','4','5','6','7','8','9',
    'A','B','C','D','E','F','G','H','I','J',
    'K','L','M','N','O','P','Q','R','S','T',
    'U','V','W','X','Y','Z',' ','.',
    'a','b','c','d','e','f','g','h','i','j',
    'k','l','m','n','o','p','q','r','s','t',
    'u','v','w','x','y','z'
};

uint8_t char_to_index(uint8_t c);

#endif
