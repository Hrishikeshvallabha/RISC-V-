// ============================================================================
// File: riscv_soc_pkg.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Master UVM package aggregating sequence items, sequences,
//              sequencer, driver, agent, environment, and test components.
// ============================================================================

package riscv_soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Agent components
    `include "agents/gpio_agent/gpio_seq_item.sv"
    `include "agents/gpio_agent/gpio_sequencer.sv"
    `include "agents/gpio_agent/gpio_sequence.sv"
    `include "agents/gpio_agent/gpio_driver.sv"
    `include "agents/gpio_agent/gpio_agent.sv"

    // Environment and Test components
    `include "env/riscv_soc_env.sv"
    `include "tests/riscv_soc_test.sv"

endpackage : riscv_soc_pkg
