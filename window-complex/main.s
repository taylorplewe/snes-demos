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
test_x: .res 2
test_y: .res 2


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
    waitForInput:
    	lda HVBJOY
    	lsr a
    	bcs waitForInput

    a16
    lda JOY1L
    bit #JOY_U
    bne moveU
    bit #JOY_D
    bne moveD
    lrCheck:
    lda JOY1L
    bit #JOY_L
    bne moveL
    bit #JOY_R
    bne moveR
    bra moveEnd
    moveU:
        dec test_y
        bra lrCheck
    moveD:
        inc test_y
        bra lrCheck
    moveL:
        dec test_x
        bra moveEnd
    moveR:
        inc test_x
    moveEnd:
    a8

    jsr window::update

    a16
    lda #$a0 ; p2.y
    pha
    lda #$20 ; p2.x
    pha
    ; lda #$0a ; p1.y
    lda test_y
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
