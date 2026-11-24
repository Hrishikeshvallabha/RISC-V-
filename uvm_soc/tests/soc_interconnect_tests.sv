// ============================================================================
// File: soc_interconnect_tests.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM tests targeting AXI Crossbar interconnect, slave address
//              decode, out-of-bounds error isolation, and Unified Memory.
// ============================================================================

`ifndef SOC_INTERCONNECT_TESTS_SV
`define SOC_INTERCONNECT_TESTS_SV

// ----------------------------------------------------------------------------
// Test: interconnect_read_write_test
// ----------------------------------------------------------------------------
class interconnect_read_write_test extends soc_base_test;
    `uvm_component_utils(interconnect_read_write_test)

    function new(string name = "interconnect_read_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        interconnect_read_write_seq seq;
        phase.raise_objection(this);
        `uvm_info("IC_RW_TEST", "Executing Interconnect AXI4 Master S00 Read/Write Test", UVM_LOW)
        seq = interconnect_read_write_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);
        #1us;
        phase.drop_objection(this);
    endtask
endclass : interconnect_read_write_test

// ----------------------------------------------------------------------------
// Test: interconnect_address_decode_test
// ----------------------------------------------------------------------------
class interconnect_address_decode_test extends soc_base_test;
    `uvm_component_utils(interconnect_address_decode_test)

    function new(string name = "interconnect_address_decode_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        interconnect_address_sweep_seq seq;
        phase.raise_objection(this);
        `uvm_info("IC_DECODE_TEST", "Executing Interconnect Slave Address Decode Sweep Test", UVM_LOW)
        seq = interconnect_address_sweep_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);
        #2us;
        phase.drop_objection(this);
    endtask
endclass : interconnect_address_decode_test

// ----------------------------------------------------------------------------
// Test: interconnect_error_test
// ----------------------------------------------------------------------------
class interconnect_error_test extends soc_base_test;
    `uvm_component_utils(interconnect_error_test)

    function new(string name = "interconnect_error_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        interconnect_error_seq seq;
        phase.raise_objection(this);
        `uvm_info("IC_ERR_TEST", "Executing Interconnect Guard Space Isolation & Error Test", UVM_LOW)
        seq = interconnect_error_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);
        #1us;
        phase.drop_objection(this);
    endtask
endclass : interconnect_error_test

// ----------------------------------------------------------------------------
// Test: memory_basic_test
// ----------------------------------------------------------------------------
class memory_basic_test extends soc_base_test;
    `uvm_component_utils(memory_basic_test)

    function new(string name = "memory_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        memory_test_seq seq;
        phase.raise_objection(this);
        `uvm_info("MEM_BASIC_TEST", "Executing Unified Memory 64 KiB Read/Write Verification Test", UVM_LOW)
        seq = memory_test_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);
        #2us;
        phase.drop_objection(this);
    endtask
endclass : memory_basic_test

`endif // SOC_INTERCONNECT_TESTS_SV
