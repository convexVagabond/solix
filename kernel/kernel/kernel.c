#include <stdio.h>

#include <kernel/tty.h>

void kernel_main(void) {
	terminal_initialize();
	printf("Welcome to Solix OS version 0.0.1 pre-alpha\n");
}
