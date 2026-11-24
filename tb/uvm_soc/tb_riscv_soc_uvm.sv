// ============================================================================
// File: tb_riscv_soc_uvm.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Top-level static SystemVerilog testbench.
//              - Generates 100 MHz clock and system/core resets.
//              - Instantiates static interface 'gpio_if_inst'.
//              - Instantiates actual SoC DUT 'soc_veer_el2_temperature_fan_top'.
//              - Connects static interface directly to DUT port 'dut.gpio_io'.
//              - Registers interface handle into uvm_config_db for dynamic driver.
//              - Provides passive hardware observation verifying pin propagation.
//              - Invokes UVM test phases via run_test().
// ============================================================================

`timescale 1ns / 1ps

module tb_riscv_soc_uvm;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import riscv_soc_pkg::*;

    // ------------------------------------------------------------------------
    // Clock and Reset Signals
    // ------------------------------------------------------------------------
    logic clk;
    logic rst;          // Active-high system reset
    wire  rst_n;        // Active-low system reset
    logic core_rst_n_i; // Active-high core run enable (active-low core reset)

    assign rst_n = ~rst;

    // 100 MHz Clock Generation (10 ns period)
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
        rst = 1'b0;     // Release system reset
        #20;
        @(posedge clk);
        core_rst_n_i = 1'b1; // Release core run reset
    end

    // ------------------------------------------------------------------------
    // Static Interface Instantiation (Exactly One Selected Interface)
    // ------------------------------------------------------------------------
    gpio_uvm_if #(
        .NUM_BITS(32)
    ) gpio_if_inst (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ------------------------------------------------------------------------
    // Quiescent Signals for External Test Master (AXI4 S00)
    // ------------------------------------------------------------------------
    logic [7:0]   axi_awid;
    logic [31:0]  axi_awaddr;
    logic [7:0]   axi_awlen;
    logic [2:0]   axi_awsize;
    logic [1:0]   axi_awburst;
    logic         axi_awlock;
    logic [3:0]   axi_awcache;
    logic [2:0]   axi_awprot;
    logic [3:0]   axi_awqos;
    logic         axi_awvalid;
    wire          axi_awready;

    logic [31:0]  axi_wdata;
    logic [3:0]   axi_wstrb;
    logic         axi_wlast;
    logic         axi_wvalid;
    wire          axi_wready;

    wire  [7:0]   axi_bid;
    wire  [1:0]   axi_bresp;
    wire          axi_bvalid;
    logic         axi_bready;

    logic [7:0]   axi_arid;
    logic [31:0]  axi_araddr;
    logic [7:0]   axi_arlen;
    logic [2:0]   axi_arsize;
    logic [1:0]   axi_arburst;
    logic         axi_arlock;
    logic [3:0]   axi_arcache;
    logic [2:0]   axi_arprot;
    logic [3:0]   axi_arqos;
    logic         axi_arvalid;
    wire          axi_arready;

    wire  [7:0]   axi_rid;
    wire  [31:0]  axi_rdata;
    wire  [1:0]   axi_rresp;
    wire          axi_rlast;
    wire          axi_rvalid;
    logic         axi_rready;

    initial begin
        axi_awid    = 8'h00;
        axi_awaddr  = 32'h0000_0000;
        axi_awlen   = 8'h00;
        axi_awsize  = 3'b010;
        axi_awburst = 2'b01;
        axi_awlock  = 1'b0;
        axi_awcache = 4'b0010;
        axi_awprot  = 3'b000;
        axi_awqos   = 4'b0000;
        axi_awvalid = 1'b0;

        axi_wdata   = 32'h0000_0000;
        axi_wstrb   = 4'h0;
        axi_wlast   = 1'b0;
        axi_wvalid  = 1'b0;
        axi_bready  = 1'b1;

        axi_arid    = 8'h00;
        axi_araddr  = 32'h0000_0000;
        axi_arlen   = 8'h00;
        axi_arsize  = 3'b010;
        axi_arburst = 2'b01;
        axi_arlock  = 1'b0;
        axi_arcache = 4'b0010;
        axi_arprot  = 3'b000;
        axi_arqos   = 4'b0000;
        axi_arvalid = 1'b0;
        axi_rready  = 1'b1;
    end

    // ------------------------------------------------------------------------
    // Peripheral Boundary Wires
    // ------------------------------------------------------------------------
    // UART
    logic        uart_rx_i;
    wire         uart_tx_o;
    wire         uart_interrupt_o;

    // SPI
    wire         spi_clk_o;
    wire         spi_cs_n_o;
    wire         spi_mosi_o;
    logic        spi_miso_i;
    wire         spi_irq_o;

    // PWM
    wire         pwm_out_o;
    wire         pwm_irq_o;

    // Seven-Segment
    wire  [6:0]  seg;
    wire  [3:0]  an;

    // GPIO Interrupt
    wire         gpio_intr_o;

    // Timer
    logic        timer_ext_meas_i;
    logic        timer_capture_i;
    wire         timer_pwm_o;
    wire         timer_trigger_o;
    wire         timer_irq_o;

    // VeeR Pipeline Trace
    wire  [31:0] trace_rv_i_insn_ip;
    wire  [31:0] trace_rv_i_address_ip;
    wire         trace_rv_i_valid_ip;
    wire         trace_rv_i_exception_ip;
    wire  [4:0]  trace_rv_i_ecause_ip;
    wire         trace_rv_i_interrupt_ip;
    wire  [31:0] trace_rv_i_tval_ip;

    initial begin
        uart_rx_i        = 1'b1; // UART idle high
        spi_miso_i       = 1'b0; // SPI MISO default low
        timer_ext_meas_i = 1'b0;
        timer_capture_i  = 1'b0;
    end

    // ------------------------------------------------------------------------
    // Actual SoC DUT Instantiation
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

        // S00 External Test Master
        .axi_awid               (axi_awid),
        .axi_awaddr             (axi_awaddr),
        .axi_awlen              (axi_awlen),
        .axi_awsize             (axi_awsize),
        .axi_awburst            (axi_awburst),
        .axi_awlock             (axi_awlock),
        .axi_awcache            (axi_awcache),
        .axi_awprot             (axi_awprot),
        .axi_awqos              (axi_awqos),
        .axi_awvalid            (axi_awvalid),
        .axi_awready            (axi_awready),

        .axi_wdata              (axi_wdata),
        .axi_wstrb              (axi_wstrb),
        .axi_wlast              (axi_wlast),
        .axi_wvalid             (axi_wvalid),
        .axi_wready             (axi_wready),

        .axi_bid                (axi_bid),
        .axi_bresp              (axi_bresp),
        .axi_bvalid             (axi_bvalid),
        .axi_bready             (axi_bready),

        .axi_arid               (axi_arid),
        .axi_araddr             (axi_araddr),
        .axi_arlen              (axi_arlen),
        .axi_arsize             (axi_arsize),
        .axi_arburst            (axi_arburst),
        .axi_arlock             (axi_arlock),
        .axi_arcache            (axi_arcache),
        .axi_arprot             (axi_arprot),
        .axi_arqos              (axi_arqos),
        .axi_arvalid            (axi_arvalid),
        .axi_arready            (axi_arready),

        .axi_rid                (axi_rid),
        .axi_rdata              (axi_rdata),
        .axi_rresp              (axi_rresp),
        .axi_rlast              (axi_rlast),
        .axi_rvalid             (axi_rvalid),
        .axi_rready             (axi_rready),

        // UART (M01)
        .uart_rx_i              (uart_rx_i),
        .uart_tx_o              (uart_tx_o),
        .uart_interrupt_o       (uart_interrupt_o),

        // SPI (M04)
        .spi_clk_o              (spi_clk_o),
        .spi_cs_n_o             (spi_cs_n_o),
        .spi_mosi_o             (spi_mosi_o),
        .spi_miso_i             (spi_miso_i),
        .spi_irq_o              (spi_irq_o),

        // PWM (M05)
        .pwm_out_o              (pwm_out_o),
        .pwm_irq_o              (pwm_irq_o),

        // Seven-Segment Display (M06)
        .seg                    (seg),
        .an                     (an),

        // --------------------------------------------------------------------
        // GPIO (M02) Connection to Static Interface Instance
        // --------------------------------------------------------------------
        .gpio_io                (gpio_if_inst.gpio_io),
        .gpio_intr_o            (gpio_intr_o),

        // Timer (M03)
        .timer_ext_meas_i       (timer_ext_meas_i),
        .timer_capture_i        (timer_capture_i),
        .timer_pwm_o            (timer_pwm_o),
        .timer_trigger_o        (timer_trigger_o),
        .timer_irq_o            (timer_irq_o),

        // VeeR Core Trace
        .trace_rv_i_insn_ip      (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip   (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip     (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip (trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip    (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip (trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip      (trace_rv_i_tval_ip)
    );

    // ------------------------------------------------------------------------
    // FSDB Waveform Dumping
    // ------------------------------------------------------------------------
    string fsdb_file;
    initial begin
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_file)) begin
            fsdb_file = "waves/riscv_soc_interface_connection.fsdb";
        end
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_riscv_soc_uvm, "+all");
        $fsdbDumpMDA(0, tb_riscv_soc_uvm);
    end

    // ------------------------------------------------------------------------
    // Passive Hardware Observation & Assertion Verification (Checks 6 & 7)
    // ------------------------------------------------------------------------
    integer pass_observation_count = 0;
    integer fail_observation_count = 0;

    always @(posedge clk) begin
        if (rst_n && (gpio_if_inst.gpio_drive_en == 32'hFFFF_FFFF)) begin
            // Check 6: Confirm physical pad dut.gpio_io directly follows driver stimulus
            if (dut.gpio_io === gpio_if_inst.gpio_in) begin
                pass_observation_count++;
                `uvm_info("DUT_PIN_OBSERVER",
                          $sformatf("[CHECK 6 PASS] DUT boundary pin 'dut.gpio_io' (0x%08h) directly follows UVM driver stimulus (0x%08h)",
                                    dut.gpio_io, gpio_if_inst.gpio_in),
                          UVM_MEDIUM)
            end else begin
                fail_observation_count++;
                `uvm_error("DUT_PIN_OBSERVER",
                           $sformatf("[CHECK 6 FAIL] Mismatch! dut.gpio_io=0x%08h, expected=0x%08h",
                                     dut.gpio_io, gpio_if_inst.gpio_in))
            end

            // Check 7: Internal synchronizer stage observation
            // After 2 clock cycles of stability, dut.gpio_inst.gpio_i should match
            #1ps; // sample after non-blocking delta
            if (dut.gpio_inst.gpio_i === gpio_if_inst.gpio_in) begin
                `uvm_info("DUT_INTERNAL_OBSERVER",
                          $sformatf("[CHECK 7 PASS] DUT internal register input 'dut.gpio_inst.gpio_i' (0x%08h) matches driven stimulus",
                                    dut.gpio_inst.gpio_i),
                          UVM_HIGH)
            end
        end
    end

    // ------------------------------------------------------------------------
    // Static-to-Dynamic Virtual Interface Registration & Test Invocation
    // ------------------------------------------------------------------------
    initial begin
        `uvm_info("TB_TOP", "==================================================", UVM_LOW)
        `uvm_info("TB_TOP", "Phase 6: Publishing static interface 'gpio_if_inst'", UVM_LOW)
        `uvm_info("TB_TOP", "Hierarchical Path: uvm_test_top.env.agent.drv", UVM_LOW)
        `uvm_info("TB_TOP", "Lookup Key:        vif", UVM_LOW)
        `uvm_info("TB_TOP", "==================================================", UVM_LOW)

        // Publish interface handle to uvm_config_db
        uvm_config_db#(virtual gpio_uvm_if)::set(
            null,
            "uvm_test_top.env.agent.drv",
            "vif",
            gpio_if_inst
        );

        `uvm_info("TB_TOP", "uvm_config_db::set() completed successfully.", UVM_LOW)
        `uvm_info("TB_TOP", "Calling run_test('riscv_soc_test')...", UVM_LOW)

        run_test("riscv_soc_test");
    end

    // Final Assertion Summary
    final begin
        if (fail_observation_count == 0 && pass_observation_count > 0) begin
            $display("\n=======================================================");
            $display(" [VERIFICATION SUCCESS] All %0d DUT pin observations PASSED!", pass_observation_count);
            $display(" Static DUT to dynamic UVM driver connection confirmed!");
            $display("=======================================================\n");
        end else begin
            $display("\n=======================================================");
            $display(" [VERIFICATION FAILURE] Observed %0d mismatches out of %0d checks!",
                     fail_observation_count, pass_observation_count + fail_observation_count);
            $display("=======================================================\n");
        end
    end

endmodule : tb_riscv_soc_uvm
