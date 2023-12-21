// from https://sistenix.com/rgb2ycbcr.html
// slighly modified as the source has worked with unsigned bytes and positioned
// the neutral value of Cb and Cr on 128. I wanted to use signed bytes here.
// Therefore -128 was added at the end.

module RGB2YCbCr (
    input clk,
    input [7:0] R,
    input [7:0] G,
    input [7:0] B,
    output bit [7:0] Y,
    output bit signed [7:0] Cb,
    output bit signed [7:0] Cr
);
    bit [7:0] Cr_temp;
    bit [7:0] Cb_temp;

    assign Cb = Cb_temp - 128;
    assign Cr = Cr_temp - 128;

    always_ff @(posedge clk) begin
        Y <= 16 + (((R << 6) + (R << 1) + (G << 7) + G + (B << 4) + (B << 3) + B) >> 8);
        Cb_temp <= 128 + ((-((R<<5)+(R<<2)+(R<<1))-((G<<6)+(G<<3)+(G<<1))+(B<<7)-(B<<4))>>8);
        Cr_temp <= 128 + (((R<<7)-(R<<4)-((G<<6)+(G<<5)-(G<<1))-((B<<4)+(B<<1)))>>8);
    end
endmodule : RGB2YCbCr
