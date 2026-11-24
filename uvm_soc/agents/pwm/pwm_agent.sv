// ============================================================================
// File: pwm_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive UVM agent encapsulating PWM monitor.
// ============================================================================

`ifndef PWM_AGENT_SV
`define PWM_AGENT_SV

class pwm_agent extends uvm_agent;

    pwm_monitor mon;
    uvm_analysis_port #(pwm_seq_item) ap;

    `uvm_component_utils(pwm_agent)

    function new(string name = "pwm_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = pwm_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
    endfunction

endclass : pwm_agent

`endif // PWM_AGENT_SV
