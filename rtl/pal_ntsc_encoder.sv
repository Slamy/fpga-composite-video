`include "coefficients.svh"


module pal_ntsc_encoder (
    input clk,
    input newframe,
    input newline,
    input even_line,
    input even_field,
    input pal_mode,
    input chroma_lowpass_enable,
    input chroma_bandpass_enable,
    input signed [7:0] yuv_u,
    input signed [7:0] yuv_v,
    input startburst,
    input [7:0] luma_filtered,
    output bit signed [7:0] chroma,
    input signed [5:0] debug_burst_u,
    input signed [5:0] debug_burst_v
);

    bit signed [5:0] yuv_u_filtered;
    bit signed [5:0] yuv_v_filtered;

    pal_chroma_lowpass clow0 (
        .clk(clk),
        .in (yuv_u[5:0]),
        .out(yuv_u_filtered)
    );

    pal_chroma_lowpass clow1 (
        .clk(clk),
        .in (yuv_v[5:0]),
        .out(yuv_v_filtered)
    );

    // We start by performing quadrature amplitude modulation
    // The result will have frequencies above and below the carrier
    // and thus will be defined as unfiltered here
    bit signed [7:0] chroma_unfiltered  /*verilator public_flat_rd*/;

    qam qam0 (
        .clk(clk),
        .newframe(newframe),
        .newline(newline),
        .startburst(startburst),
        .pal_mode,
        .in_u(chroma_lowpass_enable ? yuv_u_filtered : yuv_u[5:0]),
        .in_v(chroma_lowpass_enable ? yuv_v_filtered : yuv_v[5:0]),
        .even_line(even_line),
        .even_field(even_field),
        .chroma(chroma_unfiltered),
        .debug_burst_u,
        .debug_burst_v
    );

    // The chroma signal must be filtered using a band pass to remove
    // higher and lower frequencies to avoid bleeding into the luma signal
    // to avoid dot crawl
    bit signed [7:0] chroma_filtered  /*verilator public_flat_rd*/;


    filter_pal_carrier chromafilter0 (
        .clk(clk),
        .pal_mode,
        .in (chroma_unfiltered),
        .out(chroma_filtered)
    );

    assign chroma = chroma_bandpass_enable ? chroma_filtered : chroma_unfiltered;

    // To check if the bit width of the filters is ok, we instantiate them again
    // with a higher bit width and let them run in lock step. The results must match
`ifdef VERILATOR
    bit signed [7:0] chroma_filtered_check;
    bit signed [7:0] chroma_filtered_check_q2;

    // verilator lint_off WIDTHEXPAND

    localparam int ChromaFiltWidth = 23;

    bit signed [ChromaFiltWidth:0] chroma_filter_b0;
    bit signed [ChromaFiltWidth:0] chroma_filter_b1;
    bit signed [ChromaFiltWidth:0] chroma_filter_b2;
    bit signed [ChromaFiltWidth:0] chroma_filter_b3;
    bit signed [ChromaFiltWidth:0] chroma_filter_b4;

    bit signed [ChromaFiltWidth:0] chroma_filter_a1;
    bit signed [ChromaFiltWidth:0] chroma_filter_a2;
    bit signed [ChromaFiltWidth:0] chroma_filter_a3;
    bit signed [ChromaFiltWidth:0] chroma_filter_a4;

    always_comb begin
        chroma_filter_b0 = `NTSC_CHROMA_B0;
        chroma_filter_b1 = `NTSC_CHROMA_B1;
        chroma_filter_b2 = `NTSC_CHROMA_B2;
        chroma_filter_b3 = 0;
        chroma_filter_b4 = 0;
        chroma_filter_a1 = `NTSC_CHROMA_A1;
        chroma_filter_a2 = `NTSC_CHROMA_A2;
        chroma_filter_a3 = 0;
        chroma_filter_a4 = 0;

    end

    filter_int_5tap chromafilter_check (
        .clk(clk),
        .in(chroma_unfiltered),
        .out(chroma_filtered_check),
        .b0(chroma_filter_b0),
        .b1(chroma_filter_b1),
        .b2(chroma_filter_b2),
        .b3(chroma_filter_b3),
        .b4(chroma_filter_b4),
        .a1(chroma_filter_a1),
        .a2(chroma_filter_a2),
        .a3(chroma_filter_a3),
        .a4(chroma_filter_a4),
        .a_precision(`PAL_CHROMA_A_AFTER_DOT),
        .b_precision(`PAL_CHROMA_B_AFTER_DOT)
    );

    // verilator lint_on WIDTHEXPAND

    always_ff @(posedge clk) begin
        chroma_filtered_check_q2 <= chroma_filtered_check;
        //assert (chroma_filtered == chroma_filtered_check_q2);
    end
`endif


endmodule

