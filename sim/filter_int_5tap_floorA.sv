`include "coefficients.svh"

module filter_int_5tap_floorA (
    input clk,
    input int in,
    output int out,

    input int b0,
    input int b1,
    input int b2,
    input int b3,
    input int b4,

    input int a1,
    input int a2,
    input int a3,
    input int a4,

    input int a_precision,
    input int b_precision
);

    localparam TAPS = 5;

    int rz[0:TAPS-1];
    int lz[0:TAPS-1];

    int x;
    function automatic int reduce(input int value, input int shift);
        begin
            reduce = (value + (1 <<< (shift - 1))) >>> shift;
        end
    endfunction

    function automatic int reduce2(input int value, input int shift);
        begin
            reduce2 = value >>> shift;
        end
    endfunction


    int v;
    int y;

    int rz_next[0:TAPS-1];
    int lz_next[0:TAPS-1];

    always_comb begin
        v = rz[0] + x;
        y = lz[0] + reduce(b0 * v, b_precision);

        rz_next[0] = reduce2((-a1 * v), a_precision) + rz[1];
        rz_next[1] = reduce2((-a2 * v), a_precision) + rz[2];
        rz_next[2] = reduce2((-a3 * v), a_precision) + rz[3];
        rz_next[3] = reduce2((-a4 * v), a_precision);

        lz_next[0] = reduce((b1 * v), b_precision) + lz[1];
        lz_next[1] = reduce((b2 * v), b_precision) + lz[2];
        lz_next[2] = reduce((b3 * v), b_precision) + lz[3];
        lz_next[3] = reduce((b4 * v), b_precision);
    end

    int i;

    initial begin
        for (i = 0; i < TAPS; i++) begin
            rz[i] = 0;
            lz[i] = 0;
        end
    end

    always_ff @(posedge clk) begin
        x   <= in;  // add 1 tick delay but keeps pathes short
        out <= y;  // add 1 tick delay but keeps pathes short

        for (i = 0; i < TAPS; i++) begin
            // Right side of Transposed-Direct-Form-I which is the feedback path
            rz[i] <= rz_next[i];  // result is .0 after sum
            // Left side of  Transposed-Direct-Form-I which does the forward path
            lz[i] <= lz_next[i];  // result is .A_AFTER_DOT to keep precision

        end
    end

endmodule
