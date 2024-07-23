render_debug:

	rts

; params:
	; x, y - x, y (8x8) of element
render_element:
	@addr = local
	sty @addr
	mul8 @addr, #32
	txa
	clc
	adc @addr
	xba
	lda #0
	xba
	a16
	clc
	adc #BG1_BUFF
	tax
	a8

	
	stz refresh_screen_ind
	rts