// ============================================================================
// File: timer_sequencer.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequencer for Timer stimulus.
// ============================================================================

`ifndef TIMER_SEQUENCER_SV
`define TIMER_SEQUENCER_SV

class timer_sequencer extends uvm_sequencer #(timer_seq_item);

    `uvm_component_utils(timer_sequencer)

    function new(string name = "timer_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : timer_sequencer

`endif // TIMER_SEQUENCER_SV
