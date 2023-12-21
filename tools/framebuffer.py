import math
import time

import numpy as np

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
            u *= 2
            v *= 1.5
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
