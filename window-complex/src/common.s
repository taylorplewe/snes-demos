.code

; get COS(A:8) in A:16
cos:
	clc ; clear carry for add
	adc #$40 ; add 1/4 rotation

; get SIN(A:8) in A:16. enter with the Z flag reflecting the contents of A
sin:
	bpl @sinCos		; just get SIN/COS and return if +ve

	and #$7f		; else make +ve
	jsr @sinCos		; get SIN/COS
	
	; now do twos complement
	a16
	neg
	a8
	rts

	; get 16-bit A from SIN/COS table
	@sinCos:
	cmp #$41		; compare with max+1
	bcc @quadrant	; branch if less

	eor #$7f		; wrap $41-$7f ..
	inc             ; .. to $3F-$00

	@quadrant:
	asl	a			; * 2 bytes per value
	i8
	a16
	tax				; copy to index
	lda sintab, x	; get 16-bit SIN/COS table value
	i16
	a8
	rts

sintab:
	.word $0000,$0324,$0647,$096a,$0c8b,$0fab,$12c8,$15e2
	.word $18f8,$1c0b,$1f19,$2223,$2528,$2826,$2b1f,$2e11
	.word $30fb,$33de,$36be,$398c,$3c56,$3f17,$41ce,$447a
	.word $471c,$49b4,$4c3f,$4ebf,$5133,$539b,$55f5,$5842
	.word $5a82,$5cb4,$5ed7,$60ec,$62f2,$64eb,$66cf,$68a6
	.word $6a6d,$6c24,$6dc4,$6f5f,$70e2,$7255,$73b5,$7504
	.word $7641,$776c,$7884,$798a,$7a7d,$7b5d,$7c2a,$7ce3
	.word $7d8a,$7e1d,$7e9d,$7f09,$7f62,$7fa7,$7fd8,$7ff6
	.word $7fff