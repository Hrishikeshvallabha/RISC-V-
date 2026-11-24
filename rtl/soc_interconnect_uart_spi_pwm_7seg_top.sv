`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Cumulative Top: AXI 2x8 Interconnect + UART + SPI + PWM + 7-SEGMENT DISPLAY
//
// Address Mapping:
//   UART:  0x4000_0000 - 0x4000_0FFF (Interconnect M03)
//   SPI:   0x4000_1000 - 0x4000_1FFF (Interconnect M04)
//   PWM:   0x4000_2000 - 0x4000_2FFF (Interconnect M05)
//   7-SEG: 0x4000_3000 - 0x4000_3FFF (Interconnect M06)
//
// S00 connects to external test master. S01 is reserved for future master.
// ============================================================================

module soc_interconnect_uart_spi_pwm_7seg_top #(
    parameter DATA_WIDTH             = 32,
    parameter ADDR_WIDTH             = 32,
    parameter IC_ID_WIDTH            = 8,
    parameter UART_ID_WIDTH          = 12,
    parameter SPI_ID_WIDTH           = 12,
    parameter SPI_ADDR_WIDTH         = 7,
    parameter PWM_ADDR_WIDTH         = 4,
    parameter SEVEN_SEG_ADDR_WIDTH   = 12,
    parameter SEVEN_SEG_REFRESH_DIV  = 100
)(
    input  wire clk,
    input  wire rst,

    // ------------------------------------------------------------------------
    // AXI master-side test interface -> Interconnect S00
    // ------------------------------------------------------------------------
    input  wire [IC_ID_WIDTH-1:0]  axi_awid,
    input  wire [ADDR_WIDTH-1:0]   axi_awaddr,
    input  wire [7:0]              axi_awlen,
    input  wire [2:0]              axi_awsize,
    input  wire [1:0]              axi_awburst,
    input  wire                    axi_awlock,
    input  wire [3:0]              axi_awcache,
    input  wire [2:0]              axi_awprot,
    input  wire [3:0]              axi_awqos,
    input  wire                    axi_awvalid,
    output wire                    axi_awready,

    input  wire [DATA_WIDTH-1:0]   axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] axi_wstrb,
    input  wire                    axi_wlast,
    input  wire                    axi_wvalid,
    output wire                    axi_wready,

    output wire [IC_ID_WIDTH-1:0]  axi_bid,
    output wire [1:0]              axi_bresp,
    output wire                    axi_bvalid,
    input  wire                    axi_bready,

    input  wire [IC_ID_WIDTH-1:0]  axi_arid,
    input  wire [ADDR_WIDTH-1:0]   axi_araddr,
    input  wire [7:0]              axi_arlen,
    input  wire [2:0]              axi_arsize,
    input  wire [1:0]              axi_arburst,
    input  wire                    axi_arlock,
    input  wire [3:0]              axi_arcache,
    input  wire [2:0]              axi_arprot,
    input  wire [3:0]              axi_arqos,
    input  wire                    axi_arvalid,
    output wire                    axi_arready,

    output wire [IC_ID_WIDTH-1:0]  axi_rid,
    output wire [DATA_WIDTH-1:0]   axi_rdata,
    output wire [1:0]              axi_rresp,
    output wire                    axi_rlast,
    output wire                    axi_rvalid,
    input  wire                    axi_rready,

    // ------------------------------------------------------------------------
    // UART external pins/status
    // ------------------------------------------------------------------------
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire uart_interrupt_o,

    // ------------------------------------------------------------------------
    // SPI external pins
    // ------------------------------------------------------------------------
    output wire spi_clk_o,
    output wire spi_cs_n_o,
    output wire spi_mosi_o,
    input  wire spi_miso_i,

    // ------------------------------------------------------------------------
    // PWM external pin
    // ------------------------------------------------------------------------
    output wire pwm_out_o,

    // ------------------------------------------------------------------------
    // 7-Segment external pins
    // ------------------------------------------------------------------------
    output wire [6:0] seg,
    output wire [3:0] an
);

    localparam integer STRB_WIDTH = DATA_WIDTH/8;

    // ------------------------------------------------------------------------
    // Interconnect M03 <-> UART signals
    // ------------------------------------------------------------------------
    wire [IC_ID_WIDTH-1:0] m03_awid;
    wire [ADDR_WIDTH-1:0]  m03_awaddr;
    wire [7:0]             m03_awlen;
    wire [2:0]             m03_awsize;
    wire [1:0]             m03_awburst;
    wire                   m03_awlock;
    wire [3:0]             m03_awcache;
    wire [2:0]             m03_awprot;
    wire [3:0]             m03_awqos;
    wire                   m03_awvalid;
    wire                   m03_awready;

    wire [DATA_WIDTH-1:0]  m03_wdata;
    wire [STRB_WIDTH-1:0]  m03_wstrb;
    wire                   m03_wlast;
    wire                   m03_wvalid;
    wire                   m03_wready;

    wire [IC_ID_WIDTH-1:0] m03_bid;
    wire [1:0]             m03_bresp;
    wire                   m03_bvalid;
    wire                   m03_bready;

    wire [IC_ID_WIDTH-1:0] m03_arid;
    wire [ADDR_WIDTH-1:0]  m03_araddr;
    wire [7:0]             m03_arlen;
    wire [2:0]             m03_arsize;
    wire [1:0]             m03_arburst;
    wire                   m03_arlock;
    wire [3:0]             m03_arcache;
    wire [2:0]             m03_arprot;
    wire [3:0]             m03_arqos;
    wire                   m03_arvalid;
    wire                   m03_arready;

    wire [IC_ID_WIDTH-1:0] m03_rid;
    wire [DATA_WIDTH-1:0]  m03_rdata;
    wire [1:0]             m03_rresp;
    wire                   m03_rlast;
    wire                   m03_rvalid;
    wire                   m03_rready;

    // UART adaptation
    wire [UART_ID_WIDTH-1:0] uart_awid = {{(UART_ID_WIDTH-IC_ID_WIDTH){1'b0}}, m03_awid};
    wire [4:0]               uart_awaddr = m03_awaddr[4:0];
    wire                     uart_awvalid = m03_awvalid;
    wire                     uart_awready;
    wire [31:0]              uart_wdata = m03_wdata;
    wire [3:0]               uart_wstrb = m03_wstrb;
    wire                     uart_wvalid = m03_wvalid;
    wire                     uart_wready;
    wire [UART_ID_WIDTH-1:0] uart_bid;
    wire [1:0]               uart_bresp;
    wire                     uart_bvalid;
    wire                     uart_bready = m03_bready;

    wire [UART_ID_WIDTH-1:0] uart_arid = {{(UART_ID_WIDTH-IC_ID_WIDTH){1'b0}}, m03_arid};
    wire [4:0]               uart_araddr = m03_araddr[4:0];
    wire                     uart_arvalid = m03_arvalid;
    wire                     uart_arready;
    wire [31:0]              uart_rdata;
    wire [1:0]               uart_rresp;
    wire [UART_ID_WIDTH-1:0] uart_rid;
    wire                     uart_rvalid;
    wire                     uart_rready = m03_rready;

    assign m03_awready = uart_awready;
    assign m03_wready  = uart_wready;
    assign m03_bvalid  = uart_bvalid;
    assign m03_bresp   = uart_bresp;
    assign m03_bid     = uart_bid[IC_ID_WIDTH-1:0];

    assign m03_arready = uart_arready;
    assign m03_rvalid  = uart_rvalid;
    assign m03_rdata   = uart_rdata;
    assign m03_rresp   = uart_rresp;
    assign m03_rid     = uart_rid[IC_ID_WIDTH-1:0];
    assign m03_rlast   = 1'b1;

    // ------------------------------------------------------------------------
    // Interconnect M04 <-> SPI signals
    // ------------------------------------------------------------------------
    wire [IC_ID_WIDTH-1:0] m04_awid;
    wire [ADDR_WIDTH-1:0]  m04_awaddr;
    wire [7:0]             m04_awlen;
    wire [2:0]             m04_awsize;
    wire [1:0]             m04_awburst;
    wire                   m04_awlock;
    wire [3:0]             m04_awcache;
    wire [2:0]             m04_awprot;
    wire [3:0]             m04_awqos;
    wire                   m04_awvalid;
    wire                   m04_awready;

    wire [DATA_WIDTH-1:0]  m04_wdata;
    wire [STRB_WIDTH-1:0]  m04_wstrb;
    wire                   m04_wlast;
    wire                   m04_wvalid;
    wire                   m04_wready;

    wire [IC_ID_WIDTH-1:0] m04_bid;
    wire [1:0]             m04_bresp;
    wire                   m04_bvalid;
    wire                   m04_bready;

    wire [IC_ID_WIDTH-1:0] m04_arid;
    wire [ADDR_WIDTH-1:0]  m04_araddr;
    wire [7:0]             m04_arlen;
    wire [2:0]             m04_arsize;
    wire [1:0]             m04_arburst;
    wire                   m04_arlock;
    wire [3:0]             m04_arcache;
    wire [2:0]             m04_arprot;
    wire [3:0]             m04_arqos;
    wire                   m04_arvalid;
    wire                   m04_arready;

    wire [IC_ID_WIDTH-1:0] m04_rid;
    wire [DATA_WIDTH-1:0]  m04_rdata;
    wire [1:0]             m04_rresp;
    wire                   m04_rlast;
    wire                   m04_rvalid;
    wire                   m04_rready;

    // SPI adaptation
    wire [SPI_ID_WIDTH-1:0]   spi_awid    = {{(SPI_ID_WIDTH-IC_ID_WIDTH){1'b0}}, m04_awid};
    wire [SPI_ADDR_WIDTH-1:0] spi_awaddr  = m04_awaddr[SPI_ADDR_WIDTH-1:0];
    wire                      spi_awvalid = m04_awvalid;
    wire                      spi_awready;
    wire [31:0]               spi_wdata   = m04_wdata;
    wire [3:0]                spi_wstrb   = m04_wstrb;
    wire                      spi_wvalid  = m04_wvalid;
    wire                      spi_wready;
    wire [SPI_ID_WIDTH-1:0]   spi_bid;
    wire [1:0]                spi_bresp;
    wire                      spi_bvalid;
    wire                      spi_bready  = m04_bready;

    wire [SPI_ID_WIDTH-1:0]   spi_arid    = {{(SPI_ID_WIDTH-IC_ID_WIDTH){1'b0}}, m04_arid};
    wire [SPI_ADDR_WIDTH-1:0] spi_araddr  = m04_araddr[SPI_ADDR_WIDTH-1:0];
    wire                      spi_arvalid = m04_arvalid;
    wire                      spi_arready;
    wire [31:0]               spi_rdata;
    wire [1:0]                spi_rresp;
    wire [SPI_ID_WIDTH-1:0]   spi_rid;
    wire                      spi_rvalid;
    wire                      spi_rready  = m04_rready;

    assign m04_awready = spi_awready;
    assign m04_wready  = spi_wready;
    assign m04_bvalid  = spi_bvalid;
    assign m04_bresp   = spi_bresp;
    assign m04_bid     = spi_bid[IC_ID_WIDTH-1:0];

    assign m04_arready = spi_arready;
    assign m04_rvalid  = spi_rvalid;
    assign m04_rdata   = spi_rdata;
    assign m04_rresp   = spi_rresp;
    assign m04_rid     = spi_rid[IC_ID_WIDTH-1:0];
    assign m04_rlast   = 1'b1;

    // ------------------------------------------------------------------------
    // Interconnect M05 <-> PWM signals
    // ------------------------------------------------------------------------
    wire [IC_ID_WIDTH-1:0] m05_awid;
    wire [ADDR_WIDTH-1:0]  m05_awaddr;
    wire [7:0]             m05_awlen;
    wire [2:0]             m05_awsize;
    wire [1:0]             m05_awburst;
    wire                   m05_awlock;
    wire [3:0]             m05_awcache;
    wire [2:0]             m05_awprot;
    wire [3:0]             m05_awqos;
    wire                   m05_awvalid;
    wire                   m05_awready;

    wire [DATA_WIDTH-1:0]  m05_wdata;
    wire [STRB_WIDTH-1:0]  m05_wstrb;
    wire                   m05_wlast;
    wire                   m05_wvalid;
    wire                   m05_wready;

    wire [IC_ID_WIDTH-1:0] m05_bid;
    wire [1:0]             m05_bresp;
    wire                   m05_bvalid;
    wire                   m05_bready;

    wire [IC_ID_WIDTH-1:0] m05_arid;
    wire [ADDR_WIDTH-1:0]  m05_araddr;
    wire [7:0]             m05_arlen;
    wire [2:0]             m05_arsize;
    wire [1:0]             m05_arburst;
    wire                   m05_arlock;
    wire [3:0]             m05_arcache;
    wire [2:0]             m05_arprot;
    wire [3:0]             m05_arqos;
    wire                   m05_arvalid;
    wire                   m05_arready;

    wire [IC_ID_WIDTH-1:0] m05_rid;
    wire [DATA_WIDTH-1:0]  m05_rdata;
    wire [1:0]             m05_rresp;
    wire                   m05_rlast;
    wire                   m05_rvalid;
    wire                   m05_rready;

    // PWM adaptation
    wire [PWM_ADDR_WIDTH-1:0] pwm_awaddr  = m05_awaddr[PWM_ADDR_WIDTH-1:0];
    wire                      pwm_awvalid = m05_awvalid;
    wire                      pwm_awready;
    wire [31:0]               pwm_wdata   = m05_wdata;
    wire [3:0]                pwm_wstrb   = m05_wstrb;
    wire                      pwm_wvalid  = m05_wvalid;
    wire                      pwm_wready;
    wire [1:0]                pwm_bresp;
    wire                      pwm_bvalid;
    wire                      pwm_bready  = m05_bready;

    wire [PWM_ADDR_WIDTH-1:0] pwm_araddr  = m05_araddr[PWM_ADDR_WIDTH-1:0];
    wire                      pwm_arvalid = m05_arvalid;
    wire                      pwm_arready;
    wire [31:0]               pwm_rdata;
    wire [1:0]                pwm_rresp;
    wire                      pwm_rvalid;
    wire                      pwm_rready  = m05_rready;

    reg [IC_ID_WIDTH-1:0] pwm_bid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            pwm_bid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m05_awvalid && m05_awready)
            pwm_bid_reg <= m05_awid;
    end

    reg [IC_ID_WIDTH-1:0] pwm_rid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            pwm_rid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m05_arvalid && m05_arready)
            pwm_rid_reg <= m05_arid;
    end

    assign m05_awready = pwm_awready;
    assign m05_wready  = pwm_wready;
    assign m05_bvalid  = pwm_bvalid;
    assign m05_bresp   = pwm_bresp;
    assign m05_bid     = pwm_bid_reg;

    assign m05_arready = pwm_arready;
    assign m05_rvalid  = pwm_rvalid;
    assign m05_rdata   = pwm_rdata;
    assign m05_rresp   = pwm_rresp;
    assign m05_rid     = pwm_rid_reg;
    assign m05_rlast   = 1'b1;

    // ------------------------------------------------------------------------
    // Interconnect M06 <-> 7-Segment signals
    // ------------------------------------------------------------------------
    wire [IC_ID_WIDTH-1:0] m06_awid;
    wire [ADDR_WIDTH-1:0]  m06_awaddr;
    wire [7:0]             m06_awlen;
    wire [2:0]             m06_awsize;
    wire [1:0]             m06_awburst;
    wire                   m06_awlock;
    wire [3:0]             m06_awcache;
    wire [2:0]             m06_awprot;
    wire [3:0]             m06_awqos;
    wire                   m06_awvalid;
    wire                   m06_awready;

    wire [DATA_WIDTH-1:0]  m06_wdata;
    wire [STRB_WIDTH-1:0]  m06_wstrb;
    wire                   m06_wlast;
    wire                   m06_wvalid;
    wire                   m06_wready;

    wire [IC_ID_WIDTH-1:0] m06_bid;
    wire [1:0]             m06_bresp;
    wire                   m06_bvalid;
    wire                   m06_bready;

    wire [IC_ID_WIDTH-1:0] m06_arid;
    wire [ADDR_WIDTH-1:0]  m06_araddr;
    wire [7:0]             m06_arlen;
    wire [2:0]             m06_arsize;
    wire [1:0]             m06_arburst;
    wire                   m06_arlock;
    wire [3:0]             m06_arcache;
    wire [2:0]             m06_arprot;
    wire [3:0]             m06_arqos;
    wire                   m06_arvalid;
    wire                   m06_arready;

    wire [IC_ID_WIDTH-1:0] m06_rid;
    wire [DATA_WIDTH-1:0]  m06_rdata;
    wire [1:0]             m06_rresp;
    wire                   m06_rlast;
    wire                   m06_rvalid;
    wire                   m06_rready;

    // 7-Segment adaptation
    wire [SEVEN_SEG_ADDR_WIDTH-1:0] seven_seg_awaddr  = m06_awaddr[SEVEN_SEG_ADDR_WIDTH-1:0];
    wire                            seven_seg_awvalid = m06_awvalid;
    wire                            seven_seg_awready;
    wire [31:0]                     seven_seg_wdata   = m06_wdata;
    wire [3:0]                      seven_seg_wstrb   = m06_wstrb;
    wire                            seven_seg_wvalid  = m06_wvalid;
    wire                            seven_seg_wready;
    wire [1:0]                      seven_seg_bresp;
    wire                            seven_seg_bvalid;
    wire                            seven_seg_bready  = m06_bready;

    wire [SEVEN_SEG_ADDR_WIDTH-1:0] seven_seg_araddr  = m06_araddr[SEVEN_SEG_ADDR_WIDTH-1:0];
    wire                            seven_seg_arvalid = m06_arvalid;
    wire                            seven_seg_arready;
    wire [31:0]                     seven_seg_rdata;
    wire [1:0]                      seven_seg_rresp;
    wire                            seven_seg_rvalid;
    wire                            seven_seg_rready  = m06_rready;

    reg [IC_ID_WIDTH-1:0] seven_seg_bid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            seven_seg_bid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m06_awvalid && m06_awready)
            seven_seg_bid_reg <= m06_awid;
    end

    reg [IC_ID_WIDTH-1:0] seven_seg_rid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            seven_seg_rid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m06_arvalid && m06_arready)
            seven_seg_rid_reg <= m06_arid;
    end

    assign m06_awready = seven_seg_awready;
    assign m06_wready  = seven_seg_wready;
    assign m06_bvalid  = seven_seg_bvalid;
    assign m06_bresp   = seven_seg_bresp;
    assign m06_bid     = seven_seg_bid_reg;

    assign m06_arready = seven_seg_arready;
    assign m06_rvalid  = seven_seg_rvalid;
    assign m06_rdata   = seven_seg_rdata;
    assign m06_rresp   = seven_seg_rresp;
    assign m06_rid     = seven_seg_rid_reg;
    assign m06_rlast   = 1'b1;

    // ------------------------------------------------------------------------
    // AXI Interconnect 2x8
    //
    // Only S00 is used in this stage.
    // M03 is connected to UART  (0x4000_0000 - 0x4000_0FFF).
    // M04 is connected to SPI   (0x4000_1000 - 0x4000_1FFF).
    // M05 is connected to PWM   (0x4000_2000 - 0x4000_2FFF).
    // M06 is connected to 7-SEG (0x4000_3000 - 0x4000_3FFF).
    // ------------------------------------------------------------------------
    axi_interconnect_wrap_2x8 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(IC_ID_WIDTH),

        .M00_BASE_ADDR(0),
        .M00_ADDR_WIDTH(0),
        .M00_CONNECT_READ(2'b00),
        .M00_CONNECT_WRITE(2'b00),

        .M01_BASE_ADDR(0),
        .M01_ADDR_WIDTH(0),
        .M01_CONNECT_READ(2'b00),
        .M01_CONNECT_WRITE(2'b00),

        .M02_BASE_ADDR(0),
        .M02_ADDR_WIDTH(0),
        .M02_CONNECT_READ(2'b00),
        .M02_CONNECT_WRITE(2'b00),

        .M03_BASE_ADDR(32'h4000_0000),
        .M03_ADDR_WIDTH(12),
        .M03_CONNECT_READ(2'b01),
        .M03_CONNECT_WRITE(2'b01),

        .M04_BASE_ADDR(32'h4000_1000),
        .M04_ADDR_WIDTH(12),
        .M04_CONNECT_READ(2'b01),
        .M04_CONNECT_WRITE(2'b01),

        .M05_BASE_ADDR(32'h4000_2000),
        .M05_ADDR_WIDTH(12),
        .M05_CONNECT_READ(2'b01),
        .M05_CONNECT_WRITE(2'b01),

        .M06_BASE_ADDR(32'h4000_3000),
        .M06_ADDR_WIDTH(12),
        .M06_CONNECT_READ(2'b01),
        .M06_CONNECT_WRITE(2'b01),

        .M07_BASE_ADDR(0),
        .M07_ADDR_WIDTH(0),
        .M07_CONNECT_READ(2'b00),
        .M07_CONNECT_WRITE(2'b00)
    )
    interconnect_inst (
        .clk(clk),
        .rst(rst),

        // S00 = external test master
        .s00_axi_awid(axi_awid),
        .s00_axi_awaddr(axi_awaddr),
        .s00_axi_awlen(axi_awlen),
        .s00_axi_awsize(axi_awsize),
        .s00_axi_awburst(axi_awburst),
        .s00_axi_awlock(axi_awlock),
        .s00_axi_awcache(axi_awcache),
        .s00_axi_awprot(axi_awprot),
        .s00_axi_awqos(axi_awqos),
        .s00_axi_awuser(1'b0),
        .s00_axi_awvalid(axi_awvalid),
        .s00_axi_awready(axi_awready),
        .s00_axi_wdata(axi_wdata),
        .s00_axi_wstrb(axi_wstrb),
        .s00_axi_wlast(axi_wlast),
        .s00_axi_wuser(1'b0),
        .s00_axi_wvalid(axi_wvalid),
        .s00_axi_wready(axi_wready),
        .s00_axi_bid(axi_bid),
        .s00_axi_bresp(axi_bresp),
        .s00_axi_buser(),
        .s00_axi_bvalid(axi_bvalid),
        .s00_axi_bready(axi_bready),

        .s00_axi_arid(axi_arid),
        .s00_axi_araddr(axi_araddr),
        .s00_axi_arlen(axi_arlen),
        .s00_axi_arsize(axi_arsize),
        .s00_axi_arburst(axi_arburst),
        .s00_axi_arlock(axi_arlock),
        .s00_axi_arcache(axi_arcache),
        .s00_axi_arprot(axi_arprot),
        .s00_axi_arqos(axi_arqos),
        .s00_axi_aruser(1'b0),
        .s00_axi_arvalid(axi_arvalid),
        .s00_axi_arready(axi_arready),
        .s00_axi_rid(axi_rid),
        .s00_axi_rdata(axi_rdata),
        .s00_axi_rresp(axi_rresp),
        .s00_axi_rlast(axi_rlast),
        .s00_axi_ruser(),
        .s00_axi_rvalid(axi_rvalid),
        .s00_axi_rready(axi_rready),

        // S01 reserved for future second master
        .s01_axi_awid(8'd0),
        .s01_axi_awaddr(32'd0),
        .s01_axi_awlen(8'd0),
        .s01_axi_awsize(3'd0),
        .s01_axi_awburst(2'd0),
        .s01_axi_awlock(1'b0),
        .s01_axi_awcache(4'd0),
        .s01_axi_awprot(3'd0),
        .s01_axi_awqos(4'd0),
        .s01_axi_awuser(1'b0),
        .s01_axi_awvalid(1'b0),
        .s01_axi_awready(),
        .s01_axi_wdata(32'd0),
        .s01_axi_wstrb(4'd0),
        .s01_axi_wlast(1'b0),
        .s01_axi_wuser(1'b0),
        .s01_axi_wvalid(1'b0),
        .s01_axi_wready(),
        .s01_axi_bid(),
        .s01_axi_bresp(),
        .s01_axi_buser(),
        .s01_axi_bvalid(),
        .s01_axi_bready(1'b0),
        .s01_axi_arid(8'd0),
        .s01_axi_araddr(32'd0),
        .s01_axi_arlen(8'd0),
        .s01_axi_arsize(3'd0),
        .s01_axi_arburst(2'd0),
        .s01_axi_arlock(1'b0),
        .s01_axi_arcache(4'd0),
        .s01_axi_arprot(3'd0),
        .s01_axi_arqos(4'd0),
        .s01_axi_aruser(1'b0),
        .s01_axi_arvalid(1'b0),
        .s01_axi_arready(),
        .s01_axi_rid(),
        .s01_axi_rdata(),
        .s01_axi_rresp(),
        .s01_axi_rlast(),
        .s01_axi_ruser(),
        .s01_axi_rvalid(),
        .s01_axi_rready(1'b0),

        // M00 unused
        .m00_axi_awid(), .m00_axi_awaddr(), .m00_axi_awlen(), .m00_axi_awsize(),
        .m00_axi_awburst(), .m00_axi_awlock(), .m00_axi_awcache(), .m00_axi_awprot(),
        .m00_axi_awqos(), .m00_axi_awregion(), .m00_axi_awuser(), .m00_axi_awvalid(),
        .m00_axi_awready(1'b1), .m00_axi_wdata(), .m00_axi_wstrb(), .m00_axi_wlast(),
        .m00_axi_wuser(), .m00_axi_wvalid(), .m00_axi_wready(1'b1),
        .m00_axi_bid(8'd0), .m00_axi_bresp(2'b00), .m00_axi_buser(1'b0),
        .m00_axi_bvalid(1'b0), .m00_axi_bready(), .m00_axi_arid(), .m00_axi_araddr(),
        .m00_axi_arlen(), .m00_axi_arsize(), .m00_axi_arburst(), .m00_axi_arlock(),
        .m00_axi_arcache(), .m00_axi_arprot(), .m00_axi_arqos(), .m00_axi_arregion(),
        .m00_axi_aruser(), .m00_axi_arvalid(), .m00_axi_arready(1'b1),
        .m00_axi_rid(8'd0), .m00_axi_rdata(32'd0), .m00_axi_rresp(2'b00),
        .m00_axi_rlast(1'b1), .m00_axi_ruser(1'b0), .m00_axi_rvalid(1'b0),
        .m00_axi_rready(),

        // M01 unused
        .m01_axi_awid(), .m01_axi_awaddr(), .m01_axi_awlen(), .m01_axi_awsize(),
        .m01_axi_awburst(), .m01_axi_awlock(), .m01_axi_awcache(), .m01_axi_awprot(),
        .m01_axi_awqos(), .m01_axi_awregion(), .m01_axi_awuser(), .m01_axi_awvalid(),
        .m01_axi_awready(1'b1), .m01_axi_wdata(), .m01_axi_wstrb(), .m01_axi_wlast(),
        .m01_axi_wuser(), .m01_axi_wvalid(), .m01_axi_wready(1'b1),
        .m01_axi_bid(8'd0), .m01_axi_bresp(2'b00), .m01_axi_buser(1'b0),
        .m01_axi_bvalid(1'b0), .m01_axi_bready(), .m01_axi_arid(), .m01_axi_araddr(),
        .m01_axi_arlen(), .m01_axi_arsize(), .m01_axi_arburst(), .m01_axi_arlock(),
        .m01_axi_arcache(), .m01_axi_arprot(), .m01_axi_arqos(), .m01_axi_arregion(),
        .m01_axi_aruser(), .m01_axi_arvalid(), .m01_axi_arready(1'b1),
        .m01_axi_rid(8'd0), .m01_axi_rdata(32'd0), .m01_axi_rresp(2'b00),
        .m01_axi_rlast(1'b1), .m01_axi_ruser(1'b0), .m01_axi_rvalid(1'b0),
        .m01_axi_rready(),

        // M02 unused
        .m02_axi_awid(), .m02_axi_awaddr(), .m02_axi_awlen(), .m02_axi_awsize(),
        .m02_axi_awburst(), .m02_axi_awlock(), .m02_axi_awcache(), .m02_axi_awprot(),
        .m02_axi_awqos(), .m02_axi_awregion(), .m02_axi_awuser(), .m02_axi_awvalid(),
        .m02_axi_awready(1'b1), .m02_axi_wdata(), .m02_axi_wstrb(), .m02_axi_wlast(),
        .m02_axi_wuser(), .m02_axi_wvalid(), .m02_axi_wready(1'b1),
        .m02_axi_bid(8'd0), .m02_axi_bresp(2'b00), .m02_axi_buser(1'b0),
        .m02_axi_bvalid(1'b0), .m02_axi_bready(), .m02_axi_arid(), .m02_axi_araddr(),
        .m02_axi_arlen(), .m02_axi_arsize(), .m02_axi_arburst(), .m02_axi_arlock(),
        .m02_axi_arcache(), .m02_axi_arprot(), .m02_axi_arqos(), .m02_axi_arregion(),
        .m02_axi_aruser(), .m02_axi_arvalid(), .m02_axi_arready(1'b1),
        .m02_axi_rid(8'd0), .m02_axi_rdata(32'd0), .m02_axi_rresp(2'b00),
        .m02_axi_rlast(1'b1), .m02_axi_ruser(1'b0), .m02_axi_rvalid(1'b0),
        .m02_axi_rready(),

        // M03 -> UART
        .m03_axi_awid(m03_awid), .m03_axi_awaddr(m03_awaddr), .m03_axi_awlen(m03_awlen),
        .m03_axi_awsize(m03_awsize), .m03_axi_awburst(m03_awburst), .m03_axi_awlock(m03_awlock),
        .m03_axi_awcache(m03_awcache), .m03_axi_awprot(m03_awprot), .m03_axi_awqos(m03_awqos),
        .m03_axi_awregion(), .m03_axi_awuser(), .m03_axi_awvalid(m03_awvalid),
        .m03_axi_awready(m03_awready), .m03_axi_wdata(m03_wdata), .m03_axi_wstrb(m03_wstrb),
        .m03_axi_wlast(m03_wlast), .m03_axi_wuser(), .m03_axi_wvalid(m03_wvalid),
        .m03_axi_wready(m03_wready), .m03_axi_bid(m03_bid), .m03_axi_bresp(m03_bresp),
        .m03_axi_buser(), .m03_axi_bvalid(m03_bvalid), .m03_axi_bready(m03_bready),
        .m03_axi_arid(m03_arid), .m03_axi_araddr(m03_araddr), .m03_axi_arlen(m03_arlen),
        .m03_axi_arsize(m03_arsize), .m03_axi_arburst(m03_arburst), .m03_axi_arlock(m03_arlock),
        .m03_axi_arcache(m03_arcache), .m03_axi_arprot(m03_arprot), .m03_axi_arqos(m03_arqos),
        .m03_axi_arregion(), .m03_axi_aruser(), .m03_axi_arvalid(m03_arvalid),
        .m03_axi_arready(m03_arready), .m03_axi_rid(m03_rid), .m03_axi_rdata(m03_rdata),
        .m03_axi_rresp(m03_rresp), .m03_axi_rlast(m03_rlast), .m03_axi_ruser(),
        .m03_axi_rvalid(m03_rvalid), .m03_axi_rready(m03_rready),

        // M04 -> SPI
        .m04_axi_awid(m04_awid), .m04_axi_awaddr(m04_awaddr), .m04_axi_awlen(m04_awlen),
        .m04_axi_awsize(m04_awsize), .m04_axi_awburst(m04_awburst), .m04_axi_awlock(m04_awlock),
        .m04_axi_awcache(m04_awcache), .m04_axi_awprot(m04_awprot), .m04_axi_awqos(m04_awqos),
        .m04_axi_awregion(), .m04_axi_awuser(), .m04_axi_awvalid(m04_awvalid),
        .m04_axi_awready(m04_awready), .m04_axi_wdata(m04_wdata), .m04_axi_wstrb(m04_wstrb),
        .m04_axi_wlast(m04_wlast), .m04_axi_wuser(), .m04_axi_wvalid(m04_wvalid),
        .m04_axi_wready(m04_wready), .m04_axi_bid(m04_bid), .m04_axi_bresp(m04_bresp),
        .m04_axi_buser(), .m04_axi_bvalid(m04_bvalid), .m04_axi_bready(m04_bready),
        .m04_axi_arid(m04_arid), .m04_axi_araddr(m04_araddr), .m04_axi_arlen(m04_arlen),
        .m04_axi_arsize(m04_arsize), .m04_axi_arburst(m04_arburst), .m04_axi_arlock(m04_arlock),
        .m04_axi_arcache(m04_arcache), .m04_axi_arprot(m04_arprot), .m04_axi_arqos(m04_arqos),
        .m04_axi_arregion(), .m04_axi_aruser(), .m04_axi_arvalid(m04_arvalid),
        .m04_axi_arready(m04_arready), .m04_axi_rid(m04_rid), .m04_axi_rdata(m04_rdata),
        .m04_axi_rresp(m04_rresp), .m04_axi_rlast(m04_rlast), .m04_axi_ruser(),
        .m04_axi_rvalid(m04_rvalid), .m04_axi_rready(m04_rready),

        // M05 -> PWM
        .m05_axi_awid(m05_awid), .m05_axi_awaddr(m05_awaddr), .m05_axi_awlen(m05_awlen),
        .m05_axi_awsize(m05_awsize), .m05_axi_awburst(m05_awburst), .m05_axi_awlock(m05_awlock),
        .m05_axi_awcache(m05_awcache), .m05_axi_awprot(m05_awprot), .m05_axi_awqos(m05_awqos),
        .m05_axi_awregion(), .m05_axi_awuser(), .m05_axi_awvalid(m05_awvalid),
        .m05_axi_awready(m05_awready), .m05_axi_wdata(m05_wdata), .m05_axi_wstrb(m05_wstrb),
        .m05_axi_wlast(m05_wlast), .m05_axi_wuser(), .m05_axi_wvalid(m05_wvalid),
        .m05_axi_wready(m05_wready), .m05_axi_bid(m05_bid), .m05_axi_bresp(m05_bresp),
        .m05_axi_buser(), .m05_axi_bvalid(m05_bvalid), .m05_axi_bready(m05_bready),
        .m05_axi_arid(m05_arid), .m05_axi_araddr(m05_araddr), .m05_axi_arlen(m05_arlen),
        .m05_axi_arsize(m05_arsize), .m05_axi_arburst(m05_arburst), .m05_axi_arlock(m05_arlock),
        .m05_axi_arcache(m05_arcache), .m05_axi_arprot(m05_arprot), .m05_axi_arqos(m05_arqos),
        .m05_axi_arregion(), .m05_axi_aruser(), .m05_axi_arvalid(m05_arvalid),
        .m05_axi_arready(m05_arready), .m05_axi_rid(m05_rid), .m05_axi_rdata(m05_rdata),
        .m05_axi_rresp(m05_rresp), .m05_axi_rlast(m05_rlast), .m05_axi_ruser(),
        .m05_axi_rvalid(m05_rvalid), .m05_axi_rready(m05_rready),

        // M06 -> 7-Segment Display
        .m06_axi_awid(m06_awid), .m06_axi_awaddr(m06_awaddr), .m06_axi_awlen(m06_awlen),
        .m06_axi_awsize(m06_awsize), .m06_axi_awburst(m06_awburst), .m06_axi_awlock(m06_awlock),
        .m06_axi_awcache(m06_awcache), .m06_axi_awprot(m06_awprot), .m06_axi_awqos(m06_awqos),
        .m06_axi_awregion(), .m06_axi_awuser(), .m06_axi_awvalid(m06_awvalid),
        .m06_axi_awready(m06_awready), .m06_axi_wdata(m06_wdata), .m06_axi_wstrb(m06_wstrb),
        .m06_axi_wlast(m06_wlast), .m06_axi_wuser(), .m06_axi_wvalid(m06_wvalid),
        .m06_axi_wready(m06_wready), .m06_axi_bid(m06_bid), .m06_axi_bresp(m06_bresp),
        .m06_axi_buser(), .m06_axi_bvalid(m06_bvalid), .m06_axi_bready(m06_bready),
        .m06_axi_arid(m06_arid), .m06_axi_araddr(m06_araddr), .m06_axi_arlen(m06_arlen),
        .m06_axi_arsize(m06_arsize), .m06_axi_arburst(m06_arburst), .m06_axi_arlock(m06_arlock),
        .m06_axi_arcache(m06_arcache), .m06_axi_arprot(m06_arprot), .m06_axi_arqos(m06_arqos),
        .m06_axi_arregion(), .m06_axi_aruser(), .m06_axi_arvalid(m06_arvalid),
        .m06_axi_arready(m06_arready), .m06_axi_rid(m06_rid), .m06_axi_rdata(m06_rdata),
        .m06_axi_rresp(m06_rresp), .m06_axi_rlast(m06_rlast), .m06_axi_ruser(),
        .m06_axi_rvalid(m06_rvalid), .m06_axi_rready(m06_rready),

        // M07 unused
        .m07_axi_awid(), .m07_axi_awaddr(), .m07_axi_awlen(), .m07_axi_awsize(),
        .m07_axi_awburst(), .m07_axi_awlock(), .m07_axi_awcache(), .m07_axi_awprot(),
        .m07_axi_awqos(), .m07_axi_awregion(), .m07_axi_awuser(), .m07_axi_awvalid(),
        .m07_axi_awready(1'b1), .m07_axi_wdata(), .m07_axi_wstrb(), .m07_axi_wlast(),
        .m07_axi_wuser(), .m07_axi_wvalid(), .m07_axi_wready(1'b1),
        .m07_axi_bid(8'd0), .m07_axi_bresp(2'b00), .m07_axi_buser(1'b0),
        .m07_axi_bvalid(1'b0), .m07_axi_bready(), .m07_axi_arid(), .m07_axi_araddr(),
        .m07_axi_arlen(), .m07_axi_arsize(), .m07_axi_arburst(), .m07_axi_arlock(),
        .m07_axi_arcache(), .m07_axi_arprot(), .m07_axi_arqos(), .m07_axi_arregion(),
        .m07_axi_aruser(), .m07_axi_arvalid(), .m07_axi_arready(1'b1),
        .m07_axi_rid(8'd0), .m07_axi_rdata(32'd0), .m07_axi_rresp(2'b00),
        .m07_axi_rlast(1'b1), .m07_axi_ruser(1'b0), .m07_axi_rvalid(1'b0),
        .m07_axi_rready()
    );

    // ------------------------------------------------------------------------
    // UART
    // ------------------------------------------------------------------------
    axi_uart_top uart_inst (
        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (uart_arid),
        .axi_araddr_i      (uart_araddr),
        .axi_arvalid_i     (uart_arvalid),
        .axi_rready_i      (uart_rready),
        .axi_rresp_o       (uart_rresp),
        .axi_rdata_o       (uart_rdata),
        .axi_rid_o         (uart_rid),
        .axi_rvalid_o      (uart_rvalid),
        .axi_arready_o     (uart_arready),

        .axi_awid_i        (uart_awid),
        .axi_awaddr_i      (uart_awaddr),
        .axi_awvalid_i     (uart_awvalid),
        .axi_wdata_i       (uart_wdata),
        .axi_wstrb_i       (uart_wstrb),
        .axi_wvalid_i      (uart_wvalid),
        .axi_bready_i      (uart_bready),
        .axi_bresp_o       (uart_bresp),
        .axi_bid_o         (uart_bid),
        .axi_bvalid_o      (uart_bvalid),
        .axi_awready_o     (uart_awready),
        .axi_wready_o      (uart_wready),

        .uart_rx_i         (uart_rx_i),
        .read_interrupt_o  (uart_interrupt_o),
        .uart_tx_o         (uart_tx_o)
    );

    // ------------------------------------------------------------------------
    // SPI
    // ------------------------------------------------------------------------
    axi_spi_top spi_inst (
        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (spi_arid),
        .axi_araddr_i      (spi_araddr),
        .axi_arvalid_i     (spi_arvalid),
        .axi_rready_i      (spi_rready),
        .axi_rresp_o       (spi_rresp),
        .axi_rdata_o       (spi_rdata),
        .axi_rid_o         (spi_rid),
        .axi_rvalid_o      (spi_rvalid),
        .axi_arready_o     (spi_arready),

        .axi_awid_i        (spi_awid),
        .axi_awaddr_i      (spi_awaddr),
        .axi_awvalid_i     (spi_awvalid),
        .axi_wdata_i       (spi_wdata),
        .axi_wstrb_i       (spi_wstrb),
        .axi_wvalid_i      (spi_wvalid),
        .axi_bready_i      (spi_bready),
        .axi_bresp_o       (spi_bresp),
        .axi_bid_o         (spi_bid),
        .axi_bvalid_o      (spi_bvalid),
        .axi_awready_o     (spi_awready),
        .axi_wready_o      (spi_wready),

        .spi_clk_o         (spi_clk_o),
        .spi_cs_n_o        (spi_cs_n_o),
        .spi_mosi_o        (spi_mosi_o),
        .spi_miso_i        (spi_miso_i)
    );

    // ------------------------------------------------------------------------
    // PWM
    // ------------------------------------------------------------------------
    myip_v1_0 #(
        .C_S00_AXI_DATA_WIDTH (32),
        .C_S00_AXI_ADDR_WIDTH (4)
    ) pwm_inst (
        .s00_axi_aclk    (clk),
        .s00_axi_aresetn (~rst),

        .s00_axi_awaddr  (pwm_awaddr),
        .s00_axi_awprot  (m05_awprot),
        .s00_axi_awvalid (pwm_awvalid),
        .s00_axi_awready (pwm_awready),

        .s00_axi_wdata   (pwm_wdata),
        .s00_axi_wstrb   (pwm_wstrb),
        .s00_axi_wvalid  (pwm_wvalid),
        .s00_axi_wready  (pwm_wready),

        .s00_axi_bresp   (pwm_bresp),
        .s00_axi_bvalid  (pwm_bvalid),
        .s00_axi_bready  (pwm_bready),

        .s00_axi_araddr  (pwm_araddr),
        .s00_axi_arprot  (m05_arprot),
        .s00_axi_arvalid (pwm_arvalid),
        .s00_axi_arready (pwm_arready),

        .s00_axi_rdata   (pwm_rdata),
        .s00_axi_rresp   (pwm_rresp),
        .s00_axi_rvalid  (pwm_rvalid),
        .s00_axi_rready  (pwm_rready),

        .PWM_OUT         (pwm_out_o)
    );

    // ------------------------------------------------------------------------
    // 7-Segment Display IP
    // ------------------------------------------------------------------------
    axi_seven_segment #(
        .C_S_AXI_DATA_WIDTH (DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH (SEVEN_SEG_ADDR_WIDTH),
        .REFRESH_DIV        (SEVEN_SEG_REFRESH_DIV)
    ) seven_seg_inst (
        .s_axi_aclk         (clk),
        .s_axi_aresetn      (~rst),

        .s_axi_awaddr       (seven_seg_awaddr),
        .s_axi_awprot       (m06_awprot),
        .s_axi_awvalid      (seven_seg_awvalid),
        .s_axi_awready      (seven_seg_awready),

        .s_axi_wdata        (seven_seg_wdata),
        .s_axi_wstrb        (seven_seg_wstrb),
        .s_axi_wvalid       (seven_seg_wvalid),
        .s_axi_wready       (seven_seg_wready),

        .s_axi_bresp        (seven_seg_bresp),
        .s_axi_bvalid       (seven_seg_bvalid),
        .s_axi_bready       (seven_seg_bready),

        .s_axi_araddr       (seven_seg_araddr),
        .s_axi_arprot       (m06_arprot),
        .s_axi_arvalid      (seven_seg_arvalid),
        .s_axi_arready      (seven_seg_arready),

        .s_axi_rdata        (seven_seg_rdata),
        .s_axi_rresp        (seven_seg_rresp),
        .s_axi_rvalid       (seven_seg_rvalid),
        .s_axi_rready       (seven_seg_rready),

        .seg                (seg),
        .an                 (an)
    );

endmodule

`default_nettype wire
