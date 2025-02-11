.scope plr

PLR_X = (256/2)-(32/2)
PLR_Y = 128
GRAVITY = $80
JUMP_VSPEED = -$a00
FRAME_TIME = 4
.enum State
	Idle
	Jog
	JogAngle
	JogHardAngle
	JogBack
	JogBackAngle
	JogBackHardAngle
	Jump
.endenum

	.zeropage
prev_state:        .res 1
state:             .res 1
z_pos:             .res 2
vspeed:            .res 2
anim_ctr:          .res 1
frame:             .res 1
num_frames:        .res 1
facing_l:          .res 1
going_backwards:   .res 1
should_flip_frame: .res 1
flip_frame:        .res 1
dma_base_addr:     .res 2
dma_vblank_addr:   .res 2

	.code
.scope Frames
	Idle: .incbin "../bin/sonic_frames/idle.chr"
	Jog:
		.incbin "../bin/sonic_frames/jog0.chr"
		.incbin "../bin/sonic_frames/jog1.chr"
		.incbin "../bin/sonic_frames/jog2.chr"
	JogAngle:
		.incbin "../bin/sonic_frames/angle0.chr"
		.incbin "../bin/sonic_frames/angle1.chr"
		.incbin "../bin/sonic_frames/angle2.chr"
		.incbin "../bin/sonic_frames/angle3.chr"
		.incbin "../bin/sonic_frames/angle4.chr"
		.incbin "../bin/sonic_frames/angle5.chr"
	JogHardAngle:
		.incbin "../bin/sonic_frames/hard_angle0.chr"
		.incbin "../bin/sonic_frames/hard_angle1.chr"
		.incbin "../bin/sonic_frames/hard_angle2.chr"
		.incbin "../bin/sonic_frames/hard_angle3.chr"
		.incbin "../bin/sonic_frames/hard_angle4.chr"
		.incbin "../bin/sonic_frames/hard_angle5.chr"
	Jump:
		.incbin "../bin/sonic_frames/jump0.chr"
		.incbin "../bin/sonic_frames/jump1.chr"
		.incbin "../bin/sonic_frames/jump2.chr"
		.incbin "../bin/sonic_frames/jump3.chr"
.endscope
.proc init
	lda #State::Idle
	sta state
	rts
.endproc

.macro set_state
.scope
	stz should_flip_frame
	ldx z_pos
	beq start
		jmp end
	start:
	a16
	i8
	lda JOY1L
	bit #JOY_SHOULDER_L
	bne jog_hard_angle
	bit #JOY_SHOULDER_R
	bne jog_hard_angle
	bit #JOY_U
	bne ud
	bit #JOY_D
	beq ud_end
		ud:
		bit #JOY_L
		bne jog_angle
		bit #JOY_R
		bne jog_angle
		bra jog
	ud_end:
	idle:
		ldx #0
		stx flip_frame
		lda #Frames::Idle
		sta dma_base_addr
		ldx #1
		stx num_frames
		lda #State::Idle
		bra state_store
	jog:
		lda #Frames::Jog
		sta dma_base_addr
		ldx #1
		stx should_flip_frame
		ldx #3
		stx num_frames
		lda #State::Jog
		bra state_store
	jog_angle:
		ldx #0
		stx flip_frame
		lda #Frames::JogAngle
		sta dma_base_addr
		ldx #6
		stx num_frames
		lda #State::JogAngle
		bra state_store
	jog_hard_angle:
		ldx #0
		stx flip_frame
		ldx #6
		stx num_frames
		lda #Frames::JogHardAngle
		sta dma_base_addr
		lda #State::JogHardAngle
		; bra state_store
	state_store:
	a8
	i16
	sta state
	cmp prev_state
	beq state_end
		stz anim_ctr
		stz frame
		lda state
		sta prev_state
	state_end:

	; facing left and going backwards
	stz facing_l
	stz going_backwards
	lda state
	cmp #State::Idle
	beq end
		a16
		lda JOY1L
		bit #JOY_SHOULDER_R
		bne :++
		bit #JOY_L
		bne :+
		bit #JOY_SHOULDER_L
		beq :++
		:
		a8
		lda #SPRINFO_HFLIP
		sta facing_l
	:
	a16
	lda JOY1L
	bit #JOY_D
	beq end
		inc going_backwards
		lda facing_l
		eor #SPRINFO_HFLIP
		sta facing_l
	end:
.endscope
.endmacro

.macro jump
	.local end
	ldx vspeed
	bne end
	ldx z_pos
	bne end
		a16
		lda joy1_pressed
		bit #JOY_A
		beq :+
			stz should_flip_frame
			stz going_backwards
			stz facing_l
			lda #.loword(JUMP_VSPEED)
			sta vspeed
			ldx #Frames::Jump
			stx dma_base_addr
			lda #4
			sta num_frames
			lda #State::Jump
			sta state
		:
		a8
	end:
.endmacro

.macro update_z
	.local update, end
	ldx vspeed
	bne update
	ldx z_pos
	beq end
	update:
		a16
		lda vspeed
		clc
		adc #GRAVITY
		sta vspeed
		lda z_pos
		clc
		adc vspeed
		sta z_pos
		bmi :+
		beq :+
			stz vspeed
			stz z_pos
		:
		a8
	end:
.endmacro

.macro update_anim
	.local end
	inc anim_ctr
	lda anim_ctr
	cmp #FRAME_TIME
	bcc end
		stz anim_ctr
		lda going_backwards
		bne rewind
			inc frame
			lda frame
			cmp num_frames
			bcc :+
				stz frame
				lda should_flip_frame
				beq :+
				lda flip_frame
				eor #SPRINFO_HFLIP
				sta flip_frame
			:
			bra end
		rewind:
			dec frame
			bpl :+
				lda num_frames
				dec a
				sta frame
				lda should_flip_frame
				beq :+
				lda flip_frame
				eor #SPRINFO_HFLIP
				sta flip_frame
			:
	end:
.endmacro

.macro prepare_dma
	lda #$3
	mul a, frame
	xba
	lda #0
	a16
	clc
	adc dma_base_addr
	sta dma_vblank_addr
	a8
.endmacro

	.zeropage
draw_y:    .res 1
draw_info: .res 1
	.code
.macro draw
	.local hflip, end
	lda facing_l
	eor flip_frame
	ora #SPRINFO_PRIOR3
	sta draw_info
	lda #PLR_Y
	clc
	adc z_pos+1
	sta draw_y
	ldx #0
	oam_buff_obj #PLR_X,    draw_y, draw_info, #0,   #SPR_HI_LARGE
	lda draw_y
	clc
	adc #32
	sta draw_y
	lda draw_info
	bit #SPRINFO_HFLIP
	bne hflip
		oam_buff_obj #PLR_X,    draw_y, draw_info, #$04, #0
		oam_buff_obj #PLR_X+16, draw_y, draw_info, #$24, #0
		bra end
	hflip:
		oam_buff_obj #PLR_X,    draw_y, draw_info, #$24, #0
		oam_buff_obj #PLR_X+16, draw_y, draw_info, #$04, #0
	end:
	stx oam_lo_ind
	rts
.endmacro

.proc update
	set_state
	jump
	update_z
	update_anim
	prepare_dma
	draw
	rts
.endproc

.proc vblank
	lda #DMAP_2REG_1WR
	sta DMAP0
	lda #<VMDATAL
	sta BBAD0
	ldx #$c0
	stx DAS0L
	stz A1B0
	stz VMADDL

	lda #$60
	sta VMADDH
	ldx dma_vblank_addr
	phx
	stx A1T0L
	lda #1
	sta MDMAEN


	lda #DMAP_2REG_1WR
	sta DMAP0
	lda #<VMDATAL
	sta BBAD0
	ldx #$c0
	stx DAS0L
	stz A1B0
	stz VMADDL
	lda #$61
	sta VMADDH
	a16
	pla
	clc
	adc #$c0
	pha
	sta A1T0L
	a8
	lda #1
	sta MDMAEN
	
	lda #DMAP_2REG_1WR
	sta DMAP0
	lda #<VMDATAL
	sta BBAD0
	ldx #$c0
	stx DAS0L
	stz A1B0
	stz VMADDL
	lda #$62
	sta VMADDH
	a16
	pla
	clc
	adc #$c0
	pha
	sta A1T0L
	a8
	lda #1
	sta MDMAEN
	
	lda #DMAP_2REG_1WR
	sta DMAP0
	lda #<VMDATAL
	sta BBAD0
	ldx #$c0
	stx DAS0L
	stz A1B0
	stz VMADDL
	lda #$63
	sta VMADDH
	a16
	pla
	clc
	adc #$c0
	; pha
	sta A1T0L
	a8
	lda #1
	sta MDMAEN

	; dma $c0 bytes to VRAM addr $6000
	; dma $c0 bytes to VRAM addr $6100
	; dma $c0 bytes to VRAM addr $6200
	; dma $c0 bytes to VRAM addr $6300
	rts
.endproc

.endscope