.scope fog

r_fog_vals: .incbin "../bin/r_fog_vals.bin"
g_fog_vals: .incbin "../bin/g_fog_vals.bin"
b_fog_vals: .incbin "../bin/b_fog_vals.bin"

.proc init
	lda #CGADSUB_BG1 | CGADSUB_BACKDROP | CGADSUB_ADD
	sta CGADSUB
	lda #CGWSEL_FIXED_COLOR
	sta CGWSEL

	dma_set 5, COLDATA, DMAP_1REG_1WR, r_fog_vals
	dma_set 6, COLDATA, DMAP_1REG_1WR, g_fog_vals
	dma_set 7, COLDATA, DMAP_1REG_1WR, b_fog_vals

	lda #%11100000
	tsb m_hdmaen
	rts
.endproc

.proc vblank
	; make sky dark (subtract)
	lda #CGADSUB_BG1 | CGADSUB_BACKDROP | CGADSUB_SUBTRACT
	sta CGADSUB
	rts
.endproc

.proc irq
	; make horizon lighter (add)
	lda #CGADSUB_BG1 | CGADSUB_BACKDROP | CGADSUB_ADD
	sta CGADSUB
	rts
.endproc

.endscope
