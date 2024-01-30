import math
import time

import numpy as np

from color import rgb2ycbcr
from debugcom import DebugCom
from defaults import set_default_scalers


def transfer_picture(debugcom: DebugCom, testpic, rgb_mode, padbyte):
    print("Conversion and Rearrangement...")
    start = time.time()
    testpic = testpic.reshape(testpic.shape[0] * testpic.shape[1], 3)
    rawdata = []

    if rgb_mode:
        for pixel in testpic:
            if padbyte:
                raw = [0, pixel[2], pixel[1], pixel[0]]
            else:
                raw = [pixel[2], pixel[1], pixel[0]]

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

            if padbyte:
                raw = [0, y_raw, u_raw & 0xff, v_raw & 0xff]
            else:
                raw = [y_raw, u_raw & 0xff, v_raw & 0xff]

            rawdata.extend(raw)

    end = time.time()
    print(f"Took {end - start} seconds")

    debugcom.memwrite_u32be(0xa00, 0x200)

    # 256 byte is the maximum number of bytes we can currently transfer in one block transfer.
    # Always transfer full blocks to ensure that every transferred block is also burst written
    chunksize = 256
    number_of_chunks = math.ceil(len(rawdata) / chunksize)
    expected_number_of_bytes = number_of_chunks * chunksize
    # Fill the last chunk
    rawdata += [0] * (expected_number_of_bytes - len(rawdata))

    print(f"Transferring...")
    start = time.time()
    rawdata_splitted = np.array_split(rawdata, number_of_chunks)
    for chunk in rawdata_splitted:
        assert (len(chunk) == 256), "Something went wrong! Chunksize not full block!"
        debugcom.blockmemwrite_u8(0xa04, chunk)
    end = time.time()

    print(f"Took {end - start} seconds")


def framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width, bits_per_pixel, overscan=0):
    debugcom.configure_video_standard(videonorm)
    set_default_scalers(debugcom)

    if videonorm == "NTSC":
        lines_per_field = 200 + overscan  # for 60 Hz (NTSC)
    else:
        lines_per_field = 256 + overscan  # for 50 Hz (PAL and SECAM)

    height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode, bits_per_pixel)

    debugcom.enable_interlacing(interlacing_mode)
    debugcom.enable_rgb_mode(rgb_mode)

    return height
