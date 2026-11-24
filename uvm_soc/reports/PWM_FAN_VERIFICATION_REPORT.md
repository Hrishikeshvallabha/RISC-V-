# PWM Fan Speed Controller Subsystem Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. Subsystem Architecture & Register Mapping

The PWM Fan Controller generates a high-precision pulse-width modulated signal to drive the external cooling fan. It is mapped to Interconnect Slave Port **M05** at base address `0x4000_A000` (4 KiB address space: `0x4000_A000` - `0x4000_AFFF`).

### Register Map
| Offset | Name | Type | Reset Value | Description |
| :---: | :---: | :---: | :---: | :--- |
| `0x00` | `slv_reg0` | R/W | `0x0000_0000` | Byte 0 (`[7:0]`) controls Duty Cycle: 0 (0%) to 255 (100%) |
| `0x04` | `slv_reg1` | R/W | `0x0000_0000` | Reserved / Control Options |
| `0x08` | `slv_reg2` | R/W | `0x0000_0000` | Reserved Status |
| `0x0C` | `slv_reg3` | R/W | `0x0000_0000` | Reserved Interrupt Mask |

### Modulation Mechanics
- 8-bit free-running counter `pwm_counter` counts from 0 to 255 (period = 256 clock cycles = 2.56 $\mu$s at 100 MHz).
- Output rule: `pwm_out_o = (pwm_counter < slv_reg0[7:0])`.
- Duty cycle percentage: $\text{Duty (\%)} = \frac{\text{slv\_reg0}[7:0]}{256} \times 100\%$.

---

## 2. UVM VIP Architecture

- **Agent Name:** `pwm_agent` (Mode: Passive Protocol Monitor).
- **Monitor (`pwm_monitor`):**
  - Continuously samples `pwm_out_o` on rising edges of `clk`.
  - Measures high-time cycles ($T_{\text{high}}$) and total period cycles ($T_{\text{period}}$).
  - Computes instantaneous duty cycle: $\text{Duty} = \frac{T_{\text{high}}}{T_{\text{period}}} \times 100.0\%$.
  - Generates `pwm_seq_item` with duty cycle percentage and period length.
- **Scoreboard (`pwm_scoreboard`):**
  - Validates stability of PWM period ($256 \pm 1$ cycles).
  - Verifies modulation across thermal policy tiers.
- **Coverage (`pwm_coverage`):**
  - Bins duty cycles:
    - `duty_zero`: 0%
    - `duty_quiet_25`: $22\% - 28\%$ (Set point: 25% / 64)
    - `duty_warm_50`: $47\% - 53\%$ (Set point: 50% / 128)
    - `duty_boost_85`: $82\% - 88\%$ (Set point: 85% / 217)
    - `duty_full_100`: $98\% - 100\%$ (Set point: 100% / 255)
- **Assertions (`pwm_assertions`):**
  - Verifies that `pwm_out_o` contains no unknown (X) or high-Z (Z) states.

---

## 3. Test Cases and Execution Evidence

1. **`pwm_basic_test`:**
   - Measures default PWM waveform parameters over 4 full PWM cycles ($>10\,\mu\text{s}$).
   - Confirms period stability and duty measurement.
2. **`pwm_boundary_test`:**
   - Observes PWM modulation across all operational tiers driven by closed-loop CPU firmware.

---

## 4. Verification Verdict

All PWM Fan Controller tests passed cleanly with 0 errors and 0 assertion failures.
