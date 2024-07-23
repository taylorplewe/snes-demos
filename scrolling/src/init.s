pals:
	.word $0000, $0463, $14a4, $14c6, $14e6, $1907, $1948, $1d8b, $210a, $254b, $21ed, $2650, $0000, $0000, $0000, $0000
TOTAL_NUM_PAL_BYTES = *-pals

init_ppu:
	; palettes
	stz CGADD
	dma_ch0 #DMAP_1REG_2WR, pals, CGDATA, #TOTAL_NUM_PAL_BYTES

	stz CGADD
	lda #0
	sta CGDATA
	sta CGDATA

	; chr
	stz VMADDL
	stz VMADDH
	lda #VMAIN_WORDINC
	sta VMAIN
	dma_ch0 #DMAP_2REG_1WR, chr, VMDATAL, #CHR_LEN

	; bg
		; lda #$00
		; sta VMADDL
		; lda #$24
		; sta VMADDH

		; dma_ch0 #DMAP_2REG_1WR, bg3, VMDATAL, #TOTAL_NUM_MAP_BYTES

		; where is the bg tilemap in vram?
		lda #$20 | BGSC_64x64 ; $2000
		sta BG1SC

		; where are the bg tiles in vram?
		lda #0 ; $0000
		sta BG12NBA
		sta BG34NBA
	
	; obj
		lda #OBSEL_16x16_32x32
		sta OBSEL

	; enable bg1 & objs
	lda #TMSW_BG1
	sta TM
	
	; mode 1
	lda #BGMODE_MODE1 | BGMODE_BG3PRIOR
	sta BGMODE

	; bg1 scroll
	lda #<-1
	sta BG1VOFS
	lda #>-1
	stz BG1VOFS
	lda #0
	sta BG1HOFS
	sta BG1HOFS

	rts