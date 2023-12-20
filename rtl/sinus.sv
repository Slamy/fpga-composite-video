
// Simple sine wave generator
// The synthesis tool is expected to use a bram instance for this
module sinus (
    input clk,
    input [4:0] phase,  // phase from 0 to 31 in steps of 11.25 (360/32) degrees
    input signed [5:0] amplitude,  // amplitudes in range -31 to 31
    output bit signed [7:0] out
);
    bit [5:0] amplitude_index;
    bit [4:0] phase_internal;
    wire [10:0] index = {amplitude_index, phase_internal};

    bit signed [7:0] lut[2048];

    initial begin
        $readmemh("../mem/sinewave.txt", lut);
    end

    always_comb begin
        if (amplitude < 0) begin
            amplitude_index = -amplitude;
            phase_internal  = phase + 16;
        end else begin
            amplitude_index = amplitude;
            phase_internal  = phase;
        end
    end

    always_ff @(posedge clk) begin
        out <= lut[index];
    end

endmodule
