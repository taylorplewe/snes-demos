	.include "boiler.s"

OAM_DMA_ADDR_LO	= $1d00 ; 2 whole pages of low table OAM, 32 bytes of high table shared with stack page ($1f--)
OAM_DMA_ADDR_HI	= OAM_DMA_ADDR_LO + 512
OAM_NUM_BYTES	= 544
OAM_X			= OAM_DMA_ADDR_LO
OAM_Y			= OAM_DMA_ADDR_LO + 1
OAM_TILE		= OAM_DMA_ADDR_LO + 2
OAM_INFO		= OAM_DMA_ADDR_LO + 3

PPU_BUFF		= $1f20
PPU_BUFF_LEN	= PPU_BUFF + 0
PPU_BUFF_ADDR	= PPU_BUFF + 2
PPU_BUFF_VMAIN	= PPU_BUFF + 4
PPU_BUFF_DATA	= PPU_BUFF + 5

BG1_BUFF		= $1000 ; ..$1700 - virtual screen memory for bg1
BG3_BUFF		= $1700 ; ..$1e00 - virtual screen memory for bg3

	.zeropage
local:			.res 16
counter:		.res 1
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
		stz $1000, x
		inx
		cpx #$1000 ; $0000 - $1fff
		bcc @clearallram

	ldx #$1fff
	txs ; stack now starts at $1fff

	lda #NMITIMEN_NMIENABLE
	sta NMITIMEN ; interrupt enable register; enable NMIs and auto joypad read

	; turn off screen forppuwrites
	lda #INIDISP_BLANK
	sta INIDISP

	jsr init_ppu
	jsr cursor_init

	; turn screen back on & set brightness
	lda #$f
	sta INIDISP

forever:
	; start of frame
	inc counter
	jsr clear_oam
	jsr get_mouse_input
	jsr set_mouse_input_pressed

	;debug
	ldx z:mouse_input
	stx $42
	ldx z:mouse_input+2
	stx $40

	jsr cursor_update
	jsr cursor_draw

	jsr set_mouse_input_prev
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

	jsr refresh_screen
	; jsr apply_ppu_buff

	ply
	plx
	pla
	rti

	.include "common.s"
	.include "init.s"
	.include "nmi.s"
	.include "cursor.s"
	.include "input.s"

chr:
	.incbin "bin/graphics.chr"
chrend: