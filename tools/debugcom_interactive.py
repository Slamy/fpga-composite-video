import math

from debugcom import DebugCom
from getch import getch

debugcom = DebugCom()
import numpy as np

from color import yuv_real2raw, rgb2yuv


def transfer_picture(testpic):
    testpic = testpic.reshape(testpic.shape[0] * testpic.shape[1], 3)
    print(testpic.shape)

    rawyuv = []
    for color in testpic:
        r, g, b = rgb2yuv(color[2] / 255.0, color[1] / 255.0, color[0] / 255.0)
        y_raw, u_raw, v_raw = yuv_real2raw(r, g, b)

        raw = [0, y_raw, u_raw & 0xff, v_raw & 0xff]
        rawyuv.extend(raw)

    debugcom.memwrite_s8(11, 0)
    rawyuv = np.array_split(rawyuv, len(rawyuv) / 256)
    for chunk in rawyuv:
        debugcom.blockmemwrite_u8(10, chunk)


def construct_ebu75():
    imga = np.zeros([2, 256, 3], dtype=np.uint8)

    l = 191
    y = 0
    imga[y, 32 * 0:32 * 1] = [l, l, l]
    imga[y, 32 * 1:32 * 2] = [0, l, l]
    imga[y, 32 * 2:32 * 3] = [l, l, 0]
    imga[y, 32 * 3:32 * 4] = [0, l, 0]
    imga[y, 32 * 4:32 * 5] = [l, 0, l]
    imga[y, 32 * 5:32 * 6] = [0, 0, l]
    imga[y, 32 * 6:32 * 7] = [l, 0, 0]
    imga[y, 32 * 7:32 * 8] = [0, 0, 0]

    return imga


def interactive_configurator():
    ntsc_burst_amplitude = 10
    phase = -45 + 33
    luma_black_level = 47
    luma_scaler = 135
    luma_delay = 0
    debug_configuration = 4 | 2
    u_delay = 0
    v_delay = 0

    while True:
        ntsc_burst_v = -round(ntsc_burst_amplitude * math.sin(math.radians(phase)))
        ntsc_burst_u = -round(ntsc_burst_amplitude * math.cos(math.radians(phase)))
        debugcom.memwrite_s8(0, luma_delay)
        debugcom.memwrite_u8(6, debug_configuration)
        debugcom.memwrite_s8(7, ntsc_burst_u)
        debugcom.memwrite_s8(8, ntsc_burst_v)
        debugcom.memwrite_u8(9, luma_black_level)
        debugcom.memwrite_s8(12, u_delay)
        debugcom.memwrite_s8(13, v_delay)

        debugcom.memwrite_u8(0x0200 + 4 * 0 + 0, luma_scaler)
        debugcom.memwrite_u8(0x0200 + 4 * 0 + 1, luma_scaler)
        debugcom.memwrite_u8(0x0200 + 4 * 0 + 1, luma_scaler)

        print(ntsc_burst_amplitude, phase, ntsc_burst_u, ntsc_burst_v, luma_black_level, luma_scaler)

        char = getch()
        if char == "q":
            exit(0)
        if char == "w":
            ntsc_burst_amplitude += 1
        if char == "s":
            ntsc_burst_amplitude -= 1
        if char == 'e':
            phase += 1
            if phase > 180:
                phase -= 360
        if char == 'd':
            phase -= 1
            if phase < -180:
                phase += 360
        if char == 'r':
            luma_black_level += 1
        if char == 'f':
            luma_black_level -= 1
        if char == 't':
            luma_scaler += 1
        if char == 'g':
            luma_scaler -= 1
        if char == 'z':
            debug_configuration ^= 1  # Chroma Lowpass
            print(debug_configuration)
        if char == 'u':
            debug_configuration ^= 2  # Chroma Bandpass
            print(debug_configuration)
        if char == 'h':
            debug_configuration ^= 8  # EBU75
            print(debug_configuration)

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


# PAL
debugcom.memwrite_u8(0x0200 + 4 * 0 + 0, 135)
debugcom.memwrite_u8(0x0200 + 4 * 1 + 0, 25)
debugcom.memwrite_u8(0x0200 + 4 * 2 + 0, 25)
# NTSC
debugcom.memwrite_u8(0x0200 + 4 + 1, 25)
debugcom.memwrite_u8(0x0200 + 4 * 2 + 1, 25)
# SECAM
debugcom.memwrite_u8(0x0200 + 4 + 2, 35)
debugcom.memwrite_u8(0x0200 + 4 * 2 + 2, 35)

debugcom.configure_video_standard("PAL")
imga = construct_ebu75()
transfer_picture(imga)
interactive_configurator()
