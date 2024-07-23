.zeropage
	scroll_x:		.res 3
	scroll_y:		.res 3
	scroll_hspeed:	.res 2
	scroll_vspeed:	.res 2
.code

.scope scroll

SCROLL_ACCELERATION = $0028
SCROLL_DRAG			= $0010
SCROLL_MAXSPEED		= $0300
MAX_SCROLL_X = (MAP_WIDTH_32 * 32) - 256
MAX_SCROLL_Y = (MAP_HEIGHT_32 * 32) - 224
.proc Update
	abs_speed = local
	a16
	; ud
		; u:
			lda JOY1L
			bit #JOY_U
			beq d
				sub_zp scroll_vspeed, #SCROLL_ACCELERATION
				bpl l
				cmp #.loword(-SCROLL_MAXSPEED)
				bcs l
				lda #.loword(-SCROLL_MAXSPEED)
				sta scroll_vspeed
				bra l
		d:
			bit #JOY_D
			beq ud_no
				add_zp scroll_vspeed, #SCROLL_ACCELERATION
				bmi l
				cmp #SCROLL_MAXSPEED
				bcc l
				lda #SCROLL_MAXSPEED
				sta scroll_vspeed
				bra l
		ud_no:
			lda scroll_vspeed
			beq l
			bmi ud_no_inc
			; ud_no_dec:
				sec
				sbc #SCROLL_DRAG
				bcs :+
					lda #0
				:
				sta scroll_vspeed
				bra l
			ud_no_inc:
				clc
				adc #SCROLL_DRAG
				bcc :+
					lda #0
				:
				sta scroll_vspeed
	; lr
		l:
			lda JOY1L
			bit #JOY_L
			beq r
				sub_zp scroll_hspeed, #SCROLL_ACCELERATION
				bpl apply
				cmp #.loword(-SCROLL_MAXSPEED)
				bcs apply
				lda #.loword(-SCROLL_MAXSPEED)
				sta scroll_hspeed
				bra apply
		r:
			bit #JOY_R
			beq lr_no
				add_zp scroll_hspeed, #SCROLL_ACCELERATION
				bmi apply
				cmp #SCROLL_MAXSPEED
				bcc apply
				lda #SCROLL_MAXSPEED
				sta scroll_hspeed
				bra apply
		lr_no:
			lda scroll_hspeed
			beq apply
			bmi lr_no_inc
			; lr_no_dec:
				sec
				sbc #SCROLL_DRAG
				bcs :+
					lda #0
				:
				sta scroll_hspeed
				bra apply
			lr_no_inc:
				clc
				adc #SCROLL_DRAG
				bcc :+
					lda #0
				:
				sta scroll_hspeed
	apply:
		; v:
			lda scroll_vspeed
			bmi v_neg
			; v_pos:
				clc
				adc scroll_y
				sta scroll_y
				a8
				lda scroll_y+2
				adc #0
				sta scroll_y+2
				a16
				bra h
			v_neg:
				invert_a
				sta abs_speed
				sub_zp scroll_y, abs_speed
				a8
				lda scroll_y+2
				sbc #0
				sta scroll_y+2
				a16
		h:
			lda scroll_hspeed
			bmi h_neg
			; h_pos:
				clc
				adc scroll_x
				sta scroll_x
				a8
				lda scroll_x+2
				adc #0
				sta scroll_x+2
				a16
				bra border_check
			h_neg:
				invert_a
				sta abs_speed
				sub_zp scroll_x, abs_speed
				a8
				lda scroll_x+2
				sbc #0
				sta scroll_x+2
				a16
		border_check:
			; border_check_x
				lda scroll_x+1
				bpl :+
					stz scroll_x+1
					stz scroll_hspeed
					bra border_check_y
				:
				cmp #MAX_SCROLL_X
				bcc :+
					lda #MAX_SCROLL_X
					sta scroll_x+1
					stz scroll_hspeed
				:
			border_check_y:
				lda scroll_y+1
				bpl :+
					stz scroll_y+1
					stz scroll_vspeed
					bra end
				:
				cmp #MAX_SCROLL_Y
				bcc :+
					lda #MAX_SCROLL_Y
					sta scroll_y+1
					stz scroll_vspeed
				:
		end:
		a8
		rts
	.endproc

.endscope