`include "coefficients.svh"

module filter_secam_chroma_lowpass (
    input clk,
    input signed [8:0] in,
    output bit signed [8:0] out
);
    /* TODO for GOWIN support
     * Something here is wrong. Coefficients A are applied inverted
     * compared to the B coefficients.
     * Previously it was like this
     *   rz0_d = 11'(reduce((-a1 * v), a_precision)) + rz1_q;
     * but now it is like this
     *   rz0_d = 11'(reduce((a1 * v), a_precision)) + rz1_q;
     * and the coefficient is instead inverted here at the top.
     */
    localparam int B0 = `SECAM_CHROMA_LOWPASS_B0;
    localparam int B1 = `SECAM_CHROMA_LOWPASS_B1;
    localparam int A1 = -(`SECAM_CHROMA_LOWPASS_A1);

    localparam int APrecision = `SECAM_CHROMA_LOWPASS_A_AFTER_DOT;
    localparam int BPrecision = `SECAM_CHROMA_LOWPASS_B_AFTER_DOT;

    bit signed [9:0] rz0_d;
    bit signed [9:0] lz0_d;

    bit signed [9:0] rz0_q = 0;
    bit signed [9:0] lz0_q = 0;
    bit signed [9:0] lz0_q2 = 0;

    bit signed [9:0] x;

    function automatic int reduce(input int value, input int shift);
        begin
            reduce = (value + (1 <<< (shift - 1))) >>> shift;
        end
    endfunction

    bit signed [9:0] v;
    bit signed [9:0] v_q;
    bit signed [9:0] y;

    bit signed [9:0] v0_mul_b0_d;
    bit signed [9:0] v0_mul_b0_q;

    always_comb begin
        v = rz0_q + x;
        rz0_d = 10'(reduce((A1 * v), APrecision));

        v0_mul_b0_d = 10'(reduce(B0 * v_q, BPrecision));

        y = v0_mul_b0_q + lz0_q2;
        lz0_d = 10'(reduce((B1 * v_q), BPrecision));
    end

    always_ff @(posedge clk) begin
        x <= 10'(in) <<< 1;  // add 1 tick delay but keeps pathes short
        out <= 9'(y >>> 1);  // add 1 tick delay but keeps pathes short

        rz0_q <= rz0_d;
        lz0_q <= lz0_d;

        lz0_q2 <= lz0_q;
        v_q <= v;

        v0_mul_b0_q <= v0_mul_b0_d;
    end

endmodule
