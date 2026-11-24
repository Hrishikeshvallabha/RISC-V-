`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Module: seven_segment_decoder
// Description:
//   Purely synthesizable hexadecimal 7-segment decoder.
//   Converts 4-bit hexadecimal values (0x0 to 0xF) into 7-segment drive pattern.
//
// Hardware Model & Polarity:
//   Common-Anode representation (Active-Low):
//     0 = Segment ON (illuminated)
//     1 = Segment OFF (dark)
//
// Segment Bit Mapping:
//   seg[6:0] = {a, b, c, d, e, f, g}
//   seg[6] = a (top)
//   seg[5] = b (top-right)
//   seg[4] = c (bottom-right)
//   seg[3] = d (bottom)
//   seg[2] = e (bottom-left)
//   seg[1] = f (top-left)
//   seg[0] = g (middle)
//
// Truth Table (Active-Low):
//   Digit | a b c d e f g | seg[6:0] Binary | seg[6:0] Hex
//   ------+---------------+-----------------+-------------
//     0   | 0 0 0 0 0 0 1 |    7'b000_0001  |    7'h01
//     1   | 1 0 0 1 1 1 1 |    7'b100_1111  |    7'h4F
//     2   | 0 0 1 0 0 1 0 |    7'b001_0010  |    7'h12
//     3   | 0 0 0 0 1 1 0 |    7'b000_0110  |    7'h06
//     4   | 1 0 0 1 1 0 0 |    7'b100_1100  |    7'h4C
//     5   | 0 1 0 0 1 0 0 |    7'b010_0100  |    7'h24
//     6   | 0 1 0 0 0 0 0 |    7'b010_0000  |    7'h20
//     7   | 0 0 0 1 1 1 1 |    7'b000_1111  |    7'h0F
//     8   | 0 0 0 0 0 0 0 |    7'b000_0000  |    7'h00
//     9   | 0 0 0 0 1 0 0 |    7'b000_0100  |    7'h04
//     A   | 0 0 0 1 0 0 0 |    7'b000_1000  |    7'h08
//     B   | 1 1 0 0 0 0 0 |    7'b110_0000  |    7'h60
//     C   | 0 1 1 0 0 0 1 |    7'b011_0001  |    7'h31
//     D   | 1 0 0 0 0 1 0 |    7'b100_0010  |    7'h42
//     E   | 0 1 1 0 0 0 0 |    7'b011_0000  |    7'h30
//     F   | 0 1 1 1 0 0 0 |    7'b011_1000  |    7'h38
//   blank | 1 1 1 1 1 1 1 |    7'b111_1111  |    7'h7F
// ============================================================================

module seven_segment_decoder (
    input  wire [3:0] hex_digit,
    output reg  [6:0] seg
);

    always @(*) begin
        case (hex_digit)
            4'h0: seg = 7'b000_0001; // 0
            4'h1: seg = 7'b100_1111; // 1
            4'h2: seg = 7'b001_0010; // 2
            4'h3: seg = 7'b000_0110; // 3
            4'h4: seg = 7'b100_1100; // 4
            4'h5: seg = 7'b010_0100; // 5
            4'h6: seg = 7'b010_0000; // 6
            4'h7: seg = 7'b000_1111; // 7
            4'h8: seg = 7'b000_0000; // 8
            4'h9: seg = 7'b000_0100; // 9
            4'hA: seg = 7'b000_1000; // A
            4'hB: seg = 7'b110_0000; // b
            4'hC: seg = 7'b011_0001; // C
            4'hD: seg = 7'b100_0010; // d
            4'hE: seg = 7'b011_0000; // E
            4'hF: seg = 7'b011_1000; // F
            default: seg = 7'b111_1111; // All OFF
        endcase
    end

endmodule

`default_nettype wire
