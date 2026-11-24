// ============================================================================
// Module Name: soc_memory_axi
// Description: Unified Instruction and Data Memory with AXI4 Slave Interface
//              64 KiB (16,384 x 32-bit words), byte-write enables, burst support.
//              Initializes memory array with RISC-V NOP instructions (0x00000013).
// ============================================================================

`timescale 1ns / 1ps

module soc_memory_axi #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    parameter MEM_SIZE   = 65536, // 64 KiB
    parameter MEM_DEPTH  = MEM_SIZE / 4 // 16384 32-bit words
)(
    input  wire                  clk,
    input  wire                  rst,

    // AXI4 Write Address Channel
    input  wire [ID_WIDTH-1:0]   s_axi_awid,
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [7:0]            s_axi_awlen,
    input  wire [2:0]            s_axi_awsize,
    input  wire [1:0]            s_axi_awburst,
    input  wire                  s_axi_awlock,
    input  wire [3:0]            s_axi_awcache,
    input  wire [2:0]            s_axi_awprot,
    input  wire [3:0]            s_axi_awqos,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    // AXI4 Write Data Channel
    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wlast,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    // AXI4 Write Response Channel
    output reg  [ID_WIDTH-1:0]   s_axi_bid,
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    // AXI4 Read Address Channel
    input  wire [ID_WIDTH-1:0]   s_axi_arid,
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [7:0]            s_axi_arlen,
    input  wire [2:0]            s_axi_arsize,
    input  wire [1:0]            s_axi_arburst,
    input  wire                  s_axi_arlock,
    input  wire [3:0]            s_axi_arcache,
    input  wire [2:0]            s_axi_arprot,
    input  wire [3:0]            s_axi_arqos,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    // AXI4 Read Data Channel
    output reg  [ID_WIDTH-1:0]   s_axi_rid,
    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rlast,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    // 16384 x 32-bit memory array (64 KiB)
    reg [31:0] mem [0:MEM_DEPTH-1];

    // Initialize with safe RISC-V NOPs (0x00000013: addi x0, x0, 0)
    integer init_idx;
    initial begin
        for (init_idx = 0; init_idx < MEM_DEPTH; init_idx = init_idx + 1) begin
            mem[init_idx] = 32'h0000_0013;
        end
    end

    // ------------------------------------------------------------------------
    // Write Channel Logic
    // ------------------------------------------------------------------------
    localparam W_IDLE  = 2'b00;
    localparam W_DATA  = 2'b01;
    localparam W_RESP  = 2'b10;

    reg [1:0]            w_state;
    reg [ID_WIDTH-1:0]   w_id_reg;
    reg [ADDR_WIDTH-1:0] w_addr_reg;
    reg [7:0]            w_len_reg;

    wire [13:0] w_word_idx = w_addr_reg[15:2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_state       <= W_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            s_axi_bresp   <= 2'b00; // OKAY
            w_id_reg      <= {ID_WIDTH{1'b0}};
            w_addr_reg    <= {ADDR_WIDTH{1'b0}};
            w_len_reg     <= 8'd0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b0;
                    if (s_axi_awvalid && s_axi_awready) begin
                        w_id_reg      <= s_axi_awid;
                        w_addr_reg    <= s_axi_awaddr;
                        w_len_reg     <= s_axi_awlen;
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b1;
                        w_state       <= W_DATA;
                    end
                end

                W_DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        // Byte-strobe write
                        if (w_word_idx < MEM_DEPTH) begin
                            if (s_axi_wstrb[0]) mem[w_word_idx][7:0]   <= s_axi_wdata[7:0];
                            if (s_axi_wstrb[1]) mem[w_word_idx][15:8]  <= s_axi_wdata[15:8];
                            if (s_axi_wstrb[2]) mem[w_word_idx][23:16] <= s_axi_wdata[23:16];
                            if (s_axi_wstrb[3]) mem[w_word_idx][31:24] <= s_axi_wdata[31:24];
                        end

                        w_addr_reg <= w_addr_reg + 32'd4;

                        if (s_axi_wlast || w_len_reg == 8'd0) begin
                            s_axi_wready <= 1'b0;
                            s_axi_bvalid <= 1'b1;
                            s_axi_bid    <= w_id_reg;
                            s_axi_bresp  <= 2'b00; // OKAY
                            w_state      <= W_RESP;
                        end else begin
                            w_len_reg <= w_len_reg - 8'd1;
                        end
                    end
                end

                W_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid  <= 1'b0;
                        s_axi_awready <= 1'b1;
                        w_state       <= W_IDLE;
                    end
                end

                default: w_state <= W_IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Read Channel Logic
    // ------------------------------------------------------------------------
    localparam R_IDLE  = 2'b00;
    localparam R_BURST = 2'b01;

    reg [1:0]            r_state;
    reg [ID_WIDTH-1:0]   r_id_reg;
    reg [ADDR_WIDTH-1:0] r_addr_reg;
    reg [7:0]            r_len_reg;

    wire [13:0] r_word_idx = r_addr_reg[15:2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_state       <= R_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b0;
            r_id_reg      <= {ID_WIDTH{1'b0}};
            r_addr_reg    <= {ADDR_WIDTH{1'b0}};
            r_len_reg     <= 8'd0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid && s_axi_arready) begin
                        r_id_reg      <= s_axi_arid;
                        r_addr_reg    <= s_axi_araddr;
                        r_len_reg     <= s_axi_arlen;
                        s_axi_arready <= 1'b0;

                        // Present first read beat
                        s_axi_rvalid <= 1'b1;
                        s_axi_rid    <= s_axi_arid;
                        s_axi_rresp  <= 2'b00; // OKAY
                        s_axi_rlast  <= (s_axi_arlen == 8'd0);
                        if (s_axi_araddr[15:2] < MEM_DEPTH)
                            s_axi_rdata <= mem[s_axi_araddr[15:2]];
                        else
                            s_axi_rdata <= 32'h0000_0000;

                        r_state <= R_BURST;
                    end
                end

                R_BURST: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        if (s_axi_rlast) begin
                            s_axi_rvalid  <= 1'b0;
                            s_axi_rlast   <= 1'b0;
                            s_axi_arready <= 1'b1;
                            r_state       <= R_IDLE;
                        end else begin
                            // Next burst beat
                            r_addr_reg <= r_addr_reg + 32'd4;
                            r_len_reg  <= r_len_reg - 8'd1;

                            s_axi_rvalid <= 1'b1;
                            s_axi_rid    <= r_id_reg;
                            s_axi_rresp  <= 2'b00;
                            s_axi_rlast  <= (r_len_reg == 8'd1);

                            if ((r_addr_reg[15:2] + 1'b1) < MEM_DEPTH)
                                s_axi_rdata <= mem[r_addr_reg[15:2] + 1'b1];
                            else
                                s_axi_rdata <= 32'h0000_0000;
                        end
                    end
                end

                default: r_state <= R_IDLE;
            endcase
        end
    end

endmodule
