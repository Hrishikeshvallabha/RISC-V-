// ============================================================================
// File: uart_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface for 16550 UART subsystem.
// ============================================================================

`timescale 1ns / 1ps

interface uart_uvm_if (
    input logic clk,
    input logic rst_n
);

    // Physical UART Pins
    logic uart_rx;        // Driven by TB/UVM driver into DUT.uart_rx_i
    wire  uart_tx;        // Driven by DUT.uart_tx_o
    wire  uart_interrupt; // Driven by DUT.uart_interrupt_o

    // Initial passive drive
    initial begin
        uart_rx = 1'b1; // UART idle high
    end

    // Modports
    modport drv_mp (
        input  clk,
        input  rst_n,
        output uart_rx,
        input  uart_tx,
        input  uart_interrupt
    );

    modport mon_mp (
        input clk,
        input rst_n,
        input uart_rx,
        input uart_tx,
        input uart_interrupt
    );

endinterface : uart_uvm_if
