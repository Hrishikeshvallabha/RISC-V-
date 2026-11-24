// ============================================================================
// File: soc_virtual_sequences.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: System-level virtual sequences coordinating multiple subsystem agents.
// ============================================================================

`ifndef SOC_VIRTUAL_SEQUENCES_SV
`define SOC_VIRTUAL_SEQUENCES_SV

class soc_base_vseq extends uvm_sequence;

    `uvm_object_utils(soc_base_vseq)
    `uvm_declare_p_sequencer(soc_virtual_sequencer)

    function new(string name = "soc_base_vseq");
        super.new(name);
    endfunction

endclass : soc_base_vseq

// Virtual Sequence 1: Normal Operation (Quiet Mode 25 C)
class soc_normal_vseq extends soc_base_vseq;

    `uvm_object_utils(soc_normal_vseq)

    function new(string name = "soc_normal_vseq");
        super.new(name);
    endfunction

    virtual task body();
        gpio_sequence                   gpio_seq;
        uart_basic_seq                  uart_seq;
        spi_sensor_profile_seq          spi_seq;
        interconnect_address_sweep_seq  ic_seq;

        `uvm_info("SOC_VSEQ", "Executing Scenario A: Normal Operating Mode Bring-Up", UVM_LOW)

        // 1. Program SPI Sensor to 25 C
        spi_seq = spi_sensor_profile_seq::type_id::create("spi_seq");
        spi_seq.start(p_sequencer.spi_seqr);

        // 2. Exercise GPIO Patterns
        gpio_seq = gpio_sequence::type_id::create("gpio_seq");
        gpio_seq.start(p_sequencer.gpio_seqr);

        // 3. Exercise Interconnect Slaves
        ic_seq = interconnect_address_sweep_seq::type_id::create("ic_seq");
        ic_seq.start(p_sequencer.interconnect_seqr);

        // 4. Send UART Frame
        uart_seq = uart_basic_seq::type_id::create("uart_seq");
        uart_seq.start(p_sequencer.uart_seqr);

        `uvm_info("SOC_VSEQ", "Scenario A: Normal Operating Mode Bring-Up Completed", UVM_LOW)
    endtask

endclass : soc_normal_vseq

// Virtual Sequence 2: Concurrent Multi-Peripheral Stimulation
class soc_concurrent_vseq extends soc_base_vseq;

    `uvm_object_utils(soc_concurrent_vseq)

    function new(string name = "soc_concurrent_vseq");
        super.new(name);
    endfunction

    virtual task body();
        gpio_sequence                   gpio_seq  = gpio_sequence::type_id::create("gpio_seq");
        uart_basic_seq                  uart_seq  = uart_basic_seq::type_id::create("uart_seq");
        timer_pulse_seq                 tmr_seq   = timer_pulse_seq::type_id::create("tmr_seq");
        interconnect_address_sweep_seq  ic_seq    = interconnect_address_sweep_seq::type_id::create("ic_seq");

        `uvm_info("SOC_CONCUR_VSEQ", "Launching Concurrent Multi-Peripheral Stimulus (GPIO + UART + Timer + AXI)", UVM_LOW)

        fork
            gpio_seq.start(p_sequencer.gpio_seqr);
            uart_seq.start(p_sequencer.uart_seqr);
            tmr_seq.start(p_sequencer.timer_seqr);
            ic_seq.start(p_sequencer.interconnect_seqr);
        join

        `uvm_info("SOC_CONCUR_VSEQ", "Concurrent Multi-Peripheral Stimulus Completed Cleanly", UVM_LOW)
    endtask

endclass : soc_concurrent_vseq

// Virtual Sequence 3: Out-of-Bounds & Guard Space Isolation Test
class soc_error_vseq extends soc_base_vseq;

    `uvm_object_utils(soc_error_vseq)

    function new(string name = "soc_error_vseq");
        super.new(name);
    endfunction

    virtual task body();
        uart_error_seq          uart_err_seq = uart_error_seq::type_id::create("uart_err_seq");
        interconnect_error_seq  ic_err_seq   = interconnect_error_seq::type_id::create("ic_err_seq");

        `uvm_info("SOC_ERR_VSEQ", "Executing Fault Injection & Isolation Sequence", UVM_LOW)
        fork
            uart_err_seq.start(p_sequencer.uart_seqr);
            ic_err_seq.start(p_sequencer.interconnect_seqr);
        join
        `uvm_info("SOC_ERR_VSEQ", "Fault Injection & Isolation Sequence Completed", UVM_LOW)
    endtask

endclass : soc_error_vseq

// Virtual Sequence 4: Boundary & Thermal Stress Profile Sequence
class soc_boundary_vseq extends soc_base_vseq;

    `uvm_object_utils(soc_boundary_vseq)

    function new(string name = "soc_boundary_vseq");
        super.new(name);
    endfunction

    virtual task body();
        spi_sensor_profile_seq spi_seq;

        `uvm_info("SOC_BOUND_VSEQ", "Executing Scenario B: Thermal Boundary & Emergency Stress", UVM_LOW)

        // Run SPI multi-tier temperature sequence (25 C -> 30 C -> 50 C -> 130 C)
        spi_seq = spi_sensor_profile_seq::type_id::create("spi_seq");
        spi_seq.start(p_sequencer.spi_seqr);

        `uvm_info("SOC_BOUND_VSEQ", "Scenario B: Thermal Boundary & Emergency Stress Completed", UVM_LOW)
    endtask

endclass : soc_boundary_vseq

// Virtual Sequence 5: Full Multi-Scenario Regression Sequence
class soc_full_regression_vseq extends soc_base_vseq;

    `uvm_object_utils(soc_full_regression_vseq)

    function new(string name = "soc_full_regression_vseq");
        super.new(name);
    endfunction

    virtual task body();
        soc_normal_vseq     normal_vseq;
        soc_boundary_vseq   bound_vseq;
        soc_concurrent_vseq concur_vseq;
        soc_error_vseq      err_vseq;

        `uvm_info("SOC_FULL_REG_VSEQ", "==================================================", UVM_LOW)
        `uvm_info("SOC_FULL_REG_VSEQ", " STARTING COMPREHENSIVE MULTI-SCENARIO REGRESSION ", UVM_LOW)
        `uvm_info("SOC_FULL_REG_VSEQ", "==================================================", UVM_LOW)

        // Phase 1: Normal Operation
        `uvm_info("SOC_FULL_REG_VSEQ", "[REGRESSION PHASE 1] Normal Operating Mode Bring-up", UVM_LOW)
        normal_vseq = soc_normal_vseq::type_id::create("normal_vseq");
        normal_vseq.start(p_sequencer);

        // Phase 2: Thermal Boundary & Stress
        `uvm_info("SOC_FULL_REG_VSEQ", "[REGRESSION PHASE 2] Thermal Boundary & Emergency Stress", UVM_LOW)
        bound_vseq = soc_boundary_vseq::type_id::create("bound_vseq");
        bound_vseq.start(p_sequencer);

        // Phase 3: Concurrent Multi-Peripheral Stimulation
        `uvm_info("SOC_FULL_REG_VSEQ", "[REGRESSION PHASE 3] Concurrent Multi-Peripheral Stimulation", UVM_LOW)
        concur_vseq = soc_concurrent_vseq::type_id::create("concur_vseq");
        concur_vseq.start(p_sequencer);

        // Phase 4: Fault Injection & Isolation
        `uvm_info("SOC_FULL_REG_VSEQ", "[REGRESSION PHASE 4] Fault Injection & Guard Isolation", UVM_LOW)
        err_vseq = soc_error_vseq::type_id::create("err_vseq");
        err_vseq.start(p_sequencer);

        `uvm_info("SOC_FULL_REG_VSEQ", "==================================================", UVM_LOW)
        `uvm_info("SOC_FULL_REG_VSEQ", " COMPREHENSIVE MULTI-SCENARIO REGRESSION COMPLETE ", UVM_LOW)
        `uvm_info("SOC_FULL_REG_VSEQ", "==================================================", UVM_LOW)
    endtask

endclass : soc_full_regression_vseq

`endif // SOC_VIRTUAL_SEQUENCES_SV
