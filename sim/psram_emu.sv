
module PSRAM_Memory_Interface_HS_V2_Top (
    clk_d,
    memory_clk,
    memory_clk_p,
    pll_lock,
    rst_n,
    O_psram_ck,
    O_psram_ck_n,
    IO_psram_dq,
    IO_psram_rwds,
    O_psram_cs_n,
    O_psram_reset_n,
    wr_data,
    rd_data,
    rd_data_valid,
    addr,
    cmd,
    cmd_en,
    init_calib,
    clk_out,
    data_mask 
);
    input clk_d;
    input memory_clk;
    input memory_clk_p;
    input pll_lock;
    input rst_n;
    output [1:0] O_psram_ck;
    output [1:0] O_psram_ck_n;
    inout [15:0] IO_psram_dq;
    inout [1:0] IO_psram_rwds;
    output [1:0] O_psram_cs_n;
    output [1:0] O_psram_reset_n;
    input [63:0] wr_data;
    output bit [63:0] rd_data;
    output bit rd_data_valid=0;
    input [20:0] addr;
    input cmd;
    input cmd_en;
    output bit init_calib = 1;
    input clk_out;
    input [7:0] data_mask;


    bit [20:0] current_addr;
    int cycle = 0;
    bit active = 0;
    bit cmd_latch = 0;
    bit [7:0] memory [0:1024*1024];

    always_ff @(posedge clk_out) begin
        if (cmd_en && !active) begin

            if (cmd)
                current_addr <= addr+1;
            else
                current_addr <= addr;

            cycle <= 0;
            active<=1;
            cmd_latch <= cmd;
            if (cmd) begin
                $display("Write %0h %0h mask %0h",addr,wr_data,data_mask);
                memory[addr] <= wr_data[7:0];
            end
            else begin
                //$display("Read %0h",addr); 
            end
        end
        
        if (active)
            cycle <= cycle +1;

        if (cycle==13)begin
            active <= 0;
            //$display("Complete"); 
        end
        rd_data[7:0] <= 8'(cycle);
        
        if (cycle==8+4)rd_data_valid <= 0;
        if (cycle==8) begin
            if (!cmd_latch) begin
                rd_data_valid<=1;
                //$display("Read   %0h %0h",current_addr,memory[current_addr]); 

            end
        end

    end
endmodule
