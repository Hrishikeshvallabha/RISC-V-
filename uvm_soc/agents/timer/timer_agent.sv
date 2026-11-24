// ============================================================================
// File: timer_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Complete UVM agent for Hardware Timer subsystem.
// ============================================================================

`ifndef TIMER_AGENT_SV
`define TIMER_AGENT_SV

class timer_agent extends uvm_agent;

    timer_sequencer seqr;
    timer_driver    drv;
    timer_monitor   mon;

    uvm_analysis_port #(timer_seq_item) ap;
    uvm_analysis_port #(timer_seq_item) drv_ap;

    `uvm_component_utils(timer_agent)

    function new(string name = "timer_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = timer_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            seqr   = timer_sequencer::type_id::create("seqr", this);
            drv    = timer_driver::type_id::create("drv", this);
            drv_ap = new("drv_ap", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
            drv.drv_ap.connect(drv_ap);
        end
        ap = mon.ap;
    endfunction

endclass : timer_agent

`endif // TIMER_AGENT_SV
