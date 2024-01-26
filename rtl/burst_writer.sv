/*
 * Collects a whole burst of octets to write into memory.
 * Ensures efficient usage of memory controller bandwidth during larger memory writes.
 */
module burst_writer (
    input reset,
    input [7:0] data,
    input strobe,
    burst_bus_if.master mem
);

    bit [63:0] burst_data[4];
    bit [4:0] burst_data_write_address = 0;
    bit [1:0] burst_data_read_adr_d;
    bit [1:0] burst_data_read_adr_q = 0;

    bit cmd_en_d;
    bit increment_burst_addr;

    always_ff @(posedge mem.clk) begin
        if (reset) begin
            mem.addr <= 21'h500;  // TODO make configurable
            burst_data_write_address <= 0;
            burst_data_read_adr_q <= 0;
        end else begin
            if (strobe) begin
                case (burst_data_write_address[2:0])
                    0: burst_data[burst_data_write_address[4:3]][63:56] <= data;
                    1: burst_data[burst_data_write_address[4:3]][55:48] <= data;
                    2: burst_data[burst_data_write_address[4:3]][47:40] <= data;
                    3: burst_data[burst_data_write_address[4:3]][39:32] <= data;
                    4: burst_data[burst_data_write_address[4:3]][31:24] <= data;
                    5: burst_data[burst_data_write_address[4:3]][23:16] <= data;
                    6: burst_data[burst_data_write_address[4:3]][15:8] <= data;
                    7: burst_data[burst_data_write_address[4:3]][7:0] <= data;
                    default: ;
                endcase
                burst_data_write_address <= burst_data_write_address + 1;
            end

            mem.wr_data <= burst_data[burst_data_read_adr_d];
            mem.cmd_en <= cmd_en_d;
            burst_data_read_adr_q <= burst_data_read_adr_d;

            if (increment_burst_addr) mem.addr <= mem.addr + 8;
        end
    end

    always_comb begin
        mem.cmd = 1;
        cmd_en_d = 0;
        mem.data_mask = 0;
        increment_burst_addr = 0;
        burst_data_read_adr_d = burst_data_read_adr_q;

        // Received everything? Then go and write the burst
        if (strobe && burst_data_write_address == 5'b11111) begin
            cmd_en_d = 1;
        end

        // Hold cmd_en until ready
        if (mem.cmd_en && !mem.ready) cmd_en_d = 1;

        // If ready, we are writing the first word this cycle
        if (mem.cmd_en && mem.ready) begin
            burst_data_read_adr_d = burst_data_read_adr_q + 1;
            cmd_en_d = 0;
        end

        // If started, continue
        if (burst_data_read_adr_q != 0) begin
            burst_data_read_adr_d = burst_data_read_adr_q + 1;
        end

        // just provided the last word to write? Increment burst address
        if (burst_data_read_adr_q == 3) increment_burst_addr = 1;

    end
endmodule
