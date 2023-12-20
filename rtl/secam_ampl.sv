
module secam_ampl (
    input clk,
    input [50:0] phase_inc,
    output bit [5:0] out_ampl
);
    wire [10:0] index = 11'(phase_inc[50:36]) - 11'(2048);
    bit [5:0] lut[2048];

    initial begin
        $readmemh("../mem/secam_ampl.txt", lut);
    end

    always @(posedge clk) begin
        out_ampl <= lut[index];
    end

endmodule
