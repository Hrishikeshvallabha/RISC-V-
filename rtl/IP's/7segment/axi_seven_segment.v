`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Module: axi_seven_segment
// Description:
//   AXI4-Lite Slave Peripheral for 4-Digit 7-Segment Display Controller.
//
// Features:
//   - Synthesizable for Vivado and VCS.
//   - Completely independent AW and W channel handshakes:
//     * AW and W may arrive in the same clock cycle.
//     * AW may arrive before W.
//     * W may arrive before AW.
//   - Register Map (Base + Offset):
//     * Offset 0x00: DISPLAY_DATA (R/W)
//         [15:12] = Digit 3 (Hex 0-F, leftmost)
//         [11:8]  = Digit 2 (Hex 0-F)
//         [7:4]   = Digit 1 (Hex 0-F)
//         [3:0]   = Digit 0 (Hex 0-F, rightmost)
//         [31:16] = Reserved (read as 0)
//     * Offset 0x04: CONTROL (R/W)
//         Bit 0   = Display Enable (1 = enable refresh, 0 = blank display)
//         [31:1]  = Reserved (read as 0)
//     * Offset 0x08: STATUS (RO)
//         Bit 0   = Display Enabled status (reflects CONTROL[0])
//         [3:1]   = Reserved (read as 0)
//         [5:4]   = Current active digit index [1:0]
//         [31:6]  = Reserved (read as 0)
//
// Hardware Model & Polarity:
//   - Common-Anode (Active-Low):
//     seg[6:0] = {a, b, c, d, e, f, g} (0 = ON, 1 = OFF)
//     an[3:0]  = Digit enables (0 = ON, 1 = OFF)
// ============================================================================

module axi_seven_segment #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 12,
    parameter integer REFRESH_DIV        = 100
)(
    // AXI Clock and Reset
    input  wire                              s_axi_aclk,
    input  wire                              s_axi_aresetn,

    // AXI Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [2:0]                        s_axi_awprot,
    input  wire                              s_axi_awvalid,
    output wire                              s_axi_awready,

    // AXI Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                              s_axi_wvalid,
    output wire                              s_axi_wready,

    // AXI Write Response Channel
    output wire [1:0]                        s_axi_bresp,
    output wire                              s_axi_bvalid,
    input  wire                              s_axi_bready,

    // AXI Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [2:0]                        s_axi_arprot,
    input  wire                              s_axi_arvalid,
    output wire                              s_axi_arready,

    // AXI Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output wire [1:0]                        s_axi_rresp,
    output wire                              s_axi_rvalid,
    input  wire                              s_axi_rready,

    // 7-Segment External Pins
    output wire [6:0]                        seg,
    output wire [3:0]                        an
);

    // ------------------------------------------------------------------------
    // Registers
    // ------------------------------------------------------------------------
    reg [31:0] display_data_reg;
    reg [31:0] control_reg;

    wire [1:0]  current_digit_idx;
    wire [31:0] status_reg = {26'd0, current_digit_idx, 3'd0, control_reg[0]};

    // ------------------------------------------------------------------------
    // AXI Handshake & Internal Registers
    // ------------------------------------------------------------------------
    reg [C_S_AXI_ADDR_WIDTH-1:0]     axi_awaddr_reg;
    reg                              axi_awready_reg;
    reg                              axi_wready_reg;
    reg [1:0]                        axi_bresp_reg;
    reg                              axi_bvalid_reg;

    reg                              aw_received;
    reg                              w_received;
    reg [C_S_AXI_DATA_WIDTH-1:0]     axi_wdata_reg;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] axi_wstrb_reg;

    assign s_axi_awready = axi_awready_reg;
    assign s_axi_wready  = axi_wready_reg;
    assign s_axi_bresp   = axi_bresp_reg;
    assign s_axi_bvalid  = axi_bvalid_reg;

    // Detect handshake occurrences on current cycle
    wire aw_handshake = s_axi_awvalid && axi_awready_reg;
    wire w_handshake  = s_axi_wvalid  && axi_wready_reg;

    // Both address and data available (either previously latched or captured this cycle)
    wire wr_en = (aw_received || aw_handshake) && (w_received || w_handshake) && !axi_bvalid_reg;

    wire [C_S_AXI_ADDR_WIDTH-1:0]     effective_awaddr = aw_received ? axi_awaddr_reg : s_axi_awaddr;
    wire [C_S_AXI_DATA_WIDTH-1:0]     effective_wdata  = w_received  ? axi_wdata_reg  : s_axi_wdata;
    wire [(C_S_AXI_DATA_WIDTH/8)-1:0] effective_wstrb  = w_received  ? axi_wstrb_reg  : s_axi_wstrb;

    // ------------------------------------------------------------------------
    // AXI Write State Machine (Independent AW / W Channels)
    // ------------------------------------------------------------------------
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_awready_reg  <= 1'b1;
            axi_wready_reg   <= 1'b1;
            aw_received      <= 1'b0;
            w_received       <= 1'b0;
            axi_awaddr_reg   <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            axi_wdata_reg    <= {C_S_AXI_DATA_WIDTH{1'b0}};
            axi_wstrb_reg    <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
            axi_bvalid_reg   <= 1'b0;
            axi_bresp_reg    <= 2'b00;
            display_data_reg <= 32'h0000_0000;
            control_reg      <= 32'h0000_0000;
        end else begin
            // Address Write Handshake
            if (aw_handshake) begin
                axi_awaddr_reg <= s_axi_awaddr;
                if (!wr_en) begin
                    aw_received     <= 1'b1;
                    axi_awready_reg <= 1'b0;
                end
            end

            // Data Write Handshake
            if (w_handshake) begin
                axi_wdata_reg <= s_axi_wdata;
                axi_wstrb_reg <= s_axi_wstrb;
                if (!wr_en) begin
                    w_received     <= 1'b1;
                    axi_wready_reg <= 1'b0;
                end
            end

            // Execute Register Write when both address & data are present
            if (wr_en) begin
                aw_received     <= 1'b0;
                w_received      <= 1'b0;
                axi_awready_reg <= 1'b0;
                axi_wready_reg  <= 1'b0;
                axi_bvalid_reg  <= 1'b1;
                axi_bresp_reg   <= 2'b00; // OKAY

                case (effective_awaddr[3:2])
                    2'b00: begin // 0x00: DISPLAY_DATA
                        if (effective_wstrb[0]) display_data_reg[7:0]   <= effective_wdata[7:0];
                        if (effective_wstrb[1]) display_data_reg[15:8]  <= effective_wdata[15:8];
                        if (effective_wstrb[2]) display_data_reg[23:16] <= effective_wdata[23:16];
                        if (effective_wstrb[3]) display_data_reg[31:24] <= effective_wdata[31:24];
                    end
                    2'b01: begin // 0x04: CONTROL
                        if (effective_wstrb[0]) control_reg[7:0]   <= effective_wdata[7:0];
                        if (effective_wstrb[1]) control_reg[15:8]  <= effective_wdata[15:8];
                        if (effective_wstrb[2]) control_reg[23:16] <= effective_wdata[23:16];
                        if (effective_wstrb[3]) control_reg[31:24] <= effective_wdata[31:24];
                    end
                    default: begin
                        // Read-only or unmapped registers
                    end
                endcase
            end

            // Complete Write Transaction
            if (axi_bvalid_reg && s_axi_bready) begin
                axi_bvalid_reg  <= 1'b0;
                axi_awready_reg <= 1'b1;
                axi_wready_reg  <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // AXI Read State Machine
    // ------------------------------------------------------------------------
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr_reg;
    reg                          axi_arready_reg;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata_reg;
    reg [1:0]                    axi_rresp_reg;
    reg                          axi_rvalid_reg;

    assign s_axi_arready = axi_arready_reg;
    assign s_axi_rdata   = axi_rdata_reg;
    assign s_axi_rresp   = axi_rresp_reg;
    assign s_axi_rvalid  = axi_rvalid_reg;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_arready_reg <= 1'b1;
            axi_rvalid_reg  <= 1'b0;
            axi_rdata_reg   <= {C_S_AXI_DATA_WIDTH{1'b0}};
            axi_rresp_reg   <= 2'b00;
            axi_araddr_reg  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (s_axi_arvalid && axi_arready_reg) begin
                axi_arready_reg <= 1'b0;
                axi_rvalid_reg  <= 1'b1;
                axi_rresp_reg   <= 2'b00; // OKAY
                axi_araddr_reg  <= s_axi_araddr;

                case (s_axi_araddr[3:2])
                    2'b00:   axi_rdata_reg <= display_data_reg;
                    2'b01:   axi_rdata_reg <= control_reg;
                    2'b10:   axi_rdata_reg <= status_reg;
                    default: axi_rdata_reg <= 32'h0000_0000;
                endcase
            end else if (axi_rvalid_reg && s_axi_rready) begin
                axi_rvalid_reg  <= 1'b0;
                axi_arready_reg <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // 7-Segment Multiplexer Instance
    // ------------------------------------------------------------------------
    seven_segment_mux #(
        .REFRESH_DIV (REFRESH_DIV)
    ) u_mux (
        .clk           (s_axi_aclk),
        .rst_n         (s_axi_aresetn),
        .en            (control_reg[0]),
        .digits        (display_data_reg[15:0]),
        .seg           (seg),
        .an            (an),
        .current_digit (current_digit_idx)
    );

endmodule

`default_nettype wire
