// ============================================================================
// File: pwm_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface for PWM Fan Controller subsystem.
// ============================================================================

`timescale 1ns / 1ps

interface pwm_uvm_if (
    input logic clk,
    input logic rst_n
);

    wire pwm_out; // Driven by DUT.pwm_out_o
    wire pwm_irq; // Driven by DUT.pwm_irq_o

    modport mon_mp (
        input clk,
        input rst_n,
        input pwm_out,
        input pwm_irq
    );

endinterface : pwm_uvm_if
