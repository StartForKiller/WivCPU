OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    rom (xr) : ORIGIN = 0x00000000, LENGTH = 16K
    ram (xrw) : ORIGIN = 0x00004000, LENGTH = 112K
}

SECTIONS
{
    . = 0x4000;
    .text.init : { *(.text.init) }
    . = ALIGN(0x1000);
    .tohost : { *(.tohost) }
    . = ALIGN(0x1000);
    .text : { *(.text) }
    . = ALIGN(0x1000);
    .data : { *(.data) }
    .bss : { *(.bss) }
    _end = .;
}