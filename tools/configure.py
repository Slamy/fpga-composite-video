import math

from scipy import signal

from filterutil import FpFilter

official_ntsc_frequency = 3.579545e6
official_pal_frequency = 4.43361875e6
secam_dr_frequency = 4.40626e6
secam_db_frequency = 4.25e6
secam_dr_hub = 280e3
secam_db_hub = 230e3

system_clock = 48e6
system_clock_period = 1 / system_clock

line_length = 64e-6 / system_clock_period  # 64 usec
frame_time = line_length * 262 * system_clock_period

pal_burst_amplitude = 11
pal_burst_u = round(pal_burst_amplitude * math.sin(math.radians(-45)))
pal_burst_v = round(pal_burst_amplitude * math.cos(math.radians(-45)))
ntsc_burst_amplitude = 18
ntsc_burst_v = -round(ntsc_burst_amplitude * math.sin(math.radians(-45 + 33)))
ntsc_burst_u = -round(ntsc_burst_amplitude * math.cos(math.radians(-45 + 33)))


def sine_frequency_to_increment(freq):
    dds_accu_width = 51
    dds_wrap = 2 ** dds_accu_width
    return dds_wrap / (system_clock / freq)


phase_increment_db = round(sine_frequency_to_increment(secam_db_frequency))
phase_increment_dr = round(sine_frequency_to_increment(secam_dr_frequency))
phase_increment_pal = round(sine_frequency_to_increment(official_pal_frequency))
phase_increment_ntsc = round(sine_frequency_to_increment(official_ntsc_frequency))

print(f"Calculated pal increment would be {phase_increment_pal}")
print(f"Calculated db increment would be {phase_increment_db}")
print(f"Calculated dr increment would be {phase_increment_dr}")
print(
    f"Possible increment of increment {round(sine_frequency_to_increment(secam_db_frequency + secam_db_hub)) - round(sine_frequency_to_increment(secam_db_frequency))}")
print(f"Max hub of dB {round(sine_frequency_to_increment(secam_db_hub)) >> 39} ")
print(f"Max hub of dR {round(sine_frequency_to_increment(secam_dr_hub)) >> 39} ")


def print_filter(prefix, filter):
    print(f"{prefix} B {filter.b}")
    print(f"{prefix} A {filter.a}")

    for idx, value in enumerate(filter.b):
        file.write(f"`define {prefix}_B{idx} {filter.b[idx]}\n")

    for idx, value in enumerate(filter.a):
        file.write(f"`define {prefix}_A{idx} {filter.a[idx]}\n")

    file.write(f"`define {prefix}_B_AFTER_DOT {filter.b_after_dot}\n")
    file.write(f"`define {prefix}_A_AFTER_DOT {filter.a_after_dot}\n\n")


def generate_chroma_filter():
    b_after_dot = 5
    a_after_dot = 5

    band_start = official_pal_frequency - 1.1e6
    band_stop = official_pal_frequency + 1.7e6
    sos = signal.iirfilter(1, [band_start, band_stop], btype='bandpass', analog=False, ftype='bessel', fs=system_clock,
                           output='sos')
    b, a = signal.sos2tf(sos)
    fpfilter = FpFilter(b, a, b_after_dot, a_after_dot)
    print_filter("PAL_CHROMA", fpfilter)

    band_start = official_ntsc_frequency - 1.1e6
    band_stop = official_ntsc_frequency + 1.7e6
    sos = signal.iirfilter(1, [band_start, band_stop], btype='bandpass', analog=False, ftype='bessel', fs=system_clock,
                           output='sos')
    b, a = signal.sos2tf(sos)
    fpfilter = FpFilter(b, a, b_after_dot, a_after_dot)
    print_filter("NTSC_CHROMA", fpfilter)


def generate_pal_luma_filter():
    luma_stop = official_pal_frequency - 2e6
    print(f"luma_stop {luma_stop}")
    b_after_dot = 10
    a_after_dot = 10
    sos = signal.bessel(2, luma_stop, 'low', analog=False, norm='phase', fs=system_clock, output='sos')
    b, a = signal.sos2tf(sos)
    fpfilter = FpFilter(b, a, b_after_dot, a_after_dot)
    print_filter("PAL_LUMA_LOWPASS", fpfilter)


def generate_secam_chroma_lowpass_filter():
    b_after_dot = 11
    a_after_dot = 8
    sos = signal.bessel(1, 1.2e6, 'lp', fs=system_clock, output='sos')
    b, a = signal.sos2tf(sos)
    fpfilter = FpFilter(b, a, b_after_dot, a_after_dot)
    print_filter("SECAM_CHROMA_LOWPASS", fpfilter)


def generate_secam_amplitude_lowpass_filter():
    b_after_dot = 11
    a_after_dot = 8
    sos = signal.bessel(1, 0.5e6, 'lp', fs=system_clock, output='sos')
    b, a = signal.sos2tf(sos)
    fpfilter = FpFilter(b, a, b_after_dot, a_after_dot)
    print_filter("SECAM_AMPLITUDE_LOWPASS", fpfilter)


def generate_secam_preemphasis():
    b_after_dot = 11
    a_after_dot = 8
    sos = signal.bessel(1, 0.3e6, 'lp', fs=system_clock, output='sos')
    b, a = signal.sos2tf(sos)
    fpfilter = FpFilter(b, a, b_after_dot, a_after_dot)
    print_filter("SECAM_PREEMPHASIS", fpfilter)


def frequency_to_amplitude(x):
    x = x / 1000000
    if x < 4.286:
        y = 8 * (4.286 - x) * (4.286 - x)
    else:
        y = 4 * (4.286 - x) * (4.286 - x)
    y = y * 15 + 5
    if y > 31:
        y = 31
    return y


def increment_to_sine_frequency(increment):
    dds_accu_width = 51
    dds_wrap = 2 ** dds_accu_width
    return increment * system_clock / dds_wrap


# print(increment_to_sine_frequency(255911800489825))
# exit(0)

def build_frequency_to_amplitude_lut():
    start_inc = round(sine_frequency_to_increment(3.0e6)) >> 36
    end_inc = round(sine_frequency_to_increment(5.8e6)) >> 36
    print(start_inc)
    print(end_inc)

    with open("../mem/secam_ampl.txt", "w") as file:
        for inc in range(start_inc, end_inc):
            freq = increment_to_sine_frequency(inc << 36)
            file.write(f"{hex(round(frequency_to_amplitude(freq)))[2:]}\n")


def generate_sine_lut():
    phase_width = 5
    amplitude_width = 6

    phase_count = 2 ** phase_width
    phase_max = phase_count - 1
    amplitude_max = 2 ** amplitude_width - 1

    print(phase_max)
    print(amplitude_max)

    with open("../mem/sinewave.txt", "w") as f:
        for a in range(0, amplitude_max + 1):
            for p in range(0, phase_max + 1):
                a_scaled = a * 2
                value = round(a_scaled * math.sin(p * math.pi * 2 / phase_count))
                # Rather evil trick to convert signed to unsigned
                value = value & 0xff
                f.write(f"{value:02x}\n")


with open("../rtl/coefficients.svh", "w") as file:
    generate_sine_lut()
    generate_chroma_filter()
    generate_pal_luma_filter()
    generate_secam_amplitude_lowpass_filter()
    generate_secam_chroma_lowpass_filter()
    generate_secam_preemphasis()
    build_frequency_to_amplitude_lut()

    file.write(f"`define CLK_PERIOD_USEC {1e6 / system_clock}  // .8\n\n")

    file.write(f"`define SECAM_CHROMA_DB_DDS_INCREMENT 51'd{phase_increment_db}\n")
    file.write(f"`define SECAM_CHROMA_DR_DDS_INCREMENT 51'd{phase_increment_dr}\n")
    file.write(f"`define PAL_CHROMA_DDS_INCREMENT 51'd{phase_increment_pal}\n")
    file.write(f"`define NTSC_CHROMA_DDS_INCREMENT 51'd{phase_increment_ntsc}\n\n")

    file.write(f"`define PAL_BURST_U {pal_burst_u}\n")
    file.write(f"`define PAL_BURST_V {pal_burst_v}\n")
    file.write(f"`define NTSC_BURST_U {ntsc_burst_u}\n")
    file.write(f"`define NTSC_BURST_V {ntsc_burst_v}\n\n")
