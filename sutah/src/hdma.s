; page 2-17-5 of the official SNES dev manuel
.scope hdma

	.zeropage
hmda_ready: .res 1
x_pos: .res 2
y_pos: .res 2
angle: .res 1

	.code

M7A_VALS = $200
M7B_VALS = $300
M7C_VALS = $400
M7D_VALS = $500

persp112_8: .incbin "../bin/persp112_8.bin"
persp112_8_len = *-persp112_8

.proc init
	; write 0 to M7 A,B,C and D and disable HDMA for the first 112 scanlines
	lda #112
	sta M7A_VALS
	sta M7B_VALS
	sta M7C_VALS
	sta M7D_VALS
	stz M7A_VALS+1
	stz M7B_VALS+1
	stz M7C_VALS+1
	stz M7D_VALS+1
	stz M7A_VALS+2
	stz M7B_VALS+2
	stz M7C_VALS+2
	stz M7D_VALS+2

	; then do the fancy stuff for the last 112 scanlines
	lda #$80 | 112
	sta M7A_VALS+3
	sta M7B_VALS+3
	sta M7C_VALS+3
	sta M7D_VALS+3
	rts
.endproc

.proc setup
	and #%11110
	trb m_hdmaen

	dma_set 1, M7A, DMAP_1REG_2WR, M7A_VALS
	dma_set 2, M7B, DMAP_1REG_2WR, M7B_VALS
	dma_set 3, M7C, DMAP_1REG_2WR, M7C_VALS
	dma_set 4, M7D, DMAP_1REG_2WR, M7D_VALS

.endproc

.proc run
	lda #%00011110
	tsb m_hdmaen
	rts
.endproc

.enum Dir
	Forward
	Backward
	StrafeLeft
	StrafeRight
.endenum

; y = 0 -> move forward; 1 -> move backwards; 2 -> strafe left; 3 -> strafe right
.proc move
	php
	; x
		a8
		lda angle
		jsr cos
		a16
		cpy #Dir::Backward
		beq :+
		cpy #Dir::StrafeLeft
		beq :+
			eor #$ffff
			inc a
		:

		.repeat 7
			asr16
		.endrepeat
		cpy #Dir::StrafeLeft
		beq :+
		cpy #Dir::StrafeRight
		beq :+
			clc
			adc x_pos
			sta x_pos
			bra :++
		:
			clc
			adc y_pos
			sta y_pos
		:
	; y
		a8
		lda angle
		jsr sin
		a16
		cpy #Dir::Backward
		beq :+
		cpy #Dir::StrafeLeft
		beq :+
			eor #$ffff
			inc a
		:
		.repeat 7
			asr16
		.endrepeat
		cpy #Dir::StrafeLeft
		beq :+
		cpy #Dir::StrafeRight
		beq :+
			clc
			adc y_pos
			sta y_pos
			bra :++
		:
			eor #$ffff
			inc a
			clc
			adc x_pos
			sta x_pos
		:
	plp
	rts
.endproc

.proc control
	a16
	; turn
	lda JOY1L
	bit #JOY_L
	beq :+
		a8
		dec angle
		dec angle
		ldy #3
		jsr move
		a16
		lda mode1_hscroll+1
		sec
		sbc #8
		sta mode1_hscroll+1
	:
	lda JOY1L
	bit #JOY_R
	beq :+
		a8
		inc angle
		inc angle
		ldy #2
		jsr move
		a16
		lda mode1_hscroll+1
		clc
		adc #8
		sta mode1_hscroll+1
	:

	; move
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
	bit #JOY_SHOULDER_R
	beq :+
		ldy #Dir::StrafeRight
		jsr move
		a16
		lda mode1_hscroll
		clc
		adc #$20
		sta mode1_hscroll
		a8
		lda mode1_hscroll+2
		adc #0
		sta mode1_hscroll+2
		bra :++
	:
	.a16
	bit #JOY_SHOULDER_L
	beq :+
		ldy #Dir::StrafeLeft
		jsr move
		a16
		lda mode1_hscroll
		sec
		sbc #$20
		sta mode1_hscroll
		a8
		lda mode1_hscroll+2
		sbc #0
		sta mode1_hscroll+2
	:
	a8
	rts
.endproc

.proc calc_persp_rot_m7_vals
	locals
		is_cos_neg: .res 2
		is_sin_neg: .res 2
		cos8:       .res 1
		sin8:       .res 1
		persp:      .res 1
	endlocals

	; calulate cos for later
	lda angle
	clc
	adc #64
	pha
	jsr cos
	a16
	stz is_cos_neg
	bpl :+
		eor #$ffff
		inc a
		a8
		inc is_cos_neg
	:
	a8
	xba
	sta cos8

	; calculate sin for later
	pla
	jsr sin
	a16
	stz is_sin_neg
	bpl :+
		eor #$ffff
		inc a
		a8
		inc is_sin_neg
	:
	a8
	xba
	sta sin8

	ldy #0
	loop:
		; get perspective val
		lda persp112_8, y
		sta persp
		phy
		a16
		tya
		asl a
		clc
		adc #4
		tay
		a8

		; m7a, m7d (cos and -cos)
		mul persp, cos8
		a16
		.repeat 7
			lsr a
		.endrepeat
		sta M7A_VALS, y
		ldx is_cos_neg
		bne :+
			eor #$ffff
			inc a
			sta M7A_VALS, y
		:
		eor #$ffff
		inc a
		sta M7D_VALS, y
		a8

		; m7b, m7c (sin and -sin)
		mul persp, sin8
		a16
		.repeat 7
			lsr a
		.endrepeat
		sta M7B_VALS, y
		ldx is_sin_neg
		bne :+
			eor #$ffff
			inc a
			sta M7B_VALS, y
		:
		; eor #$ffff
		; inc a
		sta M7C_VALS, y
		a8

		ply
		iny
		cpy #persp112_8_len
		bcs end
		jmp loop
	end:
	rts
.endproc

.proc update
	stz hmda_ready
	jsr setup
	jsr control
	jsr calc_persp_rot_m7_vals
	inc hmda_ready
	rts
.endproc

.proc do_m7
	lda #0
	xba
	lda x_pos+1
	a16
	clc
	adc #128
	a8
	sta M7X
	xba
	sta M7X
	lda y_pos+1
	sta M7Y
	stz M7Y

	rts
.endproc

.endscope
