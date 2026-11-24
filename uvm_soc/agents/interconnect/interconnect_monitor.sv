// ============================================================================
// File: interconnect_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive AXI4 monitor capturing transactions on Crossbar Master S00.
// ============================================================================

`ifndef INTERCONNECT_MONITOR_SV
`define INTERCONNECT_MONITOR_SV

class interconnect_monitor extends uvm_monitor;

    virtual interconnect_uvm_if vif;
    uvm_analysis_port #(interconnect_seq_item) ap;

    `uvm_component_utils(interconnect_monitor)

    function new(string name = "interconnect_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual interconnect_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for interconnect_monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        @(posedge vif.rst_n);
        fork
            monitor_writes();
            monitor_reads();
        join
    endtask

    virtual task monitor_writes();
        interconnect_seq_item item;
        bit [31:0] captured_addr;
        bit [31:0] captured_data;

        forever begin
            @(posedge vif.clk);
            if (vif.awvalid && vif.awready) begin
                captured_addr = vif.awaddr;
                while (!(vif.wvalid && vif.wready)) @(posedge vif.clk);
                captured_data = vif.wdata;
                while (!(vif.bvalid && vif.bready)) @(posedge vif.clk);

                item = interconnect_seq_item::type_id::create("mon_ic_write");
                item.is_write = 1'b1;
                item.addr     = captured_addr;
                item.data     = captured_data;
                item.resp     = vif.bresp;

                `uvm_info("AXI_MONITOR", $sformatf("[%0t] Observed AXI WRITE Handshake: Addr=0x%08h, WDATA=0x%08h, RespCode=2'b%02b (%s), Slave_Target=%s",
                                                  $time, captured_addr, captured_data, vif.bresp,
                                                  (vif.bresp == 2'b00) ? "OKAY" : (vif.bresp == 2'b11) ? "DECERR" : "SLVERR",
                                                  (captured_addr < 32'h0001_0000) ? "M00_UnifiedRAM" :
                                                  (captured_addr >= 32'h4000_0000 && captured_addr < 32'h4000_1000) ? "M01_UART" :
                                                  (captured_addr >= 32'h4000_2000 && captured_addr < 32'h4000_3000) ? "M02_GPIO" :
                                                  (captured_addr >= 32'h4000_4000 && captured_addr < 32'h4000_5000) ? "M03_Timer" :
                                                  (captured_addr >= 32'h4000_6000 && captured_addr < 32'h4000_7000) ? "M04_SPI" :
                                                  (captured_addr >= 32'h4000_A000 && captured_addr < 32'h4000_B000) ? "M05_PWM" :
                                                  (captured_addr >= 32'h4000_C000 && captured_addr < 32'h4000_D000) ? "M06_7Segment" : "Reserved_Guard"),
                          UVM_MEDIUM)
                ap.write(item);
            end
        end
    endtask

    virtual task monitor_reads();
        interconnect_seq_item item;
        bit [31:0] captured_addr;

        forever begin
            @(posedge vif.clk);
            if (vif.arvalid && vif.arready) begin
                captured_addr = vif.araddr;
                while (!(vif.rvalid && vif.rready)) @(posedge vif.clk);

                item = interconnect_seq_item::type_id::create("mon_ic_read");
                item.is_write = 1'b0;
                item.addr     = captured_addr;
                item.rdata    = vif.rdata;
                item.resp     = vif.rresp;

                `uvm_info("AXI_MONITOR", $sformatf("[%0t] Observed AXI READ Handshake: Addr=0x%08h, RDATA=0x%08h, RespCode=2'b%02b (%s), Slave_Target=%s",
                                                  $time, captured_addr, vif.rdata, vif.rresp,
                                                  (vif.rresp == 2'b00) ? "OKAY" : (vif.rresp == 2'b11) ? "DECERR" : "SLVERR",
                                                  (captured_addr < 32'h0001_0000) ? "M00_UnifiedRAM" :
                                                  (captured_addr >= 32'h4000_0000 && captured_addr < 32'h4000_1000) ? "M01_UART" :
                                                  (captured_addr >= 32'h4000_2000 && captured_addr < 32'h4000_3000) ? "M02_GPIO" :
                                                  (captured_addr >= 32'h4000_4000 && captured_addr < 32'h4000_5000) ? "M03_Timer" :
                                                  (captured_addr >= 32'h4000_6000 && captured_addr < 32'h4000_7000) ? "M04_SPI" :
                                                  (captured_addr >= 32'h4000_A000 && captured_addr < 32'h4000_B000) ? "M05_PWM" :
                                                  (captured_addr >= 32'h4000_C000 && captured_addr < 32'h4000_D000) ? "M06_7Segment" : "Reserved_Guard"),
                          UVM_MEDIUM)
                ap.write(item);
            end
        end
    endtask

endclass : interconnect_monitor

`endif // INTERCONNECT_MONITOR_SV
