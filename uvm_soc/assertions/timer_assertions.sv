// ============================================================================
// File: timer_assertions.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SVA assertions for Timer outputs.
// ============================================================================

`timescale 1ns / 1ps

module timer_assertions (
    input logic clk,
    input logic rst_n,
    input logic timer_irq,
    input logic timer_pwm,
    input logic timer_trigger
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    property p_timer_outs_not_x;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(timer_irq) && !$isunknown(timer_pwm) && !$isunknown(timer_trigger);
    endproperty
    assert_timer_outs_not_x: assert property (p_timer_outs_not_x)
        else `uvm_error("SVA_TIMER", "Assertion Failed: Unknown state (X) on timer output signals!");

endmodule : timer_assertions
