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

CONTROLLER_U			= %0000100000000000
CONTROLLER_D			= %0000010000000000
CONTROLLER_L			= %0000001000000000
CONTROLLER_R			= %0000000100000000
CONTROLLER_SHOULDER_L	= %0000000000100000
CONTROLLER_SHOULDER_R	= %0000000000010000
CONTROLLER_A			= %0000000010000000
CONTROLLER_B			= %1000000000000000
CONTROLLER_X			= %0000000001000000
CONTROLLER_Y			= %0100000000000000
CONTROLLER_START		= %0001000000000000
CONTROLLER_SELECT		= %0010000000000000

	.segment "HEADER"
		.byte "TAYLORS TEST"
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

	.zeropage

	.code
		
reset:
	; go into native mode lets gooooo
	clc
	xce ; Now you're playing with ~power~
	rep #%00010000 ; a, x and y all 16-bit
	a8
	lda #%10000001
	sta $4200 ; interrupt enable register; enable NMIs and auto joypad read

	; screen brightness & turn off screen for VRAM writes
	lda #INIDISP_BLANK | $f
	sta INIDISP
	; set first color (bg color?)
	lda #0
	sta CGADD

	; vertical scroll = -1
	lda #$ff
	sta BG1VOFS
	sta BG1VOFS

	lda #<chr
	sta $40
	lda #>chr
	sta $41

	; dma
	lda #%00000010 ; 1 register, write twice
	sta DMAP0
	ldx #amstpals
	lda #^amstpals
	xba
	lda #<CGDATA
	ldy #amstpalsend-amstpals ; pointless to only write 2 bytes bust just to test dma yk
	jsr dmatransferch0

	;jsr InitializeSNES

	ldx #$1000
	stx VMADDL
	lda #%10000000
	sta VMAIN

	; vram test
	lda #%00000001 ; 2 register, write once
	sta DMAP0
	; ldx #<chr
	lda #>chr
	xba
	lda #<chr
	a16
	tax
	stx $82
	a8
	lda #^chr
	xba
	lda #<VMDATAL
	ldy #chrend-chr
	jsr dmatransferch0
	stz VMDATAH ; last byte lmao

	jsr copytotilemap

	; turn screen back on (keep same brightness)
	lda #$f
	sta INIDISP

	; BG mode 1
	lda #1
	sta BGMODE

	; enable BGs and OBJ (sprites)
	lda #TMSW_BG1
	sta TM

	; tilemap for BG1 starts at $1000
	lda #01
	sta BG12NBA
	stz BG1SC

forever:
	inc $42
	
	jsr readp1

	wai
	bra forever

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
;	a - destination register; $21aa
;	x - low 16 bits of source address; -------- xxxxxxxx xxxxxxxx
;	b - high 8 bits of source address; bbbbbbbb -------- --------
;	y - # of bytes to transfer
dmatransferch0:
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

amstpals:
; .word $ffff, $56F9, $56B3, $2108, $677D, $3A13, $294D, $210C, $294A, $18C6, $39EE, $1DAC, $14CA, $0C64, $0000, $25B8
.word $7FFF, $294A, $2108, $18C6, $0C64, $294D, $210C, $14CA, $677D, $56F9, $3A13, $56B3, $25B8, $1DAC, $39EE, $0000
amstpalsend:

nmi:
	pha
	phx
	phy

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
	and #CONTROLLER_A | CONTROLLER_START
	beq :+
		lda #$eaea
		sta $30
	:
	a8

	@end: rts

InitializeSNES:
  LDA #$8F
  STA $2100 ; INIDISP
;   LDA #$80
;   STA $2115 ; VMAIN
  LDA #00
  LDX #$2101
CLRRegLoop:
  STA $0000,X
  INX
  CPX #$210D
  BNE CLRRegLoop
;   STA $210E
;   STA $210E
;   STA $210F
;   STA $210F
;   STA $2110
;   STA $2110
;   STA $2111
;   STA $2111
;   STA $2112
;   STA $2112
;   STA $2113
;   STA $2113
;   STA $2114
;   STA $2114
;   LDX #$2116
; CLRRegLoopB:
;   STA $0000,X
;   INX
;   CPX #$2133
;   BNE CLRRegLoopB
;   LDX #$4200
; CLRRegLoopC:
;   STA $0000,X
;   INX
;   CPX #$420D
;   BNE CLRRegLoopC
  RTS

	.include "../registers.inc"

	.segment "BANK1"
chr:
	.incbin "bin/chr.bin"
	.incbin "bin/chr2.bin"
chrend: