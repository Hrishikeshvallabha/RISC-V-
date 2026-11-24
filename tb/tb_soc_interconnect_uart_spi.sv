`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Cumulative Testbench: AXI Interconnect + UART + SPI
// ============================================================================

module tb_soc_interconnect_uart_spi;

    // ============================================================
    // CLOCK / RESET
    // ============================================================
    reg clk;
    reg rst;

    localparam integer IC_ID_WIDTH = 8;
    localparam integer ADDR_WIDTH  = 32;
    localparam integer DATA_WIDTH  = 32;

    // ============================================================
    // GLOBAL TEST VARIABLES
    // ============================================================
    integer pass_count;
    integer fail_count;

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
    // DUT INSTANTIATION
    // ============================================================
    soc_interconnect_uart_spi_top dut (
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
        .spi_miso_i(spi_miso_i)
    );

    // ============================================================
    // CLOCK: 100 MHz (10 ns period)
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // CHECK TASK
    // ============================================================
    task automatic check;
        input condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s", message);
            end
            else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s", message);
            end
        end
    endtask

    // ============================================================
    // AXI WRITE TASK
    // AW and W handshakes handled independently with timeouts
    // ============================================================
    task automatic axi_write;
        input  [31:0] addr;
        input  [31:0] data;
        output        success;

        integer timeout;
        reg aw_done;
        reg w_done;

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
                fail_count = fail_count + 1;
                @(negedge clk);
                axi_awvalid = 1'b0;
                axi_wvalid  = 1'b0;
            end
            else begin
                $display("[AXI WRITE] AW handshake complete addr=0x%08h", addr);
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
                    fail_count = fail_count + 1;
                    @(negedge clk);
                    axi_wvalid = 1'b0;
                end
                else begin
                    $display("[AXI WRITE] W handshake complete data=0x%08h", data);
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
                        fail_count = fail_count + 1;
                    end
                    else begin
                        check(axi_bresp == 2'b00, "AXI write response OKAY");
                        if (axi_bresp == 2'b00) success = 1'b1;
                        $display("[AXI WRITE] COMPLETE addr=0x%08h", addr);
                    end
                end
            end
        end
    endtask

    // ============================================================
    // AXI READ TASK
    // AR handshake and R data channel with timeouts
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
                fail_count = fail_count + 1;
            end
            else begin
                $display("[AXI READ] AR handshake complete addr=0x%08h", addr);
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
                    fail_count = fail_count + 1;
                end
                else begin
                    data = axi_rdata;
                    check(axi_rresp == 2'b00, "AXI read response OKAY");
                    if (axi_rresp == 2'b00) success = 1'b1;
                    $display("[AXI READ] DATA=0x%08h", data);
                end
            end

            @(negedge clk);
            axi_arvalid = 1'b0;
        end
    endtask

    // ============================================================
    // UART TX TEST (Stage-1 verified behavior)
    // BAUD_DIV = 4 -> TX bit time = 50 ns
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

            // Write THR
            axi_write(32'h4000_0000, {24'h0, expected}, wr_ok);

            // Wait for start bit
            @(negedge uart_tx_o);

            // Center of start bit
            #25;

            for (i = 0; i < 10; i = i + 1) begin
                if (uart_tx_o === frame[i]) begin
                    $display("[TX BIT %0d] Expected=%b Actual=%b PASS", i, frame[i], uart_tx_o);
                end
                else begin
                    $display("[TX BIT %0d] Expected=%b Actual=%b FAIL", i, frame[i], uart_tx_o);
                    tx_fail_count = tx_fail_count + 1;
                end

                if ((i >= 1) && (i <= 8)) begin
                    actual[i-1] = uart_tx_o;
                end

                #50;
            end

            if ((tx_fail_count == 0) && (actual == expected)) begin
                pass_count = pass_count + 1;
                pass_out = 1'b1;
                $display("[TX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = PASS", expected, actual);
            end
            else begin
                fail_count = fail_count + 1;
                pass_out = 1'b0;
                $display("[TX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = FAIL", expected, actual);
            end
        end
    endtask

    // ============================================================
    // DRIVE UART RX (Stage-1 verified behavior)
    // Bit time = 40 ns
    // ============================================================
    task automatic drive_uart_rx;
        input [7:0] data;
        integer i;
        begin
            uart_rx_i = 1'b1;
            #100;
            // Start bit
            uart_rx_i = 1'b0;
            #40;
            // Data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i = data[i];
                #40;
            end
            // Stop bit
            uart_rx_i = 1'b1;
            #40;
        end
    endtask

    // ============================================================
    // UART RX TEST (Stage-1 verified behavior)
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

            check(lsr[0] === 1'b1, "UART DATA_READY reached through integration");

            // Read RBR
            axi_read(32'h4000_0000, actual, rd_ok);

            if (actual[7:0] === expected) begin
                pass_count = pass_count + 1;
                pass_out = 1'b1;
                $display("[RX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = PASS", expected, actual[7:0]);
            end
            else begin
                fail_count = fail_count + 1;
                pass_out = 1'b0;
                $display("[RX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = FAIL", expected, actual[7:0]);
            end

            check(actual[7:0] === expected, "RX byte matches expected through interconnect");
        end
    endtask

    // ============================================================
    // SPI FULL FUNCTIONAL TRANSFER TEST
    // Verified against SPI RTL (Mode 0: CPOL=0, CPHA=0, MSB first)
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

            // Step 1: Verify SCLK idle level is LOW (CPOL=0)
            sclk_initial_ok = (spi_clk_o === 1'b0);
            check(sclk_initial_ok, "SPI SCLK idle level is 0 (CPOL=0)");

            // Step 2: Assert Chip Select by writing 0x0 to SPI_SSR (0x4000_1070)
            axi_write(32'h4000_1070, 32'h0000_0000, ok);
            repeat (5) @(posedge clk);

            cs_active_ok = (spi_cs_n_o === 1'b0);
            check(cs_active_ok, "SPI CS asserted active-low (spi_cs_n_o == 0)");

            // Step 3: Run Master Write and Slave Stimulus concurrently
            fork
                // ----------------------------------------------------
                // Master Thread: Write TX byte to SPI_DTR (0x4000_1068)
                // ----------------------------------------------------
                begin
                    axi_write(32'h4000_1068, {24'h0, expected_tx}, ok);
                end

                // ----------------------------------------------------
                // Slave Thread: Sample MOSI on posedge, drive MISO on negedge
                // ----------------------------------------------------
                begin
                    integer bit_idx;
                    // Provide bit 7 before first posedge SCLK
                    spi_miso_i = slave_miso_byte[7];

                    for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                        // Wait for rising edge of SCLK with timeout
                        timeout = 0;
                        while (!spi_clk_o && (timeout < 2000)) begin
                            @(posedge clk);
                            timeout = timeout + 1;
                        end

                        if (timeout >= 2000) begin
                            $display("[ERROR] Timeout waiting for SPI clock edge %0d", bit_idx);
                            fail_count = fail_count + 1;
                        end
                        else begin
                            sclk_edges = sclk_edges + 1;
                            // Sample MOSI on rising edge (MSB first)
                            actual_tx_sampled[7 - bit_idx] = spi_mosi_o;
                            $display("[SPI SCLK %0d] posedge observed | MOSI bit=%b",
                                     bit_idx, spi_mosi_o);
                        end

                        // Wait for falling edge of SCLK with timeout
                        timeout = 0;
                        while (spi_clk_o && (timeout < 2000)) begin
                            @(posedge clk);
                            timeout = timeout + 1;
                        end

                        // Drive next MISO bit on falling edge
                        if (bit_idx < 7) begin
                            spi_miso_i = slave_miso_byte[6 - bit_idx];
                        end
                    end
                end
            join

            // Step 4: Verify SCLK edges count and final state
            repeat (20) @(posedge clk);
            sclk_final_ok = (spi_clk_o === 1'b0);
            check(sclk_edges == 8, "SPI SCLK produced exactly 8 clock cycles");
            check(sclk_final_ok, "SPI SCLK stopped and returned to 0");
            if ((sclk_edges == 8) && sclk_initial_ok && sclk_final_ok) begin
                spi_sclk_pass = 1'b1;
            end

            // Step 5: Verify TX Data
            if (actual_tx_sampled === expected_tx) begin
                pass_count = pass_count + 1;
                spi_tx_pass = 1'b1;
                $display("[SPI TX RESULT] Expected = 0x%02h | Reconstructed MOSI = 0x%02h | RESULT = PASS",
                         expected_tx, actual_tx_sampled);
            end
            else begin
                fail_count = fail_count + 1;
                spi_tx_pass = 1'b0;
                $display("[SPI TX RESULT] Expected = 0x%02h | Reconstructed MOSI = 0x%02h | RESULT = FAIL",
                         expected_tx, actual_tx_sampled);
            end

            // Step 6: Verify SPI Status Register (RX FIFO not empty, TX FIFO empty)
            axi_read(32'h4000_1064, sr_val, ok);
            $display("[SPI STATUS] Status register after exchange = 0x%08h", sr_val);
            // SR_RX_EMPTY_BIT is bit 0 (0 = not empty)
            // SR_TX_EMPTY_BIT is bit 2 (1 = empty)
            check((sr_val[0] === 1'b0) && (sr_val[2] === 1'b1),
                  "SPI SR reports RX FIFO not empty and TX FIFO empty");
            if ((sr_val[0] === 1'b0) && (sr_val[2] === 1'b1)) begin
                spi_status_pass = 1'b1;
            end

            // Step 7: Read received byte from SPI_DRR (0x4000_106C)
            axi_read(32'h4000_106C, actual_rx_read, ok);

            if (actual_rx_read[7:0] === slave_miso_byte) begin
                pass_count = pass_count + 1;
                spi_rx_pass = 1'b1;
                $display("[SPI RX RESULT] Expected = 0x%02h | AXI Read DRR = 0x%02h | RESULT = PASS",
                         slave_miso_byte, actual_rx_read[7:0]);
            end
            else begin
                fail_count = fail_count + 1;
                spi_rx_pass = 1'b0;
                $display("[SPI RX RESULT] Expected = 0x%02h | AXI Read DRR = 0x%02h | RESULT = FAIL",
                         slave_miso_byte, actual_rx_read[7:0]);
            end

            // Step 8: Deassert Chip Select by writing 0xFFFFFFFF to SPI_SSR
            axi_write(32'h4000_1070, 32'hFFFF_FFFF, ok);
            repeat (5) @(posedge clk);
            cs_inactive_ok = (spi_cs_n_o === 1'b1);
            check(cs_inactive_ok, "SPI CS returned inactive-high (spi_cs_n_o == 1)");
            if (cs_active_ok && cs_inactive_ok) begin
                spi_cs_pass = 1'b1;
            end

            if (spi_tx_pass && spi_rx_pass && spi_sclk_pass && spi_cs_pass && spi_status_pass) begin
                test_pass = 1'b1;
            end
        end
    endtask

    // ============================================================
    // ADDRESS DECODE / ISOLATION TEST
    // Verify SPI transactions do NOT hit UART, and UART do NOT hit SPI
    // ============================================================
    task automatic test_address_decode;
        output pass_out;

        reg [31:0] uart_lsr_before;
        reg [31:0] uart_lsr_after;
        reg [31:0] spi_ssr_before;
        reg [31:0] spi_ssr_after;
        reg ok;

        begin
            pass_out = 1'b0;
            $display("");
            $display("============================================================");
            $display("ADDRESS DECODE AND ISOLATION VERIFICATION");
            $display("============================================================");

            // Read UART LSR and SPI SSR
            axi_read(32'h4000_0014, uart_lsr_before, ok);
            axi_read(32'h4000_1070, spi_ssr_before, ok);

            $display("[ISOLATION] Initial UART LSR = 0x%08h | SPI SSR = 0x%08h",
                     uart_lsr_before, spi_ssr_before);

            // Write to SPI SSR
            axi_write(32'h4000_1070, 32'h0000_0000, ok);

            // Read back UART LSR to ensure untouched
            axi_read(32'h4000_0014, uart_lsr_after, ok);
            check(uart_lsr_after === uart_lsr_before,
                  "SPI write did not affect UART register space");

            // Write to UART IER
            axi_write(32'h4000_0004, 32'h0000_0001, ok);

            // Read back SPI SSR to ensure untouched
            axi_read(32'h4000_1070, spi_ssr_after, ok);
            check(spi_ssr_after === 32'h0000_0000,
                  "UART write did not affect SPI register space");

            // Restore SPI SSR
            axi_write(32'h4000_1070, 32'hFFFF_FFFF, ok);

            if ((uart_lsr_after === uart_lsr_before) &&
                (spi_ssr_after === 32'h0000_0000)) begin
                pass_out = 1'b1;
            end
        end
    endtask

    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================
    initial begin
        reg [31:0] rdata;
        reg ok;
        reg pass_tmp;

        // FSDB dump
        $fsdbDumpfile("soc_interconnect_uart_spi.fsdb");
        $fsdbDumpvars(0, tb_soc_interconnect_uart_spi);
        $fsdbDumpMDA();

        // Initial values
        clk = 1'b0;
        rst = 1'b1;

        pass_count = 0;
        fail_count = 0;

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
        addr_decode_pass = 1'b0;

        // AXI signals init
        axi_awid    = 8'h0;
        axi_awaddr  = 32'h0;
        axi_awlen   = 8'h0;
        axi_awsize  = 3'h0;
        axi_awburst = 2'h0;
        axi_awlock  = 1'b0;
        axi_awcache = 4'h0;
        axi_awprot  = 3'h0;
        axi_awqos   = 4'h0;
        axi_awvalid = 1'b0;

        axi_wdata   = 32'h0;
        axi_wstrb   = 4'h0;
        axi_wlast   = 1'b0;
        axi_wvalid  = 1'b0;
        axi_bready  = 1'b1;

        axi_arid    = 8'h0;
        axi_araddr  = 32'h0;
        axi_arlen   = 8'h0;
        axi_arsize  = 3'h0;
        axi_arburst = 2'h0;
        axi_arlock  = 1'b0;
        axi_arcache = 4'h0;
        axi_arprot  = 3'h0;
        axi_arqos   = 4'h0;
        axi_arvalid = 1'b0;
        axi_rready  = 1'b1;

        // Peripherals pin init
        uart_rx_i   = 1'b1;
        spi_miso_i  = 1'b1;

        // Reset sequence
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);

        // ========================================================
        // TEST 1: UART CONFIGURATION (Stage-1 verified sequence)
        // ========================================================
        $display("");
        $display("============================================================");
        $display("UART CONFIGURATION THROUGH AXI INTERCONNECT");
        $display("============================================================");

        // LCR: DLAB = 1
        axi_write(32'h4000_000C, 32'h0000_0080, ok);
        // BAUD_DIV = 4
        axi_write(32'h4000_0008, 32'd4, ok);
        // LCR: 8-N-1
        axi_write(32'h4000_000C, 32'h0000_0003, ok);
        // IER: RX interrupt enable
        axi_write(32'h4000_0004, 32'h0000_0001, ok);
        // Read initial UART status
        axi_read(32'h4000_0014, rdata, ok);
        $display("[UART STATUS] Initial LSR = 0x%08h", rdata);

        check(ok, "UART configuration completed successfully");
        if (ok) uart_cfg_pass = 1'b1;

        // ========================================================
        // TEST 2: UART TX TEST (Stage-1 verified)
        // ========================================================
        uart_tx_test(uart_tx_pass);

        // ========================================================
        // TEST 3: UART RX TEST (Stage-1 verified)
        // ========================================================
        uart_rx_test(uart_rx_pass);

        // ========================================================
        // TEST 4: SPI AXI READ / WRITE REGISTERS
        // ========================================================
        $display("");
        $display("============================================================");
        $display("SPI AXI REGISTER ACCESS TESTS");
        $display("============================================================");

        // Read SPI SR initial value (expected 0x0000_0005: RX_EMPTY=1, TX_EMPTY=1)
        axi_read(32'h4000_1064, rdata, ok);
        check((rdata === 32'h0000_0005) && ok, "SPI initial SR matches expected RTL reset status (0x00000005: RX_EMPTY=1, TX_EMPTY=1)");
        if (ok) spi_axi_rd_pass = 1'b1;

        // Read SPI CR initial value (expected 0x0000_0180)
        axi_read(32'h4000_1060, rdata, ok);
        check(rdata === 32'h0000_0180, "SPI initial CR matches expected (0x00000180)");

        // Read SPI SSR initial value (expected 0xFFFF_FFFF)
        axi_read(32'h4000_1070, rdata, ok);
        check(rdata === 32'hFFFF_FFFF, "SPI initial SSR matches expected (0xFFFFFFFF)");

        // Write SPI CR: enable master mode, enable SPI (bits 1, 2) -> 0x0000_0186
        axi_write(32'h4000_1060, 32'h0000_0186, ok);
        if (ok) spi_axi_wr_pass = 1'b1;

        // Readback SPI CR to verify configuration
        axi_read(32'h4000_1060, rdata, ok);
        check(rdata === 32'h0000_0186, "SPI CR readback matches configured value (0x00000186)");
        if (rdata === 32'h0000_0186) spi_cfg_pass = 1'b1;

        // ========================================================
        // TEST 5: ADDRESS DECODE AND ISOLATION
        // ========================================================
        test_address_decode(addr_decode_pass);
        check(addr_decode_pass, "Address decode & peripheral isolation verified");

        // ========================================================
        // TEST 6: SPI FUNCTIONAL TRANSFER 1 (TX = 0x5A, RX = 0xA5)
        // ========================================================
        spi_functional_transfer_test(8'h5A, 8'hA5, pass_tmp);

        // ========================================================
        // TEST 7: SPI FUNCTIONAL TRANSFER 2 (TX = 0xC3, RX = 0x3C)
        // ========================================================
        spi_functional_transfer_test(8'hC3, 8'h3C, pass_tmp);

        // ========================================================
        // FINAL SUMMARY
        // ========================================================
        $display("");
        $display("============================================================");
        $display("UART TEST");
        $display("============================================================");
        $display("UART CONFIGURATION       : %s", uart_cfg_pass ? "PASS" : "FAIL");
        $display("UART TX                  : %s", uart_tx_pass  ? "PASS" : "FAIL");
        $display("UART RX                  : %s", uart_rx_pass  ? "PASS" : "FAIL");

        $display("");
        $display("============================================================");
        $display("SPI TEST");
        $display("============================================================");
        $display("SPI AXI WRITE            : %s", spi_axi_wr_pass ? "PASS" : "FAIL");
        $display("SPI AXI READ             : %s", spi_axi_rd_pass ? "PASS" : "FAIL");
        $display("SPI CONFIGURATION        : %s", spi_cfg_pass    ? "PASS" : "FAIL");
        $display("SPI TX                   : %s", spi_tx_pass     ? "PASS" : "FAIL");
        $display("SPI RX                   : %s", spi_rx_pass     ? "PASS" : "FAIL");
        $display("SPI SCLK                 : %s", spi_sclk_pass   ? "PASS" : "FAIL");
        $display("SPI CS                   : %s", spi_cs_pass     ? "PASS" : "FAIL");
        $display("SPI STATUS               : %s", spi_status_pass ? "PASS" : "FAIL");

        $display("");
        $display("============================================================");
        $display("FINAL SUMMARY");
        $display("============================================================");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);

        if (fail_count == 0) begin
            $display("");
            $display("SOC_INTERCONNECT_UART_SPI_RESULT = PASS");
            $display("");
        end
        else begin
            $display("");
            $display("SOC_INTERCONNECT_UART_SPI_RESULT = FAIL");
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
        #2_000_000;
        $display("");
        $display("[ERROR] Simulation timeout");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("SOC_INTERCONNECT_UART_SPI_RESULT = FAIL");
        $finish;
    end

endmodule

`default_nettype wire
