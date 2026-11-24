// ============================================================================
// Module Name: soc_veer_el2_temperature_fan_top
// Description: Complete Integrated RISC-V SoC for Smart Temperature Monitoring
//              and Fan Control.
//
// Subsystems:
//   1. VeeR EL2 RISC-V 32-bit Core (RV32IMC)
//   2. 64-to-32 Width Adapters (LSU & IFU) + 2-to-1 Master Arbiter
//   3. 2-Master x 8-Slave AXI-4 Crossbar Interconnect (axi_interconnect_wrap_2x8)
//      - S00: External Test Master (32-bit AXI4)
//      - S01: VeeR EL2 Core Master (32-bit AXI4)
//   4. Slaves:
//      - M00: Unified Instruction/Data Memory (64 KiB: 0x0000_0000 - 0x0000_FFFF)
//      - M01: UART (4 KiB: 0x4000_0000 - 0x4000_0FFF)
//      - M02: GPIO (4 KiB: 0x4000_2000 - 0x4000_2FFF)
//      - M03: Timer (4 KiB: 0x4000_4000 - 0x4000_4FFF)
//      - M04: SPI Temperature Sensor Interface (4 KiB: 0x4000_6000 - 0x4000_6FFF)
//      - M05: PWM Fan Controller (4 KiB: 0x4000_A000 - 0x4000_AFFF)
//      - M06: Seven-Segment Display Controller (4 KiB: 0x4000_C000 - 0x4000_CFFF)
//      - M07: Masked / Disabled (0x0000_0000, 0 Bytes, Connect 2'b00)
// ============================================================================

`timescale 1ns / 1ps

module soc_veer_el2_temperature_fan_top
import el2_pkg::*;
#(
    parameter DATA_WIDTH            = 32,
    parameter ADDR_WIDTH            = 32,
    parameter IC_ID_WIDTH           = 8,
    parameter STRB_WIDTH            = DATA_WIDTH / 8,
    parameter GPIO_NUM_BITS         = 32,
    parameter TIMER_ADDR_WIDTH      = 32,
    parameter PWM_ADDR_WIDTH        = 4,
    parameter SEVEN_SEG_ADDR_WIDTH  = 12,
    parameter SEVEN_SEG_REFRESH_DIV = 100,
`include "el2_param.vh"
)(
    // Clock and Global Resets
    input  wire                      clk,
    input  wire                      rst,            // Active-high system reset
    input  wire                      core_rst_n_i,   // Active-high core run enable (active-low core reset)

    // ------------------------------------------------------------------------
    // External Test Master Interface (AXI4 Slave S00 on Crossbar)
    // ------------------------------------------------------------------------
    input  wire [IC_ID_WIDTH-1:0]    axi_awid,
    input  wire [ADDR_WIDTH-1:0]     axi_awaddr,
    input  wire [7:0]                axi_awlen,
    input  wire [2:0]                axi_awsize,
    input  wire [1:0]                axi_awburst,
    input  wire                      axi_awlock,
    input  wire [3:0]                axi_awcache,
    input  wire [2:0]                axi_awprot,
    input  wire [3:0]                axi_awqos,
    input  wire                      axi_awvalid,
    output wire                      axi_awready,

    input  wire [DATA_WIDTH-1:0]     axi_wdata,
    input  wire [STRB_WIDTH-1:0]     axi_wstrb,
    input  wire                      axi_wlast,
    input  wire                      axi_wvalid,
    output wire                      axi_wready,

    output wire [IC_ID_WIDTH-1:0]    axi_bid,
    output wire [1:0]                axi_bresp,
    output wire                      axi_bvalid,
    input  wire                      axi_bready,

    input  wire [IC_ID_WIDTH-1:0]    axi_arid,
    input  wire [ADDR_WIDTH-1:0]     axi_araddr,
    input  wire [7:0]                axi_arlen,
    input  wire [2:0]                axi_arsize,
    input  wire [1:0]                axi_arburst,
    input  wire                      axi_arlock,
    input  wire [3:0]                axi_arcache,
    input  wire [2:0]                axi_arprot,
    input  wire [3:0]                axi_arqos,
    input  wire                      axi_arvalid,
    output wire                      axi_arready,

    output wire [IC_ID_WIDTH-1:0]    axi_rid,
    output wire [DATA_WIDTH-1:0]     axi_rdata,
    output wire [1:0]                axi_rresp,
    output wire                      axi_rlast,
    output wire                      axi_rvalid,
    input  wire                      axi_rready,

    // ------------------------------------------------------------------------
    // Peripheral External Signals
    // ------------------------------------------------------------------------
    // UART
    input  wire                      uart_rx_i,
    output wire                      uart_tx_o,
    output wire                      uart_interrupt_o,

    // SPI (Temperature Sensor)
    output wire                      spi_clk_o,
    output wire                      spi_cs_n_o,
    output wire                      spi_mosi_o,
    input  wire                      spi_miso_i,
    output wire                      spi_irq_o,

    // PWM (Fan Controller)
    output wire                      pwm_out_o,
    output wire                      pwm_irq_o,

    // Seven-Segment Display
    output wire [6:0]                seg,
    output wire [3:0]                an,

    // GPIO
    inout  wire [GPIO_NUM_BITS-1:0]  gpio_io,
    output wire                      gpio_intr_o,

    // Timer
    input  wire                      timer_ext_meas_i,
    input  wire                      timer_capture_i,
    output wire                      timer_pwm_o,
    output wire                      timer_trigger_o,
    output wire                      timer_irq_o,

    // ------------------------------------------------------------------------
    // VeeR EL2 Core Trace / Observability Interface
    // ------------------------------------------------------------------------
    output wire [31:0]               trace_rv_i_insn_ip,
    output wire [31:0]               trace_rv_i_address_ip,
    output wire                      trace_rv_i_valid_ip,
    output wire                      trace_rv_i_exception_ip,
    output wire [4:0]                trace_rv_i_ecause_ip,
    output wire                      trace_rv_i_interrupt_ip,
    output wire [31:0]               trace_rv_i_tval_ip
);

    // =========================================================================
    // Core Clock and Reset Generation
    // =========================================================================
    wire core_rst_l = ~rst & core_rst_n_i;
    wire dbg_rst_l  = ~rst;

    // =========================================================================
    // Memory Export Interfaces for VeeR EL2 Pipeline
    // =========================================================================
    el2_mem_if el2_mem_export();
    el2_mem_if el2_icache_export();

    // =========================================================================
    // Core 64-bit AXI Interfaces
    // =========================================================================
    // LSU
    wire        lsu_axi_awvalid;
    wire        lsu_axi_awready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_awid;
    wire [31:0] lsu_axi_awaddr;
    wire [3:0]  lsu_axi_awregion;
    wire [7:0]  lsu_axi_awlen;
    wire [2:0]  lsu_axi_awsize;
    wire [1:0]  lsu_axi_awburst;
    wire        lsu_axi_awlock;
    wire [3:0]  lsu_axi_awcache;
    wire [2:0]  lsu_axi_awprot;
    wire [3:0]  lsu_axi_awqos;

    wire        lsu_axi_wvalid;
    wire        lsu_axi_wready;
    wire [63:0] lsu_axi_wdata;
    wire [7:0]  lsu_axi_wstrb;
    wire        lsu_axi_wlast;

    wire        lsu_axi_bvalid;
    wire        lsu_axi_bready;
    wire [1:0]  lsu_axi_bresp;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_bid;

    wire        lsu_axi_arvalid;
    wire        lsu_axi_arready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_arid;
    wire [31:0] lsu_axi_araddr;
    wire [3:0]  lsu_axi_arregion;
    wire [7:0]  lsu_axi_arlen;
    wire [2:0]  lsu_axi_arsize;
    wire [1:0]  lsu_axi_arburst;
    wire        lsu_axi_arlock;
    wire [3:0]  lsu_axi_arcache;
    wire [2:0]  lsu_axi_arprot;
    wire [3:0]  lsu_axi_arqos;

    wire        lsu_axi_rvalid;
    wire        lsu_axi_rready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_rid;
    wire [63:0] lsu_axi_rdata;
    wire [1:0]  lsu_axi_rresp;
    wire        lsu_axi_rlast;

    // IFU
    wire        ifu_axi_awvalid;
    wire        ifu_axi_awready = 1'b1;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_awid;
    wire [31:0] ifu_axi_awaddr;
    wire [3:0]  ifu_axi_awregion;
    wire [7:0]  ifu_axi_awlen;
    wire [2:0]  ifu_axi_awsize;
    wire [1:0]  ifu_axi_awburst;
    wire        ifu_axi_awlock;
    wire [3:0]  ifu_axi_awcache;
    wire [2:0]  ifu_axi_awprot;
    wire [3:0]  ifu_axi_awqos;

    wire        ifu_axi_wvalid;
    wire        ifu_axi_wready = 1'b1;
    wire [63:0] ifu_axi_wdata;
    wire [7:0]  ifu_axi_wstrb;
    wire        ifu_axi_wlast;

    wire        ifu_axi_bvalid = 1'b0;
    wire        ifu_axi_bready;
    wire [1:0]  ifu_axi_bresp  = 2'b00;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_bid = {pt.IFU_BUS_TAG{1'b0}};

    wire        ifu_axi_arvalid;
    wire        ifu_axi_arready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_arid;
    wire [31:0] ifu_axi_araddr;
    wire [3:0]  ifu_axi_arregion;
    wire [7:0]  ifu_axi_arlen;
    wire [2:0]  ifu_axi_arsize;
    wire [1:0]  ifu_axi_arburst;
    wire        ifu_axi_arlock;
    wire [3:0]  ifu_axi_arcache;
    wire [2:0]  ifu_axi_arprot;
    wire [3:0]  ifu_axi_arqos;

    wire        ifu_axi_rvalid;
    wire        ifu_axi_rready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_rid;
    wire [63:0] ifu_axi_rdata;
    wire [1:0]  ifu_axi_rresp;
    wire        ifu_axi_rlast;

    // PIC Interrupt vector mapping
    wire [pt.PIC_TOTAL_INT:1] extintsrc_req;
    assign extintsrc_req[1] = uart_interrupt_o;
    assign extintsrc_req[2] = spi_irq_o;
    assign extintsrc_req[3] = gpio_intr_o;
    assign extintsrc_req[4] = pwm_irq_o;
    assign extintsrc_req[pt.PIC_TOTAL_INT:5] = {(pt.PIC_TOTAL_INT-4){1'b0}};

    // =========================================================================
    // VeeR EL2 Core Wrapper Instantiation
    // =========================================================================
    el2_veer_wrapper core_inst (
        .clk                     (clk),
        .rst_l                   (core_rst_l),
        .dbg_rst_l               (dbg_rst_l),
        .rst_vec                 (31'h0000_0000), // Boot from Unified Memory base
        .nmi_int                 (1'b0),
        .nmi_vec                 (31'h0000_0000),
        .jtag_id                 (31'h0000_0001),

        .trace_rv_i_insn_ip      (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip   (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip     (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip (trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip    (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip (trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip      (trace_rv_i_tval_ip),

        // LSU AXI4
        .lsu_axi_awvalid         (lsu_axi_awvalid),
        .lsu_axi_awready         (lsu_axi_awready),
        .lsu_axi_awid            (lsu_axi_awid),
        .lsu_axi_awaddr          (lsu_axi_awaddr),
        .lsu_axi_awregion        (lsu_axi_awregion),
        .lsu_axi_awlen           (lsu_axi_awlen),
        .lsu_axi_awsize          (lsu_axi_awsize),
        .lsu_axi_awburst         (lsu_axi_awburst),
        .lsu_axi_awlock          (lsu_axi_awlock),
        .lsu_axi_awcache         (lsu_axi_awcache),
        .lsu_axi_awprot          (lsu_axi_awprot),
        .lsu_axi_awqos           (lsu_axi_awqos),

        .lsu_axi_wvalid          (lsu_axi_wvalid),
        .lsu_axi_wready          (lsu_axi_wready),
        .lsu_axi_wdata           (lsu_axi_wdata),
        .lsu_axi_wstrb           (lsu_axi_wstrb),
        .lsu_axi_wlast           (lsu_axi_wlast),

        .lsu_axi_bvalid          (lsu_axi_bvalid),
        .lsu_axi_bready          (lsu_axi_bready),
        .lsu_axi_bresp           (lsu_axi_bresp),
        .lsu_axi_bid             (lsu_axi_bid),

        .lsu_axi_arvalid         (lsu_axi_arvalid),
        .lsu_axi_arready         (lsu_axi_arready),
        .lsu_axi_arid            (lsu_axi_arid),
        .lsu_axi_araddr          (lsu_axi_araddr),
        .lsu_axi_arregion        (lsu_axi_arregion),
        .lsu_axi_arlen           (lsu_axi_arlen),
        .lsu_axi_arsize          (lsu_axi_arsize),
        .lsu_axi_arburst         (lsu_axi_arburst),
        .lsu_axi_arlock          (lsu_axi_arlock),
        .lsu_axi_arcache         (lsu_axi_arcache),
        .lsu_axi_arprot          (lsu_axi_arprot),
        .lsu_axi_arqos           (lsu_axi_arqos),

        .lsu_axi_rvalid          (lsu_axi_rvalid),
        .lsu_axi_rready          (lsu_axi_rready),
        .lsu_axi_rid             (lsu_axi_rid),
        .lsu_axi_rdata           (lsu_axi_rdata),
        .lsu_axi_rresp           (lsu_axi_rresp),
        .lsu_axi_rlast           (lsu_axi_rlast),

        // IFU AXI4
        .ifu_axi_awvalid         (ifu_axi_awvalid),
        .ifu_axi_awready         (ifu_axi_awready),
        .ifu_axi_awid            (ifu_axi_awid),
        .ifu_axi_awaddr          (ifu_axi_awaddr),
        .ifu_axi_awregion        (ifu_axi_awregion),
        .ifu_axi_awlen           (ifu_axi_awlen),
        .ifu_axi_awsize          (ifu_axi_awsize),
        .ifu_axi_awburst         (ifu_axi_awburst),
        .ifu_axi_awlock          (ifu_axi_awlock),
        .ifu_axi_awcache         (ifu_axi_awcache),
        .ifu_axi_awprot          (ifu_axi_awprot),
        .ifu_axi_awqos           (ifu_axi_awqos),

        .ifu_axi_wvalid          (ifu_axi_wvalid),
        .ifu_axi_wready          (ifu_axi_wready),
        .ifu_axi_wdata           (ifu_axi_wdata),
        .ifu_axi_wstrb           (ifu_axi_wstrb),
        .ifu_axi_wlast           (ifu_axi_wlast),

        .ifu_axi_bvalid          (ifu_axi_bvalid),
        .ifu_axi_bready          (ifu_axi_bready),
        .ifu_axi_bresp           (ifu_axi_bresp),
        .ifu_axi_bid             (ifu_axi_bid),

        .ifu_axi_arvalid         (ifu_axi_arvalid),
        .ifu_axi_arready         (ifu_axi_arready),
        .ifu_axi_arid            (ifu_axi_arid),
        .ifu_axi_araddr          (ifu_axi_araddr),
        .ifu_axi_arregion        (ifu_axi_arregion),
        .ifu_axi_arlen           (ifu_axi_arlen),
        .ifu_axi_arsize          (ifu_axi_arsize),
        .ifu_axi_arburst         (ifu_axi_arburst),
        .ifu_axi_arlock          (ifu_axi_arlock),
        .ifu_axi_arcache         (ifu_axi_arcache),
        .ifu_axi_arprot          (ifu_axi_arprot),
        .ifu_axi_arqos           (ifu_axi_arqos),

        .ifu_axi_rvalid          (ifu_axi_rvalid),
        .ifu_axi_rready          (ifu_axi_rready),
        .ifu_axi_rid             (ifu_axi_rid),
        .ifu_axi_rdata           (ifu_axi_rdata),
        .ifu_axi_rresp           (ifu_axi_rresp),
        .ifu_axi_rlast           (ifu_axi_rlast),

        // SB AXI (Tied off)
        .sb_axi_awvalid          (),
        .sb_axi_awready          (1'b1),
        .sb_axi_awid             (),
        .sb_axi_awaddr           (),
        .sb_axi_awregion         (),
        .sb_axi_awlen            (),
        .sb_axi_awsize           (),
        .sb_axi_awburst          (),
        .sb_axi_awlock           (),
        .sb_axi_awcache          (),
        .sb_axi_awprot           (),
        .sb_axi_awqos            (),
        .sb_axi_wvalid           (),
        .sb_axi_wready           (1'b1),
        .sb_axi_wdata            (),
        .sb_axi_wstrb            (),
        .sb_axi_wlast            (),
        .sb_axi_bvalid           (1'b0),
        .sb_axi_bready           (),
        .sb_axi_bresp            (2'b00),
        .sb_axi_bid              ({pt.SB_BUS_TAG{1'b0}}),
        .sb_axi_arvalid          (),
        .sb_axi_arready          (1'b1),
        .sb_axi_arid             (),
        .sb_axi_araddr           (),
        .sb_axi_arregion         (),
        .sb_axi_arlen            (),
        .sb_axi_arsize           (),
        .sb_axi_arburst          (),
        .sb_axi_arlock           (),
        .sb_axi_arcache          (),
        .sb_axi_arprot           (),
        .sb_axi_arqos            (),
        .sb_axi_rvalid           (1'b0),
        .sb_axi_rready           (),
        .sb_axi_rid              ({pt.SB_BUS_TAG{1'b0}}),
        .sb_axi_rdata            (64'd0),
        .sb_axi_rresp            (2'b00),
        .sb_axi_rlast            (1'b1),

        // DMA AXI (Tied off)
        .dma_axi_awvalid         (1'b0),
        .dma_axi_awready         (),
        .dma_axi_awid            ({pt.DMA_BUS_TAG{1'b0}}),
        .dma_axi_awaddr          (32'd0),
        .dma_axi_awsize          (3'd0),
        .dma_axi_awprot          (3'd0),
        .dma_axi_awlen           (8'd0),
        .dma_axi_awburst         (2'd0),
        .dma_axi_wvalid          (1'b0),
        .dma_axi_wready          (),
        .dma_axi_wdata           (64'd0),
        .dma_axi_wstrb           (8'd0),
        .dma_axi_wlast           (1'b0),
        .dma_axi_bvalid          (),
        .dma_axi_bready          (1'b1),
        .dma_axi_bresp           (),
        .dma_axi_bid             (),
        .dma_axi_arvalid         (1'b0),
        .dma_axi_arready         (),
        .dma_axi_arid            ({pt.DMA_BUS_TAG{1'b0}}),
        .dma_axi_araddr          (32'd0),
        .dma_axi_arsize          (3'd0),
        .dma_axi_arprot          (3'd0),
        .dma_axi_arlen           (8'd0),
        .dma_axi_arburst         (2'd0),
        .dma_axi_rvalid          (),
        .dma_axi_rready          (1'b1),
        .dma_axi_rid             (),
        .dma_axi_rdata           (),
        .dma_axi_rresp           (),
        .dma_axi_rlast           (),

        // Clock ratios
        .lsu_bus_clk_en          (1'b1),
        .ifu_bus_clk_en          (1'b1),
        .dbg_bus_clk_en          (1'b1),
        .dma_bus_clk_en          (1'b1),

        // Interrupts
        .timer_int               (timer_irq_o),
        .soft_int                (1'b0),
        .extintsrc_req           (extintsrc_req),

        .dec_tlu_perfcnt0        (),
        .dec_tlu_perfcnt1        (),
        .dec_tlu_perfcnt2        (),
        .dec_tlu_perfcnt3        (),

        // JTAG (Tied to inactive defaults, reset cleanly with system reset)
        .jtag_tck                (1'b0),
        .jtag_tms                (1'b0),
        .jtag_tdi                (1'b0),
        .jtag_trst_n             (~rst),
        .jtag_tdo                (),
        .jtag_tdoEn              (),

        .core_id                 (28'd0),

        // Internal SRAM & ICache interfaces
        .el2_mem_export          (el2_mem_export.veer_sram_src),
        .el2_icache_export       (el2_icache_export.veer_icache_src),

        // MPC debug controls
        .mpc_debug_halt_req      (1'b0),
        .mpc_debug_run_req       (1'b0),
        .mpc_reset_run_req       (1'b1),
        .mpc_debug_halt_ack      (),
        .mpc_debug_run_ack       (),
        .debug_brkpt_status      (),

        // CPU halt / run controls
        .i_cpu_halt_req          (1'b0),
        .o_cpu_halt_ack          (),
        .o_cpu_halt_status       (),
        .o_debug_mode_status     (),
        .i_cpu_run_req           (1'b0),
        .o_cpu_run_ack           (),

        // Test and DMI controls
        .scan_mode               (1'b0),
        .mbist_mode              (1'b0),
        .dmi_core_enable         (1'b0),
        .dmi_uncore_enable       (1'b0),
        .dmi_uncore_en           (),
        .dmi_uncore_wr_en        (),
        .dmi_uncore_addr         (),
        .dmi_uncore_wdata        (),
        .dmi_uncore_rdata        (32'd0),
        .dmi_active              ()
    );

    // =========================================================================
    // 64-to-32 Width Adapters
    // =========================================================================
    // 32-bit LSU AXI Signals
    wire        lsu32_awvalid;
    wire        lsu32_awready;
    wire [IC_ID_WIDTH-1:0] lsu32_awid;
    wire [31:0] lsu32_awaddr;
    wire [3:0]  lsu32_awregion;
    wire [7:0]  lsu32_awlen;
    wire [2:0]  lsu32_awsize;
    wire [1:0]  lsu32_awburst;
    wire        lsu32_awlock;
    wire [3:0]  lsu32_awcache;
    wire [2:0]  lsu32_awprot;
    wire [3:0]  lsu32_awqos;

    wire        lsu32_wvalid;
    wire        lsu32_wready;
    wire [31:0] lsu32_wdata;
    wire [3:0]  lsu32_wstrb;
    wire        lsu32_wlast;

    wire        lsu32_bvalid;
    wire        lsu32_bready;
    wire [IC_ID_WIDTH-1:0] lsu32_bid;
    wire [1:0]  lsu32_bresp;

    wire        lsu32_arvalid;
    wire        lsu32_arready;
    wire [IC_ID_WIDTH-1:0] lsu32_arid;
    wire [31:0] lsu32_araddr;
    wire [3:0]  lsu32_arregion;
    wire [7:0]  lsu32_arlen;
    wire [2:0]  lsu32_arsize;
    wire [1:0]  lsu32_arburst;
    wire        lsu32_arlock;
    wire [3:0]  lsu32_arcache;
    wire [2:0]  lsu32_arprot;
    wire [3:0]  lsu32_arqos;

    wire        lsu32_rvalid;
    wire        lsu32_rready;
    wire [IC_ID_WIDTH-1:0] lsu32_rid;
    wire [31:0] lsu32_rdata;
    wire [1:0]  lsu32_rresp;
    wire        lsu32_rlast;

    axi_adapter_lsu_64_to_32 #(
        .ID_WIDTH(IC_ID_WIDTH)
    ) lsu_adapter_inst (
        .clk            (clk),
        .rst            (rst),

        .s_axi_awvalid  (lsu_axi_awvalid),
        .s_axi_awready  (lsu_axi_awready),
        .s_axi_awid     ({{(IC_ID_WIDTH-pt.LSU_BUS_TAG){1'b0}}, lsu_axi_awid}),
        .s_axi_awaddr   (lsu_axi_awaddr),
        .s_axi_awregion (lsu_axi_awregion),
        .s_axi_awlen    (lsu_axi_awlen),
        .s_axi_awsize   (lsu_axi_awsize),
        .s_axi_awburst  (lsu_axi_awburst),
        .s_axi_awlock   (lsu_axi_awlock),
        .s_axi_awcache  (lsu_axi_awcache),
        .s_axi_awprot   (lsu_axi_awprot),
        .s_axi_awqos    (lsu_axi_awqos),

        .s_axi_wvalid   (lsu_axi_wvalid),
        .s_axi_wready   (lsu_axi_wready),
        .s_axi_wdata    (lsu_axi_wdata),
        .s_axi_wstrb    (lsu_axi_wstrb),
        .s_axi_wlast    (lsu_axi_wlast),

        .s_axi_bvalid   (lsu_axi_bvalid),
        .s_axi_bready   (lsu_axi_bready),
        .s_axi_bid      (lsu_axi_bid),
        .s_axi_bresp    (lsu_axi_bresp),

        .s_axi_arvalid  (lsu_axi_arvalid),
        .s_axi_arready  (lsu_axi_arready),
        .s_axi_arid     ({{(IC_ID_WIDTH-pt.LSU_BUS_TAG){1'b0}}, lsu_axi_arid}),
        .s_axi_araddr   (lsu_axi_araddr),
        .s_axi_arregion (lsu_axi_arregion),
        .s_axi_arlen    (lsu_axi_arlen),
        .s_axi_arsize   (lsu_axi_arsize),
        .s_axi_arburst  (lsu_axi_arburst),
        .s_axi_arlock   (lsu_axi_arlock),
        .s_axi_arcache  (lsu_axi_arcache),
        .s_axi_arprot   (lsu_axi_arprot),
        .s_axi_arqos    (lsu_axi_arqos),

        .s_axi_rvalid   (lsu_axi_rvalid),
        .s_axi_rready   (lsu_axi_rready),
        .s_axi_rid      (lsu_axi_rid),
        .s_axi_rdata    (lsu_axi_rdata),
        .s_axi_rresp    (lsu_axi_rresp),
        .s_axi_rlast    (lsu_axi_rlast),

        .m_axi_awvalid  (lsu32_awvalid),
        .m_axi_awready  (lsu32_awready),
        .m_axi_awid     (lsu32_awid),
        .m_axi_awaddr   (lsu32_awaddr),
        .m_axi_awregion (lsu32_awregion),
        .m_axi_awlen    (lsu32_awlen),
        .m_axi_awsize   (lsu32_awsize),
        .m_axi_awburst  (lsu32_awburst),
        .m_axi_awlock   (lsu32_awlock),
        .m_axi_awcache  (lsu32_awcache),
        .m_axi_awprot   (lsu32_awprot),
        .m_axi_awqos    (lsu32_awqos),

        .m_axi_wvalid   (lsu32_wvalid),
        .m_axi_wready   (lsu32_wready),
        .m_axi_wdata    (lsu32_wdata),
        .m_axi_wstrb    (lsu32_wstrb),
        .m_axi_wlast    (lsu32_wlast),

        .m_axi_bvalid   (lsu32_bvalid),
        .m_axi_bready   (lsu32_bready),
        .m_axi_bid      (lsu32_bid),
        .m_axi_bresp    (lsu32_bresp),

        .m_axi_arvalid  (lsu32_arvalid),
        .m_axi_arready  (lsu32_arready),
        .m_axi_arid     (lsu32_arid),
        .m_axi_araddr   (lsu32_araddr),
        .m_axi_arregion (lsu32_arregion),
        .m_axi_arlen    (lsu32_arlen),
        .m_axi_arsize   (lsu32_arsize),
        .m_axi_arburst  (lsu32_arburst),
        .m_axi_arlock   (lsu32_arlock),
        .m_axi_arcache  (lsu32_arcache),
        .m_axi_arprot   (lsu32_arprot),
        .m_axi_arqos    (lsu32_arqos),

        .m_axi_rvalid   (lsu32_rvalid),
        .m_axi_rready   (lsu32_rready),
        .m_axi_rid      (lsu32_rid),
        .m_axi_rdata    (lsu32_rdata),
        .m_axi_rresp    (lsu32_rresp),
        .m_axi_rlast    (lsu32_rlast)
    );

    // 32-bit IFU AXI Signals
    wire        ifu32_arvalid;
    wire        ifu32_arready;
    wire [IC_ID_WIDTH-1:0] ifu32_arid;
    wire [31:0] ifu32_araddr;
    wire [3:0]  ifu32_arregion;
    wire [7:0]  ifu32_arlen;
    wire [2:0]  ifu32_arsize;
    wire [1:0]  ifu32_arburst;
    wire        ifu32_arlock;
    wire [3:0]  ifu32_arcache;
    wire [2:0]  ifu32_arprot;
    wire [3:0]  ifu32_arqos;

    wire        ifu32_rvalid;
    wire        ifu32_rready;
    wire [IC_ID_WIDTH-1:0] ifu32_rid;
    wire [31:0] ifu32_rdata;
    wire [1:0]  ifu32_rresp;
    wire        ifu32_rlast;

    axi_adapter_ifu_64_to_32 #(
        .ID_WIDTH(IC_ID_WIDTH)
    ) ifu_adapter_inst (
        .clk            (clk),
        .rst            (rst),

        .s_axi_arvalid  (ifu_axi_arvalid),
        .s_axi_arready  (ifu_axi_arready),
        .s_axi_arid     ({{(IC_ID_WIDTH-pt.IFU_BUS_TAG){1'b0}}, ifu_axi_arid}),
        .s_axi_araddr   (ifu_axi_araddr),
        .s_axi_arregion (ifu_axi_arregion),
        .s_axi_arlen    (ifu_axi_arlen),
        .s_axi_arsize   (ifu_axi_arsize),
        .s_axi_arburst  (ifu_axi_arburst),
        .s_axi_arlock   (ifu_axi_arlock),
        .s_axi_arcache  (ifu_axi_arcache),
        .s_axi_arprot   (ifu_axi_arprot),
        .s_axi_arqos    (ifu_axi_arqos),

        .s_axi_rvalid   (ifu_axi_rvalid),
        .s_axi_rready   (ifu_axi_rready),
        .s_axi_rid      (ifu_axi_rid),
        .s_axi_rdata    (ifu_axi_rdata),
        .s_axi_rresp    (ifu_axi_rresp),
        .s_axi_rlast    (ifu_axi_rlast),

        .m_axi_arvalid  (ifu32_arvalid),
        .m_axi_arready  (ifu32_arready),
        .m_axi_arid     (ifu32_arid),
        .m_axi_araddr   (ifu32_araddr),
        .m_axi_arregion (ifu32_arregion),
        .m_axi_arlen    (ifu32_arlen),
        .m_axi_arsize   (ifu32_arsize),
        .m_axi_arburst  (ifu32_arburst),
        .m_axi_arlock   (ifu32_arlock),
        .m_axi_arcache  (ifu32_arcache),
        .m_axi_arprot   (ifu32_arprot),
        .m_axi_arqos    (ifu32_arqos),

        .m_axi_rvalid   (ifu32_rvalid),
        .m_axi_rready   (ifu32_rready),
        .m_axi_rid      (ifu32_rid),
        .m_axi_rdata    (ifu32_rdata),
        .m_axi_rresp    (ifu32_rresp),
        .m_axi_rlast    (ifu32_rlast)
    );

    // =========================================================================
    // 2-to-1 Master Arbiter (LSU + IFU -> S01 of Crossbar)
    // =========================================================================
    wire        s01_awvalid;
    wire        s01_awready;
    wire [IC_ID_WIDTH-1:0] s01_awid;
    wire [ADDR_WIDTH-1:0]  s01_awaddr;
    wire [3:0]  s01_awregion;
    wire [7:0]  s01_awlen;
    wire [2:0]  s01_awsize;
    wire [1:0]  s01_awburst;
    wire        s01_awlock;
    wire [3:0]  s01_awcache;
    wire [2:0]  s01_awprot;
    wire [3:0]  s01_awqos;

    wire        s01_wvalid;
    wire        s01_wready;
    wire [DATA_WIDTH-1:0] s01_wdata;
    wire [STRB_WIDTH-1:0] s01_wstrb;
    wire        s01_wlast;

    wire        s01_bvalid;
    wire        s01_bready;
    wire [IC_ID_WIDTH-1:0] s01_bid;
    wire [1:0]  s01_bresp;

    wire        s01_arvalid;
    wire        s01_arready;
    wire [IC_ID_WIDTH-1:0] s01_arid;
    wire [ADDR_WIDTH-1:0]  s01_araddr;
    wire [3:0]  s01_arregion;
    wire [7:0]  s01_arlen;
    wire [2:0]  s01_arsize;
    wire [1:0]  s01_arburst;
    wire        s01_arlock;
    wire [3:0]  s01_arcache;
    wire [2:0]  s01_arprot;
    wire [3:0]  s01_arqos;

    wire        s01_rvalid;
    wire        s01_rready;
    wire [IC_ID_WIDTH-1:0] s01_rid;
    wire [DATA_WIDTH-1:0]  s01_rdata;
    wire [1:0]  s01_rresp;
    wire        s01_rlast;

    axi_arbiter_2to1 #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .ID_WIDTH   (IC_ID_WIDTH)
    ) core_arbiter_inst (
        .clk            (clk),
        .rst            (rst),

        // Slave 0: LSU
        .s0_axi_awvalid (lsu32_awvalid),
        .s0_axi_awready (lsu32_awready),
        .s0_axi_awid    (lsu32_awid),
        .s0_axi_awaddr  (lsu32_awaddr),
        .s0_axi_awregion(lsu32_awregion),
        .s0_axi_awlen   (lsu32_awlen),
        .s0_axi_awsize  (lsu32_awsize),
        .s0_axi_awburst (lsu32_awburst),
        .s0_axi_awlock  (lsu32_awlock),
        .s0_axi_awcache (lsu32_awcache),
        .s0_axi_awprot  (lsu32_awprot),
        .s0_axi_awqos   (lsu32_awqos),

        .s0_axi_wvalid  (lsu32_wvalid),
        .s0_axi_wready  (lsu32_wready),
        .s0_axi_wdata   (lsu32_wdata),
        .s0_axi_wstrb   (lsu32_wstrb),
        .s0_axi_wlast   (lsu32_wlast),

        .s0_axi_bvalid  (lsu32_bvalid),
        .s0_axi_bready  (lsu32_bready),
        .s0_axi_bid     (lsu32_bid),
        .s0_axi_bresp   (lsu32_bresp),

        .s0_axi_arvalid (lsu32_arvalid),
        .s0_axi_arready (lsu32_arready),
        .s0_axi_arid    (lsu32_arid),
        .s0_axi_araddr  (lsu32_araddr),
        .s0_axi_arregion(lsu32_arregion),
        .s0_axi_arlen   (lsu32_arlen),
        .s0_axi_arsize  (lsu32_arsize),
        .s0_axi_arburst (lsu32_arburst),
        .s0_axi_arlock  (lsu32_arlock),
        .s0_axi_arcache (lsu32_arcache),
        .s0_axi_arprot  (lsu32_arprot),
        .s0_axi_arqos   (lsu32_arqos),

        .s0_axi_rvalid  (lsu32_rvalid),
        .s0_axi_rready  (lsu32_rready),
        .s0_axi_rid     (lsu32_rid),
        .s0_axi_rdata   (lsu32_rdata),
        .s0_axi_rresp   (lsu32_rresp),
        .s0_axi_rlast   (lsu32_rlast),

        // Slave 1: IFU
        .s1_axi_arvalid (ifu32_arvalid),
        .s1_axi_arready (ifu32_arready),
        .s1_axi_arid    (ifu32_arid),
        .s1_axi_araddr  (ifu32_araddr),
        .s1_axi_arregion(ifu32_arregion),
        .s1_axi_arlen   (ifu32_arlen),
        .s1_axi_arsize  (ifu32_arsize),
        .s1_axi_arburst (ifu32_arburst),
        .s1_axi_arlock  (ifu32_arlock),
        .s1_axi_arcache (ifu32_arcache),
        .s1_axi_arprot  (ifu32_arprot),
        .s1_axi_arqos   (ifu32_arqos),

        .s1_axi_rvalid  (ifu32_rvalid),
        .s1_axi_rready  (ifu32_rready),
        .s1_axi_rid     (ifu32_rid),
        .s1_axi_rdata   (ifu32_rdata),
        .s1_axi_rresp   (ifu32_rresp),
        .s1_axi_rlast   (ifu32_rlast),

        // Combined Master to S01
        .m_axi_awvalid  (s01_awvalid),
        .m_axi_awready  (s01_awready),
        .m_axi_awid     (s01_awid),
        .m_axi_awaddr   (s01_awaddr),
        .m_axi_awregion (s01_awregion),
        .m_axi_awlen    (s01_awlen),
        .m_axi_awsize   (s01_awsize),
        .m_axi_awburst  (s01_awburst),
        .m_axi_awlock   (s01_awlock),
        .m_axi_awcache  (s01_awcache),
        .m_axi_awprot   (s01_awprot),
        .m_axi_awqos    (s01_awqos),

        .m_axi_wvalid   (s01_wvalid),
        .m_axi_wready   (s01_wready),
        .m_axi_wdata    (s01_wdata),
        .m_axi_wstrb    (s01_wstrb),
        .m_axi_wlast    (s01_wlast),

        .m_axi_bvalid   (s01_bvalid),
        .m_axi_bready   (s01_bready),
        .m_axi_bid      (s01_bid),
        .m_axi_bresp    (s01_bresp),

        .m_axi_arvalid  (s01_arvalid),
        .m_axi_arready  (s01_arready),
        .m_axi_arid     (s01_arid),
        .m_axi_araddr   (s01_araddr),
        .m_axi_arregion (s01_arregion),
        .m_axi_arlen    (s01_arlen),
        .m_axi_arsize   (s01_arsize),
        .m_axi_arburst  (s01_arburst),
        .m_axi_arlock   (s01_arlock),
        .m_axi_arcache  (s01_arcache),
        .m_axi_arprot   (s01_arprot),
        .m_axi_arqos    (s01_arqos),

        .m_axi_rvalid   (s01_rvalid),
        .m_axi_rready   (s01_rready),
        .m_axi_rid      (s01_rid),
        .m_axi_rdata    (s01_rdata),
        .m_axi_rresp    (s01_rresp),
        .m_axi_rlast    (s01_rlast)
    );

    // =========================================================================
    // Crossbar Slave Port Wires (M00 through M07)
    // =========================================================================
    // M00 -> Unified Memory
    wire [IC_ID_WIDTH-1:0] m00_awid;
    wire [ADDR_WIDTH-1:0]  m00_awaddr;
    wire [7:0]             m00_awlen;
    wire [2:0]             m00_awsize;
    wire [1:0]             m00_awburst;
    wire                   m00_awlock;
    wire [3:0]             m00_awcache;
    wire [2:0]             m00_awprot;
    wire [3:0]             m00_awqos;
    wire                   m00_awvalid;
    wire                   m00_awready;
    wire [DATA_WIDTH-1:0]  m00_wdata;
    wire [STRB_WIDTH-1:0]  m00_wstrb;
    wire                   m00_wlast;
    wire                   m00_wvalid;
    wire                   m00_wready;
    wire [IC_ID_WIDTH-1:0] m00_bid;
    wire [1:0]             m00_bresp;
    wire                   m00_bvalid;
    wire                   m00_bready;
    wire [IC_ID_WIDTH-1:0] m00_arid;
    wire [ADDR_WIDTH-1:0]  m00_araddr;
    wire [7:0]             m00_arlen;
    wire [2:0]             m00_arsize;
    wire [1:0]             m00_arburst;
    wire                   m00_arlock;
    wire [3:0]             m00_arcache;
    wire [2:0]             m00_arprot;
    wire [3:0]             m00_arqos;
    wire                   m00_arvalid;
    wire                   m00_arready;
    wire [IC_ID_WIDTH-1:0] m00_rid;
    wire [DATA_WIDTH-1:0]  m00_rdata;
    wire [1:0]             m00_rresp;
    wire                   m00_rlast;
    wire                   m00_rvalid;
    wire                   m00_rready;

    // M01 -> UART
    wire [IC_ID_WIDTH-1:0] m01_awid;
    wire [ADDR_WIDTH-1:0]  m01_awaddr;
    wire [7:0]             m01_awlen;
    wire [2:0]             m01_awsize;
    wire [1:0]             m01_awburst;
    wire                   m01_awlock;
    wire [3:0]             m01_awcache;
    wire [2:0]             m01_awprot;
    wire [3:0]             m01_awqos;
    wire                   m01_awvalid;
    wire                   m01_awready;
    wire [DATA_WIDTH-1:0]  m01_wdata;
    wire [STRB_WIDTH-1:0]  m01_wstrb;
    wire                   m01_wlast;
    wire                   m01_wvalid;
    wire                   m01_wready;
    wire [IC_ID_WIDTH-1:0] m01_bid;
    wire [1:0]             m01_bresp;
    wire                   m01_bvalid;
    wire                   m01_bready;
    wire [IC_ID_WIDTH-1:0] m01_arid;
    wire [ADDR_WIDTH-1:0]  m01_araddr;
    wire [7:0]             m01_arlen;
    wire [2:0]             m01_arsize;
    wire [1:0]             m01_arburst;
    wire                   m01_arlock;
    wire [3:0]             m01_arcache;
    wire [2:0]             m01_arprot;
    wire [3:0]             m01_arqos;
    wire                   m01_arvalid;
    wire                   m01_arready;
    wire [IC_ID_WIDTH-1:0] m01_rid;
    wire [DATA_WIDTH-1:0]  m01_rdata;
    wire [1:0]             m01_rresp;
    wire                   m01_rlast;
    wire                   m01_rvalid;
    wire                   m01_rready;

    // M02 -> GPIO
    wire [IC_ID_WIDTH-1:0] m02_awid;
    wire [ADDR_WIDTH-1:0]  m02_awaddr;
    wire [7:0]             m02_awlen;
    wire [2:0]             m02_awsize;
    wire [1:0]             m02_awburst;
    wire                   m02_awlock;
    wire [3:0]             m02_awcache;
    wire [2:0]             m02_awprot;
    wire [3:0]             m02_awqos;
    wire                   m02_awvalid;
    wire                   m02_awready;
    wire [DATA_WIDTH-1:0]  m02_wdata;
    wire [STRB_WIDTH-1:0]  m02_wstrb;
    wire                   m02_wlast;
    wire                   m02_wvalid;
    wire                   m02_wready;
    wire [IC_ID_WIDTH-1:0] m02_bid;
    wire [1:0]             m02_bresp;
    wire                   m02_bvalid;
    wire                   m02_bready;
    wire [IC_ID_WIDTH-1:0] m02_arid;
    wire [ADDR_WIDTH-1:0]  m02_araddr;
    wire [7:0]             m02_arlen;
    wire [2:0]             m02_arsize;
    wire [1:0]             m02_arburst;
    wire                   m02_arlock;
    wire [3:0]             m02_arcache;
    wire [2:0]             m02_arprot;
    wire [3:0]             m02_arqos;
    wire                   m02_arvalid;
    wire                   m02_arready;
    wire [IC_ID_WIDTH-1:0] m02_rid;
    wire [DATA_WIDTH-1:0]  m02_rdata;
    wire [1:0]             m02_rresp;
    wire                   m02_rlast;
    wire                   m02_rvalid;
    wire                   m02_rready;

    // M03 -> Timer
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

    // M04 -> SPI
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

    // M05 -> PWM
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

    // M06 -> Seven-Segment Display
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

    // =========================================================================
    // 2-Master x 8-Slave AXI Crossbar Interconnect
    // =========================================================================
    axi_interconnect_wrap_2x8 #(
        .DATA_WIDTH        (DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH),
        .ID_WIDTH          (IC_ID_WIDTH),

        // M00 -> Unified Memory (64 KiB: 0x0000_0000 - 0x0000_FFFF)
        .M00_BASE_ADDR     (32'h0000_0000),
        .M00_ADDR_WIDTH    (16),
        .M00_CONNECT_READ  (2'b11),
        .M00_CONNECT_WRITE (2'b11),

        // M01 -> UART (4 KiB: 0x4000_0000 - 0x4000_0FFF)
        .M01_BASE_ADDR     (32'h4000_0000),
        .M01_ADDR_WIDTH    (12),
        .M01_CONNECT_READ  (2'b11),
        .M01_CONNECT_WRITE (2'b11),

        // M02 -> GPIO (4 KiB: 0x4000_2000 - 0x4000_2FFF)
        .M02_BASE_ADDR     (32'h4000_2000),
        .M02_ADDR_WIDTH    (12),
        .M02_CONNECT_READ  (2'b11),
        .M02_CONNECT_WRITE (2'b11),

        // M03 -> Timer (4 KiB: 0x4000_4000 - 0x4000_4FFF)
        .M03_BASE_ADDR     (32'h4000_4000),
        .M03_ADDR_WIDTH    (12),
        .M03_CONNECT_READ  (2'b11),
        .M03_CONNECT_WRITE (2'b11),

        // M04 -> SPI (4 KiB: 0x4000_6000 - 0x4000_6FFF)
        .M04_BASE_ADDR     (32'h4000_6000),
        .M04_ADDR_WIDTH    (12),
        .M04_CONNECT_READ  (2'b11),
        .M04_CONNECT_WRITE (2'b11),

        // M05 -> PWM (4 KiB: 0x4000_A000 - 0x4000_AFFF)
        .M05_BASE_ADDR     (32'h4000_A000),
        .M05_ADDR_WIDTH    (12),
        .M05_CONNECT_READ  (2'b11),
        .M05_CONNECT_WRITE (2'b11),

        // M06 -> Seven-Segment Display (4 KiB: 0x4000_C000 - 0x4000_CFFF)
        .M06_BASE_ADDR     (32'h4000_C000),
        .M06_ADDR_WIDTH    (12),
        .M06_CONNECT_READ  (2'b11),
        .M06_CONNECT_WRITE (2'b11),

        // M07 -> Masked / Disabled Final Slave Port
        .M07_BASE_ADDR     (32'h0000_0000),
        .M07_ADDR_WIDTH    (0),
        .M07_CONNECT_READ  (2'b00),
        .M07_CONNECT_WRITE (2'b00)
    ) interconnect_inst (
        .clk(clk),
        .rst(rst),

        // S00: External Test Master
        .s00_axi_awid      (axi_awid),
        .s00_axi_awaddr    (axi_awaddr),
        .s00_axi_awlen     (axi_awlen),
        .s00_axi_awsize    (axi_awsize),
        .s00_axi_awburst   (axi_awburst),
        .s00_axi_awlock    (axi_awlock),
        .s00_axi_awcache   (axi_awcache),
        .s00_axi_awprot    (axi_awprot),
        .s00_axi_awqos     (axi_awqos),
        .s00_axi_awuser    (1'b0),
        .s00_axi_awvalid   (axi_awvalid),
        .s00_axi_awready   (axi_awready),
        .s00_axi_wdata     (axi_wdata),
        .s00_axi_wstrb     (axi_wstrb),
        .s00_axi_wlast     (axi_wlast),
        .s00_axi_wuser     (1'b0),
        .s00_axi_wvalid    (axi_wvalid),
        .s00_axi_wready    (axi_wready),
        .s00_axi_bid       (axi_bid),
        .s00_axi_bresp     (axi_bresp),
        .s00_axi_buser     (),
        .s00_axi_bvalid    (axi_bvalid),
        .s00_axi_bready    (axi_bready),
        .s00_axi_arid      (axi_arid),
        .s00_axi_araddr    (axi_araddr),
        .s00_axi_arlen     (axi_arlen),
        .s00_axi_arsize    (axi_arsize),
        .s00_axi_arburst   (axi_arburst),
        .s00_axi_arlock    (axi_arlock),
        .s00_axi_arcache   (axi_arcache),
        .s00_axi_arprot    (axi_arprot),
        .s00_axi_arqos     (axi_arqos),
        .s00_axi_aruser    (1'b0),
        .s00_axi_arvalid   (axi_arvalid),
        .s00_axi_arready   (axi_arready),
        .s00_axi_rid       (axi_rid),
        .s00_axi_rdata     (axi_rdata),
        .s00_axi_rresp     (axi_rresp),
        .s00_axi_rlast     (axi_rlast),
        .s00_axi_ruser     (),
        .s00_axi_rvalid    (axi_rvalid),
        .s00_axi_rready    (axi_rready),

        // S01: VeeR EL2 Core Master
        .s01_axi_awid      (s01_awid),
        .s01_axi_awaddr    (s01_awaddr),
        .s01_axi_awlen     (s01_awlen),
        .s01_axi_awsize    (s01_awsize),
        .s01_axi_awburst   (s01_awburst),
        .s01_axi_awlock    (s01_awlock),
        .s01_axi_awcache   (s01_awcache),
        .s01_axi_awprot    (s01_awprot),
        .s01_axi_awqos     (s01_awqos),
        .s01_axi_awuser    (1'b0),
        .s01_axi_awvalid   (s01_awvalid),
        .s01_axi_awready   (s01_awready),
        .s01_axi_wdata     (s01_wdata),
        .s01_axi_wstrb     (s01_wstrb),
        .s01_axi_wlast     (s01_wlast),
        .s01_axi_wuser     (1'b0),
        .s01_axi_wvalid    (s01_wvalid),
        .s01_axi_wready    (s01_wready),
        .s01_axi_bid       (s01_bid),
        .s01_axi_bresp     (s01_bresp),
        .s01_axi_buser     (),
        .s01_axi_bvalid    (s01_bvalid),
        .s01_axi_bready    (s01_bready),
        .s01_axi_arid      (s01_arid),
        .s01_axi_araddr    (s01_araddr),
        .s01_axi_arlen     (s01_arlen),
        .s01_axi_arsize    (s01_arsize),
        .s01_axi_arburst   (s01_arburst),
        .s01_axi_arlock    (s01_arlock),
        .s01_axi_arcache   (s01_arcache),
        .s01_axi_arprot    (s01_arprot),
        .s01_axi_arqos     (s01_arqos),
        .s01_axi_aruser    (1'b0),
        .s01_axi_arvalid   (s01_arvalid),
        .s01_axi_arready   (s01_arready),
        .s01_axi_rid       (s01_rid),
        .s01_axi_rdata     (s01_rdata),
        .s01_axi_rresp     (s01_rresp),
        .s01_axi_rlast     (s01_rlast),
        .s01_axi_ruser     (),
        .s01_axi_rvalid    (s01_rvalid),
        .s01_axi_rready    (s01_rready),

        // M00 -> Unified Memory
        .m00_axi_awid(m00_awid), .m00_axi_awaddr(m00_awaddr), .m00_axi_awlen(m00_awlen),
        .m00_axi_awsize(m00_awsize), .m00_axi_awburst(m00_awburst), .m00_axi_awlock(m00_awlock),
        .m00_axi_awcache(m00_awcache), .m00_axi_awprot(m00_awprot), .m00_axi_awqos(m00_awqos),
        .m00_axi_awregion(), .m00_axi_awuser(), .m00_axi_awvalid(m00_awvalid),
        .m00_axi_awready(m00_awready), .m00_axi_wdata(m00_wdata), .m00_axi_wstrb(m00_wstrb),
        .m00_axi_wlast(m00_wlast), .m00_axi_wuser(), .m00_axi_wvalid(m00_wvalid),
        .m00_axi_wready(m00_wready), .m00_axi_bid(m00_bid), .m00_axi_bresp(m00_bresp),
        .m00_axi_buser(), .m00_axi_bvalid(m00_bvalid), .m00_axi_bready(m00_bready),
        .m00_axi_arid(m00_arid), .m00_axi_araddr(m00_araddr), .m00_axi_arlen(m00_arlen),
        .m00_axi_arsize(m00_arsize), .m00_axi_arburst(m00_arburst), .m00_axi_arlock(m00_arlock),
        .m00_axi_arcache(m00_arcache), .m00_axi_arprot(m00_arprot), .m00_axi_arqos(m00_arqos),
        .m00_axi_arregion(), .m00_axi_aruser(), .m00_axi_arvalid(m00_arvalid),
        .m00_axi_arready(m00_arready), .m00_axi_rid(m00_rid), .m00_axi_rdata(m00_rdata),
        .m00_axi_rresp(m00_rresp), .m00_axi_rlast(m00_rlast), .m00_axi_ruser(),
        .m00_axi_rvalid(m00_rvalid), .m00_axi_rready(m00_rready),

        // M01 -> UART
        .m01_axi_awid(m01_awid), .m01_axi_awaddr(m01_awaddr), .m01_axi_awlen(m01_awlen),
        .m01_axi_awsize(m01_awsize), .m01_axi_awburst(m01_awburst), .m01_axi_awlock(m01_awlock),
        .m01_axi_awcache(m01_awcache), .m01_axi_awprot(m01_awprot), .m01_axi_awqos(m01_awqos),
        .m01_axi_awregion(), .m01_axi_awuser(), .m01_axi_awvalid(m01_awvalid),
        .m01_axi_awready(m01_awready), .m01_axi_wdata(m01_wdata), .m01_axi_wstrb(m01_wstrb),
        .m01_axi_wlast(m01_wlast), .m01_axi_wuser(), .m01_axi_wvalid(m01_wvalid),
        .m01_axi_wready(m01_wready), .m01_axi_bid(m01_bid), .m01_axi_bresp(m01_bresp),
        .m01_axi_buser(), .m01_axi_bvalid(m01_bvalid), .m01_axi_bready(m01_bready),
        .m01_axi_arid(m01_arid), .m01_axi_araddr(m01_araddr), .m01_axi_arlen(m01_arlen),
        .m01_axi_arsize(m01_arsize), .m01_axi_arburst(m01_arburst), .m01_axi_arlock(m01_arlock),
        .m01_axi_arcache(m01_arcache), .m01_axi_arprot(m01_arprot), .m01_axi_arqos(m01_arqos),
        .m01_axi_arregion(), .m01_axi_aruser(), .m01_axi_arvalid(m01_arvalid),
        .m01_axi_arready(m01_arready), .m01_axi_rid(m01_rid), .m01_axi_rdata(m01_rdata),
        .m01_axi_rresp(m01_rresp), .m01_axi_rlast(m01_rlast), .m01_axi_ruser(),
        .m01_axi_rvalid(m01_rvalid), .m01_axi_rready(m01_rready),

        // M02 -> GPIO
        .m02_axi_awid(m02_awid), .m02_axi_awaddr(m02_awaddr), .m02_axi_awlen(m02_awlen),
        .m02_axi_awsize(m02_awsize), .m02_axi_awburst(m02_awburst), .m02_axi_awlock(m02_awlock),
        .m02_axi_awcache(m02_awcache), .m02_axi_awprot(m02_awprot), .m02_axi_awqos(m02_awqos),
        .m02_axi_awregion(), .m02_axi_awuser(), .m02_axi_awvalid(m02_awvalid),
        .m02_axi_awready(m02_awready), .m02_axi_wdata(m02_wdata), .m02_axi_wstrb(m02_wstrb),
        .m02_axi_wlast(m02_wlast), .m02_axi_wuser(), .m02_axi_wvalid(m02_wvalid),
        .m02_axi_wready(m02_wready), .m02_axi_bid(m02_bid), .m02_axi_bresp(m02_bresp),
        .m02_axi_buser(), .m02_axi_bvalid(m02_bvalid), .m02_axi_bready(m02_bready),
        .m02_axi_arid(m02_arid), .m02_axi_araddr(m02_araddr), .m02_axi_arlen(m02_arlen),
        .m02_axi_arsize(m02_arsize), .m02_axi_arburst(m02_arburst), .m02_axi_arlock(m02_arlock),
        .m02_axi_arcache(m02_arcache), .m02_axi_arprot(m02_arprot), .m02_axi_arqos(m02_arqos),
        .m02_axi_arregion(), .m02_axi_aruser(), .m02_axi_arvalid(m02_arvalid),
        .m02_axi_arready(m02_arready), .m02_axi_rid(m02_rid), .m02_axi_rdata(m02_rdata),
        .m02_axi_rresp(m02_rresp), .m02_axi_rlast(m02_rlast), .m02_axi_ruser(),
        .m02_axi_rvalid(m02_rvalid), .m02_axi_rready(m02_rready),

        // M03 -> Timer
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

        // M06 -> Seven-Segment Display
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

        // M07 -> Masked / Disabled
        .m07_axi_awid(), .m07_axi_awaddr(), .m07_axi_awlen(), .m07_axi_awsize(),
        .m07_axi_awburst(), .m07_axi_awlock(), .m07_axi_awcache(), .m07_axi_awprot(),
        .m07_axi_awqos(), .m07_axi_awregion(), .m07_axi_awuser(), .m07_axi_awvalid(),
        .m07_axi_awready(1'b1), .m07_axi_wdata(), .m07_axi_wstrb(), .m07_axi_wlast(),
        .m07_axi_wuser(), .m07_axi_wvalid(), .m07_axi_wready(1'b1),
        .m07_axi_bid({IC_ID_WIDTH{1'b0}}), .m07_axi_bresp(2'b00), .m07_axi_buser(1'b0),
        .m07_axi_bvalid(1'b0), .m07_axi_bready(), .m07_axi_arid(), .m07_axi_araddr(),
        .m07_axi_arlen(), .m07_axi_arsize(), .m07_axi_arburst(), .m07_axi_arlock(),
        .m07_axi_arcache(), .m07_axi_arprot(), .m07_axi_arqos(), .m07_axi_arregion(),
        .m07_axi_aruser(), .m07_axi_arvalid(), .m07_axi_arready(1'b1),
        .m07_axi_rid({IC_ID_WIDTH{1'b0}}), .m07_axi_rdata(32'd0), .m07_axi_rresp(2'b00),
        .m07_axi_rlast(1'b1), .m07_axi_ruser(1'b0), .m07_axi_rvalid(1'b0),
        .m07_axi_rready()
    );

    // =========================================================================
    // Slave 0: Unified Instruction & Data Memory (M00)
    // =========================================================================
    soc_memory_axi #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH  (IC_ID_WIDTH),
        .MEM_SIZE  (65536)
    ) unified_mem_inst (
        .clk          (clk),
        .rst          (rst),

        .s_axi_awid   (m00_awid),
        .s_axi_awaddr (m00_awaddr),
        .s_axi_awlen  (m00_awlen),
        .s_axi_awsize (m00_awsize),
        .s_axi_awburst(m00_awburst),
        .s_axi_awlock (m00_awlock),
        .s_axi_awcache(m00_awcache),
        .s_axi_awprot (m00_awprot),
        .s_axi_awqos  (m00_awqos),
        .s_axi_awvalid(m00_awvalid),
        .s_axi_awready(m00_awready),

        .s_axi_wdata  (m00_wdata),
        .s_axi_wstrb  (m00_wstrb),
        .s_axi_wlast  (m00_wlast),
        .s_axi_wvalid (m00_wvalid),
        .s_axi_wready (m00_wready),

        .s_axi_bid    (m00_bid),
        .s_axi_bresp  (m00_bresp),
        .s_axi_bvalid (m00_bvalid),
        .s_axi_bready (m00_bready),

        .s_axi_arid   (m00_arid),
        .s_axi_araddr (m00_araddr),
        .s_axi_arlen  (m00_arlen),
        .s_axi_arsize (m00_arsize),
        .s_axi_arburst(m00_arburst),
        .s_axi_arlock (m00_arlock),
        .s_axi_arcache(m00_arcache),
        .s_axi_arprot (m00_arprot),
        .s_axi_arqos  (m00_arqos),
        .s_axi_arvalid(m00_arvalid),
        .s_axi_arready(m00_arready),

        .s_axi_rid    (m00_rid),
        .s_axi_rdata  (m00_rdata),
        .s_axi_rresp  (m00_rresp),
        .s_axi_rlast  (m00_rlast),
        .s_axi_rvalid (m00_rvalid),
        .s_axi_rready (m00_rready)
    );

    // =========================================================================
    // Slave 1: UART (M01: 0x4000_0000)
    // =========================================================================
    axi_uart_top uart_inst (
        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (m01_arid[3:0]),
        .axi_araddr_i      (m01_araddr),
        .axi_arvalid_i     (m01_arvalid),
        .axi_rready_i      (m01_rready),
        .axi_rresp_o       (m01_rresp),
        .axi_rdata_o       (m01_rdata),
        .axi_rid_o         (m01_rid[3:0]),
        .axi_rvalid_o      (m01_rvalid),
        .axi_arready_o     (m01_arready),

        .axi_awid_i        (m01_awid[3:0]),
        .axi_awaddr_i      (m01_awaddr),
        .axi_awvalid_i     (m01_awvalid),
        .axi_wdata_i       (m01_wdata),
        .axi_wstrb_i       (m01_wstrb),
        .axi_wvalid_i      (m01_wvalid),
        .axi_bready_i      (m01_bready),
        .axi_bresp_o       (m01_bresp),
        .axi_bid_o         (m01_bid[3:0]),
        .axi_bvalid_o      (m01_bvalid),
        .axi_awready_o     (m01_awready),
        .axi_wready_o      (m01_wready),

        .uart_rx_i         (uart_rx_i),
        .read_interrupt_o  (uart_interrupt_o),
        .uart_tx_o         (uart_tx_o)
    );
    assign m01_rid[IC_ID_WIDTH-1:4] = {(IC_ID_WIDTH-4){1'b0}};
    assign m01_bid[IC_ID_WIDTH-1:4] = {(IC_ID_WIDTH-4){1'b0}};
    assign m01_rlast = 1'b1;

    // =========================================================================
    // Slave 2: GPIO (M02: 0x4000_2000)
    // =========================================================================
    reg [IC_ID_WIDTH-1:0] gpio_bid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) gpio_bid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m02_awvalid && m02_awready) gpio_bid_reg <= m02_awid;
    end

    reg [IC_ID_WIDTH-1:0] gpio_rid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) gpio_rid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m02_arvalid && m02_arready) gpio_rid_reg <= m02_arid;
    end

    gpio_axi #(
        .NUM_BITS (GPIO_NUM_BITS)
    ) gpio_inst (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (~rst),

        .s_axi_awaddr  (m02_awaddr),
        .s_axi_awprot  (m02_awprot),
        .s_axi_awvalid (m02_awvalid),
        .s_axi_awready (m02_awready),

        .s_axi_wdata   (m02_wdata),
        .s_axi_wstrb   (m02_wstrb),
        .s_axi_wvalid  (m02_wvalid),
        .s_axi_wready  (m02_wready),

        .s_axi_bresp   (m02_bresp),
        .s_axi_bvalid  (m02_bvalid),
        .s_axi_bready  (m02_bready),

        .s_axi_araddr  (m02_araddr),
        .s_axi_arprot  (m02_arprot),
        .s_axi_arvalid (m02_arvalid),
        .s_axi_arready (m02_arready),

        .s_axi_rdata   (m02_rdata),
        .s_axi_rresp   (m02_rresp),
        .s_axi_rvalid  (m02_rvalid),
        .s_axi_rready  (m02_rready),

        .io            (gpio_io),
        .intr          (gpio_intr_o)
    );
    assign m02_bid   = gpio_bid_reg;
    assign m02_rid   = gpio_rid_reg;
    assign m02_rlast = 1'b1;

    // =========================================================================
    // Slave 3: Timer (M03: 0x4000_4000)
    // =========================================================================
    reg [IC_ID_WIDTH-1:0] timer_bid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) timer_bid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m03_awvalid && m03_awready) timer_bid_reg <= m03_awid;
    end

    reg [IC_ID_WIDTH-1:0] timer_rid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) timer_rid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m03_arvalid && m03_arready) timer_rid_reg <= m03_arid;
    end

    timer_axi timer_inst (
        .aclk       (clk),
        .aresetn    (~rst),

        .awaddr     (m03_awaddr),
        .awprot     (m03_awprot),
        .awvalid    (m03_awvalid),
        .awready    (m03_awready),

        .wdata      (m03_wdata),
        .wstrb      (m03_wstrb),
        .wvalid     (m03_wvalid),
        .wready     (m03_wready),

        .bresp      (m03_bresp),
        .bvalid     (m03_bvalid),
        .bready     (m03_bready),

        .araddr     (m03_araddr),
        .arprot     (m03_arprot),
        .arvalid    (m03_arvalid),
        .arready    (m03_arready),

        .rdata      (m03_rdata),
        .rresp      (m03_rresp),
        .rvalid     (m03_rvalid),
        .rready     (m03_rready),

        .ext_meas_i (timer_ext_meas_i),
        .capture_i  (timer_capture_i),
        .pwm_o      (timer_pwm_o),
        .trigger_o  (timer_trigger_o),
        .irq        (timer_irq_o)
    );
    assign m03_bid   = timer_bid_reg;
    assign m03_rid   = timer_rid_reg;
    assign m03_rlast = 1'b1;

    // =========================================================================
    // Slave 4: SPI (M04: 0x4000_6000)
    // =========================================================================
    axi_spi_top spi_inst (
        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (m04_arid[3:0]),
        .axi_araddr_i      (m04_araddr),
        .axi_arvalid_i     (m04_arvalid),
        .axi_rready_i      (m04_rready),
        .axi_rresp_o       (m04_rresp),
        .axi_rdata_o       (m04_rdata),
        .axi_rid_o         (m04_rid[3:0]),
        .axi_rvalid_o      (m04_rvalid),
        .axi_arready_o     (m04_arready),

        .axi_awid_i        (m04_awid[3:0]),
        .axi_awaddr_i      (m04_awaddr),
        .axi_awvalid_i     (m04_awvalid),
        .axi_wdata_i       (m04_wdata),
        .axi_wstrb_i       (m04_wstrb),
        .axi_wvalid_i      (m04_wvalid),
        .axi_bready_i      (m04_bready),
        .axi_bresp_o       (m04_bresp),
        .axi_bid_o         (m04_bid[3:0]),
        .axi_bvalid_o      (m04_bvalid),
        .axi_awready_o     (m04_awready),
        .axi_wready_o      (m04_wready),

        .spi_clk_o         (spi_clk_o),
        .spi_cs_n_o        (spi_cs_n_o),
        .spi_mosi_o        (spi_mosi_o),
        .spi_miso_i        (spi_miso_i)
    );
    assign m04_rid[IC_ID_WIDTH-1:4] = {(IC_ID_WIDTH-4){1'b0}};
    assign m04_bid[IC_ID_WIDTH-1:4] = {(IC_ID_WIDTH-4){1'b0}};
    assign m04_rlast = 1'b1;
    assign spi_irq_o = 1'b0; // Internal status polled or tied

    // =========================================================================
    // Slave 5: PWM (M05: 0x4000_A000)
    // =========================================================================
    reg [IC_ID_WIDTH-1:0] pwm_bid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) pwm_bid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m05_awvalid && m05_awready) pwm_bid_reg <= m05_awid;
    end

    reg [IC_ID_WIDTH-1:0] pwm_rid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) pwm_rid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m05_arvalid && m05_arready) pwm_rid_reg <= m05_arid;
    end

    myip_v1_0 #(
        .C_S00_AXI_DATA_WIDTH (32),
        .C_S00_AXI_ADDR_WIDTH (PWM_ADDR_WIDTH)
    ) pwm_inst (
        .s00_axi_aclk    (clk),
        .s00_axi_aresetn (~rst),

        .s00_axi_awaddr  (m05_awaddr[PWM_ADDR_WIDTH-1:0]),
        .s00_axi_awprot  (m05_awprot),
        .s00_axi_awvalid (m05_awvalid),
        .s00_axi_awready (m05_awready),

        .s00_axi_wdata   (m05_wdata),
        .s00_axi_wstrb   (m05_wstrb),
        .s00_axi_wvalid  (m05_wvalid),
        .s00_axi_wready  (m05_wready),

        .s00_axi_bresp   (m05_bresp),
        .s00_axi_bvalid  (m05_bvalid),
        .s00_axi_bready  (m05_bready),

        .s00_axi_araddr  (m05_araddr[PWM_ADDR_WIDTH-1:0]),
        .s00_axi_arprot  (m05_arprot),
        .s00_axi_arvalid (m05_arvalid),
        .s00_axi_arready (m05_arready),

        .s00_axi_rdata   (m05_rdata),
        .s00_axi_rresp   (m05_rresp),
        .s00_axi_rvalid  (m05_rvalid),
        .s00_axi_rready  (m05_rready),

        .PWM_OUT         (pwm_out_o)
    );
    assign m05_bid   = pwm_bid_reg;
    assign m05_rid   = pwm_rid_reg;
    assign m05_rlast = 1'b1;
    assign pwm_irq_o = 1'b0;

    // =========================================================================
    // Slave 6: Seven-Segment Display (M06: 0x4000_C000)
    // =========================================================================
    reg [IC_ID_WIDTH-1:0] seg_bid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) seg_bid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m06_awvalid && m06_awready) seg_bid_reg <= m06_awid;
    end

    reg [IC_ID_WIDTH-1:0] seg_rid_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) seg_rid_reg <= {IC_ID_WIDTH{1'b0}};
        else if (m06_arvalid && m06_arready) seg_rid_reg <= m06_arid;
    end

    axi_seven_segment #(
        .C_S_AXI_DATA_WIDTH (DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH (SEVEN_SEG_ADDR_WIDTH),
        .REFRESH_DIV        (SEVEN_SEG_REFRESH_DIV)
    ) seven_seg_inst (
        .s_axi_aclk         (clk),
        .s_axi_aresetn      (~rst),

        .s_axi_awaddr       (m06_awaddr[SEVEN_SEG_ADDR_WIDTH-1:0]),
        .s_axi_awprot       (m06_awprot),
        .s_axi_awvalid      (m06_awvalid),
        .s_axi_awready      (m06_awready),

        .s_axi_wdata        (m06_wdata),
        .s_axi_wstrb        (m06_wstrb),
        .s_axi_wvalid       (m06_wvalid),
        .s_axi_wready       (m06_wready),

        .s_axi_bresp        (m06_bresp),
        .s_axi_bvalid       (m06_bvalid),
        .s_axi_bready       (m06_bready),

        .s_axi_araddr       (m06_araddr[SEVEN_SEG_ADDR_WIDTH-1:0]),
        .s_axi_arprot       (m06_arprot),
        .s_axi_arvalid      (m06_arvalid),
        .s_axi_arready      (m06_arready),

        .s_axi_rdata        (m06_rdata),
        .s_axi_rresp        (m06_rresp),
        .s_axi_rvalid       (m06_rvalid),
        .s_axi_rready       (m06_rready),

        .seg                (seg),
        .an                 (an)
    );
    assign m06_bid   = seg_bid_reg;
    assign m06_rid   = seg_rid_reg;
    assign m06_rlast = 1'b1;

endmodule
