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
	
.a16
; M7A.16 = sp + 8
; M7B.16 = sp + 6
; M7C.16 = sp + 4
; M7D.16 = sp + 2
_m7:
	pla ; return addr
	pla ; M7D
	a8
	sta M7D
	xba
	sta M7D
	a16
	pla ; M7C
	a8
	sta M7C
	xba
	sta M7C
	a16
	pla ; M7B
	a8
	sta M7B
	xba
	sta M7B
	a16
	pla ; M7A
	a8
	sta M7A
	xba
	sta M7A
	a16

	; get back to return addr
	tsx
	txa
	sec
	sbc #10
	tax
	txs
	rts
.a8

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