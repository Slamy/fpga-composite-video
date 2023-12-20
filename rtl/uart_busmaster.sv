module uart_busmaster (
    input  clk,
    input  uart_rx,
    output uart_tx,

    debug_bus_if.master dbus
);

    bit [7:0] o_com_data  /* verilator public_flat_rw */;
    bit [7:0] i_com_data  /* verilator public_flat_rw */;
    bit i_com_strobe  /* verilator public_flat_rw */;
    bit o_com_strobe  /* verilator public_flat_rw */;

`ifndef MODEL_TECH
`ifndef VERILATOR
    uart_rx #(
        .CLK_FRE  (48),
        .BAUD_RATE(3000000)
    ) uart_rx_inst (
        .clk          (clk),
        .rst_n        (1'b1),
        .rx_data      (i_com_data),
        .rx_data_valid(i_com_strobe),
        .rx_data_ready(1'b1),
        .rx_pin       (uart_rx)
    );

    uart_tx #(
        .CLK_FRE  (48),
        .BAUD_RATE(3000000)
    ) uart_tx_inst (
        .clk          (clk),
        .rst_n        (1'b1),
        .tx_data      (o_com_data),
        .tx_data_valid(o_com_strobe),
        .tx_data_ready(),
        .tx_pin       (uart_tx)
    );
`endif
`endif

    debug_busmaster db (
        .clk,
        .i_com_data  (i_com_data),
        .i_com_strobe(i_com_strobe),
        .o_com_data  (o_com_data),
        .o_com_strobe(o_com_strobe),

        .dbus
    );

endmodule
