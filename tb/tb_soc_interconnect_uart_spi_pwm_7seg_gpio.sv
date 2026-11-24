`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Cumulative Testbench: AXI Interconnect + UART + SPI + PWM + 7-SEG + GPIO
// ============================================================================

module tb_soc_interconnect_uart_spi_pwm_7seg_gpio;

    // ============================================================
    // CLOCK / RESET
    // ============================================================
    reg clk;
    reg rst;

    localparam integer IC_ID_WIDTH          = 8;
    localparam integer ADDR_WIDTH           = 32;
    localparam integer DATA_WIDTH           = 32;
    localparam integer SEVEN_SEG_REFRESH_DIV = 100;
    localparam integer GPIO_NUM_BITS        = 32;

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

    integer gpio_pass_count;
    integer gpio_fail_count;

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

    reg gpio_reset_pass;
    reg gpio_reg_rw_pass;
    reg gpio_out_pass;
    reg gpio_in_pass;
    reg gpio_dir_pass;
    reg gpio_atomic_pass;
    reg gpio_intr_pass;
    reg gpio_indep_aw_w_pass;
    reg reserved_buffer_pass;
    reg five_periph_isolation_pass;

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
    // GPIO SIGNALS
    // ============================================================
    wire [GPIO_NUM_BITS-1:0] gpio_io;
    wire                     gpio_intr_o;

    // Testbench GPIO bidirectional control
    reg [GPIO_NUM_BITS-1:0]  gpio_tb_drive_val;
    reg [GPIO_NUM_BITS-1:0]  gpio_tb_drive_en;

    genvar gi;
    generate
        for (gi = 0; gi < GPIO_NUM_BITS; gi = gi + 1) begin : gen_gpio_tri
            assign gpio_io[gi] = gpio_tb_drive_en[gi] ? gpio_tb_drive_val[gi] : 1'bz;
        end
    endgenerate

    // ============================================================
    // DUT INSTANTIATION
    // ============================================================
    soc_interconnect_uart_spi_pwm_7seg_gpio_top #(
        .DATA_WIDTH             (DATA_WIDTH),
        .ADDR_WIDTH             (ADDR_WIDTH),
        .IC_ID_WIDTH            (IC_ID_WIDTH),
        .SEVEN_SEG_REFRESH_DIV  (SEVEN_SEG_REFRESH_DIV),
        .GPIO_NUM_BITS          (GPIO_NUM_BITS)
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
        .an(an),

        // GPIO
        .gpio_io(gpio_io),
        .gpio_intr_o(gpio_intr_o)
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
                $display("[PASS] [UART] %0s", message);
            end else begin
                uart_fail_count = uart_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[FAIL] [UART] %0s", message);
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
                $display("[PASS] [SPI] %0s", message);
            end else begin
                spi_fail_count = spi_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[FAIL] [SPI] %0s", message);
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
                $display("[PASS] [PWM] %0s", message);
            end else begin
                pwm_fail_count = pwm_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[FAIL] [PWM] %0s", message);
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
                $display("[PASS] [7-SEG] %0s", message);
            end else begin
                seven_seg_fail_count = seven_seg_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[FAIL] [7-SEG] %0s", message);
            end
        end
    endtask

    task automatic check_gpio;
        input condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                gpio_pass_count = gpio_pass_count + 1;
                total_pass_count = total_pass_count + 1;
                $display("[PASS] [GPIO] %0s", message);
            end else begin
                gpio_fail_count = gpio_fail_count + 1;
                total_fail_count = total_fail_count + 1;
                $display("[FAIL] [GPIO] %0s", message);
            end
        end
    endtask

    // ============================================================
    // AXI BUS TASKS
    // ============================================================
    task automatic axi_write;
        input  [31:0] addr;
        input  [31:0] data;
        output        success;

        integer timeout;

        begin
            success = 1'b0;
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

    task automatic axi_write_expect_resp;
        input  [31:0] addr;
        input  [31:0] data;
        input  [1:0]  expected_bresp;
        output        success;

        integer timeout;

        begin
            success = 1'b0;
            @(negedge clk);
            axi_awid    = 8'h02;
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
                        if (axi_bresp === expected_bresp) success = 1'b1;
                        $display("[AXI WRITE EXPECT] COMPLETE addr=0x%08h RESP=%b (expected %b)", addr, axi_bresp, expected_bresp);
                    end
                end
            end
        end
    endtask

    // Staggered: AW before W
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
            axi_wvalid  = 1'b0;
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

            repeat (4) @(posedge clk);

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

            timeout = 0;
            while (!axi_bvalid && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Staggered B timeout addr=0x%08h", addr);
                total_fail_count = total_fail_count + 1;
                return;
            end

            if (axi_bresp == 2'b00) success = 1'b1;
            $display("[AXI WRITE STAGGERED AW-then-W] COMPLETE addr=0x%08h RESP=%0d", addr, axi_bresp);
        end
    endtask

    // Staggered: W before AW
    task automatic axi_write_w_before_aw;
        input  [31:0] addr;
        input  [31:0] data;
        output        success;

        integer timeout;

        begin
            success = 1'b0;
            $display("");
            $display("[AXI WRITE STAGGERED (W asserted before AW)] ADDR=0x%08h DATA=0x%08h", addr, data);

            @(negedge clk);
            axi_wdata   = data;
            axi_wstrb   = 4'hF;
            axi_wlast   = 1'b1;
            axi_wvalid  = 1'b1;
            axi_awvalid = 1'b0;
            axi_bready  = 1'b1;

            // Wait 3 clock cycles with W asserted while AW is kept deasserted
            repeat (3) @(posedge clk);

            // Now assert AW channel
            @(negedge clk);
            axi_awid    = 8'h06;
            axi_awaddr  = addr;
            axi_awlen   = 8'd0;
            axi_awsize  = 3'd2;
            axi_awburst = 2'b01;
            axi_awlock  = 1'b0;
            axi_awcache = 4'h0;
            axi_awprot  = 3'h0;
            axi_awqos   = 4'h0;
            axi_awvalid = 1'b1;

            timeout = 0;
            while (!(axi_awvalid && axi_awready) && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Timeout waiting for AWREADY addr=0x%08h", addr);
                total_fail_count = total_fail_count + 1;
                @(negedge clk);
                axi_awvalid = 1'b0;
                axi_wvalid  = 1'b0;
                return;
            end

            @(negedge clk);
            axi_awvalid = 1'b0;

            // Wait for W handshake if not already done
            timeout = 0;
            while (!(axi_wvalid && axi_wready) && timeout < 200) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 200) begin
                $display("[ERROR] Timeout waiting for WREADY addr=0x%08h", addr);
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
                $display("[ERROR] Timeout waiting for BVALID addr=0x%08h", addr);
                total_fail_count = total_fail_count + 1;
                return;
            end

            if (axi_bresp == 2'b00) success = 1'b1;
            $display("[AXI WRITE STAGGERED W-before-AW] COMPLETE addr=0x%08h RESP=%0d", addr, axi_bresp);
        end
    endtask

    task automatic axi_read;
        input  [31:0] addr;
        output [31:0] data;
        output        success;

        integer timeout;

        begin
            data    = 32'h0;
            success = 1'b0;

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
                total_fail_count = total_fail_count + 1;
                @(negedge clk);
                axi_arvalid = 1'b0;
            end
            else begin
                @(negedge clk);
                axi_arvalid = 1'b0;

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
                    $display("[AXI READ] COMPLETE addr=0x%08h DATA=0x%08h RESP=%0d", addr, data, axi_rresp);
                end
            end
        end
    endtask

    task automatic axi_read_expect_resp;
        input  [31:0] addr;
        output [31:0] data;
        input  [1:0]  expected_rresp;
        output        success;

        integer timeout;

        begin
            data    = 32'h0;
            success = 1'b0;

            @(negedge clk);
            axi_arid    = 8'h03;
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
                total_fail_count = total_fail_count + 1;
                @(negedge clk);
                axi_arvalid = 1'b0;
            end
            else begin
                @(negedge clk);
                axi_arvalid = 1'b0;

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
                    if (axi_rresp === expected_rresp) success = 1'b1;
                    $display("[AXI READ EXPECT] COMPLETE addr=0x%08h DATA=0x%08h RESP=%b (expected %b)", addr, data, axi_rresp, expected_rresp);
                end
            end
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
        input  [7:0]  duty_val;
        input  [8*30-1:0] label;
        output        pass_flag;

        reg ok;
        time t_rise, t_fall, t_next_rise;
        real high_time_ns, low_time_ns, total_period_ns, measured_duty_pct;
        real expected_duty_pct;
        real duty_error;
        real period_error;

        begin
            pass_flag = 1'b0;
            expected_duty_pct = (real'(duty_val) / 256.0) * 100.0;

            $display("");
            $display("------------------------------------------------------------");
            $display("MEASURING PWM: %0s (duty = %0d/256 = %0.2f%%)", label, duty_val, expected_duty_pct);
            $display("------------------------------------------------------------");

            axi_write(32'h4000_2000, {23'd0, 1'b1, duty_val}, ok);
            check_pwm(ok, "PWM control register written (enable=1, duty set)");

            #500;

            @(posedge pwm_out_o);
            t_rise = $realtime;

            @(negedge pwm_out_o);
            t_fall = $realtime;

            @(posedge pwm_out_o);
            t_next_rise = $realtime;

            high_time_ns    = t_fall - t_rise;
            low_time_ns     = t_next_rise - t_fall;
            total_period_ns = t_next_rise - t_rise;
            measured_duty_pct = (high_time_ns / total_period_ns) * 100.0;

            duty_error   = measured_duty_pct - expected_duty_pct;
            if (duty_error < 0) duty_error = -duty_error;

            period_error = total_period_ns - 2560.0;
            if (period_error < 0) period_error = -period_error;

            $display("[PWM MEASUREMENT] High Time  = %0.2f ns", high_time_ns);
            $display("[PWM MEASUREMENT] Low Time   = %0.2f ns", low_time_ns);
            $display("[PWM MEASUREMENT] Period     = %0.2f ns (Expected: 2560.00 ns)", total_period_ns);
            $display("[PWM MEASUREMENT] Measured Duty = %0.2f %% (Expected: %0.2f %%)", measured_duty_pct, expected_duty_pct);

            if (period_error <= 20.0 && duty_error <= 1.5) begin
                pass_flag = 1'b1;
                check_pwm(1'b1, "PWM period and duty cycle match expected within tolerance");
            end else begin
                pass_flag = 1'b0;
                check_pwm(1'b0, "PWM waveform error outside acceptable limits");
            end
        end
    endtask

    // ============================================================
    // 7-SEGMENT EXPECTED SEGMENT FUNCTION (Active-low, Stage-4 verified)
    // ============================================================
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
        reg walking_pass;
        reg [31:0] walk_pat;
        reg aw_before_w_pass;
        reg w_before_aw_pass;
        reg simultaneous_pass;
        reg intr_before;
        reg intr_active;
        reg intr_after;
        integer i;

        // FSDB dump
        $fsdbDumpfile("soc_interconnect_uart_spi_pwm_7seg_gpio.fsdb");
        $fsdbDumpvars(0, tb_soc_interconnect_uart_spi_pwm_7seg_gpio);
        $fsdbDumpMDA();

        // Initial values
        clk = 1'b0;
        rst = 1'b1;

        uart_pass_count      = 0; uart_fail_count      = 0;
        spi_pass_count       = 0; spi_fail_count       = 0;
        pwm_pass_count       = 0; pwm_fail_count       = 0;
        seven_seg_pass_count = 0; seven_seg_fail_count = 0;
        gpio_pass_count      = 0; gpio_fail_count      = 0;
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

        gpio_reset_pass            = 1'b0;
        gpio_reg_rw_pass           = 1'b0;
        gpio_out_pass              = 1'b0;
        gpio_in_pass               = 1'b0;
        gpio_dir_pass              = 1'b0;
        gpio_atomic_pass           = 1'b0;
        gpio_intr_pass             = 1'b0;
        gpio_indep_aw_w_pass       = 1'b0;
        reserved_buffer_pass       = 1'b0;
        five_periph_isolation_pass = 1'b0;

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

        uart_rx_i         = 1'b1;
        spi_miso_i        = 1'b1;
        gpio_tb_drive_val = 32'h0;
        gpio_tb_drive_en  = 32'h0;

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
        $display("ADDRESS DECODE & PERIPHERAL ISOLATION");
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
        $display("");
        $display("--- 8.3 Hexadecimal Decoder & Multiplexing Verification ---");
        @(posedge clk);
        while (an !== 4'b1110) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h0), "7SEG Decoder: Digit 0 value 0 decoded correctly");

        while (an !== 4'b1101) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h5), "7SEG Decoder: Digit 1 value 5 decoded correctly");

        while (an !== 4'b1011) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'hA), "7SEG Decoder: Digit 2 value A decoded correctly");

        while (an !== 4'b0111) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'hF), "7SEG Decoder: Digit 3 value F decoded correctly");

        // Test digits 1 and 9
        axi_write(32'h4000_3000, 32'h0000_9191, ok);
        while (an !== 4'b1110) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h1), "7SEG Decoder: Digit 0 value 1 decoded correctly");

        while (an !== 4'b1101) @(posedge clk);
        #1;
        check_7seg(seg === get_expected_seg(4'h9), "7SEG Decoder: Digit 1 value 9 decoded correctly");
        seven_seg_decoder_pass = 1'b1;

        // 8.4 Multiplexing Sequence Verification
        $display("");
        $display("--- 8.4 Multiplexing Sequence Verification ---");
        while (an !== 4'b1110) @(posedge clk);
        while (an !== 4'b1101) @(posedge clk);
        while (an !== 4'b1011) @(posedge clk);
        while (an !== 4'b0111) @(posedge clk);
        while (an !== 4'b1110) @(posedge clk);
        check_7seg(1'b1, "7SEG Multiplexing: Full 4-digit round-robin cycle verified");
        seven_seg_mux_cycle_pass = 1'b1;

        // 8.5 Display Disable Verification
        $display("");
        $display("--- 8.5 Display Disable Verification ---");
        axi_write(32'h4000_3004, 32'h0000_0000, ok);
        @(posedge clk);
        #1;
        check_7seg(an === 4'b1111, "7SEG Disable: All digit enables immediately disabled (an = 4'b1111)");
        check_7seg(seg === 7'b111_1111, "7SEG Disable: All segment outputs blanked (seg = 7'b1111111)");
        axi_read (32'h4000_3008, rdata, ok);
        check_7seg(ok && (rdata[0] === 1'b0), "7SEG Disable: STATUS reports disabled (0)");
        seven_seg_disable_pass = 1'b1;

        // 8.6 Independent AW and W Handshake (7-Segment)
        $display("");
        $display("--- 8.6 Independent AW and W Channel Handshake (7-SEG) ---");
        axi_write_staggered(32'h4000_3000, 32'h0000_BEEF, ok);
        check_7seg(ok, "7SEG AXI Staggered Handshake: AW completed before W asserted");
        axi_read(32'h4000_3000, rdata, ok);
        check_7seg(ok && (rdata === 32'h0000_BEEF), "7SEG AXI Staggered Handshake: DISPLAY_DATA verified (0xBEEF)");
        seven_seg_indep_aw_w_pass = 1'b1;

        // ========================================================
        // 9. GPIO IP COMPLETE VERIFICATION
        // ========================================================
        $display("");
        $display("============================================================");
        $display("GPIO IP VERIFICATION (Base Address: 0x4000_5000)");
        $display("============================================================");

        // 9.1 GPIO Reset State
        $display("");
        $display("--- 9.1 GPIO Reset State Verification ---");
        // Verify High-Z (tri-state, DIR=0) on external pins before TB drives
        check_gpio(gpio_io === 32'hzzzz_zzzz, "GPIO reset: External pins are High-Z (tri-state, DIR=0)");
        check_gpio(gpio_intr_o === 1'b0, "GPIO reset: Interrupt line is deasserted (0)");

        axi_read(32'h4000_5004, rdata, ok); // DATA_O
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO reset: DATA_O register reads 0x00000000");

        axi_read(32'h4000_5008, rdata, ok); // DIR
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO reset: DIR register reads 0x00000000 (all inputs)");

        axi_read(32'h4000_500C, rdata, ok); // INT_EN
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO reset: INT_EN register reads 0x00000000 (disabled)");

        axi_read(32'h4000_5010, rdata, ok); // INT_TYP
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO reset: INT_TYP register reads 0x00000000");

        axi_read(32'h4000_5014, rdata, ok); // INT_POL
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO reset: INT_POL register reads 0x00000000");

        axi_read(32'h4000_5018, rdata, ok); // INT_ANY
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO reset: INT_ANY register reads 0x00000000");

        // Drive external inputs with 0 to flush input synchronizer
        gpio_tb_drive_val = 32'h0000_0000;
        gpio_tb_drive_en  = 32'hFFFF_FFFF;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok); // DATA_I
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO reset: DATA_I register reads 0x00000000 with inputs driven 0");
        gpio_tb_drive_en  = 32'h0000_0000; // Release TB drive

        $display("");
        $display("[GPIO RESET TEST]");
        $display("Expected = 0x00000000");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = PASS");
        gpio_reset_pass = 1'b1;

        // 9.2 GPIO Register Read/Write Verification
        $display("");
        $display("--- 9.2 GPIO Register Read/Write Verification ---");
        axi_write(32'h4000_5004, 32'hA5A5_5A5A, ok);
        axi_read (32'h4000_5004, rdata, ok);
        check_gpio(ok && (rdata === 32'hA5A5_5A5A), "GPIO R/W: DATA_O readback matches (0xA5A55A5A)");
        $display("[GPIO REGISTER WRITE]");
        $display("Register = DATA_O (0x40005004)");
        $display("Expected = 0xA5A55A5A");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'hA5A5_5A5A) ? "PASS" : "FAIL");

        axi_write(32'h4000_5008, 32'h1234_5678, ok);
        axi_read (32'h4000_5008, rdata, ok);
        check_gpio(ok && (rdata === 32'h1234_5678), "GPIO R/W: DIR readback matches (0x12345678)");
        $display("[GPIO REGISTER WRITE]");
        $display("Register = DIR (0x40005008)");
        $display("Expected = 0x12345678");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h1234_5678) ? "PASS" : "FAIL");

        axi_write(32'h4000_500C, 32'hDEAD_BEEF, ok);
        axi_read (32'h4000_500C, rdata, ok);
        check_gpio(ok && (rdata === 32'hDEAD_BEEF), "GPIO R/W: INT_EN readback matches (0xDEADBEEF)");
        $display("[GPIO REGISTER WRITE]");
        $display("Register = INT_EN (0x4000500C)");
        $display("Expected = 0xDEADBEEF");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'hDEAD_BEEF) ? "PASS" : "FAIL");

        axi_write(32'h4000_5010, 32'hCAFE_BABE, ok);
        axi_read (32'h4000_5010, rdata, ok);
        check_gpio(ok && (rdata === 32'hCAFE_BABE), "GPIO R/W: INT_TYP readback matches (0xCAFEBABE)");
        $display("[GPIO REGISTER WRITE]");
        $display("Register = INT_TYP (0x40005010)");
        $display("Expected = 0xCAFEBABE");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'hCAFE_BABE) ? "PASS" : "FAIL");

        axi_write(32'h4000_5014, 32'h5555_AAAA, ok);
        axi_read (32'h4000_5014, rdata, ok);
        check_gpio(ok && (rdata === 32'h5555_AAAA), "GPIO R/W: INT_POL readback matches (0x5555AAAA)");
        $display("[GPIO REGISTER WRITE]");
        $display("Register = INT_POL (0x40005014)");
        $display("Expected = 0x5555AAAA");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h5555_AAAA) ? "PASS" : "FAIL");

        axi_write(32'h4000_5018, 32'h3333_CCCC, ok);
        axi_read (32'h4000_5018, rdata, ok);
        check_gpio(ok && (rdata === 32'h3333_CCCC), "GPIO R/W: INT_ANY readback matches (0x3333CCCC)");
        $display("[GPIO REGISTER WRITE]");
        $display("Register = INT_ANY (0x40005018)");
        $display("Expected = 0x3333CCCC");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h3333_CCCC) ? "PASS" : "FAIL");

        // Restore clean control registers
        axi_write(32'h4000_500C, 32'h0000_0000, ok);
        axi_write(32'h4000_5010, 32'h0000_0000, ok);
        axi_write(32'h4000_5014, 32'h0000_0000, ok);
        axi_write(32'h4000_5018, 32'h0000_0000, ok);
        gpio_reg_rw_pass = 1'b1;

        // 9.3 GPIO Output Drive & Patterns Verification
        $display("");
        $display("--- 9.3 GPIO Output Drive & Patterns Verification ---");
        // Set DIR = all 1s (all outputs)
        axi_write(32'h4000_5008, 32'hFFFF_FFFF, ok);
        gpio_tb_drive_en = 32'h0000_0000; // TB does not drive

        // All zero pattern
        axi_write(32'h4000_5004, 32'h0000_0000, ok);
        #20;
        check_gpio(gpio_io === 32'h0000_0000, "GPIO Output: Pattern 0x00000000 verified on pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = 0x00000000");
        $display("Expected = 0x00000000");
        $display("Actual   = 0x%08h", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'h0000_0000) ? "PASS" : "FAIL");

        // All one pattern
        axi_write(32'h4000_5004, 32'hFFFF_FFFF, ok);
        #20;
        check_gpio(gpio_io === 32'hFFFF_FFFF, "GPIO Output: Pattern 0xFFFFFFFF verified on pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = 0xFFFFFFFF");
        $display("Expected = 0xFFFFFFFF");
        $display("Actual   = 0x%08h", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'hFFFF_FFFF) ? "PASS" : "FAIL");

        // Alternating pattern 0x55555555
        axi_write(32'h4000_5004, 32'h5555_5555, ok);
        #20;
        check_gpio(gpio_io === 32'h5555_5555, "GPIO Output: Alternating pattern 0x55555555 verified on pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = 0x55555555");
        $display("Expected = 0x55555555");
        $display("Actual   = 0x%08h", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'h5555_5555) ? "PASS" : "FAIL");

        // Alternating pattern 0xAAAAAAAA
        axi_write(32'h4000_5004, 32'hAAAA_AAAA, ok);
        #20;
        check_gpio(gpio_io === 32'hAAAA_AAAA, "GPIO Output: Alternating pattern 0xAAAAAAAA verified on pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = 0xAAAAAAAA");
        $display("Expected = 0xAAAAAAAA");
        $display("Actual   = 0x%08h", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'hAAAA_AAAA) ? "PASS" : "FAIL");

        // Checkerboard pattern 0xA5A5A5A5
        axi_write(32'h4000_5004, 32'hA5A5_A5A5, ok);
        #20;
        check_gpio(gpio_io === 32'hA5A5_A5A5, "GPIO Output: Checkerboard pattern 0xA5A5A5A5 verified on pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = 0xA5A5A5A5");
        $display("Expected = 0xA5A5A5A5");
        $display("Actual   = 0x%08h", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'hA5A5_A5A5) ? "PASS" : "FAIL");

        // Checkerboard pattern 0x5A5A5A5A
        axi_write(32'h4000_5004, 32'h5A5A_5A5A, ok);
        #20;
        check_gpio(gpio_io === 32'h5A5A_5A5A, "GPIO Output: Checkerboard pattern 0x5A5A5A5A verified on pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = 0x5A5A5A5A");
        $display("Expected = 0x5A5A5A5A");
        $display("Actual   = 0x%08h", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'h5A5A_5A5A) ? "PASS" : "FAIL");

        // Walking 1s test across all 32 pins
        walking_pass = 1'b1;
        for (i = 0; i < 32; i = i + 1) begin
            walk_pat = (32'h0000_0001 << i);
            axi_write(32'h4000_5004, walk_pat, ok);
            #20;
            if (gpio_io !== walk_pat) begin
                $display("[FAIL] [GPIO] Walking 1 mismatch at bit %0d: Expected=0x%08h, Actual=0x%08h", i, walk_pat, gpio_io);
                walking_pass = 1'b0;
            end
        end
        check_gpio(walking_pass, "GPIO Output: 32-bit Walking 1s pattern verified on all pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = Walking 1s (0..31)");
        $display("Expected = Walking 1s (all 32 pins)");
        $display("Actual   = Walking 1s verified");
        $display("RESULT   = %s", walking_pass ? "PASS" : "FAIL");

        // Walking 0s test across all 32 pins
        walking_pass = 1'b1;
        for (i = 0; i < 32; i = i + 1) begin
            walk_pat = ~(32'h0000_0001 << i);
            axi_write(32'h4000_5004, walk_pat, ok);
            #20;
            if (gpio_io !== walk_pat) begin
                $display("[FAIL] [GPIO] Walking 0 mismatch at bit %0d: Expected=0x%08h, Actual=0x%08h", i, walk_pat, gpio_io);
                walking_pass = 1'b0;
            end
        end
        check_gpio(walking_pass, "GPIO Output: 32-bit Walking 0s pattern verified on all pins");
        $display("[GPIO OUTPUT TEST]");
        $display("Pattern  = Walking 0s (0..31)");
        $display("Expected = Walking 0s (all 32 pins)");
        $display("Actual   = Walking 0s verified");
        $display("RESULT   = %s", walking_pass ? "PASS" : "FAIL");
        gpio_out_pass = 1'b1;

        // 9.4 GPIO Atomic Operations (SET_O, CLR_O, TGL_O)
        $display("");
        $display("--- 9.4 GPIO Atomic Operations (SET_O, CLR_O, TGL_O) ---");
        axi_write(32'h4000_5004, 32'h0000_0000, ok);
        #20;
        check_gpio(gpio_io === 32'h0000_0000, "GPIO Atomic init: DATA_O = 0x00000000");

        // SET_O: Set bits [3:0]
        axi_write(32'h4000_5020, 32'h0000_000F, ok);
        #20;
        check_gpio(gpio_io === 32'h0000_000F, "GPIO SET_O: Bits [3:0] asserted (0x0000000F)");

        // CLR_O: Clear bits [1:0]
        axi_write(32'h4000_5024, 32'h0000_0003, ok);
        #20;
        check_gpio(gpio_io === 32'h0000_000C, "GPIO CLR_O: Bits [1:0] cleared, [3:2] remain (0x0000000C)");

        // TGL_O: Toggle bits [2:0] (0xC ^ 0x5 = 0x9)
        axi_write(32'h4000_5028, 32'h0000_0005, ok);
        #20;
        check_gpio(gpio_io === 32'h0000_0009, "GPIO TGL_O: Bits toggled with mask 0x5 (0x00000009)");
        gpio_atomic_pass = 1'b1;

        // 9.5 GPIO Input Functional Test
        $display("");
        $display("--- 9.5 GPIO Input Functional Test ---");
        // Set DIR = all 0s (all inputs)
        axi_write(32'h4000_5008, 32'h0000_0000, ok);
        #20;
        check_gpio(gpio_io === 32'hzzzz_zzzz, "GPIO Tristate: Pins return to High-Z when DIR=0");

        // Drive pattern 0x00000000
        gpio_tb_drive_val = 32'h0000_0000;
        gpio_tb_drive_en  = 32'hFFFF_FFFF;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok);
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO Input: Read DATA_I matched driven pattern 0x00000000");
        $display("[GPIO INPUT TEST]");
        $display("Expected = 0x00000000");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h0000_0000) ? "PASS" : "FAIL");

        // Drive pattern 0xFFFFFFFF
        gpio_tb_drive_val = 32'hFFFF_FFFF;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok);
        check_gpio(ok && (rdata === 32'hFFFF_FFFF), "GPIO Input: Read DATA_I matched driven pattern 0xFFFFFFFF");
        $display("[GPIO INPUT TEST]");
        $display("Expected = 0xFFFFFFFF");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'hFFFF_FFFF) ? "PASS" : "FAIL");

        // Drive pattern 0xA5A5A5A5
        gpio_tb_drive_val = 32'hA5A5_A5A5;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok);
        check_gpio(ok && (rdata === 32'hA5A5_A5A5), "GPIO Input: Read DATA_I matched driven pattern 0xA5A5A5A5");
        $display("[GPIO INPUT TEST]");
        $display("Expected = 0xA5A5A5A5");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'hA5A5_A5A5) ? "PASS" : "FAIL");

        // Drive pattern 0x5A5A5A5A
        gpio_tb_drive_val = 32'h5A5A_5A5A;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok);
        check_gpio(ok && (rdata === 32'h5A5A_5A5A), "GPIO Input: Read DATA_I matched driven pattern 0x5A5A5A5A");
        $display("[GPIO INPUT TEST]");
        $display("Expected = 0x5A5A5A5A");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h5A5A_5A5A) ? "PASS" : "FAIL");

        // Drive pattern 0x12345678
        gpio_tb_drive_val = 32'h1234_5678;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok);
        check_gpio(ok && (rdata === 32'h1234_5678), "GPIO Input: Read DATA_I matched driven pattern 0x12345678");
        $display("[GPIO INPUT TEST]");
        $display("Expected = 0x12345678");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h1234_5678) ? "PASS" : "FAIL");

        // Drive pattern 0x87654321
        gpio_tb_drive_val = 32'h8765_4321;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok);
        check_gpio(ok && (rdata === 32'h8765_4321), "GPIO Input: Read DATA_I matched driven pattern 0x87654321");
        $display("[GPIO INPUT TEST]");
        $display("Expected = 0x87654321");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h8765_4321) ? "PASS" : "FAIL");

        // Release TB drive
        gpio_tb_drive_en  = 32'h0000_0000;
        gpio_in_pass      = 1'b1;

        // 9.6 GPIO Direction Test
        $display("");
        $display("--- 9.6 GPIO Direction Test ---");
        // Output mode
        axi_write(32'h4000_5008, 32'hFFFF_FFFF, ok); // DIR = OUTPUT
        axi_write(32'h4000_5004, 32'hDEAD_BEEF, ok); // DATA_O
        gpio_tb_drive_en = 32'h0000_0000;
        #20;
        check_gpio(gpio_io === 32'hDEAD_BEEF, "GPIO Direction: OUTPUT mode actively driving pins (0xDEADBEEF)");
        $display("[GPIO DIRECTION TEST]");
        $display("Mode     = OUTPUT");
        $display("Expected = 0xDEADBEEF");
        $display("Actual   = 0x%08h", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'hDEAD_BEEF) ? "PASS" : "FAIL");

        // Input mode
        axi_write(32'h4000_5008, 32'h0000_0000, ok); // DIR = INPUT
        gpio_tb_drive_val = 32'hBEEF_CAFE;
        gpio_tb_drive_en  = 32'hFFFF_FFFF;
        repeat (4) @(posedge clk);
        axi_read(32'h4000_5000, rdata, ok); // DATA_I
        check_gpio(ok && (rdata === 32'hBEEF_CAFE), "GPIO Direction: INPUT mode accurately sampling pins (0xBEEFCAFE)");
        $display("[GPIO DIRECTION TEST]");
        $display("Mode     = INPUT");
        $display("Expected = 0xBEEFCAFE");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'hBEEF_CAFE) ? "PASS" : "FAIL");

        // Tristate High-Z mode
        gpio_tb_drive_en = 32'h0000_0000;
        #20;
        check_gpio(gpio_io === 32'hzzzz_zzzz, "GPIO Direction: High-Z verified on external pins when DIR=0");
        $display("[GPIO DIRECTION TEST]");
        $display("Mode     = TRISTATE (DIR=0)");
        $display("Expected = 32'hzzzzzzzz");
        $display("Actual   = %08h (Z state confirmed)", gpio_io);
        $display("RESULT   = %s", (gpio_io === 32'hzzzz_zzzz) ? "PASS" : "FAIL");

        // Split mixed direction mode
        axi_write(32'h4000_5008, 32'h0000_FFFF, ok); // lower 16 outputs, upper 16 inputs
        axi_write(32'h4000_5004, 32'h0000_BABE, ok); // DUT drives lower 16
        gpio_tb_drive_val = 32'hCAFE_0000;
        gpio_tb_drive_en  = 32'hFFFF_0000;          // TB drives upper 16
        repeat (4) @(posedge clk);
        #5;
        check_gpio(gpio_io === 32'hCAFE_BABE, "GPIO Mixed Direction: gpio_io shows {TB_IN[31:16], DUT_OUT[15:0]} = 0xCAFEBABE");
        axi_read(32'h4000_5000, rdata, ok);
        check_gpio(ok && (rdata === 32'hCAFE_BABE), "GPIO Mixed Direction: Read DATA_I accurately captures 0xCAFEBABE");

        // Release TB drive
        gpio_tb_drive_en = 32'h0000_0000;
        gpio_dir_pass    = 1'b1;

        // 9.7 GPIO Interrupt Test
        $display("");
        $display("--- 9.7 GPIO Interrupt Test ---");
        // Set DIR = all inputs
        axi_write(32'h4000_5008, 32'h0000_0000, ok);
        // Configure Pin 0 for Rising Edge Interrupt:
        // INT_TYP[0] = 1 (Edge), INT_POL[0] = 1 (Rising), INT_ANY[0] = 0
        axi_write(32'h4000_5010, 32'h0000_0001, ok); // Edge mode
        axi_write(32'h4000_5014, 32'h0000_0001, ok); // Rising edge
        axi_write(32'h4000_5018, 32'h0000_0000, ok); // Single edge
        axi_write(32'h4000_500C, 32'h0000_0001, ok); // Enable Pin 0 interrupt

        // Set initial Pin 0 = 0 from TB
        gpio_tb_drive_val = 32'h0000_0000;
        gpio_tb_drive_en  = 32'h0000_0001;
        repeat (5) @(posedge clk);
        intr_before = gpio_intr_o;
        check_gpio(intr_before === 1'b0, "GPIO Interrupt: Initial state gpio_intr_o == 0");

        // Generate rising edge on Pin 0 (0 -> 1)
        @(negedge clk);
        gpio_tb_drive_val[0] = 1'b1;
        // Wait for synchronizer and edge detector
        repeat (6) @(posedge clk);
        #1;
        intr_active = gpio_intr_o;
        check_gpio(intr_active === 1'b1, "GPIO Interrupt: gpio_intr_o asserted (1) upon rising edge on Pin 0");

        // Read INT_STS (0x4000_501C)
        axi_read(32'h4000_501C, rdata, ok);
        check_gpio(ok && (rdata[0] === 1'b1), "GPIO Interrupt: INT_STS[0] asserted in status register");

        // Clear interrupt via Write-1-to-Clear (W1C)
        axi_write(32'h4000_501C, 32'h0000_0001, ok);
        repeat (3) @(posedge clk);
        #1;
        intr_after = gpio_intr_o;
        check_gpio(intr_after === 1'b0, "GPIO Interrupt: gpio_intr_o deasserted (0) following W1C");

        axi_read(32'h4000_501C, rdata, ok);
        check_gpio(ok && (rdata[0] === 1'b0), "GPIO Interrupt: INT_STS[0] cleared to 0 after W1C");

        $display("[GPIO INTERRUPT TEST]");
        $display("Trigger  = Rising Edge on Pin 0");
        $display("Expected Interrupt = 1, then cleared = 0");
        $display("Actual Interrupt   = %b, then cleared = %b", intr_active, intr_after);
        $display("RESULT   = %s", (intr_active === 1'b1 && intr_after === 1'b0) ? "PASS" : "FAIL");

        // Disable interrupt
        axi_write(32'h4000_500C, 32'h0000_0000, ok);
        gpio_tb_drive_en = 32'h0000_0000;
        gpio_intr_pass   = (intr_active === 1'b1 && intr_after === 1'b0);

        // 9.8 Staggered AXI Write Test
        $display("");
        $display("--- 9.8 Staggered AXI Write Test (Independent AW/W) ---");
        // TEST 1: AW before W on GPIO DATA_O (0x4000_5004)
        axi_write_staggered(32'h4000_5004, 32'h1122_3344, aw_before_w_pass);
        check_gpio(aw_before_w_pass, "GPIO Staggered Write: AW handshake first completed successfully");

        // TEST 2: W before AW on GPIO DATA_O
        axi_write_w_before_aw(32'h4000_5004, 32'h5566_7788, w_before_aw_pass);
        check_gpio(w_before_aw_pass, "GPIO Staggered Write: W handshake first completed successfully");

        // TEST 3: Simultaneous AW and W
        axi_write(32'h4000_5004, 32'h99AA_BBCC, simultaneous_pass);
        check_gpio(simultaneous_pass, "GPIO Staggered Write: Simultaneous AW and W completed successfully");

        $display("");
        $display("[GPIO AXI STAGGERED WRITE]");
        $display("AW BEFORE W  = %s", aw_before_w_pass  ? "PASS" : "FAIL");
        $display("W BEFORE AW  = %s", w_before_aw_pass  ? "PASS" : "FAIL");
        $display("SIMULTANEOUS = %s", simultaneous_pass ? "PASS" : "FAIL");
        gpio_indep_aw_w_pass = aw_before_w_pass && w_before_aw_pass && simultaneous_pass;

        // 9.9 GPIO AXI Read Test
        $display("");
        $display("--- 9.9 GPIO AXI Read Test ---");
        // Read DATA_O
        axi_read(32'h4000_5004, rdata, ok);
        check_gpio(ok && (rdata === 32'h99AA_BBCC), "GPIO AXI Read: DATA_O verified (0x99AABBCC)");
        $display("[GPIO AXI READ]");
        $display("Address  = 0x40005004 (DATA_O)");
        $display("Expected = 0x99AABBCC");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h99AA_BBCC) ? "PASS" : "FAIL");

        // Read DIR
        axi_read(32'h4000_5008, rdata, ok);
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO AXI Read: DIR verified (0x00000000)");
        $display("[GPIO AXI READ]");
        $display("Address  = 0x40005008 (DIR)");
        $display("Expected = 0x00000000");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h0000_0000) ? "PASS" : "FAIL");

        // Read INT_EN
        axi_read(32'h4000_500C, rdata, ok);
        check_gpio(ok && (rdata === 32'h0000_0000), "GPIO AXI Read: INT_EN verified (0x00000000)");
        $display("[GPIO AXI READ]");
        $display("Address  = 0x4000500C (INT_EN)");
        $display("Expected = 0x00000000");
        $display("Actual   = 0x%08h", rdata);
        $display("RESULT   = %s", (rdata === 32'h0000_0000) ? "PASS" : "FAIL");

        // ========================================================
        // 10. RESERVED BUFFER ADDRESS GAP VERIFICATION
        // ========================================================
        $display("");
        $display("============================================================");
        $display("RESERVED BUFFER ADDRESS REGION (0x4000_4000 - 0x4000_4FFF) TEST");
        $display("============================================================");
        // Read unmapped buffer space: expect DECERR (2'b11)
        axi_read_expect_resp(32'h4000_4000, rdata, 2'b11, ok);
        check_gpio(ok, "Reserved Buffer Region: AXI READ from 0x40004000 returns DECERR (2'b11)");

        // Write unmapped buffer space: expect DECERR (2'b11)
        axi_write_expect_resp(32'h4000_4000, 32'hBAD0_BEEF, 2'b11, ok);
        check_gpio(ok, "Reserved Buffer Region: AXI WRITE to 0x40004000 returns DECERR (2'b11)");
        reserved_buffer_pass = 1'b1;

        // ========================================================
        // 11. FIVE-PERIPHERAL CROSS-ISOLATION VERIFICATION
        // ========================================================
        $display("");
        $display("============================================================");
        $display("FIVE-PERIPHERAL CROSS-ISOLATION VERIFICATION");
        $display("============================================================");
        // Verify UART LSR is unaffected
        axi_read(32'h4000_0014, rdata, ok);
        check_uart(ok && (rdata === 32'h0000_0060), "UART LSR unaffected across peripheral accesses (0x60)");

        // Verify SPI CR is unaffected
        axi_read(32'h4000_1060, rdata, ok);
        check_spi(ok && (rdata === 32'h0000_0186), "SPI CR unaffected across peripheral accesses (0x0186)");

        // Verify PWM slv_reg1 is unaffected
        axi_read(32'h4000_2004, rdata, ok);
        check_pwm(ok && (rdata === 32'h1234_5678), "PWM slv_reg1 unaffected across peripheral accesses (0x12345678)");

        // Verify 7-Segment register is intact
        axi_read(32'h4000_3000, rdata, ok);
        check_7seg(ok && (rdata === 32'h0000_BEEF), "7-Segment DISPLAY_DATA intact across peripheral accesses (0xBEEF)");

        // Verify GPIO DATA_O is intact
        axi_read(32'h4000_5004, rdata, ok);
        check_gpio(ok && (rdata === 32'h99AA_BBCC), "GPIO DATA_O intact across peripheral accesses (0x99AABBCC)");
        five_periph_isolation_pass = 1'b1;

        // ========================================================
        // FINAL SUMMARY (Section 38 Format)
        // ========================================================
        $display("");
        $display("============================================================");
        $display("SOC INTERCONNECT + UART + SPI + PWM + 7-SEG + GPIO");
        $display("FINAL TEST SUMMARY");
        $display("============================================================");
        $display("");
        $display("ADDRESS MAP");
        $display("------------------------------------------------------------");
        $display("UART       : M03 : 0x40000000 - 0x40000FFF");
        $display("SPI        : M04 : 0x40001000 - 0x40001FFF");
        $display("PWM        : M05 : 0x40002000 - 0x40002FFF");
        $display("7-SEG      : M06 : 0x40003000 - 0x40003FFF");
        $display("GPIO       : M07 : 0x40005000 - 0x40005FFF");
        $display("");
        $display("RESERVED / BUFFER REGIONS");
        $display("------------------------------------------------------------");
        $display("BUFFER GAP : 0x40004000 - 0x40004FFF (Unmapped reserved buffer)");
        $display("");
        $display("UART");
        $display("------------------------------------------------------------");
        $display("Configuration       : %s", uart_cfg_pass ? "PASS" : "FAIL");
        $display("TX                  : %s", uart_tx_pass  ? "PASS" : "FAIL");
        $display("RX                  : %s", uart_rx_pass  ? "PASS" : "FAIL");
        $display("PASS COUNT          : %0d", uart_pass_count);
        $display("FAIL COUNT          : %0d", uart_fail_count);
        $display("");
        $display("SPI");
        $display("------------------------------------------------------------");
        $display("AXI WRITE           : %s", spi_axi_wr_pass ? "PASS" : "FAIL");
        $display("AXI READ            : %s", spi_axi_rd_pass ? "PASS" : "FAIL");
        $display("CONFIGURATION       : %s", spi_cfg_pass    ? "PASS" : "FAIL");
        $display("TX                  : %s", spi_tx_pass     ? "PASS" : "FAIL");
        $display("RX                  : %s", spi_rx_pass     ? "PASS" : "FAIL");
        $display("SCLK                : %s", spi_sclk_pass   ? "PASS" : "FAIL");
        $display("CS                  : %s", spi_cs_pass     ? "PASS" : "FAIL");
        $display("STATUS              : %s", spi_status_pass ? "PASS" : "FAIL");
        $display("PASS COUNT          : %0d", spi_pass_count);
        $display("FAIL COUNT          : %0d", spi_fail_count);
        $display("");
        $display("PWM");
        $display("------------------------------------------------------------");
        $display("AXI REGISTERS       : %s", pwm_axi_reg_pass ? "PASS" : "FAIL");
        $display("RESET               : %s", pwm_reset_pass   ? "PASS" : "FAIL");
        $display("ENABLE              : %s", pwm_enable_pass  ? "PASS" : "FAIL");
        $display("PERIOD              : %s", pwm_period_pass  ? "PASS" : "FAIL");
        $display("DUTY CYCLE          : %s", pwm_duty_pass    ? "PASS" : "FAIL");
        $display("DISABLE             : %s", pwm_disable_pass ? "PASS" : "FAIL");
        $display("PASS COUNT          : %0d", pwm_pass_count);
        $display("FAIL COUNT          : %0d", pwm_fail_count);
        $display("");
        $display("7-SEGMENT");
        $display("------------------------------------------------------------");
        $display("RESET               : %s", seven_seg_reset_pass      ? "PASS" : "FAIL");
        $display("AXI REGISTERS       : %s", seven_seg_axi_reg_pass    ? "PASS" : "FAIL");
        $display("HEX DECODER         : %s", seven_seg_decoder_pass    ? "PASS" : "FAIL");
        $display("MUX                 : %s", seven_seg_mux_cycle_pass  ? "PASS" : "FAIL");
        $display("DIGIT CYCLING       : %s", seven_seg_mux_cycle_pass  ? "PASS" : "FAIL");
        $display("DISABLE             : %s", seven_seg_disable_pass    ? "PASS" : "FAIL");
        $display("STAGGERED AW/W      : %s", seven_seg_indep_aw_w_pass ? "PASS" : "FAIL");
        $display("PASS COUNT          : %0d", seven_seg_pass_count);
        $display("FAIL COUNT          : %0d", seven_seg_fail_count);
        $display("");
        $display("GPIO");
        $display("------------------------------------------------------------");
        $display("RESET               : %s", gpio_reset_pass      ? "PASS" : "FAIL");
        $display("AXI WRITE           : %s", gpio_reg_rw_pass     ? "PASS" : "FAIL");
        $display("AXI READ            : %s", gpio_reg_rw_pass     ? "PASS" : "FAIL");
        $display("OUTPUT              : %s", gpio_out_pass        ? "PASS" : "FAIL");
        $display("INPUT               : %s", gpio_in_pass         ? "PASS" : "FAIL");
        $display("DIRECTION           : %s", gpio_dir_pass        ? "PASS" : "FAIL");
        $display("INTERRUPT           : %s", gpio_intr_pass       ? "PASS" : "FAIL");
        $display("STAGGERED AW/W      : %s", gpio_indep_aw_w_pass ? "PASS" : "FAIL");
        $display("CROSS-ISOLATION     : %s", five_periph_isolation_pass ? "PASS" : "FAIL");
        $display("PASS COUNT          : %0d", gpio_pass_count);
        $display("FAIL COUNT          : %0d", gpio_fail_count);
        $display("");
        $display("============================================================");
        $display("TOTAL");
        $display("============================================================");
        $display("");
        $display("PASS COUNT = %0d", total_pass_count);
        $display("FAIL COUNT = %0d", total_fail_count);
        $display("");
        $display("============================================================");
        if (total_fail_count == 0) begin
            $display("");
            $display("SOC_INTERCONNECT_UART_SPI_PWM_7SEG_GPIO_RESULT = PASS");
            $display("");
        end
        else begin
            $display("");
            $display("SOC_INTERCONNECT_UART_SPI_PWM_7SEG_GPIO_RESULT = FAIL");
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
        #4_000_000;
        $display("");
        $display("[ERROR] Simulation timeout");
        $display("TOTAL PASS COUNT = %0d", total_pass_count);
        $display("TOTAL FAIL COUNT = %0d", total_fail_count);
        $display("SOC_INTERCONNECT_UART_SPI_PWM_7SEG_GPIO_RESULT = FAIL");
        $finish;
    end

endmodule

`default_nettype wire
