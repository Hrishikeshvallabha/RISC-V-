// ============================================================================
// File: display_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface for Seven-Segment Display subsystem.
// ============================================================================

`timescale 1ns / 1ps

interface display_uvm_if (
    input logic clk,
    input logic rst_n
);

    wire [6:0] seg; // Cathode segment lines (a..g) from DUT.seg
    wire [3:0] an;  // Active-low anode lines (AN3..AN0) from DUT.an

    modport mon_mp (
        input clk,
        input rst_n,
        input seg,
        input an
    );

endinterface : display_uvm_if
