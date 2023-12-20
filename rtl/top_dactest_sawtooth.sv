
module top_dactest_sawtooth (
    input clk27,
    output uart_tx,
    input uart_rx,
    input rst_n,
    output bit [7:0] video,
    output bit [7:6] video_extra
);

    bit [31:0] dac_counter = 0;
    bit [31:0] out = 0;

    always_comb begin
        out = dac_counter[10:10-7];
    end

    always_ff @(posedge clk27) begin
        dac_counter <= dac_counter + 1;

        video <= out;
        video_extra[7:6] <= out[7:6];
        // video <=8'hff;
    end

endmodule
