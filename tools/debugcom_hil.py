import subprocess

import cv2
import numpy as np

from debugcom import DebugCom
from framebuffer import transfer_picture
from v4l import video_device, capture_still_frame

debugcom = DebugCom()


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


ntsc_burst_amplitude = 10
phase = -45 + 33


def grab_and_check_ebu75(videonorm):
    debugcom.configure_video_standard(videonorm, video_device=video_device)
    # capture_video()
    # exit(0)
    frame = capture_still_frame()[40:200, :]

    kernel = np.ones((5, 5), np.float32) / 25
    frame_avg = cv2.filter2D(frame, -1, kernel)
    white = list(np.flip(frame_avg[70, 90]))
    yellow = list(np.flip(frame_avg[70, 161]))
    cyan = list(np.flip(frame_avg[70, 244]))
    green = list(np.flip(frame_avg[70, 320]))
    purple = list(np.flip(frame_avg[70, 406]))
    red = list(np.flip(frame_avg[70, 484]))
    blue = list(np.flip(frame_avg[70, 569]))
    black = list(np.flip(frame_avg[70, 633]))

    results = [white, yellow, cyan, green, purple, red, blue, black]
    print(f"{videonorm}:")
    print(f"White {white}")
    print(f"Yellow {yellow}")
    print(f"Cyan {cyan}")
    print(f"Green {green}")
    print(f"Purple {purple}")
    print(f"Red {red}")
    print(f"Blue {blue}")
    print(f"Black {black}")

    return frame, results


debugcom.set_luma_black_level(47)
debugcom.set_video_prescalers("PAL", 125, 12, 12)
debugcom.set_video_prescalers("NTSC", 125, 14, 14)
debugcom.set_video_prescalers("SECAM", 125, 20, 20)

interlacing_mode = False
rgb_mode = True
clks_per_pixel = 9
width = 256
lines_per_field = 256
height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode, clks_per_pixel)
debugcom.configure_video_standard("PAL")
config_flags = 4  # One line mode
config_flags ^= 2  # QAM Chroma Bandpass
config_flags ^= 16  # Chroma Enable
if interlacing_mode:
    config_flags |= 32  # Interlacing Mode
if rgb_mode:
    config_flags |= 64
debugcom.memwrite_u8(6, config_flags)

imga = construct_ebu75()
transfer_picture(debugcom, imga, rgb_mode)

ntsc_frame, ntsc_result = grab_and_check_ebu75("NTSC")
pal_frame, pal_result = grab_and_check_ebu75("PAL")
secam_frame, secam_result = grab_and_check_ebu75("SECAM")

print(f"NTSC {ntsc_result}")
print(f"PAL  {pal_result}")
print(f"SECAM {secam_result}")

concat = cv2.vconcat([ntsc_frame, pal_frame, secam_frame])

git_hash = subprocess.check_output("git describe --dirty --always", shell=True).decode().strip()
print(git_hash)
cv2.imwrite(f"testresults/ebu75_{git_hash}.png", concat)

# Display the resulting frame
cv2.imshow("preview", concat)

# Waits for a user input to quit the application
cv2.waitKey(0)
cv2.destroyAllWindows()
