module logic_analyzer (
    debug_bus_if.slave dbus,
    input trigger,
    input [31:0] input_data
);

    bit [31:0] mem[64];
    bit [5:0] write_position = 0;
    bit activated = 0;
    bit [31:0] read_word;
    bit [5:0] remaining = 0;

    always_comb begin
        dbus.ready = 1;

        if (dbus.addr[8]) dbus.read_data = {1'b0, write_position, activated};
        else begin
            case (dbus.addr[1:0])
                0: dbus.read_data = read_word[31:24];
                1: dbus.read_data = read_word[23:16];
                2: dbus.read_data = read_word[15:8];
                3: dbus.read_data = read_word[7:0];
                default: ;
            endcase
        end
    end

    always_ff @(posedge dbus.clk) begin
        dbus.read_data_valid <= dbus.read_enable;
        read_word <= mem[dbus.addr[7:2]];

        if (remaining != 5) begin
            mem[write_position] <= input_data;
            write_position <= write_position + 1;

            if (activated) remaining <= remaining + 1;
        end

        if (trigger) activated <= 1;
    end

endmodule
