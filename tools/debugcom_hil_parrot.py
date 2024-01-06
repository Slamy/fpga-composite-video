import cv2

from debugcom import DebugCom
from framebuffer import transfer_picture, framebuffer_easy_conf
from v4l import video_device, capture_still_frame

debugcom = DebugCom()

ntsc_burst_amplitude = 10
phase = -45 + 33


def grab_and_store(videonorm):
    debugcom.configure_video_standard(videonorm, video_device=video_device)
    frame = capture_still_frame()
    cv2.imwrite(f"../doc/parrot_{videonorm.lower()}.png", frame)


def test_parrot():
    interlacing_mode = True
    rgb_mode = True
    width = 768 + 16
    filename = "../doc/parrot.jpg"
    img = cv2.imread(filename)

    # Start with PAL
    videonorm = "PAL"
    height = framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width, overscan=15)
    print("Resizing...")
    resized = cv2.resize(img, dsize=(width, height), interpolation=cv2.INTER_AREA)

    # Perform a vertical blur for interlaced video to
    # avoid flickering hard edges. I'm using a gaussian blur here
    # with slightly modified sigma to avoid destroying too much detail.
    if interlacing_mode:
        blurred = cv2.GaussianBlur(resized, (1, 3), 0.6)

    transfer_picture(debugcom, blurred, rgb_mode)
    grab_and_store(videonorm)

    # Continue with SECAM as the resolution is the same
    videonorm = "SECAM"
    height = framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width, overscan=15)
    grab_and_store(videonorm)

    # Then do NTSC as the resolution is different
    videonorm = "NTSC"
    height = framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width, overscan=15)
    grab_and_store(videonorm)

    print("Resizing...")
    resized = cv2.resize(img, dsize=(width, height), interpolation=cv2.INTER_AREA)
    if interlacing_mode:
        blurred = cv2.GaussianBlur(resized, (1, 3), 0.6)
    transfer_picture(debugcom, blurred, rgb_mode)
    grab_and_store(videonorm)


if __name__ == '__main__':
    test_parrot()
