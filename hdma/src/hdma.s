; page 2-17-5 of the official SNES dev manuel
.scope hdma

persp128: .incbin "../bin/persp128.bin"
persp128_len = *-persp128

.proc setup
	lda #0
	sta HDMAEN

	dma_set 1, DMAP_1REG_2WR, persp128, M7A
	dma_set 2, DMAP_1REG_2WR, persp128, M7D

	lda #NLTR_EVERY_SCANLINE
	sta NLTR0 + $10
	sta NLTR0 + $20

.endproc

.proc run
	lda #%00000110
	sta HDMAEN
	sta $f0
	rts
.endproc

.endscope