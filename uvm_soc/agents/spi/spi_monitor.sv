// ============================================================================
// File: spi_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive SPI monitor capturing full-duplex MOSI/MISO byte transfers.
// ============================================================================

`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;

    virtual spi_uvm_if vif;
    uvm_analysis_port #(spi_seq_item) ap;

    `uvm_component_utils(spi_monitor)

    function new(string name = "spi_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for spi_monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        bit [7:0] captured_mosi;
        bit [7:0] captured_miso;
        spi_seq_item item;

        @(posedge vif.rst_n);

        forever begin
            @(negedge vif.spi_cs_n);
            captured_mosi = 8'h00;
            captured_miso = 8'h00;

            for (int i = 0; i < 8; i++) begin
                @(posedge vif.spi_clk);
                captured_mosi[7 - i] = vif.spi_mosi;
                captured_miso[7 - i] = vif.spi_miso;
            end

            @(posedge vif.spi_cs_n);

            item = spi_seq_item::type_id::create("mon_spi_item");
            item.mosi_cmd      = captured_mosi;
            item.miso_resp     = captured_miso;
            item.temperature_c = captured_miso;

            `uvm_info("SPI_MONITOR", $sformatf("[%0t] Observed SPI exchange completed: MOSI_cmd=0x%02h, MISO_resp=0x%02h, Decoded_Temp=%0d C, CS#=1, IRQ=%0b",
                                              $time, captured_mosi, captured_miso, captured_miso, vif.spi_irq), UVM_MEDIUM)
            ap.write(item);
        end
    endtask

endclass : spi_monitor

`endif // SPI_MONITOR_SV
