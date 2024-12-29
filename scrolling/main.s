	.include "src/boiler.s"

OAM_DMA_ADDR_LO	= $1d00 ; 2 whole pages of low table OAM, 32 bytes of high table shared with stack page ($1f--)
OAM_DMA_ADDR_HI	= OAM_DMA_ADDR_LO + 512
OAM_NUM_BYTES	= 544
OAM_X			= OAM_DMA_ADDR_LO
OAM_Y			= OAM_DMA_ADDR_LO + 1
OAM_TILE		= OAM_DMA_ADDR_LO + 2
OAM_INFO		= OAM_DMA_ADDR_LO + 3

PPU_BUFF	= $1f20
PPU_BUFF_LEN	= PPU_BUFF + 0
PPU_BUFF_ADDR	= PPU_BUFF + 2
PPU_BUFF_VMAIN	= PPU_BUFF + 4
PPU_BUFF_DATA	= PPU_BUFF + 5

MAP_WIDTH_32 = 24
MAP_HEIGHT_32 = 24
MAP_HEIGHT = MAP_HEIGHT_32 * 32

METATILE_NUM_TILES_ON_SIDE = 4

	.zeropage
local:			.res 16
oam_lo_ind:		.res 1
joy1_prev:		.res 2
joy1_pressed:	.res 2

test_bro: .res 2
	
	.code

	.include "src/common.s"
	.include "src/init.s"
	.include "src/draw.s"
	.include "src/scroll.s"
	.include "src/nmi.s"

reset:
	; go into native mode lets gooooo
	clc
	xce ; Now you're playing with ~power~
	i16
	a8

	; clear all RAM
	ldx #$1fff
	txs
	@clearallram:
		stz 0, x
		dex
		bpl @clearallram
	stx $40

	; turn off screen for PPU writes
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu
	jsr draw::Init

	lda #NMITIMEN_NMIENABLE | NMITIMEN_AUTOJOY
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

	; a16
	; lda #8
	; sta PPU_BUFF_LEN
	; lda #$2400
	; sta PPU_BUFF_ADDR
	; lda #VMAIN_WORDINC | VMAIN_INC_32
	; sta PPU_BUFF_VMAIN
	; lda #$148
	; sta PPU_BUFF_DATA
	; a8

forever:
	jsr wait_for_input
	jsr set_joy1_pressed

	jsr clear_oam

	jsr scroll::Update
	jsr draw::Render

	; end of frame
	ldx JOY1L
	stx joy1_prev
	
	wai
	bra forever

nmi:
	pha
	phx
	phy

	;oam(sprites)
	ldx #0
	stx OAMADDL
	dma_ch0 #DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAMDATA, #OAM_NUM_BYTES

	jsr nmi::ApplyPPUBuff

	; scroll
	lda scroll_x+1
	sta BG1HOFS
	lda scroll_x+2
	sta BG1HOFS
	a16
	lda scroll_y+1
	dec a
	a8
	sta BG1VOFS
	xba
	sta BG1VOFS

	ply
	plx
	pla
	rti

map:
	.include "map.s"
MAP_LEN = *-map

metas:
	.include "metas.s"
METAS_LEN = *-metas

chr:
	.incbin "bin/chr.bin"
CHR_LEN = *-chr