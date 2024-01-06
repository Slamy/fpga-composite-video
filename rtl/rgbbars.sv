module rgbbars (
    input clk,
    input newline,
    input newpixel,

    input [ 8:0] video_y,
    input [12:0] video_x,

    input bit visible_line,
    input bit visible_window,

    output bit [7:0] luma,
    output bit signed [7:0] yuv_u,
    output bit signed [7:0] yuv_v
);

    bit [7:0] R;
    bit [7:0] G;
    bit [7:0] B;

    bit [7:0] rgbconv_Y;
    bit signed [7:0] rgbconv_Cb;
    bit signed [7:0] rgbconv_Cr;

    RGB2YCbCr rgb_conv (
        .clk,
        .R,
        .G,
        .B,
        .Y (rgbconv_Y),
        .Cb(rgbconv_Cb),
        .Cr(rgbconv_Cr)
    );

    bit  [8:0] pixel_x = 0;
    bit  [2:0] rgb;
    bit  [2:0] index;
    wire [7:0] strength = video_y[6] ? 255 : 191;  // 100% and 75%

    always_ff @(posedge clk) begin
        if (newline) pixel_x <= 0;
        if (visible_window && newpixel) pixel_x <= pixel_x + 1;

        luma  <= rgbconv_Y;
        yuv_u <= rgbconv_Cb;
        yuv_v <= rgbconv_Cr;
    end

    always_comb begin
        rgb   = 0;
        index = pixel_x[7:7-2];

        // reverse order
        if (video_y[7]) index = 7 - index;

        if (visible_window && !pixel_x[8]) begin
            case (index)
                3'd0: rgb = 3'b111;
                3'd1: rgb = 3'b110;
                3'd2: rgb = 3'b011;
                3'd3: rgb = 3'b010;
                3'd4: rgb = 3'b101;
                3'd5: rgb = 3'b100;
                3'd6: rgb = 3'b001;
                3'd7: rgb = 3'b000;
                default: ;
            endcase
        end

        R = rgb[2] ? strength : 0;
        G = rgb[1] ? strength : 0;
        B = rgb[0] ? strength : 0;
    end
endmodule
