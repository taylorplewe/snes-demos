.p816
.smart

.include "src/header.inc"
.include "../snes.inc"
.include "src/macros.inc"

.include "src/ppu.s"
.include "src/window.s"

.bss

test1: .res 1
nmi_ready: .res 1

; .org 0
; test2: .res 1
; .reloc


.rodata

zero: .byte 0


.code

.a8
.i8
reset:
	clc
	xce

	i16
	ldx #$1fff
	txs

	clearMemory 0, 0
	sta MDMAEN

	lda #$ea
	sta test1

	jsr ppu::clear
	jsr ppu::setUpAmsterdam
	jsr window::init
	jsr ppu::init

forever:
	; update

	inc nmi_ready
	wai
	bra forever

nmi:
	lda nmi_ready
	beq end

	jsr window::vblank
	
	stz nmi_ready
	end:
	rti
