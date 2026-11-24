// ============================================================================
// File: spi_sequence.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequences providing thermal profile vectors to SPI sensor driver.
// ============================================================================

`ifndef SPI_SEQUENCE_SV
`define SPI_SEQUENCE_SV

class spi_sensor_profile_seq extends uvm_sequence #(spi_seq_item);

    `uvm_object_utils(spi_sensor_profile_seq)

    function new(string name = "spi_sensor_profile_seq");
        super.new(name);
    endfunction

    virtual task body();
        spi_seq_item item;
        // Thermal regulation sequence: 25 C (Quiet), 30 C (Warm), 50 C (Boost), 130 C (Emergency), 25 C (Recovery)
        bit [7:0] profile_temps[5] = '{8'h19, 8'h1E, 8'h32, 8'h82, 8'h19};

        `uvm_info("SPI_SEQ", "Starting SPI thermal profile sequence (5 temperature steps)", UVM_LOW)

        for (int i = 0; i < 5; i++) begin
            item = spi_seq_item::type_id::create($sformatf("spi_temp_step_%0d", i));
            start_item(item);
            item.temperature_c = profile_temps[i];
            item.miso_resp     = profile_temps[i];
            `uvm_info("SPI_SEQ", $sformatf("Programmed sensor temperature step [%0d/5]: %0d C (0x%02h)",
                                          i+1, item.temperature_c, item.temperature_c), UVM_LOW)
            finish_item(item);
        end
    endtask

endclass : spi_sensor_profile_seq

class spi_sensor_constant_seq extends uvm_sequence #(spi_seq_item);

    `uvm_object_utils(spi_sensor_constant_seq)

    rand bit [7:0] target_temp;

    function new(string name = "spi_sensor_constant_seq");
        super.new(name);
        target_temp = 8'h19; // Default 25 C
    endfunction

    virtual task body();
        spi_seq_item item;
        forever begin
            item = spi_seq_item::type_id::create("const_temp_item");
            start_item(item);
            item.temperature_c = target_temp;
            item.miso_resp     = target_temp;
            finish_item(item);
        end
    endtask

endclass : spi_sensor_constant_seq

`endif // SPI_SEQUENCE_SV
