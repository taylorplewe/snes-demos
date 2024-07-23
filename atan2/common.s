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






; params:
	; a.8 = diff_x
	; b.8 = diff_y
	; y = 0 = bottom right quadrant
	;     1 = bottom left quadrant
	;     2 = top left quadrant
	;     3 = top right quadrant
atan2:
	@temp = local
	@diff1 = local+1
	@diff2 = local+2

	sta @diff1
	xba
	sta @diff2
	tya
	and #1
	beq :+
		; swap xdiff and ydiff
		lda @diff1
		sta @temp
		lda @diff2
		sta @diff1
		lda @temp
		sta @diff2
	:
	lda atan_offsets, y
	sta @temp
	; only consider leftmost 3 bits of diff 1
		lda @diff1
		lsr a
		lsr a
		lsr a
		lsr a
		sta @diff1
	; 3 bits to the left of those are for diff 2
		lda @diff2
		and #%11110000
	; combine the two
		clc 
		adc @diff1
	i8
	tay
	lda atantab, y
	i16
	clc 
	adc @temp
	rts 
;------------------------------------------
atantab:
	; a>>3 = ydiff
	; a&7  = xdiff
    ; Perfectly matches round(0x20/pi * atan(((a>>3) + 0.11)
    ;                                       / ((a&7) + 0.11))) where a=0..63
    ;  or equivalently: round(0x20/pi * atan2((a>>3) + 0.11, (a&7) + 0.11))
	; .byte $08,$01,$01,$00,$00,$00,$00,$00, $0F,$08,$05,$03,$03,$02,$02,$02
	; .byte $0F,$0B,$08,$06,$05,$04,$03,$03, $10,$0D,$0A,$08,$07,$06,$05,$04
	; .byte $10,$0D,$0B,$09,$08,$07,$06,$05, $10,$0E,$0C,$0A,$09,$08,$07,$06
	; .byte $10,$0E,$0D,$0B,$0A,$09,$08,$07, $10,$0E,$0D,$0C,$0B,$0A,$09,$08

	; .byte $00,$00,$00,$00,$00,$00,$00,$00, $40,$20,$12,$0d,$09,$08,$06,$05
	; .byte $40,$2d,$20,$17,$12,$0f,$0d,$0b, $40,$32,$28,$20,$1a,$16,$12,$10
	; .byte $40,$36,$2d,$25,$20,$1b,$17,$15, $40,$37,$30,$29,$24,$20,$1c,$19
	; .byte $40,$39,$32,$2d,$28,$23,$20,$1c, $40,$3a,$34,$2f,$2a,$26,$23,$20

.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.byte $3f, $20, $13, $0d, $0a, $08, $07, $06, $05, $05, $04, $04, $03, $03, $03, $03
.byte $3f, $2d, $20, $18, $13, $10, $0d, $0b, $0a, $09, $08, $07, $07, $06, $06, $05
.byte $3f, $33, $28, $20, $1a, $16, $13, $10, $0f, $0d, $0c, $0b, $0a, $09, $09, $08
.byte $3f, $36, $2d, $26, $20, $1b, $18, $15, $13, $11, $10, $0e, $0d, $0c, $0b, $0b
.byte $3f, $38, $30, $2a, $25, $20, $1c, $19, $17, $15, $13, $11, $10, $0f, $0e, $0d
.byte $3f, $39, $33, $2d, $28, $24, $20, $1d, $1a, $18, $16, $14, $13, $12, $10, $10
.byte $3f, $3a, $35, $30, $2b, $27, $23, $20, $1d, $1b, $19, $17, $16, $14, $13, $12
.byte $3f, $3b, $36, $31, $2d, $29, $26, $23, $20, $1e, $1b, $1a, $18, $16, $15, $14
.byte $3f, $3b, $37, $33, $2f, $2b, $28, $25, $22, $20, $1e, $1c, $1a, $19, $17, $16
.byte $3f, $3c, $38, $34, $30, $2d, $2a, $27, $25, $22, $20, $1e, $1c, $1b, $19, $18
.byte $3f, $3c, $39, $35, $32, $2f, $2c, $29, $26, $24, $22, $20, $1e, $1d, $1b, $1a
.byte $3f, $3d, $39, $36, $33, $30, $2d, $2a, $28, $26, $24, $22, $20, $1e, $1d, $1b
.byte $3f, $3d, $3a, $37, $34, $31, $2e, $2c, $2a, $27, $25, $23, $22, $20, $1e, $1d
.byte $3f, $3d, $3a, $37, $35, $32, $30, $2d, $2b, $29, $27, $25, $23, $22, $20, $1f
.byte $3f, $3d, $3b, $38, $35, $33, $30, $2e, $2c, $2a, $28, $26, $25, $23, $21, $20

atan_offsets:
	; .byte $00,$10,$30,$20
	.byte 0, 64, 128, 192