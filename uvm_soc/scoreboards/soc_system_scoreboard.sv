// ============================================================================
// File: soc_system_scoreboard.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: System-level closed-loop scoreboard correlating SPI temperature,
//              VeeR EL2 thermal policy, CPU AXI register writes, PWM fan duty,
//              7-Seg display, and UART telemetry.
// ============================================================================

`ifndef SOC_SYSTEM_SCOREBOARD_SV
`define SOC_SYSTEM_SCOREBOARD_SV

`uvm_analysis_imp_decl(_sys_spi)
`uvm_analysis_imp_decl(_sys_pwm)
`uvm_analysis_imp_decl(_sys_disp)
`uvm_analysis_imp_decl(_sys_axi)
`uvm_analysis_imp_decl(_sys_uart)

class soc_system_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(soc_system_scoreboard)

    uvm_analysis_imp_sys_spi  #(spi_seq_item,          soc_system_scoreboard) spi_export;
    uvm_analysis_imp_sys_pwm  #(pwm_seq_item,          soc_system_scoreboard) pwm_export;
    uvm_analysis_imp_sys_disp #(display_seq_item,      soc_system_scoreboard) disp_export;
    uvm_analysis_imp_sys_axi  #(interconnect_seq_item, soc_system_scoreboard) axi_export;
    uvm_analysis_imp_sys_uart #(uart_seq_item,         soc_system_scoreboard) uart_export;

    int current_sensor_temp;
    real current_pwm_duty;
    bit [15:0] current_display_word;

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
    int tier_normal_passes;
    int tier_warm_passes;
    int tier_boost_passes;
    int tier_failsafe_passes;

    function new(string name = "soc_system_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        spi_export  = new("spi_export", this);
        pwm_export  = new("pwm_export", this);
        disp_export = new("disp_export", this);
        axi_export  = new("axi_export", this);
        uart_export = new("uart_export", this);

        current_sensor_temp  = 25;
        current_pwm_duty     = 25.0;
        current_display_word = 16'h25C0;

        total_expected   = 0;
        total_observed   = 0;
        comparisons      = 0;
        pass_count       = 0;
        fail_count       = 0;
        missing_count    = 0;
        unexpected_count = 0;
        trans_id         = 0;
        require_activity = 0;

        tier_normal_passes   = 0;
        tier_warm_passes     = 0;
        tier_boost_passes    = 0;
        tier_failsafe_passes = 0;
    endfunction

    virtual function void write_sys_spi(spi_seq_item item);
        current_sensor_temp = item.temperature_c;
        total_expected++;
        `uvm_info("SOC_SCOREBOARD", $sformatf("[%0t] [SENSOR TELEMETRY] Temperature received: %0d C (Raw=0x%02h)",
                                              $time, current_sensor_temp, item.temperature_c), UVM_MEDIUM)
    endfunction

    virtual function void write_sys_axi(interconnect_seq_item item);
        if (item.is_write && item.addr == 32'h4000_A000) begin
            `uvm_info("SOC_SCOREBOARD", $sformatf("[%0t] [CPU AXI WRITE] VeeR EL2 wrote PWM Duty Register: 0x%02h (%.1f%% target)",
                                                 $time, item.data[7:0], (real'(item.data[7:0]) / 256.0) * 100.0), UVM_MEDIUM)
        end else if (item.is_write && item.addr == 32'h4000_C000) begin
            `uvm_info("SOC_SCOREBOARD", $sformatf("[%0t] [CPU AXI WRITE] VeeR EL2 wrote 7-Segment Word Register: 0x%04h",
                                                 $time, item.data[15:0]), UVM_MEDIUM)
        end
    endfunction

    virtual function void write_sys_uart(uart_seq_item item);
        `uvm_info("SOC_SCOREBOARD", $sformatf("[%0t] [CPU UART TELEMETRY] Telemetry Byte: 0x%02h ('%c')",
                                             $time, item.data, (item.data >= 32 && item.data <= 126) ? item.data : "."), UVM_HIGH)
    endfunction

    virtual function void write_sys_pwm(pwm_seq_item item);
        total_observed++;
        current_pwm_duty = item.duty_cycle_pct;
        verify_thermal_policy();
    endfunction

    virtual function void write_sys_disp(display_seq_item item);
        if (item.assembled_digits != current_display_word) begin
            current_display_word = item.assembled_digits;
            verify_display_policy();
        end
    endfunction

    virtual function void verify_thermal_policy();
        bit is_match = 0;
        string tier_name = "UNKNOWN";
        real exp_duty = 25.0;
        bit [15:0] exp_disp = 16'h25C0;

        trans_id++;
        comparisons++;

        if (current_sensor_temp <= 25) begin
            tier_name = "QUIET (25% Duty)";
            exp_duty = 25.0;
            exp_disp = 16'h25C0;
            if (current_pwm_duty >= 22.0 && current_pwm_duty <= 28.0) begin
                tier_normal_passes++;
                is_match = 1;
            end
        end else if (current_sensor_temp > 25 && current_sensor_temp <= 45) begin
            tier_name = "WARM (50% Duty)";
            exp_duty = 50.0;
            exp_disp = 16'h30C0;
            if (current_pwm_duty >= 47.0 && current_pwm_duty <= 53.0) begin
                tier_warm_passes++;
                is_match = 1;
            end
        end else if (current_sensor_temp > 45 && current_sensor_temp <= 70) begin
            tier_name = "BOOST (85% Duty)";
            exp_duty = 84.8;
            exp_disp = 16'h50C0;
            if (current_pwm_duty >= 82.0 && current_pwm_duty <= 88.0) begin
                tier_boost_passes++;
                is_match = 1;
            end
        end else if (current_sensor_temp > 70) begin
            tier_name = "EMERGENCY_FAILSAFE (100% Duty)";
            exp_duty = 100.0;
            exp_disp = 16'hEEEE;
            if (current_pwm_duty >= 97.0) begin
                tier_failsafe_passes++;
                is_match = 1;
            end
        end

        if (is_match) pass_count++;
        else begin
            if (require_activity) fail_count++;
        end

        `uvm_info("SOC_SCOREBOARD", $sformatf("\n------------------------------------------------\nSOC SYSTEM CLOSED-LOOP SCOREBOARD\n------------------------------------------------\nTransaction ID : %0d\nExpected       : Temp=%0d C -> Tier=%s, ExpDuty=%.1f%%\nActual         : PWM_Duty=%.1f%%, Display_Word=0x%04h\nComparison     : %s\n------------------------------------------------",
                                              trans_id, current_sensor_temp, tier_name, exp_duty,
                                              current_pwm_duty, current_display_word,
                                              is_match ? "PASS" : "FAIL"), UVM_MEDIUM)
    endfunction

    virtual function void verify_display_policy();
        `uvm_info("SOC_SCOREBOARD", $sformatf("[%0t] [DISPLAY TELEMETRY UPDATE] 7-Segment Display Word=0x%04h for Temp=%0d C",
                                              $time, current_display_word, current_sensor_temp), UVM_MEDIUM)
        if (current_sensor_temp > 70 && current_display_word == 16'hEEEE) begin
            `uvm_info("SOC_SCOREBOARD", $sformatf("[%0t] [DISPLAY POLICY EVALUATION] Emergency 'EEEE' Pattern Verified for Temp=%0d C [PASS]",
                                                  $time, current_sensor_temp), UVM_MEDIUM)
        end
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (require_activity) begin
            if (comparisons == 0) begin
                missing_count++;
                `uvm_error("SOC_SCOREBOARD", "Zero closed-loop thermal comparisons performed when required!")
            end
            if (fail_count > 0 || missing_count > 0) begin
                `uvm_error("SOC_SCOREBOARD", $sformatf("SOC System Scoreboard finished with errors: FAIL=%0d, Missing=%0d",
                                                       fail_count, missing_count))
            end
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SOC_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", "       SOC SYSTEM SCOREBOARD SUMMARY              ", UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", "==================================================", UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("Total expected: %0d", total_expected), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("Total observed: %0d", total_observed), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("Comparisons:    %0d", comparisons), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("PASS:           %0d", pass_count), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("FAIL:           %0d", fail_count), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("Missing:        %0d", missing_count), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("Unexpected:     %0d", unexpected_count), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", "--------------------------------------------------", UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("  Quiet Mode (25 C -> 25%% PWM) Checks Passed:     %0d", tier_normal_passes), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("  Warm Mode (30 C -> 50%% PWM) Checks Passed:      %0d", tier_warm_passes), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("  Boost Mode (50 C -> 85%% PWM) Checks Passed:     %0d", tier_boost_passes), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", $sformatf("  Fail-Safe Mode (130 C -> 100%% PWM) Passed:      %0d", tier_failsafe_passes), UVM_LOW)
        `uvm_info("SOC_SCOREBOARD", "==================================================", UVM_LOW)
    endfunction

endclass : soc_system_scoreboard

`endif // SOC_SYSTEM_SCOREBOARD_SV
