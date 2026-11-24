// ============================================================================
// File: pwm_seq_item.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence item capturing measured PWM period and duty cycle.
// ============================================================================

`ifndef PWM_SEQ_ITEM_SV
`define PWM_SEQ_ITEM_SV

class pwm_seq_item extends uvm_sequence_item;

    time high_time;
    time low_time;
    time period;
    real duty_cycle_pct;

    `uvm_object_utils_begin(pwm_seq_item)
        `uvm_field_int(high_time, UVM_ALL_ON | UVM_TIME)
        `uvm_field_int(low_time, UVM_ALL_ON | UVM_TIME)
        `uvm_field_int(period, UVM_ALL_ON | UVM_TIME)
        `uvm_field_real(duty_cycle_pct, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "pwm_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("Duty=%.1f%%, Period=%0t ps, High=%0t ps, Low=%0t ps",
                        duty_cycle_pct, period, high_time, low_time);
    endfunction

endclass : pwm_seq_item

`endif // PWM_SEQ_ITEM_SV
