# Framebuffer Device

## Thoughts about pixel formats

* 32 Bit Pixel Format
    * 8 Bit Y
    * 8 Bit U
    * 8 Bit V
    * 8 Bit ignored/wasted

* 16 Bit Pixel format
    * 8 Bit Y
    * 4 Bit U
    * 4 Bit V

This might cause too much banding.

* 16 Bit Pixel format
    * 6 Bit Y
    * 5 Bit U
    * 5 Bit V

But this also causes too much banding.
A 24 bit format might be the best as no space is wasted, bus it is more difficult on the circuit design.

* 24 Bit Pixel Format
    * 8 Bit Y
    * 8 Bit U
    * 8 Bit V

## Register Map
