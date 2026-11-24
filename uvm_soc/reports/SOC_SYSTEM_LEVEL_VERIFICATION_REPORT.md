# System-Level Closed-Loop Verification Report

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Target Root:** `/home/student/Documents/078_H/proj_dir/`  
**UVM Directory:** `/home/student/Documents/078_H/proj_dir/uvm_soc/`  
**Date:** November 7, 2026  
**Status:** **VERIFIED**  

---

## 1. System-Level Verification Objectives

The primary objective of this SoC is autonomous, real-time closed-loop temperature monitoring and fan speed regulation. The system integrates:
1. **Sensor Stimulus:** External digital temperature sensor monitored via SPI Master (M04).
2. **Firmware Execution:** VeeR EL2 CPU running temperature control policy algorithm.
3. **Actuator Control:** PWM Fan Speed Controller (M05) modulating fan cooling effort.
4. **Local Display:** 4-digit Seven-Segment LED display (M06) showing real-time temperature and status.
5. **Remote Telemetry:** 16550 UART (M01) emitting diagnostic messages.
6. **Auxiliary I/O:** 32-bit GPIO (M02) and Hardware Timer (M03).

---

## 2. Four-Tier Closed-Loop Thermal Policy Verification

The UVM system scoreboard (`soc_system_scoreboard`) validates all four operational tiers in real time:

| Operational Mode | Temperature Range ($T$) | PWM Target Duty Cycle | Acceptable Tolerance | Seven-Segment Pattern | Telemetry Output | Verification Status |
| :--- | :---: | :---: | :---: | :---: | :--- | :---: |
| **Tier 1: Quiet Mode** | $T \le 25^\circ\text{C}$ | **25%** (`0x40`) | $22\% - 28\%$ | `0x25C0` ("25 C") | `[TEMP] 25C -> QUIET (25% FAN)` | **PASSED** |
| **Tier 2: Warm Mode** | $26^\circ\text{C} \le T \le 45^\circ\text{C}$ | **50%** (`0x80`) | $47\% - 53\%$ | `0x30C0` ("30 C") | `[TEMP] 30C -> WARM (50% FAN)` | **PASSED** |
| **Tier 3: Boost Mode** | $46^\circ\text{C} \le T \le 70^\circ\text{C}$ | **85%** (`0xD9`) | $82\% - 88\%$ | `0x50C0` ("50 C") | `[TEMP] 50C -> BOOST (85% FAN)` | **PASSED** |
| **Tier 4: Fail-Safe Emergency** | $T > 70^\circ\text{C}$ (e.g. $130^\circ\text{C}$) | **100%** (`0xFF`) | $97\% - 100\%$ | `0xEEEE` ("EEEE") | `[ALERT] OVERTEMP -> EMERGENCY FAN 100%` | **PASSED** |

---

## 3. End-to-End Test Scenarios

### Scenario A: Normal Operating Mode Bring-Up (`soc_temperature_fan_normal_test`)
- Injects nominal temperature ($25^\circ\text{C}$).
- Verifies CPU boot, SPI read, PWM fan speed stabilization at 25%, and Seven-Segment display reading `25C0`.

### Scenario B: Thermal Boundary & Emergency Stress (`soc_temperature_fan_boundary_test`)
- Steps sensor from $25^\circ\text{C} \rightarrow 30^\circ\text{C} \rightarrow 50^\circ\text{C} \rightarrow 130^\circ\text{C}$.
- Verifies proportional fan speed scaling across all tiers and transition to emergency fail-safe mode (`EEEE` on display, 100% fan duty).

### Scenario C: Concurrent Multi-Peripheral Traffic (`soc_concurrent_peripheral_test`)
- Concurrently stimulates GPIO pin toggles, UART RX character streaming, Hardware Timer measurement pulses, and AXI Crossbar read/write transactions while CPU executes firmware.
- Verifies zero bus starvation, zero arbiter deadlocks, and uninterrupted thermal regulation.

### Scenario D: Full SoC Master Regression (`soc_full_regression_test`)
- Executes all multi-scenario phases back-to-back in a single comprehensive regression run.

---

## 4. System Verification Verdict

All closed-loop control criteria, multi-peripheral concurrency, and emergency fail-safe responses were verified with zero errors.
