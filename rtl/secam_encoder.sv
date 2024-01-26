`include "coefficients.svh"

module secam_encoder (
    input clk,
    input even_line,
    input signed [7:0] yuv_u,
    input signed [7:0] yuv_v,
    input enabled,
    input chroma_lowpass_enable,
    input [7:0] luma_filtered,
    input signed [7:0] debug_db_swing,
    input signed [6:0] debug_dr_swing,
    input [4:0] carrier_period_delay,
    input newframe,
    output bit signed [7:0] chroma

);
    localparam int ClockDivideLastBit = 50;

    bit [ClockDivideLastBit:0] clockdivide_counter = 0;
    bit [ClockDivideLastBit:0] phase_increment;
    bit [ClockDivideLastBit:0] phase_increment_ampl;
    bit [4:0] carrier_phase;

    bit [5:0] carrier_amplitude;
    bit [5:0] enabled_amplitude;
    secam_ampl ampl (
        .clk,
        .phase_inc(phase_increment_ampl),
        .out_ampl (enabled_amplitude)
    );
    bit [5:0] enabled_amplitude_filtered;

    filter_secam_amplitude_lowpass amplow (
        .clk,
        .in (enabled_amplitude),
        .out(enabled_amplitude_filtered)
    );

    bit signed [8:0] carrier_period_modulate;

    always_comb begin
        carrier_amplitude = 0;
        carrier_period_modulate = 0;

        carrier_phase = clockdivide_counter[ClockDivideLastBit:ClockDivideLastBit-4];

        if (enabled) begin
            carrier_amplitude = enabled_amplitude_filtered;

            // perform the mux as Db and Dr are transmitted line alternating
            if (even_line) begin
                carrier_period_modulate = 9'(yuv_u);  // Db or U
            end else begin
                carrier_period_modulate = 9'(yuv_v);  // Dr or V
            end

        end
    end

    // optional low pass filter to remove high frequencies from the color difference signals.
    // luckily for SECAM we need only one as only one component is transmitted per line
    bit signed [8:0] carrier_period_filtered  /*verilator public_flat_rd*/;
    bit signed [8:0] carrier_period_deemphasis  /*verilator public_flat_rd*/;
    filter_secam_chroma_lowpass carrier_lowpass (
        .clk(clk),
        .in (carrier_period_modulate),
        .out(carrier_period_filtered)
    );
    // muxing, making the chroma lowpass optional
    bit signed [8:0] carrier_period_maybe_filtered = 0;

    always_ff @(posedge clk) begin
        carrier_period_maybe_filtered <= chroma_lowpass_enable ? carrier_period_filtered : carrier_period_modulate;
    end

    // perform internal deemphasis in a closed feedback loop
    bit signed [12:0] carrier_period_emphasis;
    filter_secam_deemphasis deemphasis (
        .clk(clk),
        .in (carrier_period_emphasis[12:4]),
        .out(carrier_period_deemphasis)
    );

    bit signed [12:0] carrier_period_emphasis_delayed;
    delayfifo #(13) df (
        .clk,
        .in(carrier_period_emphasis),
        .latency(carrier_period_delay),
        .out(carrier_period_emphasis_delayed)
    );

    wire signed [12:0] err = 2 * (13'(carrier_period_maybe_filtered) - 13'(carrier_period_deemphasis));

    // calculate emphasis swing using deemphasis result
    always_ff @(posedge clk) begin
        if (even_line) begin  // Db or U
            carrier_period_emphasis <= (debug_db_swing * err) + (13'(carrier_period_deemphasis) <<< 4);
        end else begin  // Dr or V
            carrier_period_emphasis <= (debug_dr_swing * err) + (13'(carrier_period_deemphasis) <<< 4);
        end
    end

    // calculate the phase accumulator. perform frequency modulation
    always_ff @(posedge clk) begin
        if (even_line) begin
            phase_increment_ampl    <=  `SECAM_CHROMA_DB_DDS_INCREMENT + (51'(carrier_period_emphasis)<<<35);
            phase_increment <=  `SECAM_CHROMA_DB_DDS_INCREMENT + (51'(carrier_period_emphasis_delayed)<<<35);
        end else begin
            phase_increment_ampl <=  `SECAM_CHROMA_DR_DDS_INCREMENT - (51'(carrier_period_emphasis)<<<35);
            phase_increment <=  `SECAM_CHROMA_DR_DDS_INCREMENT - (51'(carrier_period_emphasis_delayed)<<<35);
        end
    end

    always_ff @(posedge clk) begin
        clockdivide_counter <= clockdivide_counter + phase_increment;
    end


    sinus sinus0 (
        .clk(clk),
        .phase(carrier_phase),
        .amplitude(carrier_amplitude),
        .out(chroma)
    );



`ifdef VERILATOR
    bit signed [9:0] carrier_period_filtered_check;
    bit signed [9:0] carrier_period_filtered_check_q;
    bit signed [8:0] carrier_period_filtered_check_q2;
    bit signed [9:0] carrier_period_emphasis_check;
    bit signed [9:0] carrier_period_emphasis_check_q;
    bit signed [8:0] carrier_period_emphasis_check_q2;

    bit [5:0] enabled_amplitude_filtered_check;
    bit [5:0] enabled_amplitude_filtered_check_q2;

    // verilator lint_off WIDTHEXPAND

    filter_int_5tap amplow_check (
        .clk(clk),
        .in(enabled_amplitude),
        .out(enabled_amplitude_filtered_check),
        .b0(`SECAM_AMPLITUDE_LOWPASS_B0),
        .b1(`SECAM_AMPLITUDE_LOWPASS_B1),
        .b2(`SECAM_AMPLITUDE_LOWPASS_B2),
        .b3(0),
        .b4(0),
        .a1(`SECAM_AMPLITUDE_LOWPASS_A1),
        .a2(`SECAM_AMPLITUDE_LOWPASS_A2),
        .a3(0),
        .a4(0),
        .a_precision(`SECAM_AMPLITUDE_LOWPASS_A_AFTER_DOT),
        .b_precision(`SECAM_AMPLITUDE_LOWPASS_B_AFTER_DOT)
    );

    filter_int_5tap carrier_lowpass_check (
        .clk(clk),
        .in(carrier_period_modulate <<< 1),
        .out(carrier_period_filtered_check),
        .b0(`SECAM_CHROMA_LOWPASS_B0),
        .b1(`SECAM_CHROMA_LOWPASS_B1),
        .b2(`SECAM_CHROMA_LOWPASS_B2),
        .b3(0),
        .b4(0),
        .a1(`SECAM_CHROMA_LOWPASS_A1),
        .a2(`SECAM_CHROMA_LOWPASS_A2),
        .a3(0),
        .a4(0),
        .a_precision(`SECAM_CHROMA_LOWPASS_A_AFTER_DOT),
        .b_precision(`SECAM_CHROMA_LOWPASS_B_AFTER_DOT)
    );


    filter_int_5tap_floorA deemphasis_check (
        .clk(clk),
        .in((carrier_period_emphasis >>> 4) <<< 1),
        .out(carrier_period_emphasis_check),
        .b0(`SECAM_PREEMPHASIS_B0),
        .b1(`SECAM_PREEMPHASIS_B1),
        .b2(`SECAM_PREEMPHASIS_B2),
        .b3(0),
        .b4(0),
        .a1(`SECAM_PREEMPHASIS_A1),
        .a2(`SECAM_PREEMPHASIS_A2),
        .a3(0),
        .a4(0),
        .a_precision(`SECAM_PREEMPHASIS_A_AFTER_DOT),
        .b_precision(`SECAM_PREEMPHASIS_B_AFTER_DOT)
    );
    // verilator lint_on WIDTHEXPAND


    bit failed = 0;

    always_ff @(posedge clk) begin
        carrier_period_filtered_check_q <= carrier_period_filtered_check;
        carrier_period_filtered_check_q2 <= carrier_period_filtered_check_q[9:1];

        carrier_period_emphasis_check_q <= carrier_period_emphasis_check;
        carrier_period_emphasis_check_q2 <= carrier_period_emphasis_check_q[9:1];

        enabled_amplitude_filtered_check_q2 <= enabled_amplitude_filtered_check;

        if (carrier_period_filtered != carrier_period_filtered_check_q2) failed <= 1;
        assert (carrier_period_filtered == carrier_period_filtered_check_q2);

        if (carrier_period_deemphasis != carrier_period_emphasis_check_q2) failed <= 1;
        assert (carrier_period_deemphasis == carrier_period_emphasis_check_q2);

        if (enabled_amplitude_filtered != enabled_amplitude_filtered_check_q2) failed <= 1;
        assert (enabled_amplitude_filtered == enabled_amplitude_filtered_check_q2);
    end

`endif


endmodule

