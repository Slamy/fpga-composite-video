set -e

verilator --top-module top_testpic_generator \
    --trace --cc --assert --exe --build sim_top.cpp \
    ../rtl/*.svh ../rtl/*.sv  ../rtl/filter/*.sv  ../rtl/*.v \
    -I../rtl psram_emu.sv \
    /usr/lib/x86_64-linux-gnu/libpng.so

./obj_dir/Vtop_testpic_generator
eog raw_video.png

# gtkwave waveform.vcd
