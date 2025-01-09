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
	
	.code
	.include "src/common.s"
	.include "src/init.s"
	.include "src/hdma.s"
	.include "src/irq.s"
	
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

	lda #NMITIMEN_NMIENABLE | NMITIMEN_IRQENABLE_X | NMITIMEN_IRQENABLE_Y | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; EXT BG Mode 7
	lda #SETINI_M7EXTBG
	sta SETINI

	; turn off screen for PPU writes
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu
	jsr hdma::init
	jsr irqs::init

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	jsr wait_for_input
	jsr hdma::update
	jsr irqs::update

	jsr clear_oam

	; end of frame
	a16
	lda JOY1L
	sta joy1_prev
	a8
	:
	wai
	lda HVBJOY
	bit #HVBJOY_IN_VBLANK
	beq :-
	bra forever

nmi:
	pha
	phx
	phy
	a8
	i16

	;oam(sprites)
	ldx #0
	stx OAMADDL
	dma 0, DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAMDATA, OAM_NUM_BYTES

	lda hdma::hmda_ready
	beq :+
		jsr hdma::run
		jsr hdma::do_m7
	:

	lda #BGMODE_MODE1
	sta BGMODE

	ply
	plx
	pla
	rti

	.segment "BANK1"
chr:
	.incbin "bin/sand_chr.bin"
CHR_LEN = *-chr
