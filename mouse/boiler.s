	.p816	; tell ca65 we're in 65816 mode
	.i16	; tell ca65 X and Y registers are 16-bit
	.a8		; tell ca65 that A register and memory instructions are 16-bit
	.smart +	; try to automatically tell when I switch registers between 8- and 16-bit
	
	.include "macros.s"
	.include "../snes.inc"

	.segment "HEADER"
		.byte "SNES MOUSE TEST      "
	.segment "ROMINFO"
		.byte %00110000	; FastROM
		.byte 0			; no battery or expansion chips or whatever
		.byte 7			; 128kb
		.byte 0			; 0kb SRAM
		.byte 0, 0		; developer ID
		.byte 0			; version num
		.word $aaaa, $5555 ; checksum & complement

	.segment "VECTORS"
		; native mode vectors
		.word 0		; COP		triggered by COP instruction
		.word 0 	; BRK		triggered by BRK instruction
		.word 0 	; ABORT		not used in the SNES
		.word nmi 	; NMI
		.word 0		;
		.word 0		; IRQ		can be used for horizontal iterrupts?
		.word 0		;
		.word 0		;
		; emulation mode vectors
		.word 0 	; COP
		.word 0		;
		.word 0 	; ABORT
		.word 0 	; NMI
		.word reset ; RESET
		.word 0		; IRQ/BRK