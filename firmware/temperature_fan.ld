/* ============================================================================
 * Linker Script: temperature_fan.ld
 * Description: Memory layout for VeeR EL2 Unified Instruction & Data Memory
 *              Total capacity: 64 KiB (0x0000_0000 - 0x0000_FFFF)
 * ============================================================================ */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    /* Code and CRT0 entry point at reset vector 0x0000_0000 */
    .text : ALIGN(4)
    {
        _text_start = .;
        *(.text.init)
        *(.text .text.*)
        *(.gnu.linkonce.t.*)
        . = ALIGN(4);
        _text_end = .;
    } > RAM

    /* Read-only data (constants, string literals) */
    .rodata : ALIGN(4)
    {
        _rodata_start = .;
        *(.rodata .rodata.*)
        *(.gnu.linkonce.r.*)
        *(.srodata .srodata.*)
        . = ALIGN(4);
        _rodata_end = .;
    } > RAM

    /* Initialized data */
    .data : ALIGN(4)
    {
        _data_start = .;
        __data_begin$ = .;
        *(.data .data.*)
        *(.gnu.linkonce.d.*)
        *(.sdata .sdata.*)
        . = ALIGN(4);
        _data_end = .;
    } > RAM

    /* Global pointer relaxation reference */
    __global_pointer$ = MIN(_data_start + 0x800, _data_end);

    /* Zero-initialized BSS segment */
    .bss : ALIGN(4)
    {
        _bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM

    /* Heap area placeholder */
    . = ALIGN(8);
    _heap_start = .;
    _heap_end = ORIGIN(RAM) + LENGTH(RAM) - 0x800; /* Leave 2 KiB for Stack */

    /* Stack top at the very peak of 64 KiB Unified Memory */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM) - 4; /* 0x0000FFFC */

    /* Discard unused metadata sections */
    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
        *(.riscv.attributes)
    }
}
