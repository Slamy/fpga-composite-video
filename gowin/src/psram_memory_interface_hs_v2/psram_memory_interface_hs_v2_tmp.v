//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta-6
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Thu Nov 16 19:13:05 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	PSRAM_Memory_Interface_HS_V2_Top your_instance_name(
		.clk_d(clk_d_i), //input clk_d
		.memory_clk(memory_clk_i), //input memory_clk
		.memory_clk_p(memory_clk_p_i), //input memory_clk_p
		.pll_lock(pll_lock_i), //input pll_lock
		.rst_n(rst_n_i), //input rst_n
		.O_psram_ck(O_psram_ck_o), //output [1:0] O_psram_ck
		.O_psram_ck_n(O_psram_ck_n_o), //output [1:0] O_psram_ck_n
		.IO_psram_dq(IO_psram_dq_io), //inout [15:0] IO_psram_dq
		.IO_psram_rwds(IO_psram_rwds_io), //inout [1:0] IO_psram_rwds
		.O_psram_cs_n(O_psram_cs_n_o), //output [1:0] O_psram_cs_n
		.O_psram_reset_n(O_psram_reset_n_o), //output [1:0] O_psram_reset_n
		.wr_data(wr_data_i), //input [63:0] wr_data
		.rd_data(rd_data_o), //output [63:0] rd_data
		.rd_data_valid(rd_data_valid_o), //output rd_data_valid
		.addr(addr_i), //input [20:0] addr
		.cmd(cmd_i), //input cmd
		.cmd_en(cmd_en_i), //input cmd_en
		.init_calib(init_calib_o), //output init_calib
		.clk_out(clk_out_o), //output clk_out
		.data_mask(data_mask_i) //input [7:0] data_mask
	);

//--------Copy end-------------------
