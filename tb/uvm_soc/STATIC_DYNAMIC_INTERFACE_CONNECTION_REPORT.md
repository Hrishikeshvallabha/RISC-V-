# Comprehensive Technical Verification Report: Static DUT to Dynamic UVM Driver Connection

**Project:** Design and Verification of a RISC-V Based SoC for Smart Temperature Monitoring and Fan Control  
**Author:** Antigravity AI Verification System  
**Date:** November 7, 2026  
**Status:** **FULLY VERIFIED & PASSED (100% Acceptance Criteria Met)**  
**Artifact Location:** `/home/student/Documents/078_H/proj_dir/tb/uvm_soc/STATIC_DYNAMIC_INTERFACE_CONNECTION_REPORT.md`  

---

## Executive Summary

This report documents the architectural design, implementation, and cycle-accurate functional verification of the first static-to-dynamic UVM interface connection for the RISC-V VeeR EL2 System-on-Chip (SoC).

Verification demonstrated that a dynamically constructed UVM driver class (`uvm_test_top.env.agent.drv`) successfully controlled and stimulated the physical boundary pins of the statically instantiated hardware DUT (`soc_veer_el2_temperature_fan_top`). This connection was established without modifying any existing RTL, interconnect, firmware, or baseline testbenches, with all new verification assets strictly compartmentalized inside `/home/student/Documents/078_H/proj_dir/tb/uvm_soc/`.

---

## 1. Selected Interface & Technical Justification

- **Selected Subsystem:** General-Purpose Input/Output (GPIO).
- **Interface Name:** `gpio_uvm_if` (`tb/uvm_soc/interfaces/gpio_uvm_if.sv`).
- **DUT Boundary Port:** `gpio_io[31:0]` (`inout wire [31:0]`).
- **Direction:** Bidirectional I/O bus operated in external test stimulus mode.
- **Why GPIO was Selected (Prompt Preferred Selection #1 Alignment):**
  1. **Strict Alignment with User Guidelines:** The specification prioritized GPIO external input as Preferred Selection #1 over UART RX and other peripherals.
  2. **Quiescent Zero-Contention State by Design:** Inspection of the actual GPIO register block RTL (`rtl/IP's/gpio/gpio_regs.sv`, line 207) confirmed that register `s_reg_dir` (`ADDR_DIR`) resets to `32'h0000_0000`. This default configures all 32 internal output enables (`oe`) to zero (`pad = 1'bz` in `gpio_bit.sv`). Consequently, the external UVM testbench driver can assert multi-bit stimulus patterns directly onto `gpio_io` with zero bus contention.
  3. **High-Bandwidth Multi-Bit Propagation:** Unlike a single-wire serial line that requires extensive serialization cycles, a 32-bit parallel bus enables driving multiple distinct 32-bit test vectors (`0xA5A5_5A5A`, `0x5A5A_A5A5`, `0xDEAD_BEEF`, `0x1234_5678`) to unequivocally prove static-to-dynamic signal propagation.
  4. **Multi-Stage Physical Observability:** Driven stimulus is directly observable on:
     - The static interface net (`gpio_if_inst.gpio_io`).
     - The DUT boundary pin (`dut.gpio_io`).
     - The internal pad input (`dut.gpio_inst.io`).
     - The two-stage synchronizer flip-flops (`sync_reg[1:0]`) inside `gpio_bit.sv` routing to `dut.gpio_inst.gpio_i`.

---

## 2. Actual DUT Module & Target Input Port

- **DUT Module Name:** `soc_veer_el2_temperature_fan_top`
- **Source File:** `rtl/soc_veer_el2_temperature_fan_top.sv`
- **Module Declaration Port (lines 112–114):**
  ```systemverilog
  // GPIO
  inout  wire [GPIO_NUM_BITS-1:0]  gpio_io,
  output wire                      gpio_intr_o,
  ```
- **Internal Subsystem Connection (lines 1536–1558):**
  ```systemverilog
  gpio_axi #(
      .NUM_BITS (GPIO_NUM_BITS)
  ) gpio_inst (
      .s_axi_aclk    (clk),
      .s_axi_aresetn (~rst),
      // ... AXI4-Lite slave interconnect wires ...
      .io            (gpio_io),
      .intr          (gpio_intr_o)
  );
  ```

---

## 3. Static vs Dynamic Architecture & Virtual Interface Mechanism

### 3.1 Static Components (Hardware Domain)
The DUT (`soc_veer_el2_temperature_fan_top`) and the SystemVerilog interface (`gpio_uvm_if`) are **static design units**. They are allocated by the simulator at elaboration time, exist in the hierarchy throughout the entire simulation, and have fixed signal nets and wires.

### 3.2 Dynamic Components (UVM Object Domain)
The UVM test (`riscv_soc_test`), environment (`riscv_soc_env`), agent (`gpio_agent`), sequencer (`gpio_sequencer`), driver (`gpio_driver`), and sequence items (`gpio_seq_item`) are **transient, class-based dynamic objects**. They are created at runtime in dynamic memory on the simulator heap during the UVM `build_phase`.

### 3.3 The Role of the Virtual Interface and UVM Config DB
A class-based dynamic object cannot directly declare or instantiate a static hardware interface. If a driver attempted to declare an interface instance, it would violate SystemVerilog language semantics. Furthermore, creating two separate interfaces would not connect the driver to the DUT.

Instead:
1. **Static Instance:** Exactly one interface (`gpio_if_inst`) is statically instantiated in the top-level testbench (`tb_riscv_soc_uvm.sv`).
2. **Physical DUT Binding:** The bidirectional net `gpio_if_inst.gpio_io` is connected directly to `dut.gpio_io`.
3. **Handle Publishing:** The top-level testbench places a typed handle referring to that static interface into `uvm_config_db`.
4. **Handle Retrieval:** The dynamic `gpio_driver` retrieves that handle in its `build_phase` into a `virtual gpio_uvm_if vif` variable.
5. **Direct Reference:** `vif` is not a duplicate interface or an IPC channel; it is an indirect pointer/handle to `gpio_if_inst`. When `vif.gpio_in` or `vif.gpio_drive_en` is modified in the driver's `run_phase`, the physical nets of `gpio_if_inst` transition immediately, and the statically wired `dut.gpio_io` sees the exact transition.

```
+---------------------------------------------------------------------------------------------------+
| Top-Level Static Module (tb_riscv_soc_uvm)                                                        |
|                                                                                                   |
|  +------------------------+                           +----------------------------------------+  |
|  | Static Interface       |  .gpio_io (32-bit wire)   | Actual Hardware SoC DUT                |  |
|  | (gpio_if_inst)         |==========================>| (soc_veer_el2_temperature_fan_top)     |  |
|  +------------------------+                           |   .gpio_io                             |  |
|              ^                                        +----------------------------------------+  |
|              |                                                                                    |
|              | Handle stored at "uvm_test_top.env.agent.drv", key "vif"                           |
|              |                                                                                    |
|  +------------------------+                                                                       |
|  | uvm_config_db          |                                                                       |
|  +------------------------+                                                                       |
|              |                                                                                    |
|              | Retrieved via uvm_config_db::get() during build_phase                              |
|              v                                                                                    |
|  +---------------------------------------------------------------------------------------------+  |
|  | Dynamic UVM Class Hierarchy (Heaped Objects)                                                |  |
|  |                                                                                             |  |
|  |  uvm_test_top (riscv_soc_test)                                                              |  |
|  |     └── env (riscv_soc_env)                                                                 |  |
|  |          └── agent (gpio_agent)                                                             |  |
|  |               └── drv (gpio_driver)                                                         |  |
|  |                    └── virtual gpio_uvm_if vif ─────────────────────────────────+           |  |
|  |                                                                                 │           |  |
|  |                        (vif dereferences directly to static gpio_if_inst) <─────┘           |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 4. Static Interface Implementation

- **File:** `tb/uvm_soc/interfaces/gpio_uvm_if.sv`
- **Code Extract:**
  ```systemverilog
  `timescale 1ns / 1ps

  interface gpio_uvm_if #(
      parameter int NUM_BITS = 32
  )(
      input logic clk,
      input logic rst_n
  );
      // Physical bidirectional net connected to DUT boundary gpio_io
      wire [NUM_BITS-1:0] gpio_io;

      // Driver stimulus controls
      logic [NUM_BITS-1:0] gpio_in;        // Stimulus value driven into DUT
      logic [NUM_BITS-1:0] gpio_drive_en;  // 1 = Active drive, 0 = High-Z

      // Continuous Tri-state Drive to Physical Boundary Net
      genvar i;
      generate
          for (i = 0; i < NUM_BITS; i = i + 1) begin : gen_gpio_drv
              assign gpio_io[i] = gpio_drive_en[i] ? gpio_in[i] : 1'bz;
          end
      endgenerate

      // Continuous Sampling Net (Passive observation)
      logic [NUM_BITS-1:0] gpio_sampled;
      assign gpio_sampled = gpio_io;

      // Clocking blocks and modports
      clocking drv_cb @(posedge clk);
          default input #1ns output #1ns;
          output gpio_in;
          output gpio_drive_en;
          input  gpio_sampled;
      endclocking

      clocking mon_cb @(posedge clk);
          default input #1ns;
          input gpio_sampled;
      endclocking

      modport drv_mp (clocking drv_cb, input clk, input rst_n);
      modport mon_mp (clocking mon_cb, input clk, input rst_n);
  endinterface : gpio_uvm_if
  ```

---

## 5. Interface Instantiation & DUT Connection in Top TB

- **File:** `tb/uvm_soc/tb_riscv_soc_uvm.sv`
- **Location of Instance:** Top-level module scope, line 43.
- **Connection Code Extract:**
  ```systemverilog
  // Static Interface Instantiation (Exactly One Instance)
  gpio_uvm_if #(
      .NUM_BITS(32)
  ) gpio_if_inst (
      .clk   (clk),
      .rst_n (rst_n)
  );

  // Actual SoC DUT Instantiation
  soc_veer_el2_temperature_fan_top #(
      .DATA_WIDTH            (32),
      .ADDR_WIDTH            (32),
      .IC_ID_WIDTH           (8),
      .GPIO_NUM_BITS         (32),
      .SEVEN_SEG_REFRESH_DIV (10)
  ) dut (
      .clk                    (clk),
      .rst                    (rst),
      .core_rst_n_i           (core_rst_n_i),
      // ... AXI master S00, UART, SPI, PWM, 7-Seg, Timer ties ...

      // Direct connection of static interface bidirectional net to DUT port
      .gpio_io                (gpio_if_inst.gpio_io),
      .gpio_intr_o            (gpio_intr_o),

      // ... Core trace ports ...
  );
  ```

---

## 6. UVM Config DB `set()` Implementation

- **Originating Scope:** `tb_riscv_soc_uvm` (`initial begin` block, lines 342–347).
- **Exact Path:** `"uvm_test_top.env.agent.drv"` (Explicit path matching dynamic component hierarchy, zero wildcards).
- **Lookup Key:** `"vif"`
- **Source Code:**
  ```systemverilog
  uvm_config_db#(virtual gpio_uvm_if)::set(
      null,
      "uvm_test_top.env.agent.drv",
      "vif",
      gpio_if_inst
  );
  ```
- **Log Confirmation Output:**
  ```text
  UVM_INFO @ 0: reporter [TB_TOP] ==================================================
  UVM_INFO @ 0: reporter [TB_TOP] Phase 6: Publishing static interface 'gpio_if_inst'
  UVM_INFO @ 0: reporter [TB_TOP] Hierarchical Path: uvm_test_top.env.agent.drv
  UVM_INFO @ 0: reporter [TB_TOP] Lookup Key:        vif
  UVM_INFO @ 0: reporter [TB_TOP] ==================================================
  UVM_INFO @ 0: reporter [TB_TOP] uvm_config_db::set() completed successfully.
  ```

---

## 7. UVM Dynamic Component Hierarchy & Config DB `get()`

### 7.1 Dynamic Component Structure
```text
uvm_test_top                 (riscv_soc_test)
  └── env                    (riscv_soc_env)
       └── agent             (gpio_agent)
            ├── seqr         (gpio_sequencer)
            └── drv          (gpio_driver)
```

### 7.2 Driver Implementation
- **File:** `tb/uvm_soc/agents/gpio_agent/gpio_driver.sv`
- **Retrieval Code (`build_phase`):**
  ```systemverilog
  virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info("GPIO_DRV_BUILD", "Entering build_phase: attempting to retrieve virtual interface from uvm_config_db", UVM_LOW)

      if (!uvm_config_db#(virtual gpio_uvm_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NO_VIF", "Virtual interface 'vif' was not configured for gpio_driver in uvm_config_db! Dynamic driver cannot connect to static DUT interface.")
      end else begin
          `uvm_info("GPIO_DRV_BUILD", "Successfully retrieved virtual interface handle 'vif' from uvm_config_db. Static-to-dynamic binding established.", UVM_LOW)
      end
  endfunction
  ```
- **Pin Drive Task (`run_phase`):**
  ```systemverilog
  virtual task drive_item(gpio_seq_item item);
      @(posedge vif.clk);
      vif.gpio_drive_en <= item.drive_en;
      vif.gpio_in       <= item.data;
      `uvm_info("GPIO_DRV_DRIVE", $sformatf("Driving DUT pins via virtual interface: data=0x%08h, drive_en=0x%08h, holding for %0d cycles",
                                           item.data, item.drive_en, item.hold_cycles), UVM_LOW)
      repeat (item.hold_cycles) @(posedge vif.clk);
  endtask
  ```

---

## 8. Proof of Static-to-Dynamic Driver Control (Check 1 to 7 Audit)

| Check | Requirement | Verification Method | Result | Evidence / Log Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| **Check 1** | Exactly one interface instantiated in top TB | Inspected `tb_riscv_soc_uvm.sv` | **CONFIRMED** | Line 43: `gpio_uvm_if gpio_if_inst (...)` |
| **Check 2** | Connected directly to actual DUT port | Inspected DUT instantiation in `tb_riscv_soc_uvm.sv` | **CONFIRMED** | Line 275: `.gpio_io(gpio_if_inst.gpio_io)` |
| **Check 3** | `uvm_config_db::set()` info published | Log trace from `tb_riscv_soc_uvm` | **CONFIRMED** | Time 0 ps: `[TB_TOP] uvm_config_db::set() completed successfully` |
| **Check 4** | `uvm_config_db::get()` success in driver | Log trace from `gpio_driver` | **CONFIRMED** | Time 0 ps: `[GPIO_DRV_BUILD] Successfully retrieved virtual interface handle 'vif'` |
| **Check 5** | Driver activity reported | Log trace during `run_phase` | **CONFIRMED** | 4 distinct vectors driven + 1 release vector (`[GPIO_DRV_DRIVE]`) |
| **Check 6** | Actual DUT input follows driven values | Passive clock-synchronous observer checking `dut.gpio_io === gpio_if_inst.gpio_in` | **CONFIRMED** | **24 consecutive clock cycles PASSED with 0 mismatches** (`[DUT_PIN_OBSERVER]`) |
| **Check 7** | Internal functional propagation verified | Observed `dut.gpio_inst.gpio_i` after 2 synchronizer cycles | **CONFIRMED** | Waveform & assertion confirm register input captures each 32-bit vector exactly 2 cycles later |

---

## 9. Waveform Inspection & Signal Evolution Evidence

The waveform was dumped to:  
`/home/student/Documents/078_H/proj_dir/tb/uvm_soc/waves/riscv_soc_interface_connection.fsdb` (Size: 762,166 bytes).

Signal extraction was performed using Synopsys `fsdbreport` in hexadecimal radix. The cycle-accurate tabular report is presented below:

```text
Time(1ps)  *if_inst/gpio_in *t/gpio_drive_en *uvm/dut/gpio_io *pio_inst/gpio_i  State / Operation
========== ================ ================ ================ ================  ===========================================
0          00000000         00000000         ZZZZZZZZ         00000000          System Reset Asserted (rst=1)
125000     00000000         00000000         ZZZZZZZZ         ZZZZZZZZ          Reset Released, Bus in High-Z
135000     a5a55a5a         ffffffff         a5a55a5a         ZZZZZZZZ          Driver Transaction 1: 0xA5A5_5A5A (dut.gpio_io reflects immediately)
155000     a5a55a5a         ffffffff         a5a55a5a         a5a55a5a          Internal 2-stage synchronizer captures 0xA5A5_5A5A (+20ns)
195000     5a5aa5a5         ffffffff         5a5aa5a5         a5a55a5a          Driver Transaction 2: 0x5A5A_A5A5 (dut.gpio_io reflects immediately)
215000     5a5aa5a5         ffffffff         5a5aa5a5         5a5aa5a5          Internal 2-stage synchronizer captures 0x5A5A_A5A5 (+20ns)
255000     deadbeef         ffffffff         deadbeef         5a5aa5a5          Driver Transaction 3: 0xDEAD_BEEF (dut.gpio_io reflects immediately)
275000     deadbeef         ffffffff         deadbeef         deadbeef          Internal 2-stage synchronizer captures 0xDEAD_BEEF (+20ns)
315000     12345678         ffffffff         12345678         deadbeef          Driver Transaction 4: 0x1234_5678 (dut.gpio_io reflects immediately)
335000     12345678         ffffffff         12345678         12345678          Internal 2-stage synchronizer captures 0x1234_5678 (+20ns)
375000     00000000         00000000         ZZZZZZZZ         12345678          Bus Release Transaction: drive_en=0 (dut.gpio_io returns to High-Z)
395000     00000000         00000000         ZZZZZZZZ         ZZZZZZZZ          Synchronizer drains to High-Z (+20ns)
600000     00000000         00000000         ZZZZZZZZ         ZZZZZZZZ          Test drain phase complete
```

### Waveform Analysis:
1. **Immediate Boundary Reflection:** At timestamps 135 ns, 195 ns, 255 ns, and 315 ns, the moment the dynamic driver assigns `vif.gpio_in` on the clock edge, the statically connected physical boundary port `tb_riscv_soc_uvm.dut.gpio_io` transitions to that exact pattern in 0 simulation delta delay.
2. **Cycle-Accurate Synchronizer Latency:** The internal register input `tb_riscv_soc_uvm.dut.gpio_inst.gpio_i` mirrors each pattern after exactly two 10 ns clock cycles (20,000 ps latency), matching the hardware implementation of `sync_reg[1:0]` in `gpio_bit.sv`.
3. **Clean High-Z Tri-State Release:** At 375 ns, when the driver sets `drive_en = 0`, `dut.gpio_io` gracefully transitions back to `ZZZZZZZZ`, demonstrating bidirectional bus discipline.

---

## 10. Compilation & Simulation Tool Summary

### 10.1 VCS Compilation Command
```bash
cd /home/student/Documents/078_H/proj_dir/tb/uvm_soc && \
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126" && \
export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03" && \
export VERDI_HOME="/home/student/snps_tools_target/verdi/U-2023.03-SP1" && \
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH" && \
vcs -full64 -sverilog -ntb_opts uvm-1.2 +v2k -v2k_generate +vcs+initreg+random -timescale=1ns/1ps \
    -P "$VERDI_HOME/share/PLI/VCS/linux64/novas.tab" "$VERDI_HOME/share/PLI/VCS/linux64/pli.a" \
    -debug_access+all -kdb \
    -f /home/student/Documents/078_H/proj_dir/tb/uvm_soc/filelists/riscv_soc_uvm_interface_test.f \
    -top tb_riscv_soc_uvm \
    -o simv_interface_test \
    -l logs/compile_interface_test.log
```
**Compilation Result:** `CPU time: 12.769 seconds, 0 errors, 0 warnings`. Binary `simv_interface_test` generated successfully.

### 10.2 Simulation Execution Command
```bash
cd /home/student/Documents/078_H/proj_dir/tb/uvm_soc && \
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126" && \
export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03" && \
export VERDI_HOME="/home/student/snps_tools_target/verdi/U-2023.03-SP1" && \
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH" && \
./simv_interface_test -no_save +UVM_VERBOSITY=UVM_MEDIUM \
    +FSDB_FILE=waves/riscv_soc_interface_connection.fsdb \
    -l logs/riscv_soc_interface_connection.log
```
**Simulation Result:**
```text
--- UVM Report Summary ---
** Report counts by severity
UVM_INFO :   62
UVM_WARNING :    0
UVM_ERROR :    0
UVM_FATAL :    0

=======================================================
 [VERIFICATION SUCCESS] All 24 DUT pin observations PASSED!
 Static DUT to dynamic UVM driver connection confirmed!
=======================================================
Simulation time: 615,000 ps (CPU Time: 0.35s)
```

---

## 11. Acceptance Criteria Compliance Matrix (Phase 13)

| Criterion | Requirement | Status | Evidence |
| :---: | :--- | :---: | :--- |
| **1** | Actual existing SoC DUT instantiated | **PASS** | `soc_veer_el2_temperature_fan_top` instantiated in `tb_riscv_soc_uvm.sv` |
| **2** | Exactly one selected interface instance created in top TB | **PASS** | `gpio_uvm_if gpio_if_inst` declared once in `tb_riscv_soc_uvm.sv` |
| **3** | Interface connected to actual DUT port | **PASS** | `.gpio_io(gpio_if_inst.gpio_io)` connected to DUT boundary pin |
| **4** | `uvm_config_db::set()` publishes handle | **PASS** | Path `"uvm_test_top.env.agent.drv"`, key `"vif"` published in `initial` block |
| **5** | UVM driver declares virtual interface | **PASS** | `virtual gpio_uvm_if vif;` in `gpio_driver.sv` |
| **6** | `uvm_config_db::get()` successfully retrieves handle | **PASS** | Verified in `gpio_driver::build_phase`, `UVM_INFO` reported |
| **7** | Driver receives at least one transaction | **PASS** | 5 sequence items processed via `seq_item_port.get_next_item` |
| **8** | Driver drives interface signals | **PASS** | Signals `vif.gpio_in` and `vif.gpio_drive_en` actively driven |
| **9** | Actual DUT input follows driven changes | **PASS** | 24 clock checks confirmed `dut.gpio_io === gpio_if_inst.gpio_in` |
| **10** | Result visible in logs and waveform | **PASS** | Log: `logs/riscv_soc_interface_connection.log`, Wave: `waves/riscv_soc_interface_connection.fsdb` |
| **11** | Compiles and runs cleanly | **PASS** | VCS compile 0 errors, sim finished cleanly at 615 ns |
| **12** | Existing project files remain unchanged | **PASS** | All files in `rtl/`, `firmware/`, `run/`, `tb/` preserved; new files strictly in `tb/uvm_soc/` |

---

## 12. Artifacts & Deliverables Index

All files have been created inside `/home/student/Documents/078_H/proj_dir/tb/uvm_soc/`:

1. **Architecture & Project Inventory Report:**  
   `tb/uvm_soc/PROJECT_INVENTORY.md`
2. **Static Interface Definition:**  
   `tb/uvm_soc/interfaces/gpio_uvm_if.sv`
3. **UVM Sequence Item:**  
   `tb/uvm_soc/agents/gpio_agent/gpio_seq_item.sv`
4. **UVM Sequencer:**  
   `tb/uvm_soc/agents/gpio_agent/gpio_sequencer.sv`
5. **UVM Sequence:**  
   `tb/uvm_soc/agents/gpio_agent/gpio_sequence.sv`
6. **UVM Driver:**  
   `tb/uvm_soc/agents/gpio_agent/gpio_driver.sv`
7. **UVM Agent:**  
   `tb/uvm_soc/agents/gpio_agent/gpio_agent.sv`
8. **UVM Environment:**  
   `tb/uvm_soc/env/riscv_soc_env.sv`
9. **UVM Base Test:**  
   `tb/uvm_soc/tests/riscv_soc_test.sv`
10. **Master UVM Package:**  
    `tb/uvm_soc/riscv_soc_pkg.sv`
11. **Static Top-Level Testbench:**  
    `tb/uvm_soc/tb_riscv_soc_uvm.sv`
12. **VCS Compilation Filelist:**  
    `tb/uvm_soc/filelists/riscv_soc_uvm_interface_test.f`
13. **Compilation Log:**  
    `tb/uvm_soc/logs/compile_interface_test.log`
14. **Simulation Log:**  
    `tb/uvm_soc/logs/riscv_soc_interface_connection.log`
15. **FSDB Waveform:**  
    `tb/uvm_soc/waves/riscv_soc_interface_connection.fsdb`
16. **Detailed Verification Report:**  
    `tb/uvm_soc/STATIC_DYNAMIC_INTERFACE_CONNECTION_REPORT.md`
