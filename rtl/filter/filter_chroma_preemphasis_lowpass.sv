`include "coefficients.svh"

module filter_chroma_preemphasis_lowpass (
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
    localparam int B0 = `SECAM_PREEMPHASIS_B0;
    localparam int B1 = `SECAM_PREEMPHASIS_B1;
    localparam int A1 = -(`SECAM_PREEMPHASIS_A1);

    localparam int APrecision = `SECAM_PREEMPHASIS_A_AFTER_DOT;
    localparam int BPrecision = `SECAM_PREEMPHASIS_B_AFTER_DOT;

    bit signed [10:0] rz0_d;
    bit signed [ 8:0] lz0_d;

    bit signed [10:0] rz0_q = 0;
    bit signed [ 8:0] lz0_q = 0;
    bit signed [ 8:0] lz0_q2 = 0;

    bit signed [ 8:0] x;

    function automatic int reduce(input int value, input int shift);
        begin
            reduce = (value + (1 <<< (shift - 1))) >>> shift;
        end
    endfunction

    bit signed [10:0] v;
    bit signed [10:0] v_q;
    bit signed [ 8:0] y;

    bit signed [ 8:0] v0_mul_b0_d;
    bit signed [ 8:0] v0_mul_b0_q;

    always_comb begin
        v = rz0_q + 10'(x);
        rz0_d = 11'(reduce((A1 * v), APrecision));

        v0_mul_b0_d = 9'(reduce(B0 * v_q, BPrecision));

        y = v0_mul_b0_q + lz0_q2;
        lz0_d = 9'(reduce((B1 * v_q), BPrecision));
    end

    always_ff @(posedge clk) begin
        x <= in;  // add 1 tick delay but keeps pathes short
        out <= 9'(y);  // add 1 tick delay but keeps pathes short

        rz0_q <= rz0_d;
        lz0_q <= lz0_d;

        lz0_q2 <= lz0_q;
        v_q <= v;

        v0_mul_b0_q <= v0_mul_b0_d;
    end

endmodule