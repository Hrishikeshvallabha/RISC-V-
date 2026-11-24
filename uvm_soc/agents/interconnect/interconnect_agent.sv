// ============================================================================
// File: interconnect_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Complete UVM agent for AXI4 Master S00 Interconnect interface.
// ============================================================================

`ifndef INTERCONNECT_AGENT_SV
`define INTERCONNECT_AGENT_SV

class interconnect_agent extends uvm_agent;

    interconnect_sequencer seqr;
    interconnect_driver    drv;
    interconnect_monitor   mon;

    uvm_analysis_port #(interconnect_seq_item) ap;
    uvm_analysis_port #(interconnect_seq_item) drv_ap;

    `uvm_component_utils(interconnect_agent)

    function new(string name = "interconnect_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = interconnect_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            seqr   = interconnect_sequencer::type_id::create("seqr", this);
            drv    = interconnect_driver::type_id::create("drv", this);
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

endclass : interconnect_agent

`endif // INTERCONNECT_AGENT_SV
