// ============================================================================
// File: gpio_seq_item.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence item representing a GPIO transaction.
// ============================================================================

`ifndef GPIO_SEQ_ITEM_SV
`define GPIO_SEQ_ITEM_SV

class gpio_seq_item extends uvm_sequence_item;

    // Stimulus fields
    rand bit [31:0] data;
    rand bit [31:0] drive_en;
    rand int        hold_cycles;

    // Constraints
    constraint c_hold_cycles {
        hold_cycles inside {[2:8]};
    }

    constraint c_drive_en {
        drive_en == 32'hFFFF_FFFF;
    }

    `uvm_object_utils_begin(gpio_seq_item)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(drive_en, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(hold_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    function new(string name = "gpio_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("data=0x%08h, drive_en=0x%08h, hold_cycles=%0d",
                        data, drive_en, hold_cycles);
    endfunction

endclass : gpio_seq_item

`endif // GPIO_SEQ_ITEM_SV
