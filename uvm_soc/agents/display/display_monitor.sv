// ============================================================================
// File: display_monitor.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: Passive monitor decoding physical 7-segment cathodes and anodes.
// ============================================================================

`ifndef DISPLAY_MONITOR_SV
`define DISPLAY_MONITOR_SV

class display_monitor extends uvm_monitor;

    virtual display_uvm_if vif;
    uvm_analysis_port #(display_seq_item) ap;

    bit [15:0] live_assembled_word = 16'h0000;

    `uvm_component_utils(display_monitor)

    function new(string name = "display_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual display_uvm_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface 'vif' not configured for display_monitor")
        end
    endfunction

    // Pure reference model decoding cathode patterns to hex nibble
    virtual function bit [3:0] decode_segments(bit [6:0] s);
        case (s)
            7'b000_0001: return 4'h0;
            7'b100_1111: return 4'h1;
            7'b001_0010: return 4'h2;
            7'b000_0110: return 4'h3;
            7'b100_1100: return 4'h4;
            7'b010_0100: return 4'h5;
            7'b010_0000: return 4'h6;
            7'b000_1111: return 4'h7;
            7'b000_0000: return 4'h8;
            7'b000_0100: return 4'h9;
            7'b000_1000: return 4'hA;
            7'b110_0000: return 4'hB;
            7'b011_0001: return 4'hC;
            7'b100_0010: return 4'hD;
            7'b011_0000: return 4'hE;
            7'b011_1000: return 4'hF;
            default:     return 4'h0;
        endcase
    endfunction

    virtual task run_phase(uvm_phase phase);
        display_seq_item item;
        bit [3:0] dec_nibble;
        logic [3:0] prev_an = 4'b1111;
        bit [15:0] prev_word = 16'h0000;

        @(posedge vif.rst_n);

        forever begin
            @(posedge vif.clk);
            if (vif.an != 4'b1111 && vif.seg != 7'b111_1111) begin
                dec_nibble = decode_segments(vif.seg);

                case (vif.an)
                    4'b1110: live_assembled_word[3:0]   = dec_nibble; // Digit 0
                    4'b1101: live_assembled_word[7:4]   = dec_nibble; // Digit 1
                    4'b1011: live_assembled_word[11:8]  = dec_nibble; // Digit 2
                    4'b0111: live_assembled_word[15:12] = dec_nibble; // Digit 3
                    default: ;
                endcase

                item = display_seq_item::type_id::create("mon_display_item");
                item.anode_mask       = vif.an;
                item.raw_seg          = vif.seg;
                item.digit_val        = dec_nibble;
                item.assembled_digits = live_assembled_word;

                // Log on each digit transition
                if (vif.an !== prev_an) begin
                    `uvm_info("DISPLAY_MONITOR", $sformatf("[%0t] Observed 7-Segment Digit Step: Anode=4'b%04b (Digit %0d active), Cathode_Segments=7'b%07b, Decoded_Nibble=0x%01h, Live_Word=0x%04h",
                                                          $time, vif.an,
                                                          (vif.an == 4'b1110) ? 0 :
                                                          (vif.an == 4'b1101) ? 1 :
                                                          (vif.an == 4'b1011) ? 2 : 3,
                                                          vif.seg, dec_nibble, live_assembled_word), UVM_MEDIUM)
                    prev_an = vif.an;
                end

                // Log when full 4-digit word updates
                if (live_assembled_word !== prev_word) begin
                    `uvm_info("DISPLAY_MONITOR", $sformatf("[%0t] [DISPLAY REFRESH UPDATE] 4-digit word updated: 0x%04h (Decoded: %s)",
                                                          $time, live_assembled_word,
                                                          (live_assembled_word == 16'hEEEE) ? "ERROR_OUT_OF_BOUNDS (0xEEEE)" :
                                                          $sformatf("%0d%0d C", live_assembled_word[15:12], live_assembled_word[11:8])), UVM_MEDIUM)
                    prev_word = live_assembled_word;
                end

                ap.write(item);
            end
        end
    endtask

endclass : display_monitor

`endif // DISPLAY_MONITOR_SV
