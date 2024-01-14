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
    cv2.imwrite(f"../doc/secam_stresstest_result.png", frame)
    return frame


def test_secam_stress():
    interlacing_mode = False
    rgb_mode = True
    width = 256
    filename = "../doc/secam_stresstest.png"
    img = cv2.imread(filename)

    videonorm = "SECAM"
    height = framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width, overscan=0)
    transfer_picture(debugcom, img, rgb_mode)
    frame = grab_and_store(videonorm)

    return frame


if __name__ == '__main__':
    frame = test_secam_stress()

    # Display the resulting frame
    cv2.imshow("preview", frame)
    # Waits for a user input to quit the application
    cv2.waitKey(0)
    cv2.destroyAllWindows()
