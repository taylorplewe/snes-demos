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
    var curr_pos,     2 ; 8.8 fixed point; current X position
    var xadd,         2 ; 8.8 fixed point; amount to add to curr_pos each iteration
    var yadd,         2
    var dest_addr,    2 ; param

    var wall_val,        1 ; when lines go off the left or right side of the screen, this dictactes what value to write instead (0 or 255)
    var wall_before_len, 2
    var normal_len,      2 ; TODO might just do normal_len = ydiff since theyre the same, and once normal_len starts changing ydiff isnt needed anymore
    var wall_after_len,  2

    stz is_xdiff_neg ; TODO: might be able to delete this
    stz wall_before_len
    stz normal_len
    stz wall_after_len

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
    sta normal_len

    ; xadd = xdiff / ydiff
    lda xdiff
    xba
    lda #0
    tax ; if xdiff is 7, X:16 = $700
    lda ydiff
    div
    stx xadd

    ; yadd = ydiff / xdiff
    lda ydiff
    xba
    lda #0
    tax ; if ydiff is 7, X:16 = $700
    lda xdiff
    div
    stx yadd

    

    ; add p2.y to dest_addr, makes the loop easier if Y ends at 0
    a16
    lda dest_addr
    clc
    adc p2y
    sta dest_addr
    a8
    ldy wall_before_len
    beq normalLoop
    lda wall_val
    wallBeforeLoop:
        sta (dest_addr), y
        dey
        bne wallBeforeLoop
    a16
    lda dest_addr
    sec
    sbc normal_len
    sta dest_addr
    a8

    normalLoop:
    ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda #$80
    xba
    lda p1x
    i8
    ldy normal_len
    beq end
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
    bra wallAfter
        @subLoop:
        sta (dest_addr), y

        xba
        sbc xadd
        xba
        sbc xadd+1

        dey
        bne @subLoop

    wallAfter:
    ldy wall_after_len
    beq end
    a16
    lda dest_addr
    sec
    sbc wall_after_len
    sta dest_addr
    a8
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
