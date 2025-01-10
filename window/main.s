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
	.include "src/window.s"
zero: .byte 0
reset:
	clc
	xce
	i16
	a8

	; clear all RAM
	stz WMADDL
	stz WMADDM
	stz WMADDH
	dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, zero, 0 ; 0 = 64k because it dec's then checks
	sta MDMAEN ; fire again for next 64k ($1000-$1fff)

	ldx #$1fff
	txs ; stack now starts at $1fff

	lda #NMITIMEN_NMIENABLE | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn off screen for PPU writes
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu
	jsr window::init

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	jsr wait_for_input

	jsr clear_oam

	jsr draw_orca
	jsr window::update

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

	;oam(sprites)
	ldx #0
	stx OAMADDL
	dma 0, OAMDATA, DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAM_NUM_BYTES

	jsr window::vblank

	ply
	plx
	pla
	rti

; draw orca
draw_orca:
	i8
	ldx oam_lo_ind
	i16

	; bottom, larger portion
	oam_buff_obj #128-16, #112-16, #SPRINFO_PRIOR3 | SPRINFO_PAL(0), #$40, #SPR_HI_LARGE

	; fin
	oam_buff_obj #128-16, #(112-16)-16, #SPRINFO_PRIOR3 | SPRINFO_PAL(0), #0, #0

	i8
	stx oam_lo_ind
	i16
	rts

orca_chr:
	.incbin "bin/orca.bin"
orca_chr_len = *-orca_chr

	.segment "BANK1"
amst_chr:
	.incbin "bin/amst1.bin"
	.incbin "bin/amst2.bin"
amst_chr_len = *-amst_chr
