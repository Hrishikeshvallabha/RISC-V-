// ============================================================================
// Module Name: axi_adapter_ifu_64_to_32
// Description: Translates 64-bit AXI4 IFU read-only interface from VeeR EL2
//              to 32-bit AXI4 interface.
//              - Converts 64-bit fetch (arsize=3'b011, arlen=0) into a 2-beat
//                32-bit burst (arsize=3'b010, arlen=1, arburst=INCR).
//              - Assembles 32-bit word0 and word1 into 64-bit instruction data.
//              - Supports single-beat <= 32-bit accesses with zero-bubble pass-through.
// ============================================================================

`timescale 1ns / 1ps

module axi_adapter_ifu_64_to_32 #(
    parameter ID_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,

    // ------------------------------------------------------------------------
    // Slave Interface (from VeeR EL2 64-bit IFU)
    // ------------------------------------------------------------------------
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

    localparam S_IDLE       = 2'b00;
    localparam S_WAIT_BEAT0 = 2'b01;
    localparam S_WAIT_BEAT1 = 2'b10;
    localparam S_SINGLE     = 2'b11;

    reg [1:0]          state;
    reg [ID_WIDTH-1:0] id_reg;
    reg [31:0]         word0_reg;
    reg [1:0]          resp0_reg;
    reg                is_64bit_req;

    wire is_64bit = (s_axi_arsize == 3'b011);

    // Address channel combinational mapping
    assign m_axi_arvalid  = (state == S_IDLE) ? s_axi_arvalid : 1'b0;
    assign s_axi_arready  = (state == S_IDLE) ? m_axi_arready : 1'b0;
    assign m_axi_arid     = s_axi_arid;
    assign m_axi_araddr   = s_axi_araddr;
    assign m_axi_arregion = s_axi_arregion;
    assign m_axi_arlen    = is_64bit ? 8'd1 : s_axi_arlen;
    assign m_axi_arsize   = 3'b010; // 4 bytes (32-bit)
    assign m_axi_arburst  = is_64bit ? 2'b01 : s_axi_arburst; // INCR
    assign m_axi_arlock   = s_axi_arlock;
    assign m_axi_arcache  = s_axi_arcache;
    assign m_axi_arprot   = s_axi_arprot;
    assign m_axi_arqos    = s_axi_arqos;

    // Read Data Channel:
    // When in S_WAIT_BEAT1, beat 0 is already in word0_reg. Beat 1 is currently on m_axi_rdata.
    // Combinational forwarding provides 0-cycle latency for the completed 64-bit fetch!
    assign s_axi_rvalid = (state == S_WAIT_BEAT1) ? m_axi_rvalid :
                          (state == S_SINGLE)     ? m_axi_rvalid : 1'b0;
    assign s_axi_rdata  = (state == S_WAIT_BEAT1) ? {m_axi_rdata, word0_reg} :
                          (state == S_SINGLE)     ? {m_axi_rdata, m_axi_rdata} : 64'd0;
    assign s_axi_rlast  = (state == S_WAIT_BEAT1) ? 1'b1 :
                          (state == S_SINGLE)     ? m_axi_rlast : 1'b0;
    assign s_axi_rid    = (state == S_WAIT_BEAT1) ? id_reg : m_axi_rid;
    assign s_axi_rresp  = (state == S_WAIT_BEAT1) ? ((m_axi_rresp != 2'b00) ? m_axi_rresp : resp0_reg) : m_axi_rresp;

    assign m_axi_rready = (state == S_WAIT_BEAT0) ? 1'b1 :
                          (state == S_WAIT_BEAT1 || state == S_SINGLE) ? s_axi_rready : 1'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= S_IDLE;
            id_reg       <= {ID_WIDTH{1'b0}};
            word0_reg    <= 32'd0;
            resp0_reg    <= 2'b00;
            is_64bit_req <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (s_axi_arvalid && m_axi_arready) begin
                        id_reg       <= s_axi_arid;
                        is_64bit_req <= is_64bit;
                        if (is_64bit) begin
                            state <= S_WAIT_BEAT0;
                        end else begin
                            state <= S_SINGLE;
                        end
                    end
                end

                S_WAIT_BEAT0: begin
                    if (m_axi_rvalid) begin
                        word0_reg <= m_axi_rdata;
                        resp0_reg <= m_axi_rresp;
                        state     <= S_WAIT_BEAT1;
                    end
                end

                S_WAIT_BEAT1: begin
                    if (m_axi_rvalid && s_axi_rready) begin
                        state <= S_IDLE;
                    end
                end

                S_SINGLE: begin
                    if (m_axi_rvalid && s_axi_rready && m_axi_rlast) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
