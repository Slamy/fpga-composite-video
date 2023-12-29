// Include common routines
#include <verilated.h>
#include <verilated_vcd_c.h>

// Include model header, generated from Verilating "top.v"
#include "VRGB2YCbCr.h"

#include <cstdlib>
#include <cstdio>
#include <cmath>

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    VRGB2YCbCr dut;

    printf("Checking edge cases of RGB to YCbCr conversion...\n");

    for (int i = 0; i < 16; i++)
    {
        uint8_t maxval = i & 8 ? 255 : 191;

        dut.R = i & 1 ? maxval : 0;
        dut.G = i & 2 ? maxval : 0;
        dut.B = i & 4 ? maxval : 0;

        dut.clk = 1;
        dut.eval();
        dut.clk = 0;
        dut.eval();

        dut.clk = 1;
        dut.eval();
        dut.clk = 0;
        dut.eval();

        uint8_t Y = dut.Y;
        int8_t Cb = dut.Cb;
        int8_t Cr = dut.Cr;

        // Translation matrix from https://en.wikipedia.org/wiki/YCbCr
        // Approximate 8-bit matrices for BT.601 as full swing
        float verify_Y = (77 * dut.R + 150 * dut.G + 29 * dut.B) / 256.0;
        float verify_Cb = (-43 * dut.R - 84 * dut.G + 127 * dut.B) / 256.0;
        float verify_Cr = (127 * dut.R - 106 * dut.G - 21 * dut.B) / 256.0;

        printf("%3d %3d %3d -> %3d %3d %3d == %3.1f %3.1f %3.1f ? \n", dut.R, dut.G, dut.B, Y, Cb, Cr, verify_Y, verify_Cb, verify_Cr);

        assert(fabs(Y - verify_Y) < 2.1);
        assert(fabs(Cb - verify_Cb) < 2.1);
        assert(fabs(Cr - verify_Cr) < 2.1);
    }

    printf("Success\n");

    return 0;
}
