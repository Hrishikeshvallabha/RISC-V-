// ============================================================================
// File: riscv_soc_env.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Top-level UVM environment instantiating the GPIO interface agent.
// ============================================================================

`ifndef RISCV_SOC_ENV_SV
`define RISCV_SOC_ENV_SV

class riscv_soc_env extends uvm_env;

    // Subsystem agents
    gpio_agent agent;

    `uvm_component_utils(riscv_soc_env)

    function new(string name = "riscv_soc_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("SOC_ENV", "Building riscv_soc_env: instantiating GPIO agent", UVM_LOW)
        agent = gpio_agent::type_id::create("agent", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("SOC_ENV", "Connecting riscv_soc_env components", UVM_LOW)
    endfunction

endclass : riscv_soc_env

`endif // RISCV_SOC_ENV_SV
