// ============================================================================
// File: riscv_soc_test.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Top-level UVM base test initiating the static-to-dynamic
//              interface verification sequence.
// ============================================================================

`ifndef RISCV_SOC_TEST_SV
`define RISCV_SOC_TEST_SV

class riscv_soc_test extends uvm_test;

    riscv_soc_env env;

    `uvm_component_utils(riscv_soc_test)

    function new(string name = "riscv_soc_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("SOC_TEST", "Building riscv_soc_test: instantiating top environment 'env'", UVM_LOW)
        env = riscv_soc_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_sequence seq;

        phase.raise_objection(this, "Starting RISC-V SoC Interface Connection Test");
        `uvm_info("SOC_TEST", "==================================================", UVM_LOW)
        `uvm_info("SOC_TEST", "Starting Static DUT to Dynamic UVM Driver Test", UVM_LOW)
        `uvm_info("SOC_TEST", "==================================================", UVM_LOW)

        seq = gpio_sequence::type_id::create("seq");
        `uvm_info("SOC_TEST", "Starting gpio_sequence on env.agent.seqr...", UVM_LOW)
        seq.start(env.agent.seqr);

        // Allow drain time for signals to settle and synchronizers to propagate
        #200ns;

        `uvm_info("SOC_TEST", "==================================================", UVM_LOW)
        `uvm_info("SOC_TEST", "Static DUT to Dynamic Driver Test Completed Cleanly", UVM_LOW)
        `uvm_info("SOC_TEST", "==================================================", UVM_LOW)
        phase.drop_objection(this, "Completed RISC-V SoC Interface Connection Test");
    endtask

endclass : riscv_soc_test

`endif // RISCV_SOC_TEST_SV
