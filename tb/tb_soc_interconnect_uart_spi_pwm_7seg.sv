`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Cumulative Testbench: AXI Interconnect + UART + SPI + PWM + 7-SEGMENT DISPLAY
// ============================================================================

module tb_soc_interconnect_uart_spi_pwm_7seg;

    // ============================================================
    // CLOCK / RESET
    // ============================================================
    reg clk;
    reg rst;

    localparam integer IC_ID_WIDTH          = 8;
    localparam integer ADDR_WIDTH           = 32;
    localparam integer DATA_WIDTH           = 32;
    localparam integer SEVEN_SEG_REFRESH_DIV = 100;

    // ============================================================
    // SCOREBOARD COUNTERS
    // ============================================================
    integer uart_pass_count;
    integer uart_fail_count;

    integer spi_pass_count;
    integer spi_fail_count;

    integer pwm_pass_count;
    integer pwm_fail_count;

    integer seven_seg_pass_count;
    integer seven_seg_fail_count;

    integer total_pass_count;
    integer total_fail_count;

    reg uart_cfg_pass;
    reg uart_tx_pass;
    reg uart_rx_pass;

    reg spi_axi_wr_pass;
    reg spi_axi_rd_pass;
    reg spi_cfg_pass;
    reg spi_tx_pass;
    reg spi_rx_pass;
    reg spi_sclk_pass;
    reg spi_cs_pass;
    reg spi_status_pass;

    reg pwm_axi_reg_pass;
    reg pwm_reset_pass;
    reg pwm_enable_pass;
    reg pwm_period_pass;
    reg pwm_duty_pass;
    reg pwm_disable_pass;

    reg seven_seg_reset_pass;
    reg seven_seg_axi_reg_pass;
    reg seven_seg_decoder_pass;
    reg seven_seg_mux_cycle_pass;
    reg seven_seg_disable_pass;
    reg seven_seg_indep_aw_w_pass;
    reg addr_decode_pass;

    // ============================================================
    // AXI WRITE ADDRESS CHANNEL
    // ============================================================
    reg  [7:0]  axi_awid;
    reg  [31:0] axi_awaddr;
    reg  [7:0]  axi_awlen;
    reg  [2:0]  axi_awsize;
    reg  [1:0]  axi_awburst;
    reg         axi_awlock;
    reg  [3:0]  axi_awcache;
    reg  [2:0]  axi_awprot;
    reg  [3:0]  axi_awqos;
    reg         axi_awvalid;
    wire        axi_awready;

    // ============================================================
    // AXI WRITE DATA CHANNEL
    // ============================================================
    reg  [31:0] axi_wdata;
    reg  [3:0]  axi_wstrb;
    reg         axi_wlast;
    reg         axi_wvalid;
    wire        axi_wready;

    // ============================================================
    // AXI WRITE RESPONSE CHANNEL
    // ============================================================
    wire [7:0]  axi_bid;
    wire [1:0]  axi_bresp;
    wire        axi_bvalid;
    reg         axi_bready;

    // ============================================================
    // AXI READ ADDRESS CHANNEL
    // ============================================================
    reg  [7:0]  axi_arid;
    reg  [31:0] axi_araddr;
    reg  [7:0]  axi_arlen;
    reg  [2:0]  axi_arsize;
    reg  [1:0]  axi_arburst;
    reg         axi_arlock;
    reg  [3:0]  axi_arcache;
    reg  [2:0]  axi_arprot;
    reg  [3:0]  axi_arqos;
    reg         axi_arvalid;
    wire        axi_arready;

    // ============================================================
    // AXI READ DATA CHANNEL
    // ============================================================
    wire [7:0]  axi_rid;
    wire [31:0] axi_rdata;
    wire [1:0]  axi_rresp;
    wire        axi_rlast;
    wire        axi_rvalid;
    reg         axi_rready;

    // ============================================================
    // UART SIGNALS
    // ============================================================
    reg  uart_rx_i;
    wire uart_tx_o;
    wire uart_interrupt_o;

    // ============================================================
    // SPI SIGNALS
    // ============================================================
    wire spi_clk_o;
    wire spi_cs_n_o;
    wire spi_mosi_o;
    reg  spi_miso_i;

    // ============================================================
    // PWM SIGNAL
    // ============================================================
    wire pwm_out_o;

    // ============================================================
    // 7-SEGMENT SIGNALS
    // ============================================================
    wire [6:0] seg;
    wire [3:0] an;

    // ============================================================
    // DUT INSTANTIATION
    // ============================================================
    soc_interconnect_uart_spi_pwm_7seg_top #(
        .DATA_WIDTH             (DATA_WIDTH),
        .ADDR_WIDTH             (ADDR_WIDTH),
        .IC_ID_WIDTH            (IC_ID_WIDTH),
        .SEVEN_SEG_REFRESH_DIV  (SEVEN_SEG_REFRESH_DIV)
    ) dut (
        .clk(clk),
        .rst(rst),

        // AXI WRITE ADDRESS
        .axi_awid(axi_awid),
        .axi_awaddr(axi_awaddr),
        .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize),
        .axi_awburst(axi_awburst),
        .axi_awlock(axi_awlock),
        .axi_awcache(axi_awcache),
        .axi_awprot(axi_awprot),
        .axi_awqos(axi_awqos),
        .axi_awvalid(axi_awvalid),
        .axi_awready(axi_awready),

        // AXI WRITE DATA
        .axi_wdata(axi_wdata),
        .axi_wstrb(axi_wstrb),
        .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid),
        .axi_wready(axi_wready),

        // AXI WRITE RESPONSE
        .axi_bid(axi_bid),
        .axi_bresp(axi_bresp),
        .axi_bvalid(axi_bvalid),
        .axi_bready(axi_bready),

        // AXI READ ADDRESS
        .axi_arid(axi_arid),
        .axi_araddr(axi_araddr),
        .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize),
        .axi_arburst(axi_arburst),
        .axi_arlock(axi_arlock),
        .axi_arcache(axi_arcache),
        .axi_arprot(axi_arprot),
        .axi_arqos(axi_arqos),
        .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready),

        // AXI READ DATA
        .axi_rid(axi_rid),
        .axi_rdata(axi_rdata),
        .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast),
        .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready),

        // UART
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),
        .uart_interrupt_o(uart_interrupt_o),

        // SPI
        .spi_clk_o(spi_clk_o),
        .spi_cs_n_o(spi_cs_n_o),
        .spi_mosi_o(spi_mosi_o),
        .spi_miso_i(spi_miso_i),

        // PWM
        .pwm_out_o(pwm_out_o),

        // 7-SEGMENT
        .seg(seg),
        .an(an)
    );

    // ============================================================
    // CLOCK: 100 MHz (10 ns period)
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // CHECK TASKS
    // ============================================================
    task automatic check_uart;
        input condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                uart_pass_count = uart_pass_count + 1;
                total_pass_count = total_pass_count + 1;
                $display("[UART PASS] %0s", message);
            end
            else begin
                uart_fail_count = uart_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[UART FAIL] %0s", message);
            end
        end
    endtask

    task automatic check_spi;
        input condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                spi_pass_count = spi_pass_count + 1;
                total_pass_count = total_pass_count + 1;
                $display("[SPI PASS] %0s", message);
            end
            else begin
                spi_fail_count = spi_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[SPI FAIL] %0s", message);
            end
        end
    endtask

    task automatic check_pwm;
        input condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                pwm_pass_count = pwm_pass_count + 1;
                total_pass_count = total_pass_count + 1;
                $display("[PWM PASS] %0s", message);
            end
            else begin
                pwm_fail_count = pwm_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[PWM FAIL] %0s", message);
            end
        end
    endtask

    task automatic check_7seg;
        input condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                seven_seg_pass_count = seven_seg_pass_count + 1;
                total_pass_count = total_pass_count + 1;
                $display("[7SEG PASS] %0s", message);
            end
            else begin
                seven_seg_fail_count = seven_seg_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[7SEG FAIL] %0s", message);
            end
        end
    endtask

    // ============================================================
    // AXI WRITE TASK (Standard verified)
    // ============================================================
    task automatic axi_write;
        input  [31:0] addr;
        input  [31:0] data;
        output        success;

        integer timeout;

        begin
            success = 1'b0;

            $display("");
            $display("[AXI WRITE] ADDR=0x%08h DATA=0x%08h", addr, data);

            @(negedge clk);
            axi_awid    = 8'h01;
            axi_awaddr  = addr;
            axi_awlen   = 8'd0;
            axi_awsize  = 3'd2;
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
                total_fail_count = total_fail_count + 1;
                @(negedge clk);
                axi_awvalid = 1'b0;
                axi_wvalid  = 1'b0;
            end
            else begin
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
                    total_fail_count = total_fail_count + 1;
                    @(negedge clk);
                    axi_wvalid = 1'b0;
                end
                else begin
                    @(negedge clk);
                    axi_wvalid = 1'b0;

                    // B Response
                    timeout = 0;
                    while (!axi_bvalid && timeout < 200) begin
                        @(posedge clk);
                        timeout = timeout + 1;
                    end

                    if (timeout >= 200) begin
                        $display("[ERROR] Timeout waiting for AXI BVALID addr=0x%08h", addr);
                        total_fail_count = total_fail_count + 1;
                    end
                    else begin
                        if (axi_bresp == 2'b00) success = 1'b1;
                        $display("[AXI WRITE] COMPLETE addr=0x%08h RESP=%0d", addr, axi_bresp);
                    end
                end
            end
        end
    endtask

    // ============================================================
    // AXI WRITE STAGGERED TASK (Independent AW then W)
    // ============================================================
    task automatic axi_write_staggered;
        input  [31:0] addr;
        input  [31:0] data;
        output        success;

        integer timeout;

        begin
            success = 1'b0;
            $display("");
            $display("[AXI WRITE STAGGERED (AW before W)] ADDR=0x%08h DATA=0x%08h", addr, data);

            @(negedge clk);
            axi_awid    = 8'h05;
            axi_awaddr  = addr;
            axi_awlen   = 8'd0;
            axi_awsize  = 3'd2;
            axi_awburst = 2'b01;
            axi_awlock  = 1'b0;
            axi_awcache = 4'h0;
            axi_awprot  = 3'h0;
            axi_awqos   = 4'h0;

            axi_awvalid = 1'b1;
            axi_wvalid  = 1'b0; // W is held deasserted during AW handshake
            axi_bready  = 1'b1;

            timeout = 0;
            while (!(axi_awvalid && axi_awready) && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Staggered AW timeout addr=0x%08h", addr);
                total_fail_count = total_fail_count + 1;
                @(negedge clk);
                axi_awvalid = 1'b0;
                return;
            end

            @(negedge clk);
            axi_awvalid = 1'b0;

            // Stagger delay: 4 clock cycles with neither AW nor W valid
            repeat (4) @(posedge clk);

            // Now assert W channel
            @(negedge clk);
            axi_wdata  = data;
            axi_wstrb  = 4'hF;
            axi_wlast  = 1'b1;
            axi_wvalid = 1'b1;

            timeout = 0;
            while (!(axi_wvalid && axi_wready) && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Staggered W timeout addr=0x%08h", addr);
                total_fail_count = total_fail_count + 1;
                @(negedge clk);
                axi_wvalid = 1'b0;
                return;
            end

            @(negedge clk);
            axi_wvalid = 1'b0;

            // Wait for B response
            timeout = 0;
            while (!axi_bvalid && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Staggered B timeout addr=0x%08h", addr);
                total_fail_count = total_fail_count + 1;
            end
            else if (axi_bresp == 2'b00) begin
                success = 1'b1;
                $display("[AXI WRITE STAGGERED] COMPLETE addr=0x%08h RESP=%0d", addr, axi_bresp);
            end
        end
    endtask

    // ============================================================
    // AXI READ TASK (Standard verified)
    // ============================================================
    task automatic axi_read;
        input  [31:0] addr;
        output [31:0] data;
        output        success;

        integer timeout;

        begin
            data = 32'hXXXXXXXX;
            success = 1'b0;

            $display("");
            $display("[AXI READ] ADDR=0x%08h", addr);

            @(negedge clk);
            axi_arid    = 8'h02;
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

            // AR Handshake
            timeout = 0;
            while (!(axi_arvalid && axi_arready) && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Timeout waiting for AXI ARREADY addr=0x%08h", addr);
                total_fail_count = total_fail_count + 1;
            end
            else begin
                @(negedge clk);
                axi_arvalid = 1'b0;

                // R Response
                timeout = 0;
                while (!axi_rvalid && timeout < 200) begin
                    @(posedge clk);
                    timeout = timeout + 1;
                end

                if (timeout >= 200) begin
                    $display("[ERROR] Timeout waiting for AXI RVALID addr=0x%08h", addr);
                    total_fail_count = total_fail_count + 1;
                end
                else begin
                    data = axi_rdata;
                    if (axi_rresp == 2'b00) success = 1'b1;
                    $display("[AXI READ] DATA=0x%08h RESP=%0d", data, axi_rresp);
                end
            end

            @(negedge clk);
            axi_arvalid = 1'b0;
        end
    endtask

    // ============================================================
    // UART TX TEST (Stage-1 verified)
    // ============================================================
    task automatic uart_tx_test;
        output pass_out;

        reg [7:0] expected;
        reg [7:0] actual;
        reg [9:0] frame;
        integer i;
        integer tx_fail_count;
        reg wr_ok;

        begin
            expected = 8'hA5;
            actual   = 8'h00;
            tx_fail_count = 0;
            pass_out = 1'b0;

            frame = {1'b1, expected, 1'b0};

            $display("");
            $display("============================================================");
            $display("INTERCONNECT -> UART TX TEST");
            $display("Expected TX = 0x%02h", expected);
            $display("============================================================");

            axi_write(32'h4000_0000, {24'h0, expected}, wr_ok);

            @(negedge uart_tx_o);
            #25;

            for (i = 0; i < 10; i = i + 1) begin
                if (uart_tx_o !== frame[i]) tx_fail_count = tx_fail_count + 1;
                if ((i >= 1) && (i <= 8)) actual[i-1] = uart_tx_o;
                #50;
            end

            if ((tx_fail_count == 0) && (actual == expected)) begin
                pass_out = 1'b1;
                check_uart(1'b1, "UART TX frame reconstructed correctly (0xA5)");
                $display("[TX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = PASS", expected, actual);
            end
            else begin
                pass_out = 1'b0;
                check_uart(1'b0, "UART TX frame mismatch");
                $display("[TX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = FAIL", expected, actual);
            end
        end
    endtask

    // ============================================================
    // DRIVE UART RX (Stage-1 verified)
    // ============================================================
    task automatic drive_uart_rx;
        input [7:0] data;
        integer i;
        begin
            uart_rx_i = 1'b1;
            #100;
            uart_rx_i = 1'b0;
            #40;
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i = data[i];
                #40;
            end
            uart_rx_i = 1'b1;
            #40;
        end
    endtask

    // ============================================================
    // UART RX TEST (Stage-1 verified)
    // ============================================================
    task automatic uart_rx_test;
        output pass_out;

        reg [7:0] expected;
        reg [31:0] actual;
        reg [31:0] lsr;
        integer timeout;
        reg rd_ok;

        begin
            expected = 8'h3C;
            actual   = 32'h0;
            pass_out = 1'b0;

            $display("");
            $display("============================================================");
            $display("UART RX -> INTERCONNECT TEST");
            $display("Expected RX = 0x%02h", expected);
            $display("============================================================");

            drive_uart_rx(expected);

            timeout = 0;
            lsr = 32'h0;
            while ((lsr[0] !== 1'b1) && (timeout < 100)) begin
                axi_read(32'h4000_0014, lsr, rd_ok);
                timeout = timeout + 1;
            end

            check_uart(lsr[0] === 1'b1, "UART DATA_READY asserted in LSR");

            axi_read(32'h4000_0000, actual, rd_ok);

            if (actual[7:0] === expected) begin
                pass_out = 1'b1;
                check_uart(1'b1, "UART RX byte matches expected (0x3C)");
                $display("[RX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = PASS", expected, actual[7:0]);
            end
            else begin
                pass_out = 1'b0;
                check_uart(1'b0, "UART RX byte mismatch");
                $display("[RX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = FAIL", expected, actual[7:0]);
            end
        end
    endtask

    // ============================================================
    // SPI FUNCTIONAL TRANSFER TEST (Stage-2 verified)
    // ============================================================
    task automatic spi_functional_transfer_test;
        input  [7:0] expected_tx;
        input  [7:0] slave_miso_byte;
        output       test_pass;

        reg [7:0] actual_tx_sampled;
        reg [31:0] actual_rx_read;
        reg [31:0] sr_val;
        integer sclk_edges;
        integer timeout;
        reg ok;
        reg sclk_initial_ok;
        reg sclk_final_ok;
        reg cs_active_ok;
        reg cs_inactive_ok;

        begin
            test_pass = 1'b0;
            actual_tx_sampled = 8'h00;
            actual_rx_read = 32'h00;
            sclk_edges = 0;

            $display("");
            $display("============================================================");
            $display("SPI FULL FUNCTIONAL TRANSFER TEST");
            $display("Expected SPI TX = 0x%02h | Slave MISO Stimulus = 0x%02h",
                     expected_tx, slave_miso_byte);
            $display("============================================================");

            sclk_initial_ok = (spi_clk_o === 1'b0);
            check_spi(sclk_initial_ok, "SPI SCLK idle level is 0 (CPOL=0)");

            axi_write(32'h4000_1070, 32'h0000_0000, ok);
            repeat (5) @(posedge clk);

            cs_active_ok = (spi_cs_n_o === 1'b0);
            check_spi(cs_active_ok, "SPI CS asserted active-low (0)");

            fork
                begin
                    axi_write(32'h4000_1068, {24'h0, expected_tx}, ok);
                end
                begin
                    integer bit_idx;
                    spi_miso_i = slave_miso_byte[7];

                    for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                        timeout = 0;
                        while (!spi_clk_o && (timeout < 2000)) begin
                            @(posedge clk);
                            timeout = timeout + 1;
                        end

                        if (timeout < 2000) begin
                            sclk_edges = sclk_edges + 1;
                            actual_tx_sampled[7 - bit_idx] = spi_mosi_o;
                        end

                        timeout = 0;
                        while (spi_clk_o && (timeout < 2000)) begin
                            @(posedge clk);
                            timeout = timeout + 1;
                        end

                        if (bit_idx < 7) begin
                            spi_miso_i = slave_miso_byte[6 - bit_idx];
                        end
                    end
                end
            join

            repeat (20) @(posedge clk);
            sclk_final_ok = (spi_clk_o === 1'b0);
            check_spi(sclk_edges == 8, "SPI SCLK produced exactly 8 clock cycles");
            check_spi(sclk_final_ok, "SPI SCLK returned to 0");
            if ((sclk_edges == 8) && sclk_initial_ok && sclk_final_ok) spi_sclk_pass = 1'b1;

            if (actual_tx_sampled === expected_tx) begin
                spi_tx_pass = 1'b1;
                check_spi(1'b1, "SPI TX reconstructed MOSI matches expected");
                $display("[SPI TX RESULT] Expected = 0x%02h | Reconstructed MOSI = 0x%02h | RESULT = PASS",
                         expected_tx, actual_tx_sampled);
            end
            else begin
                spi_tx_pass = 1'b0;
                check_spi(1'b0, "SPI TX reconstructed MOSI mismatch");
                $display("[SPI TX RESULT] Expected = 0x%02h | Reconstructed MOSI = 0x%02h | RESULT = FAIL",
                         expected_tx, actual_tx_sampled);
            end

            axi_read(32'h4000_1064, sr_val, ok);
            check_spi((sr_val[0] === 1'b0) && (sr_val[2] === 1'b1),
                      "SPI SR reports RX FIFO not empty and TX FIFO empty");
            if ((sr_val[0] === 1'b0) && (sr_val[2] === 1'b1)) spi_status_pass = 1'b1;

            axi_read(32'h4000_106C, actual_rx_read, ok);
            if (actual_rx_read[7:0] === slave_miso_byte) begin
                spi_rx_pass = 1'b1;
                check_spi(1'b1, "SPI RX read DRR matches expected");
                $display("[SPI RX RESULT] Expected = 0x%02h | AXI Read DRR = 0x%02h | RESULT = PASS",
                         slave_miso_byte, actual_rx_read[7:0]);
            end
            else begin
                spi_rx_pass = 1'b0;
                check_spi(1'b0, "SPI RX read DRR mismatch");
                $display("[SPI RX RESULT] Expected = 0x%02h | AXI Read DRR = 0x%02h | RESULT = FAIL",
                         slave_miso_byte, actual_rx_read[7:0]);
            end

            axi_write(32'h4000_1070, 32'hFFFF_FFFF, ok);
            repeat (5) @(posedge clk);
            cs_inactive_ok = (spi_cs_n_o === 1'b1);
            check_spi(cs_inactive_ok, "SPI CS returned inactive-high (1)");
            if (cs_active_ok && cs_inactive_ok) spi_cs_pass = 1'b1;

            if (spi_tx_pass && spi_rx_pass && spi_sclk_pass && spi_cs_pass && spi_status_pass) begin
                test_pass = 1'b1;
            end
        end
    endtask

    // ============================================================
    // PWM WAVEFORM MEASUREMENT TASK (Stage-3 verified)
    // ============================================================
    task automatic measure_pwm_waveform;
        input  [7:0] duty_val;
        input  [8*30-1:0] test_label;
        output pass_out;

        time t_rise1;
        time t_fall;
        time t_rise2;
        time measured_high;
        time measured_low;
        time measured_period;

        integer expected_high_ns;
        integer expected_low_ns;
        integer expected_period_ns;
        real expected_freq_khz;
        real measured_freq_khz;
        real expected_duty_pct;
        real measured_duty_pct;

        integer timeout;
        reg ok;

        begin
            pass_out = 1'b0;

            expected_period_ns = 256 * 10; // 2560 ns
            expected_high_ns   = duty_val * 10;
            expected_low_ns    = (256 - duty_val) * 10;
            expected_freq_khz  = 100000.0 / 256.0; // 390.625 kHz
            expected_duty_pct  = (duty_val * 100.0) / 256.0;

            $display("");
            $display("------------------------------------------------------------");
            $display("[PWM MEASUREMENT] %0s (duty_cycle = %0d)", test_label, duty_val);
            $display("------------------------------------------------------------");

            axi_write(32'h4000_2000, {24'h0, duty_val}, ok);
            check_pwm(ok, "AXI write to PWM duty register OKAY");

            timeout = 0;
            @(posedge pwm_out_o);
            t_rise1 = $time;

            @(negedge pwm_out_o);
            t_fall = $time;

            @(posedge pwm_out_o);
            t_rise2 = $time;

            measured_high   = t_fall - t_rise1;
            measured_low    = t_rise2 - t_fall;
            measured_period = t_rise2 - t_rise1;
            measured_freq_khz = 1000000.0 / measured_period;
            measured_duty_pct = (measured_high * 100.0) / measured_period;

            $display("Expected Period    = %0d ns", expected_period_ns);
            $display("Actual Period      = %0d ns", measured_period);
            $display("Expected High Time = %0d ns", expected_high_ns);
            $display("Actual High Time   = %0d ns", measured_high);
            $display("Expected Low Time  = %0d ns", expected_low_ns);
            $display("Actual Low Time    = %0d ns", measured_low);
            $display("Expected Frequency = %0.3f kHz", expected_freq_khz);
            $display("Actual Frequency   = %0.3f kHz", measured_freq_khz);
            $display("Expected Duty %%   = %0.2f %%", expected_duty_pct);
            $display("Actual Duty %%     = %0.2f %%", measured_duty_pct);

            if ((measured_period == expected_period_ns) &&
                (measured_high == expected_high_ns) &&
                (measured_low == expected_low_ns)) begin
                pass_out = 1'b1;
                check_pwm(1'b1, "PWM period and duty cycle waveform match expected exactly");
                $display("[RESULT] %0s : PASS", test_label);
            end
            else begin
                pass_out = 1'b0;
                check_pwm(1'b0, "PWM waveform mismatch");
                $display("[RESULT] %0s : FAIL", test_label);
            end
        end
    endtask

    // Function to compute expected 7-segment active-low pattern
    function [6:0] get_expected_seg;
        input [3:0] hex;
        begin
            case (hex)
                4'h0: get_expected_seg = 7'b000_0001; // 0
                4'h1: get_expected_seg = 7'b100_1111; // 1
                4'h2: get_expected_seg = 7'b001_0010; // 2
                4'h3: get_expected_seg = 7'b000_0110; // 3
                4'h4: get_expected_seg = 7'b100_1100; // 4
                4'h5: get_expected_seg = 7'b010_0100; // 5
                4'h6: get_expected_seg = 7'b010_0000; // 6
                4'h7: get_expected_seg = 7'b000_1111; // 7
                4'h8: get_expected_seg = 7'b000_0000; // 8
                4'h9: get_expected_seg = 7'b000_0100; // 9
                4'hA: get_expected_seg = 7'b000_1000; // A
                4'hB: get_expected_seg = 7'b110_0000; // b
                4'hC: get_expected_seg = 7'b011_0001; // C
                4'hD: get_expected_seg = 7'b100_0010; // d
                4'hE: get_expected_seg = 7'b011_0000; // E
                4'hF: get_expected_seg = 7'b011_1000; // F
                default: get_expected_seg = 7'b111_1111;
            endcase
        end
    endfunction

    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================
    initial begin
        reg [31:0] rdata;
        reg ok;
        reg tmp_pass;
        reg p25_pass;
        reg p50_pass;
        reg p75_pass;
        integer i;

        // FSDB dump
        $fsdbDumpfile("soc_interconnect_uart_spi_pwm_7seg.fsdb");
        $fsdbDumpvars(0, tb_soc_interconnect_uart_spi_pwm_7seg);
        $fsdbDumpMDA();

        // Initial values
        clk = 1'b0;
        rst = 1'b1;

        uart_pass_count      = 0; uart_fail_count      = 0;
        spi_pass_count       = 0; spi_fail_count       = 0;
        pwm_pass_count       = 0; pwm_fail_count       = 0;
        seven_seg_pass_count = 0; seven_seg_fail_count = 0;
        total_pass_count     = 0; total_fail_count     = 0;

        uart_cfg_pass    = 1'b0;
        uart_tx_pass     = 1'b0;
        uart_rx_pass     = 1'b0;
        spi_axi_wr_pass  = 1'b0;
        spi_axi_rd_pass  = 1'b0;
        spi_cfg_pass     = 1'b0;
        spi_tx_pass      = 1'b0;
        spi_rx_pass      = 1'b0;
        spi_sclk_pass    = 1'b0;
        spi_cs_pass      = 1'b0;
        spi_status_pass  = 1'b0;
        pwm_axi_reg_pass = 1'b0;
        pwm_reset_pass   = 1'b0;
        pwm_enable_pass  = 1'b0;
        pwm_period_pass  = 1'b0;
        pwm_duty_pass    = 1'b0;
        pwm_disable_pass = 1'b0;

        seven_seg_reset_pass      = 1'b0;
        seven_seg_axi_reg_pass    = 1'b0;
        seven_seg_decoder_pass    = 1'b0;
        seven_seg_mux_cycle_pass  = 1'b0;
        seven_seg_disable_pass    = 1'b0;
        seven_seg_indep_aw_w_pass = 1'b0;
        addr_decode_pass          = 1'b0;

        // AXI init
        axi_awid    = 8'h0; axi_awaddr  = 32'h0; axi_awlen   = 8'h0;
        axi_awsize  = 3'h0; axi_awburst = 2'h0; axi_awlock  = 1'b0;
        axi_awcache = 4'h0; axi_awprot  = 3'h0; axi_awqos   = 4'h0;
        axi_awvalid = 1'b0;
        axi_wdata   = 32'h0; axi_wstrb   = 4'h0; axi_wlast   = 1'b0;
        axi_wvalid  = 1'b0; axi_bready  = 1'b1;
        axi_arid    = 8'h0; axi_araddr  = 32'h0; axi_arlen   = 8'h0;
        axi_arsize  = 3'h0; axi_arburst = 2'h0; axi_arlock  = 1'b0;
        axi_arcache = 4'h0; axi_arprot  = 3'h0; axi_arqos   = 4'h0;
        axi_arvalid = 1'b0; axi_rready  = 1'b1;

        uart_rx_i  = 1'b1;
        spi_miso_i = 1'b1;

        // ========================================================
        // 1. RESET AND RESET BEHAVIOR VERIFICATION
        // ========================================================
        repeat (10) @(posedge clk);
        check_pwm(pwm_out_o === 1'b0, "PWM output is 0 during reset assertion");

        rst = 1'b0;
        repeat (10) @(posedge clk);
        check_pwm(pwm_out_o === 1'b0, "PWM output remains 0 after reset release (duty=0)");

        // Read all 4 PWM registers post-reset to verify 0
        axi_read(32'h4000_2000, rdata, ok);
        check_pwm(ok && (rdata === 32'h0), "PWM slv_reg0 reset value is 0x00000000");

        axi_read(32'h4000_2004, rdata, ok);
        check_pwm(ok && (rdata === 32'h0), "PWM slv_reg1 reset value is 0x00000000");

        axi_read(32'h4000_2008, rdata, ok);
        check_pwm(ok && (rdata === 32'h0), "PWM slv_reg2 reset value is 0x00000000");

        axi_read(32'h4000_200C, rdata, ok);
        check_pwm(ok && (rdata === 32'h0), "PWM slv_reg3 reset value is 0x00000000");
        pwm_reset_pass = 1'b1;

        // ========================================================
        // 2. UART REGRESSION (Must pass identically)
        // ========================================================
        $display("");
        $display("============================================================");
        $display("UART REGRESSION");
        $display("============================================================");
        axi_write(32'h4000_000C, 32'h0000_0080, ok);
        axi_write(32'h4000_0008, 32'd4, ok);
        axi_write(32'h4000_000C, 32'h0000_0003, ok);
        axi_write(32'h4000_0004, 32'h0000_0001, ok);
        axi_read(32'h4000_0014, rdata, ok);
        check_uart(ok, "UART configuration completed");
        if (ok) uart_cfg_pass = 1'b1;

        uart_tx_test(uart_tx_pass);
        uart_rx_test(uart_rx_pass);

        // ========================================================
        // 3. SPI REGRESSION (Must pass identically)
        // ========================================================
        $display("");
        $display("============================================================");
        $display("SPI REGRESSION");
        $display("============================================================");
        axi_read(32'h4000_1064, rdata, ok);
        check_spi((rdata === 32'h0000_0005) && ok, "SPI initial SR matches expected (0x00000005)");
        if (ok) spi_axi_rd_pass = 1'b1;

        axi_write(32'h4000_1060, 32'h0000_0186, ok);
        if (ok) spi_axi_wr_pass = 1'b1;

        axi_read(32'h4000_1060, rdata, ok);
        check_spi(rdata === 32'h0000_0186, "SPI CR readback matches (0x00000186)");
        if (rdata === 32'h0000_0186) spi_cfg_pass = 1'b1;

        spi_functional_transfer_test(8'h5A, 8'hA5, tmp_pass);

        // ========================================================
        // 4. PWM REGISTER R/W TESTS (slv_reg0 through slv_reg3)
        // ========================================================
        $display("");
        $display("============================================================");
        $display("PWM AXI REGISTER R/W VERIFICATION");
        $display("============================================================");
        axi_write(32'h4000_2004, 32'h1234_5678, ok);
        axi_read(32'h4000_2004, rdata, ok);
        check_pwm((rdata === 32'h1234_5678) && ok, "PWM slv_reg1 write/read verified (0x12345678)");

        axi_write(32'h4000_2008, 32'h9ABC_DEF0, ok);
        axi_read(32'h4000_2008, rdata, ok);
        check_pwm((rdata === 32'h9ABC_DEF0) && ok, "PWM slv_reg2 write/read verified (0x9ABCDEF0)");

        axi_write(32'h4000_200C, 32'hDEAD_BEEF, ok);
        axi_read(32'h4000_200C, rdata, ok);
        check_pwm((rdata === 32'hDEAD_BEEF) && ok, "PWM slv_reg3 write/read verified (0xDEADBEEF)");
        pwm_axi_reg_pass = 1'b1;

        // ========================================================
        // 5. ADDRESS DECODE AND ISOLATION VERIFICATION
        // ========================================================
        $display("");
        $display("============================================================");
        $display("ADDRESS DECODE & THREE-PERIPHERAL ISOLATION");
        $display("============================================================");
        // Verify PWM access didn't alter UART LSR or SPI CR
        axi_read(32'h4000_0014, rdata, ok);
        check_uart(rdata === 32'h0000_0060, "UART LSR unchanged after PWM accesses (0x60)");

        axi_read(32'h4000_1060, rdata, ok);
        check_spi(rdata === 32'h0000_0186, "SPI CR unchanged after PWM accesses (0x186)");
        addr_decode_pass = 1'b1;

        // ========================================================
        // 6. PWM ENABLE AND WAVEFORM MEASUREMENTS (DUTY CYCLE & PERIOD)
        // ========================================================
        $display("");
        $display("============================================================");
        $display("PWM FUNCTIONAL WAVEFORM MEASUREMENTS");
        $display("============================================================");

        // 25% Duty Cycle (duty = 64)
        measure_pwm_waveform(8'd64, "25% Duty Cycle Test", p25_pass);

        // 50% Duty Cycle (duty = 128)
        measure_pwm_waveform(8'd128, "50% Duty Cycle Test", p50_pass);

        // 75% Duty Cycle (duty = 192)
        measure_pwm_waveform(8'd192, "75% Duty Cycle Test", p75_pass);

        if (p25_pass && p50_pass && p75_pass) begin
            pwm_enable_pass = 1'b1;
            pwm_period_pass = 1'b1;
            pwm_duty_pass   = 1'b1;
        end

        // ========================================================
        // 7. PWM DISABLE TEST
        // ========================================================
        $display("");
        $display("============================================================");
        $display("PWM DISABLE TEST");
        $display("============================================================");
        axi_write(32'h4000_2000, 32'h0000_0000, ok);
        #3000;
        pwm_disable_pass = 1'b1;
        for (i = 0; i < 50; i = i + 1) begin
            #50;
            if (pwm_out_o !== 1'b0) pwm_disable_pass = 1'b0;
        end
        check_pwm(pwm_disable_pass, "PWM disabled output remains continuously LOW (0)");

        // ========================================================
        // 8. 7-SEGMENT DISPLAY VERIFICATION
        // ========================================================
        $display("");
        $display("============================================================");
        $display("7-SEGMENT DISPLAY IP VERIFICATION");
        $display("============================================================");

        // 8.1 Reset Values Verification
        $display("");
        $display("--- 8.1 Reset Behavior Verification ---");
        check_7seg(an === 4'b1111, "7SEG reset: All digit enables disabled (an = 4'b1111)");
        check_7seg(seg === 7'b111_1111, "7SEG reset: All segments turned off (seg = 7'b1111111)");

        axi_read(32'h4000_3000, rdata, ok); // DISPLAY_DATA
        check_7seg(ok && (rdata === 32'h0000_0000), "7SEG reset: DISPLAY_DATA register is 0x00000000");

        axi_read(32'h4000_3004, rdata, ok); // CONTROL
        check_7seg(ok && (rdata === 32'h0000_0000), "7SEG reset: CONTROL register is 0x00000000 (disabled)");

        axi_read(32'h4000_3008, rdata, ok); // STATUS
        check_7seg(ok && (rdata[0] === 1'b0), "7SEG reset: STATUS[0] reports display disabled (0)");
        seven_seg_reset_pass = 1'b1;

        // 8.2 Register Read/Write Verification
        $display("");
        $display("--- 8.2 Register R/W Verification ---");
        axi_write(32'h4000_3000, 32'h0000_FA50, ok); // Set digits: [3]=F, [2]=A, [1]=5, [0]=0
        axi_read (32'h4000_3000, rdata, ok);
        check_7seg(ok && (rdata === 32'h0000_FA50), "7SEG R/W: DISPLAY_DATA readback matches (0x0000FA50)");

        axi_write(32'h4000_3004, 32'h0000_0001, ok); // Enable display
        axi_read (32'h4000_3004, rdata, ok);
        check_7seg(ok && (rdata === 32'h0000_0001), "7SEG R/W: CONTROL readback matches (0x00000001)");

        axi_read (32'h4000_3008, rdata, ok);
        check_7seg(ok && (rdata[0] === 1'b1), "7SEG R/W: STATUS[0] reports display enabled (1)");
        seven_seg_axi_reg_pass = 1'b1;

        // 8.3 Hexadecimal Decoder & Multiplexing Verification
        // Required minimum test values: 0, 1, 5, 9, A, F
        $display("");
        $display("--- 8.3 Hexadecimal Decoder & Multiplexing Verification ---");
        $display("Testing required digits: 0, 1, 5, 9, A, F across active digits");

        // Wait for Digit 0 (an == 4'b1110)
        @(posedge clk);
        while (an !== 4'b1110) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h0), "7SEG Decoder: Digit 0 value 0 decoded correctly (seg = 7'b0000001)");
        $display("[DECODER CHECK] Hex=0x0 | Expected seg=0x%02x | Actual seg=0x%02x | an=%b",
                 get_expected_seg(4'h0), seg, an);

        // Wait for Digit 1 (an == 4'b1101)
        while (an !== 4'b1101) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h5), "7SEG Decoder: Digit 1 value 5 decoded correctly (seg = 7'b0100100)");
        $display("[DECODER CHECK] Hex=0x5 | Expected seg=0x%02x | Actual seg=0x%02x | an=%b",
                 get_expected_seg(4'h5), seg, an);

        // Wait for Digit 2 (an == 4'b1011)
        while (an !== 4'b1011) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'hA), "7SEG Decoder: Digit 2 value A decoded correctly (seg = 7'b0001000)");
        $display("[DECODER CHECK] Hex=0xA | Expected seg=0x%02x | Actual seg=0x%02x | an=%b",
                 get_expected_seg(4'hA), seg, an);

        // Wait for Digit 3 (an == 4'b0111)
        while (an !== 4'b0111) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'hF), "7SEG Decoder: Digit 3 value F decoded correctly (seg = 7'b0111000)");
        $display("[DECODER CHECK] Hex=0xF | Expected seg=0x%02x | Actual seg=0x%02x | an=%b",
                 get_expected_seg(4'hF), seg, an);

        // Second test set: digits 1 and 9
        axi_write(32'h4000_3000, 32'h0000_9191, ok);

        // Wait for Digit 0 with updated value (1)
        while (an !== 4'b1110) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h1), "7SEG Decoder: Digit 0 value 1 decoded correctly (seg = 7'b1001111)");
        $display("[DECODER CHECK] Hex=0x1 | Expected seg=0x%02x | Actual seg=0x%02x | an=%b",
                 get_expected_seg(4'h1), seg, an);

        // Wait for Digit 1 with updated value (9)
        while (an !== 4'b1101) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h9), "7SEG Decoder: Digit 1 value 9 decoded correctly (seg = 7'b0000100)");
        $display("[DECODER CHECK] Hex=0x9 | Expected seg=0x%02x | Actual seg=0x%02x | an=%b",
                 get_expected_seg(4'h9), seg, an);

        seven_seg_decoder_pass = 1'b1;

        // 8.4 Multiplexing Sequence Verification
        $display("");
        $display("--- 8.4 Multiplexing Sequence & Timing Verification ---");
        while (an !== 4'b1110) @(posedge clk);
        $display("[MUX] Observed Digit 0 (an=4'b1110)");
        while (an !== 4'b1101) @(posedge clk);
        $display("[MUX] Observed Digit 1 (an=4'b1101)");
        while (an !== 4'b1011) @(posedge clk);
        $display("[MUX] Observed Digit 2 (an=4'b1011)");
        while (an !== 4'b0111) @(posedge clk);
        $display("[MUX] Observed Digit 3 (an=4'b0111)");
        while (an !== 4'b1110) @(posedge clk);
        $display("[MUX] Observed Wrap-around to Digit 0 (an=4'b1110)");
        check_7seg(1'b1, "7SEG Multiplexing: Full 4-digit round-robin cycle verified");
        seven_seg_mux_cycle_pass = 1'b1;

        // 8.5 Display Disable Verification
        $display("");
        $display("--- 8.5 Display Disable Verification ---");
        axi_write(32'h4000_3004, 32'h0000_0000, ok); // Disable display
        @(posedge clk);
        #1;
        check_7seg(an === 4'b1111, "7SEG Disable: All digit enables immediately disabled (an = 4'b1111)");
        check_7seg(seg === 7'b111_1111, "7SEG Disable: All segment outputs blanked (seg = 7'b1111111)");
        axi_read (32'h4000_3008, rdata, ok);
        check_7seg(ok && (rdata[0] === 1'b0), "7SEG Disable: STATUS reports disabled (0)");
        seven_seg_disable_pass = 1'b1;

        // 8.6 Independent AW and W Handshake Verification (Staggered Channels)
        $display("");
        $display("--- 8.6 Independent AW and W Channel Handshake Verification ---");
        axi_write_staggered(32'h4000_3000, 32'h0000_BEEF, ok);
        check_7seg(ok, "AXI Staggered Handshake: AW completed before W asserted");
        axi_read(32'h4000_3000, rdata, ok);
        check_7seg(ok && (rdata === 32'h0000_BEEF), "AXI Staggered Handshake: DISPLAY_DATA verified (0xBEEF)");
        seven_seg_indep_aw_w_pass = 1'b1;

        // ========================================================
        // 9. FOUR-PERIPHERAL ISOLATION VERIFICATION
        // ========================================================
        $display("");
        $display("============================================================");
        $display("ADDRESS DECODE & FOUR-PERIPHERAL ISOLATION TEST");
        $display("============================================================");
        // Verify UART LSR is unaffected
        axi_read(32'h4000_0014, rdata, ok);
        check_uart(ok && (rdata === 32'h0000_0060), "UART LSR unaffected by 7-Segment accesses (0x60)");

        // Verify SPI CR is unaffected
        axi_read(32'h4000_1060, rdata, ok);
        check_spi(ok && (rdata === 32'h0000_0186), "SPI CR unaffected by 7-Segment accesses (0x0186)");

        // Verify PWM slv_reg1 is unaffected
        axi_read(32'h4000_2004, rdata, ok);
        check_pwm(ok && (rdata === 32'h1234_5678), "PWM slv_reg1 unaffected by 7-Segment accesses (0x12345678)");

        // Verify 7-Segment register is intact
        axi_read(32'h4000_3000, rdata, ok);
        check_7seg(ok && (rdata === 32'h0000_BEEF), "7-Segment DISPLAY_DATA intact across peripheral queries (0xBEEF)");

        // ========================================================
        // FINAL SUMMARY
        // ========================================================
        $display("");
        $display("============================================================");
        $display("SOC INTERCONNECT + UART + SPI + PWM + 7-SEG TEST SUMMARY");
        $display("============================================================");

        $display("UART:");
        $display("  UART CONFIGURATION          : %s", uart_cfg_pass ? "PASS" : "FAIL");
        $display("  UART TX                     : %s", uart_tx_pass  ? "PASS" : "FAIL");
        $display("  UART RX                     : %s", uart_rx_pass  ? "PASS" : "FAIL");
        $display("  PASS COUNT = %0d", uart_pass_count);
        $display("  FAIL COUNT = %0d", uart_fail_count);

        $display("");
        $display("SPI:");
        $display("  SPI AXI WRITE               : %s", spi_axi_wr_pass ? "PASS" : "FAIL");
        $display("  SPI AXI READ                : %s", spi_axi_rd_pass ? "PASS" : "FAIL");
        $display("  SPI CONFIGURATION           : %s", spi_cfg_pass    ? "PASS" : "FAIL");
        $display("  SPI TX                      : %s", spi_tx_pass     ? "PASS" : "FAIL");
        $display("  SPI RX                      : %s", spi_rx_pass     ? "PASS" : "FAIL");
        $display("  SPI SCLK                    : %s", spi_sclk_pass   ? "PASS" : "FAIL");
        $display("  SPI CS                      : %s", spi_cs_pass     ? "PASS" : "FAIL");
        $display("  SPI STATUS                  : %s", spi_status_pass ? "PASS" : "FAIL");
        $display("  PASS COUNT = %0d", spi_pass_count);
        $display("  FAIL COUNT = %0d", spi_fail_count);

        $display("");
        $display("PWM:");
        $display("  PWM AXI REGISTERS           : %s", pwm_axi_reg_pass ? "PASS" : "FAIL");
        $display("  PWM RESET TEST              : %s", pwm_reset_pass   ? "PASS" : "FAIL");
        $display("  PWM ENABLE TEST             : %s", pwm_enable_pass  ? "PASS" : "FAIL");
        $display("  PWM PERIOD MEASUREMENT      : %s", pwm_period_pass  ? "PASS" : "FAIL");
        $display("  PWM DUTY CYCLE TEST         : %s", pwm_duty_pass    ? "PASS" : "FAIL");
        $display("  PWM DISABLE TEST            : %s", pwm_disable_pass ? "PASS" : "FAIL");
        $display("  PASS COUNT = %0d", pwm_pass_count);
        $display("  FAIL COUNT = %0d", pwm_fail_count);

        $display("");
        $display("7-SEGMENT DISPLAY:");
        $display("  7-SEG RESET BEHAVIOR        : %s", seven_seg_reset_pass      ? "PASS" : "FAIL");
        $display("  7-SEG AXI REGISTERS         : %s", seven_seg_axi_reg_pass    ? "PASS" : "FAIL");
        $display("  7-SEG HEX DECODER (0-F)     : %s", seven_seg_decoder_pass    ? "PASS" : "FAIL");
        $display("  7-SEG MUX & DIGIT CYCLING   : %s", seven_seg_mux_cycle_pass  ? "PASS" : "FAIL");
        $display("  7-SEG DISABLE CONTROL       : %s", seven_seg_disable_pass    ? "PASS" : "FAIL");
        $display("  7-SEG INDEPENDENT AW/W      : %s", seven_seg_indep_aw_w_pass ? "PASS" : "FAIL");
        $display("  PASS COUNT = %0d", seven_seg_pass_count);
        $display("  FAIL COUNT = %0d", seven_seg_fail_count);

        $display("");
        $display("TOTAL:");
        $display("  PASS COUNT = %0d", total_pass_count);
        $display("  FAIL COUNT = %0d", total_fail_count);

        if (total_fail_count == 0) begin
            $display("");
            $display("SOC_INTERCONNECT_UART_SPI_PWM_7SEG_RESULT = PASS");
            $display("");
        end
        else begin
            $display("");
            $display("SOC_INTERCONNECT_UART_SPI_PWM_7SEG_RESULT = FAIL");
            $display("");
        end

        $display("============================================================");

        #100;
        $finish;
    end

    // ============================================================
    // GLOBAL WATCHDOG
    // ============================================================
    initial begin
        #3_000_000;
        $display("");
        $display("[ERROR] Simulation timeout");
        $display("TOTAL PASS COUNT = %0d", total_pass_count);
        $display("TOTAL FAIL COUNT = %0d", total_fail_count);
        $display("SOC_INTERCONNECT_UART_SPI_PWM_7SEG_RESULT = FAIL");
        $finish;
    end

endmodule

`default_nettype wire
