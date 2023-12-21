import cv2

from debugcom import DebugCom
from framebuffer import transfer_picture

videonorm = "NTSC"
interlacing_mode = True
rgb_mode = True
width = 768 + 16

debugcom = DebugCom()
debugcom.configure_video_standard(videonorm)
debugcom.set_luma_black_level(47)
if rgb_mode:
    debugcom.set_video_prescalers("PAL", 160, 11, 11)
    debugcom.set_video_prescalers("NTSC", 160, 14, 14)
    debugcom.set_video_prescalers("SECAM", 160, 20, 20)
else:
    debugcom.set_video_prescalers("PAL", 125, 12, 12)
    debugcom.set_video_prescalers("NTSC", 125, 14, 14)
    debugcom.set_video_prescalers("SECAM", 125, 20, 20)

#exit()
if videonorm == "NTSC":
    lines_per_field = 200 + 15 # for 60 Hz (NTSC)
else:
    lines_per_field = 256 + 15  # for 50 Hz (PAL and SECAM)

height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode)

config_flags = 2 | 16  # QAM Chroma Bandpass + Chroma Enable
if interlacing_mode:
    config_flags |= 32  # Interlacing Mode
if rgb_mode:
    config_flags |= 64
debugcom.memwrite_u8(6, config_flags)

# filename = "../doc/digimon.jpg"
filename = "../doc/Bliss.bmp"
filename = "../doc/parrot.jpg"
# filename = "../doc/yoshis.jpg"

img = cv2.imread(filename)
print("Resizing...")
img = cv2.resize(img, dsize=(width, height), interpolation=cv2.INTER_AREA)

# Perform a vertical blur for interlaced video to
# avoid flickering hard edges. I'm using a gaussian blur here
# with slightly modified sigma to avoid destroying too much detail.
if interlacing_mode:
    img = cv2.GaussianBlur(img, (1, 3), 0.6)

# cv2.imshow("scaled", img)
# cv2.imshow("blurred", vblur)
# cv2.waitKey(0)
# cv2.destroyAllWindows()
# exit()

transfer_picture(debugcom, img, rgb_mode)
