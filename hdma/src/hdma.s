.scope hdma

.proc init
	lda #2
	sta HDMAEN
	rts
.endproc

.endscope