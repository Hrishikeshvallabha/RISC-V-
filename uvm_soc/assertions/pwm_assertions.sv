// ============================================================================
// File: pwm_assertions.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SVA assertions for PWM fan output waveform integrity.
// ============================================================================

`timescale 1ns / 1ps

module pwm_assertions (
    input logic clk,
    input logic rst_n,
    input logic pwm_out
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    property p_pwm_not_x;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(pwm_out);
    endproperty
    assert_pwm_not_x: assert property (p_pwm_not_x)
        else `uvm_error("SVA_PWM", "Assertion Failed: Unknown state (X) on pwm_out!");

endmodule : pwm_assertions
