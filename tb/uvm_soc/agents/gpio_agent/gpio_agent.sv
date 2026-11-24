// ============================================================================
// File: gpio_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM agent encapsulating sequencer and driver for GPIO interface.
// ============================================================================

`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;

    gpio_sequencer seqr;
    gpio_driver    drv;

    `uvm_component_utils(gpio_agent)

    function new(string name = "gpio_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            seqr = gpio_sequencer::type_id::create("seqr", this);
            drv  = gpio_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
            `uvm_info("GPIO_AGENT_CONN", "Connected driver seq_item_port to sequencer seq_item_export", UVM_LOW)
        end
    endfunction

endclass : gpio_agent

`endif // GPIO_AGENT_SV
