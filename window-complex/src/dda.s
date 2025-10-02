.scope dda

.a16
.i16
.proc swapP1P2
    ; it's important that these line up with those of drawLine()'s; not great system but it works
    localVars
    var p1x,          2
    var p1y,          2
    var p2x,          2
    var p2y,          2

    ldx p1x
    ldy p1y

    lda p2x
    sta p1x
    lda p2y
    sta p1y

    stx p2x
    sty p2y
    rts
.endproc

.macro dda_yBoundsCheck
    ai16
    ; if p1.y >= 224
    ;     overflow_amt = p1.y - 224
    ;     p1.x += overflow_amt * xadd
    ;     p1.y = 223
    lda p1y
    cmp #224 + 128
    bmi :+
        lda #224 + 127
        sta p1y
    :
    sec
    sbc #224
    bmi bottomCheckEnd
        overflow_amt = temp
        a8
        sta overflow_amt
        sta M7B
        lda xadd
        sta M7A
        lda xadd+1
        sta M7A
        a16
        lda p1x
        ldx is_xdiff_neg
        bne :+
            clc
            adc MPYM
            bra :++
        :
            sec
            sbc MPYM
        :
        sta p1x
        lda #223
        sta p1y
    bottomCheckEnd:
    a16

    ; if p2.y < 0
    ;     len -= abs(p2.y)
    ;     OR
    ;     len += p2.y (since it's negative)
    ;     OR
    ;     len = p1.y
    lda p2y
    bpl topBoundsCheckEnd
        neg
        a8
        sta M7B
        lda xadd
        sta M7A
        lda xadd+1
        sta M7A
        a16
        lda p2x
        ldx is_xdiff_neg
        beq :+ ; backwards; if the line goes up and to the right, go down and to the left
            clc
            adc MPYM
            bra :++
        :
            sec
            sbc MPYM
        :
        sta p2x
        stz p2y
    topBoundsCheckEnd:
.endmacro

.macro dda_xBoundsCheck
    ai16
    ; if (p1.x < 0 and p1.x < 0) or (p1.x >= 256) and (p2.x >= 256)
    ;bothPastLeftCheck:
    lda p1x
    bpl bothPastRightCheck
    lda p2x
    bpl bothPastRightCheck
    a8
    stz wall_val
    a16
    bra bothPastLeftOrRight
    bothPastRightCheck:
    a8
    lda p1x+1
    beq bothPastLeftOrRightCheckEnd
    lda p2x+1
    beq bothPastLeftOrRightCheckEnd
    lda #$ff
    sta wall_val
        bothPastLeftOrRight:
        a16
        inc are_both_off_sides
        jmp boundsCheckEnd
    bothPastLeftOrRightCheckEnd:

    ; if p1.x >= 256
    a8
    lda p1x+1
    beq p2RightCheck
    bmi p1Left
    p1Right:
        lda #$ff
        sta wall_val
        jsr swapP1P2
        inc is_p1_off_sides
        bra boundsCheckEnd
    .a8
    p2RightCheck:
    ; if p2.x >= 256
    ;     is_p2_off_sides = true
    ;     (dest_addr and len do not change)
    lda p2x+1
    beq boundsCheckEnd
    bmi p2Left
    p2Right:
        lda #$ff
        sta wall_val
        inc is_p2_off_sides
        bra boundsCheckEnd

    .a8
    p1Left:
        stz wall_val
        jsr swapP1P2
        inc is_p1_off_sides
        bra boundsCheckEnd
    .a8
    p2Left:
        stz wall_val
        inc is_p2_off_sides
    boundsCheckEnd:
.endmacro

.code

.a16
.i16
.proc drawLine
    localVars
    var p1x,          2
    var p1y,          2
    var p2x,          2
    var p2y,          2
    var xdiff,        1
    var ydiff,        1
    var is_xdiff_neg, 2
    var xadd,         2 ; 8.8 fixed point; amount to add to current X pos each iteration
    var dest_addr,    2 ; param

    var wall_val,           1 ; when lines go off the left or right side of the screen, this dictactes what value to write instead (0 or 255)
    var len,                2
    var is_p1_off_sides,    2
    var is_p2_off_sides,    2
    var are_both_off_sides, 2

    stz is_xdiff_neg
    stz is_p1_off_sides
    stz is_p2_off_sides
    stz are_both_off_sides

    ; xdiff = abs(p2.x - p1.x)
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
    ; same as p1.y - p2.y since p1.y is always greater
    lda p1y
    sec
    sbc p2y
    a8
    sta ydiff

    ; xadd = xdiff / ydiff
    lda xdiff
    xba
    lda #0
    tax ; if xdiff is 7, X:16 = $700
    lda ydiff
    div
    stx xadd

    ; bounds checks & position corrections
    dda_yBoundsCheck
    dda_xBoundsCheck

    ; set length of line
    a16
    ldx is_p1_off_sides
    bne :+
        lda p1y
        sec
        sbc p2y
        bra :++
    :
        lda p2y
        sec
        sbc p1y
    :
    sta len
    ; a8

    ; add line's topmost Y to dest_addr, makes the loop easier if Y ends at 0
    ; a16
    lda dest_addr
    clc
    ldx is_p1_off_sides
    bne :+
        adc p2y
        bra :++
    :
        adc p1y
    :
    sta dest_addr
    ai8

    ldy len

    lda are_both_off_sides
    beq :+
    ; wdm 0
    jmp wallLoop
    :

    ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda #$80
    xba
    lda p1x
    ldx is_p2_off_sides
    bne decLoopWithCheck
    ldx is_p1_off_sides
    bne incLoopWithCheck
    ; normal loop
    ldx is_xdiff_neg
    cpx #1
    bcs @subLoop ; carry set from lda is_xdiff_neg, ror
        @addLoop:
        sta (dest_addr), y

        xba
        adc xadd
        xba
        adc xadd+1

        dey
        bne @addLoop
    bra end
        @subLoop:
        sta (dest_addr), y

        xba
        sbc xadd
        xba
        sbc xadd+1

        dey
        bne @subLoop
    bra end

    decLoopWithCheck:
    ldx is_xdiff_neg
    cpx #1
    bcs @subLoop ; carry set from lda is_xdiff_neg, ror
        @addLoop:
        sta (dest_addr), y
        dey
        beq end

        xba
        adc xadd
        xba
        adc xadd+1
        bcc @addLoop
    bra wallLoop
        @subLoop:
        sta (dest_addr), y
        dey
        beq end

        xba
        sbc xadd
        xba
        sbc xadd+1
        bcs @subLoop
    bra wallLoop

    incLoopWithCheck:
    pha
    ; going backwards so flip the direction
    lda is_xdiff_neg
    eor #1
    cmp #1
    pla
    ldy #1
    bcs @subLoop
        @addLoop:
        sta (dest_addr), y
        iny

        xba
        adc xadd
        xba
        adc xadd+1
        bcc @addLoop
    bra incLoopAfter
        @subLoop:
        sta (dest_addr), y
        iny

        xba
        sbc xadd
        xba
        sbc xadd+1
        bcs @subLoop
    incLoopAfter:
    ai16
    cpy len
    bcs end
    tya
    clc
    adc dest_addr
    dec
    sta dest_addr
    sty temp
    lda len
    sec
    sbc temp
    tay
    iny
    ai8

    wallLoop:
    cpy #0
    beq end
    lda wall_val
        @loop:
        sta (dest_addr), y
        dey
        bne @loop    

    end:
    ai16
    rts
.endproc

.endscope
