// ============================================================================
// File: uart_driver.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Dynamic UVM driver serializing 8N1 UART frames onto uart_rx_i.
// ============================================================================

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_seq_item);

    virtual uart_uvm_if vif;
    uvm_analysis_port #(uart_seq_item) drv_ap;

    `uvm_component_utils(uart_driver)

    function new(string name = "uart_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv_ap = new("drv_ap", this);
        if (!uvm_config_db#(virtual uart_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for uart_driver")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Quiescent idle high
        vif.uart_rx <= 1'b1;

        @(posedge vif.rst_n);
        repeat (10) @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            drive_frame(req);
            seq_item_port.item_done();
        end
    endtask

    int trans_id = 0;

    virtual task drive_frame(uart_seq_item item);
        time bit_period = item.baud_period_ns * 1ns;
        trans_id++;
        drv_ap.write(item);

        `uvm_info("UART_DRIVER", $sformatf("[%0t] [TX #%0d] Driving UART 8N1 serial frame: data=0x%02h ('%c'), bit_period=%0dns, inject_framing_err=%0b",
                                          $time, trans_id, item.data,
                                          (item.data >= 32 && item.data <= 126) ? item.data : ".",
                                          item.baud_period_ns, item.inject_framing_error), UVM_MEDIUM)

        // 1. Start Bit (Logic 0)
        vif.uart_rx <= 1'b0;
        #bit_period;

        // 2. Eight Data Bits (LSB First)
        for (int i = 0; i < 8; i++) begin
            vif.uart_rx <= item.data[i];
            #bit_period;
        end

        // 3. Stop Bit (Logic 1, or 0 if injecting framing error)
        if (item.inject_framing_error) begin
            vif.uart_rx <= 1'b0;
            `uvm_info("UART_DRIVER", $sformatf("[%0t] [TX #%0d] Injecting framing error: Stop Bit forced LOW (0)", $time, trans_id), UVM_LOW)
        end else begin
            vif.uart_rx <= 1'b1;
        end
        #bit_period;

        // Return to idle
        vif.uart_rx <= 1'b1;
        #(bit_period); // Inter-frame guard
    endtask

endclass : uart_driver

`endif // UART_DRIVER_SV
