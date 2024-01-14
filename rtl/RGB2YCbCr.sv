import common::*;

/*
 * Converts RGB values into YCbCr
 */
module RGB2YCbCr (
    input clk,
    input rgb_t in,
    output ycbcr_t out
)  /* synthesis syn_dspstyle = "logic" */;

    bit [7:0] Y_temp1;
    bit [7:0] Y_temp2;
    bit [7:0] Y_temp3;

    bit signed [7:0] Cb_temp1;
    bit signed [7:0] Cb_temp2;
    bit signed [7:0] Cb_temp3;

    bit signed [7:0] Cr_temp1;
    bit signed [7:0] Cr_temp2;
    bit signed [7:0] Cr_temp3;
    always_ff @(posedge clk) begin

        // Translation matrix from https://en.wikipedia.org/wiki/YCbCr
        // Approximate 8-bit matrices for BT.601 as full swing
        Y_temp1 <= (77 * in.r) >> 8;
        Y_temp2 <= (150 * in.g) >> 8;
        Y_temp3 <= (29 * in.b) >> 8;

        Cb_temp1 <= (43 * in.r) >> 8;
        Cb_temp2 <= (84 * in.g) >> 8;

        // The GowinSynthesis tool is not very smart as it seems
        // 127 * B was replaced by 128 * B - B for optimization.
        // This replaces 6 numbers to add together with only 2.
        Cb_temp3 <= (128 * in.b - in.b) >> 8;

        Cr_temp1 <= (128 * in.r - in.r) >> 8;
        Cr_temp2 <= (106 * in.g) >> 8;
        Cr_temp3 <= (21 * in.b) >> 8;

        out.y <= Y_temp1 + Y_temp2 + Y_temp3;
        out.cb <= -Cb_temp1 - Cb_temp2 + Cb_temp3;
        out.cr <= Cr_temp1 - Cr_temp2 - Cr_temp3;
    end
endmodule : RGB2YCbCr
