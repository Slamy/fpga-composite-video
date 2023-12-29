import math
import time

import numpy as np

import color
from color import yuv_real2raw, rgb2yuv
from debugcom import DebugCom


def transfer_picture(debugcom: DebugCom, testpic, rgb_mode):
    print("Conversion and Rearrangement...")
    start = time.time()
    testpic = testpic.reshape(testpic.shape[0] * testpic.shape[1], 3)
    rawdata = []

    if rgb_mode:
        for color in testpic:
            raw = [0, color[2], color[1], color[0]]
            rawdata.extend(raw)
    else:
        for color in testpic:
            y, u, v = rgb2yuv(color[2] / 255.0, color[1] / 255.0, color[0] / 255.0)
            # Apply some scaling to move YUV more closer to YCbCr
            # TODO is this the right location to do so?
            u *= 1.5
            v *= 1.5
            assert -1 < u < 1
            assert -1 < v < 1

            y_raw, u_raw, v_raw = yuv_real2raw(y, u, v)
            raw = [0, y_raw, u_raw & 0xff, v_raw & 0xff]
            rawdata.extend(raw)

    end = time.time()
    print(f"Took {end - start} seconds")

    debugcom.memwrite_s8(11, 0)

    print("Transferring...")
    start = time.time()
    rawdata_splitted = np.array_split(rawdata, math.ceil(len(rawdata) / 256))
    for chunk in rawdata_splitted:
        debugcom.blockmemwrite_u8(10, chunk)
    end = time.time()
    print(f"Took {end - start} seconds")


def framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width):
    ntsc_burst_amplitude = 15
    ntsc_burst_phase = -45 + 33 - 5
    debugcom.set_ntsc_burst(ntsc_burst_amplitude, ntsc_burst_phase)

    debugcom.configure_video_standard(videonorm)
    debugcom.set_luma_black_level(47)
    if rgb_mode:
        _, u_scale, v_scale = color.ypbpr2yuv(0, 12, 12)
        debugcom.set_video_prescalers("PAL", 125, round(u_scale), round(v_scale))
        debugcom.set_video_prescalers("NTSC", 125, round(u_scale), round(v_scale))
        _, u_scale, v_scale = color.ypbpr2yuv(0, 10, 10)
        debugcom.set_video_prescalers("SECAM", 125, round(u_scale), round(v_scale))
    else:
        debugcom.set_video_prescalers("PAL", 125, 13, 13)
        debugcom.set_video_prescalers("NTSC", 125, 13, 13)
        debugcom.set_video_prescalers("SECAM", 125, 19, 19)

    if videonorm == "NTSC":
        lines_per_field = 200 + 15  # for 60 Hz (NTSC)
    else:
        lines_per_field = 256 + 15  # for 50 Hz (PAL and SECAM)

    height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode)

    config_flags = 2 | 16  # QAM Chroma Bandpass + Chroma Enable
    if interlacing_mode:
        config_flags |= 32  # Interlacing Mode
    if rgb_mode:
        config_flags |= 64
    debugcom.memwrite_u8(6, config_flags)

    return height
