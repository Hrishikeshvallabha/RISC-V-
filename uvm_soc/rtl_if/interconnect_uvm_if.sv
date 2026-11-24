// ============================================================================
// File: interconnect_uvm_if.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SystemVerilog static interface for AXI4 Master Port S00.
// ============================================================================

`timescale 1ns / 1ps

interface interconnect_uvm_if #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 32,
    parameter int ID_WIDTH   = 8
)(
    input logic clk,
    input logic rst_n
);

    // Write Address Channel (AW)
    logic [ID_WIDTH-1:0]   awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0]            awlen;
    logic [2:0]            awsize;
    logic [1:0]            awburst;
    logic                  awlock;
    logic [3:0]            awcache;
    logic [2:0]            awprot;
    logic [3:0]            awqos;
    logic                  awvalid;
    wire                   awready;

    // Write Data Channel (W)
    logic [DATA_WIDTH-1:0] wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                  wlast;
    logic                  wvalid;
    wire                   wready;

    // Write Response Channel (B)
    wire  [ID_WIDTH-1:0]   bid;
    wire  [1:0]            bresp;
    wire                   bvalid;
    logic                  bready;

    // Read Address Channel (AR)
    logic [ID_WIDTH-1:0]   arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0]            arlen;
    logic [2:0]            arsize;
    logic [1:0]            arburst;
    logic                  arlock;
    logic [3:0]            arcache;
    logic [2:0]            arprot;
    logic [3:0]            arqos;
    logic                  arvalid;
    wire                   arready;

    // Read Data Channel (R)
    wire  [ID_WIDTH-1:0]   rid;
    wire  [DATA_WIDTH-1:0] rdata;
    wire  [1:0]            rresp;
    wire                   rlast;
    wire                   rvalid;
    logic                  rready;

    initial begin
        awid    = '0;
        awaddr  = '0;
        awlen   = '0;
        awsize  = 3'b010; // 4 bytes
        awburst = 2'b01;  // INCR
        awlock  = 1'b0;
        awcache = 4'b0010;
        awprot  = 3'b000;
        awqos   = 4'b0000;
        awvalid = 1'b0;

        wdata   = '0;
        wstrb   = '0;
        wlast   = 1'b0;
        wvalid  = 1'b0;
        bready  = 1'b1;

        arid    = '0;
        araddr  = '0;
        arlen   = '0;
        arsize  = 3'b010;
        arburst = 2'b01;
        arlock  = 1'b0;
        arcache = 4'b0010;
        arprot  = 3'b000;
        arqos   = 4'b0000;
        arvalid = 1'b0;
        rready  = 1'b1;
    end

    modport drv_mp (
        input  clk,
        input  rst_n,
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awvalid,
        input  awready,
        output wdata, wstrb, wlast, wvalid,
        input  wready,
        input  bid, bresp, bvalid,
        output bready,
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arvalid,
        input  arready,
        input  rid, rdata, rresp, rlast, rvalid,
        output rready
    );

    modport mon_mp (
        input clk, rst_n,
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awvalid, awready,
        input wdata, wstrb, wlast, wvalid, wready,
        input bid, bresp, bvalid, bready,
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arvalid, arready,
        input rid, rdata, rresp, rlast, rvalid, rready
    );

endinterface : interconnect_uvm_if
