`include "coefficients.svh"

/*
 * Quadrature amplitude modulation
 * using direct digital synthesis (DDS) to generate two sine waves orthogonal to
 * each other.
 */
module qam (
    input clk,
    input startburst,  // Flag to start the color burst
    input pal_mode,  // 1 == PAL, 0 == NTSC
    input signed [5:0] in_u,
    input signed [5:0] in_v,
    input newline,
    input even_line,
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

    bit [ClockDivideLastBit:0] phase_accumulator = 0;

    // Use the highest 5 bit of the phase accumulator as current index
    // for the sine wave look up table
    wire [4:0] carrier_phase = phase_accumulator[ClockDivideLastBit:ClockDivideLastBit-4];

    // U phase is equal to carrier
    wire [4:0] phase_u = carrier_phase;
    // V phase is 90% rotated to U
    wire [4:0] phase_v = carrier_phase + 8;

    // Keep track on the remaining clock cycles, the burst needs to stay
    bit [7:0] burst_counter = 0;
    wire burst_enabled = (burst_counter != 0);

    bit signed [5:0] u;
    bit signed [5:0] v;

    // Handle color burst and V inversion for PAL
    always_comb begin
        // In no special case, let the input data through
        u = in_u;
        v = in_v;

        if (pal_mode) begin
            if (burst_enabled) begin
                // Provide 45 degree
                u = `PAL_BURST_U;
                v = `PAL_BURST_V;
            end

            // Do the PAL V inversion thing every other scanline
            if (even_line) v = -v;
        end else begin
            if (burst_enabled) begin
                u = debug_burst_u;
                v = debug_burst_v;
            end
        end

    end

    // Handle burst starting and DDS phase accumulation
    always @(posedge clk) begin
        if (startburst) burst_counter <= pal_mode ? BurstLen_2_2us : BurstLen_2_9us;
        else if (burst_counter != 0) burst_counter <= burst_counter - 1;

        if (pal_mode) phase_accumulator <= phase_accumulator + `PAL_CHROMA_DDS_INCREMENT;
        else phase_accumulator <= phase_accumulator + `NTSC_CHROMA_DDS_INCREMENT;
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
