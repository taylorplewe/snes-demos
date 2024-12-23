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

; NOTE: set DMAP0 beforehand!!
; Also don't forget to set the corresponding address register beforehand e.g. set CGADD before doing the DMA on CGDATA
; params:
;	a - destination PPU register; $21aa
;	x - low 16 bits of source address; -------- xxxxxxxx xxxxxxxx
;	b - high 8 bits of source address; bbbbbbbb -------- --------
;	y - # of bytes to transfer
dma_ch0:
	sta BBAD0
	stx A1T0L
	xba
	sta A1B0
	sty DAS0L

	lda #1
	sta MDMAEN ; run it
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