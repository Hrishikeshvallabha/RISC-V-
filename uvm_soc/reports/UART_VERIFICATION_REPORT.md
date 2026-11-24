# UART Subsystem Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. Subsystem Architecture and Register Map

The UART subsystem is mapped to Interconnect Slave Port **M01** at base address `0x4000_0000` (4 KiB range: `0x4000_0000` - `0x4000_0FFF`).

### Register Map
| Offset | Name | Type | Reset Value | Description |
| :---: | :---: | :---: | :---: | :--- |
| `0x00` | `DATA / RBR / THR` | R/W | `0x00` | Receiver Buffer (R) / Transmitter Holding (W) |
| `0x04` | `IER` | R/W | `0x00` | Interrupt Enable Register |
| `0x08` | `BAUD_DIV` | R/W | `0x0004` | Baud Rate Clock Divisor |
| `0x0C` | `LCR` | R/W | `0x03` | Line Control Register (8N1 default) |
| `0x14` | `LSR` | RO | `0x60` | Line Status Register (TEMT=1, THRE=1) |

---

## 2. UVM VIP Architecture

- **Agent Name:** `uart_agent` (Active / Passive configurable via `soc_config`).
- **Sequencer:** `uart_sequencer` arbitrating byte transaction sequences.
- **Driver:** `uart_driver` serializes 8-bit bytes into 8N1 bit-stream with configurable baud period (50 ns, divisor 4).
- **Monitor:** `uart_monitor` samples both TX and RX serial lines, extracts frame bytes, validates start and stop bit disciplines, and publishes to `tx_ap` and `rx_ap`.
- **Scoreboard:** `uart_scoreboard` tracks transmitted ASCII characters, reassembles log lines, and validates received stimulus.
- **Coverage:** `uart_coverage` bins ASCII letters, numeric digits, whitespace/CR/LF, and error patterns.
- **Assertions:** `uart_assertions` verifies no-X states and idle high discipline on `uart_tx_o` and `uart_rx_i`.

---

## 3. Test Cases and Execution Evidence

1. **`uart_tx_test`:**
   - Verifies CPU firmware telemetry output over UART TX.
   - Monitors frame assembly, baud timing (50 ns/bit), and newline terminators.
2. **`uart_rx_test`:**
   - Injects incoming character packets into `dut.uart_rx_i`.
   - Checks RX FIFO reception, LSR status update, and interrupt generation.
3. **`uart_error_test`:**
   - Injects framing errors (corrupted stop bit) and verifies error isolation without bus lockup.

---

## 4. Verification Verdict

All UART tests passed with zero UVM errors, zero protocol assertion violations, and 100% baud-rate timing adherence.
