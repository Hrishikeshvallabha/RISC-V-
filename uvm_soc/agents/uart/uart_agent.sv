// ============================================================================
// File: uart_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Complete UVM agent for 16550 UART subsystem.
// ============================================================================

`ifndef UART_AGENT_SV
`define UART_AGENT_SV

class uart_agent extends uvm_agent;

    uart_sequencer seqr;
    uart_driver    drv;
    uart_monitor   mon;

    uvm_analysis_port #(uart_seq_item) tx_ap;
    uvm_analysis_port #(uart_seq_item) rx_ap;
    uvm_analysis_port #(uart_seq_item) drv_ap;

    `uvm_component_utils(uart_agent)

    function new(string name = "uart_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = uart_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            seqr   = uart_sequencer::type_id::create("seqr", this);
            drv    = uart_driver::type_id::create("drv", this);
            drv_ap = new("drv_ap", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
            drv.drv_ap.connect(drv_ap);
        end
        tx_ap = mon.tx_ap;
        rx_ap = mon.rx_ap;
    endfunction

endclass : uart_agent

`endif // UART_AGENT_SV
