// ============================================================================
// File: veer_trace_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface observing VeeR EL2 core trace bus.
// ============================================================================

`timescale 1ns / 1ps

interface veer_trace_uvm_if (
    input logic clk,
    input logic rst_n
);

    logic [31:0] insn;
    logic [31:0] address;
    logic        valid;
    logic        exception;
    logic [4:0]  ecause;
    logic        interrupt;
    logic [31:0] tval;

endinterface : veer_trace_uvm_if
