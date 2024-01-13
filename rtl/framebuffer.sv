/*
 * Framebuffer device which grabs pixel data using a burst based memory interface
 * and provides it synchronized to the incoming frame timing.
 */
module framebuffer (
    burst_bus_if.master bus,
    debug_bus_if.slave  dbus, // debug bus slave for register access

    input        newframe,    // flag to indicate the start of a frame
    input        newline,     // flag to indicate the start of a scanline
    input        even_field,  // latched on newframe flag. selects one of two framebuffer pointers
    input [ 8:0] video_y,     // Scanline number
    input [12:0] video_x,     // Clock ticks since start of line

    output ycbcr_s out  // digital video output as YCbCr
);
    wire clk = bus.clk;

    localparam bit [7:0] RegisterHighAddr = 8'h03;
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
    bit rgb_mode = 0;
    // Register Map ------

    // scanline on which the visible image data starts
    // but adapted to the current field in interlacing mode
    bit [8:0] windows_v_start_9bit_d;
    bit [8:0] windows_v_start_9bit_q;

    always_comb begin
        windows_v_start_9bit_d = {2'b0, windows_v_start};
        // This here might be debatable. On the one hand, the even field is
        // the only one in non interlaced mode, so I would assume that it is
        // the "upper" frame. But this is not the case as the odd one is on
        // top. We move the odd field one line down to fix that.
        if (!even_field) windows_v_start_9bit_d = windows_v_start_9bit_d + 1;
    end

    always_ff @(posedge clk) begin
        windows_v_start_9bit_q <= windows_v_start_9bit_d;

        if (dbus.addr[15:8] == RegisterHighAddr && dbus.write_enable) begin
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
                    rgb_mode <= dbus.write_data[6];
                end
                default: ;
            endcase
        end
    end

    bit [5:0] pixel_count = 0;
    bit [9:0] pixel_x = 0;

    bit [20:0] read_addr;  // address presented to the memory controller
    bit [20:0] line_addr;  // address of first pixel of next line

    bit [63:0] fifo[16];  // queue of pixel data

    bit [63:0] fifo_read_word = 0;  // output buffer of queue
    bit [4:0] fifo_read_pos = 0;  // next index of queue to read from
    bit [4:0] fifo_read_pos_q = 0;  // current index of queue
    bit [3:0] fifo_write_pos = 0;  // next writing index

    wire [3:0] fifo_free_entries = 4'b1111 - fifo_write_pos + fifo_read_pos[4:1];

    bit [31:0] pixel_data;  // data of current pixel to output

    ycbcr_s rgb_conv_out;
    rgb_s rgb_conv_in;
    RGB2YCbCr rgb_conv (
        .clk,
        .in (rgb_conv_in),
        .out(rgb_conv_out)
    );

    always_comb begin
        bus.addr = read_addr;
        bus.data_mask = 0;
        bus.cmd = 0;
        bus.cmd_en = 0;
        bus.wr_data = 0;

        case (fifo_read_pos_q[0])
            1'b0: pixel_data = fifo_read_word[63:32];
            1'b1: pixel_data = fifo_read_word[31:0];
            default: ;
        endcase

        // Select pixel format
        if (rgb_mode) begin
            out = rgb_conv_out;
        end else begin
            out.y  = pixel_data[23:16];
            out.cb = pixel_data[15:8];
            out.cr = pixel_data[7:0];
        end

        // Don't read during active newline flag.
        // Address is currently calculated and available on next clock
        if (fifo_free_entries >= 4 && !newline) bus.cmd_en = 1;
    end

    // flag to prepare the fifo for the current line
    // and start reading pixel data
    bit restart_line = 0;

    always_ff @(posedge clk) begin
        rgb_conv_in.r <= pixel_data[23:16];
        rgb_conv_in.g <= pixel_data[15:8];
        rgb_conv_in.b <= pixel_data[7:0];

        restart_line <= newline && video_y >= windows_v_start_9bit_q &&
                        video_y < (windows_v_start_9bit_q + height);
    end

    always_ff @(posedge clk) begin
        fifo_read_pos_q <= fifo_read_pos;

        if (newframe) begin
            // A new frame has begun. Restart the readout from one of two
            // framebuffer pointers for proper interlaced output.
            if (even_field) line_addr <= start_addr_even_field;
            else line_addr <= start_addr_odd_field;

        end else if (restart_line) begin
            // Restart reading process for a new line
            pixel_count <= 0;
            pixel_x <= 0;
            fifo_read_word <= 0;
            fifo_read_pos <= 0;
            fifo_write_pos <= 0;

            if (debug_line_mode) begin
                // If the line mode is active,
                // we want to start from the same address 
                read_addr <= start_addr_even_field;
            end else begin
                // Otherwise add the stride to proceed to the next lines location
                read_addr <= line_addr;
                line_addr <= line_addr + {5'b0, stride};
            end

        end else begin
            if (pixel_x == width) begin
                // Last pixel reached? Deactivate output. Set to black.
                fifo_read_word <= 0;
            end else if (pixel_count == clk_per_pixel - 1) begin
                // Last clock of current pixel reached? Advance
                // position in FIFO
                pixel_count <= 0;
                pixel_x <= pixel_x + 1;
                fifo_read_pos <= fifo_read_pos + 1;
            end else if (video_y >= windows_v_start_9bit_q &&
                        video_x >= {3'b0, window_h_start, 2'b0} &&
                        video_y < (windows_v_start_9bit_q + height)) begin
                // Read the current value and keep waiting
                pixel_count <= pixel_count + 1;
                fifo_read_word <= fifo[fifo_read_pos[4:1]];
            end

            if (bus.rd_data_valid) begin
                // Data received from memory controller? Store it in the FIFO!
                fifo[fifo_write_pos] <= bus.rd_data;
                fifo_write_pos <= fifo_write_pos + 1;
                read_addr <= read_addr + 4;
            end
        end
    end
endmodule

