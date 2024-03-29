import cv2

from debugcom import DebugCom
from framebuffer import transfer_picture, framebuffer_easy_conf


def resize_and_transfer_picture():
    videonorm = "PAL"
    interlacing_mode = True
    rgb_mode = True
    width = 768 + 16
    bits_per_pixel = 24

    debugcom = DebugCom()
    height = framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width, bits_per_pixel, overscan=15)
    filename = "../doc/parrot.jpg"
    img = cv2.imread(filename)
    print("Resizing...")
    img = cv2.resize(img, dsize=(width, height), interpolation=cv2.INTER_AREA)

    # Perform a vertical blur for interlaced video to
    # avoid flickering hard edges. I'm using a gaussian blur here
    # with slightly modified sigma to avoid destroying too much detail.
    if interlacing_mode:
        img = cv2.GaussianBlur(img, (1, 3), 0.6)

    transfer_picture(debugcom, img, rgb_mode, bits_per_pixel == 32)


if __name__ == '__main__':
    resize_and_transfer_picture()
