# Lessons learned

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