.scope window

.bss

wh_table: .res 512


.rodata

wh_lookup:
	.incbin "..\bin\wh_lookup.bin"


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
	dmaSet 1, WH0, DMAP_2REG_1WR, wh_table
	
	rts
.endproc

points_x:
	.byte 120, 90, 130
points_y:
	.byte  40, 66,  66

; in:
	; A:8  = p1.x
	; B:8  = p2.x
    ; SP+3 = p1.y
    ; SP+4 = p2.y
    ; Y:16 = pointer to memory to write to; will write XYXYXY...
.a8
.i16
.proc bresenham
	localVars
	var p1x, 1
	var p2x, 1
    var p1y, 1
    var p2y, 1
	var dx,  1
	var dy,  1
	var sx,  1
	var sy,  1
	var err, 1
    var cx,  1
    var cy,  1

	sta p1x
    sta cx
	xba
	sta p2x
    lda 3, s
    sta p1y
    sta cy
    lda 4, s
    sta p2y

    lda p2x
    sec
    sbc p1x
    abs
    sta dx
    
    lda p2y
    sec
    sbc p1y
    abs
    neg
    sta dy

    lda p2x
    cmp p1x
    rol
    rol
    and #%10
    sec
    sbc #1
    sta sx
    
    lda p2y
    cmp p1y
    rol
    rol
    and #%10
    sec
    sbc #1
    sta sy

    lda dx
    clc
    adc dy
    sta err

    i8
    ldx dx
    lda dy
    neg
    cmp dx
    bcc :+
        ldx dy
    :
    i16
    loop:
        ; TODO bounds check
        lda cx
        sta 0, y
        lda cy
        sta 1, y

        var e2, 1
        lda err
        asl
        sta e2

        lda e2
        cmp dy
        bcc xMoveEnd
            lda cx
            cmp p2x
            beq loopEnd

            lda err
            clc
            adc dy
            sta err

            lda cx
            clc
            adc sx
            sta cx
        xMoveEnd:

        lda e2
        cmp dx
        bcc yMove
        beq yMove
        bra yMoveEnd
        yMove:
            lda cy
            cmp p2y
            beq loopEnd
            
            lda err
            clc
            adc dx
            sta err

            lda cy
            clc
            adc sy
            sta cy
        yMoveEnd:

        iny
        iny
        dex
        bne loop
    loopEnd:
    
	rts
.endproc

.a8
.i16
.proc vblank
	lda #%10
	sta HDMAEN
	
	rts
.endproc
	
.endscope
