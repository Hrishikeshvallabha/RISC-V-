# Complete Existing UVM Source Audit Report

- **Date:** Sat Nov 7 14:17:30 IST 2026
- **Project Root:** `/home/student/Documents/078_H/proj_dir/`
- **UVM Environment:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`
- **Simulator / Methodology:** Synopsys VCS U-2023.03 / UVM 1.2

---

## 1. Source Classification Matrix

Every source file within `uvm_soc/` has been inspected against the compilation filelist (`riscv_soc_uvm_full.f`), root package (`soc_pkg.sv`), testbench top (`tb_riscv_soc_uvm.sv`), and runtime test scripts.

| File Path | Purpose | Referencing Components | In `.f` or `soc_pkg` | Status Classification | Recommended Action |
|:---|:---|:---|:---:|:---:|:---|
| `tb/soc_pkg.sv` | Root UVM package | `tb_riscv_soc_uvm.sv`, `riscv_soc_uvm_full.f` | Yes | 1. Required and working | Retain & maintain |
| `tb/tb_riscv_soc_uvm.sv` | Top-level SV testbench | `riscv_soc_uvm_full.f` | Yes | 1. Required and working | Retain & maintain |
| `rtl_if/gpio_uvm_if.sv` | GPIO interface | `tb_top`, `gpio_driver`, `gpio_monitor` | Yes | 1. Required and working | Retain |
| `rtl_if/uart_uvm_if.sv` | UART interface | `tb_top`, `uart_driver`, `uart_monitor` | Yes | 1. Required and working | Retain |
| `rtl_if/spi_uvm_if.sv` | SPI interface | `tb_top`, `spi_driver`, `spi_monitor` | Yes | 1. Required and working | Retain |
| `rtl_if/timer_uvm_if.sv` | Timer interface | `tb_top`, `timer_driver`, `timer_monitor` | Yes | 1. Required and working | Retain |
| `rtl_if/pwm_uvm_if.sv` | PWM interface | `tb_top`, `pwm_monitor` | Yes | 1. Required and working | Retain |
| `rtl_if/display_uvm_if.sv` | 7-segment interface | `tb_top`, `display_monitor` | Yes | 1. Required and working | Retain |
| `rtl_if/interconnect_uvm_if.sv` | AXI4 crossbar interface | `tb_top`, `interconnect_driver`, `interconnect_monitor` | Yes | 1. Required and working | Retain |
| `rtl_if/veer_trace_uvm_if.sv` | CPU trace interface | `tb_top`, `veer_core_monitor` | Yes | 1. Required and working | Retain |
| `env/soc_config.sv` | Environment config | `soc_env`, `soc_base_test` | Yes | 1. Required and working | Retain |
| `env/soc_env.sv` | Master UVM environment | `soc_base_test`, all agents, all scoreboards | Yes | 1. Required and working | Enhance driver analysis port wiring |
| `env/soc_virtual_sequencer.sv`| Virtual sequencer | `soc_env`, virtual sequences | Yes | 1. Required and working | Retain |
| `env/soc_virtual_sequences.sv`| Multi-agent sequences | `soc_system_tests` | Yes | 1. Required and working | Retain |
| `env/veer_core_monitor.sv` | Passive VeeR EL2 monitor | `soc_env`, CPU tests | Yes | 1. Required and working | Retain |
| `agents/gpio/gpio_driver.sv` | GPIO driver | `gpio_agent` | Yes | 2. Required but incomplete | Enhance with `drv_ap` & formatted logging |
| `agents/gpio/gpio_monitor.sv` | GPIO monitor | `gpio_agent` | Yes | 1. Required and working | Retain formatted logging |
| `agents/gpio/gpio_agent.sv` | GPIO agent | `soc_env` | Yes | 2. Required but incomplete | Connect `drv_ap` |
| `agents/uart/uart_driver.sv` | UART driver | `uart_agent` | Yes | 2. Required but incomplete | Enhance with `drv_ap` & formatted logging |
| `agents/uart/uart_monitor.sv` | UART monitor | `uart_agent` | Yes | 1. Required and working | Retain formatted logging |
| `agents/uart/uart_agent.sv` | UART agent | `soc_env` | Yes | 2. Required but incomplete | Connect `drv_ap` |
| `agents/spi/spi_driver.sv` | SPI sensor driver | `spi_agent` | Yes | 2. Required but incomplete | Enhance with `drv_ap` & formatted logging |
| `agents/spi/spi_monitor.sv` | SPI monitor | `spi_agent` | Yes | 1. Required and working | Retain formatted logging |
| `agents/spi/spi_agent.sv` | SPI agent | `soc_env` | Yes | 2. Required but incomplete | Connect `drv_ap` |
| `agents/timer/timer_driver.sv` | Timer driver | `timer_agent` | Yes | 2. Required but incomplete | Enhance with `drv_ap` & formatted logging |
| `agents/timer/timer_monitor.sv`| Timer monitor | `timer_agent` | Yes | 1. Required and working | Retain formatted logging |
| `agents/timer/timer_agent.sv` | Timer agent | `soc_env` | Yes | 2. Required but incomplete | Connect `drv_ap` |
| `agents/pwm/pwm_monitor.sv` | PWM waveform monitor | `pwm_agent` | Yes | 1. Required and working | Retain formatted logging |
| `agents/pwm/pwm_agent.sv` | PWM agent | `soc_env` | Yes | 1. Required and working | Retain |
| `agents/display/display_monitor.sv` | 7-segment digit monitor | `display_agent` | Yes | 1. Required and working | Retain formatted logging |
| `agents/display/display_agent.sv` | 7-segment agent | `soc_env` | Yes | 1. Required and working | Retain |
| `agents/interconnect/interconnect_driver.sv` | AXI Master S00 driver | `interconnect_agent` | Yes | 2. Required but incomplete | Enhance with `drv_ap` & formatted logging |
| `agents/interconnect/interconnect_monitor.sv`| AXI monitor | `interconnect_agent` | Yes | 1. Required and working | Retain formatted logging |
| `agents/interconnect/interconnect_agent.sv` | AXI agent | `soc_env` | Yes | 2. Required but incomplete | Connect `drv_ap` |
| `scoreboards/gpio_scoreboard.sv` | GPIO scoreboard | `soc_env` | Yes | 2. Required but incomplete | Add expected queue, comparisons & summary |
| `scoreboards/uart_scoreboard.sv` | UART scoreboard | `soc_env` | Yes | 2. Required but incomplete | Add expected RX queue, comparisons & summary |
| `scoreboards/spi_scoreboard.sv` | SPI scoreboard | `soc_env` | Yes | 2. Required but incomplete | Add expected queue, comparisons & summary |
| `scoreboards/timer_scoreboard.sv` | Timer scoreboard | `soc_env` | Yes | 2. Required but incomplete | Add expected queue, comparisons & summary |
| `scoreboards/pwm_scoreboard.sv` | PWM scoreboard | `soc_env` | Yes | 2. Required but incomplete | Add AXI model update, tolerances & summary |
| `scoreboards/display_scoreboard.sv`| Display scoreboard | `soc_env` | Yes | 2. Required but incomplete | Add AXI model update, comparisons & summary |
| `scoreboards/interconnect_scoreboard.sv`| AXI scoreboard | `soc_env` | Yes | 2. Required but incomplete | Add address map & memory model, comparisons & summary |
| `scoreboards/soc_system_scoreboard.sv` | Closed-loop system scb | `soc_env` | Yes | 2. Required but incomplete | Add full thermal comparison format & summary |
| `tests/soc_base_test.sv` | Base test class | All tests | Yes | 1. Required and working | Retain |
| `tests/soc_peripheral_tests.sv` | Tests 1–13 | `soc_pkg`, regression | Yes | 1. Required and working | Retain |
| `tests/soc_interconnect_tests.sv`| Tests 14–17 | `soc_pkg`, regression | Yes | 1. Required and working | Retain |
| `tests/soc_system_tests.sv` | Tests 18–22 | `soc_pkg`, regression | Yes | 1. Required and working | Retain |
| `tests/soc_audit_tests.sv` | 5 Audit tests | `soc_pkg` | Yes | 1. Required and working | Add `soc_scoreboard_negative_test` |
| `run/filelists/riscv_soc_uvm_full.f` | Primary compilation filelist | VCS command | Yes | 1. Required and working | Retain |
| `run/scripts/run_regression.sh`| 22-test automated regression | Run script | Yes | 1. Required and working | Retain |
| `run/novas_dump.log` | Verdi dump log | Runtime artifact | No | 6. Simulation artifact | Safe to clean during make clean |
| `run/tr_db.log` | Transaction DB log | Runtime artifact | No | 6. Simulation artifact | Safe to clean during make clean |
| `run/ucli.key` | UCLI command log | Runtime artifact | No | 6. Simulation artifact | Safe to clean during make clean |

---

## 2. Key Audit Findings

1. **No Duplicate Classes**: The environment has exactly one definition for each VIP agent, sequence, sequencer, driver, monitor, and scoreboard.
2. **Clear Interface Bindings**: All 8 virtual interfaces match the actual SoC DUT pinout:
   - `gpio_uvm_if` -> `dut.gpio_io`
   - `uart_uvm_if` -> `dut.uart_rx_i`, `dut.uart_tx_o`, `dut.uart_interrupt_o`
   - `spi_uvm_if` -> `dut.spi_clk_o`, `dut.spi_cs_n_o`, `dut.spi_mosi_o`, `dut.spi_miso_i`, `dut.spi_irq_o`
   - `timer_uvm_if` -> `dut.timer_irq_o`, `dut.timer_ext_meas_i`, `dut.timer_capture_i`, `dut.timer_pwm_o`
   - `pwm_uvm_if` -> `dut.pwm_out_o`
   - `display_uvm_if` -> `dut.an_o`, `dut.seg_o`
   - `interconnect_uvm_if` -> `dut.m00_axi_*` (Master S00 port)
   - `veer_trace_uvm_if` -> `dut.rvtop.trace_rv_i0`
3. **Enhancement Scope Identified**: Scoreboards previously logged informational messages but lacked independent expected-value queues and standardized comparison outputs (`Expected`, `Actual`, `Result: PASS/FAIL`). All scoreboards require transaction counters and vacuous-pass detection.
