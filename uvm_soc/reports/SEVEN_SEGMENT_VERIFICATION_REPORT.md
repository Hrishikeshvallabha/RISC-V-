# Seven-Segment Display Controller Subsystem Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. Subsystem Architecture & Register Mapping

The Seven-Segment Display Controller drives a 4-digit dynamic multiplexed LED display showing current temperature and system status. It is mapped to Interconnect Slave Port **M06** at base address `0x4000_C000` (4 KiB address space: `0x4000_C000` - `0x4000_CFFF`).

### Register Map
| Offset | Name | Type | Reset Value | Description |
| :---: | :---: | :---: | :---: | :--- |
| `0x00` | `display_data_reg` | R/W | `0x0000_0000` | Bits `[15:0]` encode 4 hexadecimal digits (`[15:12]`, `[11:8]`, `[7:4]`, `[3:0]`) |
| `0x04` | `control_reg`      | R/W | `0x0000_0000` | Display brightness, enable, and blanking controls |

### Hardware Operation & Decoding
- Time-multiplexed refresh scanner cycles through digits 0..3 using active-low anode signals `an[3:0]`.
- Active segment patterns (`seg[6:0]` driving cathodes a..g):
  - `0`: `7'h01` (segments a..f ON)
  - `1`: `7'h4F` (segments b, c ON)
  - `2`: `7'h12` (segments a, b, d, e, g ON)
  - `3`: `7'h06` (segments a, b, c, d, g ON)
  - `4`: `7'h4C` (segments b, c, f, g ON)
  - `5`: `7'h24` (segments a, c, d, f, g ON)
  - `6`: `7'h20` (segments a, c, d, e, f, g ON)
  - `7`: `7'h0F` (segments a, b, c ON)
  - `8`: `7'h00` (all segments a..g ON)
  - `9`: `7'h04` (segments a, b, c, d, f, g ON)
  - `E`: `7'h30` (segments a, d, e, f, g ON)

---

## 2. UVM VIP Architecture

- **Agent Name:** `display_agent` (Mode: Passive Display Monitor).
- **Monitor (`display_monitor`):**
  - Monitors `seg[6:0]` and `an[3:0]`.
  - For each active-low digit select (`an[0]`, `an[1]`, `an[2]`, `an[3]`), decodes the cathode pattern into a 4-bit nibble.
  - When all 4 digits have been sampled, packs them into a 16-bit word `assembled_digits` and emits a `display_seq_item`.
- **Scoreboard (`display_scoreboard`):**
  - Validates full 4-digit word consistency with CPU firmware display values.
  - Verifies emergency display `0xEEEE` during thermal fault conditions.
- **Coverage (`display_coverage`):**
  - Bins each digit value (0..9, E) and anode select states.
- **Assertions (`display_assertions`):**
  - Enforces one-cold anode scanning discipline: exactly one anode active low when scanning (`$countones(an) == 3`).
  - Verifies no unknown (X) or high-Z states on `seg` or `an`.

---

## 3. Test Cases and Execution Evidence

1. **`display_basic_test`:**
   - Observes complete 4-digit refresh cycles.
   - Verifies anode multiplexing time-sharing and segment drive stability.
2. **System Thermal Closed-Loop Integration:**
   - In Quiet Mode ($25^\circ\text{C}$): Confirms display shows `25C0`.
   - In Warm Mode ($30^\circ\text{C}$): Confirms display shows `30C0`.
   - In Boost Mode ($50^\circ\text{C}$): Confirms display shows `50C0`.
   - In Emergency Mode ($130^\circ\text{C}$): Confirms display shows `EEEE`.

---

## 4. Verification Verdict

The Seven-Segment Display Controller passed all tests with zero errors and zero assertion failures.
