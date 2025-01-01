; page 2-17-5 of the official SNES dev manuel
.scope hdma

	.zeropage
x_pos: .res 2
y_pos: .res 2
angle: .res 1

	.code

M7AD_VALS = $200
M7B_VALS = $300
M7C_VALS = $400

persp112_8: .incbin "../bin/persp112_8.bin"
persp112_8_len = *-persp112_8

.proc init
	; write 0 to M7 A,B,C and D and disable HDMA for the first 112 scanlines
	lda #112
	sta M7AD_VALS
	sta M7B_VALS
	sta M7C_VALS
	stz M7AD_VALS+1
	stz M7B_VALS+1
	stz M7C_VALS+1
	stz M7AD_VALS+2
	stz M7B_VALS+2
	stz M7C_VALS+2

	; then do the fancy stuff for the last 112 scanlines
	lda #$80 | 112
	sta M7AD_VALS+3
	sta M7B_VALS+3
	sta M7C_VALS+3
	rts
.endproc

.proc setup
	lda #0
	sta HDMAEN

	dma_set 1, DMAP_1REG_2WR, M7AD_VALS, M7A
	dma_set 2, DMAP_1REG_2WR, M7AD_VALS, M7D
	dma_set 3, DMAP_1REG_2WR, M7B_VALS, M7B
	dma_set 4, DMAP_1REG_2WR, M7C_VALS, M7C

.endproc

.proc run
	lda #%00011110
	sta HDMAEN
	rts
.endproc

; y = 0 -> move forward; 1 -> move backwards; 2 -> strafe right; 3 -> strafe left
.proc move
	php
	; x
		a8
		lda angle
		jsr cos
		a16
		cpy #0
		beq :+
		cpy #2
		beq :+
			eor #$ffff
			inc a
			bra :+
		:
		.repeat 8
			asr16
		.endrepeat
		cpy #2
		beq :+
		cpy #3
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
		cpy #0
		beq :+
		cpy #2
		beq :+
			eor #$ffff
			inc a
		:
		eor #$ffff
		inc a
		.repeat 8
			asr16
		.endrepeat
		cpy #2
		beq :+
		cpy #3
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
		a16
	:
	lda JOY1L
	bit #JOY_R
	beq :+
		a8
		inc angle
		inc angle
		a16
	:

	; move
	lda JOY1L
	bit #JOY_U
	beq :+
		ldy #0
		jsr move
		bra :++
	:
	bit #JOY_D
	beq :+
		ldy #1
		jsr move
	:
	lda JOY1L
	bit #JOY_SHOULDER_L
	beq :+
		ldy #2
		jsr move
		bra :++
	:
	bit #JOY_SHOULDER_R
	beq :+
		ldy #3
		jsr move
	:
	a8
	rts
.endproc

.proc calc_persp_rot_m7_vals
	is_cos_neg = local
	is_sin_neg = local+1
	cos8 = local+2
	sin8 = local+3

	; calulate cos for later
	stz is_cos_neg
	lda angle
	clc
	adc #64
	pha
	jsr cos
	a16
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
	stz is_sin_neg
	pla
	jsr sin
	a16
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
		@persp = local+8
		; get perspective val
		lda persp112_8, y
		sta @persp
		phy
		a16
		tya
		asl a
		clc
		adc #4
		tay
		a8

		; m7a, m7d (cos)
		mul @persp, cos8
		xba
		a16
		and #$ff
		sta M7AD_VALS, y
		a8
		lda is_cos_neg
		beq :+
			a16
			lda M7AD_VALS, y
			eor #$ffff
			inc a
			sta M7AD_VALS, y
			a8
		:

		; m7b (sin)
		mul @persp, sin8
		xba
		a16
		and #$ff
		sta M7B_VALS, y
		a8
		lda is_sin_neg
		beq :+
			a16
			lda M7B_VALS, y
			eor #$ffff
			inc a
			sta M7B_VALS, y
			a8
		:

		; m7c (-sin)
		mul @persp, sin8
		xba
		a16
		and #$ff
		sta M7C_VALS, y
		a8
		lda is_sin_neg
		bne :+
			a16
			lda M7C_VALS, y
			eor #$ffff
			inc a
			sta M7C_VALS, y
			a8
		:

		ply
		iny
		cpy #persp112_8_len
		bcs end
		jmp loop
	end:
	rts
.endproc

.proc update
	jsr setup
	jsr control
	jsr calc_persp_rot_m7_vals
.endproc

.proc do_m7
	; move diagonally
	; a16
	; i8
	; lda counter
	; lsr a
	; tax
	; xba
	; tay
	; xba
	; a8
	; stx BG1HOFS
	; sty BG1HOFS
	; stx BG1VOFS
	; sty BG1VOFS
	; stx M7Y
	; sty M7Y
	; a16
	; clc
	; adc #$80
	; a8
	; sta M7X
	; xba
	; sta M7X
	; i16

	; still
	; stz BG1HOFS
	; stz BG1HOFS
	; stz BG1VOFS
	; stz BG1VOFS
	; stz M7Y
	; stz M7Y
	; lda #128
	; sta M7X
	; stz M7X

	; move down
	; a16
	; i8
	; lda counter
	; lsr a
	; tax
	; xba
	; tay
	; xba
	; sec
	; sbc #112
	; a8
	; ; m7y = 112
	; 	; sta M7Y
	; 	; xba
	; 	; sta M7Y
	; stz BG1HOFS
	; stz BG1HOFS
	; stx BG1VOFS
	; sty BG1VOFS
	; ; m7y = 0
	; 	stx M7Y
	; 	sty M7Y
	; lda #128
	; sta M7X
	; stz M7X
	; i16
	
	; controls
	.a8
	lda x_pos+1
	sta BG1HOFS
	stz BG1HOFS
	lda y_pos+1
	sta BG1VOFS
	stz BG1VOFS
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
	; stz BG1HOFS
	; stz BG1HOFS
	; stz BG1VOFS
	; stz BG1VOFS
	; stz M7Y
	; stz M7Y
	; lda #128
	; sta M7X
	; stz M7X

	rts
.endproc

.endscope