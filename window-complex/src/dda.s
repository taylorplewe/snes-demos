.scope dda

.code

; in:
    ; A:16 = p1.x
    ; SP+3 = p1.y
    ; SP+5 = p2.x
    ; SP+7 = p2.y
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
    var curr_pos,     2 ; current 8:8 fixed position of the SHORTER axis of the two (the other just inc's or dec's by 1 each iteration)
    var inc_amount,   2 ; amount to add to curr_pos each iteration
    var dest_addr,    2 ; param

    var wall_val,        1 ; when lines go off the left or right side of the screen, this dictactes what value to write instead (0 or 255)
    var wall_before_len, 1
    var normal_len,      1
    var wall_after_len,  1

    stz is_xdiff_neg ; TODO: might be able to delete this

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
    lda p2y
    sec
    sbc p1y
    abs
    a8
    sta ydiff

    ; xadd = xdiff / ydiff
    lda xdiff
    xba
    lda #0
    tax ; if xdiff is 7, X:16 = $700
    lda ydiff
    div
    stx inc_amount

    ; add p2.y to dest_addr, makes the loop easier if Y ends at 0
    a16
    lda dest_addr
    clc
    adc p2y
    sta dest_addr
    a8

    ldy wall_before_len
    lda wall_val
    wallBeforeLoop:
        sta (dest_addr), y
        dey
        bne wallBeforeLoop

    ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda #$80
    xba
    lda p1x
    i8
    ldx is_xdiff_neg
    bne @subLoop ; carry set from lda is_xdiff_neg, ror
        @addLoop:
        sta (dest_addr), y

        xba
        adc inc_amount
        xba
        adc inc_amount+1

        dey
        bne @addLoop
    bra end
        @subLoop:
        sta (dest_addr), y

        xba
        sbc inc_amount
        xba
        sbc inc_amount+1

        dey
        bne @subLoop
    bra end

    ldy wall_after_len
    lda wall_val
    wallAfterLoop:
        sta (dest_addr), y
        dey
        bne wallAfterLoop
    
    end:
    ai16
    rts
.endproc

.endscope
