OAM_DMA_ADDR_LO	= $1d00 ; 2 whole pages of low table OAM, 32 bytes of high table shared with stack page ($1f--)
OAM_DMA_ADDR_HI	= OAM_DMA_ADDR_LO + 512
OAM_NUM_BYTES	= 544
OAM_X			= OAM_DMA_ADDR_LO
OAM_Y			= OAM_DMA_ADDR_LO + 1
OAM_TILE		= OAM_DMA_ADDR_LO + 2
OAM_INFO		= OAM_DMA_ADDR_LO + 3

.scope ppu

chr:
	.incbin "bin/chr.bin"
CHR_LEN = *-chr

pals:
	.word $0000, $0463, $14a4, $14c6, $14e6, $1907, $1948, $1d8b, $210a, $254b, $21ed, $2650, $0000, $0000, $0000, $0000
TOTAL_NUM_PAL_BYTES = *-pals

.proc init
	; palettes
	stz CGADD
	dma 0, CGDATA, DMAP_1REG_2WR, pals, TOTAL_NUM_PAL_BYTES

	stz CGADD
	lda #0
	sta CGDATA
	sta CGDATA

	; chr
	stz VMADDL
	stz VMADDH
	lda #VMAIN_WORDINC
	sta VMAIN
	dma 0, VMDATAL, DMAP_2REG_1WR, chr, CHR_LEN

	; bg
		; tilemap
		; ldx #$2000
		; stx VMADDL
		; already there hun
		; m_dma_ch0 DMAP_2REG_1WR, map, VMDATAL, TOTAL_NUM_MAP_BYTES

		; lda #$00
		; sta VMADDL
		; lda #$24
		; sta VMADDH

		; m_dma_ch0 DMAP_2REG_1WR, bg3, VMDATAL, TOTAL_NUM_MAP_BYTES

		; where is the bg tilemap in vram?
		; lda #$20 ; $2000
		; sta BG1SC
		; lda #$24
		; sta BG3SC

		; where are the bg tiles in vram?
		lda #0 ; $0000
		sta BG12NBA
		sta BG34NBA
	
	; obj
		lda #OBSEL_16x16_32x32
		sta OBSEL

	; enable bg1 & objs
	lda #TMSW_OBJ
	sta TM
	
	; mode 1
	lda #BGMODE_MODE1 | BGMODE_BG3PRIOR
	sta BGMODE

	; bg1 scroll
	; lda #<-1
	; sta BG1VOFS
	; lda #>-1
	; stz BG1VOFS
	; ; bg3 scroll
	; lda #<-1
	; sta BG3VOFS
	; lda #>-1
	; stz BG3VOFS

	rts
.endproc

OAM_MUSH_LO: .byte 224
OAM_MUSH_HI: .byte $ff
.proc update
	; clear OAM buffer
	ldx #OAM_DMA_ADDR_LO
	stx WMADDL
	stz WMADDH
	dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, OAM_MUSH_LO, 512
	dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, OAM_MUSH_HI, 32
	rts
.endproc

.proc vblank
	; write OAM (sprites) buffer to VRAM
	ldx #0
	stx OAMADDL
	dma 0, OAMDATA, DMAP_1REG_1WR, OAM_DMA_ADDR_LO, OAM_NUM_BYTES
	rts
.endproc

.endscope