# Lessons learned

## PSRAM in GOWIN FPGAs is weird

* There are two PSRAM inside the GW1NR-9
* One PSRAM has an 8 bit data bus
* The PSRAM is addressed in words of 16 bit
* On the side of PSRAM_Memory_Interface_HS_V2, the addresses are in 32 bit words which probably results from its dual channel nature as two PSRAMs are fused into one.
* The smallest burst length is 16 bytes
* With two RAMs this results into a burst of
    * 16 bytes * 2 RAMs = 256 bits on the RAM bus
    * 64 bits * 4 clocks = 256 bits on the PSRAM memory controller
* The smallest addressable element from user logic view is a 32 bit word
* With 32 bits per pixel the smallest addressable element is a pixel
    * A burst consists of 8 pixels
* Because of the wrapped burst nature of the PSRAM, every memory access shall be started aligned to 8 pixels / 16 bytes
    * If this is not followed, weird wrap-arounds are visible in the picture
* The framebuffer device should discard the non wanted pixels at the start of the line

## Resetting of the QAM phase accumulator on a new frame or field is a bad idea

I first thought this might improve the pixel stability as dot crawl will no longer occur.
But I was wrong, as this has bad effects on at the least the PAL decoder of the Commodore 1084 as it creates weird flickering in the top half of the screen.
It should be noted that my USB video grabber doesn't care at all.

## For some reason, the picture on the Commodore 1084 is darker sometimes

Invalid pixel data after system reset confuses the automatic gain control. It stays like that and and the video signal must be removed to fix this.

## For some reason, the Commodore 1084 is unhappy with 1V p-p signals

My USB video grabber accepts it, but the 1084 clips white pixels to black. I've reduced 0.3V black and 1V white
to 0.2V black and 0.7V white. I don't know if this is the right solution but it works for the 1084 and the USB video grabber is also happy with that.

## Interlacing causes flicker on hard vertical edges

Vertical blurring is required! Oh god, I hate interlaced modes. Especially on the Workbench of the Amiga.

## SECAM is very complicated

Everything needs to work together to get a nice picture.
PAL and NTSC are transmitting the current state of U and V.
But SECAM transmission also depends on the change of the state as a deemphasis is used on the receiver side.
On the sender side a fitting preemphasis must be performed. This means that there is certain "swing" to the change. One can imagine this as a low pass on the receiver side and the sender side must provide "more" than the intented value to fight against the low pass.
This seems to make SECAM pretty stable as a slight shaky modulation might not affect the result.
If this "swing" is not present, the color looks dull and faded as the expected color will emerge later on.

But at the same time, there is also something called the HF Preemphasis. The amplitude of the frequency modulated signal must be correct or artefacts will occur during strong modulation. The more deviation the frequency is from a certain "center", the higher the amplitude must be.

* The amplitude of the color carrier must be correct
    * If not, there are artefacts!
* The preemphasis must be correct.
    * If not, there are artefacts!

When I started this I assumed that the line alternation might be the most complex. I was wrong as this part was only a mux.

Most of this project was spent on refining the SECAM encoder. I don't know if this was really worth it. But I like a good challenge.
