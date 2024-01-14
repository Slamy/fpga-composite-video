
package common;
    typedef enum bit {
        MODE_50HZ,
        MODE_60HZ
    } vertical_frequency_e;

    typedef enum bit [1:0] {
        PAL,
        NTSC,
        SECAM
    } video_standard_e;
endpackage

// Burst based memory port suitable for PSRAM_HS_V2 IP core
interface burst_bus_if (
    input clk
);
    bit [63:0] wr_data;
    bit [63:0] rd_data;
    bit        cmd;
    bit        cmd_en;
    bit [20:0] addr;
    bit        ready;
    bit [ 7:0] data_mask;
    bit        rd_data_valid;

    modport master(
        input clk, rd_data, ready, rd_data_valid,
        output addr, cmd, cmd_en, wr_data, data_mask
    );

    modport slave(
        input clk, addr, cmd, cmd_en, wr_data, data_mask,
        output rd_data, ready, rd_data_valid
    );

endinterface

// Digital RGB signal with 8 bit depth
typedef struct {
    bit [7:0] r;
    bit [7:0] g;
    bit [7:0] b;
} rgb_t;

// YUV signals according to PAL analog scaling
typedef struct {
    bit [7:0] y;
    bit signed [7:0] u;
    bit signed [7:0] v;
} yuv_t;

// YCbCr but as signed
// Usually the "neutral" of Cb and Cr is 128 but here it is 0
// with a swing of -127 to 127
typedef struct {
    bit [7:0] y;
    bit signed [7:0] cb;
    bit signed [7:0] cr;
} ycbcr_t;


// 16 Bit, single cycle bus
interface debug_bus_if (
    input clk
);
    bit [15:0] addr;
    bit        write_enable;
    bit        read_enable;
    bit        read_data_valid;
    bit [ 7:0] read_data;
    bit [ 7:0] write_data;
    bit        ready;

    modport master(
        input clk, read_data_valid, read_data, ready,
        output addr, write_enable, read_enable, write_data
    );

    modport slave(
        input clk, addr, write_enable, read_enable, write_data,
        output read_data_valid, read_data, ready
    );
endinterface
