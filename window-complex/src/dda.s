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
    var is_ydiff_neg, 2
    var inc_amount,   2 ; amount to add to curr_pos each iteration
    var dest_addr,    2 ; param
    var is_in_bounds, 1 ; param

    stz is_xdiff_neg
    stz is_ydiff_neg

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

        lda is_ydiff_neg
        bne :+
            jmp yIncPreLoop
        :
        jmp yDecPreLoop
    xDiffGreater:
        ; yadd = ydiff / xdiff
        lda ydiff
        xba
        lda #0
        tax ; if ydiff is 7, X:16 = $700
        lda xdiff
        div
        stx inc_amount

        lda is_ydiff_neg
        beq :+
            a16
            txa
            neg
            sta inc_amount
            a8
        :

        ; set length
        lda #0
        xba
        lda xdiff
        tax
        inx ; draw last pixel too

        lda is_xdiff_neg
        bne xDecPreLoop
        ;bra xIncPreLoop
    end:

    .a8
    .i16
    xIncPreLoop:
    ; cy = ((p1y << 8) & $ff00) + $80 (.5) (so as to be "in the middle of the pixel")
    lda p1y
    xba
    lda #$80
    tay
    sty curr_pos
    ai8
    lda p1x
    pha
    lda is_in_bounds
    bne xIncLoop
    xIncCheckLoop:
        ; plot pixel
        ldy curr_pos + 1
        beq end1
        a8
        pla
        sta (dest_addr), y
        inc
        pha
        a16

        lda curr_pos
        clc
        adc inc_amount
        sta curr_pos

        dex
        bne xIncCheckLoop
    plx
    end1:
    ai16
    rts
    xIncLoop:
        ; plot pixel
        ldy curr_pos + 1
        a8
        pla
        sta (dest_addr), y
        inc
        pha
        a16

        lda curr_pos
        clc
        adc inc_amount
        sta curr_pos

        dex
        bne xIncLoop
    bra xEnd

    .a8
    .i16
    xDecPreLoop:
    ; cy = (p1y << 8) + $80 (.5)
    lda p1y
    xba
    lda #$80
    tay
    sty curr_pos
    ai8
    lda p1x
    pha
    lda is_in_bounds
    bne xDecLoop
    xDecCheckLoop:
        ; plot pixel
        ldy curr_pos + 1
        beq end1
        a8
        pla
        sta (dest_addr), y
        dec
        pha
        a16

        lda curr_pos
        clc
        adc inc_amount
        sta curr_pos

        dex
        bne xDecCheckLoop
    xEnd:
    plx
    ai16
    rts
    xDecLoop:
        ; plot pixel
        ldy curr_pos + 1
        a8
        pla
        sta (dest_addr), y
        dec
        pha
        a16

        lda curr_pos
        clc
        adc inc_amount
        sta curr_pos

        dex
        bne xDecLoop
    bra xEnd

    .a8
    .i16
    yIncPreLoop:
	lda is_xdiff_neg
	ror
    ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda #$80
    xba
    lda p1x
    i8
    ldy is_in_bounds
    bne yIncLoop
    yIncCheckLoop:
	ldy p1y
	bcs @subLoop
        @addLoop:
        ; plot pixel
        sta (dest_addr), y
        iny
        beq yEnd

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
        iny
        beq yEnd

        xba
        sbc inc_amount
        xba
		sbc inc_amount+1

        dex
        bne @subLoop
    .a8
    .i8
    yIncLoop:
	ldy p1y
    bcs @subLoop
        @addLoop:
        ; plot pixel
        sta (dest_addr), y
        iny

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
        iny

        xba
        sbc inc_amount
        xba
        sbc inc_amount+1

        dex
        bne @subLoop
    bra yEnd

    .a8
    .i16
    yDecPreLoop:
    ; cx = ((p1x << 8) & $ff00) + $80 (.5) (so as to be "in the middle of the pixel")
    lda is_xdiff_neg
	ror
    lda #$80
    xba
    lda p1x
    i8
    ldy is_in_bounds
    bne yDecLoop
    yDecCheckLoop:
	ldy is_xdiff_neg
	php
    ldy p1y
	plp
	bne @subLoop
        @addLoop:
        ; plot pixel
        sta (dest_addr), y
        dey
        beq yEnd

        xba
        clc
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
        beq yEnd

        xba
        sec
        sbc inc_amount
        xba
		sbc inc_amount+1

        dex
        bne @subLoop
    yEnd:
    ai16
    rts
    .a8
    .i8
    yDecLoop:
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
    bra yEnd
.endproc

.endscope
