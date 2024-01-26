`include "common.svh"
import common::*;
/*
 * Generates 4 color bars according to the EBU standard.
 * It expected 256 pixels per scanline equally clocked using newpixel.
 */

module rgbbars (
    input clk,
    input newline,
    input newpixel,

    input [7:0] video_y,

    input bit visible_window,
    output ycbcr_t out
);

    bit [7:0] R_d;
    bit [7:0] G_d;
    bit [7:0] B_d;
    bit [7:0] R_q;
    bit [7:0] G_q;
    bit [7:0] B_q;

    rgb_t rgb_conv_in;
    assign rgb_conv_in.r = R_q;
    assign rgb_conv_in.g = G_q;
    assign rgb_conv_in.b = B_q;


    RGB2YCbCr rgb_conv (
        .clk,
        .in (rgb_conv_in),
        .out(out)
    );

    bit  [8:0] pixel_x = 0;
    bit  [2:0] rgb;
    bit  [2:0] index;
    wire [7:0] strength = video_y[6] ? 255 : 191;  // 100% and 75%

    always_ff @(posedge clk) begin
        if (newline) pixel_x <= 0;
        if (visible_window && newpixel) pixel_x <= pixel_x + 1;

        R_q <= R_d;
        G_q <= G_d;
        B_q <= B_d;
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

        R_d = rgb[2] ? strength : 0;
        G_d = rgb[1] ? strength : 0;
        B_d = rgb[0] ? strength : 0;
    end
endmodule
