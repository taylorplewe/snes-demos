.scope fog

r_fog_vals: .incbin "../bin/r_fog_vals.bin"
g_fog_vals: .incbin "../bin/g_fog_vals.bin"
b_fog_vals: .incbin "../bin/b_fog_vals.bin"

.proc init
	lda #CGADSUB_BG1 | CGADSUB_BACKDROP | CGADSUB_ADD
	sta CGADSUB
	lda #CGWSEL_FIXED_COLOR | CGWSEL_PREVENT_ALWAYS
	sta CGWSEL

	dma_set 5, COLDATA, DMAP_1REG_1WR, r_fog_vals
	dma_set 6, COLDATA, DMAP_1REG_1WR, g_fog_vals
	dma_set 7, COLDATA, DMAP_1REG_1WR, b_fog_vals

	lda m_hdmaen
	ora #%11100000
	sta m_hdmaen
	rts
.endproc

.proc vblank
	lda #CGWSEL_FIXED_COLOR | CGWSEL_PREVENT_ALWAYS
	sta CGWSEL
	rts
.endproc

.proc irq
	; enable color math
	lda #CGWSEL_FIXED_COLOR
	sta CGWSEL
	rts
.endproc

.endscope
