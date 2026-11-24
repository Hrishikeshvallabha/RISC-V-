// ============================================================================
// File: interconnect_driver.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Dynamic UVM AXI4 master driver stimulating Crossbar Master S00.
// ============================================================================

`ifndef INTERCONNECT_DRIVER_SV
`define INTERCONNECT_DRIVER_SV

class interconnect_driver extends uvm_driver #(interconnect_seq_item);

    virtual interconnect_uvm_if vif;
    uvm_analysis_port #(interconnect_seq_item) drv_ap;

    `uvm_component_utils(interconnect_driver)

    function new(string name = "interconnect_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv_ap = new("drv_ap", this);
        if (!uvm_config_db#(virtual interconnect_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for interconnect_driver")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Quiescent state
        vif.awvalid <= 1'b0;
        vif.wvalid  <= 1'b0;
        vif.bready  <= 1'b1;
        vif.arvalid <= 1'b0;
        vif.rready  <= 1'b1;

        @(posedge vif.rst_n);
        repeat (5) @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            if (req.is_write) begin
                axi_write(req);
            end else begin
                axi_read(req);
            end
            seq_item_port.item_done();
        end
    endtask

    int trans_id = 0;

    virtual task axi_write(interconnect_seq_item item);
        trans_id++;
        drv_ap.write(item);
        `uvm_info("AXI_DRIVER", $sformatf("[%0t] [TX #%0d] Initiating AXI WRITE: Master_ID=0x01, Addr=0x%08h, WDATA=0x%08h, WSTRB=4'b%04b, Size=32-bit",
                                         $time, trans_id, item.addr, item.data, item.strb), UVM_MEDIUM)

        @(posedge vif.clk);
        // Assert AW and W channels
        vif.awaddr  <= item.addr;
        vif.awid    <= 8'h01;
        vif.awlen   <= 8'h00;
        vif.awsize  <= 3'b010; // 32-bit
        vif.awburst <= 2'b01;  // INCR
        vif.awvalid <= 1'b1;

        vif.wdata   <= item.data;
        vif.wstrb   <= item.strb;
        vif.wlast   <= 1'b1;
        vif.wvalid  <= 1'b1;
        vif.bready  <= 1'b1;

        fork
            begin
                fork
                    begin : aw_channel
                        @(posedge vif.clk);
                        while (!vif.awready) @(posedge vif.clk);
                        vif.awvalid <= 1'b0;
                    end
                    begin : w_channel
                        @(posedge vif.clk);
                        while (!vif.wready) @(posedge vif.clk);
                        vif.wvalid <= 1'b0;
                        vif.wlast  <= 1'b0;
                    end
                    begin : b_channel
                        while (!vif.bvalid) @(posedge vif.clk);
                        item.resp = vif.bresp;
                    end
                join
            end
            begin
                repeat (300) @(posedge vif.clk);
                `uvm_warning("AXI_TIMEOUT", $sformatf("AXI WRITE timed out at addr=0x%08h", item.addr))
            end
        join_any
        disable fork;

        vif.awvalid <= 1'b0;
        vif.wvalid  <= 1'b0;
        vif.wlast   <= 1'b0;
        @(posedge vif.clk);

        `uvm_info("AXI_DRIVER", $sformatf("[%0t] [TX #%0d] AXI WRITE Handshake Completed: Addr=0x%08h, WDATA=0x%08h, RespCode=2'b%02b (%s)",
                                         $time, trans_id, item.addr, item.data, item.resp,
                                         (item.resp == 2'b00) ? "OKAY" : (item.resp == 2'b11) ? "DECERR" : "SLVERR"), UVM_MEDIUM)
    endtask

    virtual task axi_read(interconnect_seq_item item);
        trans_id++;
        drv_ap.write(item);
        `uvm_info("AXI_DRIVER", $sformatf("[%0t] [TX #%0d] Initiating AXI READ: Master_ID=0x01, Addr=0x%08h, Size=32-bit",
                                         $time, trans_id, item.addr), UVM_MEDIUM)

        @(posedge vif.clk);
        // Assert AR channel
        vif.araddr  <= item.addr;
        vif.arid    <= 8'h01;
        vif.arlen   <= 8'h00;
        vif.arsize  <= 3'b010;
        vif.arburst <= 2'b01;
        vif.arvalid <= 1'b1;
        vif.rready  <= 1'b1;

        fork
            begin
                fork
                    begin : ar_channel
                        @(posedge vif.clk);
                        while (!vif.arready) @(posedge vif.clk);
                        vif.arvalid <= 1'b0;
                    end
                    begin : r_channel
                        while (!vif.rvalid) @(posedge vif.clk);
                        item.rdata = vif.rdata;
                        item.resp  = vif.rresp;
                    end
                join
            end
            begin
                repeat (300) @(posedge vif.clk);
                `uvm_warning("AXI_TIMEOUT", $sformatf("AXI READ timed out at addr=0x%08h", item.addr))
            end
        join_any
        disable fork;

        vif.arvalid <= 1'b0;
        @(posedge vif.clk);

        `uvm_info("AXI_DRIVER", $sformatf("[%0t] [TX #%0d] AXI READ Handshake Completed: Addr=0x%08h, RDATA=0x%08h, RespCode=2'b%02b (%s)",
                                         $time, trans_id, item.addr, item.rdata, item.resp,
                                         (item.resp == 2'b00) ? "OKAY" : (item.resp == 2'b11) ? "DECERR" : "SLVERR"), UVM_MEDIUM)
    endtask

endclass : interconnect_driver

`endif // INTERCONNECT_DRIVER_SV
