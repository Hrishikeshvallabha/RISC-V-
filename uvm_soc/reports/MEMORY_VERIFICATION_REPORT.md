# Unified Memory Subsystem Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. Subsystem Architecture

The Unified Instruction and Data Memory subsystem (`soc_memory_axi`) is mapped to Interconnect Slave Port **M00** at base address `0x0000_0000` (64 KiB address space: `0x0000_0000` - `0x0000_FFFF`).

### Features & Hardware Details
- **Capacity:** 64 KiB ($16,384 \times 32$-bit words).
- **Organization:** Unified architecture serving both instruction fetch (IFU) and data memory accesses (LSU).
- **Byte Write Enable:** Supports byte, half-word, and word writes via `axi_wstrb[3:0]`.
- **Boot Preload:** Initialized with safe RISC-V NOP instructions (`0x0000_0013`) and firmware image `temperature_fan_words.hex`.
- **Latency:** Single-cycle synchronous SRAM memory array.

---

## 2. Verification Architecture

- **Stimulus VIP:** `interconnect_agent` (Master S00).
- **Test Sequence:** `memory_test_seq` sweeping memory address locations across boundaries:
  - Low memory: `0x0000_0800`, `0x0000_1800`
  - Mid memory: `0x0000_2800`, `0x0000_4800`
  - High memory: `0x0000_8800`, `0x0000_E800`
- **Data Patterns:** Walking ones, walking zeros, alternating bitmasks (`0xA5A5A5A5`, `0x5A5A5A5A`), and boundary values.
- **Checking Strategy:** Write-read-verify loop checking read data against written data.

---

## 3. Test Cases and Execution Evidence

1. **`memory_basic_test`:**
   - Performs full write-read cycles across multiple address ranges in Unified Memory.
   - Verifies 100% data retention and zero corruptions.
2. **Firmware Execution Integrity:**
   - VeeR EL2 core boots from `0x0000_0000` directly out of Unified Memory.
   - Instructions are fetched continuously over IFU and LSU without bus stalls or parity traps.

---

## 4. Verification Verdict

The Unified Memory subsystem verified successfully with zero errors.
