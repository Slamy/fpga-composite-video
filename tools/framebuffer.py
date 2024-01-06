import math
import time

import numpy as np

from color import rgb2ycbcr
from debugcom import DebugCom
from defaults import set_default_scalers


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


def framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width, overscan=0):
    debugcom.configure_video_standard(videonorm)
    set_default_scalers(debugcom)

    if videonorm == "NTSC":
        lines_per_field = 200 + overscan  # for 60 Hz (NTSC)
    else:
        lines_per_field = 256 + overscan  # for 50 Hz (PAL and SECAM)

    height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode)

    debugcom.enable_interlacing(interlacing_mode)
    debugcom.enable_rgb_mode(rgb_mode)

    return height
