pals: .incbin "../bin/sand_pal.bin"
TOTAL_NUM_PAL_BYTES = *-pals

sky_chr:
	.repeat 8
		.byte $ff
		.byte 0
	.endrepeat
	.repeat 16
		.byte 0
	.endrepeat
sky_chr_len = * - sky_chr

sky_map:
	.repeat $400
		.word 1 << 10
	.endrepeat
sky_map_len = * - sky_map

init_ppu:
	; palettes
	stz CGADD
	dma 0, DMAP_1REG_2WR, pals, CGDATA, TOTAL_NUM_PAL_BYTES

	; sand chr (mode 7) (appears first in VRAM)
	stz VMADDL
	stz VMADDH
	lda #VMAIN_WORDINC
	sta VMAIN
	dma 0, DMAP_2REG_1WR, chr, VMDATAL, CHR_LEN

	ldx #sky_map_len
	sta $20
	; sky chr (mode 1) (4bpp) (appears second in VRAM)
	stz VMADDL
	lda #$40
	sta VMADDH
	dma 0, DMAP_2REG_1WR, sky_chr, VMDATAL, sky_chr_len

	; sky map
	stz VMADDL
	lda #$78
	sta VMADDH
	dma 0, DMAP_2REG_1WR, sky_map, VMDATAL, sky_map_len

	; where is the bg tilemap in vram?
	lda #$78 ; $2000
	sta BG1SC
	; lda #$24
	; sta BG3SC

	; where are the bg tiles in vram?
	lda #4 ; $8000 for BG1
	sta BG12NBA
	
	; obj
	; lda #OBSEL_16x16_32x32
	; sta OBSEL

	lda #TMSW_BG1
	sta TM
	
	lda #BGMODE_MODE1
	sta BGMODE

	rts