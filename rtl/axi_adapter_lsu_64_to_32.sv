// ============================================================================
// Module Name: axi_adapter_lsu_64_to_32
// Description: Translates 64-bit AXI4 LSU interface from VeeR EL2 core
//              to 32-bit AXI4 interface.
//              - In RV32, all LSU transfers are <= 32 bits.
//              - Steers 32-bit write data based on awaddr[2] & wstrb[7:0].
//              - Clamps awsize/arsize to 32 bits (<= 3'b010).
//              - Replicates 32-bit read data to both lower and upper 32-bit
//                halves of the 64-bit bus ({2{m_axi_rdata}}).
// ============================================================================

`timescale 1ns / 1ps

module axi_adapter_lsu_64_to_32 #(
    parameter ID_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,

    // ------------------------------------------------------------------------
    // Slave Interface (from VeeR EL2 64-bit LSU)
    // ------------------------------------------------------------------------
    input  wire                  s_axi_awvalid,
    output wire                  s_axi_awready,
    input  wire [ID_WIDTH-1:0]   s_axi_awid,
    input  wire [31:0]           s_axi_awaddr,
    input  wire [3:0]            s_axi_awregion,
    input  wire [7:0]            s_axi_awlen,
    input  wire [2:0]            s_axi_awsize,
    input  wire [1:0]            s_axi_awburst,
    input  wire                  s_axi_awlock,
    input  wire [3:0]            s_axi_awcache,
    input  wire [2:0]            s_axi_awprot,
    input  wire [3:0]            s_axi_awqos,

    input  wire                  s_axi_wvalid,
    output wire                  s_axi_wready,
    input  wire [63:0]           s_axi_wdata,
    input  wire [7:0]            s_axi_wstrb,
    input  wire                  s_axi_wlast,

    output wire                  s_axi_bvalid,
    input  wire                  s_axi_bready,
    output wire [ID_WIDTH-1:0]   s_axi_bid,
    output wire [1:0]            s_axi_bresp,

    input  wire                  s_axi_arvalid,
    output wire                  s_axi_arready,
    input  wire [ID_WIDTH-1:0]   s_axi_arid,
    input  wire [31:0]           s_axi_araddr,
    input  wire [3:0]            s_axi_arregion,
    input  wire [7:0]            s_axi_arlen,
    input  wire [2:0]            s_axi_arsize,
    input  wire [1:0]            s_axi_arburst,
    input  wire                  s_axi_arlock,
    input  wire [3:0]            s_axi_arcache,
    input  wire [2:0]            s_axi_arprot,
    input  wire [3:0]            s_axi_arqos,

    output wire                  s_axi_rvalid,
    input  wire                  s_axi_rready,
    output wire [ID_WIDTH-1:0]   s_axi_rid,
    output wire [63:0]           s_axi_rdata,
    output wire [1:0]            s_axi_rresp,
    output wire                  s_axi_rlast,

    // ------------------------------------------------------------------------
    // Master Interface (to 32-bit AXI Interconnect / Arbiter)
    // ------------------------------------------------------------------------
    output wire                  m_axi_awvalid,
    input  wire                  m_axi_awready,
    output wire [ID_WIDTH-1:0]   m_axi_awid,
    output wire [31:0]           m_axi_awaddr,
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
    output wire [31:0]           m_axi_wdata,
    output wire [3:0]            m_axi_wstrb,
    output wire                  m_axi_wlast,

    input  wire                  m_axi_bvalid,
    output wire                  m_axi_bready,
    input  wire [ID_WIDTH-1:0]   m_axi_bid,
    input  wire [1:0]            m_axi_bresp,

    output wire                  m_axi_arvalid,
    input  wire                  m_axi_arready,
    output wire [ID_WIDTH-1:0]   m_axi_arid,
    output wire [31:0]           m_axi_araddr,
    output wire [3:0]            m_axi_arregion,
    output wire [7:0]            m_axi_arlen,
    output wire [2:0]            m_axi_arsize,
    output wire [1:0]            m_axi_arburst,
    output wire                  m_axi_arlock,
    output wire [3:0]            m_axi_arcache,
    output wire [2:0]            m_axi_arprot,
    output wire [3:0]            m_axi_arqos,

    input  wire                  m_axi_rvalid,
    output wire                  m_axi_rready,
    input  wire [ID_WIDTH-1:0]   m_axi_rid,
    input  wire [31:0]           m_axi_rdata,
    input  wire [1:0]            m_axi_rresp,
    input  wire                  m_axi_rlast
);

    // Track write address bit [2] to steer write data
    reg write_addr_b2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_addr_b2 <= 1'b0;
        end else if (s_axi_awvalid && s_axi_awready) begin
            write_addr_b2 <= s_axi_awaddr[2];
        end
    end

    // Use combinational address bit when awvalid occurs simultaneously with wvalid,
    // otherwise use latched address bit
    wire use_upper_half = (s_axi_awvalid && s_axi_awready) ? s_axi_awaddr[2] :
                          (|s_axi_wstrb[7:4])              ? 1'b1 :
                          write_addr_b2;

    // ------------------------------------------------------------------------
    // Write Address Channel
    // ------------------------------------------------------------------------
    assign m_axi_awvalid  = s_axi_awvalid;
    assign s_axi_awready  = m_axi_awready;
    assign m_axi_awid     = s_axi_awid;
    assign m_axi_awaddr   = s_axi_awaddr;
    assign m_axi_awregion = s_axi_awregion;
    assign m_axi_awlen    = s_axi_awlen;
    assign m_axi_awsize   = (s_axi_awsize > 3'b010) ? 3'b010 : s_axi_awsize;
    assign m_axi_awburst  = s_axi_awburst;
    assign m_axi_awlock   = s_axi_awlock;
    assign m_axi_awcache  = s_axi_awcache;
    assign m_axi_awprot   = s_axi_awprot;
    assign m_axi_awqos    = s_axi_awqos;

    // ------------------------------------------------------------------------
    // Write Data Channel
    // ------------------------------------------------------------------------
    assign m_axi_wvalid = s_axi_wvalid;
    assign s_axi_wready = m_axi_wready;
    assign m_axi_wdata  = use_upper_half ? s_axi_wdata[63:32] : s_axi_wdata[31:0];
    assign m_axi_wstrb  = use_upper_half ? s_axi_wstrb[7:4]   : s_axi_wstrb[3:0];
    assign m_axi_wlast  = s_axi_wlast;

    // ------------------------------------------------------------------------
    // Write Response Channel
    // ------------------------------------------------------------------------
    assign s_axi_bvalid = m_axi_bvalid;
    assign m_axi_bready = s_axi_bready;
    assign s_axi_bid    = m_axi_bid;
    assign s_axi_bresp  = m_axi_bresp;

    // ------------------------------------------------------------------------
    // Read Address Channel
    // ------------------------------------------------------------------------
    assign m_axi_arvalid  = s_axi_arvalid;
    assign s_axi_arready  = m_axi_arready;
    assign m_axi_arid     = s_axi_arid;
    assign m_axi_araddr   = s_axi_araddr;
    assign m_axi_arregion = s_axi_arregion;
    assign m_axi_arlen    = s_axi_arlen;
    assign m_axi_arsize   = (s_axi_arsize > 3'b010) ? 3'b010 : s_axi_arsize;
    assign m_axi_arburst  = s_axi_arburst;
    assign m_axi_arlock   = s_axi_arlock;
    assign m_axi_arcache  = s_axi_arcache;
    assign m_axi_arprot   = s_axi_arprot;
    assign m_axi_arqos    = s_axi_arqos;

    // ------------------------------------------------------------------------
    // Read Data Channel: Replicate 32-bit data to both halves
    // ------------------------------------------------------------------------
    assign s_axi_rvalid = m_axi_rvalid;
    assign m_axi_rready = s_axi_rready;
    assign s_axi_rid    = m_axi_rid;
    assign s_axi_rdata  = {m_axi_rdata, m_axi_rdata};
    assign s_axi_rresp  = m_axi_rresp;
    assign s_axi_rlast  = m_axi_rlast;

endmodule
