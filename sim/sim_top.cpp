// Include common routines
#include <verilated.h>
#include <verilated_vcd_c.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop_testpic_generator.h"
#include "Vtop_testpic_generator___024root.h"

#include <cstdlib>
#include <cstdio>
#include <png.h>

const int width = 0x0c00U;
const int lines = 630 * 2;
const int stretch = 1;
const int height = lines * stretch;
vluint64_t sim_time = 0;

uint8_t output_image[width * height] = {0};

void write_png_file(const char *filename)
{
  int y;

  FILE *fp = fopen(filename, "wb");
  if (!fp)
    abort();

  png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png)
    abort();

  png_infop info = png_create_info_struct(png);
  if (!info)
    abort();

  if (setjmp(png_jmpbuf(png)))
    abort();

  png_init_io(png, fp);

  // Output is 8bit depth, RGBA format.
  png_set_IHDR(
      png,
      info,
      width, height,
      8,
      PNG_COLOR_TYPE_GRAY,
      PNG_INTERLACE_NONE,
      PNG_COMPRESSION_TYPE_DEFAULT,
      PNG_FILTER_TYPE_DEFAULT);
  png_write_info(png, info);

  png_bytepp row_pointers = (png_bytepp)png_malloc(png, sizeof(png_bytepp) * height);

  for (int i = 0; i < height; i++)
  {
    row_pointers[i] = &output_image[width * i];
  }

  png_write_image(png, row_pointers);
  png_write_end(png, NULL);

  free(row_pointers);

  fclose(fp);

  png_destroy_write_struct(&png, &info);
}

int main(int argc, char **argv)
{
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);

  VerilatedVcdC m_trace;
  Vtop_testpic_generator dut;

  dut.trace(&m_trace, 5);
  m_trace.open("waveform.vcd");

  dut.switch1 = 1;

  dut.rootp->top_testpic_generator__DOT__clk = 0;
  dut.eval();
  dut.rootp->top_testpic_generator__DOT__clk = 1;
  dut.eval();

  FILE *f = fopen("../tools/secam_carrier.txt", "w");

  for (int y = 0; y < lines; y++)
  {
    for (int x = 0; x < width; x++)
    {
      dut.rootp->top_testpic_generator__DOT__clk = 0;
      dut.eval();
      m_trace.dump(sim_time);
      sim_time++;

      dut.rootp->top_testpic_generator__DOT__clk = 1;
      dut.eval();
      m_trace.dump(sim_time);
      sim_time++;

      for (int j = 0; j < stretch; j++)
      {
        assert((y * width * stretch + width * j + x) < (width * height));

        // output_image[y * width * stretch + width * j + x] = 127 + dut.rootp->top_testpic_generator__DOT__chroma;
        output_image[y * width * stretch + width * j + x] = dut.video;
      }

#if 1
      if (y == 40)
      {
        // fprintf(f, "%d %d %d\n", val1, val2, val3);

        int16_t val1 = dut.rootp->top_testpic_generator__DOT__cvbs__DOT__secam__DOT__carrier_period_emphasis2;
        uint16_t val2 = dut.rootp->top_testpic_generator__DOT__cvbs__DOT__secam__DOT__enabled_amplitude;
        uint16_t val3 = dut.rootp->top_testpic_generator__DOT__cvbs__DOT__secam__DOT__enabled_amplitude_filtered;

        val1 <<= 7;
        val1 >>= 7;
        if (dut.rootp->top_testpic_generator__DOT__video_timing0__DOT__visible_window_q)
          fprintf(f, "%d %d %d\n", val1, val2, val3);

        // fprintf(f, "%d\n", val1);
      }
#endif
    }
  }
  fclose(f);

  write_png_file("raw_video.png");

  return 0;
}
