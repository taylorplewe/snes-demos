init_ppu:
	; palettes
	; stz CGADD
	; m_dma_ch0 DMAP_1REG_2WR, pals, CGDATA, TOTAL_NUM_PAL_BYTES

	; chr
	stz VMADDL
	stz VMADDH
	lda #VMAIN_WORDINC
	sta VMAIN
	m_dma_ch0 DMAP_2REG_1WR, chr, VMDATAL, chrend - chr

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
	; lda #BGMODE_MODE1 | BGMODE_BG3PRIOR
	; sta BGMODE

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