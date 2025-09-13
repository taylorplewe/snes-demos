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
	.macro ai8
		sep #%00110000 ; both 8 bit
	.endmacro
	.macro ai16
		rep #%00110000 ; both 16 bit
	.endmacro

	.macro asr
		cmp #$80
		ror a
	.endmacro

    .a8
	.i16
	.macro dmaSet chan, reg, dmap, src, count
		.local CHANOFFS
		CHANOFFS = chan * $10

		lda #dmap
		sta DMAP0 +CHANOFFS
		ldx #.loword(src)
		stx A1T0L +CHANOFFS
		lda #^src
		sta A1B0 +CHANOFFS
		lda #<reg
		sta BBAD0 +CHANOFFS
		.ifnblank count
		ldx #count
		stx DAS0L +CHANOFFS
		.endif
	.endmacro
	.macro dma chan, reg, dmap, src, count
		dmaSet chan, reg, dmap, src, count

		lda #1 << chan
		sta MDMAEN ; run it
	.endmacro

	; set all bytes of a memory block to 0
	.a8
	.i16
	.macro clearMemory start, len
		ldx #.loword(start)
		stx WMADDL
		lda #^start
		sta WMADDH
	    dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, zero, len
	.endmacro
