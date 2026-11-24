// ============================================================================
// File: gpio_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Complete GPIO agent encapsulating sequencer, driver, and monitor.
// ============================================================================

`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;

    gpio_sequencer seqr;
    gpio_driver    drv;
    gpio_monitor   mon;

    uvm_analysis_port #(gpio_seq_item) ap;
    uvm_analysis_port #(gpio_seq_item) drv_ap;

    `uvm_component_utils(gpio_agent)

    function new(string name = "gpio_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = gpio_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            seqr   = gpio_sequencer::type_id::create("seqr", this);
            drv    = gpio_driver::type_id::create("drv", this);
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

endclass : gpio_agent

`endif // GPIO_AGENT_SV
