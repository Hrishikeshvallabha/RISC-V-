// ============================================================================
// File: interconnect_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Self-checking scoreboard for AXI4 Crossbar Interconnect, validating
//              slave address decode, response codes, memory reads, and transaction stats.
// ============================================================================

`ifndef INTERCONNECT_SCOREBOARD_SV
`define INTERCONNECT_SCOREBOARD_SV

`uvm_analysis_imp_decl(_ic_exp)
`uvm_analysis_imp_decl(_ic_act)

class interconnect_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(interconnect_scoreboard)

    uvm_analysis_imp_ic_exp #(interconnect_seq_item, interconnect_scoreboard) exp_export;
    uvm_analysis_imp_ic_act #(interconnect_seq_item, interconnect_scoreboard) item_export;

    interconnect_seq_item exp_q[$];
    bit [31:0] ref_mem[bit [31:0]];

    int total_expected;
    int total_observed;
    int comparisons;
    int pass_count;
    int fail_count;
    int missing_count;
    int unexpected_count;
    int trans_id;
    bit require_activity;

    // Backward compatibility metrics
    int total_axi_trans;
    int mem_trans;
    int periph_trans;
    int error_trans;

    function new(string name = "interconnect_scoreboard", uvm_component parent = null);
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
        total_axi_trans  = 0;
        mem_trans        = 0;
        periph_trans     = 0;
        error_trans      = 0;
    endfunction

    virtual function string decode_slave(bit [31:0] addr, output bit [1:0] exp_resp);
        if (addr <= 32'h0000_FFFF) begin
            exp_resp = 2'b00; // OKAY
            return "M00_UnifiedRAM";
        end else if (addr >= 32'h4000_0000 && addr <= 32'h4000_0FFF) begin
            exp_resp = 2'b00;
            return "M01_UART";
        end else if (addr >= 32'h4000_2000 && addr <= 32'h4000_2FFF) begin
            exp_resp = 2'b00;
            return "M02_GPIO";
        end else if (addr >= 32'h4000_4000 && addr <= 32'h4000_4FFF) begin
            exp_resp = 2'b00;
            return "M03_Timer";
        end else if (addr >= 32'h4000_6000 && addr <= 32'h4000_6FFF) begin
            exp_resp = 2'b00;
            return "M04_SPI";
        end else if (addr >= 32'h4000_A000 && addr <= 32'h4000_AFFF) begin
            exp_resp = 2'b00;
            return "M05_PWM";
        end else if (addr >= 32'h4000_C000 && addr <= 32'h4000_CFFF) begin
            exp_resp = 2'b00;
            return "M06_7Segment";
        end else begin
            exp_resp = 2'b11; // DECERR
            return "Reserved_Guard";
        end
    endfunction

    virtual function void write_ic_exp(interconnect_seq_item item);
        interconnect_seq_item cloned;
        $cast(cloned, item.clone());
        exp_q.push_back(cloned);
        total_expected++;
        if (cloned.is_write && cloned.addr <= 32'h0000_FFFF) begin
            ref_mem[cloned.addr] = cloned.data;
        end
    endfunction

    virtual function void write_ic_act(interconnect_seq_item item);
        total_observed++;
        total_axi_trans++;

        if (item.addr <= 32'h0000_FFFF) mem_trans++;
        else if (item.addr >= 32'h4000_0000 && item.addr <= 32'h4000_CFFF) periph_trans++;
        else error_trans++;

        if (exp_q.size() == 0) begin
            // Autonomous CPU firmware transactions to peripherals or memory
            bit [1:0] dummy_resp;
            string target_slave = decode_slave(item.addr, dummy_resp);
            `uvm_info("AXI_SCOREBOARD", $sformatf("[%0t] [CPU AXI ACTIVITY] Addr=0x%08h, Target=%s, Resp=2'b%02b",
                                                 $time, item.addr, target_slave, item.resp), UVM_HIGH)
        end else begin
            interconnect_seq_item exp_item = exp_q.pop_front();
            bit [1:0] exp_resp;
            string exp_slave = decode_slave(exp_item.addr, exp_resp);
            bit [1:0] dummy_resp;
            string act_slave = decode_slave(item.addr, dummy_resp);
            bit is_pass = 1;
            trans_id++;
            comparisons++;

            if (act_slave != exp_slave) is_pass = 0;
            if (item.resp != exp_resp) is_pass = 0;
            if (!item.is_write && item.addr <= 32'h0000_FFFF && ref_mem.exists(item.addr)) begin
                if (item.rdata !== ref_mem[item.addr]) is_pass = 0;
            end

            if (is_pass) pass_count++;
            else fail_count++;

            `uvm_info("AXI_SCOREBOARD", $sformatf("\n------------------------------------------------\nAXI SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Type=%s, Addr=0x%08h, Dest=%s, Resp=%s, Data=0x%08h\nActual         : Type=%s, Addr=0x%08h, Dest=%s, Resp=%s, Data=0x%08h\nComparison     : %s\n------------------------------------------------",
                                                  trans_id,
                                                  exp_item.is_write ? "WRITE" : "READ", exp_item.addr, exp_slave,
                                                  (exp_resp == 2'b00) ? "OKAY" : "DECERR",
                                                  exp_item.is_write ? exp_item.data : (ref_mem.exists(exp_item.addr) ? ref_mem[exp_item.addr] : 32'h0),
                                                  item.is_write ? "WRITE" : "READ", item.addr, act_slave,
                                                  (item.resp == 2'b00) ? "OKAY" : (item.resp == 2'b11) ? "DECERR" : "SLVERR",
                                                  item.is_write ? item.data : item.rdata,
                                                  is_pass ? "PASS" : "FAIL"), UVM_MEDIUM)

            if (!is_pass) begin
                `uvm_error("AXI_SCOREBOARD", $sformatf("AXI transaction mismatch on Transaction #%0d!", trans_id))
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
            `uvm_error("AXI_SCOREBOARD", "Zero AXI transactions observed when activity was required!")
        end
        if (fail_count > 0 || missing_count > 0) begin
            `uvm_error("AXI_SCOREBOARD", $sformatf("AXI Scoreboard finished with errors: FAIL=%0d, Missing=%0d",
                                                  fail_count, missing_count))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", "             AXI SCOREBOARD SUMMARY               ", UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("AXI_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : interconnect_scoreboard

`endif // INTERCONNECT_SCOREBOARD_SV
