`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Module: axi4lite_slave_adapter
// Description:
//   Synthesizable AXI4-Lite Slave Adapter for register block interfaces.
//   Translates AXI4-Lite AW/W/B and AR/R channel transactions into simple
//   internal synchronous register accesses (addr, wdata, rdata, we, re, be).
//
// Features:
//   - Fully independent AW and W channel handshaking:
//     * Simultaneous AW and W
//     * AW before W (arbitrary cycle delay)
//     * W before AW (arbitrary cycle delay)
//   - Clean registered read and write stages.
//   - Zero combinational loop hazards.
//   - Compatible with VCS and Vivado.
// ============================================================================

module axi4lite_slave_adapter #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic                    aclk,
    input  logic                    aresetn,

    // AXI4-Lite Write Address Channel
    input  logic [ADDR_WIDTH-1:0]   s_axi_awaddr,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [2:0]              s_axi_awprot,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic                    s_axi_awvalid,
    output logic                    s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  logic [DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  logic                    s_axi_wvalid,
    output logic                    s_axi_wready,

    // AXI4-Lite Write Response Channel
    output logic [1:0]              s_axi_bresp,
    output logic                    s_axi_bvalid,
    input  logic                    s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  logic [ADDR_WIDTH-1:0]   s_axi_araddr,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [2:0]              s_axi_arprot,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic                    s_axi_arvalid,
    output logic                    s_axi_arready,

    // AXI4-Lite Read Data Channel
    output logic [DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [1:0]              s_axi_rresp,
    output logic                    s_axi_rvalid,
    input  logic                    s_axi_rready,

    // Internal Register Bus Interface
    output logic [ADDR_WIDTH-1:0]   reg_addr,
    output logic [DATA_WIDTH-1:0]   reg_wdata,
    input  logic [DATA_WIDTH-1:0]   reg_rdata,
    output logic                    reg_we,
    output logic                    reg_re,
    output logic [DATA_WIDTH/8-1:0] reg_be
);

    // ------------------------------------------------------------------------
    // Write Channel Logic
    // ------------------------------------------------------------------------
    logic [ADDR_WIDTH-1:0]   awaddr_latched;
    logic [DATA_WIDTH-1:0]   wdata_latched;
    logic [DATA_WIDTH/8-1:0] wstrb_latched;
    logic                    aw_done;
    logic                    w_done;
    logic                    wr_active;

    // Detect handshake occurrences on current cycle
    wire aw_hs = s_axi_awvalid && s_axi_awready;
    wire w_hs  = s_axi_wvalid  && s_axi_wready;

    // A write operation commits when both address and data are present
    wire write_commit = (aw_done || aw_hs) && (w_done || w_hs) && !s_axi_bvalid && !wr_active;

    wire [ADDR_WIDTH-1:0]   effective_awaddr = aw_done ? awaddr_latched : s_axi_awaddr;
    wire [DATA_WIDTH-1:0]   effective_wdata  = w_done  ? wdata_latched  : s_axi_wdata;
    wire [DATA_WIDTH/8-1:0] effective_wstrb  = w_done  ? wstrb_latched  : s_axi_wstrb;

    // ------------------------------------------------------------------------
    // Read Channel Logic
    // ------------------------------------------------------------------------
    logic read_pending;
    logic [ADDR_WIDTH-1:0] araddr_latched;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_awready  <= 1'b1;
            s_axi_wready   <= 1'b1;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
            wr_active      <= 1'b0;
            awaddr_latched <= '0;
            wdata_latched  <= '0;
            wstrb_latched  <= '0;
            reg_we         <= 1'b0;
            reg_addr       <= '0;
            reg_wdata      <= '0;
            reg_be         <= '0;

            s_axi_arready  <= 1'b1;
            s_axi_rvalid   <= 1'b0;
            s_axi_rdata    <= '0;
            s_axi_rresp    <= 2'b00;
            reg_re         <= 1'b0;
            read_pending   <= 1'b0;
            araddr_latched <= '0;
        end else begin
            // ----------------------------------------------------------------
            // Write Processing
            // ----------------------------------------------------------------
            // Clear single-cycle write strobe
            if (reg_we) begin
                reg_we    <= 1'b0;
                wr_active <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end

            // AW channel handshake
            if (aw_hs) begin
                awaddr_latched <= s_axi_awaddr;
                if (!write_commit) begin
                    aw_done       <= 1'b1;
                    s_axi_awready <= 1'b0;
                end
            end

            // W channel handshake
            if (w_hs) begin
                wdata_latched <= s_axi_wdata;
                wstrb_latched <= s_axi_wstrb;
                if (!write_commit) begin
                    w_done       <= 1'b1;
                    s_axi_wready <= 1'b0;
                end
            end

            // Commit write to register block
            if (write_commit) begin
                reg_addr      <= effective_awaddr;
                reg_wdata     <= effective_wdata;
                reg_be        <= effective_wstrb;
                reg_we        <= 1'b1;
                wr_active     <= 1'b1;
                aw_done       <= 1'b0;
                w_done        <= 1'b0;
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            // Complete write response
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid  <= 1'b0;
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
            end

            // ----------------------------------------------------------------
            // Read Processing
            // ----------------------------------------------------------------
            reg_re <= 1'b0;

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_arready  <= 1'b0;
                araddr_latched <= s_axi_araddr;
                reg_addr       <= s_axi_araddr;
                reg_re         <= 1'b1;
                read_pending   <= 1'b1;
            end else if (read_pending) begin
                read_pending <= 1'b0;
                s_axi_rdata  <= reg_rdata;
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
