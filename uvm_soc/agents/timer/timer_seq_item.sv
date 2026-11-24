// ============================================================================
// File: timer_seq_item.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence item for timer measurement and capture pulses.
// ============================================================================

`ifndef TIMER_SEQ_ITEM_SV
`define TIMER_SEQ_ITEM_SV

class timer_seq_item extends uvm_sequence_item;

    rand bit ext_meas_val;
    rand bit capture_val;
    rand int hold_cycles;

    constraint c_cycles { hold_cycles inside {[2:10]}; }

    `uvm_object_utils_begin(timer_seq_item)
        `uvm_field_int(ext_meas_val, UVM_ALL_ON)
        `uvm_field_int(capture_val, UVM_ALL_ON)
        `uvm_field_int(hold_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    function new(string name = "timer_seq_item");
        super.new(name);
    endfunction

endclass : timer_seq_item

`endif // TIMER_SEQ_ITEM_SV
