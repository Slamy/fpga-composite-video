`timescale 1ns / 1ps

module tb_top;

    logic clk27 = 0;
    logic switch1 = 0;
    logic sys_resetn = 0;
    logic [7:0] video;
    logic [7:6] video_extra;
    logic uart_rx = 1;
    logic uart_tx;

    wire O_psram_ck;
    wire O_psram_ck_n;
    wire IO_psram_rwds;
    wire [7:0] IO_psram_dq;
    wire O_psram_reset_n;
    wire O_psram_cs_n;

    wire sec_O_psram_ck;
    wire sec_O_psram_ck_n;
    wire sec_IO_psram_rwds;
    wire [7:0] sec_IO_psram_dq;
    wire sec_O_psram_reset_n;
    wire sec_O_psram_cs_n;
    wire [5:0] led;

   top_testpic_generator dut(
        .clk27,
        .switch1,
        .led,
        .sys_resetn,
        .video,
        .video_extra,
        .uart_rx,
        .uart_tx,
        .O_psram_ck({sec_O_psram_ck, O_psram_ck}),
        .O_psram_ck_n({sec_O_psram_ck_n, O_psram_ck_n}),
        .IO_psram_rwds({sec_IO_psram_rwds, IO_psram_rwds}),
        .IO_psram_dq({sec_IO_psram_dq, IO_psram_dq}),
        .O_psram_reset_n({sec_O_psram_reset_n, O_psram_reset_n}),
        .O_psram_cs_n({sec_O_psram_cs_n, O_psram_cs_n})
    );

    //always #10 dut.clk = !dut.clk;
    //always #10 clk27 = !clk27;

    initial begin
        force dut.clk = 0;
        #5 forever #10 force dut.clk = !dut.clk;
    end

    //assign IO_psram_dq = {weak0,weak0,weak0,weak0,weak1,weak0,weak0,weak0};
    assign (pull1, pull0) IO_psram_dq = 8'b11000011;

    initial begin

        //dut.clk   = 0;
        //dut.clk_p = 0;
        //force dut.fb.fifo_read_word = 64'h8040201080402010;
	//force dut.ebu75_active = 1;

        //#100 sys_resetn = 1;
        //force dut.calib = 1;

        /*
	for ( int i = 0; i < 32 ; i++) begin
	 @(posedge dut.clk) force dut.bw_data = 1; force dut.bw_strobe = 1;
	@(posedge dut.clk) force dut.bw_data = 1; force dut.bw_strobe = 0;
	end
*/
        /*
        @(negedge dut.busy) @(posedge dut.clk) dut.i_com_data = "W";
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_data = 00;
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_data = 04;
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_data = 42;
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_strobe = 0;

        #300 @(posedge dut.clk) dut.i_com_data = "R";
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_data = 00;
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_data = 04;
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_strobe = 0;


        #2000 @(posedge dut.clk) dut.i_com_data = "R";
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_data = 00;
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_data = 04;
        dut.i_com_strobe = 1;
        @(posedge dut.clk) dut.i_com_strobe = 0;
	*/

    end
endmodule
