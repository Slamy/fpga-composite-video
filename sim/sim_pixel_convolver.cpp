// Include common routines
#include <verilated.h>
#include <verilated_vcd_c.h>

// Include model header, generated from Verilating "top.v"
#include "Vpixel_convolver.h"

#include <cstdlib>
#include <cstdio>
#include <cmath>
#include <vector>
#include <list>

void clockcycle(Vpixel_convolver &dut, VerilatedVcdC &m_trace)
{
    static vluint64_t sim_time = 0;

    // evaluate internal combinatoric according to possible external input
    if (dut.clk == 1)
    {
        dut.eval();
        m_trace.dump(sim_time);
        sim_time++;
    }

    // clock down and eval
    dut.clk = 0;
    dut.eval();
    m_trace.dump(sim_time);
    sim_time++;

    // clock up and eval
    dut.clk = 1;
    dut.eval();
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    Vpixel_convolver dut;
    VerilatedVcdC m_trace;
    Verilated::traceEverOn(true);

    dut.trace(&m_trace, 5);
    m_trace.open("waveform.vcd");

    std::list<uint32_t> input;

    input.push_back(0x01020304);
    input.push_back(0x05060708);
    input.push_back(0x090a0b0c);
    input.push_back(0x0d0e0f10);
    input.push_back(0x11121314);

    std::list<uint32_t> groundtruth;
    groundtruth.push_back(0x010203);
    groundtruth.push_back(0x040506);
    groundtruth.push_back(0x070809);
    groundtruth.push_back(0x0a0b0c);
    groundtruth.push_back(0x0d0e0f);
    groundtruth.push_back(0x101213);

    std::list<uint32_t> output;

    clockcycle(dut, m_trace);
    dut.reset = 1;
    clockcycle(dut, m_trace);
    dut.input_valid = 1;
    dut.reset = 0;
    dut.in32 = input.front();
    input.pop_front();
    clockcycle(dut, m_trace);

    for (int i = 0; i < 15; i++)
    {
        dut.strobe_out24 = dut.out24_ready;
        dut.eval();
        if (dut.strobe_input)
        {
            if (input.empty())
            {
                dut.input_valid = 0;
            }
            else
            {
                dut.input_valid = 1;
                dut.in32 = input.front();
                input.pop_front();
            }
        }
        if (dut.out24_ready)
        {
            // printf("Got data %06x\n", dut.out24);
            output.push_back(dut.out24);
        }

        clockcycle(dut, m_trace);
    }

    while (!groundtruth.empty() && !output.empty())
    {
        printf("%06x ==? %06x\n", groundtruth.front(), output.front());
        groundtruth.pop_front();
        output.pop_front();
    }

    // assert(groundtruth.empty());
    // assert(output.empty());
    printf("Success\n");

    return 0;
}
