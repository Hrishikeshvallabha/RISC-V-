// ============================================================================
// File: soc_config.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Configuration object controlling VIP agent modes and parameters.
// ============================================================================

`ifndef SOC_CONFIG_SV
`define SOC_CONFIG_SV

class soc_config extends uvm_object;

    // Agent active/passive modes
    uvm_active_passive_enum gpio_is_active         = UVM_ACTIVE;
    uvm_active_passive_enum uart_is_active         = UVM_ACTIVE;
    uvm_active_passive_enum spi_is_active          = UVM_ACTIVE;
    uvm_active_passive_enum timer_is_active        = UVM_ACTIVE;
    uvm_active_passive_enum pwm_is_active          = UVM_PASSIVE;
    uvm_active_passive_enum display_is_active      = UVM_PASSIVE;
    uvm_active_passive_enum interconnect_is_active = UVM_ACTIVE;

    // Simulation configuration
    bit enable_firmware_preload = 1'b1;
    int system_clock_period_ns  = 10;
    int uart_baud_divisor       = 4;

    `uvm_object_utils_begin(soc_config)
        `uvm_field_enum(uvm_active_passive_enum, gpio_is_active, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, uart_is_active, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, spi_is_active, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, timer_is_active, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, pwm_is_active, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, display_is_active, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, interconnect_is_active, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "soc_config");
        super.new(name);
    endfunction

endclass : soc_config

`endif // SOC_CONFIG_SV
