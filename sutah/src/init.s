pals: .incbin "../bin/sand_pal.bin"
pals_len = *-pals

sonic_pals: .incbin "../bin/sonic_pal.bin"
sonic_pals_len = *-sonic_pals

shadow_chr: .incbin "../bin/shadow.chr"
shadow_chr_len = *-shadow_chr

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
	dma 0, CGDATA, DMAP_1REG_2WR, pals, pals_len

	lda #128
	sta CGADD
	dma 0, CGDATA, DMAP_1REG_2WR, sonic_pals, sonic_pals_len

	lda #128+16
	sta CGADD
	dma 0, CGDATA, DMAP_1REG_2WR, pals, pals_len
	
	lda #VMAIN_WORDINC
	sta VMAIN

	; sand chr (mode 7) (appears first in VRAM)
	stz VMADDL
	stz VMADDH
	dma 0, VMDATAL, DMAP_2REG_1WR, chr, CHR_LEN

	; sky chr (mode 1) (4bpp) (appears second in VRAM)
	stz VMADDL
	lda #$50
	sta VMADDH
	dma 0, VMDATAL, DMAP_2REG_1WR, sky_chr, sky_chr_len

	; sky map
	stz VMADDL
	lda #$44
	sta VMADDH
	dma 0, VMDATAL, DMAP_2REG_1WR, sky_map, sky_map_len

	; shadow chr
	stz VMADDL
	lda #$40
	sta VMADDH
	dma 0, VMDATAL, DMAP_2REG_1WR, shadow_chr, shadow_chr_len

	; where is the bg tilemap in vram?
	lda #$44 ; $7800
	sta BG1SC
	; lda #$24
	; sta BG3SC

	; where are the bg tiles in vram?
	lda #5 ; $6000 for BG1
	sta BG12NBA

	lda #OBSEL_16x16_32x32 | OBSEL_BASE(4) ; $4000
	sta OBSEL

	lda #TMSW_BG1 | TMSW_OBJ
	sta TM
	
	lda #BGMODE_MODE1
	sta BGMODE

	rts