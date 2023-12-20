# FPGA Composite Video Baseband Signal Encoder

This project aims to implement an encoder on FPGA basis to convert a digital YUV signal to PAL/NTSC or SECAM composite video.

## Features

* Generator for video timing
    * Variable number of lines for 50 and 60 Hz. switchable on the fly.
* PAL and NTSC
    * Single QAM module for both.
    * Phase alternation switchable on the fly
* SECAM (not optimal due to lack of information)
    * Video pre-emphasis (not conform to standard, help from expert required)
    * HF Pre-emphasis (not conform to standard, help from expert required)
* Comes with framebuffer device for actual test pictures
* Configurable delay lines to match luma and chroma filter delays
* Uses 8 bit resistor ladder as digital analog converter
* Sample rates and filter coefficients configurable via Python script.
* Configuration interface via UART and Python scripts
    * Uses SciPy to generate filter coefficients
* "Hardware in the loop" testing using USB video grabber
* Verilator testbench with PNG export of raw video data

## Used Tools

* [verible-verilog-lint](https://chipsalliance.github.io/verible/)
* [verible-verilog-format](https://chipsalliance.github.io/verible/)
* GOWIN EDA
* [ModelSim (FPGAs Standard Edition)](https://www.intel.com/content/www/us/en/software-kit/750666/modelsim-intel-fpgas-standard-edition-software-version-20-1-1.html)
* [Verilator](https://www.veripool.org/verilator/)
* VSCode with [Verilog-HDL extension](https://marketplace.visualstudio.com/items?itemName=mshr-h.VerilogHDL)

## TODOs

* Interlaced video mode
* NTSC chroma artefacts very present at the moment
* Reduce amount of used DSPs
* Ask GOWIN support for help with synthesis problems
* Fixing SECAM (might be impossible)
* Support for RGB color space in framebuffer device
* Reduce 32 Bit Pixel format to something more compact
* UART is not working during startup with higher baud rate?
* Add schematic for external video DAC

## Motivation

* Learning more about IIR filters
* Setting again a foot into FPGA development
* Finding a smaller FPGA to build the smallest color Pong machine possible
* Old video signals are quite interesting

## Implementation on hardware

* Proven in use on Tang Nano 9K (based on GW1NR-9)
    * 48 MHz sample rate
    * GOWIN EDA used as Synthesis tool
    * Uses 38% of logic elements
    * Uses 90% of DSP units

## Used devices to verify produced video signal

* Fushicai USBTV007 Video Grabber \[EasyCAP\] 1b71:3002
    * [Got it back in 2013 from Amazon](https://www.amazon.de/gp/product/B00EOMIDXG/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&th=1)
* Sony Bravia KDL-55W828B
* Commodore 1084 (PAL and PAL60 decoding only)

## Used Resources to create this

[Parrot picture for testing](https://de.freepik.com/fotos-kostenlos/ein-bunter-papagei-mit-schwarzem-schnabel-und-gelben-augen_41630216.htm#query=papagei&position=0&from_view=keyword&track=sph&uuid=1d7397b5-0ced-4df3-80ee-074a10ad5ab8)

Modelsim:
* [Installation of modelsim on odern Linux systems](https://yoloh3.com/linux/2016/12/24/install-modelsim-in-linux/)

PSRAM:
* https://github.com/zf3/psram-tang-nano-9k.git
* https://github.com/edanuff/psram-tang-nano-9k.git
* https://github.com/dominicbeesley/psram-tang-nano-9k.git

YUV Framebuffer formats:
* https://www.flir.de/support-center/iis/machine-vision/knowledge-base/understanding-yuv-data-formats/
* http://www.chiark.greenend.org.uk/doc/linux-doc-2.6.32/html/media/ch02.html
* [Efficient RGB 2 YCbCr](https://sistenix.com/rgb2ycbcr.html)

System Verilog:
* https://verificationguide.com/systemverilog/systemverilog-parameters-and-define/
* https://www.systemverilog.io/verification/styleguide/
* https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md

IIR filter design:
* https://vhdlwhiz.com/part-2-finite-impulse-response-fir-filters/
* https://ccrma.stanford.edu/~jos/fp/Transposed_Direct_Forms.html
* https://ccrma.stanford.edu/~jos/fp/Direct_Form_I.html
* https://vhdlwhiz.com/part-1-digital-filters-in-fpgas/
* https://digitalsystemdesign.in/pipeline-implementation-of-iir-low-pass-filter/

PAL/NTSC/SECAM:
* [Elaborate document about analog video standards](https://www.yumpu.com/en/document/read/12034920/chapter-8-ntsc-pal-and-secam-overview-deetc)

PAL:
* [Video timing article by Martin Hinner](http://martin.hinner.info/vga/pal.html)
* [video timing article by Retroleum](http://blog.retroleum.co.uk/electronics-articles/pal-tv-timing-and-voltages/)
* [Circuits for modulation/demodulation](https://www.elektroniktutor.de/geraetetechnik/ffs_empf.html)
* [Reference values for test pictures](https://www.elektroniktutor.de/geraetetechnik/pal_ffs.html#farbdiff)
* [RGB to YUV concersion](https://de.wikipedia.org/wiki/YUV-Farbmodell)

NTSC:
* https://en.wikipedia.org/wiki/SMPTE_color_bars
* [Wikipedia on color burst](https://en.wikipedia.org/wiki/Colorburst)
* https://electronics.stackexchange.com/questions/428353/how-to-interpret-this-ntsc-color-waveform
* https://en.wikipedia.org/wiki/YIQ
* https://www.researchgate.net/figure/YIQ-representation-16_fig10_266462481
* http://hima-tubusi.blogspot.com/2019/11/yiqyuv.html

SECAM:
* [Wikipedia Article](https://de.wikipedia.org/wiki/SECAM)
* [Very old article on the inner workings and formulas](http://web.archive.org/web/20160502235024/http://www.pembers.freeserve.co.uk/World-TV-Standards/Colour-Standards.html)
* [Test pictures and their signaling](http://web.archive.org/web/20160409090425/http://www.pembers.freeserve.co.uk/Test-Cards/Test-Card-Technical.html#Bars)


DAC:
* [R2R resistor ladder calculator](http://www.aaabbb.de/JDAC/DAC_R2R_network_calculation_en.php)
