`include "configuration.svh"
`include "common.svh"
`include "coefficients.svh"

import common::*;

/*
 * Composite Video Baseband Signal Encoder
 * Produces PAL, NTSC and SECAM encoded analog video.
 */
module composite_video_encoder (
    input                           clk,             // Clock signal as configured in python script
    input                           sync,            // Analog vidoe sync signal
    input                           newframe,        // Flag which marks start of frame
    input                           newline,         // Flag which marks start of scanline
    input                           qam_startburst,  // Starts PAL/NTSC burst
    input                           secam_enabled,   // Activates SECAM carrier
    input  video_standard_e         video_standard,  // PAL, NTSC or SECAM
    input  ycbcr_t                  in,              // Digital video input
    output bit                [7:0] video,           // Analog video output
    output bit                      video_overflow,  // If 1, then mixing error occured
           debug_bus_if.slave       dbus             // Debug interface
);

    bit [5:0] debug_burst_u = `NTSC_BURST_U;  // TODO remove
    bit [5:0] debug_burst_v = `NTSC_BURST_V;  // TODO remove
    bit [7:0] secam_debug_db_swing = `CONFIG_SECAM_DB_SWING;
    bit [6:0] secam_debug_dr_swing = `CONFIG_SECAM_DR_SWING;
    bit [4:0] secam_debug_carrier_delay = 0;
    bit chroma_lowpass_enable = 0;  // TODO remove
    bit chroma_bandpass_enable = 1;  // TODO remove
    bit chroma_enable = 1;

    ycbcr_t in_q;

    bit [7:0] luma_black_level = 52;
    /* TODO for GOWIN support
     * Something here is wrong. It is required to set the ram style
     * to "registers" to allow initialization. Otherwise it is all zeroes.
     */
    bit [7:0] y_scaler_mem[4]  /* synthesis syn_ramstyle = "registers" */ = {
        `CONFIG_PAL_Y_SCALER, `CONFIG_NTSC_Y_SCALER, `CONFIG_SECAM_Y_SCALER, 0
    };
    bit signed [7:0] u_scaler_mem[4]  /* synthesis syn_ramstyle = "registers" */ = {
        `CONFIG_PAL_U_SCALER, `CONFIG_NTSC_U_SCALER, `CONFIG_SECAM_U_SCALER, 0
    };
    bit signed [7:0] v_scaler_mem[4]  /* synthesis syn_ramstyle = "registers" */ = {
        `CONFIG_PAL_V_SCALER, `CONFIG_NTSC_V_SCALER, `CONFIG_SECAM_V_SCALER, 0
    };

    yuv_t scaler;
    yuv_t scaled;

    // Handle debug bus for scaler configuration configuratuion
    always_ff @(posedge clk) begin
        if (dbus.addr[15:8] == 8'h02 && dbus.write_enable) begin
            case (dbus.addr[3:2])
                0: y_scaler_mem[dbus.addr[1:0]] <= dbus.write_data;
                1: u_scaler_mem[dbus.addr[1:0]] <= dbus.write_data;
                2: v_scaler_mem[dbus.addr[1:0]] <= dbus.write_data;
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        // Perform the readout using a seperate step to reduce
        // propagation delay
        scaler.y <= y_scaler_mem[video_standard];
        scaler.u <= u_scaler_mem[video_standard];
        scaler.v <= v_scaler_mem[video_standard];

        // Apply scaling to convert YCbCr into YUV using configurable scalers
        scaled.y <= 8'((16'(in_q.y) * 16'(scaler.y)) >> 8);
        scaled.u <= 8'((16'(in_q.cb) * 16'(scaler.u)) >>> 8);
        scaled.v <= 8'((16'(in_q.cr) * 16'(scaler.v)) >>> 8);
    end

    // The filters used on chroma and luma might cause both signals
    // to get out of phase. This delay line will ensure that both do again
    // align in the final sum
    bit [4:0] luma_delay_duration = 0;
    bit [4:0] yuv_u_delay_duration = 0;
    bit [4:0] yuv_v_delay_duration = 0;

    yuv_t delayed;

    delayfifo #(8) dfy (
        .clk,
        .in(scaled.y),
        .latency(luma_delay_duration),
        .out(delayed.y)
    );

    delayfifo #(8) dfu (
        .clk,
        .in(scaled.u),
        .latency(yuv_u_delay_duration),
        .out(delayed.u)
    );

    delayfifo #(8) dfv (
        .clk,
        .in(scaled.v),
        .latency(yuv_v_delay_duration),
        .out(delayed.v)
    );

    bit [7:0] luma_filtered;

    // The luma signal is not allowed to have higher frequencies as
    // it could reach the color carrier and cause rainbow artefacts.
    // These are filtered out using this low pass.
    filter_pal_luma lumafilter0 (
        .clk(clk),
        .in (delayed.y),
        .out(luma_filtered)
    );

    bit even_line = 0;
    always_ff @(posedge clk) begin
        if (newline) even_line <= !even_line;
    end

    bit signed [7:0] pal_ntsc_chroma;
`ifdef CONFIG_PAL_NTSC_ENABLED
    wire pal_mode = (video_standard == PAL);
    pal_ntsc_encoder pal_ntsc (
        .clk,
        .even_line,
        .newframe,
        .newline,
        .pal_mode,
        .chroma_lowpass_enable,
        .chroma_bandpass_enable,
        .yuv_u(delayed.u),
        .yuv_v(delayed.v),
        .startburst(qam_startburst),
        .chroma(pal_ntsc_chroma),
        .debug_burst_u,
        .debug_burst_v
    );
`endif

    bit signed [7:0] secam_chroma;
`ifdef CONFIG_SECAM_ENABLED
    secam_encoder secam (
        .clk,
        .even_line,
        .yuv_u(delayed.u),
        .yuv_v(delayed.v),
        .debug_db_swing(secam_debug_db_swing),
        .debug_dr_swing(secam_debug_dr_swing),
        .carrier_period_delay(secam_debug_carrier_delay),
        .chroma_lowpass_enable,
        .enabled(secam_enabled),
        .newframe(newframe),
        .luma_filtered,
        .chroma(secam_chroma)
    );
`endif

    // The video output of this module is only 8 bit, but
    // we perform the calculations here on 9 bit to catch
    // integer overflows.
    bit [8:0] video_d;
    bit [8:0] video_q;

    always_ff @(posedge clk) begin
        video_q <= video_d;
        in_q <= in;

        if (newframe) video_overflow <= 0;
        else if (video_d[8]) video_overflow <= 1;

        if (video_q[8]) video <= 0;
        else video <= video_q[7:0];
    end

    // Add everything together
    always_comb begin
        video_d = 0;  // Sync case with GND level is the default

        if (!sync) begin
            // Sync is not active? Lift up to black level.

            if (!chroma_enable) begin
                // Chroma is disabled. Add luma without low pass filter
                video_d = luma_black_level + delayed.y;
            end else begin
                // Chroma is enable. Add luma with low pass filter
                video_d = luma_black_level + luma_filtered;

                // now add chroma carrier
                if (video_standard == SECAM) video_d = video_d + {secam_chroma[7], secam_chroma};
                else video_d = video_d + {pal_ntsc_chroma[7], pal_ntsc_chroma};
            end
        end
    end

    // Handle debug bus to allow configuratuion
    always_ff @(posedge clk) begin
        if (dbus.addr[15:8] == 8'h00 && dbus.write_enable) begin
            case (dbus.addr[7:0])
                0: luma_delay_duration <= dbus.write_data[4:0];
                6: begin
                    chroma_lowpass_enable <= dbus.write_data[0];
                    chroma_bandpass_enable <= dbus.write_data[1];
                    chroma_enable <= dbus.write_data[4];
                end
                7: debug_burst_u <= dbus.write_data[5:0];
                8: debug_burst_v <= dbus.write_data[5:0];
                9: luma_black_level <= dbus.write_data;
                12: yuv_u_delay_duration <= dbus.write_data[4:0];
                13: yuv_v_delay_duration <= dbus.write_data[4:0];
                14: secam_debug_db_swing <= dbus.write_data[7:0];
                15: secam_debug_dr_swing <= dbus.write_data[6:0];
                16: secam_debug_carrier_delay <= dbus.write_data[4:0];
                default: ;
            endcase
        end
    end

    // Higher bit width variant of some filter to compare against
    // during verilation
`ifdef VERILATOR
    bit [7:0] luma_filtered_check;
    // verilator lint_off WIDTHEXPAND
    pal_verify_lumafilter lumafilter0_check (
        .clk(clk),
        .in (delayed.y),
        .out(luma_filtered_check)
    );
    // verilator lint_on WIDTHEXPAND
    always_ff @(posedge clk) begin
        assert (luma_filtered == luma_filtered_check);
    end
`endif


endmodule
