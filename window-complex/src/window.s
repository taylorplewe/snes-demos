.scope window

.bss

; double buffering is needed so the code that's writing to these
; tables doesn't interfere with the HDMA which is reading what's
; there currently (generated last frame)
.repeat 2, buffer_ind
    .repeat 4, window_reg_ind
        .ident(.sprintf("wh%d_data_%d", window_reg_ind, buffer_ind)): .res 224
    .endrepeat
.endrepeat

star_points:          .res 10 * 2 * 2 ; 16-bit X,Y values

is_drawing_window_2:  .res 2
star_point_inc_amt:   .res 2 ; what to add to X register to get next point to check (+4 for window 1 (CCW), -4 for window 2 (CW))
next_star_point_ind:  .res 2
lowest_inner_index:   .res 2 ; for splitting the star down the middle and drawing 2 windows
highest_inner_index:  .res 2

theta:                .res 1
scale:                .res 1


.rodata

two: .byte 2
one: .byte 1

.repeat 2, buffer_ind
    .repeat 4, window_reg_ind
        .ident(.sprintf("wh%d_hdma_table_%d", window_reg_ind, buffer_ind)):
            .byte $80 | 112
            .addr .ident(.sprintf("wh%d_data_%d", window_reg_ind, buffer_ind))
            .byte $80 | 112
            .addr .ident(.sprintf("wh%d_data_%d", window_reg_ind, buffer_ind)) + 112
            .byte 0
    .endrepeat
.endrepeat

.code

.a8
.i16
.proc init
    lda #WSEL(WSEL_LAYER_BG1, WSEL_W1, WSEL_INVERT) | WSEL(WSEL_LAYER_BG1, WSEL_W2, WSEL_INVERT)
    sta W12SEL
    lda #WLOG(WLOG_LAYER_BG1, WLOG_AND)
    sta WBGLOG
    lda #TMSW_BG1
    sta TMW

    lda #05
    sta scale
    rts
.endproc

; inner points must reach corners of screen for star to disappear
; 
;    /|
;  x/ | 112
;  /  |
; _____
;  128
; x = sqrt(112^2 + 128^2) ~= 170
; highest value from sintab = $7f = 127
; 1.0 in fixed point = $100 = 256
; (170/127) * 256 = 343 ($157)
; $1.57 is what to scale the max sintab val in order to reach corner of screen
; what about outer?
; I've found that $0.80 for outer and $0.50 for inner produced a nice-looking star.
; $80 (128) / $50 (80) = 1.6
; 1.6 * 343 ~= 549 ($225)
;
; so maximum OUTER scale is $2.25 and maxiumum INNER scale is $1.57
; 
; both these numbers are 8.8 fixed point
; SCALE_MAX_OUTER = $225 ; 549
; SCALE_MAX_INNER = $157 ; 343
SCALE_MAX_INNER = (170/127) * 256
SCALE_MAX_OUTER = SCALE_MAX_INNER * ($80/$40)

; each update loop:
;   1. calculate the scales of OUTER and INNER star points by max scale * current scale
;     example:
;     $0225    $0157  | SCALE_MAX
;   x  $.10  x  $.10  | scale
;   -------  -------
;     $0022    $0015  | curr_scale
;    
;   2. then for each point:
;     1. get the cos and sin values for this point
;     2. multiply those values by OUTER or INNER scale, depending
;       example:
;       $0022    $0015 | curr_scale
;     x   $7f  x   $00 | cos or sin
;     -------  -------
;         $10      $00 | values for matrix math

.a8
.i16
.macro window_setStarPoints
    .local loop
    localVars
    var curr_theta,  1
    var inner_scale, 2
    var outer_scale, 2

    ; calculate inner_scale and outer_scale
    lda #<SCALE_MAX_INNER
    sta M7A
    lda #>SCALE_MAX_INNER
    sta M7A
    lda scale
    sta M7B
    ldx MPYM
    stx inner_scale

    lda #<SCALE_MAX_OUTER
    sta M7A
    lda #>SCALE_MAX_OUTER
    sta M7A
    lda scale
    sta M7B
    ldx MPYM
    stx outer_scale

    ; generate points, starting with theta, and increasing the degree by 256/10 for 10 points
    lda theta
    sta curr_theta
    ldy #0
    loop:
        ; point = { sin(curr_theta) * scale, cos(curr_theta) * scale }
        lda curr_theta
        jsr sin
        xba
        sta M7B
        tya
        and #%100
        a16
        beq :+
            lda inner_scale
            bra :++
        :
            lda outer_scale
        :
        a8
        sta M7A
        xba
        sta M7A
        lda MPYM
        clc
        adc #128
        sta star_points, y

        lda curr_theta
        jsr cos
        xba
        sta M7B
        tya
        and #%100
        a16
        beq :+
            lda inner_scale
            bra :++
        :
            lda outer_scale
        :
        a8
        sta M7A
        xba
        sta M7A
        lda MPYM
        pha
        lda #112
        sec
        sbc 1, s
        sta star_points+2, y
        pla

        ; next
        lda curr_theta
        sec
        sbc #26 ; 256/10 = 25.6, rounded
        sta curr_theta
        iny
        iny
        iny
        iny
        cpy #10 * 2 * 2 ; last point
        bcc loop
    inc theta
.endmacro

.a8
.i16
.proc update
    a16
    lda JOY1L
    bit #JOY_U
    bne scaleU
    bit #JOY_D
    beq scaleEnd
    ;scaleD:
        a8
        dec scale
        bra scaleEnd
    scaleU:
        a8
        inc scale
    scaleEnd:
    a8

    window_setStarPoints
    jsr drawStar
    rts
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
    var curr_pos,     2 ; current 8:8 fixed position of the SHORTER axis of the two (the other just inc's or dec's by 1 each iteration)
    var xdiff,        1
    var ydiff,        1
    var is_xdiff_neg, 2 ; bool
    var is_ydiff_neg, 2
    var inc_amount,   2 ; amount to add to curr_pos each iteration
    var dest_addr,    2

    stz is_xdiff_neg
    stz is_ydiff_neg

    ; set p1, p2 and c
    sta p1x
    lda 3, s
    sta p1y
    lda 7, s
    sta p2y
    lda 5, s
    sta p2x

    ; xdiff = abs(p2.x - p1.x)
    ; lda p2x
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

        lda is_xdiff_neg
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
        lda ydiff
        tax
        inx ; draw last pixel too

        lda is_ydiff_neg
        bne :+
            jmp yIncBeforeLoop
        :
        jmp yDecBeforeLoop
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
        bne xDecBeforeLoop
        ;bra xIncBeforeLoop
    end:

    .a8
    .i16
    xIncBeforeLoop:
    ; cy = (p1y << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda p1y
    xba
    lda #$80
    tay
    sty curr_pos
    ai8
    lda p1x
    pha
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
    plx
    ai16
    rts

    .a8
    .i16
    xDecBeforeLoop:
    ; cy = (p1y << 8) + $80 (.5)
    lda p1y
    xba
    lda #$80
    tay
    sty curr_pos
    ai8
    lda p1x
    pha
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
    xEnd:
    plx
    ai16
    rts

    .a8
    .i16
    yIncBeforeLoop:
    ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda #$80
    xba
    lda p1x
    i8
    ldy p1y
    yIncLoop:
        ; plot pixel
        a8
        sta (dest_addr), y
        a16
        iny

        xba
        clc
        adc inc_amount
        xba

        dex
        bne yIncLoop
    ai16
    rts

    .a8
    .i16
    yDecBeforeLoop:
    ; cx = (p1x << 8) + $80 (.5) (so as to be "in the middle of the pixel")
    lda #$80
    xba
    lda p1x
    i8
    ldy p1y
    yDecLoop:
        ; plot pixel
        a8
        sta (dest_addr), y
        a16
        dey

        xba
        clc
        adc inc_amount
        xba

        dex
        bne yDecLoop
    ai16
    rts
.endproc

.a8
.i16
.macro window_clearNextWindowBuffer
    stz WMADDH
    lda counter
    lsr
    bcs :+
        ldx #wh0_data_0
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224
        ldx #wh1_data_0
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, one, 224
        ldx #wh2_data_0
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224
        ldx #wh3_data_0
        bra :++
    :
        ldx #wh0_data_1
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224
        ldx #wh1_data_1
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, one, 224
        ldx #wh2_data_1
        stx WMADDL
        dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, two, 224
        ldx #wh3_data_1
    :
    stx WMADDL
    dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, one, 224
.endmacro

.a16
.i16
.macro window_findHighestAndLowestInnerIndexes
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

.rodata
; DUdu | D = drawing D on w1, U = drawing U on w1, d = drawing D on w2, u = drawing U on w2
is_drawing_right_side_tab: .word 0, 1, 1, 0

; 12345667
; --------
; 11112222 buffers 1 and 2
; 11221122 windows 1 and 2 
; LRLRLRLR left and right sides
dest_addr_tab:
    .addr wh0_data_0
    .addr wh1_data_0
    .addr wh2_data_0
    .addr wh3_data_0
    .addr wh0_data_1
    .addr wh1_data_1
    .addr wh2_data_1
    .addr wh3_data_1
.code

.a8
.i16
.proc drawStar
    localVars
    var p1x,                   2
    var p1y,                   2
    var p2x,                   2
    var p2y,                   2
    var start_index,           2
    var is_drawing_right_side, 2

    window_clearNextWindowBuffer
    a16
    window_findHighestAndLowestInnerIndexes

    stz is_drawing_window_2
    lda #4
    sta star_point_inc_amt
    ldx lowest_inner_index
    loop:
        ; set p1
        lda star_points, x
        sta p1x
        lda star_points+2, x
        sta p1y

        ; set p2
        cpx highest_inner_index ; if at highest inner point (uppermost appearing onscreen), go across star
        bne p2SetNext
        p2SetLowest:
            ldy lowest_inner_index
            sty next_star_point_ind
            lda star_points, y
            sta p2x
            lda star_points+2, y
            bra p2SetEnd
        p2SetNext:
            phx
            txa
            clc
            adc star_point_inc_amt
            ; wrapped around backwards?
            bpl :+
                lda #9 * 4
                bra :++
            :
            ; wrapped around forwards?
            cmp #10 * 4
            bcc :+
                lda #0
            :
            tax
            lda star_points, x
            sta p2x
            lda star_points+2, x
            stx next_star_point_ind
            plx
        p2SetEnd:
        sta p2y

        ; is_drawing_right_side = if is_drawing_window_2 { p2.y > p1.y } else { p1.y > p2.y }
        ldy #0
        lda is_drawing_window_2
        beq :+
            iny
            iny
            iny
            iny
        :
        lda p1y
        cmp p2y
        bcc :+
            iny
            iny
        :
        lda is_drawing_right_side_tab, y
        sta is_drawing_right_side

        ; dda::dest_addr = &whW_data_B, where W = one of [0,1,2,3] and B = one of [0,1]
        ldy #0
        lda counter
        lsr
        bcc :+
            ldy #8
        :
        lda is_drawing_window_2
        beq :+
            iny
            iny
            iny
            iny
        :
        lda is_drawing_right_side
        beq :+
            iny
            iny
        :
        lda dest_addr_tab, y
        sta dda::dest_addr
        
        ; dda(p1, p2)
        lda p2y
        pha
        lda p2x
        pha
        lda p1y
        pha
        lda p1x
        jsr dda
        pla
        pla
        pla

        ; next
        ldx next_star_point_ind
        cpx lowest_inner_index
        beq loopEnd
        jmp loop
    loopEnd:

    lda is_drawing_window_2
    bne :+
        inc is_drawing_window_2
        lda #mi(4)
        sta star_point_inc_amt
        ldx lowest_inner_index
        jmp loop
    :

    a8

    ; set up DMA for next buffer
    lda counter
    lsr
    bcs :+
        hdmaSet 1, WH0, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh0_hdma_table_0, wh0_data_0
        hdmaSet 2, WH1, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh1_hdma_table_0, wh1_data_0
        hdmaSet 3, WH2, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh2_hdma_table_0, wh2_data_0
        hdmaSet 4, WH3, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh3_hdma_table_0, wh3_data_0
        bra :++
    :
        hdmaSet 1, WH0, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh0_hdma_table_1, wh0_data_1
        hdmaSet 2, WH1, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh1_hdma_table_1, wh1_data_1
        hdmaSet 3, WH2, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh2_hdma_table_1, wh2_data_1
        hdmaSet 4, WH3, DMAP_1REG_1WR | DMAP_HDMA_INDIRECT, wh3_hdma_table_1, wh3_data_1
    :
    lda #%11110
    sta HDMAEN

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
