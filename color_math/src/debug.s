.scope str
	NEWLINE = '['
	DemoMode: .byte "Demo mode: ", 0
	ClipColors: .byte "Clip colors: ", 0
	PreventMath: .byte "Prevent math: ", 0
	BlendMode: .byte "Blend mode: ", 0

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

	.zeropage
string_addr: .res 3
tilemap_addr: .res 2
tile_info_byte: .res 1

	.code
font_bin: .incbin "../../debug_font.bin"
font_bin_len = * - font_bin

font_pals: .incbin "../bin/debug_font_pals.bin"
font_pals_len = * - font_pals

.proc init
	ldx #$1b60
	stx tilemap_addr

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

	; clear the BG3 tilemap
	ldx #$1800
	stx VMADDL
	dma 0, VMDATAL, DMAP_2REG_1WR | DMAP_FIXED_SOURCE, zero, 32*28

	ldx #str::ClipColors
	lda #FontColor::White
	jsr print

	ldx #str::OutsideWindow
	lda #FontColor::Yellow
	jsr print

	ldx #str::PreventMath
	lda #FontColor::White
	jsr print

	ldx #str::Never
	lda #FontColor::Yellow
	jsr print

	ldx #str::BlendMode
	lda #FontColor::White
	jsr print

	ldx #str::AddThenHalf
	lda #FontColor::Yellow
	jsr print

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
	sta tile_info_byte
	xba

	ldx tilemap_addr
	stx VMADDL
	ldy #0
	loop:
		lda [string_addr], y
		beq end

		; newline?
		cmp #str::NEWLINE
		bne :+
			a16
			lda tilemap_addr
			and #%1111111111100000
			sec
			sbc #32
			sta tilemap_addr
			sta VMADDL
			lda #0
			a8
			lda tile_info_byte
			xba
			iny
			bra loop
		:

		sec
		sbc #$20
		a16
		sta VMDATAL
		inc tilemap_addr
		a8
		iny
		bra loop
	end:
	rts
.endproc

.endscope