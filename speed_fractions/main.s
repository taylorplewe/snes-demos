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

CIRCLE_SIZE = 32
; CIRCLE_START_X = (256/2)<<8
; CIRCLE_START_Y = (224/2)<<8
CIRCLE_START_X = 16<<8
CIRCLE_START_Y = 16<<8
	
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

	ldx #$0000
	stx circle_xspeed
	ldx #$0100
	stx circle_yspeed

	jsr init_ppu

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	inc counter

	jsr clear_oam
	jsr wait_for_input
	jsr set_joy1_pressed

	; update circle pos
	a16
	; xspeed
		lda circle_xspeed
		clc
		adc #1
		cmp #$0100
		bcs :+
			sta circle_xspeed
		:
	; yspeed
		lda circle_yspeed
		sec
		sbc #1
		bcc :+
			sta circle_yspeed
		:
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
	lda #SPRINFO_PAL0 | SPRINFO_PRIOR3
	sta OAM_INFO

	ldx #0
	lda #SPR_HI_LARGE
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

	.include "common.s"
	.include "init.s"

chr:
	.incbin "bin/graphics.chr"
chrend: