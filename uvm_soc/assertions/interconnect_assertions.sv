// ============================================================================
// File: interconnect_assertions.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: SVA protocol assertions for AXI4 Master S00 handshakes.
// ============================================================================

`timescale 1ns / 1ps

module interconnect_assertions (
    input logic clk,
    input logic rst_n,
    input logic awvalid,
    input logic awready,
    input logic [31:0] awaddr,
    input logic wvalid,
    input logic wready,
    input logic [31:0] wdata,
    input logic arvalid,
    input logic arready,
    input logic [31:0] araddr
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Property: AWADDR must remain stable while AWVALID is asserted and waiting for AWREADY
    property p_aw_stability;
        @(posedge clk) disable iff (!rst_n)
        (awvalid && $past(awvalid) && !$past(awready)) |-> $stable(awaddr);
    endproperty
    assert_aw_stability: assert property (p_aw_stability)
        else `uvm_error("SVA_AXI", "Assertion Failed: AXI4 AWADDR changed while waiting for AWREADY!");

    // Property: WDATA must remain stable while WVALID is asserted and waiting for WREADY
    property p_w_stability;
        @(posedge clk) disable iff (!rst_n)
        (wvalid && $past(wvalid) && !$past(wready)) |-> $stable(wdata);
    endproperty
    assert_w_stability: assert property (p_w_stability)
        else `uvm_error("SVA_AXI", "Assertion Failed: AXI4 WDATA changed while waiting for WREADY!");

    // Property: ARADDR must remain stable while ARVALID is asserted and waiting for ARREADY
    property p_ar_stability;
        @(posedge clk) disable iff (!rst_n)
        (arvalid && $past(arvalid) && !$past(arready)) |-> $stable(araddr);
    endproperty
    assert_ar_stability: assert property (p_ar_stability)
        else `uvm_error("SVA_AXI", "Assertion Failed: AXI4 ARADDR changed while waiting for ARREADY!");

endmodule : interconnect_assertions
