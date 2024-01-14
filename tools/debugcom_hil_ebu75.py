import cv2
import numpy as np

import color
from debugcom import DebugCom
from defaults import set_default_scalers
from framebuffer import transfer_picture
from v4l import video_device, capture_still_frame

debugcom = DebugCom()


def construct_ebu(l):
    imga = np.zeros([2, 256, 3], dtype=np.uint8)

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


def construct_ebu75():
    return construct_ebu(191)


def construct_ebu100():
    return construct_ebu(255)


def grab_and_check_ebu75(videonorm):
    debugcom.configure_video_standard(videonorm, video_device=video_device)
    frame = capture_still_frame()[50:200, :]

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
    # R G B

    results = [white, yellow, cyan, green, purple, red, blue, black]
    print(f"{videonorm}:")
    print(f"White {white}")
    print(f"Yellow {yellow}")
    print(f"Cyan {cyan} {color.rgb2ycbcr(cyan[0], cyan[1], cyan[2])}")
    print(f"Green {green} {color.rgb2ycbcr(green[0], green[1], green[2])}")
    print(f"Purple {purple} {color.rgb2ycbcr(purple[0], purple[1], purple[2])}")
    print(f"Red {red}")
    print(f"Blue {blue}")
    print(f"Black {black}")

    return frame, results


def test_colorbars():
    set_default_scalers(debugcom)
    interlacing_mode = False
    rgb_mode = False
    clks_per_pixel = 9
    width = 256
    lines_per_field = 256
    height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode, clks_per_pixel)
    debugcom.enable_single_line_mode(True)
    debugcom.enable_qam_chroma_bandpass(True)
    debugcom.enable_chroma_output(True)
    debugcom.enable_chroma_lowpass(False)
    debugcom.enable_interlacing(interlacing_mode)
    debugcom.enable_rgb_mode(rgb_mode)

    print("----- 100% -----")
    imga = construct_ebu100()
    transfer_picture(debugcom, imga, rgb_mode)
    ntsc_frame, ntsc_result_100 = grab_and_check_ebu75("NTSC")
    pal_frame, pal_result_100 = grab_and_check_ebu75("PAL")
    debugcom.set_delay_lines(0, 0, 3)
    secam_frame, secam_result_100 = grab_and_check_ebu75("SECAM")
    debugcom.set_delay_lines(0, 0, 0)
    ebu100concat = cv2.vconcat([ntsc_frame, pal_frame, secam_frame])
    print("-----  75% -----")
    imga = construct_ebu75()
    transfer_picture(debugcom, imga, rgb_mode)
    ntsc_frame, ntsc_result_75 = grab_and_check_ebu75("NTSC")
    pal_frame, pal_result_75 = grab_and_check_ebu75("PAL")
    debugcom.set_delay_lines(0, 0, 3)
    secam_frame, secam_result_75 = grab_and_check_ebu75("SECAM")
    debugcom.set_delay_lines(0, 0, 0)
    ebu75concat = cv2.vconcat([ntsc_frame, pal_frame, secam_frame])

    print("-----  75% -----")
    print(f"NTSC  {ntsc_result_75}")
    print(f"PAL   {pal_result_75}")
    print(f"SECAM {secam_result_75}")
    print("----- 100% -----")
    print(f"NTSC  {ntsc_result_100}")
    print(f"PAL   {pal_result_100}")
    print(f"SECAM {secam_result_100}")
    print("----- ---- -----")

    cv2.imwrite(f"../doc/ebu75.png", ebu75concat)
    cv2.imwrite(f"../doc/ebu100.png", ebu100concat)

    concat = cv2.vconcat([ebu75concat, ebu100concat])

    return concat


if __name__ == '__main__':
    concat = test_colorbars()

    # Display the resulting frame
    cv2.imshow("preview", concat)

    # Waits for a user input to quit the application
    cv2.waitKey(0)
    cv2.destroyAllWindows()
