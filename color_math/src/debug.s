.scope str
	NEWLINE = '['
	DemoMode: .byte "(Y) Demo mode: ", 0
	ClipColors: .byte "(B) Clip colors: ", 0
	PreventMath: .byte "(X) Prevent math: ", 0
	BlendMode: .byte "(A) Blend mode: ", 0

	Fade: .byte "fade[", 0
	Gradient: .byte "gradient[", 0
	Subscreen: .byte "subscreen[", 0

	Always: .byte "always[", 0
	Never: .byte "never[", 0
	InsideWindow: .byte "inside window[", 0
	OutsideWindow: .byte "outside window[", 0

	Add: .byte "add[", 0
	Subtract: .byte "subtract[", 0
	AddThenHalf: .byte "add then half[", 0
.endscope

.scope debug

.enum FontColor
	White
	Yellow
	Green
	Red
.endenum

SCREEN_BUFF = $500

	.zeropage
string_addr: .res 3
screen_buff_addr: .res 2

	.code
font_bin: .incbin "../../debug_font.bin"
font_bin_len = * - font_bin

font_pals: .incbin "../bin/debug_font_pals.bin"
font_pals_len = * - font_pals

BOTTOM_LEFT_TILE_ADDR = $6c0

.proc init
	; load debug font palette
	lda #16
	sta CGADD
	dma 0, CGDATA, DMAP_1REG_2WR, font_pals, font_pals_len

	; load font CHR
	ldx #$3000
	stx VMADDL
	dma 0, VMDATAL, DMAP_2REG_1WR, font_bin, font_bin_len

	; tell BG3 where to find tiles
	lda #$03
	sta BG34NBA

	; tell BG3 where the tilemap is
	lda #$18
	sta BG3SC

	; clear screen
	jsr clear_buffer
	jsr write_buffer_to_vram

	rts
.endproc

.proc update
	ldx #BOTTOM_LEFT_TILE_ADDR
	stx screen_buff_addr

	; jsr clear_buffer
	; rts
.endproc

.proc clear_buffer
	ldx #SCREEN_BUFF
	stx WMADDL
	stz WMADDH
	dma 0, WMDATA, DMAP_1REG_1WR | DMAP_FIXED_SOURCE, zero, 32*28*2
	rts
.endproc

.proc vblank
	; jsr write_buffer_to_vram
.endproc
.proc write_buffer_to_vram
	ldx #$1800
	stx VMADDL
	dma 0, VMDATAL, DMAP_2REG_1WR, SCREEN_BUFF, 32*28*2
	rts
.endproc

; x - address to null-terminated string
; a - font color (debug::FontColor::White)
.proc print
	stx string_addr
	stz string_addr+2 ; bank
	asl a
	asl a
	ora #(4<<2) | (1<<5) ; palette 4 (2bpp), priority
	xba

	ldx screen_buff_addr
	ldy #0
	loop:
		lda [string_addr], y
		beq end

		; newline?
		cmp #str::NEWLINE
		bne :+
			a16
			pha
			lda screen_buff_addr
			and #%1111111111000000
			sec
			sbc #64
			tax
			pla
			a8
			iny
			bra loop
		:

		sec
		sbc #$20
		a16
		sta SCREEN_BUFF, x
		inx
		inx
		a8
		iny
		bra loop
	end:
	stx screen_buff_addr
	rts
.endproc

.endscope