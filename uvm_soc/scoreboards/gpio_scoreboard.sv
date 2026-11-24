// ============================================================================
// File: gpio_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Self-checking scoreboard for GPIO subsystem, verifying driven vs
//              observed pins, High-Z states, comparisons, and transaction stats.
// ============================================================================

`ifndef GPIO_SCOREBOARD_SV
`define GPIO_SCOREBOARD_SV

`uvm_analysis_imp_decl(_gpio_exp)
`uvm_analysis_imp_decl(_gpio_act)

class gpio_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(gpio_scoreboard)

    uvm_analysis_imp_gpio_exp #(gpio_seq_item, gpio_scoreboard) exp_export;
    uvm_analysis_imp_gpio_act #(gpio_seq_item, gpio_scoreboard) item_export;

    gpio_seq_item exp_q[$];

    int total_expected;
    int total_observed;
    int comparisons;
    int pass_count;
    int fail_count;
    int missing_count;
    int unexpected_count;
    int trans_id;
    bit require_activity;

    function new(string name = "gpio_scoreboard", uvm_component parent = null);
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

    virtual function void write_gpio_exp(gpio_seq_item item);
        gpio_seq_item cloned;
        $cast(cloned, item.clone());
        exp_q.push_back(cloned);
        total_expected++;
    endfunction

    virtual function void write_gpio_act(gpio_seq_item item);
        total_observed++;
        if (exp_q.size() == 0) begin
            // Quiescent High-Z at reset stabilization is ignored if unprompted
            if (item.drive_en != 32'h0000_0000 && item.data !== 32'hzzzz_zzzz) begin
                unexpected_count++;
                `uvm_error("GPIO_SCOREBOARD", $sformatf("Unexpected GPIO transaction observed: data=0x%08h, drive_en=0x%08h", item.data, item.drive_en))
            end
        end else begin
            gpio_seq_item exp_item = exp_q.pop_front();
            bit is_pass = 0;
            trans_id++;
            comparisons++;

            if (exp_item.drive_en == 32'hFFFF_FFFF) begin
                if (item.data === exp_item.data) is_pass = 1;
            end else if (exp_item.drive_en == 32'h0000_0000) begin
                if (item.data === 32'hzzzz_zzzz || item.drive_en == 32'h0000_0000) is_pass = 1;
            end else begin
                if ((item.data & exp_item.drive_en) === (exp_item.data & exp_item.drive_en)) is_pass = 1;
            end

            if (is_pass) pass_count++;
            else fail_count++;

            `uvm_info("GPIO_SCOREBOARD", $sformatf("\n------------------------------------------------\nGPIO SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Data=0x%08h, DriveEn=0x%08h (%s)\nActual         : Data=0x%08h, DriveEn=0x%08h (%s)\nComparison     : %s\n------------------------------------------------",
                                                  trans_id,
                                                  exp_item.data, exp_item.drive_en,
                                                  (exp_item.drive_en == 32'hFFFF_FFFF) ? "DRIVE_ALL" : (exp_item.drive_en == 0) ? "HIGH_Z" : "PARTIAL",
                                                  item.data, item.drive_en,
                                                  (item.drive_en == 32'hFFFF_FFFF) ? "DRIVE_ALL" : (item.drive_en == 0) ? "HIGH_Z" : "PARTIAL",
                                                  is_pass ? "PASS" : "FAIL"), UVM_MEDIUM)
            if (!is_pass) begin
                `uvm_error("GPIO_SCOREBOARD", $sformatf("GPIO Mismatch detected on Transaction #%0d!", trans_id))
            end
        end
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (exp_q.size() > 0) begin
            missing_count += exp_q.size();
            exp_q.delete();
        end
        if (require_activity && total_observed == 0) begin
            missing_count++;
            `uvm_error("GPIO_SCOREBOARD", "Zero GPIO transactions observed when activity was required!")
        end
        if (fail_count > 0 || missing_count > 0 || unexpected_count > 0) begin
            `uvm_error("GPIO_SCOREBOARD", $sformatf("GPIO Scoreboard failed: FAIL=%0d, Missing=%0d, Unexpected=%0d",
                                                   fail_count, missing_count, unexpected_count))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("GPIO_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", "             GPIO SCOREBOARD SUMMARY              ", UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("GPIO_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : gpio_scoreboard

`endif // GPIO_SCOREBOARD_SV
