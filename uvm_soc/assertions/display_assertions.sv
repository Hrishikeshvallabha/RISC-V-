// ============================================================================
// File: display_assertions.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SVA assertions for Seven-Segment multiplexed scanning integrity.
// ============================================================================

`timescale 1ns / 1ps

module display_assertions (
    input logic clk,
    input logic rst_n,
    input logic [6:0] seg,
    input logic [3:0] an
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Property: Exactly one anode active low when scanning (one-cold encoding)
    property p_one_cold_anode;
        @(posedge clk) disable iff (!rst_n)
        (an != 4'b1111) |-> ($countones(an) == 3);
    endproperty
    assert_one_cold_anode: assert property (p_one_cold_anode)
        else `uvm_error("SVA_DISP", "Assertion Failed: Anode multiplexing violation! Not one-cold encoded.");

    // Property: No unknown states on display output pins
    property p_display_not_x;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(an) && !$isunknown(seg);
    endproperty
    assert_display_not_x: assert property (p_display_not_x)
        else `uvm_error("SVA_DISP", "Assertion Failed: Unknown state (X) on display outputs!");

endmodule : display_assertions
