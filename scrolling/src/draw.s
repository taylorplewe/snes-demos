.scope draw

.proc Init
	ldx #$2000
	stx VMADDL
		; dma_ch0 #DMAP_2REG_1WR, map, VMDATAL, #MAP_LEN
	
	; r in range 32
		; rr in range 4
			; c in range 32
				; cc in range 4
	
	r = local
	rr = local+2
	c = local+4
	map_ind = local+6
	map_ind_reset = local+8
	metas_ind = local+10
	nt = local+12

	a16
	stz map_ind
	stz map_ind_reset
	stz metas_ind
	lda #4
	sta nt

	nt_loop:
		stz r
		r_loop:
			stz rr
			rr_loop:
				stz c
				c_loop:
					ldx map_ind
					lda #0
					a8
					lda map, x
					a16
					asl a
					asl a
					asl a
					asl a ; x16 tiles in a metatile
					asl a ; words
					sta metas_ind
					lda rr
					asl a
					asl a ; x4 tiles per metatile row
					asl a ; words
					clc
					adc metas_ind
					tax
					.repeat 4
					lda metas, x
					sta VMDATAL
					inx
					inx
					.endrep
					; c_next:
					inc map_ind
					inc c
					lda c
					cmp #8
					bcc c_loop
				; rr_next:
				lda map_ind_reset
				sta map_ind
				inc rr
				lda rr
				cmp #4
				bcc rr_loop
			; r_next:
			lda map_ind_reset
			clc
			adc #MAP_WIDTH_32
			sta map_ind_reset
			sta map_ind
			inc r
			lda r
			cmp #8
			bcc r_loop
		; nt_next:
		dec nt
		beq :++
		lda nt
		lsr
		bcc :+
			; map_ind_reset -= (MAP_WIDTH_8 * 7) - (8)
			lda map_ind_reset
			sec
			sbc #(MAP_WIDTH_32 * 8) - 8
			sta map_ind_reset
			sta map_ind
			jmp nt_loop
		:
			lda map_ind_reset
			sec
			sbc #8
			sta map_ind_reset
			sta map_ind
			jmp nt_loop
		:
	a8
	rts
	.endproc

.zeropage
	render_u_32: .res 2
	render_l_32: .res 2
	render_d_32: .res 2
	render_r_32: .res 2
	trigger_u_32: .res 2
	trigger_l_32: .res 2
	render_cont_metatile_ind: .res 2
	render_cont_ppu_addition: .res 2
	render_cont_pos_32: .res 2
	render_cont_ctr: .res 2
	
.code

.proc Render
	scroll_u_32		= local			; scroll_y >> 5
	scroll_l_32		= local + 2		; scroll_x >> 5
	scroll_d_32		= local + 4		; (scroll_y + 223) >> 5
	scroll_r_32		= local + 6		; (scroll_x + 255) >> 5
	trigger_r_32	= local + 12	; trigger_l_32 + 8
	trigger_d_32	= local + 14	; trigger_u_32 + 8

	a16
	lda render_cont_ctr
	beq new_line
		; just continue rendering current metatile row/column
		ldx render_cont_pos_32
		lda render_cont_metatile_ind
		and #(METATILE_NUM_TILES_ON_SIDE * 2) - 1
		bne cont_col
		; cont_row:
			txa
			jsr RenderRow
			add_zp render_cont_metatile_ind, #METATILE_NUM_TILES_ON_SIDE * 2
			add_zp render_cont_ppu_addition, #32
			bra cont_end
		cont_col:
			txa
			jsr RenderColumn
			inc render_cont_metatile_ind
			inc render_cont_metatile_ind
			inc render_cont_ppu_addition
		cont_end:
		dec render_cont_ctr
		a8
		rts
		.a16
	new_line:

	; set vars
		; scroll_u_32
			lda scroll_y+1
			tax
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta scroll_u_32
		; scroll_d_32
			txa
			clc
			adc #223
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta scroll_d_32
		; scroll_l_32
			lda scroll_x+1
			tax
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta scroll_l_32
		; scroll_r_32
			txa
			clc
			adc #255
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta scroll_r_32
		; trigger_r_32
			lda trigger_l_32
			clc
			adc #8
			sta trigger_r_32
		; trigger_d_32
			lda trigger_u_32
			clc
			adc #8
			sta trigger_d_32

	; scroll_l_32 < trigger_l_32?
	; l
		lda scroll_l_32
		cmp trigger_l_32
		bcs r
			stz render_cont_ppu_addition
			stz render_cont_metatile_ind
		; trigger_l_32--
			dec trigger_l_32
		; updateRenders()
			jsr UpdateRenderLines
		; render left column of tiles at render_l_32
			lda render_l_32
			jsr RenderColumn
		; render_cont_metatile_ind++
			inc render_cont_metatile_ind
			inc render_cont_metatile_ind
			lda render_l_32
			sta render_cont_pos_32
			lda #METATILE_NUM_TILES_ON_SIDE - 1
			sta render_cont_ctr
			inc render_cont_ppu_addition
		; exit
			a8
			rts
			.a16
	r:
	; scroll_r_32 > trigger_r_32?
		lda trigger_r_32
		cmp scroll_r_32
		bcs u
			stz render_cont_ppu_addition
			stz render_cont_metatile_ind
		; trigger_l_32++
			inc trigger_l_32
		; updateRenders()
			jsr UpdateRenderLines
		; render left column of tiles at render_r_32
			lda render_r_32
			jsr RenderColumn
		; render_cont_metatile_ind++
			inc render_cont_metatile_ind
			inc render_cont_metatile_ind
			lda render_r_32
			sta render_cont_pos_32
			lda #METATILE_NUM_TILES_ON_SIDE - 1
			sta render_cont_ctr
			inc render_cont_ppu_addition
		; exit
			a8
			rts
			.a16
	u:
	; scroll_u_32 < trigger_u_32?
		lda scroll_u_32
		cmp trigger_u_32
		bcs d
			stz render_cont_ppu_addition
			stz render_cont_metatile_ind
		; trigger_u_32--
			dec trigger_u_32
		; updateRenders()
			jsr UpdateRenderLines
		; render top row of tiles at render_u_32
			lda render_u_32
			jsr RenderRow
		; render_cont_metatile_ind = METATILE_NUM_TILES_ON_SIDE
			lda #METATILE_NUM_TILES_ON_SIDE - 1
			sta render_cont_ctr
			lda #METATILE_NUM_TILES_ON_SIDE * 2
			sta render_cont_metatile_ind
			lda render_u_32
			sta render_cont_pos_32
			add_zp render_cont_ppu_addition, #32
		; exit
			a8
			rts
			.a16
	d:
	; scroll_d_32 > trigger_d_32?
		lda trigger_d_32
		cmp scroll_d_32
		bcs end
			stz render_cont_ppu_addition
			stz render_cont_metatile_ind
		; trigger_u_32++
			inc trigger_u_32
		; updateRenderLines()
			jsr UpdateRenderLines
		; render top row of tiles at render_d_32
			lda render_d_32
			jsr RenderRow
		; render_cont_metatile_ind = METATILE_NUM_TILES_ON_SIDE
			lda #METATILE_NUM_TILES_ON_SIDE - 1
			sta render_cont_ctr
			lda #METATILE_NUM_TILES_ON_SIDE * 2
			sta render_cont_metatile_ind
			lda render_d_32
			sta render_cont_pos_32
			add_zp render_cont_ppu_addition, #32
		end:
		; exit
			a8
			rts
			.a16
	.endproc

; params:
	; a.16 - 32x32 tile X-position on map to start rendering
.proc RenderColumn
	render_x_32 = local
	ppu_addr = local + 2
	loop_ctr = local + 4
	wrap_len = local + 6
	top_map_ind = local + 8
	sta render_x_32
	; which nametable?
		; render_x_32 & %0000_0000__0000_1000 ? $2000 : $2400
		and #%00001000
		bne :+
			lda #0
			bra :++
		:
			lda #$0400
		:
		ora #$2000
		sta ppu_addr
		lda render_x_32
		and #8 - 1
		asl a
		asl a
		ora ppu_addr
		clc
		adc render_cont_ppu_addition
		ldx #0
		sta PPU_BUFF_ADDR, x
		sta ppu_addr
		lda #64
		sta PPU_BUFF_LEN, x
		a8
		lda #VMAIN_INC_32 | VMAIN_WORDINC
		sta PPU_BUFF_VMAIN, x
		a16
		lda #8
		sta loop_ctr
		; get map index
			a8
			mul8 render_u_32, #MAP_WIDTH_32
			a16
			clc
			adc render_x_32
			sta top_map_ind
			tay
		; wrap around index
			lda render_u_32
			and #16 - 1
			sta wrap_len
			beq loop
			a8
			lda #16
			sec
			sbc wrap_len
			xba
			lda #MAP_WIDTH_32
			jsr _mul
			a16
			clc
			adc top_map_ind
			tay
		loop:
			phy
			a8
			lda map, y
			xba
			lda #(METATILE_NUM_TILES_ON_SIDE * METATILE_NUM_TILES_ON_SIDE) * 2
			jsr _mul
			a16
			clc
			adc render_cont_metatile_ind
			tay
			; 1
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
			; 2
				add_y #METATILE_NUM_TILES_ON_SIDE * 2
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
			; 3
				add_y #METATILE_NUM_TILES_ON_SIDE * 2
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
			; 4
				add_y #METATILE_NUM_TILES_ON_SIDE * 2
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
			ply
			add_y #MAP_WIDTH_32
			; wrap around?
				lda wrap_len
				beq :+
					dec wrap_len
					bne :+
					lda top_map_ind
					tay
				:

			dec loop_ctr
			bne loop
		add_zp ppu_addr, #$0800
		cmp #$3000
		bcs end
		add_x #PPU_BUFF_DATA - PPU_BUFF
		lda #64
		sta PPU_BUFF_LEN, x
		lda ppu_addr
		sta PPU_BUFF_ADDR, x
		a8
		lda #VMAIN_INC_32 | VMAIN_WORDINC
		sta PPU_BUFF_VMAIN, x
		a16
		lda #8
		sta loop_ctr
		jmp loop
	end:
	rts
	.endproc

; params:
	; a.16 - 32x32 tile Y-position on map to start rendering
.proc RenderRow
	render_y_32 = local
	ppu_addr = local + 2
	loop_ctr = local + 4
	wrap_len = local + 6
	left_map_ind = local + 8
	sta render_y_32
	; which nametable?
		; render_y_32 & %0000_0000__0000_1000 ? $2000 : $2800
		and #%00001000
		bne :+
			lda #0
			bra :++
		:
			lda #$0800
		:
		ora #$2000
		sta ppu_addr
		lda render_y_32
		and #8 - 1
		asl a
		asl a
		asl a
		asl a
		asl a
		asl a
		asl a
		ora ppu_addr
		clc
		adc render_cont_ppu_addition
		ldx #0
		sta PPU_BUFF_ADDR, x
		sta ppu_addr
		lda #64
		sta PPU_BUFF_LEN, x
		a8
		lda #VMAIN_INC_1 | VMAIN_WORDINC
		sta PPU_BUFF_VMAIN, x
		a16
		lda #8
		sta loop_ctr
		a8
		mul8 render_y_32, #MAP_WIDTH_32
		a16
		; get map index
			clc
			adc render_l_32
			sta left_map_ind
			tay
		; wrap around index
			lda render_l_32
			and #16 - 1
			sta wrap_len
			beq loop
			lda #16
			sec
			sbc wrap_len
			clc
			adc left_map_ind
			tay
		loop:
			phy
			a8
			lda map, y
			xba
			lda #(METATILE_NUM_TILES_ON_SIDE * METATILE_NUM_TILES_ON_SIDE) * 2
			jsr _mul
			a16
			clc
			adc render_cont_metatile_ind
			tay
			; 1
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
				iny
				iny
			; 2
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
				iny
				iny
			; 3
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
				iny
				iny
			; 4
				lda metas, y
				sta PPU_BUFF_DATA, x
				inx
				inx
			ply
			iny
			; wrap around?
				lda wrap_len
				beq :+
					dec wrap_len
					bne :+
					lda left_map_ind
					tay
				:
			dec loop_ctr
			bne loop
		add_zp ppu_addr, #$0400
		and #$0400
		beq end
		add_x #PPU_BUFF_DATA - PPU_BUFF
		lda #64
		sta PPU_BUFF_LEN, x
		lda ppu_addr
		sta PPU_BUFF_ADDR, x
		a8
		lda #VMAIN_INC_1 | VMAIN_WORDINC
		sta PPU_BUFF_VMAIN, x
		a16
		lda #8
		sta loop_ctr
		bra loop
	end:
	rts
	.endproc

.proc UpdateRenderLines
	; rL = max(tL - 3, 0)
		lda trigger_l_32
		tax
		sec
		sbc #3
		bcs :+
			stz render_l_32
			bra :++
		:
			sta render_l_32	
		:
	; rR = min(tL + 11, MAP_WIDTH_32 - 1)
		txa
		clc
		adc #11
		cmp #MAP_WIDTH_32 - 1
		bcc :+
			lda #MAP_WIDTH_32 - 1
			sta render_r_32
			bra :++
		:
			sta render_r_32
		:
	; rU = max(tU - 3, 0)
		lda trigger_u_32
		tax
		sec
		sbc #3
		bcs :+
			stz render_u_32
			bra :++
		:
			sta render_u_32	
		:
	; rD = min(tU + 11, MAP_HEIGHT_32 - 1)
		txa
		clc
		adc #11
		cmp #MAP_HEIGHT_32 - 1
		bcc :+
			lda #MAP_HEIGHT_32 - 1
			sta render_d_32
			bra :++
		:
			sta render_d_32
		:
	rts
	.endproc

.endscope