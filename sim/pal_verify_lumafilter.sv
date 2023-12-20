module pal_verify_lumafilter (
    input clk,
    input int in,
    output int out
);

    localparam int b0 = `PAL_LUMA_LOWPASS_B0;
    localparam int b1 = `PAL_LUMA_LOWPASS_B1;
    localparam int b2 = `PAL_LUMA_LOWPASS_B2;

    localparam int a1 = -(`PAL_LUMA_LOWPASS_A1);
    localparam int a2 = -(`PAL_LUMA_LOWPASS_A2);

    localparam int a_precision = `PAL_LUMA_LOWPASS_A_AFTER_DOT;
    localparam int b_precision = `PAL_LUMA_LOWPASS_B_AFTER_DOT;

    int rz0_d;
    int rz1_d;
    int lz0_d;
    int lz1_d;

    int rz0_q = 0;
    int rz1_q = 0;
    int lz0_q = 0;
    int lz0_q2 = 0;
    int lz1_q = 0;

    int x;

    function automatic int reduce(input int value, input int shift);
        begin
            reduce = value >>> shift;
        end
    endfunction

    int v;
    int v_q;
    int y;

    int v0_mul_b0_d;
    int v0_mul_b0_q;

    always_comb begin
        v = rz0_q + x;
        rz0_d = reduce((a1 * v), a_precision) + rz1_q;
        rz1_d = reduce((a2 * v), a_precision);

        v0_mul_b0_d = reduce(b0 * v_q, b_precision);

        y = v0_mul_b0_q + lz0_q2;
        lz0_d = reduce((b1 * v_q), b_precision) + lz1_q;
        lz1_d = reduce((b2 * v_q), b_precision);
    end

    always_ff @(posedge clk) begin
        x <= in <<< 2;  // add 1 tick delay but keeps pathes short

        // just to be sure that the output is always positive
        if (y < 0) out <= 0;
        else out <= (y + 2) >>> 2;  // add 1 tick delay but keeps pathes short

        rz0_q <= rz0_d;
        rz1_q <= rz1_d;
        lz0_q <= lz0_d;
        lz1_q <= lz1_d;

        lz0_q2 <= lz0_q;
        v_q <= v;

        v0_mul_b0_q <= v0_mul_b0_d;
    end

endmodule
