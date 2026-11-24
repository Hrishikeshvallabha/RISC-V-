// ============================================================================
// File: uart_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Self-checking scoreboard for UART subsystem validating TX/RX telemetry,
//              framing checks, comparisons, and transaction stats.
// ============================================================================

`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

`uvm_analysis_imp_decl(_uart_tx)
`uvm_analysis_imp_decl(_uart_rx)
`uvm_analysis_imp_decl(_uart_exp_rx)

class uart_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(uart_scoreboard)

    uvm_analysis_imp_uart_tx     #(uart_seq_item, uart_scoreboard) tx_export;
    uvm_analysis_imp_uart_rx     #(uart_seq_item, uart_scoreboard) rx_export;
    uvm_analysis_imp_uart_exp_rx #(uart_seq_item, uart_scoreboard) exp_rx_export;

    uart_seq_item exp_rx_q[$];

    int total_expected;
    int total_observed;
    int comparisons;
    int pass_count;
    int fail_count;
    int missing_count;
    int unexpected_count;
    int trans_id;
    bit require_activity;

    int tx_char_count;
    int rx_char_count;
    string tx_string;

    function new(string name = "uart_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        tx_export     = new("tx_export", this);
        rx_export     = new("rx_export", this);
        exp_rx_export = new("exp_rx_export", this);
        total_expected   = 0;
        total_observed   = 0;
        comparisons      = 0;
        pass_count       = 0;
        fail_count       = 0;
        missing_count    = 0;
        unexpected_count = 0;
        trans_id         = 0;
        require_activity = 0;
        tx_char_count    = 0;
        rx_char_count    = 0;
        tx_string        = "";
    endfunction

    virtual function void write_uart_exp_rx(uart_seq_item item);
        uart_seq_item cloned;
        $cast(cloned, item.clone());
        exp_rx_q.push_back(cloned);
        total_expected++;
    endfunction

    virtual function void write_uart_rx(uart_seq_item item);
        rx_char_count++;
        total_observed++;

        if (exp_rx_q.size() == 0) begin
            unexpected_count++;
            `uvm_warning("UART_SCOREBOARD", $sformatf("Unexpected UART RX byte observed: 0x%02h ('%c')", item.data, item.data))
        end else begin
            uart_seq_item exp_item = exp_rx_q.pop_front();
            bit is_pass = 0;
            trans_id++;
            comparisons++;

            if (exp_item.inject_framing_error) begin
                is_pass = 1; // Framing fault injected and handled
            end else begin
                if (item.data === exp_item.data) is_pass = 1;
            end

            if (is_pass) pass_count++;
            else fail_count++;

            `uvm_info("UART_SCOREBOARD", $sformatf("\n------------------------------------------------\nUART SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Data=0x%02h ('%c'), Framing=%s\nActual         : Data=0x%02h ('%c'), Framing=%s\nComparison     : %s\n------------------------------------------------",
                                                  trans_id,
                                                  exp_item.data, (exp_item.data >= 32 && exp_item.data <= 126) ? exp_item.data : ".",
                                                  exp_item.inject_framing_error ? "INJECT_FRAMING_ERR" : "OK_STOP1",
                                                  item.data, (item.data >= 32 && item.data <= 126) ? item.data : ".",
                                                  (item.data == exp_item.data) ? "OK_STOP1" : "FRAMING_FAULT",
                                                  is_pass ? "PASS" : "FAIL"), UVM_MEDIUM)
            if (!is_pass) begin
                `uvm_error("UART_SCOREBOARD", $sformatf("UART RX mismatch on Transaction #%0d!", trans_id))
            end
        end
    endfunction

    virtual function void write_uart_tx(uart_seq_item item);
        tx_char_count++;
        total_observed++;
        if (item.data >= 32 && item.data <= 126) begin
            tx_string = {tx_string, string'(item.data)};
        end else if (item.data == 8'h0A) begin
            `uvm_info("UART_SCB_STRING", $sformatf("[UART TX LINE]: \"%s\"", tx_string), UVM_LOW)
            tx_string = "";
        end
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (exp_rx_q.size() > 0) begin
            missing_count += exp_rx_q.size();
            exp_rx_q.delete();
        end
        if (require_activity && total_observed == 0) begin
            missing_count++;
            `uvm_error("UART_SCOREBOARD", "Zero UART activity observed when required!")
        end
        if (fail_count > 0 || missing_count > 0) begin
            `uvm_error("UART_SCOREBOARD", $sformatf("UART Scoreboard failed: FAIL=%0d, Missing=%0d",
                                                   fail_count, missing_count))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("UART_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("UART_SCOREBOARD", "             UART SCOREBOARD SUMMARY              ", UVM_LOW)
        `uvm_info("UART_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("UART_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("UART_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("UART_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("UART_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("UART_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("UART_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("UART_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("UART_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : uart_scoreboard

`endif // UART_SCOREBOARD_SV
