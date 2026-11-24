# UVM Environment Pre-Cleanup Inventory Report

- **Date:** Sat Nov 7 14:17:00 IST 2026
- **Project Root:** `/home/student/Documents/078_H/proj_dir/`
- **UVM Environment Root:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`
- **Target DUT:** `soc_veer_el2_temperature_fan_top` (VeeR EL2 RV32IMC + 2x8 AXI4 Crossbar + Peripherals)
- **Backup Location:** `/home/student/Documents/078_H/proj_dir/uvm_soc/backup_uvm_pre_selfcheck/`

---

## 1. Directory Structure Inventory

The pre-cleanup UVM environment consists of the following primary directories:

| Directory | Description | Status |
|:---|:---|:---:|
| `agents/` | 7 UVM VIP agents (display, gpio, interconnect, pwm, spi, timer, uart) | Active / Production |
| `assertions/` | 7 concurrent SVA assertion modules binding to interface wires | Active / Production |
| `coverage/` | 7 functional coverage subscribers collecting cross-coverage | Active / Production |
| `env/` | Master SoC environment, configuration, virtual sequencer, core monitor | Active / Production |
| `reference_models/` | Reserved directory for analytical reference models | Preserved |
| `reports/` | Detailed verification reports and test audits | Active Documentation |
| `rtl_if/` | 8 SystemVerilog virtual interfaces connecting static DUT to dynamic classes | Active / Production |
| `run/` | VCS compilation scripts, filelists, simulation logs, FSDB waveforms | Active Execution |
| `scoreboards/` | 8 UVM scoreboards (subsystem-level + closed-loop system scoreboard) | Active / Production |
| `tb/` | Top-level module `tb_riscv_soc_uvm.sv` and package `soc_pkg.sv` | Active / Production |
| `tests/` | 22 baseline regression tests + 5 audit tests (27 total tests) | Active / Production |

---

## 2. File Inventory by Subsystem

### 2.1 Top-Level & Environment
- `tb/tb_riscv_soc_uvm.sv`: Static testbench top instantiating DUT, clock, reset, interface bindings, and `uvm_config_db::set`.
- `tb/soc_pkg.sv`: Root package compiling all items, drivers, monitors, agents, scoreboards, and tests.
- `env/soc_config.sv`: Configuration object setting active/passive modes for VIP agents.
- `env/soc_env.sv`: Master environment wiring analysis ports, virtual sequencer, and scoreboards.
- `env/soc_virtual_sequencer.sv`: Coordinates multi-agent stimulus sequences.
- `env/soc_virtual_sequences.sv`: System-level closed-loop and concurrent sequences.
- `env/veer_core_monitor.sv`: Passive monitor tracking instruction retirement, PC, and interrupt traps.

### 2.2 Subsystem VIP Agents (`agents/`)
- **GPIO:** `gpio_seq_item.sv`, `gpio_sequencer.sv`, `gpio_driver.sv`, `gpio_monitor.sv`, `gpio_agent.sv`, `gpio_sequence.sv`.
- **UART:** `uart_seq_item.sv`, `uart_sequencer.sv`, `uart_driver.sv`, `uart_monitor.sv`, `uart_agent.sv`, `uart_sequence.sv`.
- **SPI:** `spi_seq_item.sv`, `spi_sequencer.sv`, `spi_driver.sv`, `spi_monitor.sv`, `spi_agent.sv`, `spi_sequence.sv`.
- **Timer:** `timer_seq_item.sv`, `timer_sequencer.sv`, `timer_driver.sv`, `timer_monitor.sv`, `timer_agent.sv`, `timer_sequence.sv`.
- **PWM:** `pwm_seq_item.sv`, `pwm_monitor.sv`, `pwm_agent.sv` (Passive output monitor).
- **Display:** `display_seq_item.sv`, `display_monitor.sv`, `display_agent.sv` (Passive output monitor).
- **Interconnect:** `interconnect_seq_item.sv`, `interconnect_sequencer.sv`, `interconnect_driver.sv`, `interconnect_monitor.sv`, `interconnect_agent.sv`, `interconnect_sequence.sv`.

### 2.3 SystemVerilog Interfaces (`rtl_if/`)
- `gpio_uvm_if.sv`
- `uart_uvm_if.sv`
- `spi_uvm_if.sv`
- `timer_uvm_if.sv`
- `pwm_uvm_if.sv`
- `display_uvm_if.sv`
- `interconnect_uvm_if.sv`
- `veer_trace_uvm_if.sv`

### 2.4 Scoreboards (`scoreboards/`)
- `gpio_scoreboard.sv`
- `uart_scoreboard.sv`
- `spi_scoreboard.sv`
- `timer_scoreboard.sv`
- `pwm_scoreboard.sv`
- `display_scoreboard.sv`
- `interconnect_scoreboard.sv`
- `soc_system_scoreboard.sv`

### 2.5 Test Suite (`tests/`)
- `soc_base_test.sv`: Base test with topology printing, drain time, and error reporting.
- `soc_peripheral_tests.sv`: Tests 1–13 (Reset, GPIO, UART, SPI, Timer, PWM, 7-Segment).
- `soc_interconnect_tests.sv`: Tests 14–17 (AXI RW, Decode Sweep, Error isolation, Memory).
- `soc_system_tests.sv`: Tests 18–22 (CPU Boot, Normal thermal, Boundary thermal, Concurrent, Full regression).
- `soc_audit_tests.sv`: Dedicated 5 audit tests (PWM modulation, Display multiplexing, Timer IRQ, AXI clean sweep, Thermal sweep).

---

## 3. Read-Only Production Assets Protection

The following project directories remain strictly read-only and will NOT be modified:
1. `rtl/` (Synthesizable RTL for VeeR EL2 core, AXI crossbar, unified memory, and peripherals)
2. `firmware/` (Production binary images, e.g., `temperature_fan_words.hex`)
3. `tb/` (Baseline non-UVM testbenches)
4. `run/` (Baseline root simulation scripts)

All UVM enhancements and verification files reside strictly inside `uvm_soc/`.
