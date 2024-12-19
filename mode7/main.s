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
	a8


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

	; A
		; uniform
		stz M7A
		lda #1
		sta M7A

		; increasing
		; ldy m7_inc
		; sty M7A
		; ldy m7_inc+1
		; sty M7A
		; ldy #0

		; decreasing
		; ldy m7_dec
		; sty M7A
		; ldy m7_dec+1
		; sty M7A
		; ldy #0

		; 2.0
		; sty M7A
		; ldy #2
		; sty M7A
		; ldy #0

		; 0.5
		; ldy #$80
		; sty M7A
		; ldy #0
		; sty M7A

		; cos
		lda inc_cos
		sta M7A
		lda inc_cos+1
		sta M7A
	; B
		; uniform
		stz M7B
		stz M7B

		; increasing
		; ldy m7_inc
		; sty M7B
		; ldy m7_inc+1
		; sty M7B
		; ldy #0

		; decreasing
		; ldy m7_dec
		; sty M7B
		; ldy m7_dec+1
		; sty M7B
		; ldy #0

		; 2.0
		; sty M7B
		; ldy #2
		; sty M7B

		; 0.5
		; ldy #$80
		; sty M7B
		; ldy #0
		; sty M7B

		; sin
		; lda m7_inc
		; jsr sin
		; xba
		; sta M7B
		; stz M7B
		
		; -sin
		lda inc_sin_neg
		sta M7B
		lda inc_sin_neg+1
		sta M7B
	; C
		; uniform
		stz M7C
		stz M7C

		; increasing
		; ldy m7_inc
		; sty M7C
		; ldy m7_inc+1
		; sty M7C
		; ldy #0

		; decreasing
		; ldy m7_dec
		; sty M7C
		; ldy m7_dec+1
		; sty M7C
		; ldy #0

		; 2.0
		; sty M7C
		; ldy #2
		; sty M7C

		; 0.5
		; ldy #$80
		; sty M7C
		; ldy #0
		; sty M7C
		
		; sin
		lda inc_sin
		sta M7C
		lda inc_sin+1
		sta M7C
		
		; -sin
		; lda m7_inc
		; jsr sin
		; xba
		; eor #$ff
		; inc a
		; sta M7C
		; lda #$ff
		; sta M7C
	; D
		; uniform
		stz M7D
		lda #1
		sta M7D

		; increasing
		; ldy m7_inc
		; sty M7D
		; ldy m7_inc+1
		; sty M7D
		; ldy #0

		; decreasing
		; ldy m7_dec
		; sty M7D
		; ldy m7_dec+1
		; sty M7D
		; ldy #0

		; 2.0
		; sty M7D
		; ldy #2
		; sty M7D

		; 0.5
		; ldy #$80
		; sty M7D
		; ldy #0
		; sty M7D
		
		; cos
		lda inc_cos
		sta M7D
		lda inc_cos+1
		sta M7D
	; :
	; a8
	; i16

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