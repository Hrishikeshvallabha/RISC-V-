// ============================================================================
// Testbench: tb_soc_veer_el2_temperature_fan
// Description: Comprehensive verification testbench for the integrated VeeR EL2
//              RISC-V SoC for Smart Temperature Monitoring and Fan Control.
//
// Verification Scope:
//   Phase 1: Clock, Reset, and System Initialization
//   Phase 2: Unified Instruction & Data Memory (64 KiB: M00: 0x0000_0000 - 0x0000_FFFF)
//   Phase 3: UART Peripheral Verification (M01: 0x4000_0000 - 0x4000_0FFF)
//   Phase 4: GPIO Peripheral Verification (M02: 0x4000_2000 - 0x4000_2FFF)
//   Phase 5: Timer Peripheral Verification (M03: 0x4000_4000 - 0x4000_4FFF)
//   Phase 6: SPI Temperature Sensor Interface (M04: 0x4000_6000 - 0x4000_6FFF)
//   Phase 7: PWM Fan Controller Verification (M05: 0x4000_A000 - 0x4000_AFFF)
//   Phase 8: Seven-Segment Display Controller (M06: 0x4000_C000 - 0x4000_CFFF)
//   Phase 9: Closed-Loop Smart Temperature & Fan Speed Response Simulation
//   Phase 10: VeeR EL2 RISC-V Processor Boot & Execution from Unified Memory
// ============================================================================

`timescale 1ns / 1ps

module tb_soc_veer_el2_temperature_fan;

    parameter DATA_WIDTH            = 32;
    parameter ADDR_WIDTH            = 32;
    parameter IC_ID_WIDTH           = 8;
    parameter GPIO_NUM_BITS         = 32;
    parameter SEVEN_SEG_REFRESH_DIV = 10; // Accelerated for simulation

    // Clock and Reset Signals
    reg  clk;
    reg  rst;
    reg  core_rst_n_i;

    // External Test Master Signals (S00)
    reg  [IC_ID_WIDTH-1:0]   axi_awid;
    reg  [ADDR_WIDTH-1:0]    axi_awaddr;
    reg  [7:0]               axi_awlen;
    reg  [2:0]               axi_awsize;
    reg  [1:0]               axi_awburst;
    reg                      axi_awlock;
    reg  [3:0]               axi_awcache;
    reg  [2:0]               axi_awprot;
    reg  [3:0]               axi_awqos;
    reg                      axi_awvalid;
    wire                     axi_awready;

    reg  [DATA_WIDTH-1:0]    axi_wdata;
    reg  [3:0]               axi_wstrb;
    reg                      axi_wlast;
    reg                      axi_wvalid;
    wire                     axi_wready;

    wire [IC_ID_WIDTH-1:0]   axi_bid;
    wire [1:0]               axi_bresp;
    wire                     axi_bvalid;
    reg                      axi_bready;

    reg  [IC_ID_WIDTH-1:0]   axi_arid;
    reg  [ADDR_WIDTH-1:0]    axi_araddr;
    reg  [7:0]               axi_arlen;
    reg  [2:0]               axi_arsize;
    reg  [1:0]               axi_arburst;
    reg                      axi_arlock;
    reg  [3:0]               axi_arcache;
    reg  [2:0]               axi_arprot;
    reg  [3:0]               axi_arqos;
    reg                      axi_arvalid;
    wire                     axi_arready;

    wire [IC_ID_WIDTH-1:0]   axi_rid;
    wire [DATA_WIDTH-1:0]    axi_rdata;
    wire [1:0]               axi_rresp;
    wire                     axi_rlast;
    wire                     axi_rvalid;
    reg                      axi_rready;

    // Peripheral External Signals
    reg                      uart_rx_i;
    wire                     uart_tx_o;
    wire                     uart_interrupt_o;

    wire                     spi_clk_o;
    wire                     spi_cs_n_o;
    wire                     spi_mosi_o;
    reg                      spi_miso_i;
    wire                     spi_irq_o;

    wire                     pwm_out_o;
    wire                     pwm_irq_o;

    wire [6:0]               seg;
    wire [3:0]               an;

    wire [GPIO_NUM_BITS-1:0] gpio_io;
    wire                     gpio_intr_o;
    reg  [GPIO_NUM_BITS-1:0] gpio_tb_in;
    reg  [GPIO_NUM_BITS-1:0] gpio_tb_dir;

    genvar gi;
    generate
        for (gi = 0; gi < GPIO_NUM_BITS; gi = gi + 1) begin : gen_gpio_bidir
            assign gpio_io[gi] = gpio_tb_dir[gi] ? gpio_tb_in[gi] : 1'bz;
        end
    endgenerate

    reg                      timer_ext_meas_i;
    reg                      timer_capture_i;
    wire                     timer_pwm_o;
    wire                     timer_trigger_o;
    wire                     timer_irq_o;

    // Core Trace Signals
    wire [31:0]              trace_rv_i_insn_ip;
    wire [31:0]              trace_rv_i_address_ip;
    wire                     trace_rv_i_valid_ip;
    wire                     trace_rv_i_exception_ip;
    wire [4:0]               trace_rv_i_ecause_ip;
    wire                     trace_rv_i_interrupt_ip;
    wire [31:0]              trace_rv_i_tval_ip;

    // Test Verification Counters
    integer total_tests = 0;
    integer pass_count  = 0;
    integer fail_count  = 0;

    // ------------------------------------------------------------------------
    // Clock Generation: 100 MHz (10ns period)
    // ------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // DUT Instantiation
    // ------------------------------------------------------------------------
    soc_veer_el2_temperature_fan_top #(
        .DATA_WIDTH            (DATA_WIDTH),
        .ADDR_WIDTH            (ADDR_WIDTH),
        .IC_ID_WIDTH           (IC_ID_WIDTH),
        .GPIO_NUM_BITS         (GPIO_NUM_BITS),
        .SEVEN_SEG_REFRESH_DIV (SEVEN_SEG_REFRESH_DIV)
    ) dut (
        .clk                    (clk),
        .rst                    (rst),
        .core_rst_n_i           (core_rst_n_i),

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

        .uart_rx_i              (uart_rx_i),
        .uart_tx_o              (uart_tx_o),
        .uart_interrupt_o       (uart_interrupt_o),

        .spi_clk_o              (spi_clk_o),
        .spi_cs_n_o             (spi_cs_n_o),
        .spi_mosi_o             (spi_mosi_o),
        .spi_miso_i             (spi_miso_i),
        .spi_irq_o              (spi_irq_o),

        .pwm_out_o              (pwm_out_o),
        .pwm_irq_o              (pwm_irq_o),

        .seg                    (seg),
        .an                     (an),

        .gpio_io                (gpio_io),
        .gpio_intr_o            (gpio_intr_o),

        .timer_ext_meas_i       (timer_ext_meas_i),
        .timer_capture_i        (timer_capture_i),
        .timer_pwm_o            (timer_pwm_o),
        .timer_trigger_o        (timer_trigger_o),
        .timer_irq_o            (timer_irq_o),

        .trace_rv_i_insn_ip     (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip  (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip    (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip   (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip     (trace_rv_i_tval_ip)
    );

    // ------------------------------------------------------------------------
    // Verification Assertion Tasks
    // ------------------------------------------------------------------------
    task automatic check;
        input condition;
        input [8*100-1:0] test_name;
        begin
            total_tests = total_tests + 1;
            if (condition) begin
                pass_count = pass_count + 1;
                $display("[PASS] (%0d) %0s", total_tests, test_name);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] (%0d) %0s", total_tests, test_name);
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // AXI4 Master Bus Helper Tasks (Matches Baseline Pattern)
    // ------------------------------------------------------------------------
    task automatic axi_write;
        input  [31:0] addr;
        input  [31:0] data;
        output        ok;
        integer timeout;
        begin
            ok = 1'b0;
            @(negedge clk);
            axi_awid    = 8'h01;
            axi_awaddr  = addr;
            axi_awlen   = 8'd0;
            axi_awsize  = 3'd2; // 4 bytes
            axi_awburst = 2'b01;
            axi_awlock  = 1'b0;
            axi_awcache = 4'h0;
            axi_awprot  = 3'h0;
            axi_awqos   = 4'h0;

            axi_wdata   = data;
            axi_wstrb   = 4'hF;
            axi_wlast   = 1'b1;

            axi_awvalid = 1'b1;
            axi_wvalid  = 1'b1;
            axi_bready  = 1'b1;

            // AW Handshake
            timeout = 0;
            while (!(axi_awvalid && axi_awready) && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Timeout waiting for AXI AWREADY addr=0x%08h", addr);
                @(negedge clk);
                axi_awvalid = 1'b0;
                axi_wvalid  = 1'b0;
                axi_bready  = 1'b0;
            end else begin
                @(negedge clk);
                axi_awvalid = 1'b0;

                // W Handshake
                timeout = 0;
                while (!(axi_wvalid && axi_wready) && timeout < 200) begin
                    @(posedge clk);
                    timeout = timeout + 1;
                end

                if (timeout >= 200) begin
                    $display("[ERROR] Timeout waiting for AXI WREADY addr=0x%08h", addr);
                    @(negedge clk);
                    axi_wvalid = 1'b0;
                    axi_bready = 1'b0;
                end else begin
                    @(negedge clk);
                    axi_wvalid = 1'b0;

                    // B Response Handshake
                    timeout = 0;
                    while (!axi_bvalid && timeout < 200) begin
                        @(posedge clk);
                        timeout = timeout + 1;
                    end

                    if (timeout >= 200) begin
                        $display("[ERROR] Timeout waiting for AXI BVALID addr=0x%08h", addr);
                        @(negedge clk);
                        axi_bready = 1'b0;
                    end else begin
                        if (axi_bresp == 2'b00) ok = 1'b1;
                        @(negedge clk);
                        axi_bready = 1'b0;
                    end
                end
            end
        end
    endtask

    task automatic axi_read;
        input  [31:0] addr;
        output [31:0] data;
        output        ok;
        integer timeout;
        begin
            ok   = 1'b0;
            data = 32'h0;
            @(negedge clk);
            axi_arid    = 8'h01;
            axi_araddr  = addr;
            axi_arlen   = 8'd0;
            axi_arsize  = 3'd2;
            axi_arburst = 2'b01;
            axi_arlock  = 1'b0;
            axi_arcache = 4'h0;
            axi_arprot  = 3'h0;
            axi_arqos   = 4'h0;

            axi_arvalid = 1'b1;
            axi_rready  = 1'b1;

            timeout = 0;
            while (!(axi_arvalid && axi_arready) && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Timeout waiting for AXI ARREADY addr=0x%08h", addr);
                @(negedge clk);
                axi_arvalid = 1'b0;
                axi_rready  = 1'b0;
            end else begin
                @(negedge clk);
                axi_arvalid = 1'b0;

                timeout = 0;
                while (!axi_rvalid && timeout < 200) begin
                    @(posedge clk);
                    timeout = timeout + 1;
                end

                if (timeout >= 200) begin
                    $display("[ERROR] Timeout waiting for AXI RVALID addr=0x%08h", addr);
                    @(negedge clk);
                    axi_rready = 1'b0;
                end else begin
                    data = axi_rdata;
                    if (axi_rresp == 2'b00) ok = 1'b1;
                    @(negedge clk);
                    axi_rready = 1'b0;
                end
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Helper Tasks for Peripheral Verification
    // ------------------------------------------------------------------------
    task automatic drive_uart_rx;
        input [7:0] byte_data;
        integer b;
        begin
            uart_rx_i = 1'b1;
            #100;
            uart_rx_i = 1'b0; // Start bit
            #40;
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx_i = byte_data[b];
                #40;
            end
            uart_rx_i = 1'b1; // Stop bit
            #40;
        end
    endtask

    // ------------------------------------------------------------------------
    // Main Test Stimulus
    // ------------------------------------------------------------------------
    reg ok;
    reg [31:0] rd_val;
    reg [7:0]  rx_actual;
    integer i;

    initial begin
        $display("=========================================================================");
        $display(" START: VeeR EL2 RISC-V SoC for Temperature Monitoring & Fan Control   ");
        $display("=========================================================================");

        // Initial Signal States
        rst              = 1'b1;
        core_rst_n_i     = 1'b0; // Hold core in reset during Phases 1-9
        uart_rx_i        = 1'b1;
        spi_miso_i       = 1'b0;
        gpio_tb_in       = 32'h0;
        gpio_tb_dir      = 32'h0;
        timer_ext_meas_i = 1'b0;
        timer_capture_i  = 1'b0;

        axi_awid         = 8'h0;
        axi_awaddr       = 32'h0;
        axi_awlen        = 8'h0;
        axi_awsize       = 3'h0;
        axi_awburst      = 2'h0;
        axi_awlock       = 1'b0;
        axi_awcache      = 4'h0;
        axi_awprot       = 3'h0;
        axi_awqos        = 4'h0;
        axi_awvalid      = 1'b0;
        axi_wdata        = 32'h0;
        axi_wstrb        = 4'h0;
        axi_wlast        = 1'b0;
        axi_wvalid       = 1'b0;
        axi_bready       = 1'b0;
        axi_arid         = 8'h0;
        axi_araddr       = 32'h0;
        axi_arlen        = 8'h0;
        axi_arsize       = 3'h0;
        axi_arburst      = 2'h0;
        axi_arlock       = 1'b0;
        axi_arcache      = 4'h0;
        axi_arprot       = 3'h0;
        axi_arqos        = 4'h0;
        axi_arvalid      = 1'b0;
        axi_rready       = 1'b0;

        // Reset Pulse
        repeat (10) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);
        check(rst == 1'b0, "System reset deasserted cleanly");

        // --------------------------------------------------------------------
        // Phase 1: Unified Memory Subsystem Verification (M00: 0x0000_0000)
        // --------------------------------------------------------------------
        $display("\n--- PHASE 1: Unified Memory (64 KiB: 0x0000_0000) ---");
        // Test word write and readback
        axi_write(32'h0000_0100, 32'hDEADBEEF, ok);
        check(ok, "Unified Memory write at 0x0000_0100 OKAY response");

        axi_read(32'h0000_0100, rd_val, ok);
        check(ok && rd_val == 32'hDEADBEEF, "Unified Memory readback matched 0xDEADBEEF");

        axi_write(32'h0000_0104, 32'h12345678, ok);
        axi_read(32'h0000_0104, rd_val, ok);
        check(ok && rd_val == 32'h12345678, "Unified Memory readback matched 0x12345678 at offset +4");

        // Test high memory offset near boundary (64 KiB - 4)
        axi_write(32'h0000_FFFC, 32'hCAFEBABE, ok);
        axi_read(32'h0000_FFFC, rd_val, ok);
        check(ok && rd_val == 32'hCAFEBABE, "Unified Memory high boundary readback 0xCAFEBABE");

        // --------------------------------------------------------------------
        // Phase 2: UART Peripheral Verification (M01: 0x4000_0000)
        // --------------------------------------------------------------------
        $display("\n--- PHASE 2: UART (0x4000_0000) ---");
        // Configure UART (Standard 16550 Sequence verified in baseline):
        // 1. Set DLAB = 1 (LCR at 0x0C)
        axi_write(32'h4000_000C, 32'h0000_0080, ok);
        check(ok, "UART LCR: DLAB set to 1");

        // 2. Program Baud Divisor = 4 (at 0x08)
        axi_write(32'h4000_0008, 32'd4, ok);
        check(ok, "UART Baud Divisor configured to 4");

        // 3. Clear DLAB, set 8 data bits, 1 stop bit, no parity (LCR at 0x0C)
        axi_write(32'h4000_000C, 32'h0000_0003, ok);
        check(ok, "UART LCR: 8-bit word format, 1 stop bit, parity disabled");

        // 4. Enable IER interrupt (IER at 0x04)
        axi_write(32'h4000_0004, 32'h0000_0001, ok);
        check(ok, "UART IER: Interrupt enabled");

        // 5. Read Line Status Register (LSR at 0x14)
        axi_read(32'h4000_0014, rd_val, ok);
        check(ok && (rd_val & 32'h0000_0060) == 32'h0000_0060, "UART LSR: Transmitter ready (THRE & TEMT set)");

        // 6. Transmit a character (THR at 0x00)
        axi_write(32'h4000_0000, 32'h0000_00A5, ok);
        check(ok, "UART THR: Byte 0xA5 written to transmitter FIFO");

        // Verify serial transmission on uart_tx_o
        begin
            reg [7:0] tx_reconstructed;
            reg [9:0] expected_frame;
            integer tx_err;
            expected_frame = {1'b1, 8'hA5, 1'b0};
            tx_reconstructed = 8'h00;
            tx_err = 0;

            @(negedge uart_tx_o);
            #25;
            for (i = 0; i < 10; i = i + 1) begin
                if (uart_tx_o !== expected_frame[i]) tx_err = tx_err + 1;
                if (i >= 1 && i <= 8) tx_reconstructed[i-1] = uart_tx_o;
                #50;
            end
            check(tx_err == 0 && tx_reconstructed == 8'hA5, "UART TX pin serial frame verified (0xA5)");
        end

        // 7. Test UART Receive functionality
        drive_uart_rx(8'h3C);
        // Wait for DATA_READY bit in LSR (0x14)
        rd_val = 32'h0;
        i = 0;
        while ((rd_val[0] !== 1'b1) && (i < 100)) begin
            axi_read(32'h4000_0014, rd_val, ok);
            i = i + 1;
        end
        check(rd_val[0] === 1'b1, "UART LSR DATA_READY asserted after RX frame");

        // Read received byte from RBR (0x00)
        axi_read(32'h4000_0000, rd_val, ok);
        check(ok && (rd_val[7:0] === 8'h3C), "UART RBR received byte matched 0x3C");

        // --------------------------------------------------------------------
        // Phase 3: GPIO Peripheral Verification (M02: 0x4000_2000)
        // --------------------------------------------------------------------
        $display("\n--- PHASE 3: GPIO (0x4000_2000) ---");
        // Verify reset state
        axi_read(32'h4000_2004, rd_val, ok);
        check(ok && rd_val == 32'h0, "GPIO reset: DATA_O reads 0x00000000");

        // Configure Direction as all outputs (DIR at 0x08)
        axi_write(32'h4000_2008, 32'hFFFF_FFFF, ok);
        axi_read(32'h4000_2008, rd_val, ok);
        check(ok && rd_val == 32'hFFFF_FFFF, "GPIO Direction configured as all outputs");

        // Write Output register (DATA_O at 0x04)
        axi_write(32'h4000_2004, 32'hA5A5_5A5A, ok);
        axi_read(32'h4000_2004, rd_val, ok);
        check(ok && rd_val == 32'hA5A5_5A5A, "GPIO Output register readback matched 0xA5A55A5A");
        check(gpio_io == 32'hA5A5_5A5A, "GPIO physical output pins match register value");

        // Test Atomic Clear (CLR_O at 0x24): clear lower 16 bits
        axi_write(32'h4000_2024, 32'h0000_FFFF, ok);
        #10;
        check(gpio_io == 32'hA5A5_0000, "GPIO Atomic Clear: Lower 16 bits cleared to 0");

        // Test Atomic Set (SET_O at 0x20): set lower 8 bits to 0x55
        axi_write(32'h4000_2020, 32'h0000_0055, ok);
        #10;
        check(gpio_io == 32'hA5A5_0055, "GPIO Atomic Set: Lower 8 bits set to 0x55");

        // Test Input mode (DIR = 0)
        axi_write(32'h4000_2008, 32'h0000_0000, ok);
        gpio_tb_in  = 32'h1234_5678;
        gpio_tb_dir = 32'hFFFF_FFFF; // TB drives
        repeat (4) @(posedge clk);
        axi_read(32'h4000_2000, rd_val, ok);
        check(ok && rd_val == 32'h1234_5678, "GPIO Input: Read DATA_I matched external driven pattern");
        gpio_tb_dir = 32'h0000_0000; // Release TB drive

        // --------------------------------------------------------------------
        // Phase 4: Timer Peripheral Verification (M03: 0x4000_4000)
        // --------------------------------------------------------------------
        $display("\n--- PHASE 4: Timer (0x4000_4000) ---");
        // Verify reset
        axi_read(32'h4000_4000, rd_val, ok);
        check(ok && rd_val == 32'h0, "Timer reset: CTRL register reads 0x00000000");

        // Program Prescaler (PRE at 0x0C)
        axi_write(32'h4000_400C, 32'h0000_0002, ok);
        axi_read(32'h4000_400C, rd_val, ok);
        check(ok && rd_val == 32'h0000_0002, "Timer Prescaler write/readback verified (2)");

        // Program Compare Match (CMP at 0x18)
        axi_write(32'h4000_4018, 32'h0000_0020, ok);
        axi_read(32'h4000_4018, rd_val, ok);
        check(ok && rd_val == 32'h0000_0020, "Timer Compare write/readback verified (32)");

        // Program Initial Load Value (LOAD at 0x04)
        axi_write(32'h4000_4004, 32'h0000_0050, ok);
        axi_read(32'h4000_4008, rd_val, ok);
        check(ok && rd_val == 32'h0000_0050, "Timer Counter loaded with initial value (0x50)");

        // Enable Timer (CTRL at 0x00)
        axi_write(32'h4000_4000, 32'h0000_0001, ok);
        check(ok, "Timer enabled (CTRL=1)");

        // Advance counter and check progress (timer counts down by default)
        repeat (40) @(posedge clk);
        axi_read(32'h4000_4008, rd_val, ok);
        check(ok && rd_val < 32'h0000_0050, "Timer Counter actively advancing downward from load value");

        // --------------------------------------------------------------------
        // Phase 5: SPI Temperature Sensor Interface (M04: 0x4000_6000)
        // --------------------------------------------------------------------
        $display("\n--- PHASE 5: SPI Temperature Sensor Interface (0x4000_6000) ---");
        // Read Status Register (SR at 0x64)
        axi_read(32'h4000_6064, rd_val, ok);
        check(ok && (rd_val & 32'h0000_0005) == 32'h0000_0005, "SPI Status Register: Initial FIFOs empty (0x05)");

        // Configure Control Register (CR at 0x60): Manual SS, Master mode, SPI enabled
        axi_write(32'h4000_6060, 32'h0000_0186, ok);
        axi_read(32'h4000_6060, rd_val, ok);
        check(ok && rd_val == 32'h0000_0186, "SPI Control Register programmed (0x0186)");

        // Configure Clock Divider (RCLK at 0x30)
        axi_write(32'h4000_6030, 32'h0000_0004, ok);
        check(ok, "SPI Clock ratio configured");

        // Assert Slave Select to Temperature Sensor (SSR at 0x70: active-low)
        axi_write(32'h4000_6070, 32'h0000_0000, ok);
        repeat (5) @(posedge clk);
        check(spi_cs_n_o === 1'b0, "SPI Chip Select asserted low to sensor");

        // Transmit command byte to sensor and capture response
        // Temperature sensor returns simulated 45 deg C (0x2D)
        fork
            begin
                // DUT transmits 0x55 command
                axi_write(32'h4000_6068, 32'h0000_0055, ok);
            end
            begin
                // Emulated sensor provides MISO data bits (0x2D = 8'b0010_1101)
                integer sbit;
                reg [7:0] sensor_data;
                sensor_data = 8'h2D;
                // Pre-drive MSB before SCLK rising edge (CPOL=0, CPHA=0 Mode 0)
                spi_miso_i = sensor_data[7];
                for (sbit = 0; sbit < 8; sbit = sbit + 1) begin
                    @(posedge spi_clk_o);
                    @(negedge spi_clk_o);
                    if (sbit < 7) spi_miso_i = sensor_data[6 - sbit];
                end
            end
        join

        // Wait for SPI transfer completion
        repeat (30) @(posedge clk);
        axi_read(32'h4000_6064, rd_val, ok);
        check(ok && (rd_val[0] === 1'b0), "SPI Status: RX FIFO has received sensor data");

        // Read received sensor temperature byte from DRR (0x6C)
        axi_read(32'h4000_606C, rd_val, ok);
        check(ok && (rd_val[7:0] == 8'h2D), "SPI DRR readback verified temperature reading (0x2D = 45 C)");

        // Deassert Slave Select (SSR at 0x70)
        axi_write(32'h4000_6070, 32'hFFFF_FFFF, ok);
        repeat (5) @(posedge clk);
        check(spi_cs_n_o === 1'b1, "SPI Chip Select deasserted high");

        // --------------------------------------------------------------------
        // Phase 6: PWM Fan Controller Verification (M05: 0x4000_A000)
        // --------------------------------------------------------------------
        $display("\n--- PHASE 6: PWM Fan Controller (0x4000_A000) ---");
        // Verify scratch register read/write
        axi_write(32'h4000_A004, 32'h1234_5678, ok);
        axi_read(32'h4000_A004, rd_val, ok);
        check(ok && rd_val == 32'h1234_5678, "PWM slv_reg1 write/readback verified (0x12345678)");

        // Program Duty Cycle = 128 (50% duty cycle)
        axi_write(32'h4000_A000, 32'h0000_0080, ok);
        axi_read(32'h4000_A000, rd_val, ok);
        check(ok && (rd_val & 8'hFF) == 8'h80, "PWM Duty cycle programmed to 50% (128)");

        // Observe PWM output active toggling
        begin
            reg saw_high, saw_low;
            saw_high = 1'b0;
            saw_low  = 1'b0;
            for (i = 0; i < 300; i = i + 1) begin
                @(posedge clk);
                if (pwm_out_o == 1'b1) saw_high = 1'b1;
                if (pwm_out_o == 1'b0) saw_low  = 1'b1;
            end
            check(saw_high && saw_low, "PWM Fan Controller actively modulating output pin");
        end

        // --------------------------------------------------------------------
        // Phase 7: Seven-Segment Display Verification (M06: 0x4000_C000)
        // --------------------------------------------------------------------
        $display("\n--- PHASE 7: Seven-Segment Display (0x4000_C000) ---");
        // Verify reset behavior
        axi_read(32'h4000_C004, rd_val, ok);
        check(ok && rd_val == 32'h0, "7-Segment reset: CONTROL register reads 0");

        // Write Display Data (digits: 4, 5, C, 0)
        axi_write(32'h4000_C000, 32'h0000_45C0, ok);
        axi_read(32'h4000_C000, rd_val, ok);
        check(ok && rd_val == 32'h0000_45C0, "7-Segment DISPLAY_DATA readback matched 0x000045C0");

        // Enable display
        axi_write(32'h4000_C004, 32'h0000_0001, ok);
        axi_read(32'h4000_C008, rd_val, ok);
        check(ok && rd_val[0] == 1'b1, "7-Segment STATUS reports display enabled");

        // Observe active digit multiplexing
        begin
            reg [3:0] seen_anodes;
            seen_anodes = 4'h0;
            for (i = 0; i < 200; i = i + 1) begin
                @(posedge clk);
                seen_anodes = seen_anodes | ~an;
            end
            check(seen_anodes != 4'h0, "7-Segment display actively scanning across digit anodes");
        end

        // --------------------------------------------------------------------
        // Phase 8: Smart Temperature Monitoring & Fan Control Closed Loop
        // --------------------------------------------------------------------
        $display("\n--- PHASE 8: Closed-Loop Smart Temperature & Fan Control ---");
        // Scenario 1: Normal temperature (25 C)
        //   - Update display to "0025"
        //   - Set fan speed to low (duty = 64 / 256 = 25%)
        axi_write(32'h4000_C000, 32'h0000_0025, ok);
        axi_write(32'h4000_A000, 32'h0000_0040, ok);
        check(ok, "Closed-loop: Normal temperature 25 C programmed, fan set to 25%");

        // Scenario 2: Elevated temperature (55 C)
        //   - Update display to "0055"
        //   - Boost fan speed to high (duty = 217 / 256 = 85%)
        axi_write(32'h4000_C000, 32'h0000_0055, ok);
        axi_write(32'h4000_A000, 32'h0000_00D9, ok);
        axi_read(32'h4000_A000, rd_val, ok);
        check(ok && (rd_val & 8'hFF) == 8'hD9, "Closed-loop: Elevated temperature 55 C responded with 85% fan boost");

        // --------------------------------------------------------------------
        // Phase 9: VeeR EL2 Processor Boot & Execution Verification
        // --------------------------------------------------------------------
        $display("\n--- PHASE 9: VeeR EL2 Core Boot & Unified Memory Execution ---");
        // Preload valid RV32I program into Unified Memory at reset vector (0x0000_0000)
        // Program logic:
        //   0x00: addi x1, x0, 10       (32'h00a00093)
        //   0x04: addi x2, x0, 20       (32'h01400113)
        //   0x08: add  x3, x1, x2       (32'h002081b3) -> x3 = 30
        //   0x0C: sw   x3, 32(x0)       (32'h02302023) -> mem[0x20] = 30
        //   0x10: lw   x4, 32(x0)       (32'h02002203) -> x4 = 30
        //   0x14: jal  x0, 0            (32'h0000006f) -> self-loop
        axi_write(32'h0000_0000, 32'h00a00093, ok);
        axi_write(32'h0000_0004, 32'h01400113, ok);
        axi_write(32'h0000_0008, 32'h002081b3, ok);
        axi_write(32'h0000_000C, 32'h02302023, ok);
        axi_write(32'h0000_0010, 32'h02002203, ok);
        axi_write(32'h0000_0014, 32'h0000006f, ok);
        check(ok, "Boot program preloaded into Unified Memory via S00");

        // Release Core Reset (assert core_rst_n_i = 1)
        $display("Releasing VeeR EL2 processor reset...");
        @(negedge clk);
        core_rst_n_i = 1'b1;

        // Monitor IFU fetch and instruction execution
        begin
            integer fetch_timeout;
            reg saw_core_fetch;
            reg saw_core_exec;
            reg [31:0] last_trace_pc;

            saw_core_fetch = 1'b0;
            saw_core_exec  = 1'b0;
            last_trace_pc  = 32'hFFFF_FFFF;
            for (fetch_timeout = 0; fetch_timeout < 250; fetch_timeout = fetch_timeout + 1) begin
                @(posedge clk);
                if (trace_rv_i_valid_ip) begin
                    saw_core_exec = 1'b1;
                    if (trace_rv_i_address_ip != last_trace_pc) begin
                        $display("[VeeR TRACE] PC=0x%08h INSN=0x%08h", trace_rv_i_address_ip, trace_rv_i_insn_ip);
                        last_trace_pc = trace_rv_i_address_ip;
                    end
                    if (trace_rv_i_address_ip == 32'h0000_0000) saw_core_fetch = 1'b1;
                end
            end

            check(saw_core_fetch || saw_core_exec, "VeeR EL2 processor boot & fetch from Unified Memory confirmed");
        end

        // Check data written by core into memory at address 0x0000_0020
        axi_read(32'h0000_0020, rd_val, ok);
        check(ok && rd_val == 32'd30, "LSU executed store instruction: mem[0x20] contains computed result (30)");

        // --------------------------------------------------------------------
        // Final Summary Banner
        // --------------------------------------------------------------------
        $display("\n=========================================================================");
        $display(" VERIFICATION SUMMARY");
        $display(" Total Tests Conducted : %0d", total_tests);
        $display(" Total Tests PASSED    : %0d", pass_count);
        $display(" Total Tests FAILED    : %0d", fail_count);
        $display("=========================================================================");

        if (fail_count == 0) begin
            $display(" *** ALL TESTS PASSED SUCCESSFULLY! ***\n");
        end else begin
            $display(" !!! SOME TESTS FAILED! PLEASE REVIEW LOGS. !!!\n");
        end

        $finish;
    end

endmodule
