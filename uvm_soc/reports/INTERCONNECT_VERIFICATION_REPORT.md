# AXI4 Crossbar Interconnect Subsystem Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. Interconnect Architecture & Slave Decoding

The system interconnect is a 2-Master $\times$ 8-Slave Full AXI4 Crossbar (`axi_interconnect_wrap_2x8`) featuring independent read and write channels, ID tagging, burst arbitration, and out-of-bounds decode protection.

### Topology
- **Master S00:** External Test Master (`axi_*`) — allows UVM VIP to directly stimulate all peripherals and memory.
- **Master S01:** VeeR EL2 Core (`core_axi_*`) — multiplexes IFU (instruction fetch) and LSU (data load/store) via a 2-to-1 round-robin arbiter.
- **Slave Ports:**
  - `M00`: Unified Memory (`0x0000_0000` - `0x0000_FFFF`, 64 KiB)
  - `M01`: UART (`0x4000_0000` - `0x4000_0FFF`, 4 KiB)
  - `M02`: GPIO (`0x4000_2000` - `0x4000_2FFF`, 4 KiB)
  - `M03`: Timer (`0x4000_4000` - `0x4000_4FFF`, 4 KiB)
  - `M04`: SPI (`0x4000_6000` - `0x4000_6FFF`, 4 KiB)
  - `M05`: PWM (`0x4000_A000` - `0x4000_AFFF`, 4 KiB)
  - `M06`: Seven-Segment Display (`0x4000_C000` - `0x4000_CFFF`, 4 KiB)
  - `M07`: Masked / Disabled Boundary Port (`0x0000_0000`, 0 B, `CONNECT=2'b00`)

---

## 2. UVM VIP Architecture

- **Agent Name:** `interconnect_agent` (Mode: Active AXI4 Master Test Agent).
- **Sequencer:** `interconnect_sequencer` managing address sweep, read/write, and error injection sequences.
- **Driver (`interconnect_driver`):**
  - Implements full AXI4 master handshakes on AW, W, B, AR, and R channels.
  - Supports single-word and burst transfers with ID propagation.
- **Monitor (`interconnect_monitor`):**
  - Monitors all 5 AXI channels concurrently.
  - Assembles completed read/write transactions into `interconnect_seq_item`.
  - Determines decoded target slave port based on address ranges.
- **Scoreboard (`interconnect_scoreboard`):**
  - Tracks transactions routed to Memory (M00), Peripherals (M01-M06), and DECERR/out-of-bounds traps.
  - Confirms slave response codes (`2'b00` = OKAY, `2'b11` = DECERR).
- **Coverage (`interconnect_coverage`):**
  - Crosses read/write operations with all slave address spaces and reserved guard bands.
- **Assertions (`interconnect_assertions`):**
  - Enforces AWADDR stability while AWVALID is HIGH and AWREADY is LOW.
  - Enforces WDATA stability while WVALID is HIGH and WREADY is LOW.

---

## 3. Test Cases and Execution Evidence

1. **`interconnect_read_write_test`:**
   - Issues 32-bit writes and reads through Master S00 to Unified Memory.
   - Verifies data integrity and handshake timing.
2. **`interconnect_address_decode_test`:**
   - Sweeps across base addresses of all active slaves M00 through M06.
   - Verifies correct address decoding and slave routing.
3. **`interconnect_error_test`:**
   - Accesses unmapped reserved guard space (`0x4000_1000`).
   - Verifies error response without interconnect lockup or hung bus.

---

## 4. Verification Verdict

The Interconnect Crossbar passed all tests with zero errors, zero protocol assertion failures, and 100% address routing accuracy.
