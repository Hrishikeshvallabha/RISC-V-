// ============================================================================
// File: spi_agent.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Complete UVM agent for SPI Temperature Sensor subsystem.
// ============================================================================

`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent extends uvm_agent;

    spi_sequencer seqr;
    spi_driver    drv;
    spi_monitor   mon;

    uvm_analysis_port #(spi_seq_item) ap;
    uvm_analysis_port #(spi_seq_item) drv_ap;

    `uvm_component_utils(spi_agent)

    function new(string name = "spi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = spi_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            seqr   = spi_sequencer::type_id::create("seqr", this);
            drv    = spi_driver::type_id::create("drv", this);
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

endclass : spi_agent

`endif // SPI_AGENT_SV
