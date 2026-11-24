// ============================================================================
// File: gpio_coverage.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Functional coverage collector for GPIO subsystem.
// ============================================================================

`ifndef GPIO_COVERAGE_SV
`define GPIO_COVERAGE_SV

class gpio_coverage extends uvm_subscriber #(gpio_seq_item);

    `uvm_component_utils(gpio_coverage)

    gpio_seq_item cov_item;

    covergroup gpio_cg;
        option.per_instance = 1;
        option.name = "gpio_functional_coverage";

        cp_drive_en: coverpoint cov_item.drive_en {
            bins all_driven   = {32'hFFFF_FFFF};
            bins all_released = {32'h0000_0000};
            bins partial_drive= default;
        }

        cp_data_patterns: coverpoint cov_item.data {
            bins all_zeros   = {32'h0000_0000};
            bins all_ones    = {32'hFFFF_FFFF};
            bins alt_a5      = {32'hA5A5_5A5A};
            bins alt_5a      = {32'h5A5A_A5A5};
            bins deadbeef    = {32'hDEAD_BEEF};
            bins count_pat   = {32'h1234_5678};
            bins low_range   = {[32'h0000_0001 : 32'h0000_FFFF]};
            bins mid_range   = {[32'h0001_0000 : 32'h7FFF_FFFF]};
            bins high_range  = {[32'h8000_0000 : 32'hFFFF_FFFE]};
        }

        cross_en_data: cross cp_drive_en, cp_data_patterns;
    endgroup

    function new(string name = "gpio_coverage", uvm_component parent = null);
        super.new(name, parent);
        gpio_cg = new();
    endfunction

    virtual function void write(gpio_seq_item t);
        cov_item = t;
        gpio_cg.sample();
    endfunction

endclass : gpio_coverage

`endif // GPIO_COVERAGE_SV
