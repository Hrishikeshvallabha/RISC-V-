// ============================================================================
// File: soc_env.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Master SoC environment instantiating and wiring all 7 VIP agents,
//              virtual sequencer, monitors, individual scoreboards, system
//              closed-loop scoreboard, and functional coverage collectors.
// ============================================================================

`ifndef SOC_ENV_SV
`define SOC_ENV_SV

class soc_env extends uvm_env;

    `uvm_component_utils(soc_env)

    // Configuration
    soc_config cfg;

    // Subsystem VIP Agents
    gpio_agent         gpio_agnt;
    uart_agent         uart_agnt;
    spi_agent          spi_agnt;
    timer_agent        timer_agnt;
    pwm_agent          pwm_agnt;
    display_agent      display_agnt;
    interconnect_agent interconnect_agnt;

    // Virtual Sequencer
    soc_virtual_sequencer vseqr;

    // Passive Core Monitor
    veer_core_monitor  core_mon;

    // Subsystem Scoreboards
    gpio_scoreboard         gpio_scb;
    uart_scoreboard         uart_scb;
    spi_scoreboard          spi_scb;
    timer_scoreboard        timer_scb;
    pwm_scoreboard          pwm_scb;
    display_scoreboard      display_scb;
    interconnect_scoreboard interconnect_scb;

    // Closed-Loop System Scoreboard
    soc_system_scoreboard   system_scb;

    // Functional Coverage Collectors
    gpio_coverage         gpio_cov;
    uart_coverage         uart_cov;
    spi_coverage          spi_cov;
    timer_coverage        timer_cov;
    pwm_coverage          pwm_cov;
    display_coverage      display_cov;
    interconnect_coverage interconnect_cov;

    function new(string name = "soc_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(soc_config)::get(this, "", "soc_cfg", cfg)) begin
            `uvm_info("SOC_ENV", "soc_config not found in config_db; creating default instance", UVM_MEDIUM)
            cfg = soc_config::type_id::create("cfg");
        end

        // Pass down agent active/passive modes
        uvm_config_db#(uvm_active_passive_enum)::set(this, "gpio_agnt",         "is_active", cfg.gpio_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "uart_agnt",         "is_active", cfg.uart_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "spi_agnt",          "is_active", cfg.spi_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "timer_agnt",        "is_active", cfg.timer_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "pwm_agnt",          "is_active", cfg.pwm_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "display_agnt",      "is_active", cfg.display_is_active);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "interconnect_agnt", "is_active", cfg.interconnect_is_active);

        // Instantiate Agents
        gpio_agnt         = gpio_agent::type_id::create("gpio_agnt", this);
        uart_agnt         = uart_agent::type_id::create("uart_agnt", this);
        spi_agnt          = spi_agent::type_id::create("spi_agnt", this);
        timer_agnt        = timer_agent::type_id::create("timer_agnt", this);
        pwm_agnt          = pwm_agent::type_id::create("pwm_agnt", this);
        display_agnt      = display_agent::type_id::create("display_agnt", this);
        interconnect_agnt = interconnect_agent::type_id::create("interconnect_agnt", this);

        // Instantiate Virtual Sequencer
        vseqr = soc_virtual_sequencer::type_id::create("vseqr", this);

        // Instantiate Core Monitor
        core_mon = veer_core_monitor::type_id::create("core_mon", this);

        // Instantiate Scoreboards
        gpio_scb         = gpio_scoreboard::type_id::create("gpio_scb", this);
        uart_scb         = uart_scoreboard::type_id::create("uart_scb", this);
        spi_scb          = spi_scoreboard::type_id::create("spi_scb", this);
        timer_scb        = timer_scoreboard::type_id::create("timer_scb", this);
        pwm_scb          = pwm_scoreboard::type_id::create("pwm_scb", this);
        display_scb      = display_scoreboard::type_id::create("display_scb", this);
        interconnect_scb = interconnect_scoreboard::type_id::create("interconnect_scb", this);
        system_scb       = soc_system_scoreboard::type_id::create("system_scb", this);

        // Instantiate Coverage Collectors
        gpio_cov         = gpio_coverage::type_id::create("gpio_cov", this);
        uart_cov         = uart_coverage::type_id::create("uart_cov", this);
        spi_cov          = spi_coverage::type_id::create("spi_cov", this);
        timer_cov        = timer_coverage::type_id::create("timer_cov", this);
        pwm_cov          = pwm_coverage::type_id::create("pwm_cov", this);
        display_cov      = display_coverage::type_id::create("display_cov", this);
        interconnect_cov = interconnect_coverage::type_id::create("interconnect_cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // 1. Connect Virtual Sequencer sub-handles
        if (cfg.gpio_is_active == UVM_ACTIVE)
            vseqr.gpio_seqr = gpio_agnt.seqr;
        if (cfg.uart_is_active == UVM_ACTIVE)
            vseqr.uart_seqr = uart_agnt.seqr;
        if (cfg.spi_is_active == UVM_ACTIVE)
            vseqr.spi_seqr = spi_agnt.seqr;
        if (cfg.timer_is_active == UVM_ACTIVE)
            vseqr.timer_seqr = timer_agnt.seqr;
        if (cfg.interconnect_is_active == UVM_ACTIVE)
            vseqr.interconnect_seqr = interconnect_agnt.seqr;

        // 2. Connect Subsystem Scoreboards
        if (cfg.gpio_is_active == UVM_ACTIVE)
            gpio_agnt.drv_ap.connect(gpio_scb.exp_export);
        gpio_agnt.ap.connect(gpio_scb.item_export);

        if (cfg.uart_is_active == UVM_ACTIVE)
            uart_agnt.drv_ap.connect(uart_scb.exp_rx_export);
        uart_agnt.tx_ap.connect(uart_scb.tx_export);
        uart_agnt.rx_ap.connect(uart_scb.rx_export);

        if (cfg.spi_is_active == UVM_ACTIVE)
            spi_agnt.drv_ap.connect(spi_scb.exp_export);
        spi_agnt.ap.connect(spi_scb.item_export);

        if (cfg.timer_is_active == UVM_ACTIVE)
            timer_agnt.drv_ap.connect(timer_scb.exp_export);
        timer_agnt.ap.connect(timer_scb.item_export);

        interconnect_agnt.ap.connect(pwm_scb.axi_export);
        pwm_agnt.ap.connect(pwm_scb.item_export);

        interconnect_agnt.ap.connect(display_scb.axi_export);
        display_agnt.ap.connect(display_scb.item_export);

        if (cfg.interconnect_is_active == UVM_ACTIVE)
            interconnect_agnt.drv_ap.connect(interconnect_scb.exp_export);
        interconnect_agnt.ap.connect(interconnect_scb.item_export);

        // 3. Connect Closed-Loop System Scoreboard
        spi_agnt.ap.connect(system_scb.spi_export);
        pwm_agnt.ap.connect(system_scb.pwm_export);
        display_agnt.ap.connect(system_scb.disp_export);
        interconnect_agnt.ap.connect(system_scb.axi_export);
        uart_agnt.tx_ap.connect(system_scb.uart_export);

        // 4. Connect Coverage Collectors
        gpio_agnt.ap.connect(gpio_cov.analysis_export);
        uart_agnt.tx_ap.connect(uart_cov.analysis_export);
        spi_agnt.ap.connect(spi_cov.analysis_export);
        timer_agnt.ap.connect(timer_cov.analysis_export);
        pwm_agnt.ap.connect(pwm_cov.analysis_export);
        display_agnt.ap.connect(display_cov.analysis_export);
        interconnect_agnt.ap.connect(interconnect_cov.analysis_export);
    endfunction

endclass : soc_env

`endif // SOC_ENV_SV
