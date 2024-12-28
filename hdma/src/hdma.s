; page 2-17-5 of the official SNES dev manuel
.scope hdma

M7AD_VALS = $200
M7B_VALS = $200 + 112
M7C_VALS = $200 + 112*2

persp128: .incbin "../bin/persp128.bin"
persp128_len = *-persp128

persp112_8: .incbin "../bin/persp112_8.bin"
persp112_8_len = *-persp112_8

.proc setup
	stz HDMAEN

	dma_set 1, DMAP_1REG_2WR, persp128, M7A
	dma_set 2, DMAP_1REG_2WR, persp128, M7D

	lda #NLTR_EVERY_SCANLINE
	sta NLTR0 + $10
	sta NLTR0 + $20

.endproc

.proc run
	lda #%00000110
	sta HDMAEN
	rts
.endproc

.proc do_m7
	a16
	i8
	lda counter
	lsr a
	tax
	xba
	tay
	xba
	a8
	stx BG1HOFS
	sty BG1HOFS
	stx BG1VOFS
	sty BG1VOFS
	stx M7Y
	sty M7Y
	a16
	clc
	adc #$80
	a8
	sta M7X
	xba
	sta M7X
	i16
	rts
.endproc

.endscope