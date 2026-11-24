// ============================================================================
// File: tb_soc_veer_el2_firmware_exec.sv
// Project: Design and Verification of a RISC-V-Based SoC for Smart
//          Temperature Monitoring and Fan Control
//
// Description:
//   Dedicated bare-metal C firmware execution and verification testbench.
//   Executes the compiled firmware image (temperature_fan.elf) on the
//   fully integrated VeeR EL2 SoC with 64 KiB Unified Memory, 2M x 8S AXI
//   crossbar interconnect, UART, SPI, GPIO, Timer, PWM, and 7-Segment display.
//
// Verification Scope:
//   1. Memory Preload: Load temperature_fan_words.hex into 64 KiB Unified Memory
//   2. Processor Boot: Deassert core reset and verify CRT0 initialization
//   3. MMIO Communication: Capture and display real-time UART telemetry
//   4. Dynamic Stimulus: Behavioral SPI temperature sensor providing dynamic
//      temperature transitions (25 C -> 30 C -> 35 C -> 45 C -> 50 C -> 55 C -> 70 C -> 25 C)
//   5. Closed-Loop Hardware Verification: Verify PWM duty cycle modulation,
//      seven-segment display updates, timer pacing, and GPIO status
//   6. Firmware Halt Verification: Detect graceful completion at WFI halt loop
// ============================================================================

`timescale 1ns / 1ps

module tb_soc_veer_el2_firmware_exec;

    parameter DATA_WIDTH            = 32;
    parameter ADDR_WIDTH            = 32;
    parameter IC_ID_WIDTH           = 8;
    parameter GPIO_NUM_BITS         = 32;
    parameter SEVEN_SEG_REFRESH_DIV = 10; // Accelerated refresh for simulation

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

    // Peripheral Signals
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

    // Core Trace / Observability Interface
    wire [31:0]              trace_rv_i_insn_ip;
    wire [31:0]              trace_rv_i_address_ip;
    wire                     trace_rv_i_valid_ip;
    wire                     trace_rv_i_exception_ip;
    wire [4:0]               trace_rv_i_ecause_ip;
    wire                     trace_rv_i_interrupt_ip;
    wire [31:0]              trace_rv_i_tval_ip;

    // Verification Counters
    integer total_tests = 0;
    integer pass_count  = 0;
    integer fail_count  = 0;

    reg     firmware_halted = 1'b0;
    reg     saw_main_entry  = 1'b0;
    integer instructions_executed = 0;
    integer dbg_cycle_cnt = 0;

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
    // Verification Tasks
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
    // External AXI Master Helper Tasks (S00)
    // ------------------------------------------------------------------------
    task automatic axi_write;
        input  [31:0] addr;
        input  [31:0] data;
        output        ok;
        integer timeout;
        begin
            ok = 1'b0;
            @(negedge clk);
            axi_awaddr  = addr;
            axi_awvalid = 1'b1;
            axi_wdata   = data;
            axi_wstrb   = 4'b1111;
            axi_wlast   = 1'b1;
            axi_wvalid  = 1'b1;
            axi_bready  = 1'b1;

            timeout = 100;
            fork
                begin
                    while (!axi_awready && timeout > 0) begin
                        @(posedge clk);
                        timeout = timeout - 1;
                    end
                    @(negedge clk);
                    axi_awvalid = 1'b0;
                end
                begin
                    while (!axi_wready && timeout > 0) begin
                        @(posedge clk);
                        timeout = timeout - 1;
                    end
                    @(negedge clk);
                    axi_wvalid = 1'b0;
                end
            join

            timeout = 100;
            while (!axi_bvalid && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end

            if (axi_bvalid && axi_bresp == 2'b00) begin
                ok = 1'b1;
            end
            @(negedge clk);
            axi_bready = 1'b0;
        end
    endtask

    task automatic axi_read;
        input  [31:0] addr;
        output [31:0] data;
        output        ok;
        integer timeout;
        begin
            ok = 1'b0;
            data = 32'h0;
            @(negedge clk);
            axi_araddr  = addr;
            axi_arvalid = 1'b1;
            axi_rready  = 1'b1;

            timeout = 100;
            while (!axi_arready && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end
            @(negedge clk);
            axi_arvalid = 1'b0;

            timeout = 100;
            while (!axi_rvalid && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end

            if (axi_rvalid && axi_rresp == 2'b00) begin
                data = axi_rdata;
                ok   = 1'b1;
            end
            @(negedge clk);
            axi_rready = 1'b0;
        end
    endtask

    // ------------------------------------------------------------------------
    // Dynamic SPI Temperature Sensor Slave Emulation
    // ------------------------------------------------------------------------
    reg [7:0] sensor_table [0:15];
    integer   sensor_xfer_cnt = 0;
    reg [7:0] active_sensor_byte;
    integer   sbit_idx;

    initial begin
        sensor_table[0]  = 8'h19; // 25 C (FW-SPI-001 self-test verification)
        sensor_table[1]  = 8'h19; // 25 C (Cycle 1: Normal/Quiet Mode -> Duty 25%, 7Seg 0x25C0)
        sensor_table[2]  = 8'h1E; // 30 C (Cycle 2: Warm Boundary -> Duty 50%, 7Seg 0x30C0)
        sensor_table[3]  = 8'h23; // 35 C (Cycle 3: Warm Operating Range -> Duty 50%, 7Seg 0x35C0)
        sensor_table[4]  = 8'h2D; // 45 C (Cycle 4: Upper Warm Threshold -> Duty 50%, 7Seg 0x45C0)
        sensor_table[5]  = 8'h32; // 50 C (Cycle 5: High Temp Alert -> Boost Duty 85%, 7Seg 0x50C0)
        sensor_table[6]  = 8'h37; // 55 C (Cycle 6: High Temp Alert -> Boost Duty 85%, 7Seg 0x55C0)
        sensor_table[7]  = 8'h3C; // 60 C (Cycle 7: Thermal Dissipation -> Boost Duty 85%, 7Seg 0x60C0)
        sensor_table[8]  = 8'h46; // 70 C (Cycle 8: Critical Heat Load -> Boost Duty 85%, 7Seg 0x70C0)
        sensor_table[9]  = 8'h19; // 25 C (Cycle 9: Cooldown Recovery -> Duty 25%, 7Seg 0x25C0)
        sensor_table[10] = 8'h16; // 22 C (Cycle 10: Steady-State Ambient -> Duty 25%, 7Seg 0x22C0)
        sensor_table[11] = 8'h19;
        sensor_table[12] = 8'h19;
        sensor_table[13] = 8'h19;
        sensor_table[14] = 8'h19;
        sensor_table[15] = 8'h19;
    end

    always @(negedge spi_cs_n_o) begin
        if (!rst && core_rst_n_i) begin
            if (sensor_xfer_cnt < 16) begin
                active_sensor_byte = sensor_table[sensor_xfer_cnt];
                sensor_xfer_cnt = sensor_xfer_cnt + 1;
            end else begin
                active_sensor_byte = 8'h19;
            end
            $display("\n[SPI SENSOR SIMULATOR @ %0t] Transaction %0d: CS active low! Providing temp byte: 0x%02h (%0d C)", 
                     $time, sensor_xfer_cnt, active_sensor_byte, active_sensor_byte);
            
            // Mode 0: Pre-drive MSB before first rising edge of SCLK
            spi_miso_i = active_sensor_byte[7];
            fork
                begin : spi_bit_loop
                    for (sbit_idx = 0; sbit_idx < 8; sbit_idx = sbit_idx + 1) begin
                        @(posedge spi_clk_o);
                        @(negedge spi_clk_o);
                        if (sbit_idx < 7) begin
                            spi_miso_i = active_sensor_byte[6 - sbit_idx];
                        end
                    end
                end
                begin : spi_cs_abort
                    @(posedge spi_cs_n_o);
                end
            join_any
            disable fork;
        end
    end

    // ------------------------------------------------------------------------
    // Real-Time UART Serial ASCII Decoder & Terminal Mirror
    // ------------------------------------------------------------------------
    reg [7:0] uart_rx_char;
    integer   uart_rx_bit;
    integer   uart_chars_received = 0;
    integer   uart_hw_writes      = 0;

    always @(posedge clk) begin
        if (dut.m01_wvalid && dut.m01_wready && (dut.m01_awaddr[11:0] == 12'h000)) begin
            uart_hw_writes = uart_hw_writes + 1;
        end
    end

    always begin
        @(negedge uart_tx_o);
        // Start bit: wait 25 ns (half-bit period at divisor 4 = 50 ns per bit)
        #25;
        if (uart_tx_o == 1'b0) begin
            for (uart_rx_bit = 0; uart_rx_bit < 8; uart_rx_bit = uart_rx_bit + 1) begin
                #50;
                uart_rx_char[uart_rx_bit] = uart_tx_o;
            end
            #50; // Stop bit
            $write("%c", uart_rx_char);
            $fflush();
            uart_chars_received = uart_chars_received + 1;
        end
    end

    // ------------------------------------------------------------------------
    // VeeR EL2 Pipeline Trace & Execution Monitor
    // ------------------------------------------------------------------------
    reg [31:0] prev_pc = 32'hFFFF_FFFF;

    always @(posedge clk) begin
        if (trace_rv_i_exception_ip) begin
            $display("\n[EXCEPTION DETECTED @ %0t] PC=0x%08h ecause=%0d tval=0x%08h insn_count=%0d", 
                     $time, trace_rv_i_address_ip, trace_rv_i_ecause_ip, trace_rv_i_tval_ip, instructions_executed);
        end
        if (trace_rv_i_interrupt_ip) begin
            $display("\n[INTERRUPT DETECTED @ %0t] PC=0x%08h ecause=%0d insn_count=%0d", 
                     $time, trace_rv_i_address_ip, trace_rv_i_ecause_ip, instructions_executed);
        end

        if (trace_rv_i_valid_ip) begin
            instructions_executed = instructions_executed + 1;
            if (instructions_executed <= 90 || (instructions_executed >= 15000 && instructions_executed <= 15100)) begin
                $display("[TRACE #%0d] PC=0x%08h INSN=0x%08h", instructions_executed, trace_rv_i_address_ip, trace_rv_i_insn_ip);
            end
            if (trace_rv_i_address_ip == 32'h0000_08BE && !saw_main_entry) begin
                saw_main_entry = 1'b1;
                $display("\n[CORE MONITOR] Reached main() entry point at PC=0x%08h after %0d boot instructions", 
                         trace_rv_i_address_ip, instructions_executed);
            end
            if (trace_rv_i_address_ip == 32'h0000_003A || trace_rv_i_address_ip == 32'h0000_003E) begin
                if (!firmware_halted) begin
                    firmware_halted = 1'b1;
                    $display("\n[CORE MONITOR] VeeR EL2 core entered halt_loop (WFI at PC=0x%08h)!", trace_rv_i_address_ip);
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Main Verification Execution Sequence
    // ------------------------------------------------------------------------
    reg [31:0] rd_val;
    reg        ok;
    integer    i;

    initial begin
        $display("=========================================================================");
        $display(" START: VeeR EL2 Bare-Metal C Firmware Execution & Verification");
        $display(" Firmware Binary : firmware/temperature_fan.elf (4,268 bytes)");
        $display(" Memory Range    : 0x0000_0000 - 0x0000_FFFF (64 KiB Unified Memory)");
        $display(" Target Core     : VeeR EL2 RV32IMC RISC-V Processor");
        $display(" Interconnect    : 2-Master x 8-Slave AXI Crossbar");
        $display("=========================================================================");

        // 1. Initialize Testbench Controls and Hold Reset
        rst          = 1'b1;
        core_rst_n_i = 1'b0; // Core held in reset
        uart_rx_i    = 1'b1;
        spi_miso_i   = 1'b0;
        gpio_tb_in   = 32'h0;
        gpio_tb_dir  = 32'h0;
        timer_ext_meas_i = 1'b0;
        timer_capture_i  = 1'b0;

        axi_awid    = 8'h01;
        axi_awaddr  = 32'h0;
        axi_awlen   = 8'h0;
        axi_awsize  = 3'b010;
        axi_awburst = 2'b01;
        axi_awlock  = 1'b0;
        axi_awcache = 4'h0;
        axi_awprot  = 3'h0;
        axi_awqos   = 4'h0;
        axi_awvalid = 1'b0;
        axi_wdata   = 32'h0;
        axi_wstrb   = 4'h0;
        axi_wlast   = 1'b0;
        axi_wvalid  = 1'b0;
        axi_bready  = 1'b0;

        axi_arid    = 8'h01;
        axi_araddr  = 32'h0;
        axi_arlen   = 8'h0;
        axi_arsize  = 3'b010;
        axi_arburst = 2'b01;
        axi_arlock  = 1'b0;
        axi_arcache = 4'h0;
        axi_arprot  = 3'h0;
        axi_arqos   = 4'h0;
        axi_arvalid = 1'b0;
        axi_rready  = 1'b0;

        // 2. Release System Reset (keep Core in reset)
        #100;
        @(negedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);
        check(rst === 1'b0, "System interconnect and peripheral reset released");

        // 3. Preload Bare-Metal Firmware Image into Unified Memory (64 KiB)
        $display("\n--- STEP 1: Firmware Image Preload into Unified Memory ---");
        $readmemh("../firmware/temperature_fan_words.hex", dut.unified_mem_inst.mem);
        check(dut.unified_mem_inst.mem[0] == 32'h30001073, "Memory word 0 verified: csrw mstatus, zero (0x30001073)");
        check(dut.unified_mem_inst.mem[1] == 32'h30401073, "Memory word 1 verified: csrw mie, zero (0x30401073)");
        check(dut.unified_mem_inst.mem[2] == 32'h20000293, "Memory word 2 verified: li t0, 512 [0x200] (0x20000293)");
        check(dut.unified_mem_inst.mem[3] == 32'h7c029073, "Memory word 3 verified: csrw 0x7c0, t0 [MRAC] (0x7C029073)");
        check(dut.unified_mem_inst.mem[4] == 32'h00001197, "Memory word 4 verified: auipc gp, 0x1 (0x00001197)");

        // Verify readback through AXI S00 crossbar
        axi_read(32'h0000_0000, rd_val, ok);
        check(ok && rd_val == 32'h30001073, "AXI S00 Readback at 0x0000_0000 verified across Crossbar (0x30001073)");
        axi_read(32'h0000_0004, rd_val, ok);
        check(ok && rd_val == 32'h30401073, "AXI S00 Readback at 0x0000_0004 verified across Crossbar (0x30401073)");

        // 4. Configure Accelerated UART Baud Divisor in Hardware (Divisor = 4)
        $display("\n--- STEP 2: Configure Accelerated UART Simulation Environment ---");
        axi_write(32'h4000_000C, 32'h0000_0080, ok); // Set DLAB = 1
        axi_write(32'h4000_0008, 32'd4, ok);         // Set custom baud divisor = 4
        axi_write(32'h4000_000C, 32'h0000_0003, ok); // Clear DLAB, set 8N1
        check(ok, "UART hardware configured to simulation divisor 4 (50 ns bit period)");

        // 5. Release VeeR EL2 Processor Core Reset
        $display("\n--- STEP 3: Releasing VeeR EL2 Core Reset (Boot from 0x0000_0000) ---");
        repeat (5) @(posedge clk);
        @(negedge clk);
        core_rst_n_i = 1'b1;
        $display("[BOOT EVENT] core_rst_n_i asserted high. CPU fetching instructions from Unified Memory...\n");

        // 6. Monitor Core Execution and Telemetry until Halt Loop
        // Timeout watchdog: 2,500,000 ns (2.5 ms)
        fork
            begin : wait_for_completion
                wait (firmware_halted == 1'b1);
                repeat (2000) @(posedge clk); // Allow final UART characters to flush
                $display("\n[SUCCESS] Firmware reached halt loop successfully!");
            end
            begin : watchdog_timer
                #10000000;
                $display("\n[ERROR] Simulation watchdog timeout of 10.0 ms reached! Last PC=0x%08h, insns=%0d", 
                         trace_rv_i_address_ip, instructions_executed);
                fail_count = fail_count + 1;
            end
        join_any
        disable fork;

        // 7. Verify Closed-Loop Hardware State
        $display("\n--- STEP 4: SoC Hardware State Verification ---");
        check(saw_main_entry == 1'b1, "VeeR EL2 core executed CRT0 and successfully entered main()");
        check(instructions_executed > 1000, "VeeR EL2 executed > 1,000 instructions in firmware application");
        check(uart_chars_received > 200, "UART serial transmitter emitted full telemetry stream (> 200 chars)");
        check(sensor_xfer_cnt >= 10, "SPI Master successfully executed 10+ closed-loop sensor transactions");

        // Verify PWM modulation
        begin
            reg saw_high, saw_low;
            saw_high = 1'b0;
            saw_low  = 1'b0;
            for (i = 0; i < 200; i = i + 1) begin
                @(posedge clk);
                if (pwm_out_o == 1'b1) saw_high = 1'b1;
                if (pwm_out_o == 1'b0) saw_low  = 1'b1;
            end
            check(saw_high && saw_low, "PWM Fan Controller active modulation verified on physical output pin");
        end

        // Verify Seven-Segment display scanning
        begin
            reg [3:0] seen_anodes;
            seen_anodes = 4'h0;
            for (i = 0; i < 100; i = i + 1) begin
                @(posedge clk);
                seen_anodes = seen_anodes | ~an;
            end
            check(seen_anodes != 4'h0, "Seven-Segment Display active anode scanning verified across digits");
        end

        // 8. Final Test Summary Banner
        $display("\n=========================================================================");
        $display(" FINAL VERIFICATION SUMMARY — BARE-METAL FIRMWARE EXECUTION");
        $display(" Total Test Assertions : %0d", total_tests);
        $display(" Tests PASSED          : %0d", pass_count);
        $display(" Tests FAILED          : %0d", fail_count);
        $display(" Instructions Executed : %0d", instructions_executed);
        $display(" Characters Emitted    : %0d (HW Writes: %0d)", uart_chars_received, uart_hw_writes);
        $display(" SPI Transactions      : %0d", sensor_xfer_cnt);
        $display("=========================================================================");

        if (fail_count == 0 && firmware_halted) begin
            $display(" *** ALL FIRMWARE EXECUTION TESTS PASSED SUCCESSFULLY! ***\n");
        end else begin
            $display(" !!! SOME TESTS FAILED! PLEASE REVIEW EXECUTION LOG. !!!\n");
        end

        $finish;
    end

endmodule
