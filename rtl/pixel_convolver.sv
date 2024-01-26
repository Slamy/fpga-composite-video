
/*
 * Extracts 24 bit words from a data stream consisting of 32 bit words.
 * The common factor is 24*4 = 32*3 = 96
 * For flow control, this module works pull and not push based.
 *
 * basic principle:
 * Word 0 -> 0120  the last 8 bit have to be stored temporary
 * Word 1 -> 1201  the last 16 bit have to be stored temporary
 * Word 2 -> 2012  the last 24 bit have to be stored temporary
 */
module pixel_convolver (
    input clk,
    input reset,
    input mode32,
    input [31:0] in32,  // 32 bit input data
    output bit strobe_input,  // flag to present that in32 can be changed
    input input_valid,  // indicates that in32 is allowed to be used

    output bit [23:0] out24,  // 24 bit output data
    output bit out24_ready,  // out24 is valid and strobe_out24 may be used
    input strobe_out24  // flag to indicate that the current out24 was used
);
    bit [23:0] temp_mem = 0;
    bit [1:0] state = 0;
    bit update_output;

    always_comb begin

        // If the state is <= 2 we need data from outside to continue.
        // Fetch data in case we don't have an output yet or if for output is asked.
        // For state == 3 there is no data fetching from outside.
        if (state <= 2) update_output = ((!out24_ready || strobe_out24) && input_valid);
        else update_output = strobe_out24;

        strobe_input = update_output && state <= 2;
    end

    always_ff @(posedge clk) begin

        if (reset) begin
            out24 <= 0;
            state <= 0;
            temp_mem <= 0;
            out24_ready <= 0;
        end else begin
            if (strobe_out24) out24_ready <= 0;

            if (update_output) begin
                out24_ready <= 1;

                if (mode32) begin
                    // just pass through
                    out24 <= in32[23:0];
                end else begin
                    case (state)
                        0: begin
                            // make use of the first 24 bit and store the last 8 bit
                            out24 <= in32[31:8];
                            //$display("state0 out24 %x", in32[31:8]);
                            temp_mem <= {16'b0, in32[7:0]};
                            state <= 1;
                        end
                        1: begin
                            // make use of the stored 8 bit and the first 16 bit from in32
                            // store the last 16 bit from in32
                            out24 <= {temp_mem[7:0], in32[31:16]};
                            //$display("state1 out24 %x", {temp_mem[7:0], in32[31:16]});
                            temp_mem <= {8'b0, in32[15:0]};
                            state <= 2;
                        end
                        2: begin
                            // make use of the stored 16 bit and the first 8 bit from in
                            // store the last 24 bit
                            out24 <= {temp_mem[15:0], in32[31:24]};
                            //$display("state2 out24 %x", {temp_mem[15:0], in32[31:24]});
                            temp_mem <= in32[23:0];
                            state <= 3;
                        end
                        3: begin
                            // use only the internal memory
                            out24 <= temp_mem;
                            //$display("state3 out24 %x", temp_mem);
                            state <= 0;
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                end
            end
        end

    end
endmodule
