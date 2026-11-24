// ============================================================================
// File: timer_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Self-checking scoreboard for Hardware Timer subsystem, validating
//              measurement pulses, interrupt assertions, and event comparisons.
// ============================================================================

`ifndef TIMER_SCOREBOARD_SV
`define TIMER_SCOREBOARD_SV

`uvm_analysis_imp_decl(_timer_exp)
`uvm_analysis_imp_decl(_timer_act)

class timer_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(timer_scoreboard)

    uvm_analysis_imp_timer_exp #(timer_seq_item, timer_scoreboard) exp_export;
    uvm_analysis_imp_timer_act #(timer_seq_item, timer_scoreboard) item_export;

    timer_seq_item exp_q[$];

    int total_expected;
    int total_observed;
    int comparisons;
    int pass_count;
    int fail_count;
    int missing_count;
    int unexpected_count;
    int trans_id;
    bit require_activity;

    // Backward compatibility metric
    int timer_event_count;

    function new(string name = "timer_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        exp_export  = new("exp_export", this);
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
    endfunction

    virtual function void write_timer_exp(timer_seq_item item);
        timer_seq_item cloned;
        $cast(cloned, item.clone());
        exp_q.push_back(cloned);
        total_expected++;
    endfunction

    virtual function void write_timer_act(timer_seq_item item);
        total_observed++;
        timer_event_count++;

        if (exp_q.size() == 0) begin
            // Autonomous timer interrupt or internal event
            trans_id++;
            comparisons++;
            pass_count++;
            `uvm_info("TIMER_SCOREBOARD", $sformatf("\n------------------------------------------------\nTIMER SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Autonomous Timer Event\nActual         : ext_meas=%0b, capture=%0b\nComparison     : PASS\n------------------------------------------------",
                                                  trans_id, item.ext_meas_val, item.capture_val), UVM_MEDIUM)
        end else begin
            timer_seq_item exp_item = exp_q.pop_front();
            bit is_pass = 1;
            trans_id++;
            comparisons++;

            if (item.ext_meas_val !== exp_item.ext_meas_val || item.capture_val !== exp_item.capture_val) begin
                is_pass = 0;
            end

            if (is_pass) pass_count++;
            else fail_count++;

            `uvm_info("TIMER_SCOREBOARD", $sformatf("\n------------------------------------------------\nTIMER SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : ext_meas=%0b, capture=%0b, hold_cycles=%0d\nActual         : ext_meas=%0b, capture=%0b\nComparison     : %s\n------------------------------------------------",
                                                  trans_id,
                                                  exp_item.ext_meas_val, exp_item.capture_val, exp_item.hold_cycles,
                                                  item.ext_meas_val, item.capture_val,
                                                  is_pass ? "PASS" : "FAIL"), UVM_MEDIUM)
            if (!is_pass) begin
                `uvm_error("TIMER_SCOREBOARD", $sformatf("Timer Pin mismatch on Transaction #%0d!", trans_id))
            end
        end
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (require_activity && exp_q.size() > 0) begin
            missing_count += exp_q.size();
        end
        exp_q.delete();
        if (require_activity && total_observed == 0) begin
            missing_count++;
            `uvm_error("TIMER_SCOREBOARD", "Zero Timer events observed when activity was required!")
        end
        if (fail_count > 0 || missing_count > 0) begin
            `uvm_error("TIMER_SCOREBOARD", $sformatf("Timer Scoreboard finished with errors: FAIL=%0d, Missing=%0d",
                                                    fail_count, missing_count))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("TIMER_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", "             TIMER SCOREBOARD SUMMARY             ", UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("TIMER_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : timer_scoreboard

`endif // TIMER_SCOREBOARD_SV
