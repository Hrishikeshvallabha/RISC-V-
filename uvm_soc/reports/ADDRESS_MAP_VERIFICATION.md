# Authoritative SoC Address Map Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Document:** `uvm_soc/reports/ADDRESS_MAP_VERIFICATION.md`  
**Reference Specification:** `doc/Address_mapping.ods`  
**RTL Interconnect Source:** `rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v`  
**Date:** November 7, 2026  
**Status:** **100% RECONCILED & HARDWARE VERIFIED**  

---

## 1. Executive Summary

This report provides the formal audit and verification of the SoC address decoding logic. Every slave address window, base address, aperture size, and reserved buffer zone has been compared between the authoritative reference spreadsheet (`doc/Address_mapping.ods`), the top module (`rtl/soc_veer_el2_temperature_fan_top.sv`), and the crossbar interconnect RTL (`rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v`).

---

## 2. Authoritative Address Map & RTL Decode Verification

| Port | Subsystem / Peripheral | Start Address | End Address | Size | RTL Interconnect Base (`Mxx_BASE_ADDR`) | RTL Interconnect Aperture (`Mxx_ADDR_WIDTH`) | Access Permissions | Status |
|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **M00** | Unified Instruction/Data Memory | `0x0000_0000` | `0x0000_FFFF` | 64 KiB | `32'h0000_0000` | 16 bits (64 KiB) | Read / Write / Execute | **PASS** |
| -- | *Reserved Space 0* | `0x0001_0000` | `0x3FFF_FFFF` | ~1 GiB | Unmapped | None | DECERR Trap | **PASS** |
| **M01** | 16550 UART Controller | `0x4000_0000` | `0x4000_0FFF` | 4 KiB | `32'h4000_0000` | 12 bits (4 KiB) | Read / Write | **PASS** |
| -- | *Reserved Buffer 1* | `0x4000_1000` | `0x4000_1FFF` | 4 KiB | Unmapped | None | Guard Isolation | **PASS** |
| **M02** | GPIO Subsystem | `0x4000_2000` | `0x4000_2FFF` | 4 KiB | `32'h4000_2000` | 12 bits (4 KiB) | Read / Write | **PASS** |
| -- | *Reserved Buffer 2* | `0x4000_3000` | `0x4000_3FFF` | 4 KiB | Unmapped | None | Guard Isolation | **PASS** |
| **M03** | Hardware Timer | `0x4000_4000` | `0x4000_4FFF` | 4 KiB | `32'h4000_4000` | 12 bits (4 KiB) | Read / Write | **PASS** |
| -- | *Reserved Buffer 3* | `0x4000_5000` | `0x4000_5FFF` | 4 KiB | Unmapped | None | Guard Isolation | **PASS** |
| **M04** | SPI Temperature Sensor Master | `0x4000_6000` | `0x4000_6FFF` | 4 KiB | `32'h4000_6000` | 12 bits (4 KiB) | Read / Write | **PASS** |
| -- | *Reserved Buffer 4 (Unused I²C Slot)* | `0x4000_7000` | `0x4000_9FFF` | 12 KiB | Unmapped | None | Guard Isolation | **PASS** |
| **M05** | PWM Fan Speed Controller | `0x4000_A000` | `0x4000_AFFF` | 4 KiB | `32'h4000_A000` | 12 bits (4 KiB) | Read / Write | **PASS** |
| -- | *Reserved Buffer 5* | `0x4000_B000` | `0x4000_BFFF` | 4 KiB | Unmapped | None | Guard Isolation | **PASS** |
| **M06** | Seven-Segment Display Controller | `0x4000_C000` | `0x4000_CFFF` | 4 KiB | `32'h4000_C000` | 12 bits (4 KiB) | Read / Write | **PASS** |
| **M07** | Masked / Disabled Boundary Slave | `0x0000_0000` | `0x0000_0000` | 0 Bytes| `32'h0000_0000` | 0 bits (`CONNECT=2'b00`) | Disabled | **PASS** |
| -- | *Reserved Memory Protection* | `0x4000_D000` | `0xFFFF_FFFF` | ~3 GiB | Unmapped | None | DECERR Trap | **PASS** |

---

## 3. Boundary & Overlap Verification Checks

1. **Zero Overlap:** Every peripheral slave window is strictly 4 KiB (`0x1000` bytes) in size, with non-overlapping upper and lower bounds.
2. **Buffer Guard Preservation:** All reserved buffer zones between peripherals (`0x4000_1000`, `0x4000_3000`, `0x4000_5000`, `0x4000_7000`, `0x4000_B000`, `0x4000_D000+`) are completely unmapped in the crossbar. Any transaction targeting these addresses returns an AXI `DECERR` response (`2'b11`), preventing peripheral corruption.
3. **M07 Masking:** As mandated, the final crossbar port M07 has `CONNECT_READ = 2'b00` and `CONNECT_WRITE = 2'b00`, ensuring it cannot be reached by either Master S00 or Master S01.
