import math
import time

import numpy as np

from color import rgb2ycbcr, ypbpr2yuv
from debugcom import DebugCom


def transfer_picture(debugcom: DebugCom, testpic, rgb_mode):
    print("Conversion and Rearrangement...")
    start = time.time()
    testpic = testpic.reshape(testpic.shape[0] * testpic.shape[1], 3)
    rawdata = []

    if rgb_mode:
        for pixel in testpic:
            raw = [0, pixel[2], pixel[1], pixel[0]]
            rawdata.extend(raw)
    else:
        for pixel in testpic:
            y_raw, u_raw, v_raw = rgb2ycbcr(pixel[2], pixel[1], pixel[0])

            # Limit to range of two complements
            if u_raw == 128:
                u_raw = 127
            if v_raw == 128:
                v_raw = 127

            assert y_raw <= 255
            assert -127 <= u_raw <= 127, f"u_raw {u_raw}"
            assert -127 <= v_raw <= 127, f"v_raw {v_raw}"
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
        _, u_scale, v_scale = ypbpr2yuv(0, 12, 12)
        debugcom.set_video_prescalers("PAL", 125, round(u_scale), round(v_scale))
        debugcom.set_video_prescalers("NTSC", 125, round(u_scale), round(v_scale))
        _, u_scale, v_scale = ypbpr2yuv(0, 11, 10)
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
