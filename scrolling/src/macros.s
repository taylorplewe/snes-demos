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
	.macro invert_a
		.if .asize = 8
			eor #$ff
		.else
			eor #$ffff
		.endif
		inc a
	.endmacro

	.macro add_zp dest, add
		lda dest
		clc
		adc add
		sta dest
	.endmacro
	.macro add_y add
		tya
		clc
		adc add
		tay
	.endmacro
	.macro add_x add
		txa
		clc
		adc add
		tax
	.endmacro
	.macro sub_zp dest, sub
		lda dest
		sec
		sbc sub
		sta dest
	.endmacro
	.macro sub_y sub
		tya
		sec
		sbc sub
		tay
	.endmacro
	.macro sub_x sub
		txa
		sec
		sbc sub
		tax
	.endmacro

	.macro mul8 num1, num2
		lda num1
		xba
		lda num2
		jsr _mul
	.endmacro
	.macro dma_ch0 dmap, src, ppureg, count
		lda dmap
		sta DMAP0
		ldx #src
		lda #^src
		xba
		lda #<ppureg
		ldy count
		jsr _dma_ch0
	.endmacro