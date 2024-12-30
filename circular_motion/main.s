	.include "boiler.s"

OAM_DMA_ADDR_LO	= $1d00 ; 2 whole pages of low table OAM, 32 bytes of high table shared with stack page ($1f--)
OAM_DMA_ADDR_HI	= OAM_DMA_ADDR_LO + 512
OAM_NUM_BYTES	= 544
OAM_X			= OAM_DMA_ADDR_LO
OAM_Y			= OAM_DMA_ADDR_LO + 1
OAM_TILE		= OAM_DMA_ADDR_LO + 2
OAM_INFO		= OAM_DMA_ADDR_LO + 3

	.zeropage
local:			.res 16
counter:		.res 1
circle_x:		.res 1
circle_y:		.res 1
oam_lo_ind:		.res 1
joy1_prev:		.res 2
joy1_pressed:	.res 2
linearmode:		.res 1
halfmoonmode:	.res 1

frame_ctr:		.res 1
circle_frame:	.res 1
circle_nt1:		.res 1
counter_speed:	.res 1

CIRCLE_SIZE = 32
CIRCLE_START_X = 256/2
CIRCLE_START_Y = 224/2
	
	.code
reset:
	; go into native mode lets gooooo
	clc
	xce ; Now you're playing with ~power~
	i16
	a8

	; clear all RAM
	ldx #0
	@clearallram:
		stz 0, x
		stz $1000, x
		inx
		cpx #$1000 ; $0000 - $1fff
		bcc @clearallram

	dex
	txs ; stack now starts at $1fff

	lda #NMITIMEN_NMIENABLE | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn off screen forppuwrites
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu
	lda #1
	sta counter_speed

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	lda counter
	clc
	adc counter_speed
	sta counter

	jsr clear_oam
	jsr wait_for_input
	jsr set_joy1_pressed

	jsr update_modes
	jsr update_circle
	jsr update_circle_frame

	; draw circle
	lda circle_x
	sec
	sbc #CIRCLE_SIZE/2
	sta OAM_X
	lda circle_y
	sec
	sbc #CIRCLE_SIZE/2
	sta OAM_Y
	i8
	ldx circle_frame
	i16
	lda frames, x
	sta OAM_TILE
	lda #SPRINFO_PRIOR3 | SPRINFO_PAL(0)
	ora circle_nt1
	sta OAM_INFO

	ldx #0
	lda #SPR_HI_LARGE
	ora z:circle_negx
	jsr set_oam_hi_bits

	a16
	lda JOY1L
	sta joy1_prev
	a8

	wai
	bra forever

nmi:
	pha
	phx
	phy

	;oam(sprites)
	ldx #0
	stx OAMADDL
	m_dma_ch0 DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAMDATA, OAM_NUM_BYTES

	ply
	plx
	pla
	rti

update_modes:
	a16
	lda joy1_pressed
	bit #JOY_A
	bne @a
	bit #JOY_B
	bne @b
	bit #JOY_U
	bne @u
	bit #JOY_D
	bne @d
	a8
	rts
	@a:
		a8
		lda linearmode
		eor #$ff
		sta linearmode
		rts
	@b:
		a8
		lda halfmoonmode
		eor #$ff
		sta halfmoonmode
		rts
	@u:
		a8
		lda counter_speed
		clc
		adc #1
		bmi :+
		cmp #5
		bcs :++
			:
			sta counter_speed
		:
		rts
	@d:
		a8
		lda counter_speed
		sec
		sbc #1
		bpl :+
		cmp #<-4
		bcc :++
			:
			sta counter_speed
		:
		rts

frames:
	.byte $00,$04,$08,$0c
	.byte $40,$44,$48,$4c
	.byte $80,$84,$88,$8c
	.byte $c0,$c4,$c8,$cc
	
	.byte $00,$04,$08,$0c
	.byte $40,$44,$48,$4c
	.byte $80,$84,$88,$8c
	.byte $c0,$c4
update_circle_frame:
	inc frame_ctr
	lda frame_ctr
	and #%11
	bne :+
		lda circle_frame
		clc
		adc #1
		i8
		tax
		i16
		lda #30
		jsr mod
		sta circle_frame
	:
	lda circle_frame
	cmp #16
	bcc :+
		lda #SPRINFO_NT1
		sta circle_nt1
		bra :++
	:
		stz circle_nt1
	:
	rts

.zeropage
circle_negx: .res 1
.code
update_circle:
	; cx = Math.cos(counter / 30) * radius
	; cy = Math.sin(counter / 30) * radius
	lda counter
	jsr sin
	xba
	asr
	i8
	ldx halfmoonmode
	i16
	beq :+
		cmp #0
		jsr sin
		xba
		asr
	:
	clc
	adc #CIRCLE_START_X
	sta circle_x

	lda linearmode
	bne @linear
		lda counter
		i8
		ldx halfmoonmode
		i16
		beq :+
			cmp #0
			jsr sin
			xba
			asr
		:
		jsr cos
		xba
		asr
		clc
		adc #CIRCLE_START_Y
		sta circle_y
		bra @yend
	@linear:
		lda #CIRCLE_START_Y
		sta circle_y
	@yend:
	rts

	.include "common.s"
	.include "init.s"

chr:
	.incbin "bin/graphics.chr"
chrend: