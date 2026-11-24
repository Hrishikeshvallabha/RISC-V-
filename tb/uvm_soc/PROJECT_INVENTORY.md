# Project Inventory and SoC Architecture Analysis

**Project:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Verification Directory:** `/home/student/Documents/078_H/proj_dir/tb/uvm_soc/`  
**Date:** November 7, 2026  

---

## 1. Actual SoC Top Module

- **File Path:** `rtl/soc_veer_el2_temperature_fan_top.sv`
- **Module Name:** `soc_veer_el2_temperature_fan_top`
- **Parameters:**
  ```systemverilog
  parameter DATA_WIDTH            = 32,
  parameter ADDR_WIDTH            = 32,
  parameter IC_ID_WIDTH           = 8,
  parameter STRB_WIDTH            = DATA_WIDTH / 8,  // 4
  parameter GPIO_NUM_BITS         = 32,
  parameter TIMER_ADDR_WIDTH      = 32,
  parameter PWM_ADDR_WIDTH        = 4,
  parameter SEVEN_SEG_ADDR_WIDTH  = 12,
  parameter SEVEN_SEG_REFRESH_DIV = 100
  ```
- **Port Declarations:**
  | Group | Port Name | Direction | Width | Description |
  | :--- | :--- | :--- | :--- | :--- |
  | **Clock / Reset** | `clk` | Input | 1 | Primary system clock (100 MHz, 10 ns period) |
  | | `rst` | Input | 1 | Global active-high synchronous system reset |
  | | `core_rst_n_i` | Input | 1 | Active-high core run enable (active-low core reset) |
  | **External Test Master (AXI4 S00)** | `axi_awid` | Input | `IC_ID_WIDTH` (8) | Write address ID |
  | | `axi_awaddr` | Input | `ADDR_WIDTH` (32) | Write address |
  | | `axi_awlen` | Input | 8 | Write burst length |
  | | `axi_awsize` | Input | 3 | Write burst size |
  | | `axi_awburst` | Input | 2 | Write burst type |
  | | `axi_awlock` | Input | 1 | Write lock |
  | | `axi_awcache` | Input | 4 | Write memory type |
  | | `axi_awprot` | Input | 3 | Write protection attributes |
  | | `axi_awqos` | Input | 4 | Write Quality of Service |
  | | `axi_awvalid` | Input | 1 | Write address valid |
  | | `axi_awready` | Output | 1 | Write address ready |
  | | `axi_wdata` | Input | `DATA_WIDTH` (32) | Write data |
  | | `axi_wstrb` | Input | `STRB_WIDTH` (4) | Write strobe |
  | | `axi_wlast` | Input | 1 | Write last beat |
  | | `axi_wvalid` | Input | 1 | Write data valid |
  | | `axi_wready` | Output | 1 | Write data ready |
  | | `axi_bid` | Output | `IC_ID_WIDTH` (8) | Response ID |
  | | `axi_bresp` | Output | 2 | Write response |
  | | `axi_bvalid` | Output | 1 | Write response valid |
  | | `axi_bready` | Input | 1 | Write response ready |
  | | `axi_arid` | Input | `IC_ID_WIDTH` (8) | Read address ID |
  | | `axi_araddr` | Input | `ADDR_WIDTH` (32) | Read address |
  | | `axi_arlen` | Input | 8 | Read burst length |
  | | `axi_arsize` | Input | 3 | Read burst size |
  | | `axi_arburst` | Input | 2 | Read burst type |
  | | `axi_arlock` | Input | 1 | Read lock |
  | | `axi_arcache` | Input | 4 | Read cache |
  | | `axi_arprot` | Input | 3 | Read protection |
  | | `axi_arqos` | Input | 4 | Read QoS |
  | | `axi_arvalid` | Input | 1 | Read address valid |
  | | `axi_arready` | Output | 1 | Read address ready |
  | | `axi_rid` | Output | `IC_ID_WIDTH` (8) | Read response ID |
  | | `axi_rdata` | Output | `DATA_WIDTH` (32) | Read data |
  | | `axi_rresp` | Output | 2 | Read response status |
  | | `axi_rlast` | Output | 1 | Read last beat |
  | | `axi_rvalid` | Output | 1 | Read data valid |
  | | `axi_rready` | Input | 1 | Read data ready |
  | **UART (M01)** | `uart_rx_i` | Input | 1 | Serial receive data |
  | | `uart_tx_o` | Output | 1 | Serial transmit data |
  | | `uart_interrupt_o` | Output | 1 | UART interrupt flag |
  | **SPI (M04)** | `spi_clk_o` | Output | 1 | SPI serial SCK clock |
  | | `spi_cs_n_o` | Output | 1 | Active-low chip select |
  | | `spi_mosi_o` | Output | 1 | Master Out Slave In |
  | | `spi_miso_i` | Input | 1 | Master In Slave Out |
  | | `spi_irq_o` | Output | 1 | SPI transfer complete interrupt |
  | **PWM (M05)** | `pwm_out_o` | Output | 1 | PWM modulated fan drive signal |
  | | `pwm_irq_o` | Output | 1 | PWM period interrupt |
  | **Seven-Segment (M06)** | `seg` | Output | 7 | Multiplexed 7-segment cathode lines (a..g) |
  | | `an` | Output | 4 | Active-low anode multiplexing lines (AN3..AN0) |
  | **GPIO (M02)** | `gpio_io` | Inout | `GPIO_NUM_BITS` (32) | Bidirectional general-purpose I/O bus |
  | | `gpio_intr_o` | Output | 1 | GPIO level/edge interrupt |
  | **Timer (M03)** | `timer_ext_meas_i` | Input | 1 | External measurement signal |
  | | `timer_capture_i` | Input | 1 | Input capture signal |
  | | `timer_pwm_o` | Output | 1 | Hardware timer PWM output |
  | | `timer_trigger_o` | Output | 1 | Timer event trigger output |
  | | `timer_irq_o` | Output | 1 | Timer match interrupt |
  | **VeeR EL2 Trace** | `trace_rv_i_insn_ip` | Output | 32 | Instruction word retired |
  | | `trace_rv_i_address_ip` | Output | 32 | Instruction address retired |
  | | `trace_rv_i_valid_ip` | Output | 1 | Instruction retirement valid |
  | | `trace_rv_i_exception_ip` | Output | 1 | Pipeline exception indicator |
  | | `trace_rv_i_ecause_ip` | Output | 5 | Exception cause code |
  | | `trace_rv_i_interrupt_ip` | Output | 1 | Interrupt service indicator |
  | | `trace_rv_i_tval_ip` | Output | 32 | Trap value register |

---

## 2. VeeR EL2 Processor Integration

- **Core Module:** `el2_veer_wrapper` instantiated as `core_inst` in `rtl/soc_veer_el2_temperature_fan_top.sv`.
- **ISA / Features:** RV32IMC + Zicsr, 4-stage dual-issue superscalar RISC-V core.
- **Boot Configuration:**
  - `rst_vec = 31'h0000_0000` (Boots from Unified Instruction/Data Memory M00).
- **Bus Adapters:**
  - VeeR EL2 natively outputs 64-bit AXI4 for Instruction Fetch Unit (IFU) and Load-Store Unit (LSU).
  - `axi_adapter_ifu_64_to_32`: Narrow-down converter adapting 64-bit IFU to 32-bit AXI4.
  - `axi_adapter_lsu_64_to_32`: Narrow-down converter adapting 64-bit LSU to 32-bit AXI4.
  - `axi_arbiter_2to1`: Fair 2-to-1 round-robin master arbiter multiplexing IFU and LSU transactions onto crossbar master port S01.
- **Interrupt Routing (PIC):**
  - PIC vector input `extintsrc_req[1]` = `uart_interrupt_o`
  - PIC vector input `extintsrc_req[2]` = `spi_irq_o`
  - PIC vector input `extintsrc_req[3]` = `gpio_intr_o`
  - PIC vector input `extintsrc_req[4]` = `pwm_irq_o`

---

## 3. Existing Interconnect

- **Module Name:** `axi_interconnect_wrap_2x8`
- **File:** `rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v`
- **Topology:** 2 AXI4 Master Ports $\times$ 8 AXI4 Slave Ports Crossbar.
  - Master S00: External Testbench Test Master (`axi_*`).
  - Master S01: VeeR EL2 Core Arbiter Master (`core_axi_*`).
- **Memory Map & Address Decoding:**
  | Slave Port | Subsystem | Base Address | Address Range | Size | Access Modes |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | **M00** | Unified Instruction/Data Memory | `0x0000_0000` | `0x0000_0000` - `0x0000_FFFF` | 64 KiB | Read/Write (S00, S01) |
  | **M01** | 16550 UART Controller | `0x4000_0000` | `0x4000_0000` - `0x4000_0FFF` | 4 KiB | Read/Write (S00, S01) |
  | **M02** | GPIO Subsystem | `0x4000_2000` | `0x4000_2000` - `0x4000_2FFF` | 4 KiB | Read/Write (S00, S01) |
  | **M03** | Hardware Timer | `0x4000_4000` | `0x4000_4000` - `0x4000_4FFF` | 4 KiB | Read/Write (S00, S01) |
  | **M04** | SPI Temperature Sensor Master | `0x4000_6000` | `0x4000_6000` - `0x4000_6FFF` | 4 KiB | Read/Write (S00, S01) |
  | **M05** | PWM Fan Speed Controller | `0x4000_A000` | `0x4000_A000` - `0x4000_AFFF` | 4 KiB | Read/Write (S00, S01) |
  | **M06** | Seven-Segment Display Controller | `0x4000_C000` | `0x4000_C000` - `0x4000_CFFF` | 4 KiB | Read/Write (S00, S01) |
  | **M07** | Masked / Disabled Boundary Slave | `0x0000_0000` | Disabled (`CONNECT=2'b00`) | 0 B | None (DECERR trap) |

---

## 4. Existing UART Peripheral

- **Module Name:** `axi_uart_top`
- **File:** `rtl/IP's/uart/axi_uart_top.v`
- **Sub-blocks:** `axi_internal_fifo.v`, `uart_parity_bit_compute.v`, `uart_receiver.v`, `uart_transmitter.v`, `uart_controller.v`.
- **Top Pins:** `uart_rx_i` (input), `uart_tx_o` (output), `uart_interrupt_o` (output).
- **Default Baud Setting in Simulation:** Divisor = 4 (50 ns bit period, 20 Mbaud @ 100 MHz clock).

---

## 5. Existing GPIO Peripheral

- **Module Name:** `gpio_axi`
- **File:** `rtl/IP's/gpio/gpio_axi.sv`
- **Sub-blocks:** `axi4lite_slave_adapter.sv`, `gpio_regs.sv`, `gpio_wrapper.sv`, `gpio_bit.sv`.
- **Top Pins:** `inout wire [31:0] gpio_io`, `output wire gpio_intr_o`.
- **Internal Register Defaults & Direction:**
  - Register `ADDR_DIR` (`s_reg_dir`): Resets to `32'h0000_0000`.
  - Reset condition defines **all 32 pins as high-impedance inputs** (`oe = 0`, `oe_actual = 0` $\rightarrow$ `pad = 1'bz`).
  - Therefore, an external testbench driver driving `gpio_io` experiences **zero electrical contention**.
  - Internal input synchronizer: Two-stage flip-flop synchronizer (`sync_reg[1:0]`) inside `gpio_bit.sv` samples the physical pad state continuously and transfers it to `gpio_i`, readable via register `ADDR_DATA_I` (offset `0x00`).

---

## 6. Existing SPI Peripheral

- **Module Name:** `axi_spi_top`
- **File:** `rtl/IP's/spi/axi_spi_top.v`
- **Sub-blocks:** `ratio_clk.v`, `spi_clk_gen.v`, `spi_valid_logic.v`, `spi_fifo.v`, `spi_exch_byte.v`, `spi_ctrl.v`, `axi_spi_ctrl.v`.
- **Top Pins:** `spi_clk_o`, `spi_cs_n_o`, `spi_mosi_o`, `spi_miso_i`, `spi_irq_o`.

---

## 7. Existing Timer Peripheral

- **Module Name:** `timer_axi`
- **File:** `rtl/IP's/timer/timer_axi.sv`
- **Sub-blocks:** `timer_core.sv`, `timer_regs.sv`.
- **Top Pins:** `timer_ext_meas_i`, `timer_capture_i`, `timer_pwm_o`, `timer_trigger_o`, `timer_irq_o`.

---

## 8. Existing PWM Peripheral

- **Module Name:** `myip_v1_0`
- **File:** `rtl/IP's/pwm/myip_v1_0.v`
- **Sub-blocks:** `myip_v1_0_S00_AXI.v`.
- **Top Pins:** `pwm_out_o`, `pwm_irq_o`.

---

## 9. Existing Seven-Segment Display Controller

- **Module Name:** `axi_seven_segment`
- **File:** `rtl/IP's/7segment/axi_seven_segment.v`
- **Sub-blocks:** `seven_segment_decoder.v`, `seven_segment_mux.v`.
- **Top Pins:** `seg[6:0]`, `an[3:0]`.

---

## 10. Existing Testbenches

1. `tb/tb_soc_overall_verification.sv`: Master 18-test case regression testbench verifying full SoC operations (firmware boot, memory, interconnect routing, peripherals, thermal policy TC-16).
2. `tb/tb_soc_veer_el2_temperature_fan.sv`: Subsystem testbench for thermal management and closed-loop control.
3. `tb/tb_soc_veer_el2_firmware_exec.sv`: Bare-metal C firmware bring-up testbench.
4. `tb/tb_soc_interconnect_uart_spi_pwm_7seg_gpio_timer.sv`: Peripheral bus integration testbench.
5. `tb/uart_standalone_tb.sv`: Unit testbench for UART.

---

## 11. Existing UVM Packages, Interfaces, and VIPs

1. Subsystem VIP prototypes in `tb/`:
   - `tb/gpio_uvm_tb/` (`gpio_pkg.sv`, `gpio_if.sv`, `gpio_driver.sv`, etc.)
   - `tb/uart_uvm_tb/` (`uart_pkg.sv`, `uart_if.sv`, `uart_driver.sv`, etc.)
   - `tb/spi_uvm_tb/` (`spi_pkg.sv`, `spi_if.sv`, `spi_driver.sv`, etc.)
   - `tb/pwm_uvm_tb/` (`pwm_pkg.sv`, `pwm_if.sv`, `pwm_driver.sv`, etc.)
   - `tb/seven_segment_uvm_tb/` (`seven_segment_pkg.sv`, `seven_segment_if.sv`, etc.)
2. Reference Architecture Archive (`/home/student/Downloads/soc_top_uvm_tb.zip`):
   - `soc_pkg.sv`: Top-level package definition importing subsystem VIPs.
   - `tb_top.sv`: Top-level static testbench with clock/reset, interface instantiations, DUT instantiation, and `uvm_config_db::set()`.
   - `soc_env.sv`: Dynamic UVM environment instantiating VIP agents and retrieving virtual interfaces.
   - `soc_test.sv`: Base UVM test executing `run_test()`.

---

## 12. Existing VCS Compilation Filelists

- `run/soc_overall_verification.f`: Master VCS compilation filelist containing all VeeR EL2 core packages/files, interconnect, unified memory, adapters, and peripheral modules.
- `run/soc_veer_el2_temperature_fan.f`
- `run/soc_veer_el2_firmware_exec.f`
- `run/soc_interconnect_uart_spi_pwm_7seg_gpio_timer.f`
- `run/soc_interconnect_uart.f`

---

## 13. Interface Selection Justification (Phase 3 Alignment)

- **Selected Interface:** GPIO External Input Interface (`gpio_uvm_if`).
- **DUT Module:** `soc_veer_el2_temperature_fan_top`.
- **DUT Target Port:** `gpio_io[31:0]` (`inout wire [31:0]`).
- **Direction:** Bidirectional pad, operated in external input mode during test.
- **Interface Signal Name:** `gpio_uvm_if.gpio_io` driven by `gpio_uvm_if.gpio_in` via driver enable `gpio_uvm_if.gpio_drive_en`.
- **Connection Scheme:**
  `dut.gpio_io` connected directly to `gpio_if_inst.gpio_io`.
- **Why GPIO is the optimal choice:**
  1. **Strictly aligns with Prompt Preferred Selection #1**: The user designated GPIO external input as the primary preferred interface.
  2. **Zero Contention by Design**: At system reset, the GPIO register `s_reg_dir` defaults to `32'h0000_0000`, setting all 32 internal drivers to high-Z (`1'bz`). The external UVM driver can drive arbitrary 32-bit test vectors with zero contention.
  3. **Direct Pin-to-Register Observability**: The driven stimulus directly appears on the boundary pins `dut.gpio_io`, passes through the 2-stage input synchronizers (`sync_reg`), and reaches `dut.gpio_inst.gpio_i`.
  4. **Multi-Pattern Verification**: Allows driving distinct 32-bit patterns (`0xA5A5_5A5A`, `0x5A5A_A5A5`, `0xDEAD_BEEF`, `0x1234_5678`) to unequivocally prove static-to-dynamic signal propagation.
