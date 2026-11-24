// ============================================================================
// File: spi_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Self-checking scoreboard for SPI temperature sensor transfers,
//              comparing configured sensor profile vs actual monitored MISO/MOSI.
// ============================================================================

`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

`uvm_analysis_imp_decl(_spi_exp)
`uvm_analysis_imp_decl(_spi_act)

class spi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp_spi_exp #(spi_seq_item, spi_scoreboard) exp_export;
    uvm_analysis_imp_spi_act #(spi_seq_item, spi_scoreboard) item_export;

    spi_seq_item exp_q[$];

    int total_expected;
    int total_observed;
    int comparisons;
    int pass_count;
    int fail_count;
    int missing_count;
    int unexpected_count;
    int trans_id;
    bit require_activity;

    function new(string name = "spi_scoreboard", uvm_component parent = null);
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

    virtual function void write_spi_exp(spi_seq_item item);
        spi_seq_item cloned;
        $cast(cloned, item.clone());
        exp_q.push_back(cloned);
        total_expected++;
    endfunction

    virtual function void write_spi_act(spi_seq_item item);
        total_observed++;

        if (exp_q.size() == 0) begin
            unexpected_count++;
            `uvm_warning("SPI_SCOREBOARD", $sformatf("Unexpected SPI transaction observed: Temp=%0d C, MISO=0x%02h", item.temperature_c, item.miso_resp))
        end else begin
            spi_seq_item exp_item = exp_q.pop_front();
            bit is_pass = 0;
            trans_id++;
            comparisons++;

            if (item.temperature_c === exp_item.temperature_c && item.miso_resp === exp_item.miso_resp) begin
                is_pass = 1;
                pass_count++;
            end else begin
                is_pass = 0;
                fail_count++;
            end

            `uvm_info("SPI_SCOREBOARD", $sformatf("\n------------------------------------------------\nSPI SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Temp=%0d C (Raw=0x%02h)\nActual         : Temp=%0d C (Raw=0x%02h), MOSI=0x%02h\nComparison     : %s\n------------------------------------------------",
                                                 trans_id,
                                                 exp_item.temperature_c, exp_item.miso_resp,
                                                 item.temperature_c, item.miso_resp, item.mosi_cmd,
                                                 is_pass ? "PASS" : "FAIL"), UVM_MEDIUM)
            if (!is_pass) begin
                `uvm_error("SPI_SCOREBOARD", $sformatf("SPI sensor mismatch on Transaction #%0d!", trans_id))
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
            `uvm_error("SPI_SCOREBOARD", "Zero SPI transactions observed when activity was required!")
        end
        if (fail_count > 0 || missing_count > 0) begin
            `uvm_error("SPI_SCOREBOARD", $sformatf("SPI Scoreboard finished with errors: FAIL=%0d, Missing=%0d",
                                                   fail_count, missing_count))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SPI_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", "              SPI SCOREBOARD SUMMARY              ", UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : spi_scoreboard

`endif // SPI_SCOREBOARD_SV
