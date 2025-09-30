.scope window

.bss

; double buffering is needed so the code that's writing to these
; tables doesn't interfere with the HDMA which is reading what's
; there currently (generated last frame)
.repeat 2, buffer_ind
    .repeat 4, window_reg_ind
        .ident(.sprintf("wh%d_data_%d", window_reg_ind, buffer_ind)): .res 256 ; even though there's 224 scanlines, allocating 256 makes the writing loop (which must be fully optimized) much easier to bounds check
    .endrepeat
.endrepeat

star_points:          .res 10 * 2 * 2 ; 16-bit X,Y values

is_drawing_window_2:  .res 2
star_point_inc_amt:   .res 2 ; what to add to X register to get next point to check (+4 for window 1 (CCW), -4 for window 2 (CW))
next_star_point_ind:  .res 2
lowest_inner_index:   .res 2 ; for splitting the star down the middle and drawing 2 windows
highest_inner_index:  .res 2

theta:                .res 1
scale:                .res 2


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

    lda #$70
    sta scale
    rts
.endproc

; inner points must reach corners of screen for star to fully disappear
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
; I've found that $0.80 for outer and $0.40 for inner produced a nice-looking star.
; multiply ($0.80 / $0.40) by 343 to get the max outer scale
; 
; both these numbers are 8.8 fixed point
SCALE_MAX_INNER = (170/127) * 256
SCALE_MAX_OUTER = SCALE_MAX_INNER * ($80/$40)
SCALE_HALF_INNER = SCALE_MAX_INNER / 2
SCALE_HALF_OUTER = SCALE_MAX_OUTER / 2

; each update loop:
;   1. calculate the scales of OUTER and INNER star points by (max scale) * ('scale' var)
;     example:
;     $02ae    $0157  | SCALE_MAX
;   x  $.10  x  $.10  | scale
;   -------  -------
;     $002a    $0015  | curr_scale
;    
;   2. then for each point:
;     1. get the cos and sin values for this point
;     2. multiply those values by OUTER or INNER scale, depending
;       example:
;       $002a    $0015 | curr_scale
;     x   $7f  x   $00 | cos or sin
;     -------  -------
;         $14      $00 | values for matrix math

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
    and #$7f
    sta M7B
    ldx MPYM
    stx inner_scale

    lda #<SCALE_MAX_OUTER
    sta M7A
    lda #>SCALE_MAX_OUTER
    sta M7A
    lda scale
    and #$7f
    sta M7B
    ldx MPYM
    stx outer_scale

    a16
    lda scale
    cmp #$0080
    bcc :+
        lda #SCALE_HALF_INNER
        clc
        adc inner_scale
        sta inner_scale
        lda #SCALE_HALF_OUTER
        clc
        adc outer_scale
        sta outer_scale
    :
    a8

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
        a16
        lda MPYM
        clc
        adc #128
        sta star_points, y
        a8

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
        a16
        lda MPYM
        pha
        lda #112
        sec
        sbc 1, s
        sta star_points+2, y
        pla
        a8

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
    ; inc theta
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
        lda scale
        cmp #0005
        beq scaleEnd
        dec scale
        bra scaleEnd
    scaleU:
        inc scale
    scaleEnd:
    a16
    lda JOY1L
    bit #JOY_L
    bne rotL
    bit #JOY_R
    bne rotR
    beq rotEnd
    rotL:
        dec theta
        bra rotEnd
    rotR:
        inc theta
    rotEnd:
    a8

    window_setStarPoints
    jsr drawStar
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
        bmi :+
            iny
            iny
        :
        lda is_drawing_right_side_tab, y
        sta is_drawing_right_side
        a8
        eor #1
        dec
        sta dda::drawLine::wall_val ; 0 or 255 based on is_drawing_right_side
        a16

        ; swap p1 and p2 if p1 is lower Y
        a16
        lda p1y
        cmp p2y
        beq next
        bpl swapEnd

        ldx p1x
        ldy p1y

        lda p2x
        sta p1x
        lda p2y
        sta p1y

        stx p2x
        sty p2y
        swapEnd:
        
        ; above and below bounds check
        lda p2y
        cmp #224
        bpl next
        lda p1y
        bmi next

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
        sta dda::drawLine::dest_addr
        
        ; dda(p1, p2)
        ; p1x, p1y, p2x, and p2y are all the same value in drawStar() and dda()
        jsr dda::drawLine

        next:
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
