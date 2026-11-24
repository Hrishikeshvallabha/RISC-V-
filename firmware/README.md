# RISC-V Bare-Metal Firmware Package — Temperature Monitoring & Fan Control SoC

**Project Title:** Design and Verification of a RISC-V-Based SoC for Smart Temperature Monitoring and Fan Control  
**Location:** `/home/student/Documents/078_hon/proj_dir/firmware/`  
**Target Processor:** Western Digital / CHIPS Alliance VeeR EL2 RISC-V Core (RV32IMC with Zicsr)  
**Memory Architecture:** 64 KiB Unified Instruction & Data Memory (`0x0000_0000` – `0x0000_FFFF`)  
**Reset Vector:** `0x0000_0000`  
**Status:** Fully Audited, RTL-Aligned, Freestanding C Source & Assembly CRT0  

---

## 1. Directory Structure

```
firmware/
├── temperature_fan_firmware.c   # Complete standalone C firmware (Zero custom header dependency)
├── start.S                      # Minimal CRT0 startup assembly (Stack, GP, MRAC, mtvec trap handler, BSS)
├── temperature_fan.ld           # Linker script defining 64 KiB memory layout & section mapping
├── Makefile                     # Build automation file for RISC-V GCC toolchain
└── README.md                    # Detailed firmware documentation and audit record
```

> **Safety Backups:**
> - `../firmware_backup/`: Initial snapshot taken before cleaning stale output binaries.
> - `../firmware_backup_inspect/`: Inspection backup taken before applying RTL alignment corrections.

---

## 2. Hardware Architecture & Verified MMIO Register Mapping

The firmware directly interfaces with the SoC's 2-Master x 8-Slave AXI4 crossbar interconnect (`soc_veer_el2_temperature_fan_top.sv`). All addresses, offsets, and bit positions have been audited and verified directly against the underlying SystemVerilog/Verilog RTL modules:

| Slave Slot | Base Address | Size | Description | Verified RTL Source File |
| :--- | :--- | :--- | :--- | :--- |
| **M00** | `0x0000_0000` | 64 KiB | Unified Instruction & Data RAM | `rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v` |
| **M01** | `0x4000_0000` | 4 KiB | 16550-Compatible AXI UART Controller | `rtl/IP's/uart/axi_uart_top.v` |
| **M02** | `0x4000_2000` | 4 KiB | 32-Bit Bidirectional GPIO Controller | `rtl/IP's/gpio/gpio_regs.sv` |
| **M03** | `0x4000_4000` | 4 KiB | 32-Bit Hardware Down-Counting Timer | `rtl/IP's/timer/timer_regs.sv`, `timer_core.sv` |
| **M04** | `0x4000_6000` | 4 KiB | AXI SPI Master Temperature Controller | `rtl/IP's/spi/axi_spi_top.v`, `axi_spi_ctrl.v` |
| **M05** | `0x4000_A000` | 4 KiB | 8-Bit PWM Fan Speed Controller | `rtl/IP's/pwm/myip_v1_0_S00_AXI.v` |
| **M06** | `0x4000_C000` | 4 KiB | 4-Digit 7-Segment Multiplexed Display | `rtl/IP's/7segment/axi_seven_segment.v` |
| **M07** | `0x0000_0000` | 0 B | Disabled / Masked Slave Port | `CONNECT_READ=0`, `CONNECT_WRITE=0` |

---

## 3. Peripheral RTL Verification & Firmware Corrections

### A. Hardware Timer Controller (`0x4000_4000`)
- **Registers:** `0x00` CTRL, `0x04` LOAD, `0x08` CTR (Current Value), `0x0C` PRE (Prescaler), `0x10` INT_EN, `0x14` INT_STS, `0x18` CMP, `0x1C` CAP.
- **RTL Finding & Correction (CRITICAL):**
  - In `timer_regs.sv` and `timer_core.sv`:
    - Bit 0: `en` (Counter Enable)
    - Bit 1: `mode` (1 = Repeat / Auto-Reload, 0 = One-Shot)
    - **Bit 2:** `pre_en` (Prescaler Enable). In earlier firmware revisions, Bit 2 was mislabeled as `DIR_UP`. When `pre_en == 0`, hardware bypasses the prescaler counter entirely, causing the timer to tick every 10 ns clock cycle regardless of `pre_val`.
    - **Bit 3:** `dir` (0 = Downward Count, 1 = Upward Count). Earlier revisions mislabeled Bit 3 as `ONE_SHOT`.
  - **Correction Applied:** Corrected bit definitions to `#define TIMER_CTRL_PRE_EN 0x04U` and `#define TIMER_CTRL_DIR_UP 0x08U`. Updated `timer_start()` to write `(TIMER_CTRL_EN | TIMER_CTRL_AUTO_RELOAD | TIMER_CTRL_PRE_EN)` (`0x07U`) so that the hardware prescaler is properly active during downward countdowns.

### B. UART Controller (`0x4000_0000`)
- **Registers:** `0x00` RBR/THR (DLL when DLAB=1), `0x04` IER (DLM when DLAB=1), `0x08` BAUD_DIV (when DLAB=1), `0x0C` LCR, `0x14` LSR.
- **RTL Finding & Correction:**
  - In `axi_uart_top.v`, the read state machine only decodes `UART_RBR` (`0x00`) and `UART_LSR` (`0x14`). Attempting to read `UART_LCR`, `UART_IER`, or `UART_BAUD_DIVISOR` causes an unacknowledged AXI read transaction (bus hang).
  - The write state machine assigns `uart_config_reg_int_d = axi_wdata_i` without masking by `wstrb`.
  - **Correction Applied:** Ensured that software never reads write-only UART registers. Standardized all UART register configuration writes to full 32-bit zero-extended word writes (`REG32`) to prevent uninitialized upper byte lanes on the AXI bus.

### C. SPI Master Controller (`0x4000_6000`)
- **Registers:** `0x60` CR, `0x64` SR, `0x68` DTR, `0x6C` DRR, `0x70` SSR.
- **Sensor Protocol & Transfer Sequence:**
  - Sensor is active-low on Chip Select 0 (`spi_cs_n_o = spi_slave_select_reg[0]`).
  - Master operates in SPI Mode 0 (CPOL=0, CPHA=0), MSB first.
  - Software drains stale RX FIFO bytes before transaction.
  - Asserts CS0 by writing `0xFFFFFFFEU` to `SPI_SSR`.
  - Transmits dummy byte (`0x00`) to `SPI_DTR` to trigger 8 clock pulses on `spi_clk_o`.
  - Bounded polling on `SPI_SR` bit 0 (`SPI_SR_RX_EMPTY == 0`).
  - Reads received sensor byte from `SPI_DRR`.
  - Deasserts CS0 by writing `0xFFFFFFFFU` to `SPI_SSR`.
  - On timeout error, CS0 is safely deasserted prior to returning error status.

### D. PWM Fan Controller (`0x4000_A000`)
- **Registers:** `0x00` slv_reg0 (Duty cycle threshold), `0x04` slv_reg1, `0x08` slv_reg2, `0x0C` slv_reg3.
- **Operation:**
  - Hardware compares 8-bit free-running counter `pwm_counter < duty_cycle`.
  - 0% Duty: `0x00` (Fan Off)
  - 25% Duty: `64` (`0x40`) (Quiet Mode)
  - 50% Duty: `128` (`0x80`) (Medium Mode)
  - 85% Duty: `217` (`0xD9`) (Boost Mode)
  - 100% Duty: `255` (`0xFF`) (Fail-Safe Mode)

### E. Seven-Segment Display Controller (`0x4000_C000`)
- **Registers:** `0x00` Display Data [15:0] (4 hex digits: `[Digit3][Digit2][Digit1][Digit0]`), `0x04` Control (bit 0 = enable), `0x08` Status (bit 0 = enable, bits [7:6] = active digit index).
- **Encoding:**
  - Valid temperature `25 °C` -> `0x25C0`
  - Valid temperature `30 °C` -> `0x30C0`
  - Valid temperature `45 °C` -> `0x45C0`
  - Valid temperature `55 °C` -> `0x55C0`
  - Out-of-bounds error -> `0xEEEE`

### F. CRT0 Startup Assembly & Trap Handling (`start.S`)
- Configures MRAC CSR `0x7C0` with `0x00000200` (Region 4 MMIO uncacheable non-idempotent).
- Initializes `sp` to `_stack_top` (`0x0000_FFFC`).
- Initializes `gp` to `__global_pointer$`.
- Clears `.bss` segment.
- **Trap Handling Added:** Installs `default_trap_handler` into `mtvec`. If an unmapped address access (such as TC-04 testing reserved gap `0x4000_1000`) triggers an AXI `DECERR`, the handler safely advances `mepc` by 4 bytes and executes `mret`, providing resilient exception recovery.

---

## 4. Autonomous Closed-Loop Thermal Policy

```
Sensor Reading (T)               Fan Mode       PWM Duty Cycle   7-Segment Display   Error LED (GPIO Bit 31)
-----------------------------------------------------------------------------------------------------------
T < 30 °C                        QUIET          25%  (64)        0x<T>C0             Deasserted (0)
30 °C <= T <= 45 °C              MEDIUM         50%  (128)       0x<T>C0             Deasserted (0)
T > 45 °C (T <= 120 °C)          BOOST          85%  (217)       0x<T>C0             Deasserted (0)
T < 0 °C or T > 120 °C           FAILSAFE       100% (255)       0xEEEE              ASSERTED   (1)
SPI Sensor Timeout / Failure     FAILSAFE       100% (255)       0xEEEE              ASSERTED   (1)
```

---

## 5. Verification Test Suite Traceability (TC-01 through TC-18)

| Test ID | Name | Subsystem Verified |
| :--- | :--- | :--- |
| **TC-01** | `FW-BOOT-001` | CPU Boot, Reset Vector Fetch, Stack Pointer Allocation (`0x0000_FFFC`) |
| **TC-02** | `FW-BOOT-002` | Unified Memory 32-Bit Word R/W Data Integrity at `0x0000_E000` |
| **TC-03** | `FW-BUS-001` | AXI4 Interconnect Address Decoding for All Active Peripherals (M00–M06) |
| **TC-04** | `FW-BUS-002` | Reserved Buffer Gap Isolation & Trap Recovery at `0x4000_1000` |
| **TC-05** | `FW-BUS-003` | Core IFU Fetch & LSU Load/Store Arbitration Concurrency |
| **TC-06** | `FW-UART-001` | UART Baud Rate Divisor, 8N1 Framing & TX Ready Status |
| **TC-07** | `FW-UART-002` | UART Receiver Status Flag Querying & Line Status Verification |
| **TC-08** | `FW-GPIO-001` | GPIO Direction Configuration & 32-Bit Output Data Register Access |
| **TC-09** | `FW-GPIO-002` | GPIO Atomic Bit Manipulation (SET/CLEAR) & Error Indicator (Bit 31) |
| **TC-10** | `FW-TIMER-001` | Hardware Timer Downward Decrement, Prescaler Enable & Auto-Reload |
| **TC-11** | `FW-TIMER-002` | Hardware Timer Compare Match Register & Interrupt Enable |
| **TC-12** | `FW-SPI-001` | SPI Master Controller Mode 0 Init & Manual CS0 Active-Low Toggling |
| **TC-13** | `FW-SPI-002` | SPI Full-Duplex Byte Exchange Protocol & FIFO Status Polling |
| **TC-14** | `FW-PWM-001` | PWM Fan Controller Duty Cycle Register Programming (25%, 50%, 85%) |
| **TC-15** | `FW-SEG-001` | Seven-Segment Display Packed 4-Digit Data & Multiplex Scan Enable |
| **TC-16** | `FW-APP-001` | Autonomous Multi-Tier Thermal Regulation Policy & BCD Formatting |
| **TC-17** | `FW-APP-002` | Real-Time ASCII Telemetry Streaming via UART Serial Interface |
| **TC-18** | `FW-FAULT-001` | Communication Timeout, Out-of-Bounds Detection & 100% Fail-Safe Cooling |

---

## 6. Future RISC-V GCC Build Instructions

When compiling the firmware image using the RISC-V GCC toolchain, execute the following commands:

```bash
cd /home/student/Documents/078_hon/proj_dir/firmware

# Build complete artifact suite:
make

# Or build individual targets:
make elf          # temperature_fan.elf
make bin          # temperature_fan.bin
make hex          # temperature_fan.hex (Intel HEX)
make words_hex    # temperature_fan_words.hex (Verilog 32-bit word format for simulation)
make disassemble  # temperature_fan.dis (Disassembly listing with symbols)
make size         # Memory footprint report
make clean        # Clean build artifacts
```
