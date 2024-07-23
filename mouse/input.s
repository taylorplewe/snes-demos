; The mouse returns 32 bits of data out Data1, and 1 bits thereafter. The data is:

; 00000000rlss0001 YyyyyyyyXxxxxxxx
; l/r are the two mouse buttons. 'ss' are the "speed bits", which are incremented mod 3 if Clock cycles while Latch is active. Y/X are the direction bits (set is up/left), and yyyyyyy/xxxxxxx are the distance traveled in the appropriate direction. Supposedly, the 'speed bits' may not match the internal speed setting when the mouse first receives power. The speed setting controls the delta curve of the mouse, with 0 giving a flat curve and 2 giving the greatest delta response. Data2 and IOBit are presumably not connected, but this is not known for sure.

; mouse_input
MOUSE_L				= %0000000001000000
MOUSE_R				= %0000000010000000

; mouse_input+2
MOUSE_X_DIR			= %0000000010000000
MOUSE_X_TRAVELLED	= %0000000001111111
MOUSE_Y_DIR			= %1000000000000000
MOUSE_Y_TRAVELLED	= %0111111100000000

.zeropage
mouse_input: .res 4
mouse_input_prev: .res 4
mouse_input_pressed: .res 4
.code
get_mouse_input:

	lda HVBJOY
	ora #$01
	sta HVBJOY  ; pretend it's writable

	lda #$01
	sta JOYSER0
	stz JOYSER0

	ldx #16
	@loop1:
		lda JOYSER0
		a16
		lsr
		rol mouse_input
		a8

		dex
		bne @loop1
	ldx #16
	@loop2:
		lda JOYSER0
		a16
		lsr
		rol mouse_input+2
		a8

		dex
		bne @loop2

	lda HVBJOY
	and #$7E
	sta HVBJOY  ; pretend it's writable again
	rts

set_mouse_input_prev:
	ldx mouse_input
	stx mouse_input_prev
	ldx mouse_input+2
	stx mouse_input_prev+2
	rts

set_mouse_input_pressed:
	a16
	lda mouse_input_prev
	eor #$ffff
	and mouse_input
	sta mouse_input_pressed

	lda mouse_input_prev+2
	eor #$ffff
	and mouse_input+2
	sta mouse_input_pressed+2
	a8
	rts