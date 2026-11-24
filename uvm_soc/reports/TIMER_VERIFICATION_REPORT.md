# Hardware Timer Subsystem Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. Subsystem Architecture & Register Mapping

The Hardware Timer subsystem provides periodic timing pulses, external measurement gating, and input capture interrupts. It is mapped to Interconnect Slave Port **M03** at base address `0x4000_4000` (4 KiB address window: `0x4000_4000` - `0x4000_4FFF`).

### Register Map
| Offset | Name | Type | Reset Value | Description |
| :---: | :---: | :---: | :---: | :--- |
| `0x00` | `CTRL`    | R/W | `0x0000_0000` | Timer Control (Enable, Prescaler, Mode) |
| `0x04` | `LOAD`    | R/W | `0x0000_0000` | Counter Initial Load Value |
| `0x08` | `VAL`     | RO  | `0x0000_0000` | Current 32-bit Down-Counter Value |
| `0x0C` | `PRE`     | R/W | `0x0000_0000` | Clock Prescaler Divisor |
| `0x10` | `INT_EN`  | R/W | `0x0000_0000` | Interrupt Enable Mask |
| `0x14` | `INT_STS` | R/W | `0x0000_0000` | Interrupt Status & Clear (Write 1 to clear) |
| `0x18` | `CMP`     | R/W | `0x0000_0000` | Compare Match Register |
| `0x1C` | `CAP`     | RO  | `0x0000_0000` | Input Capture Value Register |

---

## 2. UVM VIP Architecture

- **Agent Name:** `timer_agent` (Active / Passive configurable via `soc_config`).
- **Sequencer:** `timer_sequencer` managing measurement pulses and capture sequences.
- **Driver (`timer_driver`):** Drives `timer_ext_meas_i` and `timer_capture_i` with controlled duty cycles and edge events.
- **Monitor (`timer_monitor`):** Observes `timer_pwm_o`, `timer_trigger_o`, and `timer_irq_o`, timestamping events and publishing items to `timer_scb`.
- **Scoreboard (`timer_scoreboard`):** Validates timer count down, compare match matches, and interrupt assertion latency.
- **Coverage (`timer_coverage`):** Measures coverage of external measurement logic levels, input capture assertions, and IRQ generation.
- **Assertions (`timer_assertions`):** Enforces no-X conditions on all output pins (`timer_irq_o`, `timer_pwm_o`, `timer_trigger_o`).

---

## 3. Test Cases and Execution Evidence

1. **`timer_basic_test`:**
   - Drives external measurement gating and input capture pulses.
   - Confirms proper signal propagation and absence of protocol violations.
2. **`timer_interrupt_test`:**
   - Exercises timer countdown to match value.
   - Observes `timer_irq_o` transition from 0 to 1 and confirms PIC line assertion.

---

## 4. Verification Verdict

All Timer tests passed cleanly with 0 UVM errors and 0 assertion violations.
