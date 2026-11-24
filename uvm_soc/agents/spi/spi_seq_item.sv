// ============================================================================
// File: spi_seq_item.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence item for SPI temperature sensor exchange.
// ============================================================================

`ifndef SPI_SEQ_ITEM_SV
`define SPI_SEQ_ITEM_SV

class spi_seq_item extends uvm_sequence_item;

    rand bit [7:0] temperature_c; // Temperature in degrees Celsius
    rand bit [7:0] mosi_cmd;      // Captured MOSI command from master
    rand bit [7:0] miso_resp;     // Sensor response byte on MISO

    constraint c_temp_range {
        temperature_c inside {[15:135]};
    }

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(temperature_c, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(mosi_cmd, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(miso_resp, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
        mosi_cmd = 8'h00;
        miso_resp = 8'h19; // Default 25 C
    endfunction

    virtual function string convert2string();
        return $sformatf("Temp=%0d C (0x%02h), MOSI=0x%02h, MISO=0x%02h",
                        temperature_c, temperature_c, mosi_cmd, miso_resp);
    endfunction

endclass : spi_seq_item

`endif // SPI_SEQ_ITEM_SV
