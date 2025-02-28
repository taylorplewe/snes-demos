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
oam_lo_ind:		.res 2
joy1_prev:		.res 2
joy1_pressed:	.res 2

mode1_hscroll:	.res 3

m_hdmaen:		.res 1
	
	.code
	.include "src/common.s"
	.include "src/init.s"
	.include "src/fog.s"
	.include "src/hdma.s"
	.include "src/irq.s"
	.include "src/plr.s"
	
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

	; turn off screen for PPU writes
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu
	jsr hdma::init
	jsr irqs::init
	jsr fog::init

	lda #NMITIMEN_NMIENABLE | NMITIMEN_IRQENABLE_X | NMITIMEN_IRQENABLE_Y | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	jsr wait_for_input
	jsr set_joy1_pressed
	jsr hdma::update
	jsr irqs::update

	jsr clear_oam

	jsr plr::update

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
	dma 0, OAMDATA, DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAM_NUM_BYTES

	lda hdma::hmda_ready
	beq :+
		jsr hdma::run
		jsr hdma::do_m7
	:

	jsr plr::vblank
	jsr fog::vblank

	lda #BGMODE_MODE1
	sta BGMODE

	lda mode1_hscroll+1
	sta BG1HOFS
	lda mode1_hscroll+2
	sta BG1HOFS
	lda #<-(112-31)
	sta BG1VOFS
	stz BG1VOFS

	lda m_hdmaen
	sta HDMAEN

	ply
	plx
	pla
	rti

	.segment "BANK1"
chr:
	.incbin "bin/sand_chr2.bin"
CHR_LEN = *-chr
