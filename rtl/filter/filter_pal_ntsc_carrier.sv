`include "coefficients.svh"


module filter_pal_ntsc_carrier (
    input clk,
    input signed [7:0] in,
    input pal_mode,
    output bit signed [7:0] out
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
    localparam int PalB0 = `PAL_CHROMA_B0;
    localparam int PalB1 = `PAL_CHROMA_B1;
    localparam int PalB2 = `PAL_CHROMA_B2;
    localparam int PalA1 = -(`PAL_CHROMA_A1);
    localparam int PalA2 = -(`PAL_CHROMA_A2);

    localparam int NtscB0 = `NTSC_CHROMA_B0;
    localparam int NtscB1 = `NTSC_CHROMA_B1;
    localparam int NtscB2 = `NTSC_CHROMA_B2;
    localparam int NtscA1 = -(`NTSC_CHROMA_A1);
    localparam int NtscA2 = -(`NTSC_CHROMA_A2);

    int b0;
    int b1;
    int b2;
    int a1;
    int a2;

    always_comb begin
        if (pal_mode) begin
            b0 = PalB0;
            b1 = PalB1;
            b2 = PalB2;
            a1 = PalA1;
            a2 = PalA2;
        end else begin
            b0 = NtscB0;
            b1 = NtscB1;
            b2 = NtscB2;
            a1 = NtscA1;
            a2 = NtscA2;
        end

    end

    localparam int APrecision = `PAL_CHROMA_A_AFTER_DOT;
    localparam int BPrecision = `PAL_CHROMA_B_AFTER_DOT;

    bit signed [10:0] rz0_d;
    bit signed [10:0] rz1_d;
    bit signed [ 7:0] lz0_d;
    bit signed [ 7:0] lz1_d;

    bit signed [10:0] rz0_q = 0;
    bit signed [10:0] rz1_q = 0;
    bit signed [ 7:0] lz0_q = 0;
    bit signed [ 7:0] lz0_q2 = 0;
    bit signed [ 7:0] lz1_q = 0;

    bit signed [ 7:0] x;

    function automatic int reduce(input int value, input int shift);
        begin
            reduce = (value + (1 <<< (shift - 1))) >>> shift;
        end
    endfunction

    bit signed [10:0] v;
    bit signed [ 8:0] y;

    bit signed [ 8:0] v0_mul_b0_d;
    bit signed [ 8:0] v0_mul_b0_q;

    always_comb begin
        v = rz0_q + 11'(x);
        rz0_d = 11'(reduce((a1 * v), APrecision)) + rz1_q;
        rz1_d = 11'(reduce((a2 * v), APrecision));

        v0_mul_b0_d = 9'(reduce(b0 * v, BPrecision));

        y = v0_mul_b0_q + lz0_q2;
        lz0_d = 8'(reduce((b1 * v), BPrecision)) + lz1_q;
        lz1_d = 8'(reduce((b2 * v), BPrecision));
    end

    always_ff @(posedge clk) begin
        x <= in;  // add 1 tick delay but keeps pathes short
        out <= 8'(y);  // add 1 tick delay but keeps pathes short

        rz0_q <= rz0_d;
        rz1_q <= rz1_d;
        lz0_q <= lz0_d;
        lz1_q <= lz1_d;

        lz0_q2 <= lz0_q;

        v0_mul_b0_q <= v0_mul_b0_d;

    end

endmodule
