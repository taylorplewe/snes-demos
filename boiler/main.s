	.include "src/boiler.s"

	.zeropage
local:			.res 16
oam_lo_ind:		.res 1
joy1_prev:		.res 2
joy1_pressed:	.res 2
	
	.code
	.include "src/common.s"
	.include "src/ppu.s"
zero: .word 0
reset:
	; go into native mode
	clc
	xce
	i16
	a8

	; turn off screen for init code
	lda #INIDISP_BLANK
	sta INIDISP

	; clear all RAM
	stz WMADDL
	stz WMADDM
	stz WMADDH
	dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, zero, 0 ; 0 = 64k because it dec's then checks
	sta MDMAEN ; fire again for next 64k ($1000-$1fff)

	ldx #$1fff
	txs

	lda #NMITIMEN_NMIENABLE | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; all init code
	jsr ppu::init

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	jsr ppu::update
	jsr wait_for_input

	; all update code

	; end of frame
	ldx JOY1L
	stx joy1_prev
	wai
	bra forever

nmi:
	pha
	phx
	phy

	; all vblank code
	jsr ppu::vblank

	ply
	plx
	pla
	rti