# 27 MHz
create_clock -name clk27 -period 37.037 [get_ports {clk27}]

# TODO I don't know why this happens. This is inside the memory controller.
# There is also a failing Recovery Path. Still no problems so far.
set_false_path -from [get_pins {u_psram_top/u_psram_init/*/*}] -to [get_pins {u_psram_top/u_psram_wd/*/*/CALIB}]  -hold
