CURSOR_INIT_X = 256/2 - 32/2
CURSOR_INIT_Y = 224/2 - 32/2

.zeropage
cursor_x: .res 1
cursor_y: .res 1
.code

cursor_init:
	lda #CURSOR_INIT_X
	sta cursor_x
	lda #CURSOR_INIT_Y
	sta cursor_y

	rts

cursor_update:
	; click = debug stuff
	a16
	lda z:mouse_input_pressed
	and #MOUSE_L
	a8
	beq :+
		stz z:refresh_screen_ind
	:

	lda z:mouse_input+2
	bmi @xmi
	; xpl:
		and #$7f
		clc
		adc cursor_x
		bcc @xst
		lda #$ff
		bra @xst
	@xmi:
		and #$7f
		beq @xend
		eor #$ff
		clc
		adc #1
		adc cursor_x
		bcs @xst
		lda #0
	@xst:
	sta cursor_x
	@xend:

	lda z:mouse_input+3
	bmi @ymi
	; ypl:
		and #$7f
		clc
		adc cursor_y
		cmp #224
		bcc @yst
		lda #223
		bra @yst
	@ymi:
		and #$7f
		beq @yend
		eor #$ff
		clc
		adc #1
		adc cursor_y
		bcs @yst
		lda #0
	@yst:
	sta cursor_y
	@yend:

	rts

cursor_draw:
	@tile = local
	@x = local+1

	; hand icon
	lda #$80
	sta @tile
	lda cursor_x
	sta @x
	cmp #16
	bcc :+
	cmp #16+40
	bcs :+
	lda cursor_y
	cmp #144
	bcc :+
	cmp #144+16
	bcs :+
		lda cursor_x
		sec
		sbc #6
		sta @x
		lda #$84
		sta @tile
	:

	lda @x
	sta OAM_X
	lda cursor_y
	sta OAM_Y
	lda @tile
	sta OAM_TILE
	lda #SPRINFO_PAL0 | SPRINFO_NT0 | SPRINFO_PRIOR3
	sta OAM_INFO
	; hi bits
	lda #SPR_HI_LARGE
	ldx oam_lo_ind
	jsr set_oam_hi_bits

	rts