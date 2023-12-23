OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    rom (xr) : ORIGIN = 0x00000000, LENGTH = 16K
    ram (xrw) : ORIGIN = 0x00004000, LENGTH = 112K
}

SECTIONS
{
    .text 0x00004000 : {
        KEEP(*(.text.boot))
        *(.text*)
    } > ram AT > ram
    .rodata : {
        . = ALIGN(8);
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(8);
    } > ram AT > ram
    .data : {
        . = ALIGN(8);
        *(.sdata*)
        *(.data*)
        . = ALIGN(8);
    } > ram AT > ram
    .bss : {
        . = ALIGN(8);
        _bss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        _bss_end = .;
    } > ram AT > ram

    .kstack : {
        . = ALIGN(16);
        . += 4K;
        _stack_start = .;
    } > ram AT > ram

    .trap_kstack : {
        . = ALIGN(16);
        . += 4K;
        _trap_stack_start = .;
    } > ram AT > ram

    /DISCARD/ : { *(.comment .note .eh_frame) }
}