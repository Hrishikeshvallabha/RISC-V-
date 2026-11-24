// ============================================================================
// File: soc_virtual_sequencer.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Virtual sequencer referencing all individual subsystem sequencers.
// ============================================================================

`ifndef SOC_VIRTUAL_SEQUENCER_SV
`define SOC_VIRTUAL_SEQUENCER_SV

class soc_virtual_sequencer extends uvm_sequencer;

    // Subsystem Sequencer Handles
    gpio_sequencer         gpio_seqr;
    uart_sequencer         uart_seqr;
    spi_sequencer          spi_seqr;
    timer_sequencer        timer_seqr;
    interconnect_sequencer interconnect_seqr;

    `uvm_component_utils(soc_virtual_sequencer)

    function new(string name = "soc_virtual_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : soc_virtual_sequencer

`endif // SOC_VIRTUAL_SEQUENCER_SV
