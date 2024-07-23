apply_ppu_buff:
	@len = local
	a16
	lda local
	pha
	a8
	ldx #0
	@loop:
		ldy PPU_BUFF_LEN, x
		beq @end
			sty @len
			ldy PPU_BUFF_ADDR, x
			sty VMADDL
			lda PPU_BUFF_VMAIN, x
			sta VMAIN

			lda #DMAP_2REG_1WR
			sta DMAP0
			phx
			a16
			txa
			clc
			adc #PPU_BUFF_DATA
			tax
			a8
			lda #0
			xba
			lda #<VMDATAL
			ldy @len
			jsr _dma_ch0
			plx

			a16
			stz PPU_BUFF_LEN, x
		; next
		txa
		clc
		adc @len
		clc
		adc #5 ; info bytes
		tax
		a8
		bra @loop

	@end:
	a16
	pla
	sta local
	a8
	rts

.zeropage
refresh_screen_ind: .res 1
.code
refresh_screen:
	; is screen invalid?
	lda refresh_screen_ind
	cmp #$ff
	beq @end

	;bg1
		ldx #$2000
		stx VMADDL
		lda #VMAIN_INC_1 | VMAIN_WORDINC
		sta VMAIN

		lda #DMAP_2REG_1WR
		sta DMAP0

		lda #0
		xba
		lda #<VMDATAL
		ldy #896 * 2
		ldx #BG1_BUFF
		jsr _dma_ch0
	;bg3
		ldx #$2400
		stx VMADDL
		lda #VMAIN_INC_1 | VMAIN_WORDINC
		sta VMAIN

		lda #DMAP_2REG_1WR
		sta DMAP0

		lda #0
		xba
		lda #<VMDATAL
		ldy #(896 * 2)
		ldx #BG3_BUFF
		jsr _dma_ch0

	; end
	; validate screen
	lda #$ff
	sta refresh_screen_ind
	sta $50
	@end: rts