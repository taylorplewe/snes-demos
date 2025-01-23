;music code for snesgss
;written by Shiru
;modified to work with ca65 by Doug Fraker 2020-2021
;streaming audio has been removed and
;the spc code has been patched to fix a bug - and add echo
;now called snesgssQ.exe -

;version 5
;update 11/2021
;added SPC_All_Echo to set all echo parameters
;using a single table of values


LOROM = 1
;set to zero, if HIROM


.p816
.smart

.global SPC_Init, SPC_Load_Data, SPC_Play_Song, SPC_Command_ASM
.global SPC_Stereo, SPC_Global_Volume, SPC_Channel_Volume, Music_Stop
.global Music_Pause, Sound_Stop_All, SFX_Play, SFX_Play_Center
.global SFX_Play_Left, SFX_Play_Right

.global Echo_Vol, Echo_Addr, Echo_Fb_Fir, SPC_All_Echo

;notes
;cmdStereo, param 8 bit, 0 or 1
;cmdGlobalVolume, param L = vol 0-127, H = how quickly volume fades, 1-255
;cmdChannelVolume, param L = vol 0-127, H = which channel (bit field)*
;cmdMusicPlay, no param
;cmdStopAllSounds, no param
;cmdMusicStop, no param
;cmdMusicPause, param 8 bit, 0 or 1
;cmdSfxPlay, 4 params, vol 0-127, sfx #, pan, channel 0-7
;cmdLoad, params= apu address, size, src address
;stream, removed.

;*bitfield for channel volume, if channel volume command will set
; a max volume for a specific channel
;0000 0001 channel 1
;0000 0010 channel 2
;0000 0100 channel 3
;0000 1000 channel 4
;0001 0000 channel 5
;0010 0000 channel 6
;0100 0000 channel 7
;1000 0000 channel 8


.define FULL_VOL   127
.define PAN_CENTER 128
.define PAN_LEFT   0
.define PAN_RIGHT  255

;to send a command
;although 8 bit values, A should be 16 bit when you
;lda #SCMD_INITIALIZE
.define SCMD_NONE				$00
.define SCMD_INITIALIZE			$01
.define SCMD_LOAD				$02
.define SCMD_STEREO				$03
.define SCMD_GLOBAL_VOLUME		$04
.define SCMD_CHANNEL_VOLUME		$05
.define SCMD_MUSIC_PLAY 		$06
.define SCMD_MUSIC_STOP 		$07
.define SCMD_MUSIC_PAUSE 		$08
.define SCMD_SFX_PLAY			$09
.define SCMD_STOP_ALL_SOUNDS	$0a
;.define SCMD_STREAM_START		$0b
;.define SCMD_STREAM_STOP		$0c
;.define SCMD_STREAM_SEND		$0d
.define SCMD_ECHO_VOL			$0b
.define SCMD_ECHO_ADDR			$0c
.define SCMD_ECHO_FB_FIR		$0d



.zeropage

spc_temp:			.res 2
gss_param:			.res 2
gss_command:		.res 2
save_stack:			.res 2
spc_pointer:		.res 4
spc_music_load_adr:	.res 2
echo_pointer:		.res 4


.segment "BANK2"
spc700:
	.incbin "spc700.bin", 0, $8000
.segment "BANK3"
	.incbin "spc700.bin", $8000
jeux:
	.incbin "music_1.bin"
.code


;notes:
; code loads to $200
; stereo, 0 is off (mono), 1 is on;
; volume 127 = max
; pan 128 = center
; music_1.bin is song 1
; and spc700.bin is the code and brr samples
; sounds.h and sounds.asm are only useful in that
; they tell you the number value of each song
; and sfx. they are meant for tools other than ca65



;nmi should be disabled
;axy16
;lda # address of spc700.bin
;ldx # bank of spc700.bin
;jsl SPC_Init

SPC_Init:

;note, first 2 bytes of bin are size
;increment the data address by 2

	php
	a16
	i16
	sta spc_pointer ;address of music code
	stx spc_pointer+2 ;bank of music code
	
	tsx
	stx save_stack
	ldy #14 ;bytes 14-15 is the address to load the song
	lda [spc_pointer], y ;address to load the song
	sta spc_music_load_adr ;save for later
	
	lda spc_pointer+2 ;bank of music code
	pha
	lda spc_pointer ;address of music code
	inc a
	inc a ;actual code is address +2
	pha
	lda [spc_pointer] ;1st 2 bytes are the size
	pha
	lda #$0200 ;address in apu
	pha
	jsl SPC_Load_Data
	ldx save_stack
	txs ;8
	
	lda #SCMD_INITIALIZE
	sta gss_command
	stz gss_param
;	jsl SPC_Command_ASM
;	;default is mono
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
	
	

	
	

;stack relative
;5 = addr in apu, last pha
;7 = size
;9 = src l
;11 = src h

SPC_Load_Data:

	php
	a16
	i16
	
	sei
; make sure no irq's fire during this transfer

	a8
	lda #$aa
@1:
	cmp APUIO0
	bne @1

	a16
	lda 11,s				;src h
	sta spc_pointer+2
	lda 9,s					;src l
	sta spc_pointer+0
	lda 7,s					;size
	tax
	lda 5,s					;adr
	sta APUIO2
	
	a8
	lda #$01
	sta APUIO1
	lda #$cc
	sta APUIO0
	
@2:
	cmp APUIO0
	bne @2
	
	ldy #0
	
@load_loop:
;a8
;	xba ;unneccessary
	lda [spc_pointer] ;,y
	xba
	tya
	
	a16
	sta APUIO0
	a8
	
@3:
	cmp APUIO0
	bne @3
	
	iny
	a16
	inc spc_pointer
	bne @6
	inc spc_pointer+2
	
.if LOROM = 1	
	lda #$8000
	sta spc_pointer
	
.endif	
@6:	
	a8
	dex
	bne @load_loop
	
	xba
    lda #$00
    xba
	clc
	adc #$02
	a16
	tax
	
	lda #$0200			;loaded code starting address
	sta APUIO2

	txa
	sta APUIO0
	a8
	
@4:
	cmp APUIO0
	bne @4
	
	a16
@5:
	lda APUIO0			;wait until SPC700 clears all communication ports, confirming that code has started
	ora APUIO2
	bne @5
	
;	cli					;enable IRQ
;this is covered with the plp
	plp
	rtl



	
;nmi should be disabled
;axy16
;lda # address of song
;ldx # bank of song
;jsl SPC_Play_Song

;1st 2 bytes of song are size, then song+2 is address of song data

SPC_Play_Song:

	php
	a16
	i16
	sta spc_pointer
	stx spc_pointer+2
	
	jsl Music_Stop
	
	lda #SCMD_LOAD
	sta gss_command
	stz gss_param
	jsl SPC_Command_ASM
	
	a16
	i16
	tsx
	stx save_stack
	lda spc_pointer+2;#^music_code ; bank
	pha
	lda spc_pointer;#.loword(music_code)
	inc a
	inc a ;actual data at data+2
	pha
	lda [spc_pointer] ;first 2 bytes of data are size
	pha
;saved at init	
	lda spc_music_load_adr ;address in apu
	pha
	jsl SPC_Load_Data
	ldx save_stack
	txs ;8

	stz gss_param ;zero
	lda #SCMD_MUSIC_PLAY
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;send a command to the SPC driver	
;a16
;lda #command
;sta gss_command
;lda #parameter
;sta gss_param
;jsl SPC_Command_ASM

SPC_Command_ASM:

	php
	a8
@1:
	lda APUIO0
	bne @1

	a16
	lda gss_param
	sta APUIO2
	lda gss_command
	a8
	xba
	sta APUIO1
	xba
	sta APUIO0

	cmp #SCMD_LOAD	;don't wait acknowledge
	beq @3

@2:
	lda APUIO0
	beq @2

@3:
	plp
	rtl

	

;void SPC_Stereo(unsigned int stereo);
;a8 or a16
;lda #0 (mono) or 1 (stereo)
;jsl SPC_Stereo

SPC_Stereo:

	php
	a16
	i16
	and #$00ff
	sta gss_param
	
	lda #SCMD_STEREO
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;void SPC_Global_Volume(unsigned int volume,unsigned int speed);
;axy8 or axy16
;lda #speed, how quickly the volume fades, 1-255*
;ldx #volume, 0-127
;jsl SPC_Global_Volume

;*255 is default = instant (any value >= 127 is instant)
;speed = 7 is about 2 seconds, and is a medium fade in/out

SPC_Global_Volume:

	php
	a16
	i16	
	xba
	and #$ff00 ;speed
	sta gss_param
	txa
	and #$00ff ;volume
	ora gss_param
	sta gss_param
	
	lda #SCMD_GLOBAL_VOLUME
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;void SPC_Channel_Volume(unsigned int channels,unsigned int volume);
;axy8 or axy16
;lda #channels (bit field), see above
;ldx #volume   0-127
;jsl SPC_Channel_Volume

SPC_Channel_Volume:

	php
	a16
	i16
	xba
	and #$ff00 ;channel
	sta gss_param
	txa
	and #$00ff ;volume
	ora gss_param
	sta gss_param
	
	lda #SCMD_CHANNEL_VOLUME
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;void Music_Stop(void);
;jsl Music_Stop

Music_Stop:

	php
	a16
	i16
	
	lda #SCMD_MUSIC_STOP
	sta gss_command
	stz gss_param
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	

	
;void Music_Pause(unsigned int pause);
;a8 or a16
;lda #0 (unpause) or 1 (pause)
;jsl Music_Pause

Music_Pause:

	php
	a16
	i16
	and #$00ff
	sta gss_param
	
	lda #SCMD_MUSIC_PAUSE
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
;void Sound_Stop_All(void);
;jsl Sound_Stop_All

Sound_Stop_All:

	php
	a16
	i16
	
	lda #SCMD_STOP_ALL_SOUNDS
	sta gss_command
	stz gss_param
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
SFX_Play_Center:
;axy8 or axy16
;in a= sfx #
;	x= volume 0-127
;	y= sfx channel 0-7, needs to be > than max song channel
;pan center

	php
	a8
	i8
	sta spc_temp
	stx spc_temp+1
	
	a16
	i16
	tsx
	stx save_stack
	
	lda #128 ;pan center
	pha
SFX_Play_common:
	lda spc_temp+1 ;volume 0-127
	and #$00ff
	pha
	lda spc_temp ;sfx #
	and #$00ff
	pha
	tya ;channel, needs to be > the song channels
	and #$0007
	pha
	jsl SFX_Play
	ldx save_stack
	txs
	plp
	rtl

	
	
SFX_Play_Left:
;axy8 or axy16
;in a= sfx #
;	x= volume 0-127
;	y= sfx channel 0-7, needs to be > than max song channel
;pan left

	php
	a8
	i8
	sta spc_temp
	stx spc_temp+1
	
	a16
	i16
	tsx
	stx save_stack
	
	lda #0 ;pan left
	pha
	jmp	SFX_Play_common
	

	
SFX_Play_Right:
;axy8 or axy16
;in a= sfx #
;	x= volume 0-127
;	y= sfx channel 0-7, needs to be > than max song channel
;pan right

	php
	a8
	i8
	sta spc_temp
	stx spc_temp+1
	
	a16
	i16
	tsx
	stx save_stack
	
	lda #255 ;pan right
	pha
	jmp	SFX_Play_common	



	
;void SFX_Play(unsigned int chn,unsigned int sfx,unsigned int vol,int pan);
;stack relative
;5 = chn last in
;7 = volume
;9 = sfx
;11 = pan
;NOTE - use the other functions above

SFX_Play:

	php
	a16
	i16

	lda 11,s			;pan
	bpl @1
	lda #0
@1:
	cmp #255
	bcc @2
	lda #255
@2:

	xba
	and #$ff00
	sta gss_param
	
	lda 7,s				;sfx number
	and #$00ff
	ora gss_param
	sta gss_param

	lda 9,s				;volume
	xba
	and #$ff00
	sta gss_command

	lda 5,s				;chn
	asl a
	asl a
	asl a
	asl a
	and #$0070
	ora #SCMD_SFX_PLAY
	ora gss_command
	sta gss_command

;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End






;void SPC_Stream_Update(void);

SPC_Stream_Update:

; streaming functions have been removed



;adding some echo functions - doug fraker 2021

;axy8 or axy16
;lda #echo volume 0-$7f or ($80-ff negative), (0 = off) 
;ldx #which channels on? (bit field, each bit = a channel)
;jsl Echo_Vol
Echo_Vol:
	php
	a16
	i16
	and #$00ff ;***** changed v5
	sta spc_temp
	txa
	and #$00ff ;which channels
	xba
	ora spc_temp
	sta gss_param
	lda #SCMD_ECHO_VOL
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	



;axy8 or axy16
;lda #echo start address highbyte
;ldx #echo delay (0-$f), should be 0-5
;jsl Echo_Addr

; this is very important! echo vol must be off before changing this
; echo address needs to be > the last spc file byte
; delay is $800 bytes x val, and needs to be small enough
; to fit in the remaining RAM space (and shouldn't use
; that last $800 since it's part of the boot loader ROM)
; Note: a delay of 0 does actually function as a VERY short 
; echo delay, but probably won't sound very good.

Echo_Addr:
	php
	a16
	i16
	and #$00ff
	sta spc_temp
	txa
	and #$00ff
	xba
	ora spc_temp
	sta gss_param
	lda #SCMD_ECHO_ADDR
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
;axy8 or axy16
;lda #FIR filter settings (0-3)
;  0 = simple echo
;  1 = multi tap echo
;  2 = low pass echo
;  3 = high pass echo
;ldx #echo feedback volume (0-$7f) or ($80-ff negative)
;jsl Echo_Fb_Fir	
Echo_Fb_Fir:
	php
	a16
	i16
	and #$0003 ;fir
	sta spc_temp
	txa
	and #$00ff ;***** changed v5
	xba
	ora spc_temp
	sta gss_param
	lda #SCMD_ECHO_FB_FIR
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
;	jmp SPC_Common_End --- fall through ---
	
	
	
SPC_Common_End:
	jsl SPC_Command_ASM
	plp
	rtl
	
	
;sets all the echo functions AND global volume
;output from Echo4GSS is a 14 byte array
;
;1 = which channels have echo enabled
;2 = echo start address
;3 = echo size / delay
;4 = echo volume
;5 = echo feedback
;6-13 = FIR filter values
;14 = global (main) volume

;axy16
;lda # address of echo data
;ldx # bank of echo data
;jsl SPC_All_Echo

SPC_All_Echo:
	php
	a16
	i16
	sta echo_pointer ;pointer to the data
	stx echo_pointer+2 ;bank
	
	jsl Sound_Stop_All
	
;first send the FIR, overwrite FIR set #0
;	axy16
	lda #SCMD_LOAD
	sta gss_command
	stz gss_param
	jsl SPC_Command_ASM
	tsx
	stx save_stack
;	lda #^TEST_FIR ;source bank
	lda echo_pointer+2
	pha
;	lda #.loword(TEST_FIR) ;source address
	lda echo_pointer
	clc
	adc #5
	pha
	lda #8 ;size
	pha
	lda #$03aa ;SPC address to patch (= the FIR table)
	pha
	jsl SPC_Load_Data
	ldx save_stack
	txs

	a8
	i8
	ldy #4
	lda [echo_pointer], y ;echo feedback
	tax
	lda #0 ;FIR Set 0
	jsl Echo_Fb_Fir	
	
	lda #0 ;echo volume 0 before we change
	tax    ;the echo start address
	jsl Echo_Vol

	ldy #2 
	lda [echo_pointer], y ;size / delay
	and #$0f ;should be 0-f
	tax
	dey ;y = 1
	lda [echo_pointer], y ;start address
	jsl Echo_Addr
	
	ldy #13
	lda [echo_pointer], y ;global volume
	tax ;right away
	jsl SPC_Global_Volume
	
	lda [echo_pointer] ;which echo channels active
	tax 
	ldy #3
	lda [echo_pointer], y ;echo volume
	jsl Echo_Vol
	
	plp
	rtl

; reset for files that come after
.a8
.i16