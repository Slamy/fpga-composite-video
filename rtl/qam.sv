`include "coefficients.svh"

module qam (
    input clk,
    input startburst,
    input pal_mode,
    input signed [5:0] in_u,
    input signed [5:0] in_v,
    input newline,
    input even_line,
    input even_field,
    input newframe,
    output bit signed [7:0] chroma,
    input signed [5:0] debug_burst_u,
    input signed [5:0] debug_burst_v
)  /* synthesis syn_dspstyle = "logic" */;

    localparam int ClockDivideLastBit = 50;

    // 2.2 usec for 10 cycles
    localparam bit [7:0] BurstLen_2_2us = 8'(integer'(2.2 / `CLK_PERIOD_USEC));
    // 2.9 usec for 10 cycles
    localparam bit [7:0] BurstLen_2_9us = 8'(integer'(2.9 / `CLK_PERIOD_USEC));

    bit [ClockDivideLastBit:0] clockdivide_counter = 0;
    bit [4:0] carrier_phase;
    wire [4:0] phase_u = carrier_phase;
    wire [4:0] phase_v = carrier_phase + 8;
    bit [7:0] burst_counter = 0;
    wire burst_enabled = (burst_counter != 0);

    bit even_frame = 0;

    bit signed [5:0] u;
    bit signed [5:0] v;

    always_comb begin
        u = in_u;
        v = in_v;

        carrier_phase = clockdivide_counter[ClockDivideLastBit:ClockDivideLastBit-4];

        if (pal_mode) begin
            if (burst_enabled) begin
                u = `PAL_BURST_U;
                v = `PAL_BURST_V;
            end
            if (even_line) v = -v;
        end else begin
            if (burst_enabled) begin
                u = debug_burst_u;
                v = debug_burst_v;
            end
        end

    end

    always @(posedge clk) begin
        if (startburst) burst_counter <= pal_mode ? BurstLen_2_2us : BurstLen_2_9us;
        else if (burst_counter != 0) burst_counter <= burst_counter - 1;

        if (pal_mode) clockdivide_counter <= clockdivide_counter + `PAL_CHROMA_DDS_INCREMENT;
        else clockdivide_counter <= clockdivide_counter + `NTSC_CHROMA_DDS_INCREMENT;
    end

    wire signed [7:0] sinus_out_u;
    wire signed [7:0] sinus_out_v;

    sinus sine_u (
        .clk(clk),
        .phase(phase_u),
        .amplitude(u),
        .out(sinus_out_u)
    );

    sinus sine_v (
        .clk(clk),
        .phase(phase_v),
        .amplitude(v),
        .out(sinus_out_v)
    );

    always @(posedge clk) begin
        chroma <= sinus_out_u + sinus_out_v;
    end

endmodule
