// ============================================================================
// File: veer_core_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive monitor tracking VeeR EL2 instruction execution,
//              retired instruction counts, interrupts, and memory accesses.
// ============================================================================

`ifndef VEER_CORE_MONITOR_SV
`define VEER_CORE_MONITOR_SV

class veer_core_monitor extends uvm_component;

    `uvm_component_utils(veer_core_monitor)

    virtual veer_trace_uvm_if trace_vif;

    int retired_instruction_count;
    int exception_count;
    int interrupt_count;
    bit cpu_booted;

    function new(string name = "veer_core_monitor", uvm_component parent = null);
        super.new(name, parent);
        retired_instruction_count = 0;
        exception_count = 0;
        interrupt_count = 0;
        cpu_booted = 1'b0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual veer_trace_uvm_if)::get(this, "", "trace_vif", trace_vif)) begin
            `uvm_info("VEER_CORE_MON", "Optional trace_vif not bound, manual sampling enabled", UVM_HIGH)
        end
    endfunction

    virtual function void record_retired_insn(bit [31:0] pc, bit [31:0] insn);
        retired_instruction_count++;
        if (retired_instruction_count == 1) begin
            `uvm_info("CPU_BOOT", $sformatf("[%0t] VeeR EL2 CPU execution initiated: First instruction fetched at PC=0x%08h, Insn=0x%08h",
                                           $time, pc, insn), UVM_LOW)
        end
        if (!cpu_booted && retired_instruction_count > 10) begin
            cpu_booted = 1'b1;
            `uvm_info("CPU_BOOT", $sformatf("[%0t] [PASS] VeeR EL2 CPU actively executing firmware from Unified Memory (PC=0x%08h)",
                                           $time, pc), UVM_LOW)
        end
        if (retired_instruction_count % 100 == 0) begin
            `uvm_info("CPU_TRACE", $sformatf("[%0t] VeeR EL2 Instruction Retirement: count=%0d, Current PC=0x%08h, Insn=0x%08h",
                                            $time, retired_instruction_count, pc, insn), UVM_MEDIUM)
        end
    endfunction

    virtual function void record_interrupt(bit [4:0] cause);
        interrupt_count++;
        `uvm_info("CPU_INT", $sformatf("VeeR EL2 serviced external interrupt: cause=0x%02h", cause), UVM_MEDIUM)
    endfunction

    virtual task run_phase(uvm_phase phase);
        if (trace_vif == null) return;

        forever @(posedge trace_vif.clk) begin
            if (trace_vif.rst_n && trace_vif.valid) begin
                record_retired_insn(trace_vif.address, trace_vif.insn);
            end
            if (trace_vif.rst_n && trace_vif.interrupt) begin
                record_interrupt(trace_vif.ecause);
            end
            if (trace_vif.rst_n && trace_vif.exception) begin
                exception_count++;
            end
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("CPU_FINAL", "--------------------------------------------------", UVM_LOW)
        `uvm_info("CPU_FINAL", $sformatf("VeeR EL2 Summary: %0d instructions retired, %0d interrupts serviced, %0d exceptions",
                                          retired_instruction_count, interrupt_count, exception_count), UVM_LOW)
        `uvm_info("CPU_FINAL", "--------------------------------------------------", UVM_LOW)
    endfunction

endclass : veer_core_monitor

`endif // VEER_CORE_MONITOR_SV
