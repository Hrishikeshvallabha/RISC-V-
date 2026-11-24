// ============================================================================
// File: spi_assertions.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SVA protocol assertions for SPI Mode 0 master-slave transfers.
// ============================================================================

`timescale 1ns / 1ps

module spi_assertions (
    input logic clk,
    input logic rst_n,
    input logic spi_clk,
    input logic spi_cs_n,
    input logic spi_mosi,
    input logic spi_miso
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Property: SPI Clock must be idle LOW when CS# transitions LOW (Mode 0 requirement)
    property p_cpol_idle_low;
        @(negedge spi_cs_n) disable iff (!rst_n)
        (spi_clk == 1'b0);
    endproperty
    assert_cpol_idle_low: assert property (p_cpol_idle_low)
        else `uvm_error("SVA_SPI", "Assertion Failed: SPI Mode 0 violation! spi_clk is not LOW when cs_n asserted!");

    // Property: No unknown states on SPI bus signals
    property p_spi_signals_not_x;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(spi_cs_n) && !$isunknown(spi_clk);
    endproperty
    assert_spi_signals_not_x: assert property (p_spi_signals_not_x)
        else `uvm_error("SVA_SPI", "Assertion Failed: Unknown state (X) on spi_cs_n or spi_clk!");

endmodule : spi_assertions
