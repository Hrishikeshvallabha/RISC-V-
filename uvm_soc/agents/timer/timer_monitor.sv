// ============================================================================
// File: timer_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive monitor tracking timer interrupts, PWM, and triggers.
// ============================================================================

`ifndef TIMER_MONITOR_SV
`define TIMER_MONITOR_SV

class timer_monitor extends uvm_monitor;

    virtual timer_uvm_if vif;
    uvm_analysis_port #(timer_seq_item) ap;

    `uvm_component_utils(timer_monitor)

    function new(string name = "timer_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual timer_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for timer_monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        timer_seq_item item;
        logic prev_irq = 1'b0;
        logic prev_trigger = 1'b0;
        logic prev_meas = 1'b0;
        logic prev_cap = 1'b0;

        @(posedge vif.rst_n);
        prev_irq     = vif.timer_irq;
        prev_trigger = vif.timer_trigger;
        prev_meas    = vif.timer_ext_meas;
        prev_cap     = vif.timer_capture;

        forever begin
            @(posedge vif.clk);
            if ((vif.timer_irq && !prev_irq) || (vif.timer_trigger && !prev_trigger) ||
                (vif.timer_ext_meas !== prev_meas) || (vif.timer_capture !== prev_cap)) begin
                item = timer_seq_item::type_id::create("mon_timer_item");
                item.ext_meas_val = vif.timer_ext_meas;
                item.capture_val  = vif.timer_capture;
                `uvm_info("TIMER_MONITOR", $sformatf("[%0t] Observed Timer Event / Transition: ext_meas=%0b, capture=%0b (IRQ=%0b, Trigger=%0b)",
                                                    $time, vif.timer_ext_meas, vif.timer_capture,
                                                    vif.timer_irq, vif.timer_trigger), UVM_MEDIUM)
                ap.write(item);
            end
            prev_irq     = vif.timer_irq;
            prev_trigger = vif.timer_trigger;
            prev_meas    = vif.timer_ext_meas;
            prev_cap     = vif.timer_capture;
        end
    endtask

endclass : timer_monitor

`endif // TIMER_MONITOR_SV
