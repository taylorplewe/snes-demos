.scope window

BG_WINDOW_SIZE = 48
BG_WINDOW_SPEED = 2

	.zeropage
obj_x:	.res 1
bg_x:	.res 1
bg_y:	.res 1

	.code
.proc init
	; window 1 (obj)
		lda #WSEL(WSEL_LAYER_OBJ, WSEL_W1, WSEL_INVERT)
		sta WOBJSEL
		lda #150
		sta obj_x
		stz WH0
		stz WH1
		; don't need if only enabling one window
		; lda #WLOG(WLOG_LAYER_OBJ, WLOG_AND)
		; sta WOBJLOG
	; window 2 (bg1)
		lda #WSEL(WSEL_LAYER_BG1, WSEL_W2, WSEL_INVERT)
		sta W12SEL
		stz bg_x
		stz bg_y
		stz WH2
		stz WH3
	lda #TMSW_OBJ | TMSW_BG1
	sta TMW
	rts
.endproc

.proc update
	dec obj_x
	lda obj_x
	cmp #80
	bcs :+
		lda #150
		sta obj_x
	:

	jsr control_bg_window
	rts
.endproc

.proc vblank
	; window 1 (obj)
		lda obj_x
		sta WH0
		clc
		adc #15
		sta WH1

	; window 2 (bg1)
		lda bg_x
		sta WH2
		clc
		adc #BG_WINDOW_SIZE
		sta WH3
	rts
.endproc

.proc control_bg_window
	a16
	;u
	lda JOY1L
	bit #JOY_U
	beq d
		a8
		lda bg_y
		sec
		sbc #BG_WINDOW_SPEED
		sta bg_y
		bcs :+
			stz bg_y
		:
		a16
		bra ud_end
	d:
	bit #JOY_D
	beq ud_end
		a8
		lda bg_y
		clc
		adc #BG_WINDOW_SPEED
		cmp #224-BG_WINDOW_SIZE
		bcc :+
			lda #224-BG_WINDOW_SIZE
		:
		sta bg_y
		a16
	ud_end:
	l:
	lda JOY1L
	bit #JOY_L
	beq r
		a8
		lda bg_x
		sec
		sbc #BG_WINDOW_SPEED
		sta bg_x
		bcs :+
			stz bg_x
		:
		a16
		bra lr_end
	r:
	bit #JOY_R
	beq lr_end
		a8
		lda bg_x
		clc
		adc #BG_WINDOW_SPEED
		cmp #255-BG_WINDOW_SIZE
		bcc :+
			lda #255-BG_WINDOW_SIZE
		:
		sta bg_x
		a16
	lr_end:
	a8
	rts
.endproc

.endscope