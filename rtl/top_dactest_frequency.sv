
module top_dactest_frequency (
    input clk27,
    output uart_tx,
    input uart_rx,
    input rst_n,
    input switch1,
    output bit [7:0] video,
    output bit [7:6] video_extra
);

    Gowin_rPLL clk27to48 (
        .clkin (clk27),    //input clkin
        .clkout(clkout_o)  //output clkout
    );

    localparam int ClockDivideLastBit = 50;

    bit [ClockDivideLastBit:0] clockdivide_counter = 0;

    bit [4:0] carrier_phase = 0;
    wire signed [7:0] sinus_out;
    sinus sin0 (
        .clk(clkout_o),
        .phase(carrier_phase),
        .amplitude(12),
        .out(sinus_out)
    );

    bit [7:0] out = 0;

    always_comb begin
        out = 100 + sinus_out;
    end

    bit [8:0] cnt = 0;

    always_ff @(posedge clkout_o) begin
        cnt <= cnt + 1;

        //carrier_phase <= cnt[4:0];

        clockdivide_counter <= clockdivide_counter + 51'd207992122400030;
        carrier_phase <= clockdivide_counter[ClockDivideLastBit:ClockDivideLastBit-4];

        video <= out;
        video_extra[7:6] <= out[7:6];
    end

endmodule
