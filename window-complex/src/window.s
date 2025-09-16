.scope window

.bss

wh0_table: .res 1
wh0_data: .res 224 + 1 ; another info byte is needed after 127 scanlines

wh1_table: .res 1
wh1_data: .res 224 + 1 ; another info byte is needed after 127 scanlines


.rodata

test:
    .byte 127, 5, 224 - 127, 8
test2:
    .byte 127, 10, 224 - 127, 18

wh_lookup:
    .incbin "..\bin\wh_lookup.bin"

two:
    .byte 2
one:
    .byte 1


.code

.a8
.i16
.proc init
    lda #WSEL(WSEL_LAYER_BG1, WSEL_W1, WSEL_INVERT)
    sta W12SEL
    lda #TMSW_BG1
    sta TMW

    ; set up hdma
    ; dmaSet 1, WH0, DMAP_2REG_1WR, wh_lookup
    dmaSet 1, WH0, DMAP_1REG_1WR, wh0_table
    dmaSet 2, WH1, DMAP_1REG_1WR, wh1_table
    ; dmaSet 1, WH0, DMAP_1REG_1WR, test
    ; dmaSet 1, WH0, DMAP_1REG_1WR, test
    
    rts
.endproc

.a8
.i16
.proc update
    stz WMADDH
    ldx #wh0_data
    stx WMADDL
    dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224 + 1
    ldx #wh1_data
    stx WMADDL
    dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, one, 224 + 1
    rts
.endproc

; in:
    ; A:16 = p1.x
    ; SP+3 = p1.y
    ; SP+5 = p2.x
    ; SP+7 = p2.y
.a16
.i16
.proc bresenham
    localVars
    var p1x, 2
    var p2x, 2
    var p1y, 2
    var p2y, 2
    var dx,  2
    var dy,  2
    var sx,  2
    var sy,  2
    var err, 2
    var cx,  2
    var cy,  2

    ; set p1, p2 and c
    sta p1x
    sta cx
    lda 3, s
    sta p1y
    sta cy
    lda 5, s
    sta p2x
    lda 7, s
    sta p2y

    ; info byte
    a8
    lda #$80 | 127
    sta wh0_table
    sta wh1_table
    lda #$80 | (224 - 127)
    sta wh0_data + 127
    sta wh1_data + 127
    a16

    ; dx = abs(p2.x - p1.x)
    lda p2x
    sec
    sbc p1x
    abs
    sta dx
    
    ; dy = -abs(p2.y - p1.y)
    lda p2y
    sec
    sbc p1y
    abs
    neg
    sta dy

    ; sx = p1.x < p2.x ? 1 : -1
    lda #1
    sta sx
    lda p1x
    cmp p2x
    bmi :+
        lda #mi(1)
        sta sx
    :
    
    ; sy = p1.y < p2.y ? 1 : -1
    lda #1
    sta sy
    lda p1y
    cmp p2y
    bmi :+
        lda #mi(1)
        sta sy
    :

    ; err = dx + dy
    lda dx
    clc
    adc dy
    sta err

    ; num_pixels = max(dx, -dy)
    lda dx
    tax
    lda dy
    neg
    cmp dx
    bmi :+
        tax
    :
    ; for (0..num_pixels)
    loop:
        ; TODO bounds check
        ; set pixel
        ldy cy
        cpy #127
        bcc :+
            iny ; skip over the info byte in the middle
        :
        a8
        lda cx
        sta wh0_data, y
        clc
        adc #10
        sta wh1_data, y
        a16

        ; e2 = err * 2
        var e2, 2
        lda err
        asl
        sta e2

        ; if e2 >= dy
        ; lda e2
        cmp dy
        bmi xMoveEnd
            ; if c.x == p2.x then break
            lda cx
            cmp p2x
            beq loopEnd

            ; err += dy
            lda err
            clc
            adc dy
            sta err

            ; cx += sx
            lda cx
            clc
            adc sx
            sta cx
        xMoveEnd:

        ; if e2 <= dx
        lda e2
        cmp dx
        beq yMove
        bpl yMoveEnd
        yMove:
            ; if c.y == p2.y then break
            lda cy
            cmp p2y
            beq loopEnd
            
            ; err += dx
            lda err
            clc
            adc dx
            sta err

            lda cy
            clc
            adc sy
            sta cy
        yMoveEnd:

        dex
        bne loop
    loopEnd:

    ; ; info bytes
    ; pla
    ; a8
    ; ply
    ; sta LineInfo::length, y
    ; lda #Direction::Forward
    ; sta LineInfo::x_dir, y
    ; sta LineInfo::y_dir, y
    ; a16

    ; lda p1x
    ; cmp p2x
    ; bmi :+
    ;     a8
    ;     lda #Direction::Backward
    ;     sta LineInfo::x_dir, y
    ;     a16
    ; :
    ; lda p1y
    ; cmp p2y
    ; bmi :+
    ;     a8
    ;     lda #Direction::Backward
    ;     sta LineInfo::y_dir, y
    ;     a16
    ; :
    
    rts
.endproc

.a8
.i16
.proc vblank
    lda #%110
    sta HDMAEN
    
    rts
.endproc
    
.endscope
