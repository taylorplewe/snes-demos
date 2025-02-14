.scope irqs

.zeropage
	irq_routine_addr: .res 2
.code

.proc init
	ldx #185
	stx HTIMEL
	ldx #112
	stx VTIMEL
	cli
	jsr update
	rts
.endproc

.proc update
	ldx #change_to_mode_7
	stx irq_routine_addr
	rts
.endproc

.proc change_to_mode_7
	lda hdma::x_pos+1
	sta BG1HOFS
	stz BG1HOFS
	lda hdma::y_pos+1
	sta BG1VOFS
	stz BG1VOFS
	lda #BGMODE_MODE7
	sta BGMODE
	rts
.endproc

.endscope

irq:
	a8
	pha
	phx
	phy
	
	lda HVBJOY
	bit #HVBJOY_IN_VBLANK
	beq :+
		lda TIMEUP ; clear IRQ read thing
		bra @end
	:

	; irq code
	ldx #0
	jsr (irqs::irq_routine_addr, x)
	
	jsr fog::irq

	lda TIMEUP ; clear IRQ read thing

	@end:
	ply
	plx
	pla
	rti