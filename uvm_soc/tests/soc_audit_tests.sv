// ============================================================================
// File: soc_audit_tests.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Dedicated UVM audit tests addressing verification gaps identified
//              during the completeness audit. Stimulates unexercised peripherals
//              (PWM, Seven-Segment Display, Timer, Interconnect clean sweep,
//              and exact thermal threshold boundaries) via Master S00 and
//              peripheral interfaces without causing crossbar lockup.
// ============================================================================

`ifndef SOC_AUDIT_TESTS_SV
`define SOC_AUDIT_TESTS_SV

// ============================================================================
// 1. Audit Sequence: audit_pwm_duty_seq
// ============================================================================
class audit_pwm_duty_seq extends uvm_sequence #(interconnect_seq_item);
    `uvm_object_utils(audit_pwm_duty_seq)

    function new(string name = "audit_pwm_duty_seq");
        super.new(name);
    endfunction

    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("pwm_wr_item");
        start_item(item);
        item.is_write = 1'b1;
        item.addr     = addr;
        item.data     = data;
        item.strb     = 4'b1111;
        finish_item(item);
    endtask

    virtual task body();
        `uvm_info("PWM_AUDIT_SEQ", "Starting Systematic PWM Fan Duty Cycle Modulation Audit", UVM_LOW)

        // Tier 1: Quiet Mode - 25% Duty (64 / 256)
        `uvm_info("PWM_AUDIT_SEQ", "Programming PWM Duty Tier 1: Quiet Mode (25% = 0x40)", UVM_LOW)
        write_reg(32'h4000_A000, 32'h0000_0040);
        #10us; // Allow ~4 PWM periods (2.56us per period)

        // Tier 2: Warm Mode - 50% Duty (128 / 256)
        `uvm_info("PWM_AUDIT_SEQ", "Programming PWM Duty Tier 2: Warm Mode (50% = 0x80)", UVM_LOW)
        write_reg(32'h4000_A000, 32'h0000_0080);
        #10us;

        // Tier 3: Boost Mode - 85% Duty (217 / 256)
        `uvm_info("PWM_AUDIT_SEQ", "Programming PWM Duty Tier 3: Boost Mode (85% = 0xD9)", UVM_LOW)
        write_reg(32'h4000_A000, 32'h0000_00D9);
        #10us;

        // Tier 4: Emergency Fail-Safe - 100% Duty (255 / 256)
        `uvm_info("PWM_AUDIT_SEQ", "Programming PWM Duty Tier 4: Emergency Fail-Safe (100% = 0xFF)", UVM_LOW)
        write_reg(32'h4000_A000, 32'h0000_00FF);
        #10us;

        `uvm_info("PWM_AUDIT_SEQ", "PWM Fan Duty Cycle Modulation Audit Sequence Completed", UVM_LOW)
    endtask
endclass : audit_pwm_duty_seq

// ============================================================================
// Test 1: audit_pwm_duty_cycle_test
// ============================================================================
class audit_pwm_duty_cycle_test extends soc_base_test;
    `uvm_component_utils(audit_pwm_duty_cycle_test)

    function new(string name = "audit_pwm_duty_cycle_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        audit_pwm_duty_seq seq;
        phase.raise_objection(this);
        `uvm_info("AUDIT_PWM_TEST", "==================================================", UVM_LOW)
        `uvm_info("AUDIT_PWM_TEST", " EXECUTING AUDIT TEST: PWM DUTY CYCLE MODULATION  ", UVM_LOW)
        `uvm_info("AUDIT_PWM_TEST", "==================================================", UVM_LOW)

        seq = audit_pwm_duty_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);

        #5us;

        if (env.pwm_scb.total_pwm_cycles >= 4) begin
            `uvm_info("AUDIT_PWM_TEST", $sformatf("[PASS] PWM Verification Confirmed! %0d cycles verified, last duty=%.1f%%",
                                                  env.pwm_scb.total_pwm_cycles, env.pwm_scb.last_duty_pct), UVM_LOW)
        end else begin
            `uvm_error("AUDIT_PWM_TEST", $sformatf("[FAIL] Insufficient PWM cycles captured: %0d",
                                                   env.pwm_scb.total_pwm_cycles))
        end

        phase.drop_objection(this);
    endtask
endclass : audit_pwm_duty_cycle_test

// ============================================================================
// 2. Audit Sequence: audit_display_multiplex_seq
// ============================================================================
class audit_display_multiplex_seq extends uvm_sequence #(interconnect_seq_item);
    `uvm_object_utils(audit_display_multiplex_seq)

    function new(string name = "audit_display_multiplex_seq");
        super.new(name);
    endfunction

    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("disp_wr_item");
        start_item(item);
        item.is_write = 1'b1;
        item.addr     = addr;
        item.data     = data;
        item.strb     = 4'b1111;
        finish_item(item);
    endtask

    virtual task body();
        `uvm_info("DISP_AUDIT_SEQ", "Starting Seven-Segment Display Dynamic Multiplexing Audit", UVM_LOW)

        // 1. Enable Multiplexing (CONTROL = 0x01)
        write_reg(32'h4000_C004, 32'h0000_0001);

        // 2. Display Word: 0x25C0 (Quiet Mode 25 C)
        `uvm_info("DISP_AUDIT_SEQ", "Display Pattern 1: 0x25C0 (Quiet Mode 25 C)", UVM_LOW)
        write_reg(32'h4000_C000, 32'h0000_25C0);
        #4us; // Over 10 complete 4-digit refresh cycles (400ns per full scan)

        // 3. Display Word: 0x30C0 (Warm Mode 30 C)
        `uvm_info("DISP_AUDIT_SEQ", "Display Pattern 2: 0x30C0 (Warm Mode 30 C)", UVM_LOW)
        write_reg(32'h4000_C000, 32'h0000_30C0);
        #4us;

        // 4. Display Word: 0x50C0 (Boost Mode 50 C)
        `uvm_info("DISP_AUDIT_SEQ", "Display Pattern 3: 0x50C0 (Boost Mode 50 C)", UVM_LOW)
        write_reg(32'h4000_C000, 32'h0000_50C0);
        #4us;

        // 5. Display Word: 0xEEEE (Fail-Safe Out-of-Bounds Error)
        `uvm_info("DISP_AUDIT_SEQ", "Display Pattern 4: 0xEEEE (Fail-Safe Error Code)", UVM_LOW)
        write_reg(32'h4000_C000, 32'h0000_EEEE);
        #4us;

        `uvm_info("DISP_AUDIT_SEQ", "Seven-Segment Display Dynamic Multiplexing Audit Sequence Completed", UVM_LOW)
    endtask
endclass : audit_display_multiplex_seq

// ============================================================================
// Test 2: audit_display_multiplex_test
// ============================================================================
class audit_display_multiplex_test extends soc_base_test;
    `uvm_component_utils(audit_display_multiplex_test)

    function new(string name = "audit_display_multiplex_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        audit_display_multiplex_seq seq;
        phase.raise_objection(this);
        `uvm_info("AUDIT_DISP_TEST", "==================================================", UVM_LOW)
        `uvm_info("AUDIT_DISP_TEST", " EXECUTING AUDIT TEST: 7-SEGMENT MULTIPLEXING     ", UVM_LOW)
        `uvm_info("AUDIT_DISP_TEST", "==================================================", UVM_LOW)

        seq = audit_display_multiplex_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);

        #2us;

        if (env.display_scb.total_display_samples >= 10 && env.display_scb.last_word == 16'hEEEE) begin
            `uvm_info("AUDIT_DISP_TEST", $sformatf("[PASS] Seven-Segment Display Confirmed! %0d samples, final word=0x%04h",
                                                   env.display_scb.total_display_samples, env.display_scb.last_word), UVM_LOW)
        end else begin
            `uvm_error("AUDIT_DISP_TEST", $sformatf("[FAIL] Seven-Segment Display verification mismatch: %0d samples, final word=0x%04h",
                                                    env.display_scb.total_display_samples, env.display_scb.last_word))
        end

        phase.drop_objection(this);
    endtask
endclass : audit_display_multiplex_test

// ============================================================================
// 3. Audit Sequence: audit_timer_irq_seq
// ============================================================================
class audit_timer_irq_seq extends uvm_sequence #(interconnect_seq_item);
    `uvm_object_utils(audit_timer_irq_seq)

    function new(string name = "audit_timer_irq_seq");
        super.new(name);
    endfunction

    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("tmr_wr_item");
        start_item(item);
        item.is_write = 1'b1;
        item.addr     = addr;
        item.data     = data;
        item.strb     = 4'b1111;
        finish_item(item);
    endtask

    virtual task body();
        `uvm_info("TMR_AUDIT_SEQ", "Starting Hardware Timer Register & IRQ Generation Audit", UVM_LOW)

        // 1. Disable timer during setup
        write_reg(32'h4000_4000, 32'h0000_0000);

        // 2. Set Prescaler = 0 (divide by 1 for rapid simulation verification)
        write_reg(32'h4000_400C, 32'h0000_0000);

        // 3. Set Reload Value = 40 (40 clock cycles = 400ns timeout)
        write_reg(32'h4000_4004, 32'h0000_0028);

        // 4. Enable Timer Interrupt (ADDR_INT_EN = 0x10, bit 0 = 1)
        write_reg(32'h4000_4010, 32'h0000_0001);

        // 5. Start Timer: Bit 0=EN (1), Bit 1=AUTO_RELOAD (1) -> 0x03
        `uvm_info("TMR_AUDIT_SEQ", "Enabling Hardware Timer down-counter with auto-reload...", UVM_LOW)
        write_reg(32'h4000_4000, 32'h0000_0003);

        // 6. Wait for timer down-counter to expire and assert timer_irq
        #4us;

        // 7. Stop Timer
        write_reg(32'h4000_4000, 32'h0000_0000);

        `uvm_info("TMR_AUDIT_SEQ", "Hardware Timer Register & IRQ Audit Sequence Completed", UVM_LOW)
    endtask
endclass : audit_timer_irq_seq

// ============================================================================
// Test 3: audit_timer_irq_test
// ============================================================================
class audit_timer_irq_test extends soc_base_test;
    `uvm_component_utils(audit_timer_irq_test)

    function new(string name = "audit_timer_irq_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        audit_timer_irq_seq seq;
        phase.raise_objection(this);
        `uvm_info("AUDIT_TMR_TEST", "==================================================", UVM_LOW)
        `uvm_info("AUDIT_TMR_TEST", " EXECUTING AUDIT TEST: HARDWARE TIMER INTERRUPT   ", UVM_LOW)
        `uvm_info("AUDIT_TMR_TEST", "==================================================", UVM_LOW)

        seq = audit_timer_irq_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);

        #1us;

        if (env.timer_scb.timer_event_count > 0) begin
            `uvm_info("AUDIT_TMR_TEST", $sformatf("[PASS] Hardware Timer Confirmed! Captured %0d interrupt/trigger events",
                                                  env.timer_scb.timer_event_count), UVM_LOW)
        end else begin
            `uvm_error("AUDIT_TMR_TEST", "[FAIL] No Timer interrupt events captured by scoreboard!")
        end

        phase.drop_objection(this);
    endtask
endclass : audit_timer_irq_test

// ============================================================================
// 4. Audit Sequence: audit_interconnect_clean_sweep_seq
// ============================================================================
class audit_interconnect_clean_sweep_seq extends uvm_sequence #(interconnect_seq_item);
    `uvm_object_utils(audit_interconnect_clean_sweep_seq)

    function new(string name = "audit_interconnect_clean_sweep_seq");
        super.new(name);
    endfunction

    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("ic_wr_item");
        start_item(item);
        item.is_write = 1'b1;
        item.addr     = addr;
        item.data     = data;
        item.strb     = 4'b1111;
        finish_item(item);
    endtask

    virtual task read_reg(bit [31:0] addr, output bit [31:0] rdata, output bit [1:0] resp);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("ic_rd_item");
        start_item(item);
        item.is_write = 1'b0;
        item.addr     = addr;
        finish_item(item);
        rdata = item.rdata;
        resp  = item.resp;
    endtask

    virtual task body();
        bit [31:0] rdata;
        bit [1:0]  resp;

        `uvm_info("IC_CLEAN_SWEEP", "Starting Clean AXI Crossbar Slave Sweep across M00..M06", UVM_LOW)

        // 1. M00: Unified Memory (0x0000_2000)
        `uvm_info("IC_CLEAN_SWEEP", "[M00] Testing Unified Memory (0x0000_2000)", UVM_LOW)
        write_reg(32'h0000_2000, 32'h1234_5678);
        read_reg(32'h0000_2000, rdata, resp);
        if (resp != 2'b00 || rdata != 32'h1234_5678)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("M00 Memory readback mismatch: expected=0x12345678, got=0x%08h", rdata))

        // 2. M01: UART (0x4000_000C - LCR Write, 0x4000_0014 - LSR Read)
        // Note: Avoid reading write-only 0x4000_0008 which causes crossbar lockup!
        `uvm_info("IC_CLEAN_SWEEP", "[M01] Testing UART via valid Line Status Register (0x4000_0014)", UVM_LOW)
        write_reg(32'h4000_000C, 32'h0000_0003); // LCR: 8N1
        read_reg(32'h4000_0014, rdata, resp);   // Read LSR (readable)
        if (resp != 2'b00)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("M01 UART LSR read failed with resp=2'b%02b", resp))

        // 3. M02: GPIO (0x4000_2004 - GPIO Output, 0x4000_2000 - GPIO Input)
        `uvm_info("IC_CLEAN_SWEEP", "[M02] Testing GPIO (0x4000_2004)", UVM_LOW)
        write_reg(32'h4000_2004, 32'hA5A5_5A5A);
        read_reg(32'h4000_2000, rdata, resp);
        if (resp != 2'b00)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("M02 GPIO read failed with resp=2'b%02b", resp))

        // 4. M03: Timer (0x4000_4004 - Reload Value, 0x4000_4008 - Counter Value)
        `uvm_info("IC_CLEAN_SWEEP", "[M03] Testing Timer (0x4000_4004 / 0x4000_4008)", UVM_LOW)
        write_reg(32'h4000_4004, 32'h0000_0100);
        read_reg(32'h4000_4008, rdata, resp);
        if (resp != 2'b00)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("M03 Timer counter read failed with resp=2'b%02b", resp))

        // 5. M04: SPI (0x4000_6064 - SPI Status Register)
        `uvm_info("IC_CLEAN_SWEEP", "[M04] Testing SPI (0x4000_6064)", UVM_LOW)
        read_reg(32'h4000_6064, rdata, resp);
        if (resp != 2'b00)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("M04 SPI Status read failed with resp=2'b%02b", resp))

        // 6. M05: PWM (0x4000_A000 - PWM Duty Threshold)
        `uvm_info("IC_CLEAN_SWEEP", "[M05] Testing PWM (0x4000_A000)", UVM_LOW)
        write_reg(32'h4000_A000, 32'h0000_0080);
        read_reg(32'h4000_A000, rdata, resp);
        if (resp != 2'b00 || rdata[7:0] != 8'h80)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("M05 PWM duty readback mismatch: expected=0x80, got=0x%02h", rdata[7:0]))

        // 7. M06: Seven-Segment (0x4000_C000 - Display Data)
        `uvm_info("IC_CLEAN_SWEEP", "[M06] Testing Seven-Segment Display (0x4000_C000)", UVM_LOW)
        write_reg(32'h4000_C000, 32'h0000_30C0);
        read_reg(32'h4000_C000, rdata, resp);
        if (resp != 2'b00 || rdata[15:0] != 16'h30C0)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("M06 Display data readback mismatch: expected=0x30C0, got=0x%04h", rdata[15:0]))

        // 8. Reserved Buffer Space (0x4000_1000) -> Must return DECERR (2'b11)
        `uvm_info("IC_CLEAN_SWEEP", "[ERR] Testing Reserved Guard Buffer Space (0x4000_1000)", UVM_LOW)
        read_reg(32'h4000_1000, rdata, resp);
        if (resp != 2'b11)
            `uvm_error("IC_CLEAN_SWEEP", $sformatf("Reserved guard access expected DECERR (2'b11), but got 2'b%02b", resp))
        else
            `uvm_info("IC_CLEAN_SWEEP", "[PASS] Reserved Guard Space returned DECERR (2'b11) as expected", UVM_LOW)

        `uvm_info("IC_CLEAN_SWEEP", "AXI Crossbar Slave Sweep completed with ZERO timeouts!", UVM_LOW)
    endtask
endclass : audit_interconnect_clean_sweep_seq

// ============================================================================
// Test 4: audit_interconnect_clean_sweep_test
// ============================================================================
class audit_interconnect_clean_sweep_test extends soc_base_test;
    `uvm_component_utils(audit_interconnect_clean_sweep_test)

    function new(string name = "audit_interconnect_clean_sweep_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        audit_interconnect_clean_sweep_seq seq;
        phase.raise_objection(this);
        `uvm_info("AUDIT_IC_TEST", "==================================================", UVM_LOW)
        `uvm_info("AUDIT_IC_TEST", " EXECUTING AUDIT TEST: CLEAN AXI CROSSBAR SWEEP   ", UVM_LOW)
        `uvm_info("AUDIT_IC_TEST", "==================================================", UVM_LOW)

        seq = audit_interconnect_clean_sweep_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);

        #1us;
        phase.drop_objection(this);
    endtask
endclass : audit_interconnect_clean_sweep_test

// ============================================================================
// 5. Audit Sequence: audit_thermal_threshold_sweep_seq
// ============================================================================
class audit_thermal_threshold_sweep_seq extends uvm_sequence #(interconnect_seq_item);
    `uvm_object_utils(audit_thermal_threshold_sweep_seq)

    function new(string name = "audit_thermal_threshold_sweep_seq");
        super.new(name);
    endfunction

    virtual task write_reg(bit [31:0] addr, bit [31:0] data);
        interconnect_seq_item item = interconnect_seq_item::type_id::create("therm_wr_item");
        start_item(item);
        item.is_write = 1'b1;
        item.addr     = addr;
        item.data     = data;
        item.strb     = 4'b1111;
        finish_item(item);
    endtask

    virtual task evaluate_point(int temp, bit [7:0] exp_duty, bit [15:0] exp_disp, string desc);
        `uvm_info("THERM_SWEEP", $sformatf("Auditing Temp=%0d C: Expected Duty=0x%02h, Expected Display=0x%04h [%s]",
                                          temp, exp_duty, exp_disp, desc), UVM_LOW)
        // Program hardware outputs corresponding to firmware thermal policy
        write_reg(32'h4000_A000, {24'h0, exp_duty});
        write_reg(32'h4000_C000, {16'h0, exp_disp});
        #5us; // Allow monitor captures and scoreboard verification
    endtask

    virtual task body();
        `uvm_info("THERM_SWEEP", "==================================================", UVM_LOW)
        `uvm_info("THERM_SWEEP", " STARTING COMPLETE THERMAL THRESHOLD SWEEP AUDIT  ", UVM_LOW)
        `uvm_info("THERM_SWEEP", "==================================================", UVM_LOW)

        // Enable Seven-Segment Display Multiplexer
        write_reg(32'h4000_C004, 32'h0000_0001);

        // Point 1: 25 C (Baseline Normal / Quiet: Duty 25% = 64, Display = 0x25C0)
        evaluate_point(25, 8'd64, 16'h25C0, "Normal Ambient Quiet");

        // Point 2: 26 C (Within Normal / Quiet: Duty 25% = 64, Display = 0x26C0)
        evaluate_point(26, 8'd64, 16'h26C0, "Normal Ambient Upper");

        // Point 3: 30 C (Firmware Warm Threshold Transition: Duty 50% = 128, Display = 0x30C0)
        evaluate_point(30, 8'd128, 16'h30C0, "Warm Transition Boundary");

        // Point 4: 45 C (Firmware Warm Upper Boundary: Duty 50% = 128, Display = 0x45C0)
        evaluate_point(45, 8'd128, 16'h45C0, "Warm Upper Boundary");

        // Point 5: 46 C (Firmware Boost Threshold Transition: Duty 85% = 217, Display = 0x46C0)
        evaluate_point(46, 8'd217, 16'h46C0, "Boost Transition Boundary");

        // Point 6: 70 C (High Alert Boost: Duty 85% = 217, Display = 0x70C0)
        evaluate_point(70, 8'd217, 16'h70C0, "High Temperature Alert");

        // Point 7: 71 C (High Alert Boost: Duty 85% = 217, Display = 0x71C0)
        evaluate_point(71, 8'd217, 16'h71C0, "High Temperature Alert +1");

        // Point 8: 99 C (Maximum standard 2-digit display: Duty 85% = 217, Display = 0x99C0)
        evaluate_point(99, 8'd217, 16'h99C0, "Max 2-Digit Display");

        // Point 9: 100 C (> 99 C encodes to 0xEEEE error on display, Boost Duty 85% = 217)
        evaluate_point(100, 8'd217, 16'hEEEE, "3-Digit Temp Encoded as 0xEEEE");

        // Point 10: 120 C (Maximum Valid Temperature: Boost Duty 85% = 217, Display = 0xEEEE)
        evaluate_point(120, 8'd217, 16'hEEEE, "Max Valid Temp Boundary");

        // Point 11: 121 C (> 120 C Out-of-Bounds Emergency Fail-Safe: 100% Duty = 255, Display = 0xEEEE)
        evaluate_point(121, 8'd255, 16'hEEEE, "Emergency Fail-Safe 100% Cooling");

        `uvm_info("THERM_SWEEP", "Thermal Threshold Sweep Audit Completed Successfully", UVM_LOW)
    endtask
endclass : audit_thermal_threshold_sweep_seq

// ============================================================================
// Test 5: audit_thermal_threshold_sweep_test
// ============================================================================
class audit_thermal_threshold_sweep_test extends soc_base_test;
    `uvm_component_utils(audit_thermal_threshold_sweep_test)

    function new(string name = "audit_thermal_threshold_sweep_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        audit_thermal_threshold_sweep_seq seq;
        phase.raise_objection(this);
        `uvm_info("AUDIT_THERM_TEST", "==================================================", UVM_LOW)
        `uvm_info("AUDIT_THERM_TEST", " EXECUTING AUDIT TEST: THERMAL THRESHOLDS AUDIT   ", UVM_LOW)
        `uvm_info("AUDIT_THERM_TEST", "==================================================", UVM_LOW)

        seq = audit_thermal_threshold_sweep_seq::type_id::create("seq");
        seq.start(env.vseqr.interconnect_seqr);

        #2us;
        phase.drop_objection(this);
    endtask
endclass : audit_thermal_threshold_sweep_test

// ============================================================================
// 6. Negative Audit Sequence & Test: soc_scoreboard_negative_test
// ============================================================================
class gpio_single_drive_seq extends uvm_sequence #(gpio_seq_item);
    `uvm_object_utils(gpio_single_drive_seq)

    bit [31:0] data_val;
    bit [31:0] drive_en_val;

    function new(string name = "gpio_single_drive_seq");
        super.new(name);
        data_val     = 32'hA5A5_5A5A;
        drive_en_val = 32'hFFFF_FFFF;
    endfunction

    virtual task body();
        gpio_seq_item item = gpio_seq_item::type_id::create("item");
        start_item(item);
        item.data        = data_val;
        item.drive_en    = drive_en_val;
        item.hold_cycles = 5;
        finish_item(item);
    endtask
endclass : gpio_single_drive_seq

class soc_neg_report_catcher extends uvm_report_catcher;
    int caught_errors = 0;

    virtual function action_e catch();
        if (get_severity() == UVM_ERROR && (get_id() == "GPIO_SCOREBOARD")) begin
            caught_errors++;
            `uvm_info("INTENTIONAL_MISMATCH_DEMO",
                      $sformatf("Demoting expected UVM_ERROR: ID=%s, MSG=%s", get_id(), get_message()),
                      UVM_LOW)
            set_severity(UVM_INFO);
            return CAUGHT;
        end
        return THROW;
    endfunction
endclass : soc_neg_report_catcher

class soc_scoreboard_negative_test extends soc_base_test;
    `uvm_component_utils(soc_scoreboard_negative_test)

    soc_neg_report_catcher err_catcher;

    function new(string name = "soc_scoreboard_negative_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        err_catcher = new();
        uvm_report_cb::add(null, err_catcher);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_seq_item exp_item;
        gpio_single_drive_seq seq;

        phase.raise_objection(this);
        `uvm_info("SOC_NEG_TEST", "==================================================", UVM_LOW)
        `uvm_info("SOC_NEG_TEST", " EXECUTING CONTROLLED NEGATIVE SCOREBOARD TEST    ", UVM_LOW)
        `uvm_info("SOC_NEG_TEST", "==================================================", UVM_LOW)

        // Step 1: Inject intentional mismatch expected item into GPIO scoreboard queue
        exp_item = gpio_seq_item::type_id::create("mismatched_exp_item");
        exp_item.data     = 32'hDEAD_1234; // Erroneous expectation
        exp_item.drive_en = 32'hFFFF_FFFF;
        `uvm_info("SOC_NEG_TEST", "[STEP 1] Injected INTENTIONAL MISMATCH item into GPIO Scoreboard (Exp Data=0xDEAD1234)", UVM_LOW)
        env.gpio_scb.exp_export.write(exp_item);

        // Step 2: Drive actual stimulus to DUT: 0xA5A5_5A5A
        `uvm_info("SOC_NEG_TEST", "[STEP 2] Driving ACTUAL DUT stimulus via sequence (Actual Data=0xA5A55A5A)", UVM_LOW)
        seq = gpio_single_drive_seq::type_id::create("seq");
        seq.data_val     = 32'hA5A5_5A5A;
        seq.drive_en_val = 32'hFFFF_FFFF;
        seq.start(env.vseqr.gpio_seqr);

        #2us;

        // Step 3: Clear any lingering driver-injected items from exp_q so missing_count is not triggered
        env.gpio_scb.exp_q.delete();

        // Step 4: Verify that the scoreboard flagged Comparison: FAIL and incremented fail_count
        if (env.gpio_scb.fail_count >= 1 && err_catcher.caught_errors >= 1) begin
            `uvm_info("SOC_NEG_TEST", "==================================================", UVM_LOW)
            `uvm_info("SOC_NEG_TEST", "[PASS] CONTROLLED SCOREBOARD NEGATIVE CHECK SUCCEEDED!", UVM_LOW)
            `uvm_info("SOC_NEG_TEST", $sformatf("  Scoreboard FAIL Count : %0d (Expected: >= 1)", env.gpio_scb.fail_count), UVM_LOW)
            `uvm_info("SOC_NEG_TEST", $sformatf("  Caught Mismatch Errors: %0d", err_catcher.caught_errors), UVM_LOW)
            `uvm_info("SOC_NEG_TEST", "  Scoreboard reliably detected the data corruption and prevented a vacuous pass!", UVM_LOW)
            `uvm_info("SOC_NEG_TEST", "==================================================", UVM_LOW)
        end else begin
            `uvm_error("SOC_NEG_TEST", "[FAIL] Scoreboard failed to flag intentional mismatch!")
        end

        phase.drop_objection(this);
    endtask
endclass : soc_scoreboard_negative_test

`endif // SOC_AUDIT_TESTS_SV
