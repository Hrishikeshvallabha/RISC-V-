// ============================================================================
// File: start.S
// Description: Minimal CRT0 assembly startup for VeeR EL2 RISC-V core.
//              - Placed at reset vector 0x0000_0000 (.text.init section)
//              - Disables interrupts and configures MRAC CSR (0x7C0)
//              - Configures Machine Trap Vector (mtvec)
//              - Initializes stack pointer (sp) and global pointer (gp)
//              - Clears BSS segment
//              - Jumps to C entry point main()
//              - Handles graceful return / halt loop and default trap handler
// ============================================================================

    .section .text.init, "ax", @progbits
    .global _start
    .type _start, @function

_start:
    // 1. Disable all interrupts during early boot
    csrw mstatus, zero
    csrw mie, zero

    // 2. Configure Memory Region Attributes (MRAC: CSR 0x7C0)
    // Region 0 (0x0000_0000): Uncacheable memory ({side_effect=0, cacheable=0} = 2'b00)
    // Region 4 (0x4000_0000 MMIO): Non-idempotent side-effects ({side_effect=1, cacheable=0} = 2'b10)
    // Value: 0x00000200 (Bit 9 = 1)
    li t0, 0x00000200
    csrw 0x7c0, t0

    // 3. Configure Machine Trap Vector (mtvec)
    la t0, default_trap_handler
    csrw mtvec, t0

    // 4. Initialize Global Pointer (gp) with linker-defined relaxation symbol
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    // 5. Initialize Stack Pointer (sp) to top of Unified 64 KiB Memory
    la sp, _stack_top

    // 6. Clear BSS section (zero-fill uninitialized global variables)
    la t0, _bss_start
    la t1, _bss_end
    bgeu t0, t1, 2f

1:
    sw zero, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, 1b

2:
    // 7. Jump to bare-metal C main function
    call main

    // 8. Trap loop if main() returns
halt_loop:
    wfi
    j halt_loop

    .size _start, . - _start

// ============================================================================
// Default Trap Handler (Exceptions and Interrupts)
// ============================================================================
    .section .text, "ax", @progbits
    .align 4
    .global default_trap_handler
    .type default_trap_handler, @function
default_trap_handler:
    // Check if interrupt or synchronous exception
    csrr t0, mcause
    bgez t0, 1f     // Positive = exception, Negative (bit 31=1) = interrupt

    // Interrupt handling: return immediately
    mret

1:
    // Synchronous exception (e.g., bus DECERR on unmapped access):
    // Advance mepc past the faulting 4-byte instruction to resume execution
    csrr t1, mepc
    addi t1, t1, 4
    csrw mepc, t1
    mret

    .size default_trap_handler, . - default_trap_handler
