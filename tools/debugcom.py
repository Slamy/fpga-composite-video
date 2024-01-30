import math
import os
import struct

import serial
import serial.threaded


def set_bit(v, index, x):
    """Set the index:th bit of v to 1 if x is truthy, else to 0, and return the new value."""
    mask = 1 << index  # Compute mask, an integer with just bit 'index' set.
    v &= ~mask  # Clear the bit indicated by the mask (if x is False)
    if x:
        v |= mask  # If x was True, set the bit indicated by the mask.
    return v  # Return the result, we're done.


class DebugCom:
    def __init__(self):
        self.serial = serial.Serial()
        self.serial.port = "/dev/serial/by-id/usb-SIPEED_JTAG_Debugger_FactoryAIOT_Pro-if01-port0"
        self.serial.baudrate = 3000000
        self.serial.timeout = 1
        self.serial.open()

        # TODO For some reason the serial port only works after the second open.
        # This problem correlates with the baud rate. With 115200 I don't have this issue
        # This might be a linux only problem? Requires check on another operation system.
        self.serial.close()
        self.serial.open()

        self.config_flags = 0
        self.enable_chroma_output(True)

    def memwrite_u8(self, addr, val):
        command = struct.pack(">cHB", b'W', addr, val)
        self.serial.write(command)
        readback = self.serial.read()
        assert (readback == b'K')

    def blockmemwrite_u8(self, addr, data):
        assert len(data) <= 256
        command = struct.pack(">cBH", b'B', len(data) - 1, addr)
        self.serial.write(command)

        for value in data:
            command = struct.pack("B", value)
            self.serial.write(command)

        readback = self.serial.read()
        assert (readback == b'K')

    def memwrite_u16be(self, addr, val: int):
        self.memwrite_u8(addr, (val >> 8) & 0xff)
        self.memwrite_u8(addr + 1, (val >> 0) & 0xff)

    def memwrite_u32be(self, addr, val):
        self.memwrite_u8(addr, (val >> 24) & 0xff)
        self.memwrite_u8(addr + 1, (val >> 16) & 0xff)
        self.memwrite_u8(addr + 2, (val >> 8) & 0xff)
        self.memwrite_u8(addr + 3, (val >> 0) & 0xff)

    def memwrite_s8(self, addr, val):
        command = struct.pack(">cHb", b'W', addr, val)
        self.serial.write(command)
        readback = self.serial.read()
        assert (readback == b'K')

    def memread(self, addr):
        command = struct.pack(">cH", b'R', addr)
        self.serial.write(command)
        arr = self.serial.read()
        return struct.unpack("B", arr)[0]

    def configure_video_standard(self, standard, video_device=None):
        number_of_lines_50_hz = 312
        number_of_lines_60_hz = 262
        number_of_visible_lines_50_hz = 256
        number_of_visible_lines_60_hz = 200

        if standard == "SECAM":
            self.memwrite_s8(0x0001, 2)
            self.memwrite_u16be(2, number_of_lines_50_hz)
            self.memwrite_u16be(4, number_of_visible_lines_50_hz)
        elif standard == "NTSC":
            self.memwrite_s8(0x0001, 1)
            self.memwrite_u16be(2, number_of_lines_60_hz)
            self.memwrite_u16be(4, number_of_visible_lines_60_hz)
        elif standard == "PAL":
            self.memwrite_s8(0x0001, 0)
            self.memwrite_u16be(2, number_of_lines_50_hz)
            self.memwrite_u16be(4, number_of_visible_lines_50_hz)
        elif standard == "PAL60":
            self.memwrite_s8(0x0001, 0)
            self.memwrite_u16be(2, number_of_lines_60_hz)
            self.memwrite_u16be(4, number_of_visible_lines_60_hz)
        else:
            raise "Invalid argument provided!"

        if video_device:
            assert os.system(f"v4l2-ctl -d {video_device} -s {standard}") == 0

    def configure_framebuffer(self, width, lines_per_field, interlacing_mode, bits_per_pixel, clks_per_pixel=None):
        active_window_ticks = 3 * (768 + 16)
        if clks_per_pixel is None:
            clks_per_pixel = math.floor(active_window_ticks / width)

        height = lines_per_field * 2 if interlacing_mode else lines_per_field

        if bits_per_pixel == 24:
            stride = width * 3 / 4
            assert stride.is_integer()
            stride = int(stride)
            self.enable_convolver_passthrough(0)
        elif bits_per_pixel == 32:
            stride = width
            self.enable_convolver_passthrough(1)
        else:
            assert False, f"{bits_per_pixel} is not allowed. Either 24 or 32 bits per pixel!"

        # Move framebuffer away from calibration addresses
        even_field_addr = 0x200
        odd_field_addr = even_field_addr + stride

        # Double stride for interlacing so every other line is skipped
        # during field readout
        if interlacing_mode:
            stride = stride * 2

        self.memwrite_u16be(0x0300, width)  # Width
        self.memwrite_u16be(0x0302, lines_per_field)  # Height of a single field
        self.memwrite_u16be(0x0310, stride)  # Stride
        self.memwrite_u32be(0x0306, even_field_addr)  # Even field framebuffer start
        self.memwrite_u32be(0x030a, odd_field_addr)  # Odd field framebuffer start
        self.memwrite_u8(0x0304, clks_per_pixel)  # Clks per Pixel
        self.memwrite_u8(0x0305, 550 >> 2)  # Window H Start in clocks
        self.memwrite_u8(0x030e, 30)  # Window V Start in lines

        print(f"Framebuffer size {width} * {height} with {clks_per_pixel} clock ticks per pixel")
        print(f"Use a stride of {stride}")

        return height

    def set_delay_lines(self, y, u, v):
        # It should be unsigned instead of signed...
        # But having it signed allows a fast wrap around to check the maximum
        self.memwrite_s8(0, y)
        self.memwrite_s8(12, u)
        self.memwrite_s8(13, v)

    def set_ntsc_burst_uv(self, u, v):
        self.memwrite_s8(7, u)
        self.memwrite_s8(8, v)
        print(f"Set NTSC Burst {u} {v}")

    def set_secam_preemphasis_swing(self, db, dr):
        self.memwrite_s8(14, db)
        self.memwrite_s8(15, dr)
        print(f"Set SECAM Preemphasis Swing {db} {dr}")

    def set_secam_ampl_delay(self, ampl_delay):
        self.memwrite_s8(16, ampl_delay)
        print(f"Set SECAM Ampltidue Delay {ampl_delay}")

    def set_ntsc_burst(self, amplitude, phase):
        v = -round(amplitude * math.sin(math.radians(phase)))
        u = -round(amplitude * math.cos(math.radians(phase)))
        self.set_ntsc_burst_uv(u, v)

    def set_luma_black_level(self, y):
        self.memwrite_u8(9, y)

    def set_video_prescalers(self, standard, y, u, v):
        print(f"Set {standard} scalers to {y} {u} {v}")

        if standard == "PAL":
            self.memwrite_u8(0x0200 + 4 * 0 + 0, y)
            self.memwrite_u8(0x0200 + 4 * 1 + 0, u)
            self.memwrite_u8(0x0200 + 4 * 2 + 0, v)
        if standard == "NTSC":
            self.memwrite_u8(0x0200 + 4 * 0 + 1, y)
            self.memwrite_u8(0x0200 + 4 * 1 + 1, u)
            self.memwrite_u8(0x0200 + 4 * 2 + 1, v)
        if standard == "SECAM":
            self.memwrite_u8(0x0200 + 4 * 0 + 2, y)
            self.memwrite_u8(0x0200 + 4 * 1 + 2, u)
            self.memwrite_u8(0x0200 + 4 * 2 + 2, v)

    def enable_chroma_lowpass(self, v):
        self.config_flags = set_bit(self.config_flags, 0, v)
        self.memwrite_u8(6, self.config_flags)

    def enable_qam_chroma_bandpass(self, v):
        self.config_flags = set_bit(self.config_flags, 1, v)
        self.memwrite_u8(6, self.config_flags)

    def enable_single_line_mode(self, v):
        self.config_flags = set_bit(self.config_flags, 2, v)
        self.memwrite_u8(6, self.config_flags)

    def enable_internal_colorbars(self, v):
        self.config_flags = set_bit(self.config_flags, 3, v)
        self.memwrite_u8(6, self.config_flags)

    def enable_chroma_output(self, v):
        self.config_flags = set_bit(self.config_flags, 4, v)
        self.memwrite_u8(6, self.config_flags)

    def enable_interlacing(self, v):
        self.config_flags = set_bit(self.config_flags, 5, v)
        self.memwrite_u8(6, self.config_flags)

    def enable_rgb_mode(self, v):
        self.config_flags = set_bit(self.config_flags, 6, v)
        self.memwrite_u8(6, self.config_flags)

    def enable_convolver_passthrough(self, v):
        self.config_flags = set_bit(self.config_flags, 7, v)
        self.memwrite_u8(6, self.config_flags)

    def logic_analyzer_read(self):
        status = self.memread(0x100)
        if (status & 1):
            print("Trigger activated!")
        else:
            print("Collecting...")

        print(f"Measurement {self.memread(0x101)}")
        position = status >> 1
        print(position)

        for j in range(64):
            i = (j + position) % 64

            value3 = self.memread(i * 4 + 0)
            value2 = self.memread(i * 4 + 1)
            value1 = self.memread(i * 4 + 2)
            value0 = self.memread(i * 4 + 3)

            value3 = bin(value3)[2:].zfill(8)
            value2 = bin(value2)[2:].zfill(8)
            value1 = bin(value1)[2:].zfill(8)
            value0 = bin(value0)[2:].zfill(8)

            # print(i,value3,value2,value1,value0)
            print(f"{value3} {value2} {value1} {value0}")
