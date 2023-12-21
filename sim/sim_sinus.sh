set -e

verilator --top-module sinus \
    --trace --cc --assert --exe --build sim_sinus.cpp \
    ../rtl/*.svh ../rtl/*.sv  ../rtl/filter/*.sv  ../rtl/*.v \
    -I../rtl
    
./obj_dir/Vsinus

# gtkwave waveform.vcd
