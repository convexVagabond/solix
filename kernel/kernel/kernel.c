#include <stdio.h>

#include <kernel/tty.h>
#include "kernel.h"

void kernel_main(void) {
	terminal_initialize();
	printf("Welcome to Solix OS version 0.0.1 pre-alpha\n");
	shutdown();
}

void shutdown() {
	/*
	 * Don't need to make an entire file of asm
	 * Well, unless there's more than 1 function that's completely assembly
	 * Anyways, this function calls the BIOS shutdown interrupt
	 */

	asm("mov $0x1000, %ax;"
	    "mov %ss, %ax;"
	    "mov $0xf000, %sp;"
	    "mov $0x5307, %ax;"
	    "mov $0x0001, %bx;"
	    "mov $0x0003, %cx;"
	    "int $0x15;");
}
