	.include "src/boiler.s"

	.zeropage
local:			.res 16
oam_lo_ind:		.res 1
joy1_prev:		.res 2
joy1_pressed:	.res 2
	
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

	ply
	plx
	pla
	rti


	.include "src/common.s"
	.include "src/init.s"

chr:
	.incbin "bin/chr.bin"
CHR_LEN = *-chr
