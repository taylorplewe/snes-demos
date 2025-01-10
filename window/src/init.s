orca_pals:
	.word $03e6, $0000, $2108, $318c, $1010, $0110, $4210, $6318, 0, 0, 0, 0, 0, 0, 0, 0
orca_pals_len = * - orca_pals

amst_pals:
; .word $ffff, $56F9, $56B3, $2108, $677D, $3A13, $294D, $210C, $294A, $18C6, $39EE, $1DAC, $14CA, $0C64, $0000, $25B8
.word $7FFF, $294A, $2108, $18C6, $0C64, $294D, $210C, $14CA, $677D, $56F9, $3A13, $56B3, $25B8, $1DAC, $39EE, $0000
amst_pals_len = * - amst_pals

init_ppu:
	; palettes (first amsterdam, then orca)
	stz CGADD
	dma 0, CGDATA, DMAP_1REG_2WR, amst_pals, amst_pals_len

	lda #128
	sta CGADD
	dma 0, CGDATA, DMAP_1REG_2WR, orca_pals, orca_pals_len

	; chr
	stz VMADDL
	stz VMADDH
	lda #VMAIN_WORDINC
	sta VMAIN
	dma 0, VMDATAL, DMAP_2REG_1WR, orca_chr, orca_chr_len

	ldx #$4000
	stx VMADDL
	dma 0, VMDATAL, DMAP_2REG_1WR, amst_chr, amst_chr_len

	; bg
		; where is the bg tilemap in vram?
		lda #$10 ; $2000
		sta BG1SC
		; lda #$24
		; sta BG3SC

		; where are the bg tiles in vram?
		lda #$04 ; $0000
		sta BG12NBA
		; stz BG34NBA

		; scroll
		stz BG1HOFS
		stz BG1HOFS
		lda #<$ffff
		sta BG1VOFS
		lda #>$ffff
		sta BG1VOFS
	; obj
		lda #OBSEL_16x16_32x32
		sta OBSEL

	; enable bg1 & objs
	lda #TMSW_OBJ | TMSW_BG1
	sta TM
	
	; mode 1
	lda #BGMODE_MODE1 | BGMODE_BG3PRIOR
	sta BGMODE

	; write tilemap	
	ldx #$1000
	stx VMADDL
	ldx #0
	lda #VMAIN_WORDINC
	sta VMAIN
	@write_tilemap_loop:
		stx VMDATAL
		inx
		cpx #(256/8) * (224/8) ; 896 total tiles
		bcc @write_tilemap_loop

	rts