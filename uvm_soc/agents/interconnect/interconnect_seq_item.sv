// ============================================================================
// File: interconnect_seq_item.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence item representing an AXI4 read or write transaction.
// ============================================================================

`ifndef INTERCONNECT_SEQ_ITEM_SV
`define INTERCONNECT_SEQ_ITEM_SV

class interconnect_seq_item extends uvm_sequence_item;

    rand bit        is_write;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;
    bit [1:0]       resp; // 2'b00: OKAY, 2'b11: DECERR
    bit [31:0]      rdata;

    constraint c_strb { strb == 4'b1111; }

    `uvm_object_utils_begin(interconnect_seq_item)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(strb, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(resp, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "interconnect_seq_item");
        super.new(name);
        is_write = 1'b0;
        addr     = 32'h0000_0000;
        data     = 32'h0000_0000;
        strb     = 4'b1111;
        resp     = 2'b00;
        rdata    = 32'h0000_0000;
    endfunction

    virtual function string convert2string();
        if (is_write)
            return $sformatf("WRITE addr=0x%08h, data=0x%08h, resp=2'b%02b", addr, data, resp);
        else
            return $sformatf("READ addr=0x%08h, rdata=0x%08h, resp=2'b%02b", addr, rdata, resp);
    endfunction

endclass : interconnect_seq_item

`endif // INTERCONNECT_SEQ_ITEM_SV
