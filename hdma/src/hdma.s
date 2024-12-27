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

.proc calc_persp_rot_m7_vals
	; ldx #0
	; loop:
	; 	; get perspective val
	; 	lda persp112_8, x
	; 	pha

	; 	; m7A, m7B (cosine)
	; 	lda counter
	; 	jsr cos
	; 	pla


	; 	; sta PERSP_ROT_M7_VALS, x
	; 	inx
	; 	cpx #persp112_8_len
	; 	bne loop
	rts
.endproc

.endscope