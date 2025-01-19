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
	.macro mul num1, num2
		lda num1
		xba
		lda num2
		jsr _mul
	.endmacro
	.macro m_dma_ch0 dmap, src, ppureg, count
		lda #dmap
		sta DMAP0
		ldx #src & $ffff
		lda #^src
		xba
		lda #<ppureg
		ldy #count
		jsr dma_ch0
	.endmacro
	.a16
	.macro m7 m7a, m7b, m7c, m7d
		lda m7a	
		pha
		lda m7b
		pha
		lda m7c
		pha
		lda m7d
		pha
		jsr _m7
		tsc
		clc
		adc #8
		tcs
	.endmacro
	.a8