import cv2
from framebuffer import transfer_picture

from debugcom import DebugCom

debugcom = DebugCom()

luma_black_level = 47
debugcom.memwrite_u8(9, luma_black_level)

debugcom.set_video_prescalers("PAL", 130, 22, 22)
debugcom.set_video_prescalers("NTSC", 100, 23, 23)
debugcom.set_video_prescalers("SECAM", 105, 35, 35)

interlacing_mode = True
width = 768 + 16
lines_per_field = 256 + 15

debugcom.configure_video_standard("PAL")
height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode)

config_flags = 2 | 16  # QAM Chroma Bandpass + Chroma Enable
if interlacing_mode:
    config_flags |= 32  # Interlacing Mode
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

transfer_picture(debugcom, img)
