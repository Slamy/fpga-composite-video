`include "coefficients.svh"

/* 
 * Produces TV video timing and fitting sync signals.
 *
 * For PAL we have 625 lines in interlacing mode
 * Field 1 = Even Lines = 312 lines
 * Field 2 = Odd Lines = 313 lines
 * For non interlaced mode, it seems to be defined to use 312 lines.
 * Therefore we can implement non interlaced modes by just providing only even frames.
 */
module video_timing (
    input clk,
    input [8:0] v_total,
    input [8:0] v_active,
    input interlacing_enable,

    output bit sync,

    output bit newline,
    output bit newframe,
    output bit newpixel,

    output bit startburst,
    output bit [8:0] video_y,
    output bit [12:0] video_x,

    output bit visible_line,
    output visible_window,
    output bit even_field
);
    // Internal bits for the phase accumulator
    localparam int PixelPhaseAccu = 10;

    // We require one more bit for disabling the active window when
    // we heave reached pixel 256 which shall not be shown
    bit [PixelPhaseAccu-1:0] pixel_clock_accu = 0;
    bit [PixelPhaseAccu-1:0] pixel_counter_increment = 0;
    bit pixel_clock_accu_highest = 0;

    bit sync_d;

    // Length of certain timing constants in clocks
    localparam bit [12:0] LineLength = 13'(integer'(64 / `CLK_PERIOD_USEC));  // 64 usec
    localparam bit [12:0] HalfLineLength = LineLength / 2;  // 32 usec

    localparam bit [12:0] BackPorch = 13'(integer'(10 / `CLK_PERIOD_USEC));  // 10 usec
    localparam bit [12:0] FrontPorch = 13'(integer'(1.65 / `CLK_PERIOD_USEC));  // 1.65 usec

    localparam bit [12:0] NormalSync = 13'(integer'(4.7 / `CLK_PERIOD_USEC));  // 4.7 usec
    localparam bit [12:0] ShortSync = NormalSync / 2;
    localparam bit [12:0] LongSync = HalfLineLength - NormalSync;

    localparam bit [8:0] VisibleStartY = 38;

    localparam bit [12:0] BurstStart = 13'(integer'(5.6 / `CLK_PERIOD_USEC));  // 5.6 usec

    localparam bit [12:0] ActiveWindowStart = NormalSync + BackPorch;
    // TODO +4 is used here because the resolution of PixelPhaseAccu is too limited and
    // we want to have an equal width for all "pixels". Need to find a better solution.
    localparam bit [12:0] ActiveWindowStop = LineLength - 13'(integer'(5 / `CLK_PERIOD_USEC))+4;  // 64 usec

    initial begin
        // pixel_counter_increment * ticks_per_active_window must about reach a
        // pixel_x_internal value of having only the highest bit set
        automatic
        int
        ticks_per_active_window = integer'(ActiveWindowStop) - integer'(ActiveWindowStart);
        pixel_counter_increment = PixelPhaseAccu'((2 ** PixelPhaseAccu)*256 / ticks_per_active_window);
        even_field = 1;
    end

    always_ff @(posedge clk) begin
        if (video_x == (LineLength - 1)) begin  // end of line reached?
            video_x <= 0;
            pixel_clock_accu <= 0;

            if (even_field && video_y == (v_total - 1)) begin
                video_y <= 0;
                // Only change to odd field if interlacing mode is active
                if (interlacing_enable) even_field <= 0;
            end else if (!even_field && video_y == (v_total)) begin
                video_y <= 0;
                even_field <= 1;
            end else video_y <= video_y + 1;
        end else begin
            video_x <= video_x + 1;

            if (visible_window) pixel_clock_accu <= pixel_clock_accu + pixel_counter_increment;
        end

        sync <= sync_d;
        pixel_clock_accu_highest <= pixel_clock_accu[PixelPhaseAccu-1];
    end

    // Calculate sync signal and burst position

    bit first_half_long_sync;
    bit second_half_long_sync;
    bit timing_line;
    bit visible_window_q = 0;
    bit visible_window_d;
    always_ff @(posedge clk) begin
        newframe <= (video_y == 0 && video_x == 0);
        newline <= (video_x == 0);
        visible_window_q <= visible_window_d;
    end

    assign visible_window = visible_window_q;

    always_comb begin
        sync_d = 0;
        startburst = 0;
        visible_line = 0;
        visible_window_d = 0;
        newpixel = !pixel_clock_accu_highest && pixel_clock_accu[PixelPhaseAccu-1];

        first_half_long_sync = 0;
        second_half_long_sync = 0;
        timing_line = 0;

        timing_line = (video_y <= 4) || (video_y >= 310);

        if (even_field) begin
            // First field draws even lines
            first_half_long_sync  = (video_y == 0 || video_y == 1 || video_y == 2);
            second_half_long_sync = (video_y == 0 || video_y == 1);
        end else begin
            // Second field draws odd lines
            first_half_long_sync  = (video_y == 1 || video_y == 2);
            second_half_long_sync = (video_y == 0 || video_y == 1 || video_y == 2);
        end

        if (timing_line) begin
            if (first_half_long_sync && second_half_long_sync) begin
                // ______-______-
                if (video_x < LongSync) sync_d = 1;
                else if (video_x < HalfLineLength) sync_d = 0;
                else if (video_x < (HalfLineLength + LongSync)) sync_d = 1;
            end

            if (first_half_long_sync && !second_half_long_sync) begin
                // ______-_------ for first and second line in even fields
                if (video_x < LongSync) sync_d = 1;
                else if (video_x < HalfLineLength) sync_d = 0;
                else if (video_x < (HalfLineLength + ShortSync)) sync_d = 1;
            end

            if (!first_half_long_sync && second_half_long_sync) begin
                // _------______- used only for field 2 in the first line
                if (video_x < ShortSync) sync_d = 1;
                else if (video_x < HalfLineLength) sync_d = 0;
                else if (video_x < (HalfLineLength + LongSync)) sync_d = 1;
            end

            if (!first_half_long_sync && !second_half_long_sync) begin
                // _------_------
                if (video_x < ShortSync) sync_d = 1;
                else if (video_x < HalfLineLength) sync_d = 0;
                else if (video_x < (HalfLineLength + ShortSync)) sync_d = 1;
            end
        end else begin
            // 256 visible lines starting at line 38
            if (video_y >= VisibleStartY && video_y < (VisibleStartY + v_active)) begin
                visible_line = 1;
                if (video_x >= ActiveWindowStart && video_x <= ActiveWindowStop)
                    visible_window_d = 1;
            end
            if (video_x < NormalSync) sync_d = 1;
            if (video_x == BurstStart && video_y > 7) startburst = 1;
        end
    end


`ifdef VERILATOR
    int field_line_number;
    // verilator lint_off WIDTHEXPAND
    always_comb begin
        field_line_number = video_y + 1 + (!even_field ? 312 : 0);
    end
    // verilator lint_on WIDTHEXPAND
`endif

endmodule
