module ebu75 (
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

    bit [7:0] pixel_x = 0;

    always_ff @(posedge clk) begin
        if (newline) pixel_x <= 0;
        if (visible_window && newpixel) pixel_x <= pixel_x + 1;
    end

    always_comb begin
        luma  = 0;
        yuv_u = 0;
        yuv_v = 0;

        if (visible_window) begin
            case (pixel_x[7:7-2])
                3'd0: begin
                    luma  = 255;
                    yuv_u = 0;
                    yuv_v = 0;
                end
                3'd1: begin
                    luma  = 168;
                    yuv_u = -41;
                    yuv_v = 9;
                end
                3'd2: begin
                    luma  = 133;
                    yuv_u = 14;
                    yuv_v = -58;
                end
                3'd3: begin
                    luma  = 112;
                    yuv_u = -27;
                    yuv_v = -49;
                end
                3'd4: begin
                    luma  = 76;
                    yuv_u = 27;
                    yuv_v = 49;
                end
                3'd5: begin
                    luma  = 56;
                    yuv_u = -14;
                    yuv_v = 58;
                end
                3'd6: begin
                    luma  = 20;
                    yuv_u = 41;
                    yuv_v = -9;
                end
                3'd7: begin
                    luma  = 0;
                    yuv_u = 0;
                    yuv_v = 0;
                end
                default: ;
            endcase

        end
    end

endmodule
