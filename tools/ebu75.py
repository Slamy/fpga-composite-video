import color
from color import rgb2yuv, yuv2rgb


def yuv_real2raw(y, u, v):
    global index
    y_raw, u_raw, v_raw = color.yuv_real2raw(y, u, v)
    print(f"3'd{index}: begin luma={round(y_raw)}; yuv_u = {round(u_raw)};yuv_v = {round(v_raw)};end")
    index += 1
    # print(y_raw, u_raw, v_raw)


index = 0

print(rgb2yuv(1, 0, 0))
print(rgb2yuv(0.8, 0.8, 0.2))
print(yuv2rgb(0.299, -0.14740699999999998, 0.614777))

r, g, b = yuv2rgb(0.66, -0.327, 0.073)
r *= 255
g *= 255
b *= 255

print(r, g, b)

# Got these values from https://www.elektroniktutor.de/geraetetechnik/pal_ffs.html#farbdiff
yuv_real2raw(1, 0, 0)
# yuv_real2raw(0.9, 0, 0)
yuv_real2raw(0.66, -0.327, 0.073)
yuv_real2raw(0.52, 0.110, -0.462)
yuv_real2raw(0.44, -0.217, -0.389)
yuv_real2raw(0.30, 0.217, 0.389)
yuv_real2raw(0.22, -0.110, 0.462)
yuv_real2raw(0.08, 0.327, -0.073)
yuv_real2raw(0, 0, 0)

# yuv_real2raw(0, 0, 0)
