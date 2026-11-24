// ============================================================================
// File: uart_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive UART monitor capturing serial frames on TX and RX lines.
// ============================================================================

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;

    virtual uart_uvm_if vif;
    uvm_analysis_port #(uart_seq_item) tx_ap;
    uvm_analysis_port #(uart_seq_item) rx_ap;

    time bit_period = 50ns; // Divisor = 4 (50ns bit period)

    `uvm_component_utils(uart_monitor)

    function new(string name = "uart_monitor", uvm_component parent = null);
        super.new(name, parent);
        tx_ap = new("tx_ap", this);
        rx_ap = new("rx_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for uart_monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        @(posedge vif.rst_n);
        fork
            monitor_tx();
            monitor_rx();
        join
    endtask

    // Monitor DUT Transmitter (uart_tx_o)
    virtual task monitor_tx();
        bit [7:0] captured_byte;
        bit       stop_bit;
        uart_seq_item item;

        forever begin
            // Wait for Start Bit falling edge
            @(negedge vif.uart_tx);
            #(bit_period / 2); // Sample at mid-bit

            if (vif.uart_tx == 1'b0) begin
                for (int i = 0; i < 8; i++) begin
                    #bit_period;
                    captured_byte[i] = vif.uart_tx;
                end

                #bit_period; // Stop bit
                stop_bit = vif.uart_tx;
                item = uart_seq_item::type_id::create("mon_tx_item");
                item.data = captured_byte;
                item.baud_period_ns = 50;

                `uvm_info("UART_MONITOR", $sformatf("[%0t] Observed DUT UART TX: data=0x%02h ('%c'), framing=%s, bit_period=%0dns, intr=%0b",
                                                   $time, captured_byte,
                                                   (captured_byte >= 32 && captured_byte <= 126) ? captured_byte : ".",
                                                   (stop_bit == 1'b1) ? "OK_STOP1" : "FRAMING_ERROR",
                                                   item.baud_period_ns, vif.uart_interrupt),
                          UVM_MEDIUM)
                tx_ap.write(item);
            end
        end
    endtask

    // Monitor Driver Receiver Line (uart_rx_i)
    virtual task monitor_rx();
        bit [7:0] captured_byte;
        bit       stop_bit;
        uart_seq_item item;

        forever begin
            @(negedge vif.uart_rx);
            #(bit_period / 2);

            if (vif.uart_rx == 1'b0) begin
                for (int i = 0; i < 8; i++) begin
                    #bit_period;
                    captured_byte[i] = vif.uart_rx;
                end

                #bit_period; // Stop bit
                stop_bit = vif.uart_rx;
                item = uart_seq_item::type_id::create("mon_rx_item");
                item.data = captured_byte;
                item.baud_period_ns = 50;

                `uvm_info("UART_MONITOR", $sformatf("[%0t] Observed DUT UART RX: data=0x%02h ('%c'), framing=%s, bit_period=%0dns",
                                                   $time, captured_byte,
                                                   (captured_byte >= 32 && captured_byte <= 126) ? captured_byte : ".",
                                                   (stop_bit == 1'b1) ? "OK_STOP1" : "FRAMING_FAULT_DETECTED",
                                                   item.baud_period_ns),
                          UVM_MEDIUM)
                rx_ap.write(item);
            end
        end
    endtask

endclass : uart_monitor

`endif // UART_MONITOR_SV
