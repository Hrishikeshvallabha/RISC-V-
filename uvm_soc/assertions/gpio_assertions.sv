// ============================================================================
// File: gpio_assertions.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog Assertions (SVA) verifying GPIO protocol timing,
//              synchronization latency, and bus contention prevention.
// ============================================================================

`timescale 1ns / 1ps

module gpio_assertions #(
    parameter int NUM_BITS = 32
)(
    input  logic                clk,
    input  logic                rst_n,
    input  logic [NUM_BITS-1:0] drive_en,
    input  logic [NUM_BITS-1:0] drive_data,
    input  wire  [NUM_BITS-1:0] pad_io,
    input  logic [NUM_BITS-1:0] dut_gpio_i
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ------------------------------------------------------------------------
    // Property 1: No Unknown (X) States on Driven Bus
    // ------------------------------------------------------------------------
    property p_no_x_on_driven_pad;
        @(posedge clk) disable iff (!rst_n)
        (drive_en == {NUM_BITS{1'b1}}) |-> !$isunknown(pad_io);
    endproperty
    assert_no_x_on_driven_pad: assert property (p_no_x_on_driven_pad)
        else `uvm_error("SVA_GPIO", "Assertion Failed: Unknown state (X) detected on driven GPIO pad!");

    // ------------------------------------------------------------------------
    // Property 2: Pad Follows Stimulus When Driver Active
    // ------------------------------------------------------------------------
    property p_pad_follows_driver;
        @(posedge clk) disable iff (!rst_n)
        (drive_en == {NUM_BITS{1'b1}}) |-> (pad_io === drive_data);
    endproperty
    assert_pad_follows_driver: assert property (p_pad_follows_driver)
        else `uvm_error("SVA_GPIO", "Assertion Failed: GPIO pad does not match driver output!");

    // ------------------------------------------------------------------------
    // Property 3: 2-Cycle Input Synchronizer Latency
    // ------------------------------------------------------------------------
    property p_sync_latency_2_cycles;
        logic [NUM_BITS-1:0] expected_val;
        @(posedge clk) disable iff (!rst_n)
        (drive_en == {NUM_BITS{1'b1}}, expected_val = drive_data) ##2 (drive_en == {NUM_BITS{1'b1}} && drive_data == expected_val) |->
            ##1 (dut_gpio_i === expected_val);
    endproperty
    assert_sync_latency_2_cycles: assert property (p_sync_latency_2_cycles)
        else `uvm_error("SVA_GPIO", "Assertion Failed: DUT internal synchronizer failed 2-cycle latency check!");

endmodule : gpio_assertions
