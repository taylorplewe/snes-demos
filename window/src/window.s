.scope window

	.zeropage
x_pos: .res 1

	.code
.proc init
	lda #WSEL(WSEL_LAYER_OBJ, WSEL_W1, WSEL_NOINVERT)
	sta WOBJSEL
	stz x_pos
	stz WH0
	stz WH1
	; don't need if only enabling one window
	; lda #WLOG(WLOG_LAYER_OBJ, WLOG_AND)
	; sta WOBJLOG
	lda #TMSW_OBJ
	sta TMW
	rts
.endproc

.proc update
	dec x_pos
	lda x_pos
	cmp #256-16
	bcc :+
		lda #256-16
		sta x_pos
	:
	rts
.endproc

.proc vblank
	lda x_pos
	sta WH0
	clc
	adc #15
	sta WH1
	rts
.endproc

.endscope