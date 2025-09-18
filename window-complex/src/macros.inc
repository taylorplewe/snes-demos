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

    .macro neg
        .if .asize = 8
            eor #$ff
        .else
            eor #$ffff
        .endif
        inc
    .endmacro

    .macro abs
        .local end
        bpl end
        neg
        end:
    .endmacro

    ; in:
        ; A:8  = divisor
        ; X:16 = dividend
    ; out:
        ; X:16 = quotient
    .macro div
    	stx WRDIVL
    	sta WRDIVB
        nop
        nop
        nop
        nop
        nop
    	nop
    	nop
    	nop
    	nop
    	ldx RDDIVL
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

    .a8
    .i16
    .macro hdmaSet chan, reg, dmap, src, indirect_addr
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
        .ifnblank indirect_addr
        lda #^indirect_addr
        sta DASB0 +CHANOFFS
        .endif
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

    .define mi(num) .loword(-num)

    ; local function vars
    SIZEOF_LOCAL_VARS = 32
    localVarPos .set 0
    .define localVars localVarPos .set 0
    .macro var name, size
        name = localVarPos
        localVarPos .set localVarPos + size
        .assert localVarPos <= SIZEOF_LOCAL_VARS, error, "Max size of local var space exceeded"
    .endmacro
