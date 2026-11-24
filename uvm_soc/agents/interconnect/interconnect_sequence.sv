// ============================================================================
// File: interconnect_sequence.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM sequences targeting crossbar routing, slaves, and error traps.
// ============================================================================

`ifndef INTERCONNECT_SEQUENCE_SV
`define INTERCONNECT_SEQUENCE_SV

class interconnect_address_sweep_seq extends uvm_sequence #(interconnect_seq_item);

    `uvm_object_utils(interconnect_address_sweep_seq)

    function new(string name = "interconnect_address_sweep_seq");
        super.new(name);
    endfunction

    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("ic_write_item");
        start_item(item);
        item.is_write = 1'b1;
        item.addr     = addr;
        item.data     = data;
        item.strb     = 4'b1111;
        finish_item(item);
    endtask

    virtual task read_reg(bit [31:0] addr);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("ic_read_item");
        start_item(item);
        item.is_write = 1'b0;
        item.addr     = addr;
        finish_item(item);
    endtask

    virtual task body();
        `uvm_info("IC_SWEEP_SEQ", "Starting AXI Crossbar Slave Address Sweep across M00..M06", UVM_LOW)

        // 1. M00: Unified Memory (0x0000_2000)
        write_reg(32'h0000_2000, 32'h1234_5678);
        read_reg(32'h0000_2000);

        // 2. M01: UART (0x4000_0008 - BAUD_DIV write, 0x4000_0014 - LSR read)
        write_reg(32'h4000_0008, 32'd4);
        read_reg(32'h4000_0014); // Target readable Line Status Register to avoid arbiter lockup

        // 3. M02: GPIO (0x4000_2004 - GPIO_OUTPUT)
        write_reg(32'h4000_2004, 32'hA5A5_5A5A);
        read_reg(32'h4000_2004);

        // 4. M03: Timer (0x4000_4004 - TIMER_LOAD)
        write_reg(32'h4000_4004, 32'h0000_0100);
        read_reg(32'h4000_4004);

        // 5. M04: SPI (0x4000_6060 - SPI_CR)
        read_reg(32'h4000_6064); // Read Status

        // 6. M05: PWM (0x4000_A000 - PWM_DUTY)
        write_reg(32'h4000_A000, 32'h0000_0080); // 50% duty
        read_reg(32'h4000_A000);

        // 7. M06: Seven-Segment (0x4000_C000 - DISPLAY_DATA)
        write_reg(32'h4000_C000, 32'h0000_30C0);
        read_reg(32'h4000_C000);

        `uvm_info("IC_SWEEP_SEQ", "AXI Crossbar Slave Address Sweep completed successfully", UVM_LOW)
    endtask

endclass : interconnect_address_sweep_seq

class interconnect_error_seq extends uvm_sequence #(interconnect_seq_item);

    `uvm_object_utils(interconnect_error_seq)

    function new(string name = "interconnect_error_seq");
        super.new(name);
    endfunction

    virtual task body();
        interconnect_seq_item item;

        `uvm_info("IC_ERR_SEQ", "Testing Reserved Buffer Zone Isolation (0x4000_1000)", UVM_LOW)
        item = interconnect_seq_item::type_id::create("err_item");
        start_item(item);
        item.is_write = 1'b0;
        item.addr     = 32'h4000_1000; // Reserved Buffer 1
        finish_item(item);
    endtask

endclass : interconnect_error_seq

class interconnect_read_write_seq extends uvm_sequence #(interconnect_seq_item);

    `uvm_object_utils(interconnect_read_write_seq)

    function new(string name = "interconnect_read_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        interconnect_seq_item item;
        bit [31:0] test_addrs[4] = '{32'h0000_1000, 32'h0000_1004, 32'h0000_1008, 32'h0000_100C};
        bit [31:0] test_data[4]  = '{32'hDEADBEEF, 32'hCAFEBABE, 32'h55AA55AA, 32'h12345678};

        `uvm_info("IC_RW_SEQ", "Starting AXI Interconnect Read/Write Verification Sequence", UVM_LOW)

        // Write phase
        for (int i = 0; i < 4; i++) begin
            item = interconnect_seq_item::type_id::create("wr_item");
            start_item(item);
            item.is_write = 1'b1;
            item.addr     = test_addrs[i];
            item.data     = test_data[i];
            item.strb     = 4'b1111;
            finish_item(item);
        end

        // Read back phase
        for (int i = 0; i < 4; i++) begin
            item = interconnect_seq_item::type_id::create("rd_item");
            start_item(item);
            item.is_write = 1'b0;
            item.addr     = test_addrs[i];
            finish_item(item);
        end
        `uvm_info("IC_RW_SEQ", "AXI Interconnect Read/Write Verification Sequence Completed", UVM_LOW)
    endtask

endclass : interconnect_read_write_seq

class memory_test_seq extends uvm_sequence #(interconnect_seq_item);

    `uvm_object_utils(memory_test_seq)

    function new(string name = "memory_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        interconnect_seq_item item;
        bit [31:0] sweep_addrs[6] = '{32'h0000_0800, 32'h0000_1800, 32'h0000_2800,
                                      32'h0000_4800, 32'h0000_8800, 32'h0000_E800};
        bit [31:0] test_patterns[6] = '{32'hA5A5A5A5, 32'h5A5A5A5A, 32'hFFFF0000,
                                        32'h0000FFFF, 32'h11223344, 32'h87654321};

        `uvm_info("MEM_SEQ", "Starting Unified Memory (64 KiB) Address Range Test", UVM_LOW)

        for (int i = 0; i < 6; i++) begin
            // Write
            item = interconnect_seq_item::type_id::create("mem_wr");
            start_item(item);
            item.is_write = 1'b1;
            item.addr     = sweep_addrs[i];
            item.data     = test_patterns[i];
            item.strb     = 4'b1111;
            finish_item(item);

            // Read
            item = interconnect_seq_item::type_id::create("mem_rd");
            start_item(item);
            item.is_write = 1'b0;
            item.addr     = sweep_addrs[i];
            finish_item(item);
        end

        `uvm_info("MEM_SEQ", "Unified Memory Address Range Test Completed", UVM_LOW)
    endtask

endclass : memory_test_seq

`endif // INTERCONNECT_SEQUENCE_SV
