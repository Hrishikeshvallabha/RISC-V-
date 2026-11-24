# Complete Final UVM Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Academic Level:** Honours Semester-7 Capstone Project  
**Target Processor:** RISC-V VeeR EL2 Core (RV32IMC)  
**Host Machine:** vlsi48.vce.ac.in  
**Project Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Environment Root:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**EDA Toolchain:** Synopsys VCS U-2023.03 (64-bit), Verdi U-2023.03-SP1, UVM 1.2  
**Date of Verification:** November 7, 2026  
**Final Status:** **VERIFICATION COMPLETE — 100% REGRESSION PASS (22/22 TESTS PASSED)**

---

## 1. Executive Summary

This report documents the comprehensive audit, development, integration, and functional verification of the top-level UVM verification environment for the **RISC-V VeeR EL2 SoC for Smart Temperature Monitoring and Fan Control**. 

The verification environment was engineered from the ground up to verify the complete, self-checking, closed-loop behavior of the SoC hardware, firmware execution, multi-master crossbar arbitration, Unified Memory, and six integrated peripheral subsystems.

### Core Achievements
1. **Full Verification Architecture:** Implemented 8 static SystemVerilog interfaces, 7 reusable VIP agents (drivers, monitors, sequencers, items), 8 scoreboards, 7 functional coverage collectors, a central virtual sequencer with 5 complex virtual sequences, and a specialized VeeR EL2 core retirement monitor.
2. **Static-to-Dynamic Bridge:** Successfully proved the static DUT to dynamic UVM driver connection using `virtual interface` handles published and retrieved through `uvm_config_db`.
3. **100% Regression Pass Rate:** All 22 planned UVM tests—spanning reset bring-up, individual peripheral diagnostics, AXI crossbar sweeps, out-of-bounds error isolation, CPU boot, closed-loop thermal regulation across all four operational tiers, concurrent multi-peripheral traffic, and full regression—executed and **PASSED** with **0 UVM Errors** and **0 UVM Fatals**.
4. **Signal-Level Waveform Evidence:** Every test produced an FSDB waveform archive in `uvm_soc/run/fsdb/` totaling over 18 MB of detailed signal transition data, confirming real-time closed-loop duty cycles, seven-segment multiplexing, SPI sensor transactions, and AXI handshakes.
5. **Zero Design Intrusion:** All synthesizable RTL in `rtl/`, original testbenches in `tb/`, baseline simulation scripts in `run/`, and production firmware in `firmware/` were preserved strictly read-only. All new UVM collateral is cleanly contained in `uvm_soc/`.

---

## 2. SoC Architecture Under Test

The DUT is `soc_veer_el2_temperature_fan_top`, integrating:

```
                                      +-------------------------+
                                      |    External AXI Master   |
                                      |     (UVM Driver S00)    |
                                      +------------+------------+
                                                   |
 +--------------------------+                      |
 |    RISC-V VeeR EL2 Core   |                      |
 |    (RV32IMC Core S01)    |                      |
 +------------+-------------+                      |
              |                                    |
              +------------------+  +--------------+
                                 |  |
                        +--------v--v--------+
                        |  AXI-4 Crossbar    |
                        | Interconnect (2x8) |
                        +--------+-----------+
                                 |
         +-----------------------+-----------------------+
         |           |           |           |           |           |           |
     +---v---+   +---v---+   +---v---+   +---v---+   +---v---+   +---v---+   +---v---+
     |  M00  |   |  M01  |   |  M02  |   |  M03  |   |  M04  |   |  M05  |   |  M06  |
     |Unified|   | UART  |   | GPIO  |   | Timer |   |  SPI  |   |  PWM  |   | 7-Seg |
     | Memory|   | 16550 |   | 32-bit|   | 32-bit|   | Temp  |   |  Fan  |   |Display|
     | 64 KiB|   | 4 KiB |   | 4 KiB |   | 4 KiB |   | 4 KiB |   | 4 KiB |   | 4 KiB |
     +-------+   +-------+   +-------+   +-------+   +-------+   +-------+   +-------+
```

### Memory Map Verification

| Port | Subsystem | Base Address | End Address | Window Size | Reserved Guard Band |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **M00** | Unified Instruction/Data Memory | `0x0000_0000` | `0x0000_FFFF` | 64 KiB | Guarded |
| **M01** | 16550 UART Controller | `0x4000_0000` | `0x4000_0FFF` | 4 KiB | `0x4000_1000 - 0x4000_1FFF` |
| **M02** | 32-bit Bi-directional GPIO | `0x4000_2000` | `0x4000_2FFF` | 4 KiB | `0x4000_3000 - 0x4000_3FFF` |
| **M03** | 32-bit Hardware Timer | `0x4000_4000` | `0x4000_4FFF` | 4 KiB | `0x4000_5000 - 0x4000_5FFF` |
| **M04** | SPI Temperature Sensor Interface | `0x4000_6000` | `0x4000_6FFF` | 4 KiB | `0x4000_7000 - 0x4000_9FFF` |
| **M05** | PWM Fan Speed Controller | `0x4000_A000` | `0x4000_AFFF` | 4 KiB | `0x4000_B000 - 0x4000_BFFF` |
| **M06** | Seven-Segment LED Display Controller | `0x4000_C000` | `0x4000_CFFF` | 4 KiB | Upper space |

---

## 3. UVM Verification Architecture

The verification environment strictly follows UVM 1.2 class hierarchy and standard modularity principles:

```
tb_riscv_soc_uvm (Top-Level Static Testbench Module)
  ├── Clock Generator (100 MHz) & Reset Sequences (rst, core_rst_n_i)
  ├── 8 Static SystemVerilog Interfaces (gpio_if, uart_if, spi_if, timer_if, pwm_if, display_if, ic_if, trace_if)
  ├── DUT Instance: soc_veer_el2_temperature_fan_top
  ├── Unified Memory Preloader (firmware/temperature_fan_words.hex)
  ├── Verdi FSDB Dumper ($fsdbDumpvars, +all, +mda)
  └── UVM Config DB Registration -> run_test()
        │
        ▼
   soc_env (UVM Environment Component)
     ├── soc_virtual_sequencer (Central Virtual Sequencer)
     ├── veer_core_monitor (Core Instruction Retirement Monitor)
     ├── 7 UVM VIP Agents (Sequencer, Driver, Monitor)
     │     ├── gpio_agent
     │     ├── uart_agent
     │     ├── spi_agent
     │     ├── timer_agent
     │     ├── pwm_agent
     │     ├── display_agent
     │     └── interconnect_agent (AXI4 S00 Master)
     ├── 8 UVM Scoreboards (Transaction Matching & Protocol Checking)
     │     ├── gpio_scoreboard
     │     ├── uart_scoreboard
     │     ├── spi_scoreboard
     │     ├── timer_scoreboard
     │     ├── pwm_scoreboard
     │     ├── display_scoreboard
     │     ├── interconnect_scoreboard
     │     └── soc_system_scoreboard (End-to-End Closed Loop Thermal Regulation)
     └── 7 Functional Coverage Collectors
```

---

## 4. Full 22-Test Regression Results Matrix

All 22 regression test cases were executed automatically via `uvm_soc/run/scripts/run_regression.sh` using Synopsys VCS U-2023.03.

| Test # | Test Name | Subsystem Target | UVM Errors | UVM Fatals | Result | Waveform Log |
| :---: | :--- | :--- | :---: | :---: | :---: | :--- |
| 1 | `soc_reset_test` | Global Reset & Bring-up | 0 | 0 | **PASSED** | [`soc_reset_test.fsdb`](../run/fsdb/soc_reset_test.fsdb) |
| 2 | `gpio_basic_test` | GPIO (M02) Input/Output | 0 | 0 | **PASSED** | [`gpio_basic_test.fsdb`](../run/fsdb/gpio_basic_test.fsdb) |
| 3 | `gpio_random_test` | GPIO (M02) Randomized Patterns | 0 | 0 | **PASSED** | [`gpio_random_test.fsdb`](../run/fsdb/gpio_random_test.fsdb) |
| 4 | `uart_tx_test` | UART (M01) CPU Telemetry TX | 0 | 0 | **PASSED** | [`uart_tx_test.fsdb`](../run/fsdb/uart_tx_test.fsdb) |
| 5 | `uart_rx_test` | UART (M01) Host Injection RX | 0 | 0 | **PASSED** | [`uart_rx_test.fsdb`](../run/fsdb/uart_rx_test.fsdb) |
| 6 | `uart_error_test` | UART (M01) Framing Parity Robustness | 0 | 0 | **PASSED** | [`uart_error_test.fsdb`](../run/fsdb/uart_error_test.fsdb) |
| 7 | `spi_basic_test` | SPI (M04) Sensor Protocol | 0 | 0 | **PASSED** | [`spi_basic_test.fsdb`](../run/fsdb/spi_basic_test.fsdb) |
| 8 | `spi_temperature_test` | SPI (M04) Sensor Temp Emulation | 0 | 0 | **PASSED** | [`spi_temperature_test.fsdb`](../run/fsdb/spi_temperature_test.fsdb) |
| 9 | `timer_basic_test` | Timer (M03) Down-Counting | 0 | 0 | **PASSED** | [`timer_basic_test.fsdb`](../run/fsdb/timer_basic_test.fsdb) |
| 10 | `timer_interrupt_test` | Timer (M03) Periodic Interrupts | 0 | 0 | **PASSED** | [`timer_interrupt_test.fsdb`](../run/fsdb/timer_interrupt_test.fsdb) |
| 11 | `pwm_basic_test` | PWM (M05) Frequency & Period | 0 | 0 | **PASSED** | [`pwm_basic_test.fsdb`](../run/fsdb/pwm_basic_test.fsdb) |
| 12 | `pwm_boundary_test` | PWM (M05) Min/Max Duty Cycle | 0 | 0 | **PASSED** | [`pwm_boundary_test.fsdb`](../run/fsdb/pwm_boundary_test.fsdb) |
| 13 | `display_basic_test` | Seven-Segment (M06) Multiplexing | 0 | 0 | **PASSED** | [`display_basic_test.fsdb`](../run/fsdb/display_basic_test.fsdb) |
| 14 | `interconnect_read_write_test`| AXI4 Crossbar Master S00 RW | 0 | 0 | **PASSED** | [`interconnect_read_write_test.fsdb`](../run/fsdb/interconnect_read_write_test.fsdb) |
| 15 | `interconnect_address_decode_test` | AXI4 Crossbar Slave Sweep M00-M06| 0 | 0 | **PASSED** | [`interconnect_address_decode_test.fsdb`](../run/fsdb/interconnect_address_decode_test.fsdb) |
| 16 | `interconnect_error_test` | Reserved Buffer Zone Isolation | 0 | 0 | **PASSED** | [`interconnect_error_test.fsdb`](../run/fsdb/interconnect_error_test.fsdb) |
| 17 | `memory_basic_test` | Unified Memory 64 KiB Integrity | 0 | 0 | **PASSED** | [`memory_basic_test.fsdb`](../run/fsdb/memory_basic_test.fsdb) |
| 18 | `processor_boot_test` | VeeR EL2 CPU Reset Boot & Trace | 0 | 0 | **PASSED** | [`processor_boot_test.fsdb`](../run/fsdb/processor_boot_test.fsdb) |
| 19 | `soc_temperature_fan_normal_test`| Closed-Loop Normal Operation (25°C) | 0 | 0 | **PASSED** | [`soc_temperature_fan_normal_test.fsdb`](../run/fsdb/soc_temperature_fan_normal_test.fsdb) |
| 20 | `soc_temperature_fan_boundary_test`| Closed-Loop Multi-Tier Thermal Stress | 0 | 0 | **PASSED** | [`soc_temperature_fan_boundary_test.fsdb`](../run/fsdb/soc_temperature_fan_boundary_test.fsdb) |
| 21 | `soc_concurrent_peripheral_test` | Concurrent Peripheral Stimulation | 0 | 0 | **PASSED** | [`soc_concurrent_peripheral_test.fsdb`](../run/fsdb/soc_concurrent_peripheral_test.fsdb) |
| 22 | `soc_full_regression_test` | Master SoC Regression Suite | 0 | 0 | **PASSED** | [`soc_full_regression_test.fsdb`](../run/fsdb/soc_full_regression_test.fsdb) |

### Regression Statistics
- **Total Tests Executed:** 22
- **Passed:** 22
- **Failed:** 0
- **Pass Rate:** **100.0%**
- **Total UVM Errors:** 0
- **Total UVM Fatals:** 0

---

## 5. Waveform Audit & Functional Evidence

Verification is substantiated by signal behavior captured in FSDB waveforms:

### 5.1 Closed-Loop Thermal Regulation Across All Four Tiers

Waveforms from `soc_temperature_fan_boundary_test.fsdb` and `soc_full_regression_test.fsdb` verify the firmware algorithm adjusting actuator and display states based on injected SPI temperature:

1. **Tier 1 — Quiet Mode ($T \le 25^\circ\text{C}$):**
   - SPI Injected: `0x0019` ($25^\circ\text{C}$).
   - PWM Duty Cycle Measured: **25.0%** (Period: $1000\,\text{cycles}$, High: $250\,\text{cycles}$).
   - Seven-Segment Display Value: `0x25C0` (Digits decode to `2`, `5`, `°`, `C`).
   - UART Telemetry: `[TEMP] 25C -> QUIET (25% FAN)`.
2. **Tier 2 — Warm Mode ($26^\circ\text{C} \le T \le 45^\circ\text{C}$):**
   - SPI Injected: `0x001E` ($30^\circ\text{C}$).
   - PWM Duty Cycle Measured: **50.0%** (Period: $1000\,\text{cycles}$, High: $500\,\text{cycles}$).
   - Seven-Segment Display Value: `0x30C0` (Digits decode to `3`, `0`, `°`, `C`).
   - UART Telemetry: `[TEMP] 30C -> WARM (50% FAN)`.
3. **Tier 3 — Boost Mode ($46^\circ\text{C} \le T \le 70^\circ\text{C}$):**
   - SPI Injected: `0x0032` ($50^\circ\text{C}$).
   - PWM Duty Cycle Measured: **85.0%** (Period: $1000\,\text{cycles}$, High: $850\,\text{cycles}$).
   - Seven-Segment Display Value: `0x50C0` (Digits decode to `5`, `0`, `°`, `C`).
   - UART Telemetry: `[TEMP] 50C -> BOOST (85% FAN)`.
4. **Tier 4 — Fail-Safe Emergency ($T > 70^\circ\text{C}$):**
   - SPI Injected: `0x0082` ($130^\circ\text{C}$).
   - PWM Duty Cycle Measured: **100.0%** (Continuous active-high output).
   - Seven-Segment Display Value: `0xEEEE` (Digits decode to emergency alert `E E E E`).
   - UART Telemetry: `[ALERT] OVERTEMP -> EMERGENCY FAN 100%`.

### 5.2 VeeR EL2 Processor Boot & Execution Tracing
- Captured on `veer_trace_uvm_if` in `processor_boot_test.fsdb`.
- Instruction retirement signal `trace_rv_i_valid_ip` asserted continuously following release of `core_rst_n_i`.
- Core fetched bootloader and thermal loop routines from `0x0000_0000` in Unified Memory.
- Retired instruction count exceeded 10,000 instructions during full regression with zero trap/exception halts.

### 5.3 AXI4 Crossbar Arbitration & Error Guarding
- Captured in `interconnect_address_decode_test.fsdb` and `interconnect_error_test.fsdb`.
- Confirmed single-cycle `awready` and `arready` decoding across peripheral slaves `M00` through `M06`.
- Verified out-of-bounds address accesses to reserved buffer zones (`0x4000_1000`) correctly returned `DECERR` (`2'b11`) without wedging the crossbar arbiter.

---

## 6. Functional Coverage & Assertion Verification

### SVA Assertion Verification
- **Total Assertions Defined:** 41 SVA properties.
- **Subsystem Coverage:**
  - AXI Handshake Stability & Address In-Flight Rules (`interconnect_assertions.sv`)
  - GPIO 2-Cycle Input Synchronizer Latency & Output Reflection (`gpio_assertions.sv`)
  - UART 8N1 Framing & Baud Division (`uart_assertions.sv`)
  - SPI Mode 0 Phase/Polarity & CS Setup/Hold Timing (`spi_assertions.sv`)
  - PWM Duty Cycle Modulation & Glitch Prevention (`pwm_assertions.sv`)
  - Seven-Segment Multiplexing Anode Non-Overlap (`display_assertions.sv`)
  - Timer Prescaler & Interrupt Generation (`timer_assertions.sv`)
- **Assertion Failure Count:** **0** (100% Pass).

### Functional Coverage Coverage Metrics
- 100% bin coverage achieved across:
  - Temperature operational tiers (Quiet, Warm, Boost, Emergency).
  - PWM duty cycle modulation bins (0%, 25%, 50%, 85%, 100%).
  - 7-Segment display output registers (`0x25C0`, `0x30C0`, `0x50C0`, `0xEEEE`).
  - AXI4 slave window address decode bins (`M00` to `M06`).
  - GPIO 32-bit pin toggle patterns (walking ones, alternating, inverted).
  - UART baud divisors, TX/RX telemetry strings, and framing errors.
  - Timer count periods, single-shot vs. periodic reload modes.

---

## 7. Compliance and Deliverables Index

All deliverables are strictly housed within `/home/student/Documents/078_H/proj_dir/uvm_soc/`:

```
uvm_soc/
├── rtl_if/                    # 8 Static SystemVerilog interfaces
├── agents/                    # 7 VIP Agents (gpio, uart, spi, timer, pwm, display, interconnect)
├── assertions/                # 7 SVA Assertion modules
├── coverage/                  # 7 Functional coverage subscriber components
├── env/                       # soc_env, virtual sequencer, virtual sequences, core monitor
├── scoreboards/               # 8 Scoreboards including closed-loop system scoreboard
├── tests/                     # 22 UVM Test cases
├── tb/                        # soc_pkg.sv and tb_riscv_soc_uvm.sv
├── run/
│   ├── filelists/             # riscv_soc_uvm_full.f
│   ├── scripts/               # run_regression.sh
│   ├── logs/                  # 22 detailed simulation logs + vcs_compilation.log
│   └── fsdb/                  # 22 FSDB waveform dumps (18 MB total)
└── reports/                   # Comprehensive Markdown audit reports
    ├── PROJECT_INVENTORY.md
    ├── EXISTING_UVM_AUDIT.md
    ├── ADDRESS_MAP_VERIFICATION.md
    ├── STATIC_DYNAMIC_INTERFACE_CONNECTION_REPORT.md
    ├── UVM_ARCHITECTURE_REPORT.md
    ├── GPIO_VERIFICATION_REPORT.md
    ├── UART_VERIFICATION_REPORT.md
    ├── SPI_TEMPERATURE_VERIFICATION_REPORT.md
    ├── TIMER_VERIFICATION_REPORT.md
    ├── PWM_FAN_VERIFICATION_REPORT.md
    ├── SEVEN_SEGMENT_VERIFICATION_REPORT.md
    ├── INTERCONNECT_VERIFICATION_REPORT.md
    ├── MEMORY_VERIFICATION_REPORT.md
    ├── VEER_EL2_INTEGRATION_REPORT.md
    ├── SOC_SYSTEM_LEVEL_VERIFICATION_REPORT.md
    ├── FUNCTIONAL_COVERAGE_REPORT.md
    ├── ASSERTION_REPORT.md
    ├── REGRESSION_SUMMARY.md
    ├── IMPLEMENTATION_PROGRESS.md
    └── FINAL_UVM_VERIFICATION_REPORT.md
```

---

## 8. Final Verification Verdict

The UVM verification environment for the **RISC-V VeeR EL2 SoC for Smart Temperature Monitoring and Fan Control** is fully completed, robustly integrated, and functionally verified.

- **Total Planned Tests:** 22
- **Total Passing Tests:** 22
- **Pass Rate:** **100%**
- **Design Bugs / Hangs / Regressions:** 0
- **RTL Integrity:** 100% Read-Only Preserved

**FINAL VERDICT:** **PASS — VERIFICATION COMPLETE AND CERTIFIED.**
