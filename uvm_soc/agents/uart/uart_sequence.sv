// ============================================================================
// File: uart_sequence.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequences generating directed, randomized, and error frames.
// ============================================================================

`ifndef UART_SEQUENCE_SV
`define UART_SEQUENCE_SV

class uart_basic_seq extends uvm_sequence #(uart_seq_item);

    `uvm_object_utils(uart_basic_seq)

    function new(string name = "uart_basic_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_seq_item item;
        bit [7:0] test_chars[4] = '{8'hA5, 8'h3C, 8'h55, 8'hAA};

        `uvm_info("UART_SEQ", "Starting UART basic sequence (4 characters)", UVM_LOW)

        for (int i = 0; i < 4; i++) begin
            item = uart_seq_item::type_id::create($sformatf("uart_item_%0d", i));
            start_item(item);
            item.data                 = test_chars[i];
            item.baud_period_ns       = 50; // 50ns per bit
            item.inject_framing_error = 1'b0;
            `uvm_info("UART_SEQ", $sformatf("Submitting UART char [%0d/4]: 0x%02h ('%c')",
                                          i+1, item.data, item.data), UVM_LOW)
            finish_item(item);
        end

        `uvm_info("UART_SEQ", "UART basic sequence completed successfully", UVM_LOW)
    endtask

endclass : uart_basic_seq

class uart_random_seq extends uvm_sequence #(uart_seq_item);

    `uvm_object_utils(uart_random_seq)

    rand int num_chars;
    constraint c_num { num_chars inside {[8:16]}; }

    function new(string name = "uart_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_seq_item item;
        `uvm_info("UART_RND_SEQ", $sformatf("Starting randomized UART sequence (%0d chars)", num_chars), UVM_LOW)

        for (int i = 0; i < num_chars; i++) begin
            item = uart_seq_item::type_id::create($sformatf("uart_rnd_item_%0d", i));
            start_item(item);
            if (!item.randomize()) `uvm_error("UART_RND_SEQ", "Randomization failed")
            item.baud_period_ns = 50;
            item.inject_framing_error = 1'b0;
            finish_item(item);
        end
    endtask

endclass : uart_random_seq

class uart_error_seq extends uvm_sequence #(uart_seq_item);

    `uvm_object_utils(uart_error_seq)

    function new(string name = "uart_error_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_seq_item item = uart_seq_item::type_id::create("uart_err_item");
        start_item(item);
        item.data = 8'hEE;
        item.baud_period_ns = 50;
        item.inject_framing_error = 1'b1; // Stop bit driven low (framing error)
        finish_item(item);
    endtask

endclass : uart_error_seq

`endif // UART_SEQUENCE_SV
