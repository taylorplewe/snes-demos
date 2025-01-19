.scope color

	.zeropage
.enum DemoMode
	Fade
	Gradient
	Subscreen ; gonna be like a water texture or something
	_num_fields
.endenum
demo_mode: .res 1

.enum BlendMethod
	Add
	Subtract
	AddThenHalf
	_num_fields
.endenum
blend_method: .res 1

clip_colors_method: .res 1
prevent_math_method: .res 1
counter: .res 2

	.code
blend_method_strs:        .addr str::Add, str::Subtract, str::AddThenHalf
demo_mode_strs:           .addr str::Fade, str::Gradient, str::Subscreen
prevent_math_method_strs:
clip_colors_method_strs:  .addr str::Never, str::OutsideWindow, str::InsideWindow, str::Always
r_hdma_table: .incbin "../bin/r_hdma_vals.bin"
g_hdma_table: .incbin "../bin/g_hdma_vals.bin"
b_hdma_table: .incbin "../bin/b_hdma_vals.bin"
.proc init
	; lda #COLDATA_R | 15
	; sta COLDATA
	; lda #COLDATA_G | 15
	; sta COLDATA
	; lda #COLDATA_B | 15
	; sta COLDATA

	; lda #CGADSUB_SUBTRACT | CGADSUB_BACKDROP | CGADSUB_BG1
	; sta CGADSUB

	lda #DemoMode::Fade
	sta demo_mode
	lda #BlendMethod::Add
	sta blend_method
	stz clip_colors_method
	stz prevent_math_method
	rts
.endproc

.proc update
	a16
	inc counter

	lda counter
	a8
	
	jsr control
	jsr print_debug_msgs
	rts
.endproc

.proc vblank
	a16
	lda counter
	lsr a
	a8
	sta BG2HOFS
	stz BG2HOFS
	a16
	lsr a
	a8
	sta BG2VOFS
	stz BG2VOFS

	jsr update_fixed_colors
	jsr set_regs
	rts
.endproc

.proc update_fixed_colors
	lda demo_mode
	cmp #DemoMode::Fade
	beq fade
	; gradient:
		; fire 3 HDMAs for R, G and B
		dma_set 1, COLDATA, DMAP_1REG_1WR, r_hdma_table
		dma_set 2, COLDATA, DMAP_1REG_1WR, g_hdma_table
		dma_set 3, COLDATA, DMAP_1REG_1WR, b_hdma_table
		lda #%1110
		tsb m_hdmaen
		rts
	fade:
		lda #%1110
		trb m_hdmaen
		lda counter
		lsr a
		lsr a
		lsr a
		pha
		ora #COLDATA_R
		sta COLDATA
		pla
		pha
		ora #COLDATA_G
		sta COLDATA
		pla
		ora #COLDATA_B
		sta COLDATA
		rts
.endproc

.proc control
	a16
	lda joy1_pressed
	bit #JOY_A
	beq b_check
		a8
		lda blend_method
		clc
		adc #1
		cmp #BlendMethod::_num_fields
		bcc :+
			lda #0
		:
		sta blend_method
		a16
	b_check:
	lda joy1_pressed
	bit #JOY_B
	beq x_check
		a8
		lda clip_colors_method
		clc
		adc #1
		cmp #4
		bcc :+
			lda #0
		:
		sta clip_colors_method
		a16
	x_check:
	lda joy1_pressed
	bit #JOY_X
	beq y_check
		a8
		lda prevent_math_method
		clc
		adc #1
		cmp #4
		bcc :+
			lda #0
		:
		sta prevent_math_method
		a16
	y_check:
	lda joy1_pressed
	bit #JOY_Y
	beq end
		a8
		lda demo_mode
		clc
		adc #1
		cmp #DemoMode::_num_fields
		bcc :+
			lda #0
		:
		sta demo_mode
		a16
	end:
	a8
	rts
.endproc

.proc set_regs
	.scope cgadsub
		lda #CGADSUB_BACKDROP | CGADSUB_BG1
		xba
		lda blend_method
		cmp #BlendMethod::Add
		beq add
		cmp #BlendMethod::Subtract
		beq subtract
		cmp #BlendMethod::AddThenHalf
		beq add_then_half
		add:
			xba
			ora #CGADSUB_ADD
			bra st
		subtract:
			xba
			ora #CGADSUB_SUBTRACT
			bra st
		add_then_half:
			xba
			ora #CGADSUB_ADD | CGADSUB_HALFCOL
			bra st ; I know this is redundant but it's safe for when I add more cases after this
		st:
		sta CGADSUB
	.endscope
	.scope cgwsel
		_cgwsel = local
		; subscreen or fixed color?
		lda demo_mode
		cmp #DemoMode::Subscreen
		beq :+
			lda #CGWSEL_FIXED_COLOR
			bra :++
		:
			lda #CGWSEL_SUBSCREEN
		:
		sta _cgwsel

		; prevent color math where?
		lda prevent_math_method
		.repeat 4
			asl a
		.endrepeat
		ora _cgwsel
		sta _cgwsel

		; clip colors where?
		lda clip_colors_method
		.repeat 6
			asl a
		.endrepeat
		ora _cgwsel
		
		sta CGWSEL
	.endscope
	rts
.endproc

.proc print_debug_msgs
	; blend mode
		ldx #str::BlendMode
		lda #debug::FontColor::White
		jsr debug::print
		lda #0
		xba
		lda blend_method
		asl a
		tax
		ldy blend_method_strs, x
		tyx
		lda #debug::FontColor::Yellow
		jsr debug::print
	; clip mode
		ldx #str::ClipColors
		lda #debug::FontColor::White
		jsr debug::print
		lda #0
		xba
		lda clip_colors_method
		asl a
		tax
		ldy clip_colors_method_strs, x
		tyx
		lda #debug::FontColor::Yellow
		jsr debug::print
	; prevent mode
		ldx #str::PreventMath
		lda #debug::FontColor::White
		jsr debug::print
		lda #0
		xba
		lda prevent_math_method
		asl a
		tax
		ldy prevent_math_method_strs, x
		tyx
		lda #debug::FontColor::Yellow
		jsr debug::print
	; demo mode
		ldx #str::DemoMode
		lda #debug::FontColor::White
		jsr debug::print
		lda #0
		xba
		lda demo_mode
		asl a
		tax
		ldy demo_mode_strs, x
		tyx
		lda #debug::FontColor::Yellow
		jsr debug::print
	rts
.endproc

.endscope
