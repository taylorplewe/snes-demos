.scope ppu

.rodata

amsterdam_pal:
	.incbin "..\bin\amst.pal"
amsterdam_pal_len = * - amsterdam_pal


.segment "BANK1"

amsterdam:
	.incbin "..\chr\amst1.bin"
	.incbin "..\chr\amst2.bin"
amsterdam_len = * - amsterdam


.code

.a8
.i16
.proc clear
	ldx #0
	lda #INIDISP_BLANK
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

	rts
.endproc

.a8
.i16
.proc setUpAmsterdam
	stz CGADD
	dma 0, CGDATA, DMAP_1REG_2WR, amsterdam_pal, amsterdam_pal_len

	; tilemap at $0000.w
	ldx #0
	stx VMADDL
	lda #VMAIN_WORDINC
	sta VMAIN
	tilemapLoop:
		stx VMDATAL
		inx
		cpx #896
		bcc tilemapLoop

	; chr data at $1000.w
	ldx #$1000
	stx VMADDL
	dma 0, VMDATAL, DMAP_2REG_1WR, amsterdam, amsterdam_len

	lda #01
	sta BG12NBA
	stz BG1SC

	lda #1
	sta BGMODE

	lda #$ff
	sta BG1VOFS
	sta BG1VOFS

	rts
.endproc

.a8
.i16
.proc init
	lda #TMSW_BG1
	sta TM

	lda #$0f
	sta INIDISP

	lda #NMITIMEN_NMIENABLE
	sta NMITIMEN
	
	rts
.endproc
	
.endscope
