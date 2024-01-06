`include "configuration.svh"

import common::*;

module composite_video_encoder (
    input                           clk,
    input                           sync,
    input                           newframe,
    input                           newline,
    input                           qam_startburst,
    input                           secam_enabled,
    input  video_standard_e         video_standard,
    input                     [7:0] luma,
    input  signed             [7:0] yuv_u,
    input  signed             [7:0] yuv_v,
    output bit                [7:0] video,
    output bit                      video_overflow,
           debug_bus_if.slave       dbus,
    input                           even_field
);

    bit [5:0] debug_burst_u = -14;  // TODO remove
    bit [5:0] debug_burst_v = 4;  // TODO remove
    bit [7:0] secam_debug_db_swing = 52;
    bit [6:0] secam_debug_dr_swing = 42;
    bit [4:0] secam_debug_carrier_delay = 20;
    bit chroma_lowpass_enable = 0;  // TODO remove
    bit chroma_bandpass_enable = 1;  // TODO remove
    bit chroma_enable = 1;

    bit signed [7:0] yuv_u_q;
    bit signed [7:0] yuv_v_q;
    bit [7:0] luma_q;

    bit [7:0] luma_black_level = 52;
    bit [7:0] y_scaler_mem[4];
    bit signed [7:0] u_scaler_mem[4];
    bit signed [7:0] v_scaler_mem[4];

    bit [7:0] luma_scaled;
    bit signed [7:0] u_scaled;
    bit signed [7:0] v_scaled;

    bit [7:0] luma_scaler = 150;

    initial begin
        video_overflow  = 0;
        y_scaler_mem[0] = `CONFIG_PAL_Y_SCALER;
        y_scaler_mem[1] = `CONFIG_NTSC_Y_SCALER;
        y_scaler_mem[2] = `CONFIG_SECAM_Y_SCALER;
        u_scaler_mem[0] = `CONFIG_PAL_U_SCALER;
        u_scaler_mem[1] = `CONFIG_NTSC_U_SCALER;
        u_scaler_mem[2] = `CONFIG_SECAM_U_SCALER;
        v_scaler_mem[0] = `CONFIG_PAL_V_SCALER;
        v_scaler_mem[1] = `CONFIG_NTSC_V_SCALER;
        v_scaler_mem[2] = `CONFIG_SECAM_V_SCALER;
    end

    bit [1:0] video_standard_adr;

    always_ff @(posedge clk) begin
        // TODO for GOWIN Support.
        // Why can't I use video_standard as an index?
        // It seems to not work. Even if I translate it using if and else if
        // to an actual number...
        /*
        if (video_standard == PAL) video_standard_adr <= 0;
        else if (video_standard == NTSC) video_standard_adr <= 1;
        else if (video_standard == SECAM) video_standard_adr <= 2;

        luma_scaled <= 8'((16'(luma_q) * 16'(y_scaler_mem[video_standard_adr])) >> 8);
        u_scaled <= 8'((16'(yuv_u_q) * 16'(u_scaler_mem[video_standard_adr])) >>> 6);
        v_scaled <= 8'((16'(yuv_v_q) * 16'(v_scaler_mem[video_standard_adr])) >>> 6);
        */
        // TODO The following code is only a substitution until a real
        // solution is found...

        case (video_standard)
            PAL: luma_scaled <= 8'((16'(luma_q) * 16'(y_scaler_mem[0])) >> 8);
            NTSC: luma_scaled <= 8'((16'(luma_q) * 16'(y_scaler_mem[1])) >> 8);
            SECAM: luma_scaled <= 8'((16'(luma_q) * 16'(y_scaler_mem[2])) >> 8);
            default: ;  // Do nothing
        endcase

        case (video_standard)
            PAL: u_scaled <= 8'((16'(yuv_u_q) * 16'(u_scaler_mem[0])) >>> 6);
            NTSC: u_scaled <= 8'((16'(yuv_u_q) * 16'(u_scaler_mem[1])) >>> 6);
            SECAM: u_scaled <= 8'((16'(yuv_u_q) * 16'(u_scaler_mem[2])) >>> 6);
            default: ;  // Do nothing
        endcase

        case (video_standard)
            PAL: v_scaled <= 8'((16'(yuv_v_q) * 16'(v_scaler_mem[0])) >>> 6);
            NTSC: v_scaled <= 8'((16'(yuv_v_q) * 16'(v_scaler_mem[1])) >>> 6);
            SECAM: v_scaled <= 8'((16'(yuv_v_q) * 16'(v_scaler_mem[2])) >>> 6);
            default: ;  // Do nothing
        endcase

    end

    // The filters used on chroma and luma might cause both signals
    // to get out of phase. This delay line will ensure that both do again
    // align in the final sum
    bit [4:0] luma_delay_duration = 0;
    bit [4:0] yuv_u_delay_duration = 0;
    bit [4:0] yuv_v_delay_duration = 0;
    bit [7:0] luma_delayed;
    bit signed [7:0] yuv_u_delayed;
    bit signed [7:0] yuv_v_delayed;

    delayfifo32 #(8) dfy (
        .clk,
        .in(luma_scaled),
        .latency(luma_delay_duration),
        .out(luma_delayed)
    );

    delayfifo32 #(8) dfu (
        .clk,
        .in(u_scaled),
        .latency(yuv_u_delay_duration),
        .out(yuv_u_delayed)
    );

    delayfifo32 #(8) dfv (
        .clk,
        .in(v_scaled),
        .latency(yuv_v_delay_duration),
        .out(yuv_v_delayed)
    );

    bit [7:0] luma_filtered;

    // The luma signal is not allowed to have higher frequencies as
    // it could reach the color carrier and cause rainbow artefacts.
    // These are filtered out using this low pass.
    filter_pal_luma lumafilter0 (
        .clk(clk),
        .in (luma_delayed),
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
        .even_field,
        .newframe,
        .newline,
        .pal_mode,
        .chroma_lowpass_enable,
        .chroma_bandpass_enable,
        .yuv_u(yuv_u_delayed),
        .yuv_v(yuv_v_delayed),
        .startburst(qam_startburst),
        .luma_filtered,
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
        .yuv_u(yuv_u_delayed),
        .yuv_v(yuv_v_delayed),
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
    //bit [8:0] video;


    always_ff @(posedge clk) begin
        video_q <= video_d;
        luma_q  <= luma;
        yuv_u_q <= yuv_u;
        yuv_v_q <= yuv_v;

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
                video_d = luma_black_level + luma_delayed;
            end else begin
                // Chroma is enable. Add luma with low pass filter
                video_d = luma_black_level + luma_filtered;

                // now add chroma carrier
                if (video_standard == SECAM) video_d = video_d + {secam_chroma[7], secam_chroma};
                else video_d = video_d + {pal_ntsc_chroma[7], pal_ntsc_chroma};
            end
        end
    end

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

        if (dbus.addr[15:8] == 8'h02 && dbus.write_enable) begin
            case (dbus.addr[3:2])
                0: y_scaler_mem[dbus.addr[1:0]] <= dbus.write_data;
                1: u_scaler_mem[dbus.addr[1:0]] <= dbus.write_data;
                2: v_scaler_mem[dbus.addr[1:0]] <= dbus.write_data;
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
        .in (luma_delayed),
        .out(luma_filtered_check)
    );
    // verilator lint_on WIDTHEXPAND
    always_ff @(posedge clk) begin
        assert (luma_filtered == luma_filtered_check);
    end
`endif


endmodule
