// ============================================================================
// File: spi_sequencer.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequencer for SPI temperature sensor stimulus.
// ============================================================================

`ifndef SPI_SEQUENCER_SV
`define SPI_SEQUENCER_SV

class spi_sequencer extends uvm_sequencer #(spi_seq_item);

    `uvm_component_utils(spi_sequencer)

    function new(string name = "spi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : spi_sequencer

`endif // SPI_SEQUENCER_SV
