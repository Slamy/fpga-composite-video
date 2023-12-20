module burst_bus_arbiter (
    burst_bus_if.master mem,
    burst_bus_if.slave  m1,
    burst_bus_if.slave  m2
);

    bit m1_active = 0;
    bit m2_active = 0;

    always_ff @(posedge mem.clk) begin

        if (mem.ready) begin
            if (m1.cmd_en) begin
                m1_active <= 1;
                m2_active <= 0;
            end else if (m2.cmd_en) begin
                m2_active <= 1;
                m1_active <= 0;
            end
        end
    end


    always_comb begin
        m1.rd_data_valid = 0;
        m2.rd_data_valid = 0;
        mem.cmd_en = 0;

        m1.rd_data = mem.rd_data;
        m2.rd_data = mem.rd_data;

        mem.cmd = m2.cmd;
        mem.wr_data = m2.wr_data;
        mem.addr = m2.addr;
        mem.data_mask = m2.data_mask;

        if (m1_active) begin
            m1.rd_data_valid = mem.rd_data_valid;

            mem.cmd = m1.cmd;
            mem.wr_data = m1.wr_data;
            mem.addr = m1.addr;
            mem.data_mask = m1.data_mask;

        end else if (m2_active) begin
            m2.rd_data_valid = mem.rd_data_valid;
        end


        if (mem.ready) begin
            if (m1.cmd_en) begin
                // Master 1 has a higher priority
                m1.ready = 1;
                m2.ready = 0;
                mem.cmd_en = 1;

                mem.cmd = m1.cmd;
                mem.wr_data = m1.wr_data;
                mem.addr = m1.addr;
                mem.data_mask = m1.data_mask;

            end else if (m2.cmd_en) begin
                // Master 2 has the lower priority
                m2.ready = 1;
                m1.ready = 0;
                mem.cmd_en = 1;

                mem.cmd = m2.cmd;
                mem.wr_data = m2.wr_data;
                mem.addr = m2.addr;
                mem.data_mask = m2.data_mask;
            end else begin
                m1.ready = mem.ready;
                m2.ready = mem.ready;
            end
        end else begin
            // Memory is not ready? Forward that to both
            m1.ready = 0;
            m2.ready = 0;
        end
    end

endmodule
