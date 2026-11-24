# RISC-V Based SoC for Smart Temperature Monitoring and Fan Control

## Overview

This project focuses on the design and verification of a RISC-V based System-on-Chip (SoC) for smart temperature monitoring and automatic fan control.

The SoC integrates a RISC-V processor with memory, an interconnect, and memory-mapped peripheral interfaces. It is designed to support temperature acquisition, peripheral communication, timer-based operations, and PWM-based fan control.

The project also explores a scalable SoC architecture in which additional peripherals can be integrated through a structured address map and interconnect.

## Project Objectives

- Design and integrate a RISC-V based SoC architecture.
- Interface memory-mapped peripherals with the processor.
- Implement communication interfaces such as UART and SPI.
- Support GPIO and timer-based operations.
- Enable PWM-based fan speed control.
- Develop a structured peripheral address map.
- Verify the functionality of individual modules and SoC-level interactions.

## System Architecture

The proposed SoC architecture consists of the following major components:

- **RISC-V Processor:** Executes instructions and controls the SoC.
- **Instruction and Data Memory:** Stores program instructions and data.
- **Interconnect:** Provides communication between the processor and peripheral modules.
- **UART:** Supports serial communication.
- **GPIO:** Provides general-purpose digital input and output.
- **Timer:** Supports timing and counter-based operations.
- **PWM Controller:** Generates PWM signals for fan-speed control.
- **SPI Interface:** Supports communication with external temperature-sensing devices.
- **Interrupt Handling:** Supports peripheral interrupt management.

Additional peripheral regions are reserved in the address map for future integration.

## Peripheral Address Map

The peripheral address space is organized into 4 KB regions, beginning at `0x40000000`.

| Peripheral | Start Address | End Address |
|---|---|---|
| UART | `0x40000000` | `0x40000FFF` |
| GPIO | `0x40002000` | `0x40002FFF` |
| Timer | `0x40004000` | `0x40004FFF` |
| PWM | `0x40006000` | `0x40006FFF` |
| SPI | `0x40008000` | `0x40008FFF` |
| Watchdog Timer | `0x4000A000` | `0x4000AFFF` |
| FFT Control | `0x4000C000` | `0x4000CFFF` |
| FFT Memory Interface | `0x4000E000` | `0x4000EFFF` |
| FIR | `0x40010000` | `0x40010FFF` |
| ADC Interface | `0x40012000` | `0x40012FFF` |
| QRS Detector | `0x40014000` | `0x40014FFF` |
| AES-128 | `0x40016000` | `0x40016FFF` |
| Interrupt Aggregator | `0x40018000` | `0x40018FFF` |

**Note:** The address map also includes reserved 4 KB buffer regions between peripheral regions to support future expansion. The listed peripheral map represents the proposed address-space organization; actual implementation status should be checked against the RTL.

## Hardware and Design Features

- RISC-V based processor architecture.
- Memory-mapped peripheral communication.
- Modular peripheral integration.
- Structured address decoding.
- UART serial communication.
- GPIO input/output control.
- Timer and PWM functionality.
- SPI-based sensor communication.
- Interrupt-oriented peripheral architecture.
- Expandable peripheral address space.

## Register Mapping

Peripherals use memory-mapped registers that allow the processor to configure and communicate with individual hardware modules.

Examples include:

| Peripheral | Register | Address |
|---|---|---|
| UART | RBR / RX Data | `0x40000000` |
| UART | THR / TX Data | `0x40000000` |
| UART | Interrupt Enable | `0x40000004` |
| GPIO | DATA_I | `0x40002000` |
| GPIO | DATA_O | `0x40002004` |
| GPIO | DIR | `0x40002008` |
| Timer | CTRL | `0x40004000` |
| Timer | LOAD | `0x40004004` |
| PWM | PWM_PERIOD | `0x40006000` |
| PWM | PWM_DUTY | `0x40006004` |
| SPI | SPI_TXDATA | `0x40008000` |
| SPI | SPI_RXDATA | `0x40008004` |

Refer to the address mapping documentation for the complete register-level specification.

## Repository Structure

The repository is organized into separate directories for RTL design, simulation, documentation, and verification.

```text
RISC-V-SoC/
│
├── rtl/
│   ├── processor/
│   ├── memory/
│   ├── interconnect/
│   └── peripherals/
│       ├── uart/
│       ├── gpio/
│       ├── timer/
│       ├── pwm/
│       └── spi/
│
├── tb/
│   └── testbenches/
│
├── run/
│   └── simulation_scripts/
│
├── doc/
│   ├── hardware_specification.pdf
│   └── address_mapping.ods
│
├── README.md
```

*The directory structure above is illustrative. Adjust it to match the actual repository contents.*

## Design and Verification

The project uses RTL design and simulation-based verification to evaluate the functionality of the processor subsystem, interconnect, and peripheral interfaces.

Verification activities include:

- Module-level functional testing.
- Peripheral read and write transactions.
- Interconnect communication testing.
- UART transmission and reception testing.
- SoC-level integration testing.

Simulation results and verification status should be documented alongside the corresponding testbenches and logs.

## Tools and Technologies

- **HDL:** Verilog / SystemVerilog (as used by individual modules)
- **Processor Architecture:** RISC-V
- **Simulation:** Synopsys VCS
- **Waveform Debugging:** Synopsys Verdi
- **Design Verification:** RTL simulation and testbenches
- **Version Control:** Git and GitHub

## Reference Documentation

The repository includes the following design references:

- `RISC-V_VeeR_EL2_PRM.pdf` – VeeR EL2 Programmer's Reference Manual.
- `Address_mapping.ods` – Peripheral address mapping and register definitions.

The VeeR EL2 reference manual is used as processor documentation; its inclusion does not by itself establish the exact processor configuration or implementation in this SoC.

## Future Enhancements

- Complete integration of the peripheral subsystem.
- Expand interrupt handling and peripheral support.
- Integrate and verify the temperature sensor interface.
- Implement and validate automatic fan-speed control.
- Extend SoC-level verification.
- Improve scalability through additional memory-mapped peripherals.

## Project Information

**Project Title:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control

**Domain:** VLSI Design and Verification

**Project Type:** Honors Project

---

*This repository contains the RTL design, verification environment, address mapping, and documentation associated with the RISC-V based SoC project.*


## RISC-V Core

The RISC-V processor core used in this project is based on an
externally maintained GitHub repository.
https://github.com/chipsalliance/Cores-VeeR-EL2.git
Refer to the original repository for the processor core source code.
