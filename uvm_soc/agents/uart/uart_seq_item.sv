// ============================================================================
// File: uart_seq_item.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequence item representing a UART character frame transaction.
// ============================================================================

`ifndef UART_SEQ_ITEM_SV
`define UART_SEQ_ITEM_SV

class uart_seq_item extends uvm_sequence_item;

    rand bit [7:0] data;
    rand int       baud_period_ns;
    rand bit       parity_en;
    rand bit       parity_mode; // 0=odd, 1=even
    rand bit       stop_bits;   // 0=1 bit, 1=2 bits
    rand bit       inject_framing_error;

    constraint c_baud {
        baud_period_ns == 50; // 50ns = 5 cycles at 100MHz (divisor 4)
    }

    constraint c_default_frame {
        parity_en == 1'b0;
        stop_bits == 1'b0;
        inject_framing_error == 1'b0;
    }

    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(baud_period_ns, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(parity_en, UVM_ALL_ON)
        `uvm_field_int(parity_mode, UVM_ALL_ON)
        `uvm_field_int(stop_bits, UVM_ALL_ON)
        `uvm_field_int(inject_framing_error, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("data=0x%02h ('%c'), baud=%0dns, err=%0b",
                        data, (data >= 32 && data <= 126) ? data : ".", baud_period_ns, inject_framing_error);
    endfunction

endclass : uart_seq_item

`endif // UART_SEQ_ITEM_SV
