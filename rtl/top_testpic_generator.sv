`include "coefficients.svh"
`include "common.svh"

import common::*;

module top_testpic_generator (
    input clk27,
    input switch1,
    input sys_resetn,
    output bit [7:0] video,
    output bit [7:6] video_extra,
    input uart_rx,
    output uart_tx,
    output bit [5:0] led,

    output [ 1:0] O_psram_ck,       // Magic ports for PSRAM to be inferred
    output [ 1:0] O_psram_ck_n,
    inout  [ 1:0] IO_psram_rwds,
    inout  [15:0] IO_psram_dq,
    output [ 1:0] O_psram_reset_n,
    output [ 1:0] O_psram_cs_n
)  /* synthesis syn_netlist_hierarchy=0 */;

    wire video_overflow;

    assign video_extra[7:6] = video[7:6];
    assign led[5:1] = 5'b11111;
    assign led[0] = !video_overflow;

    wire lock_o;
    wire clk96;
    wire clk96_p;
    wire clkoutd_o;
    wire clk  /*verilator public_flat_rw*/;

`ifndef VERILATOR
    Gowin_rPLL pll (
        .clkout(clk96),  //output clkout
        .lock(lock_o),  //output lock
        .clkoutp(clk96_p),  //output clkoutp
        .clkoutd(clkoutd_o),  //output clkoutd
        .clkin(clk27)  //input clkin
    );
`endif

    burst_bus_if mem_bus (clk);
    burst_bus_if debug_mem_bus (clk);

    wire calib;

    PSRAM_Memory_Interface_HS_V2_Top u_psram_top (
        .clk_d(clkoutd_o),  //input clk_d
        .memory_clk(clk96),  //input memory_clk
        .memory_clk_p(clk96_p),  //input memory_clk_p
        .pll_lock(lock_o),  //input pll_lock
        .rst_n(1'b1),  //input rst_n
        .O_psram_ck(O_psram_ck),  //output [1:0] O_psram_ck
        .O_psram_ck_n(O_psram_ck_n),  //output [1:0] O_psram_ck_n
        .IO_psram_dq(IO_psram_dq),  //inout [15:0] IO_psram_dq
        .IO_psram_rwds(IO_psram_rwds),  //inout [1:0] IO_psram_rwds
        .O_psram_cs_n(O_psram_cs_n),  //output [1:0] O_psram_cs_n
        .O_psram_reset_n(O_psram_reset_n),  //output [1:0] O_psram_reset_n
        .wr_data(mem_bus.wr_data),  //input [63:0] wr_data
        .rd_data(mem_bus.rd_data),  //output [63:0] rd_data
        .rd_data_valid(mem_bus.rd_data_valid),  //output rd_data_valid
        .addr(mem_bus.addr),  //input [20:0] addr
        .cmd(mem_bus.cmd),  //input cmd
        .cmd_en(mem_bus.cmd_en),  //input cmd_en
        .init_calib(calib),  //output init_calib
        .clk_out(clk),  //output clk_out
        .data_mask(mem_bus.data_mask)  //input [7:0] data_mask
    );

    bit [5:0] cycle = 0;  // 14 cycles between write and read
    bit busy = 0;
    wire ram_ready = !busy && calib;
    assign mem_bus.ready = ram_ready;

    // implement busy flag as the memory controller doesn't create such a signal
    always_ff @(posedge clk) begin
        if (mem_bus.cmd_en) begin
            busy  <= 1;
            cycle <= 0;
        end

        if (busy) begin
            cycle <= cycle + 1;

            // IPUG 943 - Table 4-2, Tcmd is 14 when burst==16
            /* This is a weird thing. Usually after 14 cycles the RAM controller
             * is again able to take a command. But the data which is read back
             * for the current read command is delivered after about 14 cycles as well.
             * This makes it a little bit more difficult for multiple masters
             * as communication is interleaved.
             * As I currently don't want to solve this, I set this value to 20
             * instead of the probably more performant 13.
             */
            if (cycle == 20) begin
                busy <= 0;
            end
        end
    end


    debug_bus_if dbus (clk);

    uart_busmaster uart_db (
        .clk,
        .uart_rx,
        .uart_tx,
        .dbus(dbus.master)
    );

    localparam bit [8:0] NumberOfLines_50HZ = 312;
    localparam bit [8:0] NumberOfLines_60Hz = 262;
    localparam bit [8:0] NumberOfVisibleLines_50HZ = 256;
    localparam bit [8:0] NumberOfVisibleLines_60HZ = 200;

    bit sync;
    bit newline;
    bit newframe;
    bit newpixel;
    bit qam_startburst;
    bit [8:0] video_y;
    bit [12:0] video_x;
    bit visible_line;
    bit visible_window;
    bit [8:0] v_total = NumberOfLines_50HZ;
    bit [8:0] v_active = NumberOfVisibleLines_50HZ;
    bit even_field;
    bit interlacing_enable;

    video_timing video_timing0 (
        .clk(clk),
        .v_total(v_total),
        .v_active(v_active),
        .interlacing_enable,
        .sync(sync),
        .newline(newline),
        .newframe(newframe),
        .newpixel(newpixel),
        .startburst(qam_startburst),
        .video_x(video_x),
        .video_y(video_y),

        .visible_line  (visible_line),
        .visible_window(visible_window),
        .even_field
    );

    video_standard_e video_standard = PAL;
    ycbcr_t cvbs_in;

    bit secam_enabled;

    composite_video_encoder cvbs (
        .clk,
        .sync(sync),
        .newframe,
        .newline,
        .secam_enabled,
        .qam_startburst,
        .video_standard,
        .in  (cvbs_in),
        .video,
        .video_overflow,
        .dbus
    );
    burst_bus_if fb_bus (clk);

    burst_bus_arbiter arbiter (
        .mem(mem_bus),
        .m2 (debug_mem_bus),
        .m1 (fb_bus)
    );

    ycbcr_t fb_output;


    framebuffer fb (
        .bus(fb_bus),
        .newframe,
        .newline,
        .even_field,
        .video_y,
        .video_x,
        .out(fb_output),
        .dbus
    );

    ycbcr_t colorbars_output;
    bit colorbars_active = 1;

    rgbbars testpattern (
        .clk,
        .newline,
        .newpixel,
        .video_y(8'(video_y - 9'(38))),
        .visible_window,
        .out(colorbars_output)
    );

    always_ff @(posedge clk) begin
        if (dbus.addr[15:8] == 8'h00 && dbus.write_enable) begin
            case (dbus.addr[7:0])
                1: video_standard <= video_standard_e'(dbus.write_data[1:0]);
                2: v_total[8] <= dbus.write_data[0];
                3: v_total[7:0] <= dbus.write_data;
                4: v_active[8] <= dbus.write_data[0];
                5: v_active[7:0] <= dbus.write_data;
                6: begin
                    colorbars_active   <= dbus.write_data[3];
                    interlacing_enable <= dbus.write_data[5];
                end
                default: ;
            endcase
        end
    end

    assign dbus.ready = 1;

    burst_writer bw (
        .dbus,
        .mem(debug_mem_bus)
    );

    always_comb begin
        secam_enabled = 0;
        if (video_y > 7) begin
            secam_enabled = 1;
        end

        cvbs_in = fb_output;
        if (colorbars_active) begin
            cvbs_in = colorbars_output;
        end
    end
endmodule
