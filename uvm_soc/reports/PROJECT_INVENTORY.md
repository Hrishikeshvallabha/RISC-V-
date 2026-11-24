# Comprehensive Project Inventory and RTL Architecture Audit

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Verification Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Reference Manuals:** `RISC-V_VeeR_EL2_PRM.pdf`, `Address_mapping.ods`  
**Audit Date:** November 7, 2026  
**Status:** **AUTHORITATIVE & VERIFIED**  

---

## 1. Executive Summary

This audit establishes the comprehensive hardware and verification inventory for the RISC-V VeeR EL2 System-on-Chip (SoC). All declarations, port lists, bus protocols, and memory maps have been extracted directly from the synthesizable RTL and verified against authoritative reference specifications.

---

## 2. Processor Inventory (VeeR EL2)

- **Integration Top:** `rtl/soc_veer_el2_temperature_fan_top.sv`
- **Core Wrapper:** `el2_veer_wrapper` instantiated as `core_inst` (`rtl/IP's/Cores-VeeR-EL2/design/el2_veer_wrapper.sv`).
- **Core Architecture:** Western Digital / CHIPS Alliance VeeR EL2 (RV32IMC + Zicsr), 4-stage dual-issue superscalar RISC-V core.
- **Clock & Reset:**
  - Clock: `clk` (100 MHz System Clock, 10 ns period).
  - System Reset: `rst` (Active-high global reset).
  - Core Run Reset: `core_rst_n_i` (Active-low core reset, active-high run enable).
  - Core Reset Input: `core_rst_l = ~rst & core_rst_n_i`.
  - Debug Reset Input: `dbg_rst_l = ~rst`.
  - Boot Vector: `rst_vec = 31'h0000_0000` (boots directly from Unified Memory base at `0x0000_0000`).
- **Instruction Memory Interface:**
  - Natively 64-bit AXI4 Instruction Fetch Unit (`ifu_axi_*`).
  - Adapted via `axi_adapter_ifu_64_to_32` (`rtl/axi_adapter_ifu_64_to_32.sv`) to 32-bit AXI4.
- **Data Memory Interface:**
  - Natively 64-bit AXI4 Load-Store Unit (`lsu_axi_*`).
  - Adapted via `axi_adapter_lsu_64_to_32` (`rtl/axi_adapter_lsu_64_to_32.sv`) to 32-bit AXI4.
- **Master Arbitration:**
  - 2-to-1 round-robin fair arbiter `axi_arbiter_2to1` (`rtl/axi_arbiter_2to1.sv`) multiplexes IFU and LSU transactions onto Crossbar Master Port S01 (`core_axi_*`).
- **Programmable Interrupt Controller (PIC):**
  - PIC vector mapping (`extintsrc_req`):
    - `extintsrc_req[1]` = UART Interrupt (`uart_interrupt_o`)
    - `extintsrc_req[2]` = SPI Interrupt (`spi_irq_o`)
    - `extintsrc_req[3]` = GPIO Interrupt (`gpio_intr_o`)
    - `extintsrc_req[4]` = PWM Period Interrupt (`pwm_irq_o`)
    - `extintsrc_req[pt.PIC_TOTAL_INT:5]` = Tied to `0`
- **Pipeline Observability / Trace Port:**
  - `trace_rv_i_insn_ip[31:0]` : Instruction word retired
  - `trace_rv_i_address_ip[31:0]`: Instruction address retired
  - `trace_rv_i_valid_ip` : Instruction retirement strobe
  - `trace_rv_i_exception_ip` : Pipeline exception flag
  - `trace_rv_i_ecause_ip[4:0]` : Exception cause code
  - `trace_rv_i_interrupt_ip` : Interrupt service strobe
  - `trace_rv_i_tval_ip[31:0]` : Trap value register

---

## 3. Interconnect Inventory

- **Module Name:** `axi_interconnect_wrap_2x8` (`rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v`).
- **Sub-blocks:** `axi_interconnect.v`, `arbiter.v`, `priority_encoder.v`.
- **Protocol:** AXI4 (Full AXI4 with ID tagging, burst support, independent read/write channels).
- **Dimensions:** 2 Master Ports $\times$ 8 Slave Ports.
  - **Master S00:** External Test Master (`axi_*`) — allows testbench to inject transactions.
  - **Master S01:** VeeR EL2 Core (`core_axi_*`) — driven by IFU/LSU arbiter.
- **Data Width:** 32 bits (`DATA_WIDTH = 32`).
- **Address Width:** 32 bits (`ADDR_WIDTH = 32`).
- **ID Width:** 8 bits (`IC_ID_WIDTH = 8`).
- **Address Decoding & Slave Map:**
  | Port | Subsystem | Base Address | Address Range | Size | Access Modes | Status in Scope |
  | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
  | **M00** | Unified Instruction/Data Memory | `0x0000_0000` | `0x0000_0000` - `0x0000_FFFF` | 64 KiB | Read / Write / Execute | **Active** |
  | **M01** | 16550 UART Controller | `0x4000_0000` | `0x4000_0000` - `0x4000_0FFF` | 4 KiB | Read / Write | **Active** |
  | **M02** | GPIO Subsystem | `0x4000_2000` | `0x4000_2000` - `0x4000_2FFF` | 4 KiB | Read / Write | **Active** |
  | **M03** | Hardware Timer | `0x4000_4000` | `0x4000_4000` - `0x4000_4FFF` | 4 KiB | Read / Write | **Active** |
  | **M04** | SPI Temperature Sensor Master | `0x4000_6000` | `0x4000_6000` - `0x4000_6FFF` | 4 KiB | Read / Write | **Active** |
  | **M05** | PWM Fan Speed Controller | `0x4000_A000` | `0x4000_A000` - `0x4000_AFFF` | 4 KiB | Read / Write | **Active** |
  | **M06** | Seven-Segment Display Controller | `0x4000_C000` | `0x4000_C000` - `0x4000_CFFF` | 4 KiB | Read / Write | **Active** |
  | **M07** | Masked / Disabled Boundary Slave | `0x0000_0000` | Disabled (`CONNECT=2'b00`) | 0 B | None (DECERR Trap) | **Disabled** |

- **Reserved Buffer Zones:** Explicitly unmapped 4 KiB guard spaces exist between peripherals (`0x4000_1000`, `0x4000_3000`, `0x4000_5000`, `0x4000_7000`, `0x4000_8000–0x4000_9FFF`, `0x4000_B000`, `0x4000_D000–0x4000_FFFF`) ensuring strict isolation and catching out-of-bounds accesses.

---

## 4. Peripheral Subsystems Inventory

### 4.1 Unified Memory Subsystem (M00)
- **Module:** `soc_memory_axi` (`rtl/soc_memory_axi.sv`).
- **Capacity:** 64 KiB ($16,384 \times 32$-bit words).
- **Features:** Byte-write strobes (`wstrb[3:0]`), synchronous read/write, default initialized with safe RISC-V NOP instructions (`0x0000_0013`).

### 4.2 UART Subsystem (M01)
- **Module:** `axi_uart_top` (`rtl/IP's/uart/axi_uart_top.v`).
- **Registers:** DATA/RBR/THR (`0x00`), IER (`0x04`), BAUD_DIV (`0x08`), LCR (`0x0C`), LSR (`0x14`).
- **Pins:** `uart_rx_i` (input), `uart_tx_o` (output), `uart_interrupt_o` (output).
- **Simulation Baud:** Divisor = 4 (50 ns bit period, 20 Mbaud at 100 MHz).

### 4.3 GPIO Subsystem (M02)
- **Module:** `gpio_axi` (`rtl/IP's/gpio/gpio_axi.sv`).
- **Registers:** DATA_I (`0x00`), DATA_O (`0x04`), DIR (`0x08`), INT_EN (`0x14`), INT_STS (`0x18`), SET (`0x24`), CLR (`0x28`).
- **Pins:** `inout wire [31:0] gpio_io`, `output wire gpio_intr_o`.
- **Default State:** Register `DIR` resets to `0x0000_0000` (all 32 pins configured as high-impedance inputs). Input signals pass through a 2-stage flip-flop synchronizer.

### 4.4 Hardware Timer Subsystem (M03)
- **Module:** `timer_axi` (`rtl/IP's/timer/timer_axi.sv`).
- **Registers:** CTRL (`0x00`), LOAD (`0x04`), VAL (`0x08`), PRE (`0x0C`), INT_EN (`0x10`), INT_STS (`0x14`), CMP (`0x18`), CAP (`0x1C`).
- **Pins:** `timer_ext_meas_i`, `timer_capture_i`, `timer_pwm_o`, `timer_trigger_o`, `timer_irq_o`.

### 4.5 SPI Temperature Sensor Interface Subsystem (M04)
- **Module:** `axi_spi_top` (`rtl/IP's/spi/axi_spi_top.v`).
- **Registers:** CR (`0x60`), SR (`0x64`), DTR (`0x68`), DRR (`0x6C`), SSR (`0x70`), SRR (`0x40`).
- **Pins:** `spi_clk_o`, `spi_cs_n_o`, `spi_mosi_o`, `spi_miso_i`, `spi_irq_o`.
- **Protocol:** SPI Mode 0 (CPOL=0, CPHA=0), full duplex byte exchange with external temperature sensor.

### 4.6 PWM Fan Speed Controller Subsystem (M05)
- **Module:** `myip_v1_0` (`rtl/IP's/pwm/myip_v1_0.v`).
- **Registers:** `slv_reg0[7:0]` (Duty Cycle: 0 to 255).
- **Pins:** `pwm_out_o` (output), `pwm_irq_o` (output).
- **Operation:** 8-bit counter `pwm_counter` (0..255) generates modulated fan control pulse `pwm_out_o = (pwm_counter < duty_cycle)`.

### 4.7 Seven-Segment Display Controller Subsystem (M06)
- **Module:** `axi_seven_segment` (`rtl/IP's/7segment/axi_seven_segment.v`).
- **Registers:** `display_data_reg` (`0x00`), `control_reg` (`0x04`).
- **Pins:** `seg[6:0]` (active-high cathode segment drives a..g), `an[3:0]` (active-low anode digit selects AN3..AN0).
- **Operation:** Dynamic time-multiplexed display refresh scanning 4 digits.

---

## 5. Interface & UVM Verification Components Classification

| IP / Subsystem | External Interface Port(s) | Direction | Clock | Reset | UVM Agent Role | Verification Components Required |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **GPIO** | `gpio_io[31:0]`, `gpio_intr_o` | Inout / Output | `clk` | `rst_n` | Active Driver / Monitor | `gpio_uvm_if`, Driver, Monitor, Scoreboard, Coverage, Assertions |
| **UART** | `uart_rx_i`, `uart_tx_o`, `uart_interrupt_o` | Input / Output | `clk` | `rst_n` | Active TX/RX Driver / Monitor | `uart_uvm_if`, Driver, Monitor, Scoreboard, Coverage, Assertions |
| **SPI Sensor** | `spi_clk_o`, `spi_cs_n_o`, `spi_mosi_o`, `spi_miso_i`, `spi_irq_o` | Output / Input | `spi_clk_o` | `rst_n` | Reactive Slave Sensor Model | `spi_uvm_if`, Slave Driver, Monitor, Scoreboard, Coverage, Assertions |
| **Timer** | `timer_ext_meas_i`, `timer_capture_i`, `timer_pwm_o`, `timer_trigger_o`, `timer_irq_o` | Input / Output | `clk` | `rst_n` | Active Stimulus / Monitor | `timer_uvm_if`, Driver, Monitor, Scoreboard, Coverage, Assertions |
| **PWM Fan** | `pwm_out_o`, `pwm_irq_o` | Output | `clk` | `rst_n` | Passive Protocol Monitor | `pwm_uvm_if`, Monitor, Duty-Cycle Scoreboard, Coverage, Assertions |
| **Seven-Segment** | `seg[6:0]`, `an[3:0]` | Output | `clk` | `rst_n` | Passive Display Monitor | `display_uvm_if`, Monitor, BCD Decode Reference Model, Scoreboard, Coverage |
| **Interconnect (S00)**| `axi_aw*`, `axi_w*`, `axi_b*`, `axi_ar*`, `axi_r*` | Input / Output | `clk` | `rst_n` | Active AXI4 Master Test Agent | `interconnect_uvm_if`, AXI Driver, Monitor, Routing Scoreboard, Coverage |
| **VeeR EL2 Trace** | `trace_rv_i_*` | Output | `clk` | `core_rst_n_i` | Passive Execution Monitor | Core Trace Monitor, Instruction Retired Tracker, Firmware Completion Checker |
| **System Closed Loop** | All Subsystems Coordinated | In/Out | `clk` | Multi | Virtual Sequencer / Sequences | `soc_virtual_sequencer`, End-to-End Virtual Sequences, System Scoreboard |
