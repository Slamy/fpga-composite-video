# FPGA Composite Video Baseband Signal Encoder

This project aims to implement an encoder on FPGA basis to convert a digital YUV signal to PAL/NTSC or SECAM composite video.

## Features

* PAL and NTSC
    * Single QAM and burst generator for both.
    * Phase alternation switchable on the fly
* SECAM (not optimal due to lack of information)
    * Video pre-emphasis (not conform to standard, help from expert required)
    * HF Pre-emphasis (not conform to standard, help from expert required)
* Comes with generator for video timing.
    * Variable number of lines for 50 and 60 Hz. Configuration on the fly.
    * Interlaced and non-interlaced mode (eg. 625 line PAL or 312 line PAL)
* Comes with framebuffer device for bitmap test pictures.
    * Optional internal RGB to YCbCr conversion
* Optional delay lines to match luma and chroma filter delays.
* Uses 8 bit R2R ladder as digital analog converter.
* Uses direct digital synthesis for color carrier sine wave generation.
* Sample rates and filter coefficients configurable via Python script.
* Realtime configuration interface via UART and Python scripts.
    * Uses SciPy to generate filter coefficients
    * DAC sample rate can be changed using configure.py
* "Hardware in the Loop" testing using USB video grabber
* Verilator testbench with PNG export of raw video data

## Example results

### Picture of a parrot

These were recorded using [this USB videograbber](https://www.amazon.de/gp/product/B00EOMIDXG/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&th=1) and OpenCV.

#### Reference 

[This picture of a parrot](https://de.freepik.com/fotos-kostenlos/ein-bunter-papagei-mit-schwarzem-schnabel-und-gelben-augen_41630216.htm#query=papagei&position=0&from_view=keyword&track=sph&uuid=1d7397b5-0ced-4df3-80ee-074a10ad5ab8) was cropped to fit into 4:3 and is then resized by the Python script to fit into the framebuffer.
![Parrot reference picture](doc/parrot.jpg)

#### PAL
PAL is the clear winner here. Reproduced in interlacing mode at a resolution of 720 x 576.
It looks a little bit too bright though.

![Parrot via PAL](doc/parrot_pal.png)

#### NTSC

NTSC should show similar results to PAL but sadly doesn't. The color carrier is clearly visible. The used resolution here is 720 x 480. Also OpenCV doesn't scale the output to 4:3 and instead uses square pixels. This is more noticable with NTSC as with PAL where it is the opposite problem.

![Parrot via NTSC](doc/parrot_ntsc.png)

#### SECAM

SECAM is the problem child of this project. The preemphasis (Video and RF) doesn't work correctly, causing some horizontal artefacts in form of the popular "SECAM fire".

![Parrot via SECAM](doc/parrot_secam.png)

### EBU75 and EBU100

From top to bottom we have EBU 75% color bars for NTSC, PAL and SECAM.

![EBU75 color bards](doc/ebu75.png)

This picture clearly shows the problems with SECAM as not the color itself is transmitted but instead the color transition. The preemphasis doesn't fit the deemphasis.

![EBU100](doc/ebu100.png)

Here EBU 100% to check for edge case problems.

## Project structure

* rtl
    * composite\_video\_encoder.sv (the CVBS encoder itself)
    * top\_testpic\_generator.sv (example top level module for use with a framebuffer device)
* sim
    * sim_top.sh (execute Verilator model which produces a png file with raw video data)
* gowin
    * fpga\_pong.gprj (GOWIN EDA example project for Tang Nano 9K)
* tools
    * configure.py (calculates filter coefficients and direct digital synthesis parameters)
    * debugcom.py (interface class to access registers using the UART busmaster)
    * debugcom_hil_ebu75.py (produces EBU75 color stripes using all video norms, captures and checks them using USB video grabber)
    * debugcom_hil_parrot.py (records a reference picture for comparsion)
    * debugcom_imageviewer.py (transfers an image into the framebuffer for display)
    * vlc_\*.sh (helper functions to start VLC to show the input of the USB video grabber)

## Used devices to verify produced video signal

* Fushicai USBTV007 Video Grabber \[EasyCAP\] 1b71:3002
    * [Got it back in 2013 from Amazon](https://www.amazon.de/gp/product/B00EOMIDXG/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&th=1)
* Sony Bravia KDL-55W828B
* Commodore 1084 (PAL decoding only)
* FLUKE PM3394A

## Used Tools

* [verible-verilog-lint](https://chipsalliance.github.io/verible/)
* [verible-verilog-format](https://chipsalliance.github.io/verible/)
* [GOWIN EDA](https://www.gowinsemi.com/en/support/download_eda/)
* [ModelSim (FPGAs Standard Edition)](https://www.intel.com/content/www/us/en/software-kit/750666/modelsim-intel-fpgas-standard-edition-software-version-20-1-1.html)
* [Verilator](https://www.veripool.org/verilator/)
* VS Code with [Verilog-HDL extension](https://marketplace.visualstudio.com/items?itemName=mshr-h.VerilogHDL)
* [GTKWave](https://gtkwave.sourceforge.net/) to visualize Verilator results
* [PyCharm](https://www.jetbrains.com/de-de/pycharm/) for the Python Code

## TODOs

* NTSC chroma artefacts very present at the moment
* There might be a gamma correction missing
* Saturated artithmetics instead of overflow
* Reduce amount of used DSPs
* Ask GOWIN support for help with synthesis problems
* Fixing SECAM (might be impossible due to lack of info)
* Reduce 32 Bit Pixel format to something more compact (24 Bit)
* UART is not working during startup with higher baud rate?
* Add schematic for external video DAC circuit
* HIL verify issues, OpenCV is not very consistent when capturing video footage
    * VLC is as bright as a 1084 but seems to change brightness on the fly.
    * Auto Gain Control on VLC and 1084 but not OpenCV?
* Cleanup register map

## Motivation

* Learning more about IIR filters
* Setting again a foot into FPGA development
* Finding a smaller FPGA to build the smallest color Pong machine possible
* Old video signals are quite interesting

## Implementation on hardware

* Proven in use on Tang Nano 9K (based on GW1NR-9)
    * 48 MHz sample rate
    * GOWIN EDA used as Synthesis tool
    * Uses 41% of logic elements for whole test picture generator project
    * Should take only 20% of logic elements as about the half is spent on the PSRAM controller and the debugging interface
    * Uses 90% of DSP units

## Used Resources to create this

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
* [Style Guide for SystemVerilog Code](https://www.systemverilog.io/verification/styleguide/)
* [lowRISC Verilog Coding Style Guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md)

IIR filter design:
* https://vhdlwhiz.com/part-2-finite-impulse-response-fir-filters/
* https://ccrma.stanford.edu/~jos/fp/Transposed_Direct_Forms.html
* https://ccrma.stanford.edu/~jos/fp/Direct_Form_I.html
* https://vhdlwhiz.com/part-1-digital-filters-in-fpgas/
* https://digitalsystemdesign.in/pipeline-implementation-of-iir-low-pass-filter/

PAL/NTSC/SECAM:
* [Very elaborate document about various analog video standards](https://www.yumpu.com/en/document/read/12034920/chapter-8-ntsc-pal-and-secam-overview-deetc)

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

Modelsim:
* [Installation of modelsim on odern Linux systems](https://yoloh3.com/linux/2016/12/24/install-modelsim-in-linux/)

[Colorful parrot picture for testing](https://de.freepik.com/fotos-kostenlos/ein-bunter-papagei-mit-schwarzem-schnabel-und-gelben-augen_41630216.htm#query=papagei&position=0&from_view=keyword&track=sph&uuid=1d7397b5-0ced-4df3-80ee-074a10ad5ab8)
which is published under free license and can therefore be packaged with this project