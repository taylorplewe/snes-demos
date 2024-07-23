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
	sta $32
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

; get COS(A.8) in A.16
cos:
	clc                    ; clear carry for add
	adc  #$40              ; add 1/4 rotation

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
	.word $0000,$0324,$0647,$096A,$0C8B,$0FAB,$12C8,$15E2
	.word $18F8,$1C0B,$1F19,$2223,$2528,$2826,$2B1F,$2E11
	.word $30FB,$33DE,$36BE,$398C,$3C56,$3F17,$41CE,$447A
	.word $471C,$49B4,$4C3F,$4EBF,$5133,$539B,$55F5,$5842
	.word $5A82,$5CB4,$5ED7,$60EC,$62F2,$64EB,$66CF,$68A6
	.word $6A6D,$6C24,$6DC4,$6F5F,$70E2,$7255,$73B5,$7504
	.word $7641,$776C,$7884,$798A,$7A7D,$7B5D,$7C2A,$7CE3
	.word $7D8A,$7E1D,$7E9D,$7F09,$7F62,$7FA7,$7FD8,$7FF6
	.word $7FFF