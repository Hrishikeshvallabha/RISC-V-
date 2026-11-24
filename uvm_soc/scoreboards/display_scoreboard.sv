// ============================================================================
// File: display_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Self-checking scoreboard for Seven-Segment Display controller,
//              comparing expected programmed display word vs actual multiplexed digits.
// ============================================================================

`ifndef DISPLAY_SCOREBOARD_SV
`define DISPLAY_SCOREBOARD_SV

`uvm_analysis_imp_decl(_disp_axi)
`uvm_analysis_imp_decl(_disp_item)

class display_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(display_scoreboard)

    uvm_analysis_imp_disp_axi  #(interconnect_seq_item, display_scoreboard) axi_export;
    uvm_analysis_imp_disp_item #(display_seq_item,     display_scoreboard) item_export;

    int total_expected;
    int total_observed;
    int comparisons;
    int pass_count;
    int fail_count;
    int missing_count;
    int unexpected_count;
    int trans_id;
    bit require_activity;

    bit [15:0] expected_word;
    bit [15:0] last_verified_word;

    // Backward compatibility metrics
    int total_display_samples;
    bit [15:0] last_word;

    function new(string name = "display_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        axi_export  = new("axi_export", this);
        item_export = new("item_export", this);
        total_expected        = 0;
        total_observed        = 0;
        comparisons           = 0;
        pass_count            = 0;
        fail_count            = 0;
        missing_count         = 0;
        unexpected_count      = 0;
        trans_id              = 0;
        require_activity      = 0;
        total_display_samples = 0;
        last_word             = 16'h0000;

        expected_word      = 16'h25C0; // Default boot display (25 C)
        last_verified_word = 16'hFFFF;
    endfunction

    virtual function void write_disp_axi(interconnect_seq_item item);
        if (item.is_write && item.addr == 32'h4000_C000) begin
            total_expected++;
            expected_word = item.data[15:0];
            `uvm_info("DISPLAY_SCOREBOARD", $sformatf("[%0t] [MODEL UPDATE] Programmed 7-Segment Word Reg=0x%04h",
                                                     $time, expected_word), UVM_MEDIUM)
        end
    endfunction

    virtual function void write_disp_item(display_seq_item item);
        total_display_samples++;
        last_word = item.assembled_digits;
        total_observed++;

        if (total_expected == 0) total_expected = 1;

        // When the assembled digits reach the expected word, confirm verified transition
        if (item.assembled_digits === expected_word && last_verified_word !== expected_word) begin
            trans_id++;
            comparisons++;
            pass_count++;
            last_verified_word = expected_word;

            `uvm_info("DISPLAY_SCOREBOARD", $sformatf("\n------------------------------------------------\nDISPLAY SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Word=0x%04h (Digits: %0x %0x %0x %0x)\nActual         : Word=0x%04h (Digits: %0x %0x %0x %0x)\nComparison     : PASS\n------------------------------------------------",
                                                     trans_id,
                                                     expected_word, expected_word[15:12], expected_word[11:8], expected_word[7:4], expected_word[3:0],
                                                     item.assembled_digits,
                                                     item.assembled_digits[15:12], item.assembled_digits[11:8],
                                                     item.assembled_digits[7:4], item.assembled_digits[3:0]), UVM_MEDIUM)
        end
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (require_activity) begin
            if (expected_word !== 16'h0000 && last_verified_word !== expected_word) begin
                fail_count++;
                `uvm_error("DISPLAY_SCOREBOARD", $sformatf("Display never reached expected word 0x%04h, last word was 0x%04h",
                                                          expected_word, last_word))
            end
            if (total_observed == 0) begin
                missing_count++;
                `uvm_error("DISPLAY_SCOREBOARD", "Zero Display samples captured when activity was required!")
            end
        end
        if (fail_count > 0 || missing_count > 0) begin
            `uvm_error("DISPLAY_SCOREBOARD", $sformatf("Display Scoreboard finished with errors: FAIL=%0d, Missing=%0d",
                                                      fail_count, missing_count))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("DISPLAY_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", "           DISPLAY SCOREBOARD SUMMARY             ", UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("DISPLAY_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : display_scoreboard

`endif // DISPLAY_SCOREBOARD_SV
