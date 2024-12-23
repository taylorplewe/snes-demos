.scope irqs

.zeropage
	irq_test: .res 1
.code

.i16
.proc init
	ldx #200
	stx HTIMEL
	cli
	rts
.endproc

.endscope

.rodata
	sky_grad: .incbin "../bin/sky_grad.bin"
	sky_grad_len = *-sky_grad
.code
irq:
	php
	pha
	phx
	phy
	
	lda HVBJOY
	bit #HVBJOY_IN_VBLANK
	beq :+
		stz scanline
		lda TIMEUP ; clear IRQ read thing
		ply
		plx
		pla
		plp
		rti
	:

	stz CGADD
	a16
	lda scanline
	asl a
	tax
	lda sky_grad, x
	a8
	sta CGDATA
	xba
	sta CGDATA

	lda TIMEUP ; clear IRQ read thing
	inc scanline

	ply
	plx
	pla
	plp
	rti