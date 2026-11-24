// ============================================================================
// File: gpio_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive GPIO monitor continuously sampling the physical GPIO bus
//              and publishing observed transactions via analysis port.
// ============================================================================

`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;

    virtual gpio_uvm_if vif;
    uvm_analysis_port #(gpio_seq_item) ap;

    `uvm_component_utils(gpio_monitor)

    function new(string name = "gpio_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not found for gpio_monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_seq_item item;
        logic [31:0] prev_val = 32'hxxxx_xxxx;

        // Synchronize with reset
        @(posedge vif.rst_n);

        forever begin
            @(posedge vif.clk);
            if (vif.gpio_sampled !== prev_val) begin
                item = gpio_seq_item::type_id::create("monitored_gpio_item");
                item.data        = vif.gpio_sampled;
                item.drive_en    = vif.gpio_drive_en;
                item.hold_cycles = 1;

                `uvm_info("GPIO_MONITOR", $sformatf("[%0t] Observed GPIO transition: sampled_bus=0x%08h, drive_en=0x%08h, mode=%s, intr=%0b",
                                                   $time, vif.gpio_sampled, vif.gpio_drive_en,
                                                   (vif.gpio_drive_en == 32'h0000_0000) ? "HIGH_IMPEDANCE_INPUT" :
                                                   (vif.gpio_drive_en == 32'hFFFF_FFFF) ? "DRIVEN_OUTPUT_ALL" : "PARTIAL_DRIVE",
                                                   vif.gpio_intr), UVM_MEDIUM)
                ap.write(item);
                prev_val = vif.gpio_sampled;
            end
        end
    endtask

endclass : gpio_monitor

`endif // GPIO_MONITOR_SV
