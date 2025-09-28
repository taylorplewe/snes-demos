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
    var curr_pos,     2 ; current 8:8 fixed position of the SHORTER axis of the two (the other just inc's or dec's by 1 each iteration)
    var xdiff,        1
    var ydiff,        1
    var is_xdiff_neg, 2 ; bool
    var inc_amount,   2 ; amount to add to curr_pos each iteration
    var dest_addr,    2 ; param

    stz is_xdiff_neg

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

    ; set length
    lda #0
    xba
    lda ydiff
    tax
    inx ; draw last pixel too

	lda is_xdiff_neg
	ror
    ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda #$80
    xba
    lda p1x
    i8
	ldy p1y
    bcs @subLoop ; carry set from lda is_xdiff_neg, ror
        @addLoop:
        ; plot pixel
        sta (dest_addr), y
        dey

        xba
        adc inc_amount
        xba
        adc inc_amount+1

        dex
        bne @addLoop
    bra yEnd
        @subLoop:
        ; plot pixel
        sta (dest_addr), y
        dey

        xba
        sbc inc_amount
        xba
        sbc inc_amount+1

        dex
        bne @subLoop
    yEnd:
    ai16
    rts
.endproc

.endscope
