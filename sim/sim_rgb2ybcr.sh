set -e

verilator --top-module RGB2YCbCr \
    --trace --cc --assert --exe --build sim_rgb2ycbcr.cpp \
    ../rtl/*.svh ../rtl/*.sv  ../rtl/filter/*.sv  ../rtl/*.v \
    -I../rtl
    
./obj_dir/VRGB2YCbCr

# gtkwave waveform.vcd
