// ============================================================================
// File: pwm_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive PWM monitor measuring physical pulse widths and duty cycle.
// ============================================================================

`ifndef PWM_MONITOR_SV
`define PWM_MONITOR_SV

class pwm_monitor extends uvm_monitor;

    virtual pwm_uvm_if vif;
    uvm_analysis_port #(pwm_seq_item) ap;

    `uvm_component_utils(pwm_monitor)

    function new(string name = "pwm_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual pwm_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for pwm_monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        time t_rise, t_fall, t_next_rise;
        pwm_seq_item item;

        @(posedge vif.rst_n);

        forever begin
            @(posedge vif.pwm_out);
            t_rise = $time;

            @(negedge vif.pwm_out);
            t_fall = $time;

            @(posedge vif.pwm_out);
            t_next_rise = $time;

            item = pwm_seq_item::type_id::create("mon_pwm_item");
            item.high_time = t_fall - t_rise;
            item.low_time  = t_next_rise - t_fall;
            item.period    = t_next_rise - t_rise;
            if (item.period > 0) begin
                item.duty_cycle_pct = (real'(item.high_time) / real'(item.period)) * 100.0;
            end else begin
                item.duty_cycle_pct = 0.0;
            end

            `uvm_info("PWM_MONITOR", $sformatf("[%0t] Observed PWM waveform: period=%0t (%0d ns), high_time=%0t (%0d ns), low_time=%0t (%0d ns), duty=%0.2f%% (%s)",
                                              $time, item.period, item.period/1ns, item.high_time, item.high_time/1ns,
                                              item.low_time, item.low_time/1ns, item.duty_cycle_pct,
                                              (item.duty_cycle_pct >= 22.0 && item.duty_cycle_pct <= 28.0) ? "QUIET_25%" :
                                              (item.duty_cycle_pct >= 47.0 && item.duty_cycle_pct <= 53.0) ? "WARM_50%" :
                                              (item.duty_cycle_pct >= 82.0 && item.duty_cycle_pct <= 88.0) ? "BOOST_85%" :
                                              (item.duty_cycle_pct >= 97.0) ? "EMERGENCY_100%" : "INTERMEDIATE"),
                      UVM_MEDIUM)
            ap.write(item);
        end
    endtask

endclass : pwm_monitor

`endif // PWM_MONITOR_SV
