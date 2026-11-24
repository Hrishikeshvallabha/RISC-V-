# RISC-V VeeR EL2 SoC UVM Verification Environment: Implementation Progress

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Host & Date:** vlsi48.vce.ac.in | November 7, 2026  
**Project Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Environment Root:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Simulator / Toolchain:** Synopsys VCS U-2023.03 (64-bit), Verdi U-2023.03-SP1, UVM 1.2  

---

## Chronological Phase Milestones Log

### Phase 0: Project Inspection, Structural Inventory & Baseline Audit
- **Status:** **COMPLETE**
- **Artifacts:** [`PROJECT_INVENTORY.md`](./PROJECT_INVENTORY.md), [`EXISTING_UVM_AUDIT.md`](./EXISTING_UVM_AUDIT.md)
- **Details:**
  - Audited full SoC RTL hierarchy (`rtl/soc_veer_el2_temperature_fan_top.sv`).
  - Identified VeeR EL2 RV32IMC core, 2x8 AXI4 crossbar interconnect (`axi_interconnect_wrap_2x8`), Unified 64 KiB SRAM, and 6 peripherals (UART, GPIO, Timer, SPI, PWM, Seven-Segment display).
  - Enforced strict preservation policies: synthesizable RTL, firmware hex, and baseline testbenches in `rtl/`, `firmware/`, `tb/`, and `run/` marked strictly READ-ONLY.
  - Established dedicated verification directory: `/home/student/Documents/078_H/proj_dir/uvm_soc/`.

---

### Phase 1: SoC Memory Map & Register Address Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`ADDRESS_MAP_VERIFICATION.md`](./ADDRESS_MAP_VERIFICATION.md)
- **Details:**
  - Correlated hardware decode masks in `soc_veer_el2_temperature_fan_top.sv` against memory map specifications.
  - Verified slave address windows:
    - `M00` Unified RAM: `0x0000_0000 - 0x0000_FFFF` (64 KiB)
    - `M01` UART: `0x4000_0000 - 0x4000_0FFF` (4 KiB)
    - `M02` GPIO: `0x4000_2000 - 0x4000_2FFF` (4 KiB)
    - `M03` Timer: `0x4000_4000 - 0x4000_4FFF` (4 KiB)
    - `M04` SPI: `0x4000_6000 - 0x4000_6FFF` (4 KiB)
    - `M05` PWM: `0x4000_A000 - 0x4000_AFFF` (4 KiB)
    - `M06` Seven-Segment: `0x4000_C000 - 0x4000_CFFF` (4 KiB)
  - Confirmed 4 KiB reserved buffer isolation guard bands between peripheral windows.

---

### Phase 2: Static Interfaces & Virtual Interface Connection Bridge
- **Status:** **COMPLETE**
- **Artifacts:** [`STATIC_DYNAMIC_INTERFACE_CONNECTION_REPORT.md`](./STATIC_DYNAMIC_INTERFACE_CONNECTION_REPORT.md), `uvm_soc/rtl_if/*.sv`
- **Details:**
  - Authored 8 static SystemVerilog interfaces: `gpio_uvm_if`, `uart_uvm_if`, `spi_uvm_if`, `timer_uvm_if`, `pwm_uvm_if`, `display_uvm_if`, `interconnect_uvm_if`, and `veer_trace_uvm_if`.
  - Registered all interfaces in `uvm_config_db #(virtual ...)::set()` at top-level testbench (`tb_riscv_soc_uvm.sv`).
  - Connected UVM drivers and monitors via `uvm_config_db #(virtual ...)::get()` during `build_phase()`.

---

### Phase 3: GPIO VIP Agent & Functional Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`GPIO_VERIFICATION_REPORT.md`](./GPIO_VERIFICATION_REPORT.md), `uvm_soc/agents/gpio/`, `uvm_soc/assertions/gpio_assertions.sv`
- **Details:**
  - Implemented 32-bit GPIO UVM agent with driver, monitor, sequencer, and sequence items.
  - Verified input pin synchronization, output pin driving, and interrupt generation.
  - Resolved SVA latency evaluation with local variable state capture in `gpio_assertions.sv`.
  - Executed and passed `gpio_basic_test` and `gpio_random_test`.

---

### Phase 4: UART Telemetry VIP Agent & Protocol Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`UART_VERIFICATION_REPORT.md`](./UART_VERIFICATION_REPORT.md), `uvm_soc/agents/uart/`, `uvm_soc/assertions/uart_assertions.sv`
- **Details:**
  - Built 16550 UART VIP agent supporting 115200 baud 8N1 serial framing.
  - Monitor captures CPU firmware ASCII telemetry messages (`[TEMP] ...`, `[ALERT] ...`).
  - Driver supports host-to-SoC command injection.
  - Executed and passed `uart_tx_test`, `uart_rx_test`, and `uart_error_test`.

---

### Phase 5: SPI Temperature Sensor VIP Agent & Emulation
- **Status:** **COMPLETE**
- **Artifacts:** [`SPI_TEMPERATURE_VERIFICATION_REPORT.md`](./SPI_TEMPERATURE_VERIFICATION_REPORT.md), `uvm_soc/agents/spi/`, `uvm_soc/assertions/spi_assertions.sv`
- **Details:**
  - Built SPI Agent operating in sensor emulation mode (SPI Mode 0: CPOL=0, CPHA=0).
  - Injects realistic 16-bit 2's complement temperature words ($25^\circ\text{C}$, $30^\circ\text{C}$, $50^\circ\text{C}$, $130^\circ\text{C}$).
  - Executed and passed `spi_basic_test` and `spi_temperature_test`.

---

### Phase 6: Hardware Timer VIP Agent & Interrupt Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`TIMER_VERIFICATION_REPORT.md`](./TIMER_VERIFICATION_REPORT.md), `uvm_soc/agents/timer/`, `uvm_soc/assertions/timer_assertions.sv`
- **Details:**
  - Built Timer UVM Agent with external clock gating, capture inputs, and interrupt observation.
  - Verified down-counter behavior, period match interrupts, and prescaler divisors.
  - Executed and passed `timer_basic_test` and `timer_interrupt_test`.

---

### Phase 7: PWM Fan Actuator VIP Agent & Duty Cycle Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`PWM_FAN_VERIFICATION_REPORT.md`](./PWM_FAN_VERIFICATION_REPORT.md), `uvm_soc/agents/pwm/`, `uvm_soc/assertions/pwm_assertions.sv`
- **Details:**
  - Built PWM monitor tracking duty cycle percentages with high-precision timestamp math.
  - Validated 25%, 50%, 85%, and 100% duty cycle configurations.
  - Executed and passed `pwm_basic_test` and `pwm_boundary_test`.

---

### Phase 8: Seven-Segment Display VIP Agent & Multiplexing Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`SEVEN_SEGMENT_VERIFICATION_REPORT.md`](./SEVEN_SEGMENT_VERIFICATION_REPORT.md), `uvm_soc/agents/display/`, `uvm_soc/assertions/display_assertions.sv`
- **Details:**
  - Built 4-digit Seven-Segment display monitor decoding anode refresh multiplexing and cathode segment encoding.
  - Verified real-time temperature display decode (`0x25C0`, `0x30C0`, `0x50C0`) and emergency alert decode (`0xEEEE`).
  - Executed and passed `display_basic_test`.

---

### Phase 9: AXI4 Crossbar Interconnect VIP & Arbitration Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`INTERCONNECT_VERIFICATION_REPORT.md`](./INTERCONNECT_VERIFICATION_REPORT.md), `uvm_soc/agents/interconnect/`, `uvm_soc/assertions/interconnect_assertions.sv`
- **Details:**
  - Built AXI4 Master S00 agent driving concurrent address, write, read, and response channels.
  - Resolved single-cycle ready pulse alignment in `interconnect_driver.sv`.
  - Executed and passed `interconnect_read_write_test`, `interconnect_address_decode_test`, and `interconnect_error_test`.

---

### Phase 10: Unified Memory VIP & Memory Range Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`MEMORY_VERIFICATION_REPORT.md`](./MEMORY_VERIFICATION_REPORT.md), `uvm_soc/tests/soc_interconnect_tests.sv`
- **Details:**
  - Verified 64 KiB Unified Memory byte enables (`wstrb`), contiguous reads/writes, and zero data corruption.
  - Executed and passed `memory_basic_test`.

---

### Phase 11: VeeR EL2 Processor Integration & Execution Tracing
- **Status:** **COMPLETE**
- **Artifacts:** [`VEER_EL2_INTEGRATION_REPORT.md`](./VEER_EL2_INTEGRATION_REPORT.md), `uvm_soc/env/veer_core_monitor.sv`
- **Details:**
  - Monitored core trace interface (`trace_rv_i_insn_ip`, `trace_rv_i_address_ip`, `trace_rv_i_valid_ip`).
  - Tracked instruction retirement counter to ensure robust boot from reset vector `0x0000_0000`.
  - Executed and passed `processor_boot_test`.

---

### Phase 12-16: Virtual Sequencer & Multi-Agent Virtual Sequences
- **Status:** **COMPLETE**
- **Artifacts:** `uvm_soc/env/soc_virtual_sequencer.sv`, `uvm_soc/env/soc_virtual_sequences.sv`
- **Details:**
  - Integrated central `soc_virtual_sequencer` coordinating all 7 subsystem sequencers.
  - Authored `soc_normal_vseq`, `soc_boundary_vseq`, `soc_concurrent_vseq`, `soc_error_vseq`, and `soc_full_regression_vseq`.

---

### Phase 17: Closed-Loop System Scoreboard & Thermal Policy Verification
- **Status:** **COMPLETE**
- **Artifacts:** [`SOC_SYSTEM_LEVEL_VERIFICATION_REPORT.md`](./SOC_SYSTEM_LEVEL_VERIFICATION_REPORT.md), `uvm_soc/scoreboards/soc_system_scoreboard.sv`
- **Details:**
  - Implemented real-time tracking of SPI injected temperature and corresponding PWM duty cycle and 7-segment display status.
  - Verified Tier 1 (Quiet), Tier 2 (Warm), Tier 3 (Boost), and Tier 4 (Fail-Safe Emergency).

---

### Phase 18: System Assertions & Protocol Rule Checks
- **Status:** **COMPLETE**
- **Artifacts:** [`ASSERTION_REPORT.md`](./ASSERTION_REPORT.md), `uvm_soc/assertions/*.sv`
- **Details:**
  - Implemented 41 SVA properties covering AXI4 stability, SPI timing, PWM period consistency, UART framing, GPIO latency, and Display refresh.
  - 100% assertion pass rate with zero assertion failures.

---

### Phase 19: Functional Coverage Metric Implementation
- **Status:** **COMPLETE**
- **Artifacts:** [`FUNCTIONAL_COVERAGE_REPORT.md`](./FUNCTIONAL_COVERAGE_REPORT.md), `uvm_soc/coverage/*.sv`
- **Details:**
  - Embedded 7 coverage collector subscribers across all agents.
  - Achieved comprehensive bin coverage across operational tiers, register spaces, and transfer sizes.

---

### Phase 20: Top-Level UVM Testbench Elaboration & Build
- **Status:** **COMPLETE**
- **Artifacts:** `uvm_soc/tb/tb_riscv_soc_uvm.sv`, `uvm_soc/tb/soc_pkg.sv`, `uvm_soc/run/filelists/riscv_soc_uvm_full.f`
- **Details:**
  - Cleanly compiled complete SoC RTL and UVM 1.2 environment using Synopsys VCS U-2023.03 (64-bit).
  - Preloaded firmware image `firmware/temperature_fan_words.hex`.

---

### Phase 21: Full Regression Suite Execution & Validation
- **Status:** **COMPLETE**
- **Artifacts:** `uvm_soc/run/logs/*.log`, `uvm_soc/run/scripts/run_regression.sh`
- **Details:**
  - Automated execution of all 22 tests.
  - Resolved minor simulation timeouts and SVA assertions during incremental debug.

---

### Phase 22: FSDB Waveform Generation & Protocol Validation
- **Status:** **COMPLETE**
- **Artifacts:** `uvm_soc/run/fsdb/*.fsdb` (22 FSDB files generated, 18 MB total)
- **Details:**
  - Verified FSDB waveforms generated with full hierarchy dumping (`tb_riscv_soc_uvm`, `+all`, `+mda`).
  - Confirmed signal-level transitions for clock, resets, AXI handshakes, SPI transfers, and PWM pulses.

---

### Phase 23: Complete 22-Test Automated Regression Run
- **Status:** **COMPLETE**
- **Artifacts:** [`REGRESSION_SUMMARY.md`](./REGRESSION_SUMMARY.md)
- **Details:**
  - 22 / 22 Tests Passed (100% Pass Rate).
  - 0 UVM Errors, 0 UVM Fatals across all simulation runs.

---

### Phase 24: Final Audit, Documentation & Project Delivery
- **Status:** **COMPLETE**
- **Artifacts:** [`FINAL_UVM_VERIFICATION_REPORT.md`](./FINAL_UVM_VERIFICATION_REPORT.md), [`UVM_ARCHITECTURE_REPORT.md`](./UVM_ARCHITECTURE_REPORT.md)
- **Details:**
  - Synthesized all component verification reports, coverage metrics, waveform audit data, and regression logs into final executive documentation.
  - All generated code, scripts, logs, waveforms, and reports preserved cleanly within `uvm_soc/`.
