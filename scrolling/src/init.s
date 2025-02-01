pals:
	.word $0000, $0463, $14a4, $14c6, $14e6, $1907, $1948, $1d8b, $210a, $254b, $21ed, $2650, $0000, $0000, $0000, $0000
TOTAL_NUM_PAL_BYTES = *-pals

init_ppu:
	; official SNES dev manual's recommended startup registers
	; I know this is less efficient than zeroing with a 16-bit accumulator, but this is far more readable and gives me peace of mind
	ldx #0
	lda #INIDISP_BLANK | $ff
	sta INIDISP
	stz OBSEL
	stx OAMADDL
	stz BGMODE
	stz MOSAIC
	stz BG1SC
	stz BG2SC
	stz BG3SC
	stz BG4SC
	stz BG12NBA
	stz BG34NBA
	stz BG1HOFS ; ww
	stz BG1HOFS
	stz BG2HOFS ; ww
	stz BG2HOFS
	stz BG3HOFS ; ww
	stz BG3HOFS
	stz BG4HOFS ; ww
	stz BG4HOFS
	stz BG1VOFS ; ww
	stz BG1VOFS
	stz BG2VOFS ; ww
	stz BG2VOFS
	stz BG3VOFS ; ww
	stz BG3VOFS
	stz BG4VOFS ; ww
	stz BG4VOFS
	lda #VMAIN_WORDINC
	sta VMAIN
	stx VMADDL
	stz M7SEL
	lda #<$0100
	sta M7A ; ww
	lda #>$0100
	sta M7A
	stz M7B ; ww
	stz M7B
	stz M7C ; ww
	stz M7C
	lda #<$0100
	sta M7D ; ww
	lda #>$0100
	sta M7D
	stz M7X ; ww
	stz M7X
	stz M7Y ; ww
	stz M7Y
	stz CGADD
	stz W12SEL
	stz W34SEL
	stz WOBJSEL
	stz WH0
	stz WH1
	stz WH2
	stz WH3
	stz WBGLOG
	stz WOBJLOG
	stz TM
	stz TS
	stz TMW
	stz TSW
	lda #CGWSEL_PREVENT_ALWAYS
	sta CGWSEL
	stz CGADSUB
	lda #COLDATA_R | COLDATA_G | COLDATA_B | $00
	sta COLDATA
	stz SETINI
	stz NMITIMEN
	lda #$ff
	sta WRIO
	stz WRMPYA
	stz WRMPYB
	stx WRDIVL
	stz WRDIVB
	stx HTIMEL
	stx VTIMEL
	stz MDMAEN
	stz HDMAEN
	stz MEMSEL

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