// ============================================================================
// File: tb_riscv_soc_uvm.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Master Top-Level Static SystemVerilog Testbench for VeeR EL2 SoC.
//              - Instantiates 100 MHz clock and coordinated system/core resets.
//              - Instantiates all 8 static SystemVerilog interfaces.
//              - Connects all interface signals directly to SoC DUT boundary ports.
//              - Instantiates SystemVerilog Assertion (SVA) protocol checkers.
//              - Publishes all virtual interfaces into uvm_config_db.
//              - Preloads firmware into 64 KiB Unified Memory.
//              - Enables FSDB waveform dumping via +FSDB_FILE runtime option.
//              - Executes UVM test phases via run_test().
// ============================================================================

`timescale 1ns / 1ps

module tb_riscv_soc_uvm;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import soc_pkg::*;

    // ------------------------------------------------------------------------
    // Clock and Reset Generation
    // ------------------------------------------------------------------------
    logic clk;
    logic rst;          // Active-high global system reset
    wire  rst_n;        // Active-low global system reset
    logic core_rst_n_i; // Active-high core run enable (active-low core reset)

    assign rst_n = ~rst;

    // 100 MHz Master System Clock (10 ns period)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Power-on Reset Generation Sequence
    initial begin
        rst          = 1'b1;
        core_rst_n_i = 1'b0;
        #100;
        @(posedge clk);
        rst = 1'b0;     // Release system peripheral reset
        #20;
        @(posedge clk);
        core_rst_n_i = 1'b1; // Release CPU execution reset
        `uvm_info("TB_TOP", "Power-on reset deasserted; VeeR EL2 core unhalted", UVM_LOW)
    end

    // ------------------------------------------------------------------------
    // Static Interface Instantiations
    // ------------------------------------------------------------------------
    gpio_uvm_if #(
        .NUM_BITS(32)
    ) gpio_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    uart_uvm_if uart_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    spi_uvm_if spi_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    timer_uvm_if timer_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    pwm_uvm_if pwm_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    display_uvm_if display_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    interconnect_uvm_if #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .ID_WIDTH  (8)
    ) ic_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    veer_trace_uvm_if trace_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ------------------------------------------------------------------------
    // Boundary Connecting Nets
    // ------------------------------------------------------------------------
    // Interconnect S00 Wires
    wire        axi_awready;
    wire        axi_wready;
    wire [7:0]  axi_bid;
    wire [1:0]  axi_bresp;
    wire        axi_bvalid;
    wire        axi_arready;
    wire [7:0]  axi_rid;
    wire [31:0] axi_rdata;
    wire [1:0]  axi_rresp;
    wire        axi_rlast;
    wire        axi_rvalid;

    assign ic_if_inst.awready = axi_awready;
    assign ic_if_inst.wready  = axi_wready;
    assign ic_if_inst.bid     = axi_bid;
    assign ic_if_inst.bresp   = axi_bresp;
    assign ic_if_inst.bvalid  = axi_bvalid;
    assign ic_if_inst.arready = axi_arready;
    assign ic_if_inst.rid     = axi_rid;
    assign ic_if_inst.rdata   = axi_rdata;
    assign ic_if_inst.rresp   = axi_rresp;
    assign ic_if_inst.rlast   = axi_rlast;
    assign ic_if_inst.rvalid  = axi_rvalid;

    // Peripheral Interconnect Wires
    wire uart_tx_w;
    wire uart_intr_w;
    assign uart_if_inst.uart_tx        = uart_tx_w;
    assign uart_if_inst.uart_interrupt = uart_intr_w;

    wire spi_clk_w;
    wire spi_cs_n_w;
    wire spi_mosi_w;
    wire spi_irq_w;
    assign spi_if_inst.spi_clk  = spi_clk_w;
    assign spi_if_inst.spi_cs_n = spi_cs_n_w;
    assign spi_if_inst.spi_mosi = spi_mosi_w;
    assign spi_if_inst.spi_irq  = spi_irq_w;

    wire pwm_out_w;
    wire pwm_irq_w;
    assign pwm_if_inst.pwm_out = pwm_out_w;
    assign pwm_if_inst.pwm_irq = pwm_irq_w;

    wire [6:0] seg_w;
    wire [3:0] an_w;
    assign display_if_inst.seg = seg_w;
    assign display_if_inst.an  = an_w;

    wire gpio_intr_w;
    assign gpio_if_inst.gpio_intr = gpio_intr_w;

    wire timer_pwm_w;
    wire timer_trigger_w;
    wire timer_irq_w;
    assign timer_if_inst.timer_pwm     = timer_pwm_w;
    assign timer_if_inst.timer_trigger = timer_trigger_w;
    assign timer_if_inst.timer_irq     = timer_irq_w;

    // VeeR Core Trace
    wire [31:0] trace_insn_w;
    wire [31:0] trace_address_w;
    wire        trace_valid_w;
    wire        trace_exception_w;
    wire [4:0]  trace_ecause_w;
    wire        trace_interrupt_w;
    wire [31:0] trace_tval_w;
    assign trace_if_inst.insn      = trace_insn_w;
    assign trace_if_inst.address   = trace_address_w;
    assign trace_if_inst.valid     = trace_valid_w;
    assign trace_if_inst.exception = trace_exception_w;
    assign trace_if_inst.ecause    = trace_ecause_w;
    assign trace_if_inst.interrupt = trace_interrupt_w;
    assign trace_if_inst.tval      = trace_tval_w;

    // ------------------------------------------------------------------------
    // SoC DUT Instantiation
    // ------------------------------------------------------------------------
    soc_veer_el2_temperature_fan_top #(
        .DATA_WIDTH            (32),
        .ADDR_WIDTH            (32),
        .IC_ID_WIDTH           (8),
        .GPIO_NUM_BITS         (32),
        .SEVEN_SEG_REFRESH_DIV (10)
    ) dut (
        .clk                    (clk),
        .rst                    (rst),
        .core_rst_n_i           (core_rst_n_i),

        // S00 External Test Master (AXI4 Slave Port)
        .axi_awid               (ic_if_inst.awid),
        .axi_awaddr             (ic_if_inst.awaddr),
        .axi_awlen              (ic_if_inst.awlen),
        .axi_awsize             (ic_if_inst.awsize),
        .axi_awburst            (ic_if_inst.awburst),
        .axi_awlock             (ic_if_inst.awlock),
        .axi_awcache            (ic_if_inst.awcache),
        .axi_awprot             (ic_if_inst.awprot),
        .axi_awqos              (ic_if_inst.awqos),
        .axi_awvalid            (ic_if_inst.awvalid),
        .axi_awready            (axi_awready),

        .axi_wdata              (ic_if_inst.wdata),
        .axi_wstrb              (ic_if_inst.wstrb),
        .axi_wlast              (ic_if_inst.wlast),
        .axi_wvalid             (ic_if_inst.wvalid),
        .axi_wready             (axi_wready),

        .axi_bid                (axi_bid),
        .axi_bresp              (axi_bresp),
        .axi_bvalid             (axi_bvalid),
        .axi_bready             (ic_if_inst.bready),

        .axi_arid               (ic_if_inst.arid),
        .axi_araddr             (ic_if_inst.araddr),
        .axi_arlen              (ic_if_inst.arlen),
        .axi_arsize             (ic_if_inst.arsize),
        .axi_arburst            (ic_if_inst.arburst),
        .axi_arlock             (ic_if_inst.arlock),
        .axi_arcache            (ic_if_inst.arcache),
        .axi_arprot             (ic_if_inst.arprot),
        .axi_arqos              (ic_if_inst.arqos),
        .axi_arvalid            (ic_if_inst.arvalid),
        .axi_arready            (axi_arready),

        .axi_rid                (axi_rid),
        .axi_rdata              (axi_rdata),
        .axi_rresp              (axi_rresp),
        .axi_rlast              (axi_rlast),
        .axi_rvalid             (axi_rvalid),
        .axi_rready             (ic_if_inst.rready),

        // UART (M01)
        .uart_rx_i              (uart_if_inst.uart_rx),
        .uart_tx_o              (uart_tx_w),
        .uart_interrupt_o       (uart_intr_w),

        // SPI Temperature Sensor (M04)
        .spi_clk_o              (spi_clk_w),
        .spi_cs_n_o             (spi_cs_n_w),
        .spi_mosi_o             (spi_mosi_w),
        .spi_miso_i             (spi_if_inst.spi_miso),
        .spi_irq_o              (spi_irq_w),

        // PWM Fan Controller (M05)
        .pwm_out_o              (pwm_out_w),
        .pwm_irq_o              (pwm_irq_w),

        // Seven-Segment Display (M06)
        .seg                    (seg_w),
        .an                     (an_w),

        // GPIO (M02)
        .gpio_io                (gpio_if_inst.gpio_io),
        .gpio_intr_o            (gpio_intr_w),

        // Hardware Timer (M03)
        .timer_ext_meas_i       (timer_if_inst.timer_ext_meas),
        .timer_capture_i        (timer_if_inst.timer_capture),
        .timer_pwm_o            (timer_pwm_w),
        .timer_trigger_o        (timer_trigger_w),
        .timer_irq_o            (timer_irq_w),

        // VeeR EL2 Pipeline Trace
        .trace_rv_i_insn_ip      (trace_insn_w),
        .trace_rv_i_address_ip   (trace_address_w),
        .trace_rv_i_valid_ip     (trace_valid_w),
        .trace_rv_i_exception_ip (trace_exception_w),
        .trace_rv_i_ecause_ip    (trace_ecause_w),
        .trace_rv_i_interrupt_ip (trace_interrupt_w),
        .trace_rv_i_tval_ip      (trace_tval_w)
    );

    // ------------------------------------------------------------------------
    // Assertions Instantiations
    // ------------------------------------------------------------------------
    display_assertions display_assert_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .seg   (seg_w),
        .an    (an_w)
    );

    gpio_assertions #(.NUM_BITS(32)) gpio_assert_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .drive_en   (gpio_if_inst.gpio_drive_en),
        .drive_data (gpio_if_inst.gpio_in),
        .pad_io     (dut.gpio_io),
        .dut_gpio_i (dut.gpio_inst.gpio_i)
    );

    interconnect_assertions ic_assert_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .awvalid (ic_if_inst.awvalid),
        .awready (axi_awready),
        .awaddr  (ic_if_inst.awaddr),
        .wvalid  (ic_if_inst.wvalid),
        .wready  (axi_wready),
        .wdata   (ic_if_inst.wdata),
        .arvalid (ic_if_inst.arvalid),
        .arready (axi_arready),
        .araddr  (ic_if_inst.araddr)
    );

    pwm_assertions pwm_assert_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .pwm_out (pwm_out_w)
    );

    spi_assertions spi_assert_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .spi_clk  (spi_clk_w),
        .spi_cs_n (spi_cs_n_w),
        .spi_mosi (spi_mosi_w),
        .spi_miso (spi_if_inst.spi_miso)
    );

    timer_assertions timer_assert_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .timer_irq     (timer_irq_w),
        .timer_pwm     (timer_pwm_w),
        .timer_trigger (timer_trigger_w)
    );

    uart_assertions uart_assert_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .uart_rx (uart_if_inst.uart_rx),
        .uart_tx (uart_tx_w)
    );

    // ------------------------------------------------------------------------
    // FSDB Waveform Dumping
    // ------------------------------------------------------------------------
    string fsdb_file;
    initial begin
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_file)) begin
            fsdb_file = "fsdb/soc_uvm.fsdb";
        end
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_riscv_soc_uvm, "+all");
        $fsdbDumpMDA(0, tb_riscv_soc_uvm);
    end

    // ------------------------------------------------------------------------
    // Unified Memory Firmware Preload
    // ------------------------------------------------------------------------
    initial begin
        string hex_file;
        if (!$value$plusargs("HEX_FILE=%s", hex_file)) begin
            hex_file = "../firmware/temperature_fan_words.hex";
        end
        $readmemh(hex_file, dut.unified_mem_inst.mem);
        `uvm_info("TB_TOP", $sformatf("Preloaded Unified Memory firmware image from: %s", hex_file), UVM_LOW)
    end

    // ------------------------------------------------------------------------
    // Virtual Interface Registration and Test Invocation
    // ------------------------------------------------------------------------
    initial begin
        `uvm_info("TB_TOP", "==================================================", UVM_LOW)
        `uvm_info("TB_TOP", "  Registering Static Interfaces in uvm_config_db   ", UVM_LOW)
        `uvm_info("TB_TOP", "==================================================", UVM_LOW)

        uvm_config_db#(virtual gpio_uvm_if)::set(null, "*", "vif", gpio_if_inst);
        uvm_config_db#(virtual uart_uvm_if)::set(null, "*", "vif", uart_if_inst);
        uvm_config_db#(virtual spi_uvm_if)::set(null, "*", "vif", spi_if_inst);
        uvm_config_db#(virtual timer_uvm_if)::set(null, "*", "vif", timer_if_inst);
        uvm_config_db#(virtual pwm_uvm_if)::set(null, "*", "vif", pwm_if_inst);
        uvm_config_db#(virtual display_uvm_if)::set(null, "*", "vif", display_if_inst);
        uvm_config_db#(virtual interconnect_uvm_if)::set(null, "*", "vif", ic_if_inst);
        uvm_config_db#(virtual veer_trace_uvm_if)::set(null, "*", "trace_vif", trace_if_inst);

        `uvm_info("TB_TOP", "All 8 virtual interfaces registered successfully.", UVM_LOW)
        `uvm_info("TB_TOP", "Handing off control to UVM Test Phasing via run_test()...", UVM_LOW)

        run_test();
    end

endmodule : tb_riscv_soc_uvm
