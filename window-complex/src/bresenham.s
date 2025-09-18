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
        lda is_drawing_right_side
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