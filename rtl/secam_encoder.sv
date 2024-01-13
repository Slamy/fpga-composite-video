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

    bit signed [8:0] carrier_period_modulate  /*verilator public_flat_rd*/;
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

    always_comb begin
        carrier_amplitude = 0;
        carrier_period_modulate = 0;

        carrier_phase = clockdivide_counter[ClockDivideLastBit:ClockDivideLastBit-4];

        if (enabled) begin
            carrier_amplitude = enabled_amplitude_filtered;

            if (even_line) begin
                carrier_period_modulate = 9'(yuv_u);
            end else begin
                carrier_period_modulate = 9'(yuv_v);
            end

        end
    end

    bit signed [8:0] carrier_period_filtered  /*verilator public_flat_rd*/;
    bit signed [8:0] carrier_period_emphasis  /*verilator public_flat_rd*/;
    bit signed [8:0] carrier_period_clipped  /*verilator public_flat_rd*/;

    filter_secam_chroma_lowpass chlo (
        .clk(clk),
        .in (carrier_period_modulate),
        .out(carrier_period_filtered)
    );

    bit signed [8:0] carrier_period_maybe_filtered = 0;
    always_ff @(posedge clk) begin
        carrier_period_maybe_filtered <= chroma_lowpass_enable ? carrier_period_filtered : carrier_period_modulate;
    end

    filter_chroma_preemphasis_lowpass chlolo (
        .clk(clk),
        .in (carrier_period_maybe_filtered),
        .out(carrier_period_emphasis)
    );

    bit signed [12:0] carrier_period_emphasis2  /*verilator public_flat_rd*/;
    bit signed [12:0] carrier_period_emphasis2_delayed  /*verilator public_flat_rd*/;

    delayfifo #(13) df (
        .clk,
        .in(carrier_period_emphasis2),
        .latency(carrier_period_delay),
        .out(carrier_period_emphasis2_delayed)
    );


    always_ff @(posedge clk) begin
        if (even_line) begin
            // Db or U
            carrier_period_emphasis2 <= (13'(carrier_period_maybe_filtered)<<<4) + (debug_db_swing*(13'(carrier_period_maybe_filtered)-13'(carrier_period_emphasis)));
        end else begin
            // Dr or V
            carrier_period_emphasis2 <= (13'(carrier_period_maybe_filtered)<<<4) + (debug_dr_swing*(13'(carrier_period_maybe_filtered)-13'(carrier_period_emphasis)));

        end
    end

    always_ff @(posedge clk) begin
        if (even_line) begin
            phase_increment_ampl    <=  `SECAM_CHROMA_DB_DDS_INCREMENT + (51'(carrier_period_emphasis2)<<<35);
            phase_increment <=  `SECAM_CHROMA_DB_DDS_INCREMENT + (51'(carrier_period_emphasis2_delayed)<<<35);
        end else begin
            phase_increment_ampl <=  `SECAM_CHROMA_DR_DDS_INCREMENT - (51'(carrier_period_emphasis2)<<<35);
            phase_increment <=  `SECAM_CHROMA_DR_DDS_INCREMENT - (51'(carrier_period_emphasis2_delayed)<<<35);
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

    filter_int_5tap chlo_check (
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

    filter_int_5tap chlolo_check (
        .clk(clk),
        .in(carrier_period_maybe_filtered <<< 1),
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

        if (carrier_period_emphasis != carrier_period_emphasis_check_q2) failed <= 1;
        assert (carrier_period_emphasis == carrier_period_emphasis_check_q2);

        if (enabled_amplitude_filtered != enabled_amplitude_filtered_check_q2) failed <= 1;
        assert (enabled_amplitude_filtered == enabled_amplitude_filtered_check_q2);
    end

`endif


endmodule

