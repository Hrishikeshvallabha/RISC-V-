// ============================================================================
// File: display_coverage.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Functional coverage collector for Seven-Segment digit patterns.
// ============================================================================

`ifndef DISPLAY_COVERAGE_SV
`define DISPLAY_COVERAGE_SV

class display_coverage extends uvm_subscriber #(display_seq_item);

    `uvm_component_utils(display_coverage)

    display_seq_item cov_item;

    covergroup display_cg;
        option.per_instance = 1;
        option.name = "display_functional_coverage";

        cp_anode: coverpoint cov_item.anode_mask {
            bins an0 = {4'b1110};
            bins an1 = {4'b1101};
            bins an2 = {4'b1011};
            bins an3 = {4'b0111};
        }

        cp_digits: coverpoint cov_item.digit_val {
            bins hex_0_to_9 = {[4'h0:4'h9]};
            bins hex_c      = {4'hC};
            bins hex_e      = {4'hE};
            bins other_hex  = default;
        }

        cross_an_digit: cross cp_anode, cp_digits;
    endgroup

    function new(string name = "display_coverage", uvm_component parent = null);
        super.new(name, parent);
        display_cg = new();
    endfunction

    virtual function void write(display_seq_item t);
        cov_item = t;
        display_cg.sample();
    endfunction

endclass : display_coverage

`endif // DISPLAY_COVERAGE_SV
