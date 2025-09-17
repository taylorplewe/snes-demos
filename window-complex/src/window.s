.scope window

.bss

; double buffering is needed so the code that's writing to these
; tables doesn't interfere with the HDMA which is reading what's
; there currently (generated last frame)
;
; the following code allocates (226*8) = 1,808 bytes in total.
.repeat 2, buffer_ind
    .repeat 4, window_reg_ind
        .ident(.sprintf("wh%d_table_%d", window_reg_ind, buffer_ind)): .res 1
        .ident(.sprintf("wh%d_data_%d", window_reg_ind, buffer_ind)): .res 224 + 1
    .endrepeat
.endrepeat

star_points:         .res 10 * 2 * 2 ; 16-bit X,Y values

is_drawing_up:       .res 2
is_drawing_window_2: .res 2
lowest_inner_index:  .res 2 ; for splitting the star down the middle and drawing 2 windows
highest_inner_index: .res 2


.rodata

two: .byte 2
one: .byte 1


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
    ; dmaSet 1, WH0, DMAP_1REG_1WR, wh0_table
    ; dmaSet 2, WH1, DMAP_1REG_1WR, wh1_table
    ; dmaSet 1, WH0, DMAP_1REG_1WR, test
    ; dmaSet 1, WH0, DMAP_1REG_1WR, test

    ; first info NLTRx info byte
    lda #$80 | 127
    sta wh0_table_0
    sta wh1_table_0
    sta wh2_table_0
    sta wh3_table_0
    sta wh0_table_1
    sta wh1_table_1
    sta wh2_table_1
    sta wh3_table_1

    .macro setStarPoint x_val, y_val
        lda #x_val
        sta star_points, y
        lda #y_val
        sta star_points+2, y
        .repeat 4
            iny
        .endrepeat
    .endmacro

    ldy #0
    a16
    setStarPoint 128,  38
    setStarPoint 111,  89
    setStarPoint  57,  91
    setStarPoint 100, 124
    setStarPoint  85, 176
    setStarPoint 128, 146
    setStarPoint 170, 176
    setStarPoint 155, 124
    setStarPoint 197,  91
    setStarPoint 144,  89
    a8
    
    rts
.endproc

.a8
.i16
.proc update
    jmp drawStar
.endproc

; in:
    ; A:16 = p1.x
    ; SP+3 = p1.y
    ; SP+5 = p2.x
    ; SP+7 = p2.y
.a16
.i16
.proc dda
    localVars
    var p1x,          2
    var p2x,          2
    var p1y,          2
    var p2y,          2
    var cx,           2 ; 8:8 fixed point
    var cy,           2
    var xdiff,        1
    var ydiff,        1
    var is_xdiff_neg, 2 ; bool
    var is_ydiff_neg, 2
    var xadd,         2 ; 8:8 fixed point
    var yadd,         2
    var dest_addr,    2

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

    ; xdiff = abs(p2.x - p1.x)
    stz is_xdiff_neg
    lda p2x
    sec
    sbc p1x
    php
    cmp #$8000
    rol is_xdiff_neg ; 1 if negative, 0 otherwise
    plp
    abs
    a8
    sta xdiff
    a16

    ; ydiff = abs(p2.y - p1.y)
    stz is_ydiff_neg
    lda p2y
    sec
    sbc p1y
    php
    cmp #$8000
    rol is_ydiff_neg
    plp
    abs
    a8
    sta ydiff

    ; lda ydiff
    cmp xdiff
    bcc xDiffGreater
    yDiffGreater:
        lda is_ydiff_neg
        bne :+
            ldx #$100 ; 1.0
            bra :++
        :
            ldx #mi($100)
        :
        stx yadd

        ; xadd = xdiff / ydiff
        lda xdiff
        xba
        lda #0
        tax ; if xdiff is 7, X:16 = $700
        lda ydiff
        div
        stx xadd

        lda is_xdiff_neg
        beq :+
            a16
            txa
            neg
            sta xadd
            a8
        :

        lda #0
        xba
        lda ydiff
        tax
        inx ; draw last pixel too

        bra beforeLoop
    xDiffGreater:
        lda is_xdiff_neg
        bne :+
            ldx #$100 ; 1.0
            bra :++
        :
            ldx #mi($100)
        :
        stx xadd

        ; yadd = ydiff / xdiff
        lda ydiff
        xba
        lda #0
        tax ; if ydiff is 7, X:16 = $700
        lda xdiff
        div
        stx yadd

        lda is_ydiff_neg
        beq :+
            a16
            txa
            neg
            sta yadd
            a8
        :

        lda #0
        xba
        lda xdiff
        tax
        inx ; draw last pixel too
    end:

    beforeLoop:
        ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
        lda p1x
        xba
        lda #$80
        tay
        sty cx
        ; cy = (p1y << 8) + $80 (.5)
        lda p1y
        xba
        lda #$80
        tay
        sty cy

    loop:
        ; plot pixel
        a8
        lda #0
        xba
        lda cy + 1
        cmp #127
        bcc :+
            inc
        :
        tay
        lda cx + 1
        sta (dest_addr), y
        a16

        lda cx
        clc
        adc xadd
        sta cx

        lda cy
        clc
        adc yadd
        sta cy

        dex
        bne loop

    rts
.endproc

.a8
.i16
.macro windowClearNextWindowBuffer
    stz WMADDH
    lda counter
    and #1
    bne :+
        ldx #wh0_data_0
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224 + 1
        ldx #wh1_data_0
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, one, 224 + 1
        ldx #wh2_data_0
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224 + 1
        ldx #wh3_data_0
        bra :++
    :
        ldx #wh0_data_1
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224 + 1
        ldx #wh1_data_1
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, one, 224 + 1
        ldx #wh2_data_1
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224 + 1
        ldx #wh3_data_1
    :
    stx WMADDL
    dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, one, 224 + 1
.endmacro

.a8
.i16
.macro windowSetMiddleInfoBytes
    lda #$80 | (224 - 127)
    sta wh0_data_0 + 127
    sta wh1_data_0 + 127
    sta wh2_data_0 + 127
    sta wh3_data_0 + 127
    sta wh0_data_1 + 127
    sta wh1_data_1 + 127
    sta wh2_data_1 + 127
    sta wh3_data_1 + 127
.endmacro

.a16
.i16
.macro windowFindHighestAndLowestInnerIndexes
    .local loop
    var ly, 2
    var hy, 2

    lda star_points+6
    sta ly
    sta hy
    lda #4
    sta lowest_inner_index
    sta highest_inner_index
    ldx #3 * 4 ; 2nd inner point
    loop:
        lda star_points+2, x
        pha
        cmp ly
        bpl :+
            sta ly
            stx lowest_inner_index
        :
        pla
        cmp hy
        bmi :+
            sta hy
            stx highest_inner_index
        :
        txa
        clc
        adc #2 * 4 ; skip next 2 X,Y points
        tax
        cpx #10 * 4
        bcc loop
.endmacro

.a8
.i16
.proc drawStar
    localVars
    var p1x,         2
    var p1y,         2
    var p2x,         2
    var p2y,         2
    var start_index, 2

    windowClearNextWindowBuffer
    windowSetMiddleInfoBytes
    a16
    windowFindHighestAndLowestInnerIndexes

    stz is_drawing_up
    ldx lowest_inner_index
    loop:
        lda star_points, x
        sta p1x
        lda star_points+2, x
        sta p1y
        cpx highest_inner_index ; if at highest inner point (uppermost appearing onscreen), go across star
        beq p2SetLowest
        cpx #9 * 4 ; if at last point, wrap around to first
        bcc p2SetNext
        p2SetFirst:
            lda star_points
            sta p2x
            lda star_points+2
            bra p2SetEnd
        p2SetLowest:
            ldy lowest_inner_index
            lda star_points, y
            sta p2x
            lda star_points+2, y
            bra p2SetEnd
        p2SetNext:
            lda star_points+4, x
            sta p2x
            lda star_points+6, x
        p2SetEnd:
        sta p2y

        lda p1y
        cmp p2y
        bcc :+
            lda #1
            sta is_drawing_up
        :

        ; set dest_addr
        lda counter
        and #1
        bne setDestOdd
        ;setDestEven:
            lda is_drawing_up
            bne :+
                lda #wh0_data_0
                bra setDestEnd
            :
                lda #wh1_data_0
                bra setDestEnd
        setDestOdd:
            lda is_drawing_up
            bne :+
                lda #wh0_data_1
                bra setDestEnd
            :
                lda #wh1_data_1
                bra setDestEnd
        setDestEnd:
        sta dda::dest_addr

        phx

        lda p2y
        pha
        lda p2x
        pha
        lda p1y
        pha
        lda p1x
        jsr window::dda
        pla
        pla
        pla

        ; next:
        pla
        cmp highest_inner_index
        beq loopEnd
        clc
        adc #4
        cmp #10 * 4
        bcc :+
            lda #0
        :
        tax
        jmp loop
    loopEnd:

    a8

    lda counter
    and #1
    bne :+
        dmaSet 1, WH0, DMAP_1REG_1WR, wh0_table_0
        dmaSet 2, WH1, DMAP_1REG_1WR, wh1_table_0
        lda #%110
        bra :++
    :
        dmaSet 1, WH0, DMAP_1REG_1WR, wh0_table_1
        dmaSet 2, WH1, DMAP_1REG_1WR, wh1_table_1
        lda #%110
    :

    lda #%110
    sta HDMAEN

    rts
.endproc


; I am not going to use this function anymore as it is way too expensive; I was only able to draw about 4 1/2 lines on a medium-sized star per frame.
; I will, however, keep it here for prosperity's sake
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
    sta wh0_table_0
    sta wh1_table_0
    lda #$80 | (224 - 127)
    sta wh0_data_0 + 127
    sta wh1_data_0 + 127
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
    inx
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
        lda is_drawing_up
        beq drawWh0
        ;drawWh1:
            lda cx
            sta wh1_data_0, y
            bra drawEnd
        drawWh0:
            lda cx
            sta wh0_data_0, y
            lda #255
            sta wh1_data_0, y
        drawEnd:
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
    
    rts
.endproc

.a8
.i16
.proc vblank
    ; lda #%110
    ; sta HDMAEN
    
    rts
.endproc
    
.endscope
