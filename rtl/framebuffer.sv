module framebuffer (
    burst_bus_if.master bus,
    debug_bus_if.slave  dbus,

    input newframe,
    input newline,
    input even_field,
    input [8:0] video_y,
    input [12:0] video_x,

    output bit [7:0] luma,
    output bit signed [7:0] yuv_u,
    output bit signed [7:0] yuv_v
);

    wire clk = bus.clk;

    // Register Map ------
    bit [9:0] width = 256;
    bit [15:0] stride = 256 * 4;
    bit [8:0] height = 256;
    bit [5:0] clk_per_pixel = 9;
    bit [7:0] window_h_start = 8'(580 >> 2);
    bit [20:0] start_addr_even_field = 0;
    bit [20:0] start_addr_odd_field = 0;
    bit [6:0] windows_v_start = 30;
    bit debug_line_mode = 0;
    // Register Map ------

    bit [8:0] windows_v_start_9bit;

    always_comb begin
        windows_v_start_9bit = {2'b0, windows_v_start};
        // This here might be debatable. On the one hand, the even field is
        // the only one in non interlaced mode, so I would assume that it is
        // the "upper" frame. But this is not the case as the odd one is on
        // top. We move the odd field one line down to fix that.
        if (!even_field) windows_v_start_9bit = windows_v_start_9bit + 1;
    end

    always_ff @(posedge clk) begin
        if (dbus.addr[15:8] == 8'h03 && dbus.write_enable) begin
            case (dbus.addr[7:0])
                0:  width[9:8] <= dbus.write_data[1:0];
                1:  width[7:0] <= dbus.write_data;
                2:  height[8] <= dbus.write_data[0];
                3:  height[7:0] <= dbus.write_data;
                4:  clk_per_pixel <= dbus.write_data[5:0];
                5:  window_h_start <= dbus.write_data;
                6:  ;  // reserved for start_addr[31:24]
                7:  start_addr_even_field[20:16] <= dbus.write_data[4:0];
                8:  start_addr_even_field[15:8] <= dbus.write_data;
                9:  start_addr_even_field[7:0] <= dbus.write_data;
                10: ;  // reserved for start_addr[31:24]
                11: start_addr_odd_field[20:16] <= dbus.write_data[4:0];
                12: start_addr_odd_field[15:8] <= dbus.write_data;
                13: start_addr_odd_field[7:0] <= dbus.write_data;

                14: windows_v_start <= dbus.write_data[6:0];
                16: stride[15:8] <= dbus.write_data;
                17: stride[7:0] <= dbus.write_data;
                default: ;
            endcase
        end

        // TODO Move address space
        if (dbus.addr[15:8] == 8'h00 && dbus.write_enable) begin
            case (dbus.addr[7:0])
                6: begin
                    debug_line_mode <= dbus.write_data[2];
                end
                default: ;
            endcase
        end
    end

    bit [5:0] pixel_count = 0;
    bit [9:0] pixel_x = 0;

    bit [20:0] read_addr;
    bit [20:0] line_addr;

    bit [63:0] fifo[16];

    bit [63:0] fifo_read_word = 0;
    bit [4:0] fifo_read_pos = 0;
    bit [4:0] fifo_read_pos_q2 = 0;
    bit [3:0] fifo_write_pos = 0;

    wire [3:0] fifo_free_entries = 4'b1111 - fifo_write_pos + fifo_read_pos[4:1];

    bit [31:0] pixel_data;

    always_comb begin
        bus.addr = read_addr;
        bus.data_mask = 0;
        bus.cmd = 0;
        bus.cmd_en = 0;
        bus.wr_data = 0;

        luma = 0;
        yuv_u = 0;
        yuv_v = 0;

        case (fifo_read_pos_q2[0])
            1'b0: pixel_data = fifo_read_word[63:32];
            1'b1: pixel_data = fifo_read_word[31:0];
            default: ;
        endcase

        luma  = pixel_data[23:16];
        yuv_u = pixel_data[15:8];
        yuv_v = pixel_data[7:0];

        // Don't read during newline flag.
        // Address not yet at required value!
        if (fifo_free_entries >= 4 && !newline) bus.cmd_en = 1;
    end

    always_ff @(posedge clk) begin

        fifo_read_pos_q2 <= fifo_read_pos;

        if (newframe) begin
            if (even_field) line_addr <= start_addr_even_field;
            else line_addr <= start_addr_odd_field;

        end else if (newline && video_y >= windows_v_start_9bit &&
                        video_y < (windows_v_start_9bit + height)) begin
            // Restart reading process for a new line
            pixel_count <= 0;
            pixel_x <= 0;
            fifo_read_word <= 0;
            fifo_read_pos <= 0;
            fifo_write_pos <= 0;

            if (debug_line_mode) begin
                read_addr <= start_addr_even_field;
            end else begin
                read_addr <= line_addr;
                line_addr <= line_addr + {5'b0, stride};
            end

        end else begin
            if (pixel_x == width) begin
                fifo_read_word <= 0;
            end else begin
                if (pixel_count == clk_per_pixel - 1) begin
                    pixel_count <= 0;
                    pixel_x <= pixel_x + 1;
                    fifo_read_pos <= fifo_read_pos + 1;
                end else if (video_y >= windows_v_start_9bit &&
                        video_x >= {3'b0, window_h_start, 2'b0} &&
                        video_y < (windows_v_start_9bit + height)) begin
                    pixel_count <= pixel_count + 1;
                    fifo_read_word <= fifo[fifo_read_pos[4:1]];
                end
            end

            if (bus.rd_data_valid) begin
                fifo[fifo_write_pos] <= bus.rd_data;
                fifo_write_pos <= fifo_write_pos + 1;
                read_addr <= read_addr + 4;
            end
        end
    end
endmodule

