// ============================================================================
// File: display_seq_item.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence item capturing 7-Segment multiplexed display data.
// ============================================================================

`ifndef DISPLAY_SEQ_ITEM_SV
`define DISPLAY_SEQ_ITEM_SV

class display_seq_item extends uvm_sequence_item;

    bit [3:0]  anode_mask;
    bit [6:0]  raw_seg;
    bit [3:0]  digit_val;
    bit [15:0] assembled_digits;

    `uvm_object_utils_begin(display_seq_item)
        `uvm_field_int(anode_mask, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(raw_seg, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(digit_val, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(assembled_digits, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "display_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("AN=4'b%04b, Seg=7'h%02h, Digit=0x%01h, Assembled=0x%04h",
                        anode_mask, raw_seg, digit_val, assembled_digits);
    endfunction

endclass : display_seq_item

`endif // DISPLAY_SEQ_ITEM_SV
