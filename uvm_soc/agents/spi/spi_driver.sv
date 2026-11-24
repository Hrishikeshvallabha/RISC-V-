// ============================================================================
// File: spi_driver.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Reactive UVM slave driver modeling external SPI temperature sensor.
// ============================================================================

`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_seq_item);

    virtual spi_uvm_if vif;
    uvm_analysis_port #(spi_seq_item) drv_ap;

    bit [7:0] active_temp_byte = 8'h19; // Default 25 C
    int transaction_idx = 0;

    `uvm_component_utils(spi_driver)

    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv_ap = new("drv_ap", this);
        if (!uvm_config_db#(virtual spi_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for spi_driver")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.spi_miso <= 1'b0;
        @(posedge vif.rst_n);

        fork
            // Background transaction fetcher
            fetch_items();
            // Reactive SPI Slave responder
            respond_to_spi();
        join
    endtask

    virtual task fetch_items();
        forever begin
            seq_item_port.try_next_item(req);
            if (req != null) begin
                active_temp_byte = req.miso_resp;
                `uvm_info("SPI_DRIVER", $sformatf("[%0t] Temperature sensor profile updated: queued response temp=%0d C (MISO=0x%02h)",
                                                 $time, req.temperature_c, active_temp_byte), UVM_MEDIUM)
                seq_item_port.item_done();
            end else begin
                #100ns;
            end
        end
    endtask

    virtual task respond_to_spi();
        forever begin
            // Wait for Master to assert Chip Select (Active Low)
            @(negedge vif.spi_cs_n);
            transaction_idx++;
            begin
                spi_seq_item exp_item = spi_seq_item::type_id::create("spi_exp_item");
                exp_item.temperature_c = active_temp_byte;
                exp_item.miso_resp     = active_temp_byte;
                exp_item.mosi_cmd      = 8'h00;
                drv_ap.write(exp_item);
            end

            `uvm_info("SPI_DRIVER", $sformatf("[%0t] [Exchange #%0d] CS# Asserted (0): Starting SPI transfer with configured sensor temp=%0d C (MISO=0x%02h), SCLK=%0b",
                                             $time, transaction_idx, active_temp_byte, active_temp_byte, vif.spi_clk), UVM_MEDIUM)

            // SPI Mode 0: Present MSB prior to first rising clock edge
            vif.spi_miso <= active_temp_byte[7];

            fork
                begin : shift_bits
                    for (int bit_idx = 0; bit_idx < 8; bit_idx++) begin
                        @(posedge vif.spi_clk); // Master samples MISO, drives MOSI
                        @(negedge vif.spi_clk); // Slave updates MISO
                        if (bit_idx < 7) begin
                            vif.spi_miso <= active_temp_byte[6 - bit_idx];
                        end
                    end
                end
                begin : wait_cs_deassert
                    @(posedge vif.spi_cs_n);
                end
            join_any
            disable fork;

            // Release MISO to quiescent low after CS# deasserts
            vif.spi_miso <= 1'b0;
            `uvm_info("SPI_DRIVER", $sformatf("[%0t] [Exchange #%0d] CS# Deasserted (1): SPI byte transfer finished, MISO released to 0",
                                             $time, transaction_idx), UVM_MEDIUM)
        end
    endtask

endclass : spi_driver

`endif // SPI_DRIVER_SV
