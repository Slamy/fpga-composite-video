
module memory_tester (
    burst_bus_if.master mem,
    output bit error
);

    bit [7:0] cnt = 0;
    bit [7:0] state_d;
    bit [7:0] state_q = 0;
    bit [7:0] collected_words = 0;
    bit cmd = 1;
    bit increment_collected_words;
    bit [63:0] data;
    bit next_cycle;

    bit [63:0] memory_addr = 0;

    initial begin
        error = 0;
        cnt   = 0;
    end

    always_comb begin
        state_d = state_q;
        mem.cmd_en = 0;
        increment_collected_words = 0;
        next_cycle = 0;
        mem.addr = memory_addr[20:0];

        case (state_q)
            0: begin
                if (!error) begin
                    mem.cmd_en = 1;

                    if (mem.ready) begin
                        state_d = 1;

                        if (cmd) increment_collected_words = 1;
                    end
                end
            end
            25: begin
                state_d = 0;
                next_cycle = 1;
            end
            default: begin
                state_d = state_q + 1;
                if (cmd) increment_collected_words = 1;
            end
        endcase

        if (!cmd && mem.rd_data_valid) increment_collected_words = 1;

        data[63:56] = cnt + 0 + collected_words * 8;
        data[55:48] = cnt + 1 + collected_words * 8;
        data[47:40] = cnt + 2 + collected_words * 8;
        data[39:32] = cnt + 3 + collected_words * 8;
        data[31:24] = cnt + 4 + collected_words * 8;
        data[23:16] = cnt + 5 + collected_words * 8;
        data[15:8] = cnt + 6 + collected_words * 8;
        data[7:0] = cnt + 7 + collected_words * 8;

        mem.cmd = cmd;
        mem.data_mask = 0;

        mem.wr_data = data;
    end

    always_ff @(posedge mem.clk) begin

        if (increment_collected_words && cmd && state_q < 4)
            $display("Writing %0h %d %d ", data, state_d, cmd);

        state_q <= state_d;

        if (next_cycle) begin
            cmd <= !cmd;
            collected_words <= 0;

            if (!cmd) begin
                cnt <= cnt + 1;
                memory_addr <= memory_addr + 1;

            end
        end else if (mem.rd_data_valid) begin
            if (mem.rd_data != mem.wr_data) error <= 1;

            $display("Compare %d %0h %0h ", state_d, mem.rd_data, mem.wr_data);
        end


        if (increment_collected_words) collected_words <= collected_words + 1;

    end

endmodule
