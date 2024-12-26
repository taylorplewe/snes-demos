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

	; dma/hdma
	.a8
	.i16
	.macro dma_set chan, dmap, src, ppureg, count
		.local CHANOFFS
		CHANOFFS = chan * $10

		lda #dmap
		sta DMAP0 +CHANOFFS
		ldx #src & $ffff
		stx A1T0L +CHANOFFS
		lda #^src
		sta A1B0 +CHANOFFS
		lda #<ppureg
		sta BBAD0 +CHANOFFS
		.ifnblank count
		ldx #count
		stx DAS0L +CHANOFFS
		.endif
	.endmacro
	.macro dma chan, dmap, src, ppureg, count
		dma_set chan, dmap, src, ppureg, count

		lda #1 << chan
		sta MDMAEN ; run it
	.endmacro
	.macro hdma chan, dmap, src, ppureg, count
		dma_set chan, dmap, src, ppureg, count

		lda #1 << chan
		sta HDMAEN ; run it
	.endmacro

	; mode 7
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
		tsx
		txa
		clc
		adc #8
		tax
		txs
	.endmacro