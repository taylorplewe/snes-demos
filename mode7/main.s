	.include "src/boiler.s"

	.zeropage
local:			.res 16
oam_lo_ind:		.res 1
joy1_prev:		.res 2
joy1_pressed:	.res 2

	.code
reset:
	; put in 65816 mode
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

	; turn off screen for PPU writes
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu
	lda #NMITIMEN_NMIENABLE | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	jsr wait_for_input

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

	stz BG1HOFS
	stz BG1VOFS

	a16
	i8
	ldy #0
	ldx #1
	lda JOY1L
	bit #JOY_A
	beq :+
		sty M7A
		sty M7A
		bra :++
	:
		sty M7A
		stx M7A
	:
	bit #JOY_B
	beq :+
		sty M7B
		sty M7B
		bra :++
	:
		sty M7B
		sty M7B
	:
	bit #JOY_X
	beq :+
		sty M7C
		sty M7C
		bra :++
	:
		sty M7C
		sty M7C
	:
	bit #JOY_Y
	beq :+
		sty M7D
		sty M7D
		bra :++
	:
		sty M7D
		stx M7D
	:
	a8
	i16

	stz M7X
	stz M7X
	stz M7Y
	stz M7Y

	ply
	plx
	pla
	rti


	.include "src/common.s"
	.include "src/init.s"

	.segment "BANK1"
chr:
	.incbin "bin/pillars.bin"
CHR_LEN = *-chr