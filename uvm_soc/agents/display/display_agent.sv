// ============================================================================
// File: display_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive UVM agent encapsulating the Seven-Segment Display monitor.
// ============================================================================

`ifndef DISPLAY_AGENT_SV
`define DISPLAY_AGENT_SV

class display_agent extends uvm_agent;

    display_monitor mon;
    uvm_analysis_port #(display_seq_item) ap;

    `uvm_component_utils(display_agent)

    function new(string name = "display_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = display_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
    endfunction

endclass : display_agent

`endif // DISPLAY_AGENT_SV
