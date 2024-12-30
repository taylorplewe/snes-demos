.scope tank

WIDTH = 32
HEIGHT = 32

.struct Tank
	x_pos .word
	y_pos .word
.endstruct
.zeropage
tank: .tag Tank

.code
.proc init
	; init tank's data
	stz tank + Tank::x_pos
	lda #128
	sta tank + Tank::x_pos + 1
	stz tank + Tank::y_pos
	lda #112
	sta tank + Tank::y_pos + 1
	rts
.endproc

.proc update
	a16
	lda tank + Tank::x_pos
	clc
	adc #$0040
	sta tank + Tank::x_pos
	lda tank + Tank::y_pos
	clc
	adc #$0020
	sta tank + Tank::y_pos
	a8
	rts
.endproc

.proc draw
	i8
	ldx oam_lo_ind
	i16
	; draw circle
	; x
		lda tank + Tank::x_pos + 1
		sec
		sbc #WIDTH/2
		sta OAM_X, x
	; y
		lda tank + Tank::y_pos + 1
		sec
		sbc #HEIGHT/2
		sta OAM_Y, x
	; tile
		stz OAM_TILE, x
	; info
		lda #SPRINFO_PAL(0) | SPRINFO_PRIOR3
		sta OAM_INFO, x
	; hi
		lda #SPR_HI_LARGE
		jsr set_oam_hi_bits
	i8
	txa
	i16
	clc
	adc #4
	sta oam_lo_ind
	rts
.endproc

.endscope