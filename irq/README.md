By implementing an IRQ (interrupt request), it's possible to change the backdrop color every scanline, acheiving the sky/desert effect in the screenshot.

Note that this is _not_ possible with HDMA (H-blank direct memory access), because HDMA can only take bytes from somewhere and write them to a PPU register each scanline, and every write to the PPU register `CGDATA` _automatically increments_ `CGADDR`, so effectively every scanline you'd be writing to the _next palette color_, not the same one over and over again like I want here. An IRQ by contrast can actually _execute code_ every scanline, so I can manually reset `CGADDR` to 0 after each write to `CGDATA`.

![irq](irq.png)

---
[NMITIMEN - Interrupt Enable Flags description on wiki.superfamicom.org](https://wiki.superfamicom.org/registers#nmitimen-interrupt-enable-flags-828)
