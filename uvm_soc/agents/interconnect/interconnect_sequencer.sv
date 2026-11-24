// ============================================================================
// File: interconnect_sequencer.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequencer for AXI4 Master S00 transactions.
// ============================================================================

`ifndef INTERCONNECT_SEQUENCER_SV
`define INTERCONNECT_SEQUENCER_SV

class interconnect_sequencer extends uvm_sequencer #(interconnect_seq_item);

    `uvm_component_utils(interconnect_sequencer)

    function new(string name = "interconnect_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : interconnect_sequencer

`endif // INTERCONNECT_SEQUENCER_SV
