module debug_busmaster (
    input clk,
    input [7:0] i_com_data,
    input i_com_strobe,
    output bit [7:0] o_com_data,
    output bit o_com_strobe,

    debug_bus_if.master dbus
);

    typedef enum bit [3:0] {
        IDLE,
        READ_ADDR0,
        READ_ADDR1,
        READ_DATA,
        WRITE_ADDR0,
        WRITE_ADDR1,
        WRITE_DATA,
        WRITE_DATA_PERFORM,
        BLOCK_COUNT
    } states_e;

    states_e state = IDLE;
    states_e next_state;

    bit [7:0] remaining_bytes = 0;
    bit decrement_remaining_bytes;
    bit set_remaining_bytes;
    bit collect_adr_high;
    bit collect_adr_low;

    always_comb begin
        o_com_data = dbus.read_data;
        dbus.write_enable = 0;
        o_com_strobe = 0;
        dbus.read_enable = 0;
        next_state = state;
        decrement_remaining_bytes = 0;
        set_remaining_bytes = 0;

        collect_adr_high = 0;
        collect_adr_low = 0;

        case (state)
            IDLE: begin
                if (i_com_strobe) begin
                    if (i_com_data == "R") begin
                        next_state = READ_ADDR0;
                    end else if (i_com_data == "W") begin
                        next_state = WRITE_ADDR0;
                    end else if (i_com_data == "B") begin
                        next_state = BLOCK_COUNT;
                    end
                end
            end

            BLOCK_COUNT:
            if (i_com_strobe) begin
                next_state = WRITE_ADDR0;
                set_remaining_bytes = 1;
            end

            WRITE_ADDR0:
            if (i_com_strobe) begin
                next_state = WRITE_ADDR1;
                collect_adr_high = 1;
            end
            WRITE_ADDR1:
            if (i_com_strobe) begin
                next_state = WRITE_DATA;
                collect_adr_low = 1;
            end
            WRITE_DATA: if (i_com_strobe) next_state = WRITE_DATA_PERFORM;
            WRITE_DATA_PERFORM: begin
                dbus.write_enable = 1;
                if (dbus.ready) begin

                    if (remaining_bytes == 0) begin
                        next_state   = IDLE;
                        o_com_data   = "K";
                        o_com_strobe = 1;
                    end else begin
                        next_state = WRITE_DATA;
                        decrement_remaining_bytes = 1;
                    end

                end
            end

            READ_ADDR0:
            if (i_com_strobe) begin
                next_state = READ_ADDR1;
                collect_adr_high = 1;
            end
            READ_ADDR1:
            if (i_com_strobe) begin
                next_state = READ_DATA;
                collect_adr_low = 1;
            end
            READ_DATA: begin
                dbus.read_enable = 1;

                if (dbus.read_data_valid) begin
                    next_state   = IDLE;
                    o_com_strobe = 1;
                end
            end

            default: begin
            end
        endcase
    end

    always_ff @(posedge clk) begin

        if (set_remaining_bytes) remaining_bytes <= i_com_data;
        else if (decrement_remaining_bytes) remaining_bytes <= remaining_bytes - 1;

        if (collect_adr_high) dbus.addr[15:8] <= i_com_data;
        if (collect_adr_low) dbus.addr[7:0] <= i_com_data;
        if (i_com_strobe && state == WRITE_DATA) dbus.write_data <= i_com_data;

        state <= next_state;
    end


endmodule
