; params:
	; a - 8-bit number to mod against
	; x - 16-bit number to mod
mod:
	stx WRDIVL
	sta WRDIVB
	a16
	txa
	a8
	nop
	nop
	nop
	nop
	ldx RDDIVL
	beq @end
	ldx RDMPYL
	a16
	txa
	a8
	@end: rts

; multiply A.8 & B.8, result in A.16
_mul:
	sta WRMPYA
	xba
	sta WRMPYB	; now wait 8 machine cycles for result
	nop			; +2 = 2 of 8 machine cycles
	a16			; +3 = 5 of 8 machine cycles
	lda RDMPYL	; +4 = 9 of 8 machine cycles
	a8
	rts

; NOTE: if you're ever desparate for frame time to do stuff (that doesn't need controller input), place it before this function, which just waits until controller input is ready, gets called
wait_for_input:
	lda HVBJOY
	lsr a
	bcs wait_for_input
	rts

set_joy1_pressed:
	a16
	lda joy1_prev
	eor #$ffff
	and JOY1L
	sta joy1_pressed
	a8
	rts

clear_oam:
	ldx #0
	stz oam_lo_ind
	lda #@oam_mush_lo
	@loloop:
		sta OAM_DMA_ADDR_LO, x
		inx
		cpx #512
		bcc @loloop
	ldx #0
	lda #@oam_mush_hi
	@hiloop:
		sta OAM_DMA_ADDR_HI, x
		inx
		cpx #32
		bcc @hiloop
	rts
	@oam_mush_lo = 224
	@oam_mush_hi = $ff

; params:
;	x - oam_lo_ind
;	a - bits to set (will be masked off for correct sprite, e.g. send over %10101010 and it will be masked off to only update %--10----)
set_oam_hi_bits:
	@new_hi_bits		= local
	@oam_hi_ind			= local+1
	@oam_hi_mask		= local+2
	pha
	a16
	txa
	lsr a
	lsr a
		pha
		and #%11
		tax
		pla
	lsr a
	lsr a ; /16
	a8
	sta @oam_hi_ind
	lda #%00000011
	@shift_left_loop:
		cpx #0
		beq :+
		asl a
		asl a
		dex
		bra @shift_left_loop
	:
	sta @oam_hi_mask

	pla
	and @oam_hi_mask
	sta @new_hi_bits
	lda @oam_hi_mask
	eor #$ff
	i8
	ldx @oam_hi_ind
	and OAM_DMA_ADDR_HI, x
	ora @new_hi_bits
	sta OAM_DMA_ADDR_HI, x
	i16
	rts


; Come into this function A.16
.a16
asr8:
	bit #$8000
	beq @pos
	;neg
		xba
		ora #$ff00
		rts
	@pos:
		xba
		and #$00ff
		rts
.a8


; get COS(A.8) in A.16
cos:
	clc ; clear carry for add
	adc #$40 ; add 1/4 rotation

; get SIN(A.8) in A.16. enter with the Z flag reflecting the contents of A
sin:
	bpl @sin_cos		; just get SIN/COS and return if +ve

	and #$7f		; else make +ve
	jsr @sin_cos		; get SIN/COS
	
	; now do twos complement
	a16
	eor #$ffff
	clc
	adc #1
	a8
	rts

	; get 16-bit A from SIN/COS table
	@sin_cos:
	cmp #$41		; compare with max+1
	bcc @quadrant	; branch if less

	eor #$7F		; wrap $41 to $7F ..
	adc #$00		; .. to $3F to $00

	@quadrant:
	asl	a			; * 2 bytes per value
	i8
	a16
	tax				; copy to index
	lda sintab, x	; get 16-bit SIN/COS table value
	i16
	a8
	rts

sintab:
	.word $0000,$0324,$0647,$096a,$0c8b,$0fab,$12c8,$15e2
	.word $18f8,$1c0b,$1f19,$2223,$2528,$2826,$2b1f,$2e11
	.word $30fb,$33de,$36be,$398c,$3c56,$3f17,$41ce,$447a
	.word $471c,$49b4,$4c3f,$4ebf,$5133,$539b,$55f5,$5842
	.word $5a82,$5cb4,$5ed7,$60ec,$62f2,$64eb,$66cf,$68a6
	.word $6a6d,$6c24,$6dc4,$6f5f,$70e2,$7255,$73b5,$7504
	.word $7641,$776c,$7884,$798a,$7a7d,$7b5d,$7c2a,$7ce3
	.word $7d8a,$7e1d,$7e9d,$7f09,$7f62,$7fa7,$7fd8,$7ff6
	.word $7fff