// ============================================================================
// File: uart_coverage.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Functional coverage collector for UART TX/RX character streams.
// ============================================================================

`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

class uart_coverage extends uvm_subscriber #(uart_seq_item);

    `uvm_component_utils(uart_coverage)

    uart_seq_item cov_item;

    covergroup uart_cg;
        option.per_instance = 1;
        option.name = "uart_functional_coverage";

        cp_char_data: coverpoint cov_item.data {
            bins ascii_letters = {[8'h41:8'h5A], [8'h61:8'h7A]};
            bins ascii_digits  = {[8'h30:8'h39]};
            bins control_chars = {8'h0A, 8'h0D, 8'h20};
            bins pattern_a5    = {8'hA5};
            bins pattern_3c    = {8'h3C};
            bins pattern_55    = {8'h55};
            bins pattern_aa    = {8'hAA};
            bins edge_00       = {8'h00};
            bins edge_ff       = {8'hFF};
            bins others        = default;
        }

        cp_baud: coverpoint cov_item.baud_period_ns {
            bins fast_baud = {50}; // 50ns = divisor 4
        }

        cp_errors: coverpoint cov_item.inject_framing_error {
            bins normal_frame = {1'b0};
            bins framing_err  = {1'b1};
        }
    endgroup

    function new(string name = "uart_coverage", uvm_component parent = null);
        super.new(name, parent);
        uart_cg = new();
    endfunction

    virtual function void write(uart_seq_item t);
        cov_item = t;
        uart_cg.sample();
    endfunction

endclass : uart_coverage

`endif // UART_COVERAGE_SV
