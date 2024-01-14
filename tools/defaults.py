import color
from debugcom import DebugCom


def set_default_scalers(debugcom: DebugCom):
    ntsc_burst_amplitude = 14
    # This should be 0 degree. But for some reason
    # my USB video grabber has some phase issues
    # On my TV, 0 works and -17 is totally wrong.
    ntsc_burst_phase = -17
    debugcom.set_ntsc_burst(ntsc_burst_amplitude, ntsc_burst_phase)
    secam_db_swing = 33
    secam_dr_swing = 20
    debugcom.set_secam_preemphasis_swing(secam_db_swing, secam_dr_swing)
    debugcom.set_secam_ampl_delay(0)
    debugcom.set_luma_black_level(47)

    # Might look dark on Commodore 1084 but on the USB videograbber these values
    # are suitable for 75% and 100% color bars.
    _, u_scale, v_scale = color.ypbpr2yuv(0, 47, 47)
    debugcom.set_video_prescalers("PAL", 100, round(u_scale), round(v_scale))
    debugcom.set_video_prescalers("NTSC", 100, round(u_scale), round(v_scale))
    _, u_scale, v_scale = color.ypbpr2yuv(0, 41, 39)
    debugcom.set_video_prescalers("SECAM", 100, round(u_scale), round(v_scale))

    debugcom.enable_qam_chroma_bandpass(True)
    debugcom.enable_chroma_output(True)
