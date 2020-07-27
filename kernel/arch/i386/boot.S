.global bootstrap_ia32
.section .data
.align 0x1000
_kernel_pd:
	.space 0x1000, 0x00
_kernel_pt:
	.space 0x1000, 0x00
_kernel_low_pt:
	.space 0x1000, 0x00
.set INITSTACKSIZE, 0x10000
initstack:
	.space INITSTACKSIZE, 0x00
_msg_panic:
	.asciz "PANIC!"
.section .text
.code32
.set ALIGN,         1<<0             # align loaded modules on page boundaries
.set MEMINFO,       1<<1             # provide memory map
.set FLAGS,         ALIGN | MEMINFO  # this is the Multiboot 'flag' field
.set MAGIC,         0x1BADB002       # 'magic number' lets bootloader find the header
.set CHECKSUM,      -(MAGIC + FLAGS) # checksum required

.align 4

multiboot_header:
	.long MAGIC
	.long FLAGS
	.long CHECKSUM

.set VIDEO_RAM, 0xB8000
.set VIDEO_DWORDS, 0x3E8

bootstrap_ia32:	
	mov $(initstack + INITSTACKSIZE), %esp
	subl $KERNEL_HIGH_VMA, %esp
	call init_boot_paging_ia32
	addl $KERNEL_HIGH_VMA, %esp
	mov %esp, %ebp
	mov $VIDEO_RAM, %edi
	mov $VIDEO_DWORDS, %ecx
	mov $0x07200720, %eax
	rep stosl
	push %eax
	push %ebx
	call kernel_main

the_end:
	mov $_msg_panic, %eax
	call boot_print_msg
	cli
	hlt

boot_print_msg:
	push %edx
	push %ebx
	mov $VIDEO_RAM, %edx
	_print_loop:
		movb (%eax), %bl
		xorb %bh, %bh
		cmpb $0x0, %bl
		je _end_print
		orw $0x4F00, %bx
		movw %bx, (%edx)
		add $0x2, %edx
		inc %eax
		jmp _print_loop
	_end_print:

	pop %ebx
	pop %edx

init_boot_paging_ia32:
	push %eax
	push %ebx
	push %edx
	push %ecx
	mov $_kernel_pd, %eax
	sub $KERNEL_HIGH_VMA, %eax
	mov $_kernel_low_pt, %ebx
	sub $KERNEL_HIGH_VMA, %ebx
	or $0x1, %ebx
	mov %ebx, (%eax)
	push %eax
	mov $KERNEL_HIGH_VMA, %eax
	shr $22, %eax
	mov $4, %ecx
	mul %ecx
	mov %eax, %edx
	pop %eax
	push %eax
	add %edx, %eax
	mov $_kernel_pt, %ebx
	sub $KERNEL_HIGH_VMA, %ebx
	or $0x1, %ebx
	mov %ebx, (%eax)
	pop %ebx
	mov $0x100000, %ecx
	_idmap_first_mb_loop:
		mov %ecx, %edx
		call boot_map_page_ia32
		sub $0x1000, %ecx
		jnz _idmap_first_mb_loop
	mov $KERNEL_BOOT_VMA, %ecx
	mov $_core_end, %eax
	sub $KERNEL_HIGH_VMA, %eax
	_map_kernel:	
		mov %ecx, %edx
		call boot_map_page_ia32
		push %ecx
		add $KERNEL_HIGH_VMA, %ecx
		call boot_map_page_ia32
		pop %ecx
		add $0x1000, %ecx
		cmp %eax, %ecx
		jle _map_kernel
	mov %ebx, %cr3
	mov %cr0, %eax
	or $(1 << 31), %eax
	mov %eax, %cr0
	pop %ecx
	pop %edx
	pop %ebx
	pop %eax
	ret

boot_map_page_ia32:
	push %eax
	push %ebx
	push %ecx
	push %edx
	push %edx
	push %ecx
	mov %ecx, %eax
	shr $22, %eax
	mov $4, %ecx
	mul %ecx
	add %eax, %ebx
	mov (%ebx), %eax
	mov %eax, %ecx
	and $0x1, %ecx
	cmp $0x0, %ecx
	je the_end
	and $0xFFFFF000, %eax
	pop %edx
	push %eax
	mov %edx, %eax
	shr $0xC, %eax
	and $0x3FF, %eax
	mov $0x4, %ecx
	mul %ecx
	mov %eax, %ebx
	pop %eax
	pop %edx
	add %ebx, %eax
	or $0x1, %edx
	mov %edx, (%eax)
	pop %edx
	pop %ecx
	pop %ebx
	pop %eax
	ret
	
