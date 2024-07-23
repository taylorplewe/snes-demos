.scope nmi

.proc ApplyPPUBuff
	len = local
	ldx local
	phx
	ldx #0
	loop:
		ldy PPU_BUFF_LEN, x
		beq end
			sty len
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
			ldy len
			jsr _dma_ch0
			plx

			a16
			stz PPU_BUFF_LEN, x
		; next
		txa
		clc
		adc len
		clc
		adc #5 ; info bytes
		tax
		a8
		bra loop

	end:
	plx
	stx local
	rts
	.endproc

.endscope