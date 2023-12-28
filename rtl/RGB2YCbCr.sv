// Translation matrix from https://en.wikipedia.org/wiki/YCbCr
// Approximate 8-bit matrices for BT.601 as full swing
module RGB2YCbCr (
    input clk,
    input [7:0] R,
    input [7:0] G,
    input [7:0] B,
    output bit [7:0] Y,
    output bit signed [7:0] Cb,
    output bit signed [7:0] Cr
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

        Y_temp1 <= (77 * R) >> 8;
        Y_temp2 <= (150 * G) >> 8;
        Y_temp3 <= (29 * B) >> 8;

        Cb_temp1 <= (43 * R) >> 8;
        Cb_temp2 <= (84 * G) >> 8;

        // The GowinSynthesis tool is not very smart as it seems
        // 127 * B was replaced by 128 * B - B for optimization.
        // This replaces 6 numbers to add together with only 2.
        Cb_temp3 <= (128 * B - B) >> 8;

        Cr_temp1 <= (128 * R - R) >> 8;
        Cr_temp2 <= (106 * G) >> 8;
        Cr_temp3 <= (21 * B) >> 8;

        Y <= Y_temp1 + Y_temp2 + Y_temp3;
        Cb <= -Cb_temp1 - Cb_temp2 + Cb_temp3;
        Cr <= Cr_temp1 - Cr_temp2 - Cr_temp3;
    end
endmodule : RGB2YCbCr
