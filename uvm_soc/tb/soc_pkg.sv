// ============================================================================
// File: soc_pkg.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Master UVM package compiling and exporting all configuration
//              classes, items, sequencers, drivers, monitors, agents, scoreboards,
//              coverage subscribers, environments, virtual sequences, and tests.
// ============================================================================

`ifndef SOC_PKG_SV
`define SOC_PKG_SV

package soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Configuration Object
    `include "../env/soc_config.sv"

    // Sequence Items
    `include "../agents/gpio/gpio_seq_item.sv"
    `include "../agents/uart/uart_seq_item.sv"
    `include "../agents/spi/spi_seq_item.sv"
    `include "../agents/timer/timer_seq_item.sv"
    `include "../agents/pwm/pwm_seq_item.sv"
    `include "../agents/display/display_seq_item.sv"
    `include "../agents/interconnect/interconnect_seq_item.sv"

    // Sequencers & Drivers
    `include "../agents/gpio/gpio_sequencer.sv"
    `include "../agents/gpio/gpio_driver.sv"
    `include "../agents/uart/uart_sequencer.sv"
    `include "../agents/uart/uart_driver.sv"
    `include "../agents/spi/spi_sequencer.sv"
    `include "../agents/spi/spi_driver.sv"
    `include "../agents/timer/timer_sequencer.sv"
    `include "../agents/timer/timer_driver.sv"
    `include "../agents/interconnect/interconnect_sequencer.sv"
    `include "../agents/interconnect/interconnect_driver.sv"

    // Monitors
    `include "../agents/gpio/gpio_monitor.sv"
    `include "../agents/uart/uart_monitor.sv"
    `include "../agents/spi/spi_monitor.sv"
    `include "../agents/timer/timer_monitor.sv"
    `include "../agents/pwm/pwm_monitor.sv"
    `include "../agents/display/display_monitor.sv"
    `include "../agents/interconnect/interconnect_monitor.sv"
    `include "../env/veer_core_monitor.sv"

    // Sequences
    `include "../agents/gpio/gpio_sequence.sv"
    `include "../agents/uart/uart_sequence.sv"
    `include "../agents/spi/spi_sequence.sv"
    `include "../agents/timer/timer_sequence.sv"
    `include "../agents/interconnect/interconnect_sequence.sv"

    // Agents
    `include "../agents/gpio/gpio_agent.sv"
    `include "../agents/uart/uart_agent.sv"
    `include "../agents/spi/spi_agent.sv"
    `include "../agents/timer/timer_agent.sv"
    `include "../agents/pwm/pwm_agent.sv"
    `include "../agents/display/display_agent.sv"
    `include "../agents/interconnect/interconnect_agent.sv"

    // Scoreboards
    `include "../scoreboards/gpio_scoreboard.sv"
    `include "../scoreboards/uart_scoreboard.sv"
    `include "../scoreboards/spi_scoreboard.sv"
    `include "../scoreboards/timer_scoreboard.sv"
    `include "../scoreboards/pwm_scoreboard.sv"
    `include "../scoreboards/display_scoreboard.sv"
    `include "../scoreboards/interconnect_scoreboard.sv"
    `include "../scoreboards/soc_system_scoreboard.sv"

    // Functional Coverage Collectors
    `include "../coverage/gpio_coverage.sv"
    `include "../coverage/uart_coverage.sv"
    `include "../coverage/spi_coverage.sv"
    `include "../coverage/timer_coverage.sv"
    `include "../coverage/pwm_coverage.sv"
    `include "../coverage/display_coverage.sv"
    `include "../coverage/interconnect_coverage.sv"

    // Virtual Sequencer & Virtual Sequences
    `include "../env/soc_virtual_sequencer.sv"
    `include "../env/soc_virtual_sequences.sv"

    // Master Environment
    `include "../env/soc_env.sv"

    // Test Suite
    `include "../tests/soc_base_test.sv"
    `include "../tests/soc_peripheral_tests.sv"
    `include "../tests/soc_interconnect_tests.sv"
    `include "../tests/soc_system_tests.sv"
    `include "../tests/soc_audit_tests.sv"

endpackage : soc_pkg

`endif // SOC_PKG_SV
