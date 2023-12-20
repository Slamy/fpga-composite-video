`include "coefficients.svh"


module filter_pal_luma (
    input clk,
    input [7:0] in,
    output bit [7:0] out
);

    localparam int B0 = `PAL_LUMA_LOWPASS_B0;
    localparam int B1 = `PAL_LUMA_LOWPASS_B1;
    localparam int B2 = `PAL_LUMA_LOWPASS_B2;

    localparam int A1 = -(`PAL_LUMA_LOWPASS_A1);
    localparam int A2 = -(`PAL_LUMA_LOWPASS_A2);

    localparam int APrecision = `PAL_LUMA_LOWPASS_A_AFTER_DOT;
    localparam int BPrecision = `PAL_LUMA_LOWPASS_B_AFTER_DOT;

    bit signed [14:0] rz0_d;
    bit signed [14:0] rz1_d;
    bit signed [10:0] lz0_d;
    bit signed [10:0] lz1_d;

    bit signed [14:0] rz0_q = 0;
    bit signed [14:0] rz1_q = 0;
    bit signed [10:0] lz0_q = 0;
    bit signed [10:0] lz0_q2 = 0;
    bit signed [10:0] lz1_q = 0;

    bit [9:0] x;

    function automatic int reduce(input int value, input int shift);
        begin
            reduce = value >>> shift;
        end
    endfunction

    bit signed [14:0] v;
    bit signed [14:0] v_q;
    bit signed [10:0] y;

    bit signed [10:0] v0_mul_b0_d;
    bit signed [10:0] v0_mul_b0_q;

    always_comb begin
        v = rz0_q + 14'(x);
        rz0_d = 15'(reduce((A1 * v), APrecision)) + rz1_q;
        rz1_d = 15'(reduce((A2 * v), APrecision));

        v0_mul_b0_d = 11'(reduce(B0 * v_q, BPrecision));

        y = v0_mul_b0_q + lz0_q2;
        lz0_d = 11'(reduce((B1 * v_q), BPrecision)) + lz1_q;
        lz1_d = 11'(reduce((B2 * v_q), BPrecision));
    end

    always_ff @(posedge clk) begin
        x <= 10'(in) <<< 2;  // add 1 tick delay but keeps pathes short

        // just to be sure that the output is always positive
        if (y < 0) out <= 0;
        else out <= 8'((y + 11'd2) >>> 2);  // add 1 tick delay but keeps pathes short

        rz0_q <= rz0_d;
        rz1_q <= rz1_d;
        lz0_q <= lz0_d;
        lz1_q <= lz1_d;

        lz0_q2 <= lz0_q;
        v_q <= v;

        v0_mul_b0_q <= v0_mul_b0_d;
    end

endmodule
