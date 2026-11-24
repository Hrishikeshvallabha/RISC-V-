// ============================================================================
// File: spi_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface for SPI Temperature Sensor.
// ============================================================================

`timescale 1ns / 1ps

interface spi_uvm_if (
    input logic clk,
    input logic rst_n
);

    // Physical SPI boundary nets
    logic spi_clk;   // Clock from DUT master (spi_clk_o)
    logic spi_cs_n;  // Active-low chip select from DUT master (spi_cs_n_o)
    logic spi_mosi;  // Master-out Slave-in from DUT master (spi_mosi_o)
    logic spi_miso;  // Master-in Slave-out driven by UVM slave sensor model into DUT.spi_miso_i
    logic spi_irq;   // Interrupt flag from DUT master (spi_irq_o)

    initial begin
        spi_miso = 1'b0; // Quiescent low
    end

    // Modports
    modport sensor_slave_mp (
        input  clk,
        input  rst_n,
        input  spi_clk,
        input  spi_cs_n,
        input  spi_mosi,
        output spi_miso,
        input  spi_irq
    );

    modport mon_mp (
        input clk,
        input rst_n,
        input spi_clk,
        input spi_cs_n,
        input spi_mosi,
        input spi_miso,
        input spi_irq
    );

endinterface : spi_uvm_if
