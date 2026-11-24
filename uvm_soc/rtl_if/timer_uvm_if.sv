// ============================================================================
// File: timer_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface for Hardware Timer subsystem.
// ============================================================================

`timescale 1ns / 1ps

interface timer_uvm_if (
    input logic clk,
    input logic rst_n
);

    logic timer_ext_meas; // Driven by driver to DUT.timer_ext_meas_i
    logic timer_capture;  // Driven by driver to DUT.timer_capture_i
    wire  timer_pwm;      // Output from DUT.timer_pwm_o
    wire  timer_trigger;  // Output from DUT.timer_trigger_o
    wire  timer_irq;      // Output from DUT.timer_irq_o

    initial begin
        timer_ext_meas = 1'b0;
        timer_capture  = 1'b0;
    end

    modport drv_mp (
        input  clk,
        input  rst_n,
        output timer_ext_meas,
        output timer_capture,
        input  timer_pwm,
        input  timer_trigger,
        input  timer_irq
    );

    modport mon_mp (
        input clk,
        input rst_n,
        input timer_ext_meas,
        input timer_capture,
        input timer_pwm,
        input timer_trigger,
        input timer_irq
    );

endinterface : timer_uvm_if
