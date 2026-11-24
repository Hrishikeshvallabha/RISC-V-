// ============================================================================
// File: gpio_driver.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Dynamic UVM driver component that retrieves the virtual
//              interface handle via uvm_config_db and drives pin stimulus
//              directly to the statically instantiated SoC DUT pins.
// ============================================================================

`ifndef GPIO_DRIVER_SV
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_seq_item);

    // Dynamic handle referring to the static SystemVerilog interface instance
    virtual gpio_uvm_if vif;
    uvm_analysis_port #(gpio_seq_item) drv_ap;

    `uvm_component_utils(gpio_driver)

    function new(string name = "gpio_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv_ap = new("drv_ap", this);

        `uvm_info("GPIO_DRV_BUILD", "Entering build_phase: attempting to retrieve virtual interface from uvm_config_db", UVM_LOW)

        // Retrieve the virtual interface handle registered by the top-level testbench
        if (!uvm_config_db#(virtual gpio_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' was not configured for gpio_driver in uvm_config_db! Dynamic driver cannot connect to static DUT interface.")
        end else begin
            `uvm_info("GPIO_DRV_BUILD", "Successfully retrieved virtual interface handle 'vif' from uvm_config_db. Static-to-dynamic binding established.", UVM_LOW)
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("GPIO_DRV_RUN", "Entering run_phase: initializing interface pins", UVM_LOW)

        // Initialize signals to quiescent high-impedance state
        vif.gpio_in       <= '0;
        vif.gpio_drive_en <= '0;

        // Synchronize with reset release
        if (!vif.rst_n) begin
            `uvm_info("GPIO_DRV_RUN", "Waiting for reset deassertion (rst_n = 1)...", UVM_LOW)
            @(posedge vif.rst_n);
            `uvm_info("GPIO_DRV_RUN", "Reset deasserted. Driver ready to process transactions.", UVM_LOW)
        end

        // Wait a few cycles after reset stabilization
        repeat (2) @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    int trans_id = 0;

    virtual task drive_item(gpio_seq_item item);
        trans_id++;
        drv_ap.write(item);
        `uvm_info("GPIO_DRIVER", $sformatf("[%0t] [TX #%0d] Driving GPIO: data=0x%08h, drive_en=0x%08h (%s), hold_cycles=%0d",
                                          $time, trans_id, item.data, item.drive_en,
                                          (item.drive_en == 32'hFFFF_FFFF) ? "DRIVE_ALL_PINS" :
                                          (item.drive_en == 32'h0000_0000) ? "HIGH_IMPEDANCE_RELEASE" : "PARTIAL_DRIVE",
                                          item.hold_cycles), UVM_MEDIUM)

        @(posedge vif.clk);
        vif.gpio_drive_en <= item.drive_en;
        vif.gpio_in       <= item.data;

        repeat (item.hold_cycles) @(posedge vif.clk);
    endtask

endclass : gpio_driver

`endif // GPIO_DRIVER_SV
