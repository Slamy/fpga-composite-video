/*
 * Implements a delay line with variable latency.
 * The maximum possible latency can be defined using parameters.
 * With the current implementation, changing the latency on the fly might cause a single maximum latency run
 * through the memory.
 * The total latency is equal to the provided input +1 as the output is buffered once to reduce propagation delays.
 */

module delayfifo #(
    parameter int BIT_WIDTH = 8,
    parameter int SIZE = 5
) (
    input clk,
    input [SIZE-1:0] latency,
    input [BIT_WIDTH-1:0] in,
    output bit [BIT_WIDTH-1:0] out
);

    // Storage memory
    bit [BIT_WIDTH-1:0] delay_mem[1<<SIZE];

    // Current index for writing and reading at the same time.
    bit [SIZE-1:0] index = 0;

    // Initialize memory with zeroes.
    initial begin
        delay_mem = '{default: '0};
        out = 0;
    end

    always_ff @(posedge clk) begin
        // Use the current memory position for writing and reading.
        delay_mem[index] <= in;
        out <= delay_mem[index];

        if (index == latency) index <= 0;
        else index <= index + 1;
    end
endmodule
