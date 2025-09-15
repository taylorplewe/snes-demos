.p816
.smart

.include "src/header.inc"
.include "../snes.inc"
.include "src/macros.inc"

.include "src/ppu.s"
.include "src/window.s"

.zeropage

local: .res SIZEOF_LOCAL_VARS
nmi_ready: .res 1


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

    a16
    ldy #$300
    lda #40
    pha
    lda #40
    pha
    lda #30
    pha
    lda #30
    jsr window::bresenham
    pla
    pla
    pla
    a8

forever:

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
