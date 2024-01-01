import math

import color
from debugcom import DebugCom
from debugcom_hil_ebu75 import construct_ebu75, construct_ebu
from framebuffer import transfer_picture
from getch import getch

debugcom = DebugCom()


def interactive_configurator():
    ntsc_burst_amplitude = 10
    ntsc_burst_phase = -45 + 33
    luma_black_level = 47
    luma_scaler = 125
    luma_delay = 0

    config_flags = 4  # One line mode
    config_flags ^= 2  # QAM Chroma Bandpass
    config_flags ^= 16  # Chroma Enable

    u_delay = 0
    v_delay = 0

    while True:
        ntsc_burst_v = -round(ntsc_burst_amplitude * math.sin(math.radians(ntsc_burst_phase)))
        ntsc_burst_u = -round(ntsc_burst_amplitude * math.cos(math.radians(ntsc_burst_phase)))
        debugcom.set_delay_lines(luma_delay, u_delay, v_delay)
        debugcom.set_luma_black_level(luma_black_level)
        debugcom.memwrite_u8(6, config_flags)
        debugcom.set_ntsc_burst_uv(ntsc_burst_u, ntsc_burst_v)

        print(ntsc_burst_amplitude, ntsc_burst_phase, ntsc_burst_u, ntsc_burst_v, luma_black_level, luma_scaler)

        char = getch()
        if char == "q":
            exit(0)
        if char == "w":
            ntsc_burst_amplitude += 1
        if char == "s":
            ntsc_burst_amplitude -= 1
        if char == 'e':
            ntsc_burst_phase += 1
            if ntsc_burst_phase > 180:
                ntsc_burst_phase -= 360
        if char == 'd':
            ntsc_burst_phase -= 1
            if ntsc_burst_phase < -180:
                ntsc_burst_phase += 360
        if char == 'r':
            luma_black_level += 1
        if char == 'f':
            luma_black_level -= 1
        if char == 't':
            luma_scaler += 1
        if char == 'g':
            luma_scaler -= 1
        if char == 'z':
            config_flags ^= 1  # Chroma Lowpass
            print(config_flags)
        if char == 'u':
            config_flags ^= 2  # Chroma Bandpass
            print(config_flags)
        if char == 'h':
            config_flags ^= 8  # EBU75
            print(config_flags)

        if char == "+":
            luma_delay += 1
            print(f"luma_delay {luma_delay}")
        if char == "-":
            luma_delay -= 1
            print(f"luma_delay {luma_delay}")

        if char == "2":
            u_delay += 1
            print(f"u_delay {u_delay}")
        if char == "1":
            u_delay -= 1
            print(f"u_delay {u_delay}")

        if char == "4":
            v_delay += 1
            print(f"v_delay {v_delay}")
        if char == "3":
            v_delay -= 1
            print(f"v_delay {v_delay}")

        if char == 'p':
            debugcom.configure_video_standard("PAL")
        if char == 'n':
            debugcom.configure_video_standard("NTSC")

debugcom.set_luma_black_level(47)
_, u_scale, v_scale = color.ypbpr2yuv(0, 12, 12)
debugcom.set_video_prescalers("PAL", 125, round(u_scale), round(v_scale))
debugcom.set_video_prescalers("NTSC", 125, round(u_scale), round(v_scale))
_, u_scale, v_scale = color.ypbpr2yuv(0, 11, 10)
debugcom.set_video_prescalers("SECAM", 125, round(u_scale), round(v_scale))

interlacing_mode = False
rgb_mode = False
clks_per_pixel = 9
width = 256
lines_per_field = 256
height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode, clks_per_pixel)

debugcom.configure_video_standard("SECAM")
imga = construct_ebu75()
transfer_picture(debugcom, imga, rgb_mode)
interactive_configurator()
