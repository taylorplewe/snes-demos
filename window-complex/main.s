.p816
.smart

.include "src/header.inc"
.include "../snes.inc"
.include "src/macros.inc"
.include "src/common.s"

.include "src/ppu.s"
.include "src/dda.s"
.include "src/window.s"

.zeropage

temp:      .res SIZEOF_TEMP_VARS
local:     .res SIZEOF_LOCAL_VARS
nmi_ready: .res 1
test_x:    .res 2
test_y:    .res 2
counter:   .res 2


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

    jsr ppu::clear
    jsr ppu::setUpAmsterdam
    jsr window::init
    jsr ppu::init

forever:
    a16
    inc counter
    a8
    waitForInput:
    	lda HVBJOY
    	lsr a
    	bcs waitForInput

    jsr window::update
    ; wdm 0

    inc nmi_ready
    wai
    bra forever

nmi:
    lda nmi_ready
    beq end

    jsr window::vblank
    
    stz nmi_ready
    end:
    ; wdm 0
    rti
