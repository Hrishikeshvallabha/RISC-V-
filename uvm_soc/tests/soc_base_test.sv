// ============================================================================
// File: soc_base_test.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Base test defining environment instantiation, phase management,
//              drain time configuration, and overall test reporting.
// ============================================================================

`ifndef SOC_BASE_TEST_SV
`define SOC_BASE_TEST_SV

class soc_base_test extends uvm_test;

    `uvm_component_utils(soc_base_test)

    soc_env    env;
    soc_config cfg;

    function new(string name = "soc_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = soc_config::type_id::create("cfg");
        configure_env();
        uvm_config_db#(soc_config)::set(this, "env", "soc_cfg", cfg);

        env = soc_env::type_id::create("env", this);
    endfunction

    virtual function void configure_env();
        // Default configuration: all active where supported
        cfg.gpio_is_active         = UVM_ACTIVE;
        cfg.uart_is_active         = UVM_ACTIVE;
        cfg.spi_is_active          = UVM_ACTIVE;
        cfg.timer_is_active        = UVM_ACTIVE;
        cfg.pwm_is_active          = UVM_PASSIVE;
        cfg.display_is_active      = UVM_PASSIVE;
        cfg.interconnect_is_active = UVM_ACTIVE;
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("SOC_BASE_TEST", "Topology elaboration completed. Test hierarchy:", UVM_MEDIUM)
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.phase_done.set_drain_time(this, 1000ns);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        int err_count = svr.get_severity_count(UVM_ERROR);
        int fatal_count = svr.get_severity_count(UVM_FATAL);

        super.report_phase(phase);

        `uvm_info(get_name(), "==================================================", UVM_LOW)
        `uvm_info(get_name(), $sformatf("           TEST REPORT: %s", get_name()), UVM_LOW)
        `uvm_info(get_name(), "==================================================", UVM_LOW)
        `uvm_info(get_name(), $sformatf(" UVM Errors: %0d", err_count), UVM_LOW)
        `uvm_info(get_name(), $sformatf(" UVM Fatals: %0d", fatal_count), UVM_LOW)
        if (err_count == 0 && fatal_count == 0) begin
            `uvm_info(get_name(), " >>> TEST STATUS: PASSED <<<", UVM_LOW)
        end else begin
            `uvm_error(get_name(), " >>> TEST STATUS: FAILED <<<")
        end
        `uvm_info(get_name(), "==================================================", UVM_LOW)
    endfunction

endclass : soc_base_test

`endif // SOC_BASE_TEST_SV
