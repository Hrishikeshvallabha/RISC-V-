# UVM Regression Execution Summary Report

- **Date:** Sat Nov  7 14:37:03 IST 2026
- **Host:** vlsi48.vce.ac.in
- **VCS Version:** Synopsys VCS U-2023.03 (64-bit)
- **UVM Version:** UVM 1.2
- **DUT:** `soc_veer_el2_temperature_fan_top` (VeeR EL2 RV32IMC + 2x8 AXI4 Interconnect + Peripherals)

## Regression Results Matrix

| Test # | Test Name | Target Subsystem | UVM Errors | UVM Fatals | Result | Waveform Log |
| :---: | :--- | :--- | :---: | :---: | :---: | :--- |
| 1 | `soc_reset_test` | System Closed-Loop | 0 | 0 | **PASSED** | [`soc_reset_test.fsdb`](../run/fsdb/soc_reset_test.fsdb) |
| 2 | `gpio_basic_test` | GPIO (M02) | 0 | 0 | **PASSED** | [`gpio_basic_test.fsdb`](../run/fsdb/gpio_basic_test.fsdb) |
| 3 | `gpio_random_test` | GPIO (M02) | 0 | 0 | **PASSED** | [`gpio_random_test.fsdb`](../run/fsdb/gpio_random_test.fsdb) |
| 4 | `uart_tx_test` | UART (M01) | 0 | 0 | **PASSED** | [`uart_tx_test.fsdb`](../run/fsdb/uart_tx_test.fsdb) |
| 5 | `uart_rx_test` | UART (M01) | 0 | 0 | **PASSED** | [`uart_rx_test.fsdb`](../run/fsdb/uart_rx_test.fsdb) |
| 6 | `uart_error_test` | UART (M01) | 0 | 0 | **PASSED** | [`uart_error_test.fsdb`](../run/fsdb/uart_error_test.fsdb) |
| 7 | `spi_basic_test` | SPI Temp Sensor (M04) | 0 | 0 | **PASSED** | [`spi_basic_test.fsdb`](../run/fsdb/spi_basic_test.fsdb) |
| 8 | `spi_temperature_test` | SPI Temp Sensor (M04) | 0 | 0 | **PASSED** | [`spi_temperature_test.fsdb`](../run/fsdb/spi_temperature_test.fsdb) |
| 9 | `timer_basic_test` | Hardware Timer (M03) | 0 | 0 | **PASSED** | [`timer_basic_test.fsdb`](../run/fsdb/timer_basic_test.fsdb) |
| 10 | `timer_interrupt_test` | Hardware Timer (M03) | 0 | 0 | **PASSED** | [`timer_interrupt_test.fsdb`](../run/fsdb/timer_interrupt_test.fsdb) |
| 11 | `pwm_basic_test` | PWM Fan (M05) | 0 | 0 | **PASSED** | [`pwm_basic_test.fsdb`](../run/fsdb/pwm_basic_test.fsdb) |
| 12 | `pwm_boundary_test` | PWM Fan (M05) | 0 | 0 | **PASSED** | [`pwm_boundary_test.fsdb`](../run/fsdb/pwm_boundary_test.fsdb) |
| 13 | `display_basic_test` | Seven-Segment (M06) | 0 | 0 | **PASSED** | [`display_basic_test.fsdb`](../run/fsdb/display_basic_test.fsdb) |
| 14 | `interconnect_read_write_test` | AXI4 Crossbar / RAM (M00) | 0 | 0 | **PASSED** | [`interconnect_read_write_test.fsdb`](../run/fsdb/interconnect_read_write_test.fsdb) |
| 15 | `interconnect_address_decode_test` | AXI4 Crossbar / RAM (M00) | 0 | 0 | **PASSED** | [`interconnect_address_decode_test.fsdb`](../run/fsdb/interconnect_address_decode_test.fsdb) |
| 16 | `interconnect_error_test` | AXI4 Crossbar / RAM (M00) | 0 | 0 | **PASSED** | [`interconnect_error_test.fsdb`](../run/fsdb/interconnect_error_test.fsdb) |
| 17 | `memory_basic_test` | AXI4 Crossbar / RAM (M00) | 0 | 0 | **PASSED** | [`memory_basic_test.fsdb`](../run/fsdb/memory_basic_test.fsdb) |
| 18 | `processor_boot_test` | VeeR EL2 Core | 0 | 0 | **PASSED** | [`processor_boot_test.fsdb`](../run/fsdb/processor_boot_test.fsdb) |
| 19 | `soc_temperature_fan_normal_test` | System Closed-Loop | 0 | 0 | **PASSED** | [`soc_temperature_fan_normal_test.fsdb`](../run/fsdb/soc_temperature_fan_normal_test.fsdb) |
| 20 | `soc_temperature_fan_boundary_test` | System Closed-Loop | 0 | 0 | **PASSED** | [`soc_temperature_fan_boundary_test.fsdb`](../run/fsdb/soc_temperature_fan_boundary_test.fsdb) |
| 21 | `soc_concurrent_peripheral_test` | System Closed-Loop | 0 | 0 | **PASSED** | [`soc_concurrent_peripheral_test.fsdb`](../run/fsdb/soc_concurrent_peripheral_test.fsdb) |
| 22 | `soc_full_regression_test` | System Closed-Loop | 0 | 0 | **PASSED** | [`soc_full_regression_test.fsdb`](../run/fsdb/soc_full_regression_test.fsdb) |

## Summary Statistics

- **Total Tests Executed:** 22
- **Passed:** 22
- **Failed:** 0
- **Pass Rate:** 100%

