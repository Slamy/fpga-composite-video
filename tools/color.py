import numpy


# https://de.wikipedia.org/wiki/YUV-Farbmodell
def ypbpr2yuv(y, pb, pr):
    return y, pb * 0.872021, pr * 1.229951


def yuv2ypbpr(y, u, v):
    return y, u / 0.872021, v / 1.229951


def yuv_real2raw(y, u, v):
    y_raw = round(numpy.interp(y, [0, 1], [0, 255]))
    u_raw = round(numpy.interp(u, [-1, 1], [-126, 126]))
    v_raw = round(numpy.interp(v, [-1, 1], [-126, 126]))
    return y_raw, u_raw, v_raw


# https://de.wikipedia.org/wiki/Component_Video
def rgb2yprpb(r, g, b):
    y = 0.299 * r + 0.587 * g + 0.114 * b
    pb = -0.168 * r - 0.331 * g + 0.5 * b
    pr = 0.5 * r - 0.418 * g - 0.081 * b
    return y, pb, pr


# https://en.wikipedia.org/wiki/YCbCr
def rgb2ycbcr(r, g, b):
    # This might surprise but the formulas are exactly the same
    # Only difference is the 128 offset for Cb and Cr
    # But we are ignoring these here as we are using signed bytes
    # Also the input being 0..255 instead of 0..1
    y, pb, pr = rgb2yprpb(r, g, b)
    return round(y), round(pb), round(pr)


# https://www.pcmag.com/encyclopedia/term/yuvrgb-conversion-formulas
def rgb2yuv(r, g, b):
    y = 0.299 * r + 0.587 * g + 0.114 * b
    u = 0.493 * (b - y)
    v = 0.877 * (r - y)
    return y, u, v


def yuv2rgb(y, u, v):
    r = y + 1.140 * v
    g = y - 0.395 * u - 0.581 * v
    b = y + 2.032 * u
    return r, g, b
