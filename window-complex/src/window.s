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

.a8
.i16
.proc bresenham
	localVars
	var p1,  1
	var p2,  1
	var dx,  1
	var dy,  1
	var sx,  1
	var sy,  1
	var err, 1

	lda #$ea
	sta p1
	lda #$cd
	sta dx
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
