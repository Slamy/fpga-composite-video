import math

import cv2
import numpy as np
import time
from color import yuv_real2raw, rgb2yuv
from debugcom import DebugCom

def transfer_picture(debugcom: DebugCom, testpic):
    print("Conversion to YUV...")
    start = time.time()
    testpic = testpic.reshape(testpic.shape[0] * testpic.shape[1], 3)
    print(testpic.shape)

    rawyuv = []
    for color in testpic:
        r, g, b = rgb2yuv(color[2] / 255.0, color[1] / 255.0, color[0] / 255.0)
        y_raw, u_raw, v_raw = yuv_real2raw(r, g, b)
        raw = [0, y_raw, u_raw & 0xff, v_raw & 0xff]
        rawyuv.extend(raw)

    end = time.time()
    print(f"Took {end - start} seconds")

    debugcom.memwrite_s8(11, 0)

    print("Transferring...")
    start = time.time()
    rawyuv = np.array_split(rawyuv, math.ceil(len(rawyuv) / 256))
    for chunk in rawyuv:
        debugcom.blockmemwrite_u8(10, chunk)
    end = time.time()
    print(f"Took {end - start} seconds")




