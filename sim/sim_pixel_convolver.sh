set -e

verilator --top-module pixel_convolver \
    --trace --cc --assert --exe --build sim_pixel_convolver.cpp \
    ../rtl/*.svh ../rtl/*.sv  ../rtl/filter/*.sv  ../rtl/*.v \
    -I../rtl
    
./obj_dir/Vpixel_convolver

# gtkwave waveform.vcd
