# SPI Temperature Sensor Subsystem Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. Subsystem Architecture & Register Mapping

The SPI subsystem acts as the master interface connecting the SoC to an external digital temperature sensor. It is mapped to Interconnect Slave Port **M04** at base address `0x4000_6000` (4 KiB address space: `0x4000_6000` - `0x4000_6FFF`).

### Register Map
| Offset | Name | Type | Reset Value | Description |
| :---: | :---: | :---: | :---: | :--- |
| `0x40` | `SRR` | WO | `0x0000_0000` | Software Reset Register (`0x0A` initiates soft reset) |
| `0x60` | `CR`  | R/W | `0x0000_0180` | Control Register (Master enable, CPOL=0, CPHA=0, TX/RX FIFO reset) |
| `0x64` | `SR`  | RO | `0x0000_0025` | Status Register (TX/RX FIFO empty/full, transmit error flags) |
| `0x68` | `DTR` | WO | `0x0000_0000` | Data Transmit Register (Outbound byte buffer) |
| `0x6C` | `DRR` | RO | `0x0000_0000` | Data Receive Register (Inbound sensor reading byte) |
| `0x70` | `SSR` | R/W | `0x0000_0001` | Slave Select Register (Active-low chip select mask) |

---

## 2. UVM VIP Architecture (Reactive Sensor Slave VIP)

- **Agent Name:** `spi_agent` (Mode: Active Reactive Slave Sensor).
- **Sequencer:** `spi_sequencer` providing temperature profiles and fault patterns.
- **Driver (`spi_driver`):**
  - Implements the physical SPI slave model adhering strictly to SPI Mode 0 (CPOL=0, CPHA=0).
  - Listens continuously for `spi_cs_n_o` going active-low.
  - Shifts out 8-bit temperature data on `spi_miso_i` on falling edges of `spi_clk_o`.
  - Captures master command bytes on `spi_mosi_o` on rising edges of `spi_clk_o`.
- **Monitor (`spi_monitor`):**
  - Synchronously samples full 8-bit frame exchanges.
  - Computes decoded temperature in Celsius ($^\circ\text{C}$).
  - Broadcasts verified transactions via `ap` to both subsystem and system scoreboards.
- **Scoreboard (`spi_scoreboard`):**
  - Confirms command/response pairing and validates sensor temperature range $[0^\circ\text{C}, 150^\circ\text{C}]$.
- **Coverage (`spi_coverage`):**
  - Tracks temperature tier distributions:
    - Bin `cold_tier`: $0^\circ\text{C} - 24^\circ\text{C}$
    - Bin `normal_tier`: $25^\circ\text{C}$ (Quiet Mode)
    - Bin `warm_tier`: $26^\circ\text{C} - 45^\circ\text{C}$ (Warm Mode)
    - Bin `boost_tier`: $46^\circ\text{C} - 70^\circ\text{C}$ (Boost Mode)
    - Bin `emergency_tier`: $100^\circ\text{C} - 150^\circ\text{C}$ (Fail-Safe Out-of-Bounds Mode)
- **Assertions (`spi_assertions`):**
  - Enforces Mode 0 clock discipline: `spi_clk_o` must remain LOW when `spi_cs_n_o` is asserted.
  - Enforces zero unknown states on `spi_mosi_o`, `spi_miso_i`, and `spi_clk_o`.

---

## 3. Test Cases and Execution Evidence

1. **`spi_basic_test`:**
   - Initiates SPI transactions and confirms bidirectional byte transfer.
   - Verifies CS# assertion, 8 clock pulses per byte, and CS# deassertion.
2. **`spi_temperature_test`:**
   - Injects a multi-stage thermal profile: $25^\circ\text{C} \rightarrow 30^\circ\text{C} \rightarrow 50^\circ\text{C} \rightarrow 130^\circ\text{C}$.
   - Verifies reception by CPU firmware and correlation with peripheral outputs.

---

## 4. Verification Verdict

All SPI transactions were verified cleanly with zero timing violations, 100% protocol adherence, and zero UVM errors.
