.scope tank

WIDTH = 32
HEIGHT = 32
MOVE_SPEED = $0120
TURN_SPEED = 2

.struct Tank
	x_pos     .word
	y_pos     .word
	angle     .byte
	dot_x_pos .word
	dot_y_pos .word
.endstruct
.zeropage
tank: .tag Tank

.code
.proc init
	; init tank's data
	stz tank + Tank::angle
	stz tank + Tank::x_pos
	lda #128
	sta tank + Tank::x_pos + 1
	stz tank + Tank::y_pos
	lda #112
	sta tank + Tank::y_pos + 1
	rts
.endproc

.enum Dir
	Forward
	Backward
	StrafeLeft
	StrafeRight
.endenum

; y = 0 = forward, 1 = backward, 2 = strafe left, 3 = strafe right
.proc move
	php
	a8
	; x (cos)
		lda tank + Tank::angle
		jsr cos
		a16
		cpy #Dir::Forward
		beq :+
		cpy #Dir::StrafeRight
		beq :+
			eor #$ffff
			inc a
		:
		.repeat 6
			asr16
		.endrepeat
		cpy #Dir::StrafeLeft
		beq :+
		cpy #Dir::StrafeRight
		beq :+
			clc
			adc tank + Tank::x_pos
			sta tank + Tank::x_pos
			bra :++
		:
			clc
			adc tank + Tank::y_pos
			sta tank + Tank::y_pos
		:
	; y (sin)
		a8
		lda tank + Tank::angle
		jsr sin
		a16
		cpy #Dir::Forward
		beq :+
		cpy #Dir::StrafeLeft
		beq :+
			eor #$ffff
			inc a
		:
		.repeat 6
			asr16
		.endrepeat
		cpy #Dir::StrafeLeft
		beq :+
		cpy #Dir::StrafeRight
		beq :+
			clc
			adc tank + Tank::y_pos
			sta tank + Tank::y_pos
			bra :++
		:
			clc
			adc tank + Tank::x_pos
			sta tank + Tank::x_pos
		:
	plp
	rts
.endproc

.proc update
	; move tank
	a16
	lda JOY1L
	bit #JOY_L
	beq :+
		a8
		lda tank + Tank::angle
		sec
		sbc #TURN_SPEED
		sta tank + Tank::angle
		a16
		bra :++
	:
	lda JOY1L
	bit #JOY_R
	beq :+
		a8
		lda tank + Tank::angle
		clc
		adc #TURN_SPEED
		sta tank + Tank::angle
		a16
	:
	lda JOY1L
	bit #JOY_U
	beq :+
		ldy #Dir::Forward
		jsr move
		bra :++
	:
	bit #JOY_D
	beq :+
		ldy #Dir::Backward
		jsr move
	:
	lda JOY1L
	bit #JOY_SHOULDER_L
	beq :+
		ldy #Dir::StrafeLeft
		jsr move
		bra :++
	:
	bit #JOY_SHOULDER_R
	beq :+
		ldy #Dir::StrafeRight
		jsr move
	:
	a8

	; position dot
	; x
		lda tank + Tank::angle
		jsr cos
		a16
		.repeat 2
			asr16
		.endrepeat
		clc
		adc tank + Tank::x_pos
		sta tank + Tank::dot_x_pos
	; y
		a8
		lda tank + Tank::angle
		jsr sin
		a16
		.repeat 2
			asr16
		.endrepeat
		clc
		adc tank + Tank::y_pos
		sta tank + Tank::dot_y_pos
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
		lda #SPRINFO_PRIOR3 | SPRINFO_PAL(0)
		sta OAM_INFO, x
	; hi
		lda #SPR_HI_LARGE
		jsr set_oam_hi_bits
	
	.repeat 4
		inx
	.endrepeat

	; draw pointer
	; x
		lda tank + Tank::dot_x_pos + 1
		sec
		sbc #4
		sta OAM_X, x
	; y
		lda tank + Tank::dot_y_pos + 1
		sec
		sbc #4
		sta OAM_Y, x
	; tile
		lda #4
		sta OAM_TILE, x
	; info
		lda #SPRINFO_PRIOR3 | SPRINFO_PAL(0)
		sta OAM_INFO, x
	; hi
		lda #0
		jsr set_oam_hi_bits

	.repeat 4
		inx
	.endrepeat
	i8
	stx oam_lo_ind
	i16
	rts
.endproc

.endscope