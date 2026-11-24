// ============================================================================
// File: gpio_sequence.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence delivering targeted stimulus patterns to the driver.
// ============================================================================

`ifndef GPIO_SEQUENCE_SV
`define GPIO_SEQUENCE_SV

class gpio_sequence extends uvm_sequence #(gpio_seq_item);

    `uvm_object_utils(gpio_sequence)

    function new(string name = "gpio_sequence");
        super.new(name);
    endfunction

    virtual task body();
        gpio_seq_item item;
        bit [31:0] test_patterns[4] = '{
            32'hA5A5_5A5A,
            32'h5A5A_A5A5,
            32'hDEAD_BEEF,
            32'h1234_5678
        };

        `uvm_info("GPIO_SEQ", "Starting GPIO stimulus sequence with 4 distinct test patterns", UVM_LOW)

        for (int i = 0; i < 4; i++) begin
            item = gpio_seq_item::type_id::create($sformatf("gpio_item_%0d", i));
            start_item(item);
            item.data        = test_patterns[i];
            item.drive_en    = 32'hFFFF_FFFF;
            item.hold_cycles = 5;
            `uvm_info("GPIO_SEQ", $sformatf("Submitting transaction [%0d/4]: data=0x%08h, drive_en=0x%08h, hold=%0d cycles",
                                          i+1, item.data, item.drive_en, item.hold_cycles), UVM_LOW)
            finish_item(item);
        end

        // Release bus after driving test vectors (tri-state release)
        item = gpio_seq_item::type_id::create("gpio_item_release");
        start_item(item);
        item.data        = 32'h0000_0000;
        item.drive_en    = 32'h0000_0000; // Release to high-Z
        item.hold_cycles = 4;
        `uvm_info("GPIO_SEQ", "Submitting bus release transaction (drive_en=0, high-Z)", UVM_LOW)
        finish_item(item);

        `uvm_info("GPIO_SEQ", "GPIO stimulus sequence completed successfully", UVM_LOW)
    endtask

endclass : gpio_sequence

`endif // GPIO_SEQUENCE_SV
