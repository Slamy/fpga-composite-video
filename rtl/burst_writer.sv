/*
 * Collects a whole burst of octets to write into memory.
 * Ensures efficient usage of memory controller bandwidth during larger memory writes.
 */
module burst_writer (
    debug_bus_if.slave  dbus,  // debug bus slave for register access
    burst_bus_if.master mem
);
    wire chip_enable = dbus.addr[15:8] == 8'h0a;
    wire write_enable = dbus.write_enable && chip_enable;
    wire strobe = write_enable && (dbus.addr[4:0] == 4);

    bit [63:0] burst_data[4];
    bit [4:0] burst_data_write_address = 0;
    bit [1:0] burst_data_read_adr_d;
    bit [1:0] burst_data_read_adr_q = 0;

    bit cmd_en_d;
    bit increment_burst_addr;

    always_ff @(posedge mem.clk) begin

        if (write_enable) begin
            case (dbus.addr[4:0])
                // 4 first registers to reset the write address
                0: begin  // Ignore highest byte
                end
                1: mem.addr[20:16] <= dbus.write_data[4:0];
                2: mem.addr[15:8] <= dbus.write_data;
                3: begin
                    mem.addr[7:0] <= dbus.write_data;
                    // use the lowest significant byte to
                    // initialize the machine
                    burst_data_write_address <= 0;
                    burst_data_read_adr_q <= 0;
                end
                // Register 4 to feed the actual burst data
                4: begin
                    case (burst_data_write_address[2:0])
                        0: burst_data[burst_data_write_address[4:3]][63:56] <= dbus.write_data;
                        1: burst_data[burst_data_write_address[4:3]][55:48] <= dbus.write_data;
                        2: burst_data[burst_data_write_address[4:3]][47:40] <= dbus.write_data;
                        3: burst_data[burst_data_write_address[4:3]][39:32] <= dbus.write_data;
                        4: burst_data[burst_data_write_address[4:3]][31:24] <= dbus.write_data;
                        5: burst_data[burst_data_write_address[4:3]][23:16] <= dbus.write_data;
                        6: burst_data[burst_data_write_address[4:3]][15:8] <= dbus.write_data;
                        7: burst_data[burst_data_write_address[4:3]][7:0] <= dbus.write_data;
                        default: ;
                    endcase
                    burst_data_write_address <= burst_data_write_address + 1;
                end
                default: begin  // do nothing
                end
            endcase
        end

        mem.wr_data <= burst_data[burst_data_read_adr_d];
        mem.cmd_en <= cmd_en_d;
        burst_data_read_adr_q <= burst_data_read_adr_d;

        if (increment_burst_addr) mem.addr <= mem.addr + 8;
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
