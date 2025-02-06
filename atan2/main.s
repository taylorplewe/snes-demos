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
joy1_prev:		.res 2
joy1_pressed:	.res 2
oam_lo_ind:		.res 1
circle_x:		.res 2 ; 00000000.00000000
circle_y:		.res 2
circle_xspeed:	.res 2 ; 00000000.00000000
circle_yspeed:	.res 2
circle2_x:		.res 2
circle2_y:		.res 2

CIRCLE_SIZE = 32
CIRCLE_START_X = (256/2)<<8
CIRCLE_START_Y = (224/2)<<8
CIRCLE2_START_X = 196<<8
CIRCLE2_START_Y = 19<<8
	
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

	ldx #CIRCLE_START_X
	stx circle_x
	ldx #CIRCLE_START_Y
	stx circle_y

	ldx #CIRCLE2_START_X
	stx circle2_x
	ldx #CIRCLE2_START_Y
	stx circle2_y

	jsr init_ppu

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	inc counter

	jsr clear_oam
	jsr wait_for_input
	jsr set_joy1_pressed

	jsr move_circle2
	jsr move_circle

	; update circle pos
	a16
	lda circle_x
	clc
	adc circle_xspeed
	sta circle_x
	lda circle_y
	clc
	adc circle_yspeed
	sta circle_y
	a8

	; draw circle
	lda circle_x+1
	sec
	sbc #CIRCLE_SIZE/2
	sta OAM_X
	lda circle_y+1
	sec
	sbc #CIRCLE_SIZE/2
	sta OAM_Y
	stz OAM_TILE
	lda #SPRINFO_PRIOR3 | SPRINFO_PAL(0)
	sta OAM_INFO
		; hi bits
		ldx #0
		lda #SPR_HI_LARGE
		jsr set_oam_hi_bits
	
	; draw circle 2
	lda circle2_x+1
	sec
	sbc #CIRCLE_SIZE/2
	sta OAM_X+4
	lda circle2_y+1
	sec
	sbc #CIRCLE_SIZE/2
	sta OAM_Y+4
	stz OAM_TILE+4
	lda #SPRINFO_PAL(0) | SPRINFO_PRIOR3
	sta OAM_INFO+4
		; hi bits
		ldx #4
		lda #SPR_HI_LARGE
		jsr set_oam_hi_bits


	a16
	lda JOY1L
	sta joy1_prev
	a8

	wai
	jmp forever

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

calc_circles_atan2:
	; figure out which quadrant
	lda circle2_x+1
	cmp circle_x+1
	bcs @r
	; l:
		lda circle_x+1
		sec
		sbc circle2_x+1
		xba
		lda circle2_y+1
		cmp circle_y+1
		bcs @ld
		; lu:
			lda circle_y+1
			sec
			sbc circle2_y+1
			xba
			ldy #2
			bra @qend
		@ld:
			lda circle2_y+1
			sec
			sbc circle_y+1
			xba
			ldy #1
			bra @qend
	@r:
		lda circle2_x+1
		sec
		sbc circle_x+1
		xba
		lda circle2_y+1
		cmp circle_y+1
		bcs @rd
		; ru:
			lda circle_y+1
			sec
			sbc circle2_y+1
			xba
			ldy #3
			bra @qend
		@rd:
			lda circle2_y+1
			sec
			sbc circle_y+1
			xba
			ldy #0
			bra @qend
	@qend:
	jmp atan2
	; rts

move_circle:
	; arctan action
	jsr calc_circles_atan2
	pha
	sta $f0
	jsr sin
	a16
	asr16
	asr16
	asr16
	asr16
	asr16
	asr16
	asr16
	sta circle_yspeed
	a8
	pla
	jsr cos
	a16
	asr16
	asr16
	asr16
	asr16
	asr16
	asr16
	asr16
	sta circle_xspeed
	a8
	rts

move_circle2:
	a16
	lda JOY1L
	bit #JOY_U
	bne @u
	bit #JOY_D
	bne @d
	bit #JOY_L
	bne @l
	bit #JOY_R
	bne @r
	bra @lr
	@u:
		a8
		lda circle2_y+1
		sec
		sbc #2
		bcs :+
			lda #0
		:
		sta circle2_y+1
		bra @lr
	@d:
		a8
		inc circle2_y+1
		inc circle2_y+1
	@lr:
	a16
	lda JOY1L
	bit #JOY_L
	bne @l
	bit #JOY_R
	bne @r
	a8
	rts
	@l:
		a8
		dec circle2_x+1
		dec circle2_x+1
		rts
	@r:
		a8
		inc circle2_x+1
		inc circle2_x+1
		rts
;

	.include "common.s"
	.include "init.s"

chr:
	.incbin "bin/graphics.chr"
chrend:
