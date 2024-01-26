onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/dut/fb/RegisterHighAddr
add wave -noupdate /tb_top/dut/fb/newframe
add wave -noupdate /tb_top/dut/fb/newline
add wave -noupdate /tb_top/dut/fb/even_field
add wave -noupdate /tb_top/dut/fb/video_y
add wave -noupdate /tb_top/dut/fb/video_x
add wave -noupdate /tb_top/dut/fb/out
add wave -noupdate /tb_top/dut/fb/clk
add wave -noupdate /tb_top/dut/fb/width
add wave -noupdate /tb_top/dut/fb/stride
add wave -noupdate /tb_top/dut/fb/height
add wave -noupdate /tb_top/dut/fb/clk_per_pixel
add wave -noupdate /tb_top/dut/fb/window_h_start
add wave -noupdate /tb_top/dut/fb/start_addr_even_field
add wave -noupdate /tb_top/dut/fb/start_addr_odd_field
add wave -noupdate /tb_top/dut/fb/windows_v_start
add wave -noupdate /tb_top/dut/fb/debug_line_mode
add wave -noupdate /tb_top/dut/fb/rgb_mode
add wave -noupdate /tb_top/dut/fb/windows_v_start_9bit_d
add wave -noupdate /tb_top/dut/fb/windows_v_start_9bit_q
add wave -noupdate /tb_top/dut/fb/visible_window
add wave -noupdate /tb_top/dut/fb/pixel_count
add wave -noupdate /tb_top/dut/fb/pixel_x
add wave -noupdate /tb_top/dut/fb/discard_words
add wave -noupdate /tb_top/dut/fb/read_addr
add wave -noupdate /tb_top/dut/fb/line_addr
add wave -noupdate /tb_top/dut/fb/fifo
add wave -noupdate /tb_top/dut/fb/fifo_read_word
add wave -noupdate /tb_top/dut/fb/fifo_read_pos
add wave -noupdate /tb_top/dut/fb/fifo_read_pos_q
add wave -noupdate /tb_top/dut/fb/fifo_write_pos
add wave -noupdate /tb_top/dut/fb/fifo_free_entries_d
add wave -noupdate /tb_top/dut/fb/fifo_free_entries_q
add wave -noupdate /tb_top/dut/fb/pixel_data
add wave -noupdate -radix hexadecimal -expand /tb_top/dut/fb/rgb_conv_out
add wave -noupdate -radix hexadecimal -expand /tb_top/dut/fb/rgb_conv_in
add wave -noupdate /tb_top/dut/fb/restart_line
add wave -noupdate /tb_top/dut/fb/convolver_in32
add wave -noupdate /tb_top/dut/fb/convolver_strobe_input
add wave -noupdate /tb_top/dut/fb/convolver_input_valid
add wave -noupdate -radix hexadecimal /tb_top/dut/fb/convolver_out24
add wave -noupdate -radix hexadecimal /tb_top/dut/fb/convolver_out24_visible_window
add wave -noupdate /tb_top/dut/fb/convolver_out24_ready
add wave -noupdate /tb_top/dut/fb/convolver_strobe_out24
add wave -noupdate /tb_top/dut/fb/convolver_pass_through
add wave -noupdate /tb_top/dut/fb/bus/clk
add wave -noupdate -radix hexadecimal /tb_top/dut/fb/bus/wr_data
add wave -noupdate -radix hexadecimal /tb_top/dut/fb/bus/rd_data
add wave -noupdate /tb_top/dut/fb/bus/cmd
add wave -noupdate /tb_top/dut/fb/bus/cmd_en
add wave -noupdate /tb_top/dut/fb/bus/addr
add wave -noupdate /tb_top/dut/fb/bus/ready
add wave -noupdate /tb_top/dut/fb/bus/data_mask
add wave -noupdate /tb_top/dut/fb/bus/rd_data_valid
add wave -noupdate /tb_top/dut/fb/pixel_convolver/clk
add wave -noupdate /tb_top/dut/fb/pixel_convolver/reset
add wave -noupdate /tb_top/dut/fb/pixel_convolver/mode32
add wave -noupdate -radix hexadecimal /tb_top/dut/fb/pixel_convolver/in32
add wave -noupdate /tb_top/dut/fb/pixel_convolver/strobe_input
add wave -noupdate /tb_top/dut/fb/pixel_convolver/input_valid
add wave -noupdate -radix hexadecimal /tb_top/dut/fb/pixel_convolver/out24
add wave -noupdate /tb_top/dut/fb/pixel_convolver/out24_ready
add wave -noupdate /tb_top/dut/fb/pixel_convolver/strobe_out24
add wave -noupdate /tb_top/dut/fb/pixel_convolver/temp_mem
add wave -noupdate /tb_top/dut/fb/pixel_convolver/state
add wave -noupdate /tb_top/dut/fb/pixel_convolver/update_output
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1967038410 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 253
configure wave -valuecolwidth 163
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {1965666250 ps} {1967829502 ps}
