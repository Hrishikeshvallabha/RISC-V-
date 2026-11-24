// ============================================================================
// File: uart_assertions.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SVA protocol assertions for UART serial framing and idle discipline.
// ============================================================================

`timescale 1ns / 1ps

module uart_assertions (
    input logic clk,
    input logic rst_n,
    input logic uart_rx,
    input logic uart_tx
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Property: Idle UART TX line must remain 1 when not actively transmitting
    property p_tx_not_x;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(uart_tx);
    endproperty
    assert_tx_not_x: assert property (p_tx_not_x)
        else `uvm_error("SVA_UART", "Assertion Failed: Unknown state (X) on uart_tx!");

    // Property: Idle UART RX line must not be X
    property p_rx_not_x;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(uart_rx);
    endproperty
    assert_rx_not_x: assert property (p_rx_not_x)
        else `uvm_error("SVA_UART", "Assertion Failed: Unknown state (X) on uart_rx!");

endmodule : uart_assertions
