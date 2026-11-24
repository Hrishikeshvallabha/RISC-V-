module tb_soc_interconnect_uart;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    reg clk;
    reg rst;

    localparam integer IC_ID_WIDTH = 8;


    // ============================================================
    // GLOBAL TEST VARIABLES
    // ============================================================

    reg [31:0] lsr;

    integer pass_count;
    integer fail_count;


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
    // UART
    // ============================================================

    reg  uart_rx_i;
    wire uart_tx_o;
    wire uart_interrupt_o;


    // ============================================================
    // DUT
    // ============================================================

    soc_interconnect_uart_top dut (
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
        .uart_interrupt_o(uart_interrupt_o)
    );


    // ============================================================
    // CLOCK
    // 100 MHz
    // 10 ns period
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
    // AXI WRITE
    //
    // AW and W channels are handled independently.
    // ============================================================

    task automatic axi_write;

        input [31:0] addr;
        input [31:0] data;

        integer timeout;

        begin

            $display("");
            $display("[AXI WRITE] ADDR=0x%08h DATA=0x%08h",
                     addr, data);

            // ----------------------------------------------------
            // Prepare transaction
            // ----------------------------------------------------

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


            // ----------------------------------------------------
            // AW HANDSHAKE
            // ----------------------------------------------------

            timeout = 0;

            while (!(axi_awvalid && axi_awready) &&
                   timeout < 200) begin

                @(posedge clk);
                timeout = timeout + 1;

            end


            if (timeout >= 200) begin

                $display(
                    "[FAIL] AXI WRITE AW handshake timeout addr=0x%08h",
                    addr
                );

                fail_count = fail_count + 1;

                @(negedge clk);

                axi_awvalid = 1'b0;
                axi_wvalid  = 1'b0;

            end
            else begin

                $display(
                    "[AXI WRITE] AW handshake complete addr=0x%08h",
                    addr
                );


                // ------------------------------------------------
                // Remove AWVALID
                // ------------------------------------------------

                @(negedge clk);

                axi_awvalid = 1'b0;


                // ------------------------------------------------
                // W HANDSHAKE
                // ------------------------------------------------

                timeout = 0;

                while (!(axi_wvalid && axi_wready) &&
                       timeout < 200) begin

                    @(posedge clk);
                    timeout = timeout + 1;

                end


                if (timeout >= 200) begin

                    $display(
                        "[FAIL] AXI WRITE W handshake timeout addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    @(negedge clk);

                    axi_wvalid = 1'b0;

                end
                else begin

                    $display(
                        "[AXI WRITE] W handshake complete data=0x%08h",
                        data
                    );


                    // ------------------------------------------------
                    // Remove WVALID
                    // ------------------------------------------------

                    @(negedge clk);

                    axi_wvalid = 1'b0;


                    // ------------------------------------------------
                    // B RESPONSE
                    // ------------------------------------------------

                    timeout = 0;

                    while (!axi_bvalid &&
                           timeout < 200) begin

                        @(posedge clk);
                        timeout = timeout + 1;

                    end


                    if (timeout >= 200) begin

                        $display(
                            "[FAIL] AXI WRITE response timeout addr=0x%08h",
                            addr
                        );

                        fail_count = fail_count + 1;

                    end
                    else begin

                        check(
                            axi_bresp == 2'b00,
                            "AXI write response OKAY"
                        );

                        $display(
                            "[AXI WRITE] COMPLETE addr=0x%08h",
                            addr
                        );

                    end

                end

            end

        end

    endtask


    // ============================================================
    // AXI READ
    // ============================================================

    task automatic axi_read;

        input  [31:0] addr;
        output [31:0] data;

        integer timeout;

        begin

            data = 32'hXXXXXXXX;

            $display("");
            $display("[AXI READ] ADDR=0x%08h", addr);


            // ----------------------------------------------------
            // Prepare read transaction
            // ----------------------------------------------------

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


            // ----------------------------------------------------
            // AR HANDSHAKE
            // ----------------------------------------------------

            timeout = 0;

            while (!(axi_arvalid && axi_arready) &&
                   timeout < 200) begin

                @(posedge clk);
                timeout = timeout + 1;

            end


            if (timeout >= 200) begin

                $display(
                    "[FAIL] AXI READ AR handshake timeout addr=0x%08h",
                    addr
                );

                fail_count = fail_count + 1;

            end
            else begin

                $display(
                    "[AXI READ] AR handshake complete addr=0x%08h",
                    addr
                );


                @(negedge clk);

                axi_arvalid = 1'b0;


                // ------------------------------------------------
                // READ DATA
                // ------------------------------------------------

                timeout = 0;

                while (!axi_rvalid &&
                       timeout < 200) begin

                    @(posedge clk);
                    timeout = timeout + 1;

                end


                if (timeout >= 200) begin

                    $display(
                        "[FAIL] AXI READ response timeout addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                end
                else begin

                    data = axi_rdata;

                    check(
                        axi_rresp == 2'b00,
                        "AXI read response OKAY"
                    );

                    $display(
                        "[AXI READ] DATA=0x%08h",
                        data
                    );

                end

            end


            @(negedge clk);

            axi_arvalid = 1'b0;

        end

    endtask


    // ============================================================
    // UART TX TEST
    //
    // BAUD_DIV = 4
    // TX BIT TIME = (4 + 1) * 10 ns = 50 ns
    // ============================================================

    task automatic tx_test;

        reg [7:0] expected;
        reg [7:0] actual;
        reg [9:0] frame;

        integer i;
        integer tx_fail_count;

        begin

            expected = 8'hA5;
            actual   = 8'h00;

            tx_fail_count = 0;

            // UART frame:
            //
            // bit 0 = START
            // bits 1-8 = DATA LSB first
            // bit 9 = STOP

            frame = {1'b1, expected, 1'b0};


            $display("");
            $display("============================================================");
            $display("INTERCONNECT -> UART TX TEST");
            $display("Expected TX = 0x%02h", expected);
            $display("============================================================");


            // ----------------------------------------------------
            // Write THR through interconnect
            // ----------------------------------------------------

            axi_write(
                32'h4000_0000,
                {24'h0, expected}
            );


            // ----------------------------------------------------
            // Wait for start bit
            // ----------------------------------------------------

            @(negedge uart_tx_o);


            // ----------------------------------------------------
            // Sample at center of each bit
            //
            // Bit period = 50 ns
            // First sample = 25 ns after start edge
            // ----------------------------------------------------

            #25;


            for (i = 0; i < 10; i = i + 1) begin

                if (uart_tx_o === frame[i]) begin

                    $display(
                        "[TX BIT %0d] Expected=%b Actual=%b PASS",
                        i,
                        frame[i],
                        uart_tx_o
                    );

                end
                else begin

                    $display(
                        "[TX BIT %0d] Expected=%b Actual=%b FAIL",
                        i,
                        frame[i],
                        uart_tx_o
                    );

                    tx_fail_count = tx_fail_count + 1;

                end


                // Capture data bits
                if ((i >= 1) && (i <= 8)) begin
                    actual[i-1] = uart_tx_o;
                end


                // Move exactly one UART bit period
                #50;

            end


            // ----------------------------------------------------
            // TX RESULT
            // ----------------------------------------------------

            if (tx_fail_count == 0) begin

                pass_count = pass_count + 1;

                $display(
                    "[TX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = PASS",
                    expected,
                    actual
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    "[TX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = FAIL",
                    expected,
                    actual
                );

            end

        end

    endtask


    // ============================================================
    // DRIVE UART RX
    //
    // RX BIT TIME = 40 ns according to the existing test setup
    // ============================================================

    task automatic drive_uart_rx;

        input [7:0] data;

        integer i;

        begin

            // Idle
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
    // UART RX TEST
    // ============================================================

    task automatic rx_test;

        reg [7:0] expected;
        reg [31:0] actual;

        integer timeout;

        begin

            expected = 8'h3C;
            actual   = 32'h0;


            $display("");
            $display("============================================================");
            $display("UART RX -> INTERCONNECT TEST");
            $display("Expected RX = 0x%02h", expected);
            $display("============================================================");


            // ----------------------------------------------------
            // Drive UART RX
            // ----------------------------------------------------

            drive_uart_rx(expected);


            // ----------------------------------------------------
            // Wait for DATA_READY
            // ----------------------------------------------------

            timeout = 0;
            lsr = 32'h0;


            while ((lsr[0] !== 1'b1) &&
                   timeout < 100) begin

                axi_read(
                    32'h4000_0014,
                    lsr
                );

                timeout = timeout + 1;

            end


            check(
                lsr[0] === 1'b1,
                "UART DATA_READY reached through integration"
            );


            // ----------------------------------------------------
            // Read RBR through interconnect
            // ----------------------------------------------------

            axi_read(
                32'h4000_0000,
                actual
            );


            // ----------------------------------------------------
            // Check RX byte
            // ----------------------------------------------------

            if (actual[7:0] === expected) begin

                pass_count = pass_count + 1;

                $display(
                    "[RX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = PASS",
                    expected,
                    actual[7:0]
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    "[RX RESULT] Expected = 0x%02h | Actual = 0x%02h | RESULT = FAIL",
                    expected,
                    actual[7:0]
                );

            end


            check(
                actual[7:0] === expected,
                "RX byte matches expected through interconnect"
            );

        end

    endtask


    // ============================================================
    // AXI DEBUG MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (axi_awvalid ||
            axi_wvalid  ||
            axi_awready ||
            axi_wready  ||
            axi_bvalid) begin

            $display(
                "[AXI DBG %0t] AWV=%b AWR=%b WV=%b WR=%b BV=%b",
                $time,
                axi_awvalid,
                axi_awready,
                axi_wvalid,
                axi_wready,
                axi_bvalid
            );

        end

    end


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // FSDB
        // --------------------------------------------------------

        $fsdbDumpfile("soc_interconnect_uart.fsdb");
        $fsdbDumpvars(0, tb_soc_interconnect_uart);
        $fsdbDumpMDA();


        // --------------------------------------------------------
        // INITIAL VALUES
        // --------------------------------------------------------

        clk = 1'b0;
        rst = 1'b1;

        lsr = 32'h0;


        // --------------------------------------------------------
        // AXI WRITE ADDRESS
        // --------------------------------------------------------

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


        // --------------------------------------------------------
        // AXI WRITE DATA
        // --------------------------------------------------------

        axi_wdata   = 32'h0;
        axi_wstrb   = 4'h0;
        axi_wlast   = 1'b0;
        axi_wvalid  = 1'b0;


        // --------------------------------------------------------
        // AXI WRITE RESPONSE
        // --------------------------------------------------------

        axi_bready = 1'b1;


        // --------------------------------------------------------
        // AXI READ ADDRESS
        // --------------------------------------------------------

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


        // --------------------------------------------------------
        // AXI READ DATA
        // --------------------------------------------------------

        axi_rready = 1'b1;


        // --------------------------------------------------------
        // UART
        // --------------------------------------------------------

        uart_rx_i = 1'b1;


        // --------------------------------------------------------
        // COUNTERS
        // --------------------------------------------------------

        pass_count = 0;
        fail_count = 0;


        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        repeat (10) @(posedge clk);

        rst = 1'b0;

        repeat (10) @(posedge clk);


        // ========================================================
        // UART CONFIGURATION
        // ========================================================

        $display("");
        $display("============================================================");
        $display("UART CONFIGURATION THROUGH AXI INTERCONNECT");
        $display("============================================================");


        // LCR: DLAB = 1
        axi_write(
            32'h4000_000C,
            32'h0000_0080
        );


        // BAUD_DIV = 4
        axi_write(
            32'h4000_0008,
            32'd4
        );


        // LCR: 8-N-1
        axi_write(
            32'h4000_000C,
            32'h0000_0003
        );


        // IER: RX interrupt enable
        axi_write(
            32'h4000_0004,
            32'h0000_0001
        );


        // --------------------------------------------------------
        // Read initial UART status
        // --------------------------------------------------------

        axi_read(
            32'h4000_0014,
            lsr
        );


        $display(
            "[UART STATUS] Initial LSR = 0x%08h",
            lsr
        );


        // ========================================================
        // TX TEST
        // ========================================================

        tx_test();


        // ========================================================
        // RX TEST
        // ========================================================

        rx_test();


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("============================================================");
        $display("SOC INTERCONNECT + UART TEST SUMMARY");
        $display("============================================================");

        $display(
            "PASS COUNT = %0d",
            pass_count
        );

        $display(
            "FAIL COUNT = %0d",
            fail_count
        );


        if (fail_count == 0) begin

            $display("");
            $display("SOC_INTERCONNECT_UART_RESULT = PASS");
            $display("");

        end
        else begin

            $display("");
            $display("SOC_INTERCONNECT_UART_RESULT = FAIL");
            $display("");

        end


        $display("============================================================");

        #100;

        $finish;

    end


    // ============================================================
    // WATCHDOG
    // ============================================================

    initial begin

        #2_000_000;

        $display("");
        $display("[FAIL] Integration testbench watchdog timeout");

        $display(
            "PASS COUNT = %0d",
            pass_count
        );

        $display(
            "FAIL COUNT = %0d",
            fail_count
        );

        $finish;

    end

endmodule
