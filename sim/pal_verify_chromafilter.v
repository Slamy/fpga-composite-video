// Implements IIR filter
// Used https://ccrma.stanford.edu/~jos/fp/Transposed_Direct_Forms.html
// for inspiration. The advantage of this approach is not having
// two multiplications on one signal path between registers

module pal_verify_chromafilter (
    input clk,
    input signed [7:0] in,
    output reg signed [7:0] out
);

    parameter BIT_WIDTH = 31;

    localparam b_after_dot = `PAL_CHROMA_B_AFTER_DOT;
    localparam a_after_dot = `PAL_CHROMA_A_AFTER_DOT;
    localparam b_to_a_diff_after_dot = `PAL_CHROMA_B_TO_A_DIFF_AFTER_DOT;

    localparam signed [BIT_WIDTH:0] b0 = `PAL_CHROMA_B0;  //.CHROMA_B_AFTER_DOT
    localparam signed [BIT_WIDTH:0] b1 = `PAL_CHROMA_B1;  //.CHROMA_B_AFTER_DOT
    localparam signed [BIT_WIDTH:0] b2 = `PAL_CHROMA_B2;  //.CHROMA_B_AFTER_DOT
    localparam signed [BIT_WIDTH:0] b3 = `PAL_CHROMA_B3;  //.CHROMA_B_AFTER_DOT
    localparam signed [BIT_WIDTH:0] b4 = `PAL_CHROMA_B4;  //.CHROMA_B_AFTER_DOT

    localparam signed [BIT_WIDTH:0] a1 = `PAL_CHROMA_A1;  //.CHROMA_A_AFTER_DOT
    localparam signed [BIT_WIDTH:0] a2 = `PAL_CHROMA_A2;  //.CHROMA_A_AFTER_DOT
    localparam signed [BIT_WIDTH:0] a3 = `PAL_CHROMA_A3;  //.CHROMA_A_AFTER_DOT
    localparam signed [BIT_WIDTH:0] a4 = `PAL_CHROMA_A4;  //.CHROMA_A_AFTER_DOT

    reg signed [BIT_WIDTH:0] rz[0:3];  //.0
    reg signed [BIT_WIDTH:0] lz[0:3];  //.0

    reg signed [7:0] x;  //.0

    wire signed [BIT_WIDTH:0] v = rz[0] + BIT_WIDTH'(x);  //.0
    wire signed [7:0] y = 8'((lz[0] + ((b0 * v) >>> b_to_a_diff_after_dot)) >> a_after_dot);  //.0

    always @(posedge clk) begin
        x <= in;  // add 1 tick delay but keeps pathes short
        out <= y;  // add 1 tick delay but keeps pathes short

        // Right side of Transposed-Direct-Form-I which is the feedback path
        rz[0] <= ((-a1 * v) >>> a_after_dot) + rz[1];  // result is .0 after sum
        rz[1] <= ((-a2 * v) >>> a_after_dot) + rz[2];  // result is .0
        rz[2] <= ((-a3 * v) >>> a_after_dot) + rz[3];  // result is .0
        rz[3] <= ((-a4 * v) >>> a_after_dot);  // result is .0

        // Left side of  Transposed-Direct-Form-I which does the forward path
        lz[0] <= ((b1 * v) >>> b_to_a_diff_after_dot) + lz[1]; // result is .CHROMA_A_AFTER_DOT to keep precision
        lz[1] <= ((b2 * v) >>> b_to_a_diff_after_dot) + lz[2]; // result is .CHROMA_A_AFTER_DOT to keep precision
        lz[2] <= ((b3 * v) >>> b_to_a_diff_after_dot) + lz[3]; // result is .CHROMA_A_AFTER_DOT to keep precision
        lz[3] <= ((b4 * v) >>> b_to_a_diff_after_dot);  // result is .CHROMA_A_AFTER_DOT to keep precision
    end

endmodule
