`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Module: seven_segment_mux
// Description:
//   4-Digit 7-Segment Display Multiplexer with integrated clock refresh divider.
//   Sequentially cycles through 4 hexadecimal digits:
//     - Digit 0 (digits[3:0])   -> an[0] active (4'b1110)
//     - Digit 1 (digits[7:4])   -> an[1] active (4'b1101)
//     - Digit 2 (digits[11:8])  -> an[2] active (4'b1011)
//     - Digit 3 (digits[15:12]) -> an[3] active (4'b0111)
//
// Hardware Model & Polarity:
//   Common-Anode (Active-Low):
//     an[3:0]:  0 = digit selected/enabled, 1 = digit disabled
//     seg[6:0]: 0 = segment illuminated,   1 = segment dark
//
// Enable Control:
//   When en == 1'b0:
//     All digits are blanked (an = 4'b1111, seg = 7'b111_1111).
//     Refresh counter and digit index are held at 0.
//
// Reset Behavior:
//   On rst_n == 1'b0:
//     All outputs are set to safe, disabled states:
//       an            = 4'b1111 (all digits dark)
//       seg           = 7'b111_1111 (all segments off)
//       current_digit = 2'b00
// ============================================================================

module seven_segment_mux #(
    parameter integer REFRESH_DIV = 100 // Clock cycles per active digit slot
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [15:0] digits,

    output reg  [6:0]  seg,
    output reg  [3:0]  an,
    output wire [1:0]  current_digit
);

    localparam integer CNT_WIDTH = (REFRESH_DIV > 1) ? $clog2(REFRESH_DIV) : 1;

    reg [CNT_WIDTH-1:0] refresh_cnt;
    reg [1:0]           digit_sel;

    assign current_digit = digit_sel;

    // Select the 4-bit nibble for the currently active digit
    reg [3:0] current_nibble;
    always @(*) begin
        case (digit_sel)
            2'b00:   current_nibble = digits[3:0];   // Digit 0 (rightmost)
            2'b01:   current_nibble = digits[7:4];   // Digit 1
            2'b10:   current_nibble = digits[11:8];  // Digit 2
            2'b11:   current_nibble = digits[15:12]; // Digit 3 (leftmost)
            default: current_nibble = 4'h0;
        endcase
    end

    // Instantiate 7-segment decoder
    wire [6:0] decoded_seg;
    seven_segment_decoder u_decoder (
        .hex_digit (current_nibble),
        .seg       (decoded_seg)
    );

    // Refresh counter and digit multiplexing sequencer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt <= {CNT_WIDTH{1'b0}};
            digit_sel   <= 2'b00;
            an          <= 4'b1111;
            seg         <= 7'b111_1111;
        end else if (!en) begin
            refresh_cnt <= {CNT_WIDTH{1'b0}};
            digit_sel   <= 2'b00;
            an          <= 4'b1111;
            seg         <= 7'b111_1111;
        end else begin
            // Active cycling
            if (refresh_cnt >= (REFRESH_DIV - 1)) begin
                refresh_cnt <= {CNT_WIDTH{1'b0}};
                digit_sel   <= digit_sel + 1'b1;
            end else begin
                refresh_cnt <= refresh_cnt + 1'b1;
            end

            // Drive outputs for current digit (Active-Low)
            case (digit_sel)
                2'b00:   an <= 4'b1110; // Digit 0
                2'b01:   an <= 4'b1101; // Digit 1
                2'b10:   an <= 4'b1011; // Digit 2
                2'b11:   an <= 4'b0111; // Digit 3
                default: an <= 4'b1111;
            endcase

            seg <= decoded_seg;
        end
    end

endmodule

`default_nettype wire
