module delayfifo32 #(
    parameter int BIT_WIDTH = 8
) (
    input clk,
    input [4:0] latency,
    input [BIT_WIDTH-1:0] in,
    output bit [BIT_WIDTH-1:0] out
);
    bit [BIT_WIDTH-1:0] delay_mem[32];
    bit [4:0] index = 0;

    initial begin
        delay_mem = '{default: '0};
        out = 0;
    end

    always_ff @(posedge clk) begin
        delay_mem[index] <= in;
        out <= delay_mem[index];

        if (index == latency) index <= 0;
        else index <= index + 1;
    end
endmodule
