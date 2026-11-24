// ============================================================================
// File: timer_coverage.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Functional coverage collector for Timer inputs and interrupts.
// ============================================================================

`ifndef TIMER_COVERAGE_SV
`define TIMER_COVERAGE_SV

class timer_coverage extends uvm_subscriber #(timer_seq_item);

    `uvm_component_utils(timer_coverage)

    timer_seq_item cov_item;

    covergroup timer_cg;
        option.per_instance = 1;
        option.name = "timer_functional_coverage";

        cp_ext_meas: coverpoint cov_item.ext_meas_val {
            bins low  = {1'b0};
            bins high = {1'b1};
        }

        cp_capture: coverpoint cov_item.capture_val {
            bins low  = {1'b0};
            bins high = {1'b1};
        }
    endgroup

    function new(string name = "timer_coverage", uvm_component parent = null);
        super.new(name, parent);
        timer_cg = new();
    endfunction

    virtual function void write(timer_seq_item t);
        cov_item = t;
        timer_cg.sample();
    endfunction

endclass : timer_coverage

`endif // TIMER_COVERAGE_SV
