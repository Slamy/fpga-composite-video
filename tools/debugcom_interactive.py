import math

import cv2

from debugcom import DebugCom
from debugcom_hil_ebu75 import construct_ebu75
from defaults import set_default_scalers
from framebuffer import transfer_picture, framebuffer_easy_conf
from getch import getch

debugcom = DebugCom()


def interactive_configurator(single_line=False, interlacing_mode=False, rgb_mode=False, secam_focused=False,
                             internal_colorbars=False):
    ntsc_burst_amplitude = 10
    ntsc_burst_phase = 0
    luma_black_level = 47
    luma_scaler = 125
    ampl_delay = 0

    chroma_lowpass = False
    qam_bandpass = False
    debugcom.enable_single_line_mode(single_line)
    debugcom.enable_internal_colorbars(internal_colorbars)
    debugcom.enable_interlacing(interlacing_mode)
    debugcom.enable_rgb_mode(rgb_mode)

    y_delay = 0
    u_delay = 0
    v_delay = 0

    # ampl_delay 4 u_delay 0 v_delay 7 secam_db_swing 56 secam_dr_swing 32

    secam_db_swing = 29
    secam_dr_swing = 17

    while True:
        ntsc_burst_v = -round(ntsc_burst_amplitude * math.sin(math.radians(ntsc_burst_phase)))
        ntsc_burst_u = -round(ntsc_burst_amplitude * math.cos(math.radians(ntsc_burst_phase)))
        debugcom.set_delay_lines(y_delay, u_delay, v_delay)
        debugcom.set_luma_black_level(luma_black_level)
        debugcom.set_ntsc_burst_uv(ntsc_burst_u, ntsc_burst_v)
        debugcom.set_secam_preemphasis_swing(secam_db_swing, secam_dr_swing)
        debugcom.set_secam_ampl_delay(ampl_delay)

        if secam_focused:
            print(
                f"ampl_delay {ampl_delay} u_delay {u_delay} v_delay {v_delay} secam_db_swing {secam_db_swing} secam_dr_swing {secam_dr_swing}")
        else:
            print(ntsc_burst_amplitude, ntsc_burst_phase, ntsc_burst_u, ntsc_burst_v, luma_black_level, luma_scaler)

        char = getch()
        if char == "q":
            exit(0)

        if secam_focused:
            if char == "w":
                secam_db_swing += 1
            if char == "s":
                secam_db_swing -= 1
            if char == 'e':
                secam_dr_swing += 1
            if char == 'd':
                secam_dr_swing -= 1

            if char == "+":
                ampl_delay += 1
                print(f"ampl_delay {ampl_delay}")
            if char == "-":
                ampl_delay -= 1
                print(f"ampl_delay {ampl_delay}")
        else:
            if char == "w":
                ntsc_burst_amplitude += 1
            if char == "s":
                ntsc_burst_amplitude -= 1
            if char == 'e':
                ntsc_burst_phase += 1
                if ntsc_burst_phase > 180:
                    ntsc_burst_phase -= 360
            if char == 'd':
                ntsc_burst_phase -= 1
                if ntsc_burst_phase < -180:
                    ntsc_burst_phase += 360

            if char == "+":
                y_delay += 1
                print(f"y_delay {y_delay}")
            if char == "-":
                y_delay -= 1
                print(f"y_delay {y_delay}")

        if char == 'r':
            luma_black_level += 1
        if char == 'f':
            luma_black_level -= 1
        if char == 't':
            luma_scaler += 1
        if char == 'g':
            luma_scaler -= 1
        if char == 'z':
            chroma_lowpass = not chroma_lowpass
            debugcom.enable_chroma_lowpass(chroma_lowpass)
        if char == 'u':
            qam_bandpass = not qam_bandpass
            debugcom.enable_qam_chroma_bandpass(qam_bandpass)
        if char == 'h':
            internal_colorbars = not internal_colorbars
            debugcom.enable_internal_colorbars(internal_colorbars)

        if char == "2":
            u_delay += 1
            print(f"u_delay {u_delay}")
        if char == "1":
            u_delay -= 1
            print(f"u_delay {u_delay}")

        if char == "4":
            v_delay += 1
            print(f"v_delay {v_delay}")
        if char == "3":
            v_delay -= 1
            print(f"v_delay {v_delay}")

        if char == '6':
            debugcom.configure_video_standard("PAL")
        if char == '7':
            debugcom.configure_video_standard("NTSC")
        if char == '8':
            debugcom.configure_video_standard("SECAM")


def ebu75_interactive():
    interlacing_mode = False
    rgb_mode = False
    clks_per_pixel = 9
    width = 256
    lines_per_field = 256
    height = debugcom.configure_framebuffer(width, lines_per_field, interlacing_mode, 32, clks_per_pixel)

    set_default_scalers(debugcom)
    debugcom.configure_video_standard("SECAM")
    imga = construct_ebu75()
    transfer_picture(debugcom, imga, rgb_mode)
    interactive_configurator(single_line=True, interlacing_mode=interlacing_mode, rgb_mode=rgb_mode)


def secam_stresstest_interactive():
    videonorm = "SECAM"
    interlacing_mode = False
    rgb_mode = False
    width = 256

    height = framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width)
    filename = "../doc/secam_stresstest.png"
    img = cv2.imread(filename)
    transfer_picture(debugcom, img, rgb_mode)
    interactive_configurator(interlacing_mode=interlacing_mode, rgb_mode=rgb_mode, secam_focused=True)


def parrot_interactive():
    videonorm = "SECAM"
    interlacing_mode = True
    rgb_mode = True
    width = 768 + 16

    height = framebuffer_easy_conf(debugcom, videonorm, interlacing_mode, rgb_mode, width)
    filename = "../doc/parrot.jpg"
    img = cv2.imread(filename)
    print("Resizing...")
    img = cv2.resize(img, dsize=(width, height), interpolation=cv2.INTER_AREA)
    img = cv2.GaussianBlur(img, (1, 3), 0.6)
    transfer_picture(debugcom, img, rgb_mode)
    interactive_configurator(interlacing_mode=interlacing_mode, rgb_mode=rgb_mode, secam_focused=True)


def internal_colorbars_interactive():
    set_default_scalers(debugcom)
    interactive_configurator(single_line=True, secam_focused=True, internal_colorbars=True)


if __name__ == '__main__':
    # ebu75_interactive()
    # internal_colorbars_interactive()
    # parrot_interactive()
    secam_stresstest_interactive()
