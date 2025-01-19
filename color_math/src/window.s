.scope window

BG_WINDOW_SIZE = 116
BG_WINDOW_SPEED = 2

WH2_HDMA_TABLE_ADDR = $200
WH3_HDMA_TABLE_ADDR = $300

	.zeropage
bg_x:	.res 1
bg_y:	.res 1

	.code
.proc init
	lda #WSEL(WSEL_LAYER_COL, WSEL_W2, WSEL_NOINVERT)
	sta WOBJSEL
	stz bg_x
	stz bg_y
	stz WH2
	stz WH3

	; ; set up hdma
	dma_set 4, WH2, DMAP_1REG_1WR, WH2_HDMA_TABLE_ADDR
	dma_set 5, WH3, DMAP_1REG_1WR, WH3_HDMA_TABLE_ADDR
	lda #%110000
	tsb m_hdmaen
	rts
.endproc

.proc update
	jsr control_bg_window
	jmp fill_hdma_tables
	; rts
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

.proc fill_hdma_tables
	; TOP section (blank until <bg_y> # of scanlines)
	ldx #0
	lda bg_y
	beq :+
		; blank for <bg_y> # of scanlines
		sta WH2_HDMA_TABLE_ADDR, x
		sta WH3_HDMA_TABLE_ADDR, x
		inx
		stz WH3_HDMA_TABLE_ADDR, x
		lda #1
		sta WH2_HDMA_TABLE_ADDR, x
		inx
	:

	; MAIN section (where bg is visible)
	lda #$80 | BG_WINDOW_SIZE
	sta WH2_HDMA_TABLE_ADDR, x
	sta WH3_HDMA_TABLE_ADDR, x
	inx
	ldy #BG_WINDOW_SIZE
	lda bg_x
	clc
	adc #BG_WINDOW_SIZE
	xba
	lda bg_x
	loop:
		sta WH2_HDMA_TABLE_ADDR, x
		xba
		sta WH3_HDMA_TABLE_ADDR, x
		xba
		inx
		dey
		bne loop

	; BOTTOM section (blank for rest of screen)
	lda bg_y
	cmp #223-BG_WINDOW_SIZE
	bcs :+
		lda #223-BG_WINDOW_SIZE
		sec
		sbc bg_y
		sta WH2_HDMA_TABLE_ADDR, x
		sta WH3_HDMA_TABLE_ADDR, x
		inx
		stz WH3_HDMA_TABLE_ADDR, x
		lda #1
		sta WH2_HDMA_TABLE_ADDR, x
	:
	rts
.endproc

.endscope
