// ============================================================================
// File: interconnect_coverage.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Functional coverage collector for Crossbar slave regions and access.
// ============================================================================

`ifndef INTERCONNECT_COVERAGE_SV
`define INTERCONNECT_COVERAGE_SV

class interconnect_coverage extends uvm_subscriber #(interconnect_seq_item);

    `uvm_component_utils(interconnect_coverage)

    interconnect_seq_item cov_item;

    covergroup ic_cg;
        option.per_instance = 1;
        option.name = "interconnect_functional_coverage";

        cp_rw: coverpoint cov_item.is_write {
            bins read  = {1'b0};
            bins write = {1'b1};
        }

        cp_slave_regions: coverpoint cov_item.addr {
            bins m00_memory    = {[32'h0000_0000 : 32'h0000_FFFF]};
            bins m01_uart      = {[32'h4000_0000 : 32'h4000_0FFF]};
            bins buf_1         = {[32'h4000_1000 : 32'h4000_1FFF]};
            bins m02_gpio      = {[32'h4000_2000 : 32'h4000_2FFF]};
            bins buf_2         = {[32'h4000_3000 : 32'h4000_3FFF]};
            bins m03_timer     = {[32'h4000_4000 : 32'h4000_4FFF]};
            bins buf_3         = {[32'h4000_5000 : 32'h4000_5FFF]};
            bins m04_spi       = {[32'h4000_6000 : 32'h4000_6FFF]};
            bins buf_4         = {[32'h4000_7000 : 32'h4000_9FFF]};
            bins m05_pwm       = {[32'h4000_A000 : 32'h4000_AFFF]};
            bins buf_5         = {[32'h4000_B000 : 32'h4000_BFFF]};
            bins m06_7seg      = {[32'h4000_C000 : 32'h4000_CFFF]};
            bins other_regions = default;
        }

        cross_rw_region: cross cp_rw, cp_slave_regions;
    endgroup

    function new(string name = "interconnect_coverage", uvm_component parent = null);
        super.new(name, parent);
        ic_cg = new();
    endfunction

    virtual function void write(interconnect_seq_item t);
        cov_item = t;
        ic_cg.sample();
    endfunction

endclass : interconnect_coverage

`endif // INTERCONNECT_COVERAGE_SV
