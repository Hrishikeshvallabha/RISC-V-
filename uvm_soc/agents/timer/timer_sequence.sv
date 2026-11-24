// ============================================================================
// File: timer_sequence.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequences generating capture and external measurement pulses.
// ============================================================================

`ifndef TIMER_SEQUENCE_SV
`define TIMER_SEQUENCE_SV

class timer_pulse_seq extends uvm_sequence #(timer_seq_item);

    `uvm_object_utils(timer_pulse_seq)

    function new(string name = "timer_pulse_seq");
        super.new(name);
    endfunction

    virtual task body();
        timer_seq_item item;

        `uvm_info("TIMER_SEQ", "Sending timer input capture pulses", UVM_LOW)

        // Pulse capture input
        item = timer_seq_item::type_id::create("cap_pulse_1");
        start_item(item);
        item.capture_val  = 1'b1;
        item.ext_meas_val = 1'b0;
        item.hold_cycles  = 3;
        finish_item(item);

        item = timer_seq_item::type_id::create("cap_pulse_0");
        start_item(item);
        item.capture_val  = 1'b0;
        item.ext_meas_val = 1'b0;
        item.hold_cycles  = 5;
        finish_item(item);
    endtask

endclass : timer_pulse_seq

`endif // TIMER_SEQUENCE_SV
