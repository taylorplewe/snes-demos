pals:
	.include "pals.s"
PALS_LEN = *-pals

blankmap:
	.include "map.s"
MAP_LEN = *-blankmap

init_ppu:
	; palettes
	stz CGADD
	dma_ch0 #DMAP_1REG_2WR, pals, CGDATA, #PALS_LEN

	; chr
	stz VMADDL
	stz VMADDH
	lda #VMAIN_WORDINC
	sta VMAIN
	dma_ch0 #DMAP_2REG_1WR, chr, VMDATAL, #chrend - chr

	; bg
		; tilemap
		ldx #$2000
		stx VMADDL
		dma_ch0 #DMAP_2REG_1WR, blankmap, VMDATAL, #MAP_LEN
		ldx #$2400
		stx VMADDL
		dma_ch0 #DMAP_2REG_1WR, blankmap, VMDATAL, #MAP_LEN

		; where is the bg tilemap in vram?
		lda #$20 ; $2000
		sta BG1SC
		lda #$24
		sta BG2SC

		; where are the bg tiles in vram?
		lda #0 ; $0000
		sta BG12NBA
		sta BG34NBA
	
	; obj
		lda #OBSEL_16x16_32x32
		sta OBSEL

	; enable bg1 & objs
	lda #TMSW_OBJ | TMSW_BG1 | TMSW_BG2
	sta TM
	
	; mode 1
	lda #BGMODE_MODE1
	sta BGMODE

	; bg1 scroll
	lda #<-1
	sta BG1VOFS
	lda #>-1
	stz BG1VOFS
	; bg3 scroll
	lda #<-4
	sta BG2HOFS
	lda #>-4
	sta BG2HOFS
	lda #<-5
	sta BG2VOFS
	lda #>-5
	stz BG2VOFS

	; draw save button
		lda #$c0
		sta BG1_BUFF + (2 + (18*32))*2
		lda #$c1
		sta BG1_BUFF + (3 + (18*32))*2
		lda #$c1
		sta BG1_BUFF + (4 + (18*32))*2
		lda #$c1
		sta BG1_BUFF + (5 + (18*32))*2
		lda #$c2
		sta BG1_BUFF + (6 + (18*32))*2
		lda #$d0
		sta BG1_BUFF + (2 + (19*32))*2
		lda #$d1
		sta BG1_BUFF + (3 + (19*32))*2
		lda #$d1
		sta BG1_BUFF + (4 + (19*32))*2
		lda #$d1
		sta BG1_BUFF + (5 + (19*32))*2
		lda #$d2
		sta BG1_BUFF + (6 + (19*32))*2

		lda #'S'
		sta BG3_BUFF + (2 + (18*32))*2
		lda #%00100000
		sta BG3_BUFF + (2 + (18*32))*2+1
		lda #'A'
		sta $60
		sta BG3_BUFF + (3 + (18*32))*2
		lda #%00100000
		sta BG3_BUFF + (3 + (18*32))*2+1
		lda #'V'
		sta BG3_BUFF + (4 + (18*32))*2
		lda #%00100000
		sta BG3_BUFF + (4 + (18*32))*2+1
		lda #'E'
		sta BG3_BUFF + (5 + (18*32))*2
		lda #%00100000
		sta BG3_BUFF + (5 + (18*32))*2+1

	rts