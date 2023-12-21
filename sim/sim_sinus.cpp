// Include common routines
#include <verilated.h>
#include <verilated_vcd_c.h>

// Include model header, generated from Verilating "top.v"
#include "Vsinus.h"

#include <cstdlib>
#include <cstdio>
#include <cmath>

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vsinus dut;

    printf("Checking whole range of sine values and compare against reference...\n");
    for (int amplitude = -32; amplitude < 31; amplitude++)
    {
        printf("%3d  ", amplitude);
        for (int phase = 0; phase < 32; phase++)
        {
            dut.phase = phase;
            dut.amplitude = amplitude;
            dut.clk = 1;
            dut.eval();
            dut.clk = 0;
            dut.eval();

            dut.clk = 1;
            dut.eval();
            dut.clk = 0;
            dut.eval();

            int8_t result = dut.out;

            int8_t verify_val = round(amplitude * 2.0 * sin(phase * M_PI * 2 / 32));
            assert(result == verify_val);
            printf(" %3d", verify_val);
        }
        printf("\n");
    }

    printf("Success\n");

    return 0;
}
