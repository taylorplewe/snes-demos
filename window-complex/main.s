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
test_x: .res 1


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
    inc test_x
    jsr window::update

    a16
    lda #$a0 ; p2.y
    pha
    lda #$20 ; p2.x
    pha
    lda #$0a ; p1.y
    pha
    ; lda #$80 ; p1.x
    lda test_x
    jsr window::bresenham
    pla
    pla
    pla
    a8

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
