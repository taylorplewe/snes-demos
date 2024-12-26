	.include "src/boiler.s"

	.zeropage
local:			.res 16
oam_lo_ind:		.res 1
joy1_prev:		.res 2
joy1_pressed:	.res 2

m7_inc:			.res 2
m7_dec:			.res 2

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

	; set m7_dec to 1.0
	lda #1
	sta m7_dec+1

	; m7 empty space = bg, don't loop
	; lda #%10000000
	; sta M7SEL

forever:
	a16
	inc m7_inc
	dec m7_dec
	a8
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

	; increasing
	; lda m7_inc
	; sta BG1HOFS
	; lda m7_inc+1
	; sta BG1HOFS
	; uniform
	stz BG1HOFS
	stz BG1HOFS
	stz BG1VOFS
	stz BG1VOFS

	inc_cos = local
	inc_cos_neg = local+2
	inc_sin = local+4
	inc_sin_neg = local+6

	lda m7_inc
	jsr cos
	a16
	jsr asr8
	sta inc_cos

	eor #$ffff
	inc a
	sta inc_cos_neg

	a8
	lda m7_inc
	jsr sin
	a16
	jsr asr8
	sta inc_sin

	eor #$ffff
	inc a
	sta inc_sin_neg

	; uniform
	; m7 #$0100, #0, #0, #$0100

	; growing
	; m7 m7_inc, #0, #0, m7_inc

	; rotating CCW
	m7 inc_cos, inc_sin, inc_sin_neg, inc_cos

	; showcase C
	; m7 #$0100, #0, #$0100, #$0100

	a8

	; var lerp = function(v0, v1, t) {
  	; 	return v0 + t * (v1 - v0);
	; };

	; var sl = lerp(1/farDist, 1/nearDist, scanline / 223);
	; var scale = 1/sl;

	; m7a = scale * (8/7);
	; m7b = 0x0000;
	; m7c = 0x0000;
	; m7d = scale * (8/7);

	; lda m7_inc
	lda #$80
	sta M7X
	stz M7X
	sta M7Y
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