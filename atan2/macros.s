	.macro a8
		sep #%00100000 ; a 8 bit
	.endmacro
	.macro a16
		rep #%00100000 ; a 16 bit
	.endmacro
	.macro i8
		sep #%00010000 ; x & y 8 bit
	.endmacro
	.macro i16
		rep #%00010000 ; x & y 16 bit
	.endmacro
	.macro asr
		cmp #$80
		ror a
	.endmacro
	.macro asr16
		cmp #$8000
		ror a
	.endmacro
	.macro m_dma_ch0 dmap, src, ppureg, count
		lda #dmap
		sta DMAP0
		ldx #src
		lda #^src
		xba
		lda #<ppureg
		ldy #count
		jsr dma_ch0
	.endmacro