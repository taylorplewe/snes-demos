init_ppu:
	; chr
	stz VMADDL
	stz VMADDH
	lda #VMAIN_WORDINC
	sta VMAIN
	dma 0, DMAP_2REG_1WR, chr, VMDATAL, CHR_LEN

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