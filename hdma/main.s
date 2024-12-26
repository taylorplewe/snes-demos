	.include "src/boiler.s"

OAM_DMA_ADDR_LO	= $1d00 ; 2 whole pages of low table OAM, 32 bytes of high table shared with stack page ($1f--)
OAM_DMA_ADDR_HI	= OAM_DMA_ADDR_LO + 512
OAM_NUM_BYTES	= 544
OAM_X			= OAM_DMA_ADDR_LO
OAM_Y			= OAM_DMA_ADDR_LO + 1
OAM_TILE		= OAM_DMA_ADDR_LO + 2
OAM_INFO		= OAM_DMA_ADDR_LO + 3

	.zeropage
local:			.res 16
oam_lo_ind:		.res 1
joy1_prev:		.res 2
joy1_pressed:	.res 2
counter: .res 2
	
	.code
	.include "src/common.s"
	.include "src/init.s"
	.include "src/hdma.s"
	
reset:
	clc
	xce
	i16
	a8

	; clear all RAM
	ldx #0
	@clearallram:
		stz 0, x
		inx
		cpx #$2000
		bcc @clearallram

	dex
	txs ; stack now starts at $1fff

	lda #NMITIMEN_NMIENABLE | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn off screen for PPU writes
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	a16
	lda counter
	inc a
	and #%0001111111111111
	sta counter
	a8
	jsr hdma::setup
	jsr wait_for_input

	jsr clear_oam

	; end of frame
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
	php
	a8
	i16

	jsr hdma::run

	;oam(sprites)
	ldx #0
	stx OAMADDL
	dma 0, DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAMDATA, OAM_NUM_BYTES

	; mode 7
	; a16
	; m7 #$0100, #0, #0, #$0100
	; a8

	a16
	lda counter
	lsr a
	lsr a
	pha
	a8
	sta BG1HOFS
	xba
	sta BG1HOFS
	a16
	pla
	clc
	adc #$80
	a8
	sta M7X
	xba
	sta M7X

	plp
	ply
	plx
	pla
	rti

	.segment "BANK1"
chr:
	.incbin "bin/pillars.bin"
CHR_LEN = *-chr
