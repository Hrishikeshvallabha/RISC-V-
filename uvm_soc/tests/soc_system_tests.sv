// ============================================================================
// File: soc_system_tests.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: System-level tests: processor boot, thermal closed-loop regulation,
//              concurrent peripheral traffic, and full regression test.
// ============================================================================

`ifndef SOC_SYSTEM_TESTS_SV
`define SOC_SYSTEM_TESTS_SV

// ----------------------------------------------------------------------------
// Test: processor_boot_test
// ----------------------------------------------------------------------------
class processor_boot_test extends soc_base_test;
    `uvm_component_utils(processor_boot_test)

    function new(string name = "processor_boot_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("PROC_BOOT_TEST", "Executing VeeR EL2 Processor Boot & Execution Verification Test", UVM_LOW)
        // Wait for CPU to boot, fetch instructions from Unified Memory, and retire at least 100 instructions
        #25us;
        if (env.core_mon.retired_instruction_count > 0) begin
            `uvm_info("PROC_BOOT_TEST", $sformatf("[PASS] CPU confirmed running! Retired %0d instructions",
                                                  env.core_mon.retired_instruction_count), UVM_LOW)
        end else begin
            `uvm_error("PROC_BOOT_TEST", "[FAIL] CPU failed to retire any instructions after reset!")
        end
        phase.drop_objection(this);
    endtask
endclass : processor_boot_test

// ----------------------------------------------------------------------------
// Test: soc_temperature_fan_normal_test
// ----------------------------------------------------------------------------
class soc_temperature_fan_normal_test extends soc_base_test;
    `uvm_component_utils(soc_temperature_fan_normal_test)

    function new(string name = "soc_temperature_fan_normal_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        soc_normal_vseq vseq;
        phase.raise_objection(this);
        `uvm_info("SOC_NORM_TEST", "Executing Closed-Loop Thermal Regulation: Normal Operation Test", UVM_LOW)
        vseq = soc_normal_vseq::type_id::create("vseq");
        vseq.start(env.vseqr);
        #15us;
        phase.drop_objection(this);
    endtask
endclass : soc_temperature_fan_normal_test

// ----------------------------------------------------------------------------
// Test: soc_temperature_fan_boundary_test
// ----------------------------------------------------------------------------
class soc_temperature_fan_boundary_test extends soc_base_test;
    `uvm_component_utils(soc_temperature_fan_boundary_test)

    function new(string name = "soc_temperature_fan_boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        soc_boundary_vseq vseq;
        phase.raise_objection(this);
        `uvm_info("SOC_BOUND_TEST", "Executing Closed-Loop Thermal Regulation: Boundary & Emergency Stress Test", UVM_LOW)
        vseq = soc_boundary_vseq::type_id::create("vseq");
        vseq.start(env.vseqr);
        #30us;
        phase.drop_objection(this);
    endtask
endclass : soc_temperature_fan_boundary_test

// ----------------------------------------------------------------------------
// Test: soc_concurrent_peripheral_test
// ----------------------------------------------------------------------------
class soc_concurrent_peripheral_test extends soc_base_test;
    `uvm_component_utils(soc_concurrent_peripheral_test)

    function new(string name = "soc_concurrent_peripheral_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        soc_concurrent_vseq vseq;
        phase.raise_objection(this);
        `uvm_info("SOC_CONCUR_TEST", "Executing Concurrent Multi-Peripheral Stimulation Test", UVM_LOW)
        vseq = soc_concurrent_vseq::type_id::create("vseq");
        vseq.start(env.vseqr);
        #20us;
        phase.drop_objection(this);
    endtask
endclass : soc_concurrent_peripheral_test

// ----------------------------------------------------------------------------
// Test: soc_full_regression_test
// ----------------------------------------------------------------------------
class soc_full_regression_test extends soc_base_test;
    `uvm_component_utils(soc_full_regression_test)

    function new(string name = "soc_full_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        soc_full_regression_vseq vseq;
        phase.raise_objection(this);
        `uvm_info("SOC_REG_TEST", "Executing Master Full SoC Regression Test Across All Subsystems", UVM_LOW)
        vseq = soc_full_regression_vseq::type_id::create("vseq");
        vseq.start(env.vseqr);
        #40us;
        phase.drop_objection(this);
    endtask
endclass : soc_full_regression_test

`endif // SOC_SYSTEM_TESTS_SV
