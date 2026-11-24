// ============================================================================
// File: pwm_coverage.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Functional coverage collector for PWM Fan duty-cycle tiers.
// ============================================================================

`ifndef PWM_COVERAGE_SV
`define PWM_COVERAGE_SV

class pwm_coverage extends uvm_subscriber #(pwm_seq_item);

    `uvm_component_utils(pwm_coverage)

    pwm_seq_item cov_item;

    covergroup pwm_cg;
        option.per_instance = 1;
        option.name = "pwm_functional_coverage";

        cp_duty_tiers: coverpoint int'(cov_item.duty_cycle_pct) {
            bins duty_zero      = {0};
            bins duty_quiet_25  = {[22:28]};
            bins duty_warm_50   = {[47:53]};
            bins duty_boost_85  = {[82:88]};
            bins duty_full_100  = {[98:100]};
            bins other_duties   = default;
        }
    endgroup

    function new(string name = "pwm_coverage", uvm_component parent = null);
        super.new(name, parent);
        pwm_cg = new();
    endfunction

    virtual function void write(pwm_seq_item t);
        cov_item = t;
        pwm_cg.sample();
    endfunction

endclass : pwm_coverage

`endif // PWM_COVERAGE_SV
