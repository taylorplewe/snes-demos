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

; M7A.16 = sp + 8
; M7B.16 = sp + 6
; M7C.16 = sp + 4
; M7D.16 = sp + 2
_m7:
	php
	a8
	lda 4, s
	sta M7D
	lda 5, s
	sta M7D
	lda 6, s
	sta M7C
	lda 7, s
	sta M7C
	lda 8, s
	sta M7B
	lda 9, s
	sta M7B
	lda 10, s
	sta M7A
	lda 11, s
	sta M7A
	plp
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