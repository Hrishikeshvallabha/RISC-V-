// ============================================================================
// File: gpio_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface for GPIO subsystem.
//              Provides physical pin connections to the DUT and signal
//              handles for the dynamic UVM driver and monitor.
// ============================================================================

`timescale 1ns / 1ps

interface gpio_uvm_if #(
    parameter int NUM_BITS = 32
)(
    input logic clk,
    input logic rst_n
);

    // ------------------------------------------------------------------------
    // Physical Bidirectional Bus (connected to DUT boundary gpio_io)
    // ------------------------------------------------------------------------
    wire [NUM_BITS-1:0] gpio_io;
    logic               gpio_intr;

    // ------------------------------------------------------------------------
    // Dynamic UVM Driver Control Nets
    // ------------------------------------------------------------------------
    logic [NUM_BITS-1:0] gpio_in;        // Stimulus value driven into the DUT
    logic [NUM_BITS-1:0] gpio_drive_en;  // 1 = Driver active, 0 = High-Z (release)

    // ------------------------------------------------------------------------
    // Continuous Tri-state Drive to Physical Boundary Net
    // ------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < NUM_BITS; i = i + 1) begin : gen_gpio_drv
            assign gpio_io[i] = gpio_drive_en[i] ? gpio_in[i] : 1'bz;
        end
    endgenerate

    // ------------------------------------------------------------------------
    // Continuous Sampling Net (Passive observation of physical pins)
    // ------------------------------------------------------------------------
    logic [NUM_BITS-1:0] gpio_sampled;
    assign gpio_sampled = gpio_io;

    // ------------------------------------------------------------------------
    // Driver Clocking Block (Synchronous interface timing)
    // ------------------------------------------------------------------------
    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output gpio_in;
        output gpio_drive_en;
        input  gpio_sampled;
    endclocking

    // ------------------------------------------------------------------------
    // Monitor Clocking Block (Synchronous passive observation)
    // ------------------------------------------------------------------------
    clocking mon_cb @(posedge clk);
        default input #1ns;
        input gpio_sampled;
    endclocking

    // Modport declarations
    modport drv_mp (
        clocking drv_cb,
        input clk,
        input rst_n
    );

    modport mon_mp (
        clocking mon_cb,
        input clk,
        input rst_n
    );

endinterface : gpio_uvm_if
