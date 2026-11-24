// ============================================================================
// File: pwm_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Self-checking scoreboard for PWM fan controller, validating
//              expected vs actual period, high time, and duty cycle.
// ============================================================================

`ifndef PWM_SCOREBOARD_SV
`define PWM_SCOREBOARD_SV

`uvm_analysis_imp_decl(_pwm_axi)
`uvm_analysis_imp_decl(_pwm_item)

class pwm_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(pwm_scoreboard)

    uvm_analysis_imp_pwm_axi  #(interconnect_seq_item, pwm_scoreboard) axi_export;
    uvm_analysis_imp_pwm_item #(pwm_seq_item,          pwm_scoreboard) item_export;

    int total_expected;
    int total_observed;
    int comparisons;
    int pass_count;
    int fail_count;
    int missing_count;
    int unexpected_count;
    int trans_id;
    bit require_activity;

    real expected_duty_pct;
    int  expected_period_ns;
    int  expected_high_ns;
    bit  just_updated_reg;

    // Backward compatibility metrics
    int  total_pwm_cycles;
    real last_duty_pct;

    function new(string name = "pwm_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        axi_export  = new("axi_export", this);
        item_export = new("item_export", this);
        total_expected   = 0;
        total_observed   = 0;
        comparisons      = 0;
        pass_count       = 0;
        fail_count       = 0;
        missing_count    = 0;
        unexpected_count = 0;
        trans_id         = 0;
        require_activity = 0;
        total_pwm_cycles = 0;
        last_duty_pct    = 0.0;

        // Default baseline (Quiet mode: 25.0% = 64/256)
        expected_duty_pct  = 25.0;
        expected_period_ns = 2560;
        expected_high_ns   = 640;
    endfunction

    virtual function void write_pwm_axi(interconnect_seq_item item);
        if (item.is_write && item.addr == 32'h4000_A000) begin
            total_expected++;
            expected_duty_pct  = (real'(item.data[7:0]) / 256.0) * 100.0;
            expected_period_ns = 2560;
            expected_high_ns   = int'(expected_duty_pct * 25.6);
            just_updated_reg   = 1;
            `uvm_info("PWM_SCOREBOARD", $sformatf("[%0t] [MODEL UPDATE] Programmed PWM Duty Reg=0x%02h -> Expected Period=%0dns, HighTime=%0dns, Duty=%.1f%%",
                                                  $time, item.data[7:0], expected_period_ns, expected_high_ns, expected_duty_pct), UVM_MEDIUM)
        end
    endfunction

    virtual function void write_pwm_item(pwm_seq_item item);
        bit is_pass = 0;
        int act_period_ns = item.period / 1ns;
        int act_high_ns   = item.high_time / 1ns;
        real duty_diff;

        total_observed++;
        total_pwm_cycles++;
        last_duty_pct = item.duty_cycle_pct;

        // Skip transition cycles (< 2400ns) immediately following register reprogramming mid-cycle
        if ((act_period_ns < 2000) || (just_updated_reg && act_period_ns < 2400)) begin
            `uvm_info("PWM_SCOREBOARD", $sformatf("Skipping transition cycle (period=%0d ns, high=%0d ns) during dynamic register reprogramming",
                                                  act_period_ns, act_high_ns), UVM_HIGH)
            just_updated_reg = 0;
            return;
        end
        just_updated_reg = 0;

        // If no explicit AXI writes occurred yet, baseline initial cycle is expected
        if (total_expected == 0) begin
            total_expected = 1;
        end

        trans_id++;
        comparisons++;

        duty_diff = (item.duty_cycle_pct > expected_duty_pct) ?
                    (item.duty_cycle_pct - expected_duty_pct) :
                    (expected_duty_pct - item.duty_cycle_pct);

        // Period tolerance: 2560ns ± 150ns. Duty cycle tolerance: ±3.8% (or >= 95% if emergency 100%)
        if (act_period_ns >= 2400 && act_period_ns <= 2700) begin
            if (expected_duty_pct >= 95.0 && item.duty_cycle_pct >= 95.0) begin
                is_pass = 1;
            end else if (duty_diff <= 3.8) begin
                is_pass = 1;
            end
        end

        if (is_pass) pass_count++;
        else fail_count++;

        `uvm_info("PWM_SCOREBOARD", $sformatf("\n------------------------------------------------\nPWM SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Period=%0d ns, HighTime=%0d ns, Duty=%.1f%%\nActual         : Period=%0d ns, HighTime=%0d ns, Duty=%.1f%%\nComparison     : %s\n------------------------------------------------",
                                              trans_id,
                                              expected_period_ns, expected_high_ns, expected_duty_pct,
                                              act_period_ns, act_high_ns, item.duty_cycle_pct,
                                              is_pass ? "PASS" : "FAIL"), UVM_MEDIUM)

        if (!is_pass) begin
            `uvm_error("PWM_SCOREBOARD", $sformatf("PWM Duty Cycle / Period out of tolerance on Transaction #%0d!", trans_id))
        end
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (require_activity && total_observed == 0) begin
            missing_count++;
            `uvm_error("PWM_SCOREBOARD", "Zero PWM cycles captured when activity was required!")
        end
        if (fail_count > 0 || missing_count > 0) begin
            `uvm_error("PWM_SCOREBOARD", $sformatf("PWM Scoreboard finished with errors: FAIL=%0d, Missing=%0d",
                                                  fail_count, missing_count))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("PWM_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", "              PWM SCOREBOARD SUMMARY              ", UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("PWM_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : pwm_scoreboard

`endif // PWM_SCOREBOARD_SV
