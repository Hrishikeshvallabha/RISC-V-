// ============================================================================
// File: timer_driver.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM driver driving external timer input signals.
// ============================================================================

`ifndef TIMER_DRIVER_SV
`define TIMER_DRIVER_SV

class timer_driver extends uvm_driver #(timer_seq_item);

    virtual timer_uvm_if vif;
    uvm_analysis_port #(timer_seq_item) drv_ap;

    `uvm_component_utils(timer_driver)

    function new(string name = "timer_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv_ap = new("drv_ap", this);
        if (!uvm_config_db#(virtual timer_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for timer_driver")
        end
    endfunction

    int trans_id = 0;

    virtual task run_phase(uvm_phase phase);
        vif.timer_ext_meas <= 1'b0;
        vif.timer_capture  <= 1'b0;

        @(posedge vif.rst_n);

        forever begin
            seq_item_port.get_next_item(req);
            trans_id++;
            drv_ap.write(req);
            `uvm_info("TIMER_DRIVER", $sformatf("[%0t] [TX #%0d] Driving Timer input pins: ext_meas=%0b, capture=%0b, hold_cycles=%0d",
                                               $time, trans_id, req.ext_meas_val, req.capture_val, req.hold_cycles), UVM_MEDIUM)

            @(posedge vif.clk);
            vif.timer_ext_meas <= req.ext_meas_val;
            vif.timer_capture  <= req.capture_val;
            repeat (req.hold_cycles) @(posedge vif.clk);
            seq_item_port.item_done();
        end
    endtask

endclass : timer_driver

`endif // TIMER_DRIVER_SV
