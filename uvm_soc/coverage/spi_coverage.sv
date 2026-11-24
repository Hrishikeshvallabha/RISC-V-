// ============================================================================
// File: spi_coverage.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Functional coverage collector for SPI temperature sensor transfers.
// ============================================================================

`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV

class spi_coverage extends uvm_subscriber #(spi_seq_item);

    `uvm_component_utils(spi_coverage)

    spi_seq_item cov_item;

    covergroup spi_cg;
        option.per_instance = 1;
        option.name = "spi_functional_coverage";

        cp_temp_tiers: coverpoint cov_item.temperature_c {
            bins cold_tier      = {[0:24]};          // < 25 C
            bins normal_tier    = {25};              // 25 C (Quiet Mode)
            bins warm_tier      = {[26:45]};         // 26 C - 45 C
            bins boost_tier     = {[46:70]};         // > 45 C
            bins emergency_tier = {[100:150]};       // Extreme out of bounds
        }

        cp_mosi_cmd: coverpoint cov_item.mosi_cmd {
            bins nop_cmd   = {8'h00};
            bins read_cmd  = {8'h01, 8'h02, 8'h50};
            bins other_cmd = default;
        }
    endgroup

    function new(string name = "spi_coverage", uvm_component parent = null);
        super.new(name, parent);
        spi_cg = new();
    endfunction

    virtual function void write(spi_seq_item t);
        cov_item = t;
        spi_cg.sample();
    endfunction

endclass : spi_coverage

`endif // SPI_COVERAGE_SV
