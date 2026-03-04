#include <stdio.h>
#include <termios.h>
#include <stddef.h>

int main() {
    printf("TERM_SIZE equ %zu\n", sizeof(struct termios));
    printf("C_LFLAG   equ %zu\n", offsetof(struct termios, c_lflag));
    printf("ICANON_V  equ %u\n", ICANON);
    printf("ECHO_V    equ %u\n", ECHO);
    return 0;
}