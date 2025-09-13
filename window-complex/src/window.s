.scope window

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
	dmaSet 1, WH0, DMAP_2REG_1WR, wh_lookup
	
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
