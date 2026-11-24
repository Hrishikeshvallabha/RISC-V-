// ============================================================================
// Module Name: axi_arbiter_2to1
// Description: Arbitrates between 32-bit LSU (Master 0) and 32-bit IFU (Master 1)
//              onto a single 32-bit AXI4 master interface (connected to S01
//              of the SoC crossbar interconnect).
//              - LSU has dedicated write channel pass-through.
//              - Read address arbitration with fair round-robin when both request.
//              - Clean burst tracking for read responses (rlast).
// ============================================================================

`timescale 1ns / 1ps

module axi_arbiter_2to1 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
)(
    input  wire                  clk,
    input  wire                  rst,

    // ------------------------------------------------------------------------
    // Slave 0: LSU (Read / Write)
    // ------------------------------------------------------------------------
    input  wire                  s0_axi_awvalid,
    output wire                  s0_axi_awready,
    input  wire [ID_WIDTH-1:0]   s0_axi_awid,
    input  wire [ADDR_WIDTH-1:0] s0_axi_awaddr,
    input  wire [3:0]            s0_axi_awregion,
    input  wire [7:0]            s0_axi_awlen,
    input  wire [2:0]            s0_axi_awsize,
    input  wire [1:0]            s0_axi_awburst,
    input  wire                  s0_axi_awlock,
    input  wire [3:0]            s0_axi_awcache,
    input  wire [2:0]            s0_axi_awprot,
    input  wire [3:0]            s0_axi_awqos,

    input  wire                  s0_axi_wvalid,
    output wire                  s0_axi_wready,
    input  wire [DATA_WIDTH-1:0] s0_axi_wdata,
    input  wire [3:0]            s0_axi_wstrb,
    input  wire                  s0_axi_wlast,

    output wire                  s0_axi_bvalid,
    input  wire                  s0_axi_bready,
    output wire [ID_WIDTH-1:0]   s0_axi_bid,
    output wire [1:0]            s0_axi_bresp,

    input  wire                  s0_axi_arvalid,
    output reg                   s0_axi_arready,
    input  wire [ID_WIDTH-1:0]   s0_axi_arid,
    input  wire [ADDR_WIDTH-1:0] s0_axi_araddr,
    input  wire [3:0]            s0_axi_arregion,
    input  wire [7:0]            s0_axi_arlen,
    input  wire [2:0]            s0_axi_arsize,
    input  wire [1:0]            s0_axi_arburst,
    input  wire                  s0_axi_arlock,
    input  wire [3:0]            s0_axi_arcache,
    input  wire [2:0]            s0_axi_arprot,
    input  wire [3:0]            s0_axi_arqos,

    output wire                  s0_axi_rvalid,
    input  wire                  s0_axi_rready,
    output wire [ID_WIDTH-1:0]   s0_axi_rid,
    output wire [DATA_WIDTH-1:0] s0_axi_rdata,
    output wire [1:0]            s0_axi_rresp,
    output wire                  s0_axi_rlast,

    // ------------------------------------------------------------------------
    // Slave 1: IFU (Read Only)
    // ------------------------------------------------------------------------
    input  wire                  s1_axi_arvalid,
    output reg                   s1_axi_arready,
    input  wire [ID_WIDTH-1:0]   s1_axi_arid,
    input  wire [ADDR_WIDTH-1:0] s1_axi_araddr,
    input  wire [3:0]            s1_axi_arregion,
    input  wire [7:0]            s1_axi_arlen,
    input  wire [2:0]            s1_axi_arsize,
    input  wire [1:0]            s1_axi_arburst,
    input  wire                  s1_axi_arlock,
    input  wire [3:0]            s1_axi_arcache,
    input  wire [2:0]            s1_axi_arprot,
    input  wire [3:0]            s1_axi_arqos,

    output wire                  s1_axi_rvalid,
    input  wire                  s1_axi_rready,
    output wire [ID_WIDTH-1:0]   s1_axi_rid,
    output wire [DATA_WIDTH-1:0] s1_axi_rdata,
    output wire [1:0]            s1_axi_rresp,
    output wire                  s1_axi_rlast,

    // ------------------------------------------------------------------------
    // Combined Master Interface (to S01 of AXI Interconnect)
    // ------------------------------------------------------------------------
    output wire                  m_axi_awvalid,
    input  wire                  m_axi_awready,
    output wire [ID_WIDTH-1:0]   m_axi_awid,
    output wire [ADDR_WIDTH-1:0] m_axi_awaddr,
    output wire [3:0]            m_axi_awregion,
    output wire [7:0]            m_axi_awlen,
    output wire [2:0]            m_axi_awsize,
    output wire [1:0]            m_axi_awburst,
    output wire                  m_axi_awlock,
    output wire [3:0]            m_axi_awcache,
    output wire [2:0]            m_axi_awprot,
    output wire [3:0]            m_axi_awqos,

    output wire                  m_axi_wvalid,
    input  wire                  m_axi_wready,
    output wire [DATA_WIDTH-1:0] m_axi_wdata,
    output wire [3:0]            m_axi_wstrb,
    output wire                  m_axi_wlast,

    input  wire                  m_axi_bvalid,
    output wire                  m_axi_bready,
    input  wire [ID_WIDTH-1:0]   m_axi_bid,
    input  wire [1:0]            m_axi_bresp,

    output reg                   m_axi_arvalid,
    input  wire                  m_axi_arready,
    output reg  [ID_WIDTH-1:0]   m_axi_arid,
    output reg  [ADDR_WIDTH-1:0] m_axi_araddr,
    output reg  [3:0]            m_axi_arregion,
    output reg  [7:0]            m_axi_arlen,
    output reg  [2:0]            m_axi_arsize,
    output reg  [1:0]            m_axi_arburst,
    output reg                   m_axi_arlock,
    output reg  [3:0]            m_axi_arcache,
    output reg  [2:0]            m_axi_arprot,
    output reg  [3:0]            m_axi_arqos,

    input  wire                  m_axi_rvalid,
    output reg                   m_axi_rready,
    input  wire [ID_WIDTH-1:0]   m_axi_rid,
    input  wire [DATA_WIDTH-1:0] m_axi_rdata,
    input  wire [1:0]            m_axi_rresp,
    input  wire                  m_axi_rlast
);

    // ------------------------------------------------------------------------
    // Write Channels (Dedicated to LSU)
    // ------------------------------------------------------------------------
    assign m_axi_awvalid  = s0_axi_awvalid;
    assign s0_axi_awready = m_axi_awready;
    assign m_axi_awid     = s0_axi_awid;
    assign m_axi_awaddr   = s0_axi_awaddr;
    assign m_axi_awregion = s0_axi_awregion;
    assign m_axi_awlen    = s0_axi_awlen;
    assign m_axi_awsize   = s0_axi_awsize;
    assign m_axi_awburst  = s0_axi_awburst;
    assign m_axi_awlock   = s0_axi_awlock;
    assign m_axi_awcache  = s0_axi_awcache;
    assign m_axi_awprot   = s0_axi_awprot;
    assign m_axi_awqos    = s0_axi_awqos;

    assign m_axi_wvalid   = s0_axi_wvalid;
    assign s0_axi_wready  = m_axi_wready;
    assign m_axi_wdata    = s0_axi_wdata;
    assign m_axi_wstrb    = s0_axi_wstrb;
    assign m_axi_wlast    = s0_axi_wlast;

    assign s0_axi_bvalid  = m_axi_bvalid;
    assign m_axi_bready   = s0_axi_bready;
    assign s0_axi_bid     = m_axi_bid;
    assign s0_axi_bresp   = m_axi_bresp;

    // ------------------------------------------------------------------------
    // Read Channels Arbitration (Robust Lockable Arbiter)
    // ------------------------------------------------------------------------
    reg active_valid;
    reg active_master; // 0 = LSU, 1 = IFU
    reg addr_done;
    reg round_robin_priority; // 0 = LSU higher priority, 1 = IFU higher priority

    wire req0 = s0_axi_arvalid;
    wire req1 = s1_axi_arvalid;
    wire sel_master = (req0 && req1) ? round_robin_priority : (req0 ? 1'b0 : 1'b1);
    wire cur_master = active_valid ? active_master : sel_master;

    wire ar_handshake_done = m_axi_arvalid && m_axi_arready;
    wire r_handshake_done  = m_axi_rvalid && m_axi_rready && m_axi_rlast;

    // Backward-compatibility monitor wire
    wire [1:0] read_state = active_valid ? (active_master ? 2'b10 : 2'b01) : 2'b00;

    // Address Channel Outputs
    always @(*) begin
        m_axi_arvalid  = active_valid ? (!addr_done) : (req0 || req1);
        s0_axi_arready = (cur_master == 1'b0 && m_axi_arvalid) ? m_axi_arready : 1'b0;
        s1_axi_arready = (cur_master == 1'b1 && m_axi_arvalid) ? m_axi_arready : 1'b0;

        if (cur_master == 1'b0) begin
            m_axi_arid     = s0_axi_arid;
            m_axi_araddr   = s0_axi_araddr;
            m_axi_arregion = s0_axi_arregion;
            m_axi_arlen    = s0_axi_arlen;
            m_axi_arsize   = s0_axi_arsize;
            m_axi_arburst  = s0_axi_arburst;
            m_axi_arlock   = s0_axi_arlock;
            m_axi_arcache  = s0_axi_arcache;
            m_axi_arprot   = s0_axi_arprot;
            m_axi_arqos    = s0_axi_arqos;
        end else begin
            m_axi_arid     = s1_axi_arid;
            m_axi_araddr   = s1_axi_araddr;
            m_axi_arregion = s1_axi_arregion;
            m_axi_arlen    = s1_axi_arlen;
            m_axi_arsize   = s1_axi_arsize;
            m_axi_arburst  = s1_axi_arburst;
            m_axi_arlock   = s1_axi_arlock;
            m_axi_arcache  = s1_axi_arcache;
            m_axi_arprot   = s1_axi_arprot;
            m_axi_arqos    = s1_axi_arqos;
        end
    end

    // Read Data Channel Demuxing
    assign s0_axi_rvalid = (active_valid && active_master == 1'b0) ? m_axi_rvalid : 1'b0;
    assign s0_axi_rid    = m_axi_rid;
    assign s0_axi_rdata  = m_axi_rdata;
    assign s0_axi_rresp  = m_axi_rresp;
    assign s0_axi_rlast  = m_axi_rlast;

    assign s1_axi_rvalid = (active_valid && active_master == 1'b1) ? m_axi_rvalid : 1'b0;
    assign s1_axi_rid    = m_axi_rid;
    assign s1_axi_rdata  = m_axi_rdata;
    assign s1_axi_rresp  = m_axi_rresp;
    assign s1_axi_rlast  = m_axi_rlast;

    always @(*) begin
        if (active_valid && active_master == 1'b0)
            m_axi_rready = s0_axi_rready;
        else if (active_valid && active_master == 1'b1)
            m_axi_rready = s1_axi_rready;
        else
            m_axi_rready = 1'b0;
    end

    // Sequential Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_valid         <= 1'b0;
            active_master        <= 1'b0;
            addr_done            <= 1'b0;
            round_robin_priority <= 1'b0;
        end else begin
            if (!active_valid) begin
                if (req0 || req1) begin
                    if (ar_handshake_done && r_handshake_done) begin
                        active_valid         <= 1'b0;
                        addr_done            <= 1'b0;
                        round_robin_priority <= ~sel_master;
                    end else if (ar_handshake_done) begin
                        active_valid         <= 1'b1;
                        active_master        <= sel_master;
                        addr_done            <= 1'b1;
                        round_robin_priority <= ~sel_master;
                    end else begin
                        active_valid         <= 1'b1;
                        active_master        <= sel_master;
                        addr_done            <= 1'b0;
                        round_robin_priority <= ~sel_master;
                    end
                end
            end else begin
                if (ar_handshake_done) begin
                    addr_done <= 1'b1;
                end
                if (r_handshake_done) begin
                    active_valid <= 1'b0;
                    addr_done    <= 1'b0;
                end
            end
        end
    end

endmodule
