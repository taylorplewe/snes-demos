	.p816	; tell ca65 we're in 65816 mode
	.i16	; tell ca65 X and Y registers are 16-bit
	.a8		; tell ca65 that A register is 16-bit
	.smart +	; try to automatically tell when I switch registers between 8- and 16-bit

	.macro a8
		sep #%00100000 ; a 8 bit
	.endmacro
	.macro a16
		rep #%00100000 ; a 16 bit
	.endmacro
	.macro i8
		sep #%00010000 ; x & y 8 bit
	.endmacro
	.macro i16
		rep #%00010000 ; x & y 16 bit
	.endmacro

	.segment "HEADER"
		.byte "ORCA                 "
	.segment "ROMINFO"
		.byte %00110000	; FastROM
		.byte 0			; no battery or expansion chips or whatever
		.byte 7			; 128kb
		.byte 0			; 0kb SRAM
		.byte 0, 0		; developer ID
		.byte 0			; version num
		.word $aaaa, $5555 ; checksum & complement
	; .segment "VECTORS"
    ; .word 0, 0, 0, 0, 0, 0, 0, 0
    ; .word 0, 0, 0, 0, 0, 0, reset, 0

	.segment "VECTORS"
		; native mode vectors
		.word 0		; COP		triggered by COP instruction
		.word 0 	; BRK		triggered by BRK instruction
		.word 0 	; ABORT		not used in the SNES
		.word nmi 	; NMI
		.word 0		;
		.word 0		; IRQ		can be used for horizontal iterrupts?
		.word 0		;
		.word 0		;
		; emulation mode vectors
		.word 0 	; COP
		.word 0		;
		.word 0 	; ABORT
		.word 0 	; NMI
		.word reset ; RESET
		.word 0		; IRQ/BRK
	
	.macro m_dma_ch0 dmap, src, ppureg, count
		lda #dmap
		sta DMAP0
		ldx #src
		lda #^src
		xba
		lda #<ppureg
		ldy #count
		jsr dma_ch0
	.endmacro

	.zeropage
xscroll: .res 2
yscroll: .res 2

orcax: .res 1
orcay: .res 1
orcatile: .res 1
orcainfo: .res 1

orcaframectr: .res 1
orcaframe: .res 1
orcafacingl: .res 1
ORCANUMFRAMES = 6

finx: .res 1
fintile: .res 1


	.code
		
reset:
	; go into native mode lets gooooo
	clc
	xce ; Now you're playing with ~power~
	i16
	a8

	; clear all RAM
	ldx #0
	@clearallram:
		stz 0, x
		inx
		cpx #$2000
		bcc @clearallram
	
	dex
	txs ; stack now starts at $1fff

	lda #%10000001
	sta $4200 ; interrupt enable register; enable NMIs and auto joypad read

	; screen brightness & turn off screen for VRAM writes
	lda #INIDISP_BLANK | $f
	sta INIDISP
	; set first color (bg color?)
	lda #128
	sta CGADD

	; dma
	lda #%00000010 ; 1 register, write twice
	sta DMAP0
	ldx #orcapals
	lda #^orcapals
	xba
	lda #<CGDATA
	ldy #orcapalsend-orcapals ; pointless to only write 2 bytes bust just to test dma yk
	jsr dma_ch0


	; scroll
	ldx #0
	stx xscroll
	stx yscroll

	; load vram with orca CHR
		ldx #$1000
		stx VMADDL
		lda #VMAIN_WORDINC
		sta VMAIN
		m_dma_ch0 DMAP_2REG_1WR, orcachr, VMDATAL, orcachrend - orcachr

	jsr initoam
	
	; init orca sprite
		lda #256/2 - 16
		sta orcax
		lda #224/2 - 16
		sta orcay
		lda #$40
		sta orcatile
		lda #SPRINFO_NT1
		sta orcainfo
		
		ldx #$0100
		stx OAMADDL
		lda #%11110010
		sta OAMDATA


	; turn screen back on (keep same brightness)
	lda #$f
	sta INIDISP

	; BG mode 1
	lda #1
	sta BGMODE

	; enable BGs and OBJ (sprites)
	lda #TMSW_OBJ
	sta TM

	; tilemap for BG1 starts at $1000
	lda #01
	sta BG12NBA
	stz BG1SC

	; block move test
	; a16
	; lda #10           -1
	; ldx #testdata
	; ldy #testdest
	; mvn 0, 0
	; a8


forever:
	jsr readp1

	jsr updateorca

	wai
	bra forever

updateorca:
	a16
	lda JOY1L
	bit #JOY_L
	bne @l
	bit #JOY_R
	beq :+
	@r:
		a8
		inc orcaframectr
		stz orcafacingl
		inc orcax
		bra :+
	@l:
		a8
		inc orcaframectr
		lda #SPRINFO_HFLIP
		sta orcafacingl
		dec orcax
	:
	a16
	; make sure framectr is 0 when not moving
	lda JOY1L
	and #JOY_L | JOY_R
	bne :+
		a8
		stz orcaframectr
	:
	a8

	; update orca's frame
	lda orcaframectr
	cmp #6
	bcc :+
		stz orcaframectr
		inc orcaframe
		lda orcaframe
		cmp #ORCANUMFRAMES
		bcc :+
		stz orcaframe
	:

	; update orca's tile based on frame
	i8
	ldx orcaframe
	lda orcatiles, x
	sta orcatile
	i16 

	; update orca's bytes
	lda orcainfo
	and #SPRINFO_HFLIP ^ $ff
	ora orcafacingl
	sta orcainfo

	; orca's fin
	; x
	lda orcax
	sta finx
	lda orcafacingl
	beq :+
		lda orcax
		clc
		adc #16
		sta finx
	:
	; tile
	lda orcaframe
	asl a
	sta fintile


	rts

orcatiles:
	.byte $40, $44, $48, $4c, $80, $84

initoam:
	lda #OBSEL_16x16_32x32 | %00000
	sta OBSEL

	; clear oam
	ldx #0
	stx OAMADDL
	m_dma_ch0 DMAP_1REG_1WR | DMAP_FIXED_SOURCE, @lomush, OAMDATA, 544
	ldx #$100
	stx OAMADDL
	m_dma_ch0 DMAP_1REG_1WR | DMAP_FIXED_SOURCE, @himush, OAMDATA, 32
	

	rts
	@lomush: .byte 224
	@himush: .byte $ff

copytotilemap:
	ldx #0
	stx VMADDL
	lda #VMAIN_WORDINC
	sta VMAIN
	@loop:
		stx VMDATAL
		inx
		cpx #896
		bcc @loop
	rts

; NOTE: set DMAP0 beforehand!!
; Also don't forget to set the corresponding address register beforehand e.g. set CGADD before doing the DMA on CGDATA
; params:
;	a - destination PPU register; $21aa
;	x - low 16 bits of source address; -------- xxxxxxxx xxxxxxxx
;	b - high 8 bits of source address; bbbbbbbb -------- --------
;	y - # of bytes to transfer
dma_ch0:
	sta BBAD0
	stx A1T0L
	xba
	sta A1B0
	sty DAS0L

	lda #1
	sta MDMAEN ; run it
	rts

colordata:
	.word $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a, $127a
colordataend:

bgtest:
	; .word $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa, $aaaa
	.word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
bgtestend:

orcapals:
	.word $03e6, $0000, $2108, $318c, $1010, $0110, $4210, $6318, 0, 0, 0, 0, 0, 0, 0, 0
orcapalsend:

nmi:
	pha
	phx
	phy

	lda xscroll
	sta BG1HOFS
	lda xscroll+1
	sta BG1HOFS

	lda yscroll
	sta BG1VOFS
	lda yscroll+1
	sta BG1VOFS

	
	ldx #0
	stx OAMADDL
	lda orcax
	sta OAMDATA
	lda orcay
	sta OAMDATA
	lda orcatile
	sta OAMDATA
	lda orcainfo
	sta OAMDATA
	; fin
	lda finx
	sta OAMDATA
	lda orcay
	sec
	sbc #16
	sta OAMDATA
	lda fintile
	sta OAMDATA
	lda orcainfo
	sta OAMDATA

	ply
	plx
	pla
	rti

readp1:
	lda HVBJOY
	lsr a
	bcs readp1

	a16
	lda JOY1L		; BYsS UDLR  AXlr ----
					; $0080
					; 00000000 10000000
	and #JOY_A | JOY_START
	beq :+
		lda #$eaea
		sta $30
	:
	a8

	@end: rts
;

	.include "../snes.inc"
	orcachr: .incbin "bin/orca.bin"
orcachrend:

	.segment "BANK1"
	.segment "BANK2"
	.segment "BANK3"