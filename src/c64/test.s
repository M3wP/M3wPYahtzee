;	TODO:
;		- Cursor when editing text
;		- Update user name button
;
;		- Optimise log panel presentation
;		- Optimise 1 height controls presentation?
;
;
;	LIMITATIONS:
;		- Making controls invisible requires some effort to redisplay 
;		  properly
;		- Beware overlapping controls
;
;
;	BUGS:
;		- In VICE, doing a reset while successfully connected results in a 
;		  zombie client (the socket is not closed).  I believe the problem is
;		  in VICE and will eventually have a work-around when I implement
;		  idle time limitations in the server.
;
;

	.include "../inc/common.inc"
	.include "../inc/net.inc"
	.include "../inc/error.inc"

	.import ip65_error
	.import eth_driver_name
	.import eth_driver_io_base
	.import cfg_ip

;	.import abort_key
;	.importzp abort_key_default
;	.importzp abort_key_disable

	.import drv_init
	.importzp drv_init_default
	.import dns_hostname_is_dotted_quad
	.import dns_ip
	.import dns_resolve
	.import dns_set_hostname
	.import ip65_init
	.import ip65_process
	.import dhcp_init
	.import tcp_callback
	.import tcp_close
	.import tcp_connect
	.import tcp_connect_ip
	.import tcp_inbound_data_ptr
	.import tcp_inbound_data_length
	.import tcp_send
	.import tcp_send_data_len
	.import tcp_send_keep_alive
	.import timer_read

	.export	check_for_abort_key


	.define	DEBUG_RASTERTIME	0
	.define	DEBUG_MSGSPUSHSZ	1


cpuIRQ		=	$FFFE
cpuRESET	=	$FFFC
cpuNMI		=	$FFFA

krnlOutChr	= 	$E716

CIA1_PRA        = 	$DC00        		; Port A
CIA1_PRB	=	$DC01
CIA1_DDRA	=	$DC02
CIA1_DDRB	=	$DC03
cia1IRQCtl	=	$DC0D

VIC     	= 	$D000         		; VIC REGISTERS
VICXPOS0    	= 	VIC + $00      		; LOW ORDER X POSITION
VICYPOS0    	= 	VIC + $01      		; Y POSITION
VICXPOS1    	= 	VIC + $02      		; LOW ORDER X POSITION
VICYPOS1    	= 	VIC + $03      		; Y POSITION
VICXPOS2    	= 	VIC + $04      		; LOW ORDER X POSITION
VICYPOS2    	= 	VIC + $05      		; Y POSITION
VICXPOS3    	= 	VIC + $06      		; LOW ORDER X POSITION
VICYPOS3    	= 	VIC + $07      		; Y POSITION
VICXPOSMSB 	=	VIC + $10      		; BIT 0 IS HIGH ORDER X POS
vicCtrlReg	=	$D011
vicRstrVal	=	$D012
vicSprEnab	= 	$D015
vicSprExpY	=	$D017
vicMemCtrl	=	$D018
vicIRQFlgs	=	$D019
vicIRQMask	=	$D01A
vicSprCMod	= 	$D01C
vicSprExpX	= 	$D01D
vicBrdrClr	=	$D020
vicBkgdClr	= 	$D021
vicSprMCl0	= 	$D025
vicSprMCl1	= 	$D026
vicSprClr0	= 	$D027
vicSprClr1	= 	$D028
vicSprClr2	= 	$D029
vicSprClr3	= 	$D02A

SID     	= 	$D400         		; SID REGISTERS
SID_ADConv1    	= 	SID + $19
SID_ADConv2    	= 	SID + $1A

keyModNone	=	$00
keyModShift	=	$01
keyModSystem	=	$02
keyModControl	=	$04

buttonLeft	=	$10
buttonRight	=	$01

spriteMem20	= 	$0800

spritePtr0	=	$07F8
spritePtr1	=	$07F9
spritePtr2	=	$07FA
spritePtr3	=	$07FB

offsX		=	24
offsY		=	50

	.define MSG_CATG_SYST	$00
	.define MSG_CATG_TEXT	$10
	.define MSG_CATG_LOBY	$20
	.define MSG_CATG_CNCT	$30
	.define MSG_CATG_CLNT	$40
	.define MSG_CATG_SRVR	$50
	.define MSG_CATG_PLAY	$60


	.define	INET_PROC_IDLE	$00
	.define INET_PROC_HALT	$01
	.define INET_PROC_INIT	$02
	.define INET_PROC_CNCT	$03
	.define INET_PROC_EXEC	$04
	.define INET_PROC_DISC	$05
	.define INET_PROC_PCNT	$06
	.define INET_PROC_DSCD	$07

	.define	INET_STATE_NORM	$00
	.define INET_STATE_ERR	$01
	.define INET_STATE_TICK $02
	
	.define INET_ERR_NONE	$00
	.define INET_ERR_INTRF	$01
	.define INET_ERR_INTRN	$02

	.define INET_ERROR_NONE $00
	.define INET_ERROR_INIT $01
	.define	INET_ERROR_CNCT	$02
	.define INET_ERROR_DISC	$03


	.define	KEY_ASC_BKSPC	$08
	.define KEY_ASC_CR	$0D

	.define KEY_ASC_SPACE	$20
	.define KEY_ASC_EXMRK	$21
	.define KEY_ASC_DQUOTE	$22
	.define KEY_ASC_POUND	$23
	.define KEY_ASC_HASH	$23		;Alternate
	.define KEY_ASC_DOLLAR	$24
	.define KEY_ASC_PERCENT	$25
	.define KEY_ASC_AMP 	$26
	.define KEY_ASC_QUOTE	$27
	.define KEY_ASC_OBRCKT 	$28
	.define KEY_ASC_LBRCKT 	$28		;Alternate
	.define	KEY_ASC_CBRCKT	$29
	.define	KEY_ASC_RBRCKT	$29		;Alternate
	.define KEY_ASC_MULT	$2A
	.define KEY_ASC_PLUS	$2B
	.define KEY_ASC_COMMA	$2C
	.define KEY_ASC_MINUS	$2D
	.define KEY_ASC_STOP	$2E
	.define KEY_ASC_DIV	$2F
	.define KEY_ASC_FSLASH	$2F		;Alternate
	.define KEY_ASC_0	$30
	.define KEY_ASC_1	$31
	.define KEY_ASC_2	$32
	.define KEY_ASC_3	$33
	.define KEY_ASC_4	$34
	.define KEY_ASC_5	$35
	.define KEY_ASC_6	$36
	.define KEY_ASC_7	$37
	.define KEY_ASC_8	$38
	.define KEY_ASC_9	$39
	.define KEY_ASC_COLON	$3A
	.define KEY_ASC_SCOLON	$3B
	.define KEY_ASC_LESSTH	$3C
	.define KEY_ASC_EQUALS	$3D
	.define	KEY_ASC_GRTRTH	$3E
	.define KEY_ASC_QMARK	$3F
	.define KEY_ASC_AT	$40
	.define KEY_ASC_A	$41
	.define KEY_ASC_B	$42
	.define KEY_ASC_C	$43
	.define KEY_ASC_D	$44
	.define KEY_ASC_E	$45
	.define KEY_ASC_F	$46
	.define KEY_ASC_G	$47
	.define KEY_ASC_H	$48
	.define KEY_ASC_I	$49
	.define KEY_ASC_J	$4A
	.define KEY_ASC_K	$4B
	.define KEY_ASC_L	$4C
	.define KEY_ASC_M	$4D
	.define KEY_ASC_N	$4E
	.define KEY_ASC_O	$4F
	.define KEY_ASC_P	$50
	.define KEY_ASC_Q	$51
	.define KEY_ASC_R	$52
	.define KEY_ASC_S	$53
	.define KEY_ASC_T	$54
	.define KEY_ASC_U	$55
	.define KEY_ASC_V	$56
	.define KEY_ASC_W	$57
	.define	KEY_ASC_X	$58
	.define KEY_ASC_Y	$59
	.define	KEY_ASC_Z	$5A
	.define	KEY_ASC_OSQRBR	$5B
	.define	KEY_ASC_LSQRBR	$5B		;Alternate
	.define KEY_ASC_BSLASH	$5C		;!!Needs screen code xlat
	.define KEY_ASC_CSQRBR	$5D
	.define KEY_ASC_RSQRBR	$5D		;Alternate
	.define KEY_ASC_CARET	$5E		;!!Needs screen code xlat
	.define KEY_ASC_USCORE	$5F		;!!Needs screen code xlat
	.define KEY_ASC_BQUOTE	$60		;!!Needs screen code xlat. !!Not C64
	.define KEY_ASC_L_A	$61
	.define KEY_ASC_L_B	$62
	.define KEY_ASC_L_C	$63
	.define KEY_ASC_L_D	$64
	.define KEY_ASC_L_E	$65
	.define KEY_ASC_L_F	$66
	.define KEY_ASC_L_G	$67
	.define KEY_ASC_L_H	$68
	.define KEY_ASC_L_I	$69
	.define KEY_ASC_L_J	$6A
	.define KEY_ASC_L_K	$6B
	.define KEY_ASC_L_L	$6C
	.define KEY_ASC_L_M	$6D
	.define KEY_ASC_L_N	$6E
	.define KEY_ASC_L_O	$6F
	.define KEY_ASC_L_P	$70
	.define KEY_ASC_L_Q	$71
	.define KEY_ASC_L_R	$72
	.define KEY_ASC_L_S	$73
	.define KEY_ASC_L_T	$74
	.define KEY_ASC_L_U	$75
	.define KEY_ASC_L_V	$76
	.define KEY_ASC_L_W	$77
	.define	KEY_ASC_L_X	$78
	.define KEY_ASC_L_Y	$79
	.define	KEY_ASC_L_Z	$7A
	.define KEY_ASC_OCRLYB	$7B		;!!Needs screen code xlat. !!Not C64
	.define KEY_ASC_LCRLYB	$7B		;Alternate
	.define KEY_ASC_PIPE	$7C		;!!Needs screen code xlat
	.define KEY_ASC_CCRLYB	$7D		;!!Needs screen code xlat. !!Not C64
	.define KEY_ASC_RCRLYB	$7D		;Alternate
	.define KEY_ASC_TILDE	$7E		;!!Needs screen code xlat

	.define KEY_C64_SHIFT	$01		;Used twice.  Be nice to id l/r
	.define KEY_C64_SYS	$02
	.define KEY_C64_STOP	$03	
	.define KEY_C64_CTRL	$04
	.define	KEY_C64_CRIGHT 	$1D		;Could be ascii tab? $09
	.define	KEY_C64_CDOWN 	$11		;Could be ascii line feed? $0A
	.define KEY_C64_HOME	$13
	.define KEY_C64_POUND	$5C
	.define KEY_C64_ARRUP	$5E
	.define KEY_C64_ARRLEFT	$5F
	.define KEY_C64_SHSTOP	$83
	.define	KEY_C64_F1 	$85
	.define	KEY_C64_F3 	$86
	.define	KEY_C64_F5 	$87
	.define	KEY_C64_F7 	$88
	.define KEY_C64_F2	$89
	.define KEY_C64_F4	$8A
	.define KEY_C64_F6	$8B
	.define KEY_C64_F8	$8C
	.define KEY_C64_SHRET	$8D		;Not mapped
	.define KEY_C64_CUP	$91
	.define KEY_C64_CLEAR	$93
	.define KEY_C64_INS	$94		;Could be ascii shift in? $0F
	.define KEY_C64_CLEFT	$9D		

	.define KEY_C64_INVALID	$FF


	.define	CLR_BACK	$FD
	.define	CLR_BORDER	$FE
	.define	CLR_CURSOR	$FF
	.define	CLR_TEXT	$00
	.define	CLR_FOCUS	$01
	.define	CLR_INSET	$02
	.define	CLR_FACE	$03
	.define CLR_SHADOW	$04
	.define CLR_PAPER	$05
	.define CLR_MONEY	$06
	.define CLR_DICE	$07
	.define CLR_SPEC_TEXT	$10
	.define CLR_SPEC_CTRL	$20

;	.define TYPE_ELEMENT	$00
;	.define TYPE_PAGE	$10
;	.define TYPE_PANEL	$20
;	.define TYPE_TABPANEL	TYPE_PANEL | $01
;	.define TYPE_CONTROL	$30
;	.define TYPE_LABEL	TYPE_CONTROL | $01

	.define STATE_CHANGED	$80
	.define STATE_DIRTY	$40
	.define STATE_PRESENTED	$20		;For optimisations
	.define STATE_VISIBLE	$01
	.define STATE_ENABLED	$02
	.define STATE_PICK	$04
	.define STATE_ACTIVE	$08
	.define STATE_DOWN	$10

	.define	OPT_NOPRESENT	$01
	.define	OPT_NONAVIGATE	$02
	.define OPT_NODOWNACTV	$04
	.define OPT_DOWNCAPTURE $10
	.define	OPT_AUTOCHECK	$20
	.define OPT_TEXTACCEL2X	$40
	.define OPT_TEXTCONTMRK $80


	.struct	ELEMENT
		prepare	.word
		present	.word
		changed .word
		keypress .word
;		type	.byte
		state	.byte
		options	.byte
		colour	.byte
		posx	.byte
		posy	.byte
		width	.byte
		height	.byte
		tag	.byte
	.endstruct
	
	.struct PAGE
		_element .tag ELEMENT
		textptr	.word
		testoffx .byte
		panels	.word
		panlcnt	.byte
	.endstruct

	.struct	PANEL
		_element .tag ELEMENT
		page	.word
		controls .word
		ctrlcnt	.byte
	.endstruct

	.struct	TABPANEL
		_panel	.tag PANEL
		page	.word
	.endstruct

	.struct	LOGPANEL
		_panel	.tag	PANEL
		lines	.word
		currln	.byte
	.endstruct
	
	.struct	CONTROL
		_element .tag ELEMENT
		panel	.word
		textptr	.word
		textoffx .byte
		textaccel .byte
		accelchar .byte
	.endstruct

	.struct LABELCTRL
		_control .tag CONTROL
		actvctrl .word
	.endstruct

	.struct	EDITCTRL
		_control .tag	CONTROL
		textsiz  .byte
		textmaxsz .byte
	.endstruct


	.exportzp inetproc

;===============================================================================
	.segment  "ZEROPAGE": zeropage
;===============================================================================
pageptr0:
			.res	2
panlptr0:
			.res	2
elemptr0:
			.res	2
ctrlptr0:
			.res	2
ctrlptr1:
			.res	2
tempptr0:		
			.res 	2
tempptr1:		
			.res 	2
tempptr2:		
			.res 	2
tempdat0:
			.res	1
tempdat1:
			.res	1
tempdat2:
			.res 	1
tempdat3:
			.res	1
tempbit0:
			.res	1
msgsptr0:
			.res	2
msgsdat0:
			.res	1
msgsdat1:
			.res	1
senddat0:
			.res	1
sendptr0:
			.res	2
pickCtrl:
			.res	2
downCtrl:
			.res	2
actvCtrl:
			.res	2

inetproc:
			.res	1
inetstat:
			.res	1
ineterrk:
			.res	1
ineterrc:
			.res	1
inetread:
			.res	2

keyZPKeyDown:
			.res	1
keyZPKeyCount:
			.res	1
keyZPKeyScan:
			.res	1
keyZPDecodePtr:
			.res	2
keyZPAbort:
			.res	1
;===============================================================================


;===============================================================================
	.segment 	"STARTUP"
;===============================================================================
;		Ends up at $080D
		JMP 	main
		
;		* = $0810
		.byte	           %10000000, %00000000
		.byte	%01010000, %01000000, %00000000
		.byte	%01101000, %00100000, %00000000
		.byte	%01000100, %01000000, %00000000
		.byte	%00000010, %10000000, %00000000
		.byte	%00000001, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	$00
		
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00111110, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000010, %00000000, %00000000
		.byte	%00000001, %00000000, %00000000
		.byte	%00000000, %10000000, %00000000
		.byte	%00000000, %01000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	$00
		
		.byte	%11111111, %11000000, %00000000
		.byte	%10000000, %01000000, %00000000
		.byte	%10000000, %10000000, %00000000
		.byte	%10100001, %00000000, %00000000
		.byte	%10100000, %10000000, %00000000
		.byte	%10100000, %01000000, %00000000
		.byte	%10101000, %00100000, %00000000
		.byte	%10010100, %01010000, %00000000
		.byte	%10101010, %10100000, %00000000
		.byte	%11000101, %01000000, %00000000
		.byte	%00000010, %10000000, %00000000
		.byte	%00000001, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	$00

		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00011100, %00000000, %00000000
		.byte	%00011100, %00000000, %00000000
		.byte	%00011110, %00000000, %00000000
		.byte	%00000111, %00000000, %00000000
		.byte	%00000011, %10000000, %00000000
		.byte	%00000001, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	$00

;===============================================================================

;===============================================================================
	.segment	"CODE"
;===============================================================================
;-------------------------------------------------------------------------------
;Input driver variables
;-------------------------------------------------------------------------------
OldPotX:        
	.byte    	0               	;Old hw counter values
OldPotY:        
	.byte    	0

XPos:           
	.word    	0               	;Current mouse position, X
YPos:           
	.word    	0               	;Current mouse position, Y
XMin:           
	.word    	0               	;X1 value of bounding box
YMin:           
	.word    	0               	;Y1 value of bounding box
XMax:           
	.word    	319               	;X2 value of bounding box
YMax:           
	.word    	199           		;Y2 value of bounding box
	
Buttons:        
	.byte    	0               	;button status bits
ButtonsOld:
	.byte		0
ButtonLClick:
	.byte		0
ButtonRClick:
	.byte		0
MouseUsed:
	.byte		$00

OldValue:       
	.byte    	0               	;Temp for MoveCheck routine
NewValue:       
	.byte    	0               	;Temp for MoveCheck routine

tempValue:	
	.word		0

mouseCheck:
	.byte		$00
mouseTemp0:
	.word		$0000
mouseXCol:
	.byte		$00
mouseYRow:
	.byte		$00
;mouseLastY:
;	.word           $0000

mousePanl:
		.byte	$00

mouseExtX:
		.byte	$00
mouseExtY:
		.byte	$00
	
keyBuffer0:
	.repeat	20, I
		.byte	$00
	.endrep
keyBufferSize:
		.byte	$00
keyRepeatFlag:
		.byte	$00
keyRepeatSpeed:
		.byte	$00
keyRepeatDelay:
		.byte	$00
keyModifierFlag:
		.byte	$00
keyModifierLast:
		.byte	$00

pickBlinkDelay:
		.byte	$00
pickBlinkState:
		.byte	$00



	.export	userIRQInstall
;-------------------------------------------------------------------------------
userIRQInstall:
;-------------------------------------------------------------------------------
		LDA	#<userIRQ		;install our handler
		STA	cpuIRQ
		LDA	#>userIRQ
		STA	cpuIRQ + 1

		LDA	#<userNOP		;install our handler
		STA	cpuRESET
		LDA	#>userNOP
		STA	cpuRESET + 1

		LDA	#<userNOP		;install our handler
		STA	cpuNMI
		LDA	#>userNOP
		STA	cpuNMI + 1


		LDA	#%01111111		;We'll always want rasters
		AND	vicCtrlReg		;    less than $0100
		STA	vicCtrlReg
		
		LDA	#$19
		STA	vicRstrVal
		
		LDA	#$01			;Enable raster irqs
		STA	vicIRQMask
		
		RTS

;-------------------------------------------------------------------------------
userNOP:
;-------------------------------------------------------------------------------
		RTI


	.export	userIRQ
;-------------------------------------------------------------------------------
userIRQ:
;-------------------------------------------------------------------------------
		PHP				;save the initial state
		PHA
		TXA				
		PHA
		TYA
		PHA

		CLD
		
;	Is the VIC-II needing service?
		LDA	vicIRQFlgs
		AND	#$01
		BNE	@proc
		
;	Some other interrupt source??  Peculiar...  And a real problem!  How
;	do I acknowledge it if its not a BRK when I don't know what it would be?
		LDA	#$02
		STA	vicBrdrClr
		STA	vicBkgdClr

		JMP 	@done
		
@proc:
		ASL	vicIRQFlgs
		
		JSR	userIRQHandler

@done:
		PLA             
		TAY             
		PLA             
		TAX             
		PLA             
		PLP

		RTI


;-------------------------------------------------------------------------------
userIRQHandler:
;-------------------------------------------------------------------------------
	.if	DEBUG_RASTERTIME
		LDA	#$00
		STA	vicBrdrClr
	.endif

		JSR	userProcessMouse	;Do mouse first so we can skip
						;	expensive all lines
						;	keyboard scan when mouse
						;	used.

	.if	DEBUG_RASTERTIME
		LDA	#$05
		STA	vicBrdrClr
	.endif

		JSR	userKeyScanKey
		
		LDA	ctrlsLock
		BNE	@skipUpdate

		LDA	ctrlsPrep
		BNE	@skipUpdate

	.if	DEBUG_RASTERTIME
		LDA	#$01
		STA	vicBrdrClr
	.endif

		JSR	userHandleMouse
		
		LDA	ButtonLClick
		BEQ	@finish
		
		JSR	userHandleMouseClick
		JMP	@finish
	
@skipUpdate:
		LDY	pickBlinkDelay
		BEQ	@finish

		DEY
		STY	pickBlinkDelay


@finish:
	.if	DEBUG_RASTERTIME
		LDA	#$0E
		STA	vicBrdrClr
	.endif

		LDA	#$19
		STA	vicRstrVal
		
		RTS


;-------------------------------------------------------------------------------
userDiscardKey:
;-------------------------------------------------------------------------------
		LDY	keyBuffer0		;copy kernal code for input key
		LDX	#$00
@loop:
		LDA	keyBuffer0 + 2, X
		STA	keyBuffer0, X
		INX
		
		LDA	keyBuffer0 + 3, X
		STA	keyBuffer0 + 1, X
		INX

		CPX	keyZPKeyCount
		BNE	@loop
		
		DEC	keyZPKeyCount
		DEC	keyZPKeyCount

		TYA
;		CLI				;NO!  Causes problem for IRQ
		CLC
		RTS


;-------------------------------------------------------------------------------
userReadKey:
;-------------------------------------------------------------------------------
		LDX	#$00

		STX	keyZPAbort

		LDA	keyZPKeyCount
		BEQ	@exit

		LDA	keyBuffer0, X
		PHA
		INX
		LDA	keyBuffer0, X
		PHA

		JSR	userDiscardKey

		PLA
		TAX
		PLA

@exit:
		RTS
	

;-------------------------------------------------------------------------------
userKeyScanKey:
;-------------------------------------------------------------------------------
		LDA	Buttons			;When button down, just leave 
		BEQ	@begin			;	already

		RTS

@begin:
		LDY	#%00000000              ; Set ports A and B to input
		STY	CIA1_DDRB
		STY	CIA1_DDRA               ; Keyboard won't look like joystick
		LDA	CIA1_PRB                ; Read Control-Port 1
		DEC	CIA1_DDRA               ; Set port A back to output
		EOR	#%11111111              ; Bit goes up when switch goes down
		BEQ	@docheck                   ;(bze)
		DEC	CIA1_DDRB               ; Joystick won't look like keyboard
		STY	CIA1_PRB                ; Set "all keys pushed"

@docheck:
;.,EA87 A9 00    clear A
		LDA 	#$00        
;.,EA89 8D 8D 02 clear the keyboard shift/control/c= flag
		STA 	keyModifierFlag
;.,EA8C A0 40    set no key
		LDY 	#$40
;.,EA8E 84 CB    save which key
		STY 	keyZPKeyScan         
;.,EA90 8D 00 DC clear VIA 1 DRA, keyboard column drive
		STA 	$DC00       
;.,EA93 AE 01 DC read VIA 1 DRB, keyboard row port
		LDX 	$DC01       
;.,EA96 E0 FF    compare with all bits set
		CPX 	#$FF        
;.,EA98 F0 61    if no key pressed clear current key and exit (does
;                                further BEQ to $EBBA)
		BEQ 	keysTstSave		;$EAFB       
;.,EA9A A8       clear the key count
		TAY             
;.,EA9B A9 81    get the decode table low byte
		LDA 	#<keyTableAscii	;$81        
;.,EA9D 85 F5    save the keyboard pointer low byte
		STA 	keyZPDecodePtr         
;.,EA9F A9 EB    get the decode table high byte
		LDA 	#>keyTableAscii	;$EB        
;.,EAA1 85 F6    save the keyboard pointer high byte
		STA 	keyZPDecodePtr + 1         
;.,EAA3 A9 FE    set column 0 low
		LDA 	#$FE
;.,EAA5 8D 00 DC save VIA 1 DRA, keyboard column drive
		STA 	$DC00    
@loopcol:		
;.,EAA8 A2 08    set the row count
		LDX 	#$08        
;.,EAAA 48       save the column
		PHA          
@pollport:		
;.,EAAB AD 01 DC read VIA 1 DRB, keyboard row port
		LDA 	$DC01       
;.,EAAE CD 01 DC compare it with itself
		CMP 	$DC01       
;.,EAB1 D0 F8    loop if changing
		BNE 	@pollport		;$EAAB       
@loop0:
;.,EAB3 4A       shift row to Cb
		LSR             
;.,EAB4 B0 16    if no key closed on this row go do next row
		BCS 	@next			;$EACC       
;.,EAB6 48       save row
		PHA             
;.,EAB7 B1 F5    get character from decode table
		LDA 	(keyZPDecodePtr),Y     
;.,EAB9 C9 05    compare with $05, there is no $05 key but the control
;                                keys are all less than $05
		CMP 	#$05        
;.,EABB B0 0C    if not shift/control/c=/stop go save key count
;                                else was shift/control/c=/stop key
		BCS 	@nextfix		;$EAC9       
;.,EABD C9 03    compare with $03, stop
		CMP 	#$03        
;.,EABF F0 08    if stop go save key count and continue
;                                character is $01 - shift, $02 - c= or $04 - control
;		BEQ 	@nextfix		;$EAC9       
		

		BNE	@savemod

		PHA
		LDA	#$01
		STA	keyZPAbort
		PLA

		JMP	@nextfix

@savemod:

;.,EAC1 0D 8D 02 OR it with the keyboard shift/control/c= flag
		ORA 	keyModifierFlag       
;.,EAC4 8D 8D 02 save the keyboard shift/control/c= flag
		STA 	keyModifierFlag       
;.,EAC7 10 02    skip save key, branch always
		BPL 	@nextfix1		;$EACB       
@nextfix:
;.,EAC9 84 CB    save key count
		STY 	keyZPKeyScan      
@nextfix1:
;.,EACB 68       restore row
		PLA             
@next:
;.,EACC C8       increment key count
		INY             
;.,EACD C0 41    compare with max+1
		CPY 	#$41        
;.,EACF B0 0B    exit loop if >= max+1
		BCS 	@evalspecialfix		;$EADC       
;                                else still in matrix
;.,EAD1 CA       decrement row count
		DEX             
;.,EAD2 D0 DF    loop if more rows to do
		BNE 	@loop0			;$EAB3       
;.,EAD4 38       set carry for keyboard column shift
		SEC             
;.,EAD5 68       restore the column
		PLA             
;.,EAD6 2A       shift the keyboard column
		ROL             
;.,EAD7 8D 00 DC save VIA 1 DRA, keyboard column drive
		STA 	$DC00       
;.,EADA D0 CC    loop for next column, branch always
		BNE 	@loopcol		;$EAA8       
@evalspecialfix:
;.,EADC 68       dump the saved column
		PLA             
		
;;.,EADD 6C 8F 02 evaluate the SHIFT/CTRL/C= keys, $EBDC
;;                                key decoding continues here after the SHIFT/CTRL/C= keys are evaluated
;		JMP 	(keyModifierVect)     

		JMP	keyEvaluateSpecial
		
keysCont:
;.,EAE0 A4 CB    get saved key count
		LDY 	keyZPKeyScan         
;.,EAE2 B1 F5    get character from decode table
		LDA 	(keyZPDecodePtr), Y     
;.,EAE4 AA       copy character to X
		TAX             
;.,EAE5 C4 C5    compare key count with last key count
		CPY 	keyZPKeyDown         
;.,EAE7 F0 07    if this key = current key, key held, go test repeat
		BEQ 	@tstrepeat		;$EAF0 
;.,EAE9 A0 10    set the repeat delay count
		LDY 	#$10        
;.,EAEB 8C 8C 02 save the repeat delay count
		STY 	keyRepeatDelay
;.,EAEE D0 36    go save key to buffer and exit, branch always
		BNE 	keysSave		;$EB26       
@tstrepeat:
;.,EAF0 29 7F    clear b7
		AND 	#$7F        
;.,EAF2 2C 8A 02 test key repeat
		BIT 	keyRepeatFlag
;.,EAF5 30 16    if repeat all go ??
		BMI 	keysNextRep		;$EB0D       
;.,EAF7 70 49    
		BVS 	exitKeys		;$EB42       if repeat none go ??
;.,EAF9 C9 7F    compare with end marker
		CMP 	#$7F        
keysTstSave:
;.,EAFB F0 29           if $00/end marker go save key to buffer and exit
		BEQ 	keysSave		;$EB26
;.,EAFD C9 14    compare with [INSERT]/[DELETE]
;		CMP 	#$14 

		CMP	#KEY_ASC_BKSPC
       
;.,EAFF F0 0C    if [INSERT]/[DELETE] go test for repeat
		BEQ 	keysNextRep		;$EB0D       
;.,EB01 C9 20    compare with [SPACE]
		CMP 	#$20        
;.,EB03 F0 08    if [SPACE] go test for repeat
		BEQ 	keysNextRep		;$EB0D       
;.,EB05 C9 1D    compare with [CURSOR RIGHT]
		CMP 	#$1D        
;.,EB07 F0 04    if [CURSOR RIGHT] go test for repeat
		BEQ 	keysNextRep		;$EB0D       
;.,EB09 C9 11    compare with [CURSOR DOWN]
		CMP 	#$11        
;.,EB0B D0 35    if not [CURSOR DOWN] just exit
;                               was one of the cursor movement keys, insert/delete
;                                key or the space bar so always do repeat tests
		BNE 	exitKeys		;$EB42       

keysNextRep:
;.,EB0D AC 8C 02 get the repeat delay counter
		LDY 	keyRepeatDelay 
;.,EB10 F0 05    if delay expired go ??
		BEQ 	@decrephigh		;$EB17       
;.,EB12 CE 8C 02 else decrement repeat delay counter
		DEC 	keyRepeatDelay 
;.,EB15 D0 2B    if delay not expired go ??
;                                repeat delay counter has expired
		BNE 	exitKeys		;$EB42       
@decrephigh:
;.,EB17 CE 8B 02 decrement the repeat speed counter
		DEC 	keyRepeatSpeed      
;.,EB1A D0 26    branch if repeat speed count not expired
		BNE 	exitKeys		;$EB42       
;.,EB1C A0 04    set for 4/60ths of a second
		LDY 	#$04        
;.,EB1E 8C 8B 02 save the repeat speed counter
		STY 	keyRepeatSpeed       
;.,EB21 A4 C6    get the keyboard buffer index
		LDY 	keyZPKeyCount         
;.,EB23 88       decrement it
		DEY             
;.,EB24 10 1C    if the buffer isn't empty just exit
;                                else repeat the key immediately
;                                possibly save the key to the keyboard buffer. if there was no key pressed or the key
;                                was not found during the scan (possibly due to key bounce) then X will be $FF here
		BPL 	exitKeys		;$EB42       
keysSave:
;.,EB26 A4 CB    get the key count
		LDY 	keyZPKeyScan         
;.,EB28 84 C5    save it as the current key count
		STY 	keyZPKeyDown        
;.,EB2A AC 8D 02 get the keyboard shift/control/c= flag
		LDY 	keyModifierFlag       
;.,EB2D 8C 8E 02 save it as last keyboard shift pattern
		STY 	keyModifierLast      
;.,EB30 E0 FF    compare the character with the table end marker or no key
		CPX 	#$FF        
;.,EB32 F0 0E    if it was the table end marker or no key just exit
		BEQ 	exitKeys		;$EB42       
;.,EB34 8A       copy the character to A
		TXA             
;.,EB35 A6 C6    get the keyboard buffer index
		LDX 	keyZPKeyCount         
;.,EB37 EC 89 02 compare it with the keyboard buffer size
		CPX 	keyBufferSize
;.,EB3A B0 06    if the buffer is full just exit
		BCS 	exitKeys		;$EB42       
;.,EB3C 9D 77 02 save the character to the keyboard buffer
		STA 	keyBuffer0, X 

		TYA
		INX
		STA	keyBuffer0, X
    
;.,EB3F E8       increment the index
		INX             
;.,EB40 86 C6    save the keyboard buffer index
		STX 	keyZPKeyCount         
exitKeys:
;.,EB42 A9 7F    enable column 7 for the stop key
		LDA 	#$7F        
;.,EB44 8D 00 DC save VIA 1 DRA, keyboard column drive
		STA 	$DC00       
;.,EB47 60       
		RTS 


keyEvaluateSpecial:
;;				*** evaluate the SHIFT/CTRL/C= keys
;;.,EB48 AD 8D 02 get the keyboard shift/control/c= flag
		LDA 	keyModifierFlag
		AND	#01
		BNE	@shifted
		
		JMP	@done

@shifted:
		LDA	#<keyTableAsciiShift
		STA	keyZPDecodePtr
		LDA	#>keyTableAsciiShift
		STA	keyZPDecodePtr + 1
		
		JMP	@done
		

;;.,EB4B C9 03    compare with [SHIFT][C=]
;		CMP 	#$03        
;;.,EB4D D0 15    if not [SHIFT][C=] go ??
;		BNE 	@control		;$EB64       
;;.,EB4F CD 8E 02 compare with last
;		CMP 	keyModifierLast
;;.,EB52 F0 EE    exit if still the same
;		BEQ 	exitKeys		;$EB42       
;;.,EB54 AD 91 02 get the shift mode switch $00 = enabled, $80 = locked
;		LDA 	keyModifierLock      
;;.,EB57 30 1D    if locked continue keyboard decode
;;                               toggle text mode
;		BMI 	@done			;$EB76       
;;.,EB59 AD 18 D0 get the start of character memory address
;		LDA 	$D018       
;;.,EB5C 49 02    toggle address b1
;		EOR 	#$02        
;;.,EB5E 8D 18 D0 save the start of character memory address
;		STA 	$D018       
;;.,EB61 4C 76 EB continue the keyboard decode
;;                                select keyboard table
;		JMP 	@done			;$EB76       
;@control:
;;.,EB64 0A       << 1
;		ASL             
;;.,EB65 C9 08    compare with [CTRL]
;		CMP 	#$08        
;;.,EB67 90 02    if [CTRL] is not pressed skip the index change
;		BCC 	@copy			;$EB6B       
;;.,EB69 A9 06    else [CTRL] was pressed so make the index = $06
;		LDA 	#$06        
;@copy:
;;.,EB6B AA       copy the index to X
;		TAX             
;;.,EB6C BD 79 EB get the decode table pointer low byte
;		LDA 	keyTableAddresses, X     
;;.,EB6F 85 F5    save the decode table pointer low byte
;		STA 	keyZPDecodePtr         
;;.,EB71 BD 7A EB get the decode table pointer high byte
;		LDA 	keyTableAddresses + 1,X     
;;.,EB74 85 F6    save the decode table pointer high byte
;		STA 	keyZPDecodePtr + 1         
@done:
;;.,EB76 4C E0 EA continue the keyboard decode
		JMP 	keysCont		;$EAE0       

;keyTableStandard:
;.:EB81 14 0D 1D 88 85 86 87 11
;	.byte	$14, $0D, $1D, $88, $85, $86, $87, $11
;.:EB89 33 57 41 34 5A 53 45 01
;	.byte	$33, $57, $41, $34, $5A, $53, $45, $01
;.:EB91 35 52 44 36 43 46 54 58
;	.byte	$35, $52, $44, $36, $43, $46, $54, $58
;.:EB99 37 59 47 38 42 48 55 56
;	.byte	$37, $59, $47, $38, $42, $48, $55, $56
;.:EBA1 39 49 4A 30 4D 4B 4F 4E
;	.byte	$39, $49, $4A, $30, $4D, $4B, $4F, $4E
;.:EBA9 2B 50 4C 2D 2E 3A 40 2C
;	.byte	$2B, $50, $4C, $2D, $2E, $3A, $40, $2C
;.:EBB1 5C 2A 3B 13 01 3D 5E 2F
;	.byte	$5C, $2A, $3B, $13, $01, $3D, $5E, $2F
;.:EBB9 31 5F 04 32 20 02 51 03
;	.byte	$31, $5F, $04, $32, $20, $02, $51, $03
;.:EBC1 FF
;	.byte	$FF


keyTableAscii:
	.byte	KEY_ASC_BKSPC, KEY_ASC_CR, KEY_C64_CRIGHT, KEY_C64_F7, KEY_C64_F1
	.byte	KEY_C64_F3, KEY_C64_F5, KEY_C64_CDOWN, KEY_ASC_3, KEY_ASC_L_W
	.byte	KEY_ASC_L_A, KEY_ASC_4, KEY_ASC_L_Z, KEY_ASC_L_S, KEY_ASC_L_E
	.byte	KEY_C64_SHIFT, KEY_ASC_5, KEY_ASC_L_R, KEY_ASC_L_D, KEY_ASC_6
	.byte	KEY_ASC_L_C, KEY_ASC_L_F, KEY_ASC_L_T, KEY_ASC_L_X, KEY_ASC_7
	.byte	KEY_ASC_L_Y, KEY_ASC_L_G, KEY_ASC_8, KEY_ASC_L_B, KEY_ASC_L_H
	.byte	KEY_ASC_L_U, KEY_ASC_L_V, KEY_ASC_9, KEY_ASC_L_I, KEY_ASC_L_J
	.byte	KEY_ASC_0, KEY_ASC_L_M, KEY_ASC_L_K, KEY_ASC_L_O, KEY_ASC_L_N
	.byte	KEY_ASC_PLUS, KEY_ASC_L_P, KEY_ASC_L_L, KEY_ASC_MINUS
	.byte	KEY_ASC_STOP, KEY_ASC_COLON, KEY_ASC_AT, KEY_ASC_COMMA
	.byte	KEY_ASC_BSLASH, KEY_ASC_MULT, KEY_ASC_SCOLON, KEY_C64_HOME
	.byte	KEY_C64_SHIFT, KEY_ASC_EQUALS, KEY_ASC_CARET, KEY_ASC_DIV
	.byte	KEY_ASC_1, KEY_ASC_USCORE, KEY_C64_CTRL, KEY_ASC_2, KEY_ASC_SPACE 
	.byte	KEY_C64_SYS, KEY_ASC_L_Q, KEY_C64_STOP
	.byte	KEY_C64_INVALID

keyTableAsciiShift:
	.byte	KEY_C64_INS, KEY_ASC_CR, KEY_C64_CLEFT, KEY_C64_F8, KEY_C64_F2
	.byte	KEY_C64_F4, KEY_C64_F6, KEY_C64_CUP, KEY_ASC_POUND, KEY_ASC_W
	.byte	KEY_ASC_A, KEY_ASC_DOLLAR, KEY_ASC_Z, KEY_ASC_S, KEY_ASC_E
	.byte	KEY_C64_SHIFT, KEY_ASC_PERCENT, KEY_ASC_R, KEY_ASC_D, KEY_ASC_AMP
	.byte	KEY_ASC_C, KEY_ASC_F, KEY_ASC_T, KEY_ASC_X, KEY_ASC_QUOTE
	.byte	KEY_ASC_Y, KEY_ASC_G, KEY_ASC_OBRCKT, KEY_ASC_B, KEY_ASC_H
	.byte	KEY_ASC_U, KEY_ASC_V, KEY_ASC_CBRCKT, KEY_ASC_I, KEY_ASC_J
	.byte	KEY_ASC_0, KEY_ASC_M, KEY_ASC_K, KEY_ASC_O, KEY_ASC_N
	.byte	KEY_ASC_PLUS, KEY_ASC_P, KEY_ASC_L, KEY_ASC_MINUS
	.byte	KEY_ASC_GRTRTH, KEY_ASC_OSQRBR, KEY_ASC_BQUOTE, KEY_ASC_LESSTH
	.byte	KEY_ASC_PIPE, KEY_ASC_MULT, KEY_ASC_CSQRBR, KEY_C64_CLEAR
	.byte	KEY_C64_SHIFT, KEY_ASC_EQUALS, KEY_ASC_TILDE, KEY_ASC_QMARK
	.byte	KEY_ASC_EXMRK, KEY_ASC_USCORE, KEY_C64_CTRL, KEY_ASC_DQUOTE, KEY_ASC_SPACE 
	.byte	KEY_C64_SYS, KEY_ASC_Q, KEY_C64_SHSTOP
	.byte	KEY_C64_INVALID


;-------------------------------------------------------------------------------
check_for_abort_key:
;-------------------------------------------------------------------------------
		LDA	keyZPAbort
		BEQ	@nokey

		SEC
		RTS

@nokey:
		CLC
		RTS


	.export	userHandleMouse
;-------------------------------------------------------------------------------
userHandleMouse:
;-------------------------------------------------------------------------------
		LDA	mouseCheck
		CMP	#$10
		BCS	@proc
			
		LDA	ButtonLClick
		BNE	@proc

		LDA	pickCtrl + 1
		BNE	@tstblink

		RTS

@tstblink:
		CMP	downCtrl + 1
		BNE	@blink

		LDA	pickCtrl
		CMP	downCtrl
		BNE	@blink

		RTS

@blink:
		JSR	userMousePickBlink
		RTS

@proc:
		LDA	#$00
		STA	mouseCheck

		LDA	XPos
		STA	mouseTemp0
		LDA	XPos + 1
		STA	mouseTemp0 + 1
		
		LDX	#$02
@xDiv8Loop:
		LSR
		STA	mouseTemp0 + 1
		LDA	mouseTemp0
		ROR
		STA	mouseTemp0
		LDA	mouseTemp0 + 1
		
		DEX
		BPL	@xDiv8Loop
		
		LDA	mouseTemp0
		STA	mouseXCol
		
		LDA	YPos
		STA	mouseTemp0
		LDA	YPos + 1
		STA	mouseTemp0 + 1
		
		LDX	#$02
@yDiv8Loop:
		LSR
		STA	mouseTemp0 + 1
		LDA	mouseTemp0
		ROR
		STA	mouseTemp0
		LDA	mouseTemp0 + 1
		
		DEX
		BPL	@yDiv8Loop
		
		LDA	mouseTemp0
		STA	mouseYRow

;		Find last panel on page
		
		LDY	#PAGE::panels
		LDA	(pageptr0), Y
		STA	ctrlptr0
		INY
		LDA	(pageptr0), Y
		STA	ctrlptr0 + 1

		LDY	#PAGE::panlcnt
		LDA	(pageptr0), Y
		ASL
		STA	ctrlvar_a
		DEC	ctrlvar_a

@panel0:
;		for each panel on page rev
		LDY	ctrlvar_a

		LDA	(ctrlptr0), Y
		STA	panlptr0 + 1
		DEY
		LDA	(ctrlptr0), Y
		STA	panlptr0
		DEY
		
		STY	ctrlvar_a

		LDY	#ELEMENT::state
		LDA	(panlptr0), Y
		AND	#STATE_VISIBLE
		BEQ	@panelnext

		LDA	(panlptr0), Y
		AND	#STATE_ENABLED
		BEQ	@panelnext

		LDY	#ELEMENT::options
		LDA	(panlptr0), Y
		AND	#OPT_NONAVIGATE
		BNE	@panelnext

;		find coord in panel

		LDA	panlptr0
		STA	elemptr0
		LDA	panlptr0 + 1
		STA	elemptr0 + 1

		JSR	userMouseInCtrl
		BCC	@panelnext

;		for each elem in panel 

		LDY	#PANEL::controls
		LDA	(panlptr0), Y
		STA	ctrlptr1
		INY
		LDA	(panlptr0), Y
		STA	ctrlptr1 + 1

		LDY	#$00
		
@elem0:
		LDA	(ctrlptr1), Y
		STA	elemptr0
		INY
		LDA	(ctrlptr1), Y
		BEQ	@panelnext
		
		STA	elemptr0 + 1
		INY
		
		STY	ctrlvar_b

;		find coord in elem on panel
		
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_VISIBLE
		BEQ	@elemnext

		LDA	(elemptr0), Y
		AND	#STATE_ENABLED
		BEQ	@elemnext

		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_NONAVIGATE
		BNE	@elemnext

;		find coord in elem

		JSR	userMouseInCtrl
		BCC	@elemnext

		LDA	elemptr0
		CMP	pickCtrl
		BNE	@newpick

		LDA	elemptr0 + 1
		CMP	pickCtrl + 1
		BNE	@newpick

		JSR	userMousePickBlink
		RTS

@newpick:
		LDA	#$29
		STA	pickBlinkDelay
		LDA	#$01
		STA	pickBlinkState

		JSR	userMousePickCtrl
		RTS
		
@elemnext:
		LDY	ctrlvar_b
		JMP	@elem0

@panelnext:
		LDY	ctrlvar_a
		BMI	@unpick
		
		JMP	@panel0

@unpick:
		JSR	userMouseUnPickCtrl

		RTS


;-------------------------------------------------------------------------------
userHandleMouseClick:
;-------------------------------------------------------------------------------
		LDA	#$00			
		STA	ButtonLClick

		LDA	pickCtrl + 1
		BNE	@down

		RTS

@down:
		STA	elemptr0 + 1
		LDA	pickCtrl
		STA	elemptr0 

		JSR	ctrlsDownCtrl

		RTS


	.export	userMousePickBlink
;-------------------------------------------------------------------------------
userMousePickBlink:
;-------------------------------------------------------------------------------
		LDY	pickBlinkDelay
		BEQ	@blink

		DEY
		STY	pickBlinkDelay
		
		RTS

@blink:
		LDY	#$29
		STY	pickBlinkDelay

		LDA	pickCtrl
		STA	elemptr0
		LDA	pickCtrl + 1
		STA	elemptr0 + 1
		
		LDA	pickBlinkState
		EOR	#$01
		STA	pickBlinkState

;		JSR 	ctrlsControlInvalidate

		BEQ	@exclude
	
		LDA	#STATE_PICK
		JSR	ctrlsIncludeState
		RTS

@exclude:
		LDA	#STATE_PICK
		JSR	ctrlsExcludeState

		RTS


;-------------------------------------------------------------------------------
userMouseUnPickCtrl:
;-------------------------------------------------------------------------------
		LDA	pickCtrl + 1
		BEQ	@exit

		LDY	#ELEMENT::state
		LDA	(pickCtrl), Y

		AND	#STATE_PICK
		BEQ	@clear

		LDA	pickCtrl
		STA	elemptr0
		LDA	pickCtrl + 1
		STA	elemptr0 + 1

		LDA	#STATE_PICK
		JSR	ctrlsExcludeState
		
@clear:
		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1

@exit:
		RTS


	.export	userMousePickCtrl
;-------------------------------------------------------------------------------
userMousePickCtrl:
;-------------------------------------------------------------------------------
		LDA	elemptr0
		CMP	pickCtrl
		BNE	@update

		LDA	elemptr0 + 1
		CMP	pickCtrl + 1
		BNE	@update

		RTS

@update:
		LDA	elemptr0
		STA	tempptr0
		LDA	elemptr0 + 1
		STA	tempptr0 + 1

		JSR	userMouseUnPickCtrl

		LDA	tempptr0
		STA	pickCtrl
		STA	elemptr0
		LDA	tempptr0 + 1
		STA	pickCtrl + 1
		STA	elemptr0 + 1

		LDA	#STATE_PICK
		JSR	ctrlsIncludeState
		
		RTS


	.export userMouseInCtrl
;-------------------------------------------------------------------------------
userMouseInCtrl:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::posy
		LDA	(elemptr0), Y
		STA	ctrlvar_c

		LDA	mouseYRow
		CMP	ctrlvar_c
		BPL	@testh

		JMP	@nomatch

@testh:
		LDY	#ELEMENT::height
		LDA	(elemptr0), Y

		CLC
		ADC	ctrlvar_c
		STA	ctrlvar_c

		LDA	mouseYRow
		CMP	ctrlvar_c
		BPL	@nomatch

		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	ctrlvar_c

		LDA	mouseXCol
		CMP	ctrlvar_c
		BPL	@testw

@nomatch:
		CLC
		RTS

@testw:
		LDY	#ELEMENT::width
		LDA	(elemptr0), Y

		CLC
		ADC	ctrlvar_c
		STA	ctrlvar_c

		LDA	mouseXCol
		CMP	ctrlvar_c
		BPL	@nomatch

		SEC
		
		RTS


;-------------------------------------------------------------------------------
userProcessMouse:
;-------------------------------------------------------------------------------
		LDA	mouseCheck
		BEQ	@begin
		
		INC	mouseCheck
		
@begin:
		LDY     #%00000000              ;Set ports A and B to input
		STY     CIA1_DDRB
		STY     CIA1_DDRA               ;Keyboard won't look like mouse
		LDA     CIA1_PRB                ;Read Control-Port 1
		DEC     CIA1_DDRA               ;Set port A back to output
		EOR     #%11111111              ;Bit goes up when button goes down
		STA     Buttons
		BEQ     @L0                     ;(bze)
		DEC     CIA1_DDRB               ;Mouse won't look like keyboard
		STY     CIA1_PRB                ;Set "all keys pushed"

@L0:    
		JSR	ButtonCheck
		
		LDA     SID_ADConv1             ;Get mouse X movement
		LDY     OldPotX
		JSR     MoveCheck               ;Calculate movement vector

; Skip processing if nothing has changed

		BCC     @SkipX
		STY     OldPotX

; Calculate the new X coordinate (--> a/y)

		CLC
		ADC	XPos

		TAY                             ;Remember low byte
		TXA
		ADC     XPos+1
		TAX

; Limit the X coordinate to the bounding box

		CPY     XMin
		SBC     XMin+1
		BPL     @L1
		LDY     XMin
		LDX     XMin+1
		JMP     @L2
@L1:    	
		TXA

		CPY     XMax
		SBC     XMax+1
		BMI     @L2
		LDY     XMax
		LDX     XMax+1
@L2:    
		STY     XPos
		STX     XPos+1

; Move the mouse pointer to the new X pos

		TYA
		JSR     CMOVEX
		
		LDA	mouseCheck
		BNE	@SkipX

		LDA	#$01
		STA	mouseCheck

; Calculate the Y movement vector

@SkipX: 
		LDA     SID_ADConv2             ;Get mouse Y movement
		LDY     OldPotY
		JSR     MoveCheck               ;Calculate movement

; Skip processing if nothing has changed

		BCC     @SkipY
		STY     OldPotY

; Calculate the new Y coordinate (--> a/y)

		STA     OldValue
		LDA     YPos
		SEC
		SBC	OldValue

		TAY
		STX     OldValue
		LDA     YPos+1
		SBC     OldValue
		TAX

; Limit the Y coordinate to the bounding box

		CPY     YMin
		SBC     YMin+1
		BPL     @L3
		LDY     YMin
		LDX     YMin+1
		JMP     @L4
@L3:    
		TXA

		CPY     YMax
		SBC     YMax+1
		BMI     @L4
		LDY     YMax
		LDX     YMax+1
@L4:    	
		STY     YPos
		STX     YPos+1

; Move the mouse pointer to the new Y pos

		TYA
		JSR     CMOVEY

		LDA	mouseCheck
		BNE	@SkipY
		
		LDA	#$01
		STA	mouseCheck

; Done

@SkipY: 
;		JSR     CDRAW

;dengland:	What is this for???
		CLC                             ;Interrupt not "handled"

		RTS
		

;-------------------------------------------------------------------------------
MoveCheck:
; Move check routine, called for both coordinates.
;
; Entry:        y = old value of pot register
;               a = current value of pot register
; Exit:         y = value to use for old value
;               x/a = delta value for position
;-------------------------------------------------------------------------------
;***FIXME:	Are you supposed to mask out certain bits (lowest?) in order to
;		correct for jitter?  A real mouse isn't synced to the C64 like 
;		it should be or tries to be...  I could allow sensativity setting
;		as per joystick but instead mask off lowest 0, 1 or 2 bits.

		STY     OldValue
		STA     NewValue
		LDX     #$00

		SEC				; a = mod64 (new - old)
		SBC	OldValue

		AND     #%01111111
		CMP     #%01000000              ; if (a > 0)
		BCS     @L1                     ;
		LSR                             ;   a /= 2;
		BEQ     @L2                     ;   if (a != 0)
		LDY     NewValue                ;     y = NewValue
		SEC
		RTS                             ;   return

@L1:    
		ORA     #%11000000              ; else, "or" in high-order bits
		CMP     #$FF                    ; if (a != -1)
		BEQ     @L2
		SEC
		ROR                             ;   a /= 2
		DEX                             ;   high byte = -1 (X = $FF)
		LDY     NewValue
		SEC
		RTS

@L2:    
		TXA                             ; A = $00
		CLC
		RTS


;-------------------------------------------------------------------------------
ButtonCheck:
;-------------------------------------------------------------------------------
		LDA	Buttons			;Buttons still the same as last
		CMP	ButtonsOld		;time?
		BEQ	@done			;Yes - don't do anything here
		
;		PHA
;		LDA	#$01
;		STA	MouseUsed
;		PLA
		
		AND	#buttonLeft		;No - Is left button down?
		BNE	@testRight		;Yes - test right
		
		LDA	ButtonsOld		;No, but was it last time?
		AND	#buttonLeft
		BEQ	@testRight		;No - test right
		
		LDA	#$01			;Yes - flag have left click
		STA	ButtonLClick
		
@testRight:
		AND	#buttonRight		;Is right button down?
		BNE	@done			;Yes - don't do anything here
		
		LDA	ButtonsOld		;No, but was it last time?
		AND	#buttonRight
		BEQ	@done			;No - don't do anything here
		
		LDA	#$01			;Yes - flag have right click
		STA	ButtonRClick

@done:
		LDA	Buttons			;Store the current state
		STA	ButtonsOld
		RTS


;-------------------------------------------------------------------------------
CMOVEX:
;-------------------------------------------------------------------------------
		CLC
		LDA	XPos
		ADC	#offsX
		STA	tempValue
		LDA	XPos + 1
		ADC	#$00
		STA	tempValue + 1
	
		LDA	tempValue
		STA	VICXPOS0
		STA	VICXPOS1
		STA	VICXPOS2
		STA	VICXPOS3
		
		LDA	tempValue + 1
		CMP	#$00
		BEQ	@unset
	
		LDA	VICXPOSMSB
		ORA	#$0F
		STA	VICXPOSMSB
		RTS
	
@unset:
		LDA	VICXPOSMSB
		AND	#$F0
		STA	VICXPOSMSB
		RTS
	
;-------------------------------------------------------------------------------
CMOVEY:
;-------------------------------------------------------------------------------
		CLC
		LDA	YPos
		ADC	#offsY
		STA	tempValue
		LDA	YPos + 1
		ADC	#$00
		STA	tempValue + 1
	
		LDA	tempValue
		STA	VICYPOS0
		STA	VICYPOS1
		STA	VICYPOS2
		STA	VICYPOS3
	
		RTS


;===============================================================================
;USER INTERFACE DEFINITIONS
;===============================================================================


;-------------------------------------------------------------------------------
page_splsh:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00 		;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$16		;height	.byte
			.byte	$00		;tag	.byte
			.word	$0000		;textptr	.word
			.byte	$00		;textoffx .byte
			.word	page_splsh_pnls ;panels	.word
			.byte	$05

page_splsh_pnls:
			.word	panel_splsh_hdr
			.word	panel_splsh_body
			.word	panel_splsh_bkgd
			.word	panel_splsh_frgd
			.word	panel_splsh_foot
			.word	$0000
			
panel_splsh_hdr:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$00		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$03		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_splsh
			.word	panel_splsh_hdr_ctrls	;controls .word
			.byte	$01

panel_splsh_hdr_ctrls:
			.word	hlabel_splsh_title
			.word	$0000

hlabel_splsh_title:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FOCUS	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$02		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_hdr	;panel	.word
			.word	text_splsh_title	;textptr	.word
			.byte	$0E		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.word	$0000		;actvctrl .word

panel_splsh_body:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$15		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_splsh
			.word	panel_splsh_body_ctrls	;controls .word
			.byte	$01

panel_splsh_body_ctrls:
			.word	button_splsh_cont
			.word	$0000

button_splsh_cont:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientSplshContChng
			.word	clientSplshContKeyPress
			.byte	$00
			.byte	$00		;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$0F		;posx	.byte
			.byte	$16		;posy	.byte
			.byte	$0A		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_body	;panel	.word
			.word	text_splsh_cont	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	'c'		;accelchar .byte

panel_splsh_bkgd:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_SHADOW	;colour	.byte
			.byte	$04		;posx	.byte
			.byte	$07		;posy	.byte
			.byte	$23		;width	.byte
			.byte	$0E		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_splsh
			.word	panel_splsh_bkgd_ctrls	;controls .word
			.byte	$00

panel_splsh_bkgd_ctrls:
			.word	$0000

panel_splsh_frgd:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_PAPER	;colour	.byte
			.byte	$02		;posx	.byte
			.byte	$05		;posy	.byte
			.byte	$24		;width	.byte
			.byte	$0F		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_splsh
			.word	panel_splsh_frgd_ctrls	;controls .word
			.byte	$05

panel_splsh_frgd_ctrls:
			.word	static_splsh_text0
			.word	static_splsh_text1
			.word	static_splsh_text2
			.word	static_splsh_text3
			.word	static_splsh_text4
			.word	$0000

static_splsh_text0:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$02		;posx	.byte
			.byte	$07		;posy	.byte
			.byte	$24		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_frgd	;panel	.word
			.word	text_splsh_text0	;textptr	.word
			.byte	$04		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte

static_splsh_text1:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$02		;posx	.byte
			.byte	$09		;posy	.byte
			.byte	$24		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_frgd	;panel	.word
			.word	text_splsh_text1	;textptr	.word
			.byte	$06		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte

static_splsh_text2:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$02		;posx	.byte
			.byte	$0C		;posy	.byte
			.byte	$24		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_frgd	;panel	.word
			.word	text_splsh_text2	;textptr	.word
			.byte	$09		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte

static_splsh_text3:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$02		;posx	.byte
			.byte	$0F		;posy	.byte
			.byte	$24		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_frgd	;panel	.word
			.word	text_splsh_text3	;textptr	.word
			.byte	$06		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte

static_splsh_text4:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$02		;posx	.byte
			.byte	$11		;posy	.byte
			.byte	$24		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_frgd	;panel	.word
			.word	text_splsh_text4	;textptr	.word
			.byte	$09		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte

panel_splsh_foot:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$18		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_splsh
			.word	panel_splsh_foot_ctrls	;controls .word
			.byte	$01
			
panel_splsh_foot_ctrls:
			.word	static_init_text0
			.word	$0000

static_init_text0:
			.word	$0000		;prepare
			.word	clientInitLblPres	;present	.word
			.word	$0000			;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$18		;posy	.byte
			.byte	$24		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_splsh_foot	;panel	.word
			.word	text_init_text0	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte


tab_main:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_TAB
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NOPRESENT 	;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$00		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$03		;height	.byte
			.byte	$00		;tag	.byte
			.word	$0000
			.word	tab_main_ctrls	;controls .word
			.byte	$04
			.word	$0000		;page	.word
			
tab_main_ctrls:
			.word	tlabel_main_begin
			.word	tlabel_main_chat
			.word	tlabel_main_play
			.word	hlabel_main_page
			.word	$0000

tlabel_main_begin:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientMainBeginChng	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE | OPT_NODOWNACTV | OPT_TEXTACCEL2X	
			.byte	CLR_FOCUS	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$00		;posy	.byte
			.byte	$09		;width	.byte
			.byte	$02		;height	.byte
			.byte	$00		;tag	.byte
			.word	tab_main	;panel	.word
			.word	text_main_begin ;textptr	.word
			.byte	$00		;testoffx .byte
			.byte	$00		;testaccel .byte
			.byte	KEY_C64_F1	;accelchar .byte
			.word	$0000		;actvctrl .word
			
tlabel_main_chat:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientMainChatChng ;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NODOWNACTV | OPT_TEXTACCEL2X 
			.byte	CLR_FACE	;colour	.byte
			.byte	$09		;posx	.byte
			.byte	$00		;posy	.byte
			.byte	$09		;width	.byte
			.byte	$02		;height	.byte
			.byte	$00		;tag	.byte
			.word	tab_main	;panel	.word
			.word	text_main_chat  ;textptr	.word
			.byte	$01		;testoffx .byte
			.byte	$01		;testaccel .byte
			.byte	KEY_C64_F3		;accelchar .byte
			.word	$0000		;actvctrl .word
		
tlabel_main_play:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NODOWNACTV | OPT_TEXTACCEL2X	
			.byte	CLR_FACE	;colour	.byte
			.byte	$12		;posx	.byte
			.byte	$00		;posy	.byte
			.byte	$09		;width	.byte
			.byte	$02		;height	.byte
			.byte	$00		;tag	.byte
			.word	tab_main	;panel	.word
			.word	text_main_play  ;textptr	.word
			.byte	$01		;testoffx .byte
			.byte	$01		;testaccel .byte
			.byte	KEY_C64_F5		;accelchar .byte
			.word	$0000		;actvctrl .word
		
hlabel_main_page:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FOCUS	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$02		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	tab_main	;panel	.word
			.word	$0000 		;textptr	.word
			.byte	$00		;testoffx .byte
			.byte	$FF		;testaccel .byte
			.byte	$00		;accelchar .byte
			.word	$0000		;actvctrl .word

page_connect:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_PAGE
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00 		;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$16		;height	.byte
			.byte	$00		;tag	.byte
			.word	text_page_connect;textptr	.word
			.byte	$10		;testoffx .byte
			.word	page_connect_pnls;panels	.word
			.byte	$03

page_connect_pnls:
			.word	tab_main
			.word	panel_cnct_data
			.word	lpanel_cnct_log
			.word	$0000
			
panel_cnct_data:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_PANEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$09		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_connect
			.word	panel_cnct_data_ctrls	;controls .word
			.byte	$09
			
panel_cnct_data_ctrls:
			.word	label_cnct_host
			.word	edit_cnct_host
			.word	label_cnct_user
			.word	edit_cnct_user
			.word	button_cnct_upd
			.word	button_cnct_cnct
			.word	button_cnct_dcnt
			.word	label_cnct_info
			.word	combo_cnct_info
			.word	$0000

label_cnct_host:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$04		;posy	.byte
			.byte	$0B		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	text_cnct_host  ;textptr	.word
			.byte	$00		;testoffx .byte
			.byte	$00		;testaccel .byte
			.byte	'h'		;accelchar .byte
			.word	edit_cnct_host	;actvctrl .word
			
edit_cnct_host:
			.word	$0000		;prepare
			.word	ctrlsEditDefPresent
			.word	$0000		;changed .word
			.word	ctrlsEditDefKeyPress
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_TEXTCONTMRK
			.byte	CLR_PAPER	;colour	.byte
			.byte	$0B		;posx	.byte
			.byte	$04		;posy	.byte
			.byte	$1D		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	edit_cnct_host_buf ;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.byte	$00		;textsiz
			.byte	$3C		;textmaxsz
			

edit_cnct_host_buf:
	.repeat	61	
		.byte	$00
	.endrep

label_cnct_user:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$06		;posy	.byte
			.byte	$0B		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	text_cnct_user  ;textptr	.word
			.byte	$00		;testoffx .byte
			.byte	$00		;testaccel .byte
			.byte	'u'		;accelchar .byte
			.word	edit_cnct_user	;actvctrl .word
			
edit_cnct_user:
			.word	$0000		;prepare
			.word	ctrlsEditDefPresent
			.word	$0000		;changed .word
			.word	ctrlsEditDefKeyPress
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$0B		;posx	.byte
			.byte	$06		;posy	.byte
			.byte	$09		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	edit_cnct_user_buf
			.byte	$00		;testoffx .byte
			.byte	$FF		;testaccel .byte
			.byte	$00		;accelchar .byte
			.byte	$00		;textsiz
			.byte	$08		;textmaxsz

edit_cnct_user_buf:
	.repeat	9	
			.byte	$00
	.endrep
			
button_cnct_upd:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE
			.byte	$00		;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$1E		;posx	.byte
			.byte	$06		;posy	.byte
			.byte	$0A		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	text_cnct_upd	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$02		;textaccel .byte
			.byte	'p'		;accelchar .byte

button_cnct_cnct:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientCnctCnctChng
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00		;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$1E		;posx	.byte
			.byte	$08		;posy	.byte
			.byte	$0A		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	text_cnct_cnct	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	'c'		;accelchar .byte
			
button_cnct_dcnt:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientCnctDCntChng
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	$00
			.byte	$00		;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$1E		;posx	.byte
			.byte	$08		;posy	.byte
			.byte	$0A		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	text_cnct_dcnct	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	'd'		;accelchar .byte

label_cnct_info:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$0A		;posy	.byte
			.byte	$0B		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	text_cnct_info  ;textptr	.word
			.byte	$00		;testoffx .byte
			.byte	$05		;testaccel .byte
			.byte	'i'		;accelchar .byte
			.word	combo_cnct_info	;actvctrl .word
			
combo_cnct_info:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00		;options	.byte
			.byte	CLR_TEXT	;colour	.byte
			.byte	$0B		;posx	.byte
			.byte	$0A		;posy	.byte
			.byte	$1D		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	$0000 		;textptr	.word
			.byte	$00		;testoffx .byte
			.byte	$FF		;testaccel .byte
			.byte	$00		;accelchar .byte

lpanel_cnct_log:
			.word	$0000		;prepare
			.word	ctrlsLPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$0C		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$0D		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_connect
			.word	lpanel_cnct_log_ctrls	;controls .word
			.byte	$00
			.word	lpanel_cnct_log_lines
			.byte	$00

lpanel_cnct_log_lines:
			.word	cnct_log_line0
			.word	cnct_log_line1
			.word	cnct_log_line2
			.word	cnct_log_line3
			.word	cnct_log_line4
			.word	cnct_log_line5
			.word	cnct_log_line6
			.word	cnct_log_line7
			.word	cnct_log_line8
			.word	cnct_log_line9
			.word	cnct_log_lineA
			.word	cnct_log_lineB
			.word	cnct_log_lineC

lpanel_cnct_log_ctrls:
			.word	$0000

page_room:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_PAGE
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00 		;options	.byte
			.byte	CLR_TEXT	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$16		;height	.byte
			.byte	$00		;tag	.byte
			.word	text_page_room	;textptr	.word
			.byte	$10		;testoffx .byte
			.word	page_room_pnls	;panels	.word
			.byte	$05

page_room_pnls:
			.word	tab_main
			.word	panel_room_more
			.word	panel_room_log
			.word	panel_room_data
			.word 	panel_room_less
			.word	$0000
			
panel_room_less:
			.word	$0000			;prepare
			.word	ctrlsPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
;			.byte	TYPE_PANEL
			.byte	$00
			.byte	$00
			.byte	CLR_INSET		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$03			;posy	.byte
			.byte	$28			;width	.byte
			.byte	$02			;height	.byte
			.byte	$00			;tag	.byte
			.word	page_room
			.word	panel_room_less_ctrls	;controls 
			.byte	$01
			
panel_room_less_ctrls:
			.word	button_room_more
			.word	$0000
			
button_room_more:
			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientRoomMoreChng
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_less		;panel	.word
			.word	text_room_more		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$08			;textaccel .byte
			.byte	'>'			;accelchar .byte			

panel_room_more:
			.word	$0000			;prepare
			.word	ctrlsPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00
			.byte	CLR_INSET		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$03			;posy	.byte
			.byte	$28			;width	.byte
			.byte	$07			;height	.byte
			.byte	$00			;tag	.byte
			.word	page_room
			.word	panel_room_more_ctrls	;controls 
			.byte	$07
			
panel_room_more_ctrls:
			.word	label_room_room
			.word	edit_room_room
			.word	button_room_list
			.word	label_room_pwd
			.word	edit_room_pwd
			.word	button_room_join
			.word	button_room_less
			.word	$0000

label_room_room:
			.word	$0000			;prepare
			.word	$0000			;present
			.word	$0000			;changed 
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$0C			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	text_room_room  	;textptr	.word
			.byte	$00			;testoffx .byte
			.byte	$00			;testaccel .byte
			.byte	'r'			;accelchar .byte
			.word	edit_room_room		;actvctrl .word

edit_room_room:
			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	$0000			;changed .word
			.word	ctrlsEditDefKeyPress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE
			.byte	CLR_PAPER		;colour	.byte
			.byte	$0C			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$09			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	edit_room_room_buf
			.byte	$00			;testoffx .byte
			.byte	$FF			;testaccel .byte
			.byte	$00			;accelchar .byte
			.byte	$00			;textsiz
			.byte	$08			;textmaxsz

edit_room_room_buf:
	.repeat	9	
			.byte	$00
	.endrep

button_room_list:
			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	text_room_list		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$01			;textaccel .byte
			.byte	'l'			;accelchar .byte			

label_room_pwd:
			.word	$0000			;prepare
			.word	$0000			;present
			.word	$0000			;changed 
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$06			;posy	.byte
			.byte	$0C			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	text_room_pwd	  	;textptr	.word
			.byte	$00			;testoffx .byte
			.byte	$00			;testaccel .byte
			.byte	'p'			;accelchar .byte
			.word	edit_room_pwd		;actvctrl .word

edit_room_pwd:
			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	$0000			;changed .word
			.word	ctrlsEditDefKeyPress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE
			.byte	CLR_PAPER		;colour	.byte
			.byte	$0C			;posx	.byte
			.byte	$06			;posy	.byte
			.byte	$09			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	edit_room_pwd_buf
			.byte	$00			;testoffx .byte
			.byte	$FF			;testaccel .byte
			.byte	$00			;accelchar .byte
			.byte	$00			;textsiz
			.byte	$08			;textmaxsz

edit_room_pwd_buf:
	.repeat	9	
			.byte	$00
	.endrep

button_room_join:
			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$06			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	text_room_join		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$01			;textaccel .byte
			.byte	'j'			;accelchar .byte			

button_room_less:
			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientRoomLessChng
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$08			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	text_room_less		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$08			;textaccel .byte
			.byte	'<'			;accelchar .byte			

panel_room_log:
			.word	$0000			;prepare
			.word	ctrlsPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
;			.byte	TYPE_PANEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$0A		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$0D		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_room
			.word	panel_room_log_ctrls	;controls .word
			.byte	$00

panel_room_log_ctrls:
			.word	$0000

panel_room_data:
			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_PANEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$17		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$02		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_room
			.word	panel_room_data_ctrls	;controls .word
			.byte	$01

panel_room_data_ctrls:
			.word	edit_room_text
			.word	$0000

edit_room_text:
			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$18		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_room_data	;panel	.word
			.word	$0000 		;textptr	.word
			.byte	$00		;testoffx .byte
			.byte	$FF		;testaccel .byte
			.byte	$00		;accelchar .byte




;===============================================================================
;MAIN PROGRAM CODE STARTS HERE
;===============================================================================



	.export main
;-------------------------------------------------------------------------------
main:
;-------------------------------------------------------------------------------
		LDA	#$8E			;go to uppercase characters
		JSR	krnlOutChr
		LDA	#$08			;disable change character case
		JSR	krnlOutChr
	
		SEI
		CLD

		LDA	#$7F			;disable standard CIA irqs
		STA	cia1IRQCtl
		
		JSR	initCore

;		Reset the stack pointer
		LDX	#$FF
		TXS

		LDA	#$00
		JSR	colourSchemeSelect
		
		LDA	#<page_splsh
		STA	elemptr0
		LDA	#>page_splsh
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect

		CLI
	
@loop:						;This is where we do our timer
	.if	DEBUG_RASTERTIME		;	check for TCP keep alives
		LDA	#$06			;	and any message data sends
		STA	vicBrdrClr
	.endif

		LDA	inetproc
		CMP	#INET_PROC_INIT
		BEQ	@inetinit

		CMP	#INET_PROC_IDLE
		BNE	@tstnxt0

@idle:
		JSR	inetIdle
		JMP	@lock

@tstnxt0:
		CMP	#INET_PROC_HALT
		BEQ	@idle

		CMP	#INET_PROC_CNCT
		BEQ	@connect

		CMP	#INET_PROC_PCNT
		BNE	@tstnxt1

		LDA	#INET_PROC_CNCT
		STA	inetproc
		JMP	@lock
		
@tstnxt1:
		CMP	#INET_PROC_EXEC
		BNE	@tstnxt2

		JSR	inetExecute
		JMP	@lock

@tstnxt2:
		CMP	#INET_PROC_DISC
		BNE	@tstnxt3

		JSR	inetDisconnect
		JMP	@lock

@tstnxt3:
		CMP	#INET_PROC_DSCD
		BNE	@tstnxt4

		JSR	inetDisconnected
		JMP	@lock

@tstnxt4:
		JMP	@lock

@connect:
		JSR	inetConnect
		JMP	@lock

@inetinit:
		JSR	inetInitialise


@lock:						;We need to lock here for reads...
		JSR	ctrlsLockAcquire


	.if	DEBUG_RASTERTIME
		LDA	#$02
		STA	vicBrdrClr
	.endif

@prepare:					;Normal control life cycle starts
		LDA	ctrlsPrep
		BEQ	@changed

		JSR	ctrlsDisposeMsgs	;I don't think that the total time
						;	for reads and control life
		JSR	ctrlsPagePrepare	;	will cause problems for TCP
						;	keep alives.  If it does, 
		LDA	#$00			;	need to do one or other, 
		STA	ctrlsPrep		;	reads or ctrl updates.
		STA	ctrlsLChg

		JMP	@next

@changed:
		LDA	msgs_change_idx
		BEQ	@present

		LDA	ctrlsLChg
		BNE	@present

		JSR	ctrlsPageChanged

		LDA	#$01
		STA	ctrlsLChg

		JMP	@next

@present:
		LDA	#$00
		STA	ctrlsLChg

		LDA	msgs_dirty_idx
		BEQ	@keys

		JSR	ctrlsPagePresent

;		JMP	@next

@keys:
		JSR	userReadKey
		BEQ	@next

		JSR	ctrlsPageKeyPress

@next:
	.if	DEBUG_RASTERTIME
		LDA	#$0E
		STA	vicBrdrClr
	.endif

@unlock:					;Unlock here...
		JSR	ctrlsLockRelease

		JMP	@loop

		RTS


;-------------------------------------------------------------------------------
mainPanic:
;-------------------------------------------------------------------------------
		JMP	mainPanic


;-------------------------------------------------------------------------------
inetInitialise:
;-------------------------------------------------------------------------------
		LDA	#INET_PROC_HALT
		STA	inetproc

		LDA	#INET_STATE_ERR
		STA	inetstat

		LDA	#INET_ERR_INTRF
		STA	ineterrk
		LDA	#INET_ERROR_INIT
		STA	ineterrc

		LDA 	#$00
		JSR 	drv_init
		
		JSR 	ip65_init
		BCC	:+

		JSR	clientOutputInetError
		RTS

:
		JSR 	dhcp_init
		BCC 	:+

		LDA	#INET_ERR_INTRN
		STA	ineterrk
		LDA	ip65_error
		STA	ineterrc
		
		JSR	clientOutputInetError
		RTS

:
		LDA	#INET_PROC_IDLE
		STA	inetproc

		LDA	#INET_STATE_NORM
		STA	inetstat

		LDA	#INET_ERR_NONE
		STA	ineterrk
		LDA	#INET_ERROR_NONE
		STA	ineterrc


		JSR	clientOutputInetConfig

		RTS


;-------------------------------------------------------------------------------
inetIdle:
;-------------------------------------------------------------------------------
		LDX	$7F
@sleep0:
		LDY	#$FF
@sleep1:
		DEY
		BNE	@sleep1
		DEX
		BPL	@sleep0
		
		RTS

	
	.export	inetConnect
;-------------------------------------------------------------------------------
inetConnect:
;-------------------------------------------------------------------------------
		LDA	#INET_PROC_HALT
		STA	inetproc

		LDA	#INET_STATE_ERR
		STA	inetstat

		LDA	#INET_ERR_INTRF
		STA	ineterrk
		LDA	#INET_ERROR_CNCT
		STA	ineterrc

		LDAX 	#edit_cnct_host_buf
		JSR 	dns_set_hostname
		
		BCC 	:+

@haveerror:		
		LDA	#INET_ERR_INTRN
		STA	ineterrk
		LDA	ip65_error
		STA	ineterrc
		
		JSR	clientOutputInetError
		RTS

; resolve host name
: 
		LDA 	dns_hostname_is_dotted_quad
		BNE 	:+
		
		JSR 	dns_resolve
		BCC 	:+
		
		JMP	@haveerror
		
: 
		LDAX 	#7632
		STAX 	inet_port

; connect
		LDAX 	#inet_callback
		STAX 	tcp_callback
	
		LDX 	#3
: 
		LDA 	dns_ip, X
		STA 	tcp_connect_ip, X
		
		DEX
  		BPL 	:-
		
		LDAX 	inet_port
		JSR 	tcp_connect
		BCC 	:+
	
		JMP	@haveerror

; connected
: 
		LDA 	#0
		STA 	connection_close_requested
		STA 	connection_closed
		STA 	data_received

		STA	readmsglen
  
;		LDA 	#abort_key_disable
;		STA 	abort_key

		LDA	#INET_PROC_EXEC
		STA	inetproc

		LDA	#INET_STATE_NORM
		STA	inetstat

		LDA	#INET_ERR_NONE
		STA	ineterrk
		LDA	#INET_ERROR_NONE
		STA	ineterrc
		
		JSR	clientOutputInetError

		JSR	ctrlsLockAcquire

		LDA	#<button_cnct_cnct
		STA	elemptr0
		LDA	#>button_cnct_cnct
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<button_cnct_dcnt
		STA	elemptr0
		LDA	#>button_cnct_dcnt
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		LDA	#<button_cnct_cnct
		CMP	actvCtrl
		BNE	@pick

		LDA	#>button_cnct_cnct
		CMP	actvCtrl + 1
		BNE	@pick

		JSR	ctrlsActivateCtrl

@pick:
		LDA	#<button_cnct_cnct
		CMP	pickCtrl
		BNE	@exit

		LDA	#>button_cnct_cnct
		CMP	pickCtrl + 1
		BNE	@exit

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1

@exit:
		LDA	#<button_cnct_upd
		STA	elemptr0
		LDA	#>button_cnct_upd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		JSR	ctrlsLockRelease

		RTS


;-------------------------------------------------------------------------------
inetDisconnect:
;-------------------------------------------------------------------------------
		JSR 	tcp_close

		LDA	#INET_PROC_DSCD
		STA	inetproc

		LDA	#INET_STATE_NORM
		STA	inetstat

		LDA	#INET_ERR_NONE
		STA	ineterrk

		LDA	#INET_ERROR_NONE
		STA	ineterrc

		RTS


;-------------------------------------------------------------------------------
inetDisconnected:
;-------------------------------------------------------------------------------
		LDA	#INET_PROC_IDLE
		STA	inetproc

		LDA	#INET_STATE_NORM
		STA	inetstat

		LDA	#INET_ERR_INTRF
		STA	ineterrk

		LDA	#INET_ERROR_DISC
		STA	ineterrc

		JSR	clientOutputInetError

		JSR	ctrlsLockAcquire

		LDA	#<button_cnct_dcnt
		STA	elemptr0
		LDA	#>button_cnct_dcnt
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<button_cnct_cnct
		STA	elemptr0
		LDA	#>button_cnct_cnct
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		LDA	#<button_cnct_dcnt
		CMP	actvCtrl
		BNE	@pick

		LDA	#>button_cnct_dcnt
		CMP	actvCtrl + 1
		BNE	@pick

		JSR	ctrlsActivateCtrl

@pick:
		LDA	#<button_cnct_dcnt
		CMP	pickCtrl
		BNE	@exit

		LDA	#>button_cnct_dcnt
		CMP	pickCtrl + 1
		BNE	@exit

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1

@exit:
		LDA	#<button_cnct_upd
		STA	elemptr0
		LDA	#>button_cnct_upd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		JSR	ctrlsLockRelease

		RTS


;-------------------------------------------------------------------------------
inetExecute:
;-------------------------------------------------------------------------------
		LDA	inetstat
		CMP	#INET_STATE_TICK
		BEQ	@check_timeout

		JSR 	timer_read
		
		TXA                           ; 1/1000 * 256 = ~ 1/4 seconds
		ADC 	#$20                  ; 32 x 1/4 = ~ 8 seconds
		
		STA 	inet_timeout

		LDA	#INET_STATE_TICK
		STA	inetstat
		
@check_timeout:
		LDA 	data_received
		BNE 	:+
  
		JSR 	timer_read
		CPX 	inet_timeout		;***TODO:  if no data and not timeout
		BNE 	:+			;	should sleep?
  
		JSR 	tcp_send_keep_alive
		
		LDA	#INET_STATE_NORM
		STA	inetstat
		RTS
		
: 
		LDA 	#0
		STA 	data_received
		JSR 	ip65_process
		
		LDA 	connection_close_requested
		BEQ 	@tstclosed
		
		LDA	#INET_PROC_DISC
		STA	inetproc

		LDA	#INET_STATE_NORM
		STA	inetstat

		LDA	#INET_ERR_NONE
		STA	ineterrk

		LDA	#INET_ERROR_NONE
		STA	ineterrc

		JMP 	@done
		
@tstclosed: 
		LDA 	connection_closed
		BNE 	@closed
		
		LDA	sendmsgscnt
		BNE	@send

		JMP	@done

		
@send:
		JSR	inetSendData
		JMP	@done

@closed:
;		LDA 	#abort_key_default
;		STA 	abort_key
		
		LDA	#INET_PROC_DSCD
		STA	inetproc

		LDA	#INET_STATE_NORM
		STA	inetstat

		LDA	#INET_ERR_NONE
		STA	ineterrk
		LDA	#INET_ERROR_NONE
		STA	ineterrc
	
@done:	
		
		RTS


;-------------------------------------------------------------------------------
sendmsgtable:
		.word	sendmsg0
		.word	sendmsg1
		.word	sendmsg2


;-------------------------------------------------------------------------------
inetGetNextSend:
;-------------------------------------------------------------------------------
		LDY	sendmsgscnt

	.if	DEBUG_MSGSPUSHSZ
		CPY	#$06
		BNE	@cont
		
		LDA	#$02
		STA	vicBrdrClr
		LDA	#$05
		STA	vicBkgdClr
		
		JMP	mainPanic

@cont:
	.endif

		LDA	sendmsgtable, Y
		STA	tempptr0
		INY
		LDA	sendmsgtable, Y
		STA	tempptr0 + 1
		INY

		STY	sendmsgscnt

		LDA	#$01
		STA	tempdat0

		RTS


	.export	inetSendData
;-------------------------------------------------------------------------------
inetSendData:
;-------------------------------------------------------------------------------
		LDY	#$00
		STY	senddat0

@loop:
		LDA	sendmsgtable, Y
		STA	sendptr0
		INY
		LDA	sendmsgtable, Y
		STA	sendptr0 + 1
		INY
		
		STY	senddat0

		LDY	#$00
		LDA	(sendptr0), Y

		STA	tcp_send_data_len
		INC	tcp_send_data_len

		LDA	#$00
		STA	tcp_send_data_len + 1

		LDA	sendptr0
		LDX	sendptr0 + 1
		JSR 	tcp_send
		BCS 	@error
		
		LDY	senddat0
		CPY	sendmsgscnt
		BNE	@loop

		JMP	@exit
		
		
@error:
		LDA 	ip65_error
		CMP 	#IP65_ERROR_CONNECTION_CLOSED
		BNE 	@errother
		
		LDA 	#1
		STA 	connection_closed
		
		JMP	@exit

@errother:
		LDA	#INET_PROC_HALT
		STA	inetproc

		LDA	#INET_STATE_ERR
		STA	inetstat

		LDA	#INET_ERR_INTRN
		STA	ineterrk

		LDA	ip65_error
		STA	ineterrc
		
		JSR	clientOutputInetError

@exit:
		LDA	#$00
		STA	sendmsgscnt

		RTS


	.export	inet_callback
;-------------------------------------------------------------------------------
inet_callback:
;-------------------------------------------------------------------------------
	.if	DEBUG_RASTERTIME
		LDA	vicBrdrClr
		PHA

		LDA	#$07
		STA	vicBrdrClr
	.endif

		LDA 	#1
		LDX 	tcp_inbound_data_length + 1
		CPX 	#$FF
		BNE 	@begin
		
		STA 	connection_closed
		JMP	@exit
		
@begin:
		STA 	data_received

		LDA 	tcp_inbound_data_length
		STAX	readmsgbuflen

		LDAX 	tcp_inbound_data_ptr
		STAX 	inetread

		LDY	#$00
		STY	readbufidx

		LDA	readmsglen
		BNE	@readmsg

@newmsg:
		LDY	#$00
		LDA	(inetread), Y
		STA	readmsg0, Y
		INY

		STY	readbufidx
		STY	readmsgidx

		TAY
		INY
		STY	readmsglen

		SEC	
		LDA	readmsgbuflen
		SBC	#$01
		STA	readmsgbuflen
		LDA	readmsgbuflen + 1
		SBC	#$00
		STA	readmsgbuflen + 1


;***TODO:	Sanity check len and idx??

@readmsg:
		LDY	readbufidx
		LDA	(inetread), Y
		INY
		STY	readbufidx

		LDY	readmsgidx
		STA	readmsg0, Y
		INY
		STY	readmsgidx

		SEC	
		LDA	readmsgbuflen
		SBC	#$01
		STA	readmsgbuflen
		LDA	readmsgbuflen + 1
		SBC	#$00
		STA	readmsgbuflen + 1

		LDY	readmsgidx
		CPY	readmsglen
		BNE	@tstbreak

		JSR	clientHandleReadMsg

		CLC
		LDA	inetread
		ADC	readmsglen
		STA	inetread
		LDA	inetread + 1
		ADC	#$00
		STA	inetread + 1

		LDA	#$00
		STA	readbufidx
		STA	readmsglen

@tstbreak:
		LDA	readmsgbuflen
		BNE	@tstnext
		LDA	readmsgbuflen + 1
		BEQ	@exit

@tstnext:
		LDA	readbufidx
		BEQ	@newmsg
		
		JMP	@readmsg

@exit:
	.if	DEBUG_RASTERTIME
		PLA
		STA	vicBrdrClr
	.endif

		RTS


;-------------------------------------------------------------------------------
inetScanReadParams:
;-------------------------------------------------------------------------------
		LDX	#$00
		STX	readparmcnt
		
		LDA	readmsg0
		TAY
		INY
		STY	tempvar_z
		
		CPY	#$02
		BNE	@proc
		
		RTS
		
@proc:
		LDY	#$02

@mark:
		TYA
		STA	readparm0, X
		INX
		
		STX	readparmcnt
		
		CPX	#$03
		BNE	@loop
		
		RTS

@loop:
		CPY	tempvar_z
		BNE	@cont
		
		RTS
		
@cont:
		LDA	readmsg0, Y
		
		INY
		
		CMP	#KEY_ASC_SPACE
		BNE	@loop
		
		JMP	@mark
	

;-------------------------------------------------------------------------------
clientMsgProcs:
			.word	clientProcSysMsg
			.word	clientProcTextMsg
			.word	clientProcLobbyMsg
			.word	clientProcConctMsg
			.word	clientProcClientMsg
			.word	clientProcServerMsg
			.word	clientProcPlayMsg

;-------------------------------------------------------------------------------
clientProcUnknownMsg:
;-------------------------------------------------------------------------------
		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_trace_unkmsg
		JSR	strsAppendString

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		RTS


;-------------------------------------------------------------------------------
clientSendIdent:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		LDA	#MSG_CATG_CLNT
		ORA	#$01

		JSR	strsAppendChar

		LDAX	#text_ident_vernam
		JSR	strsAppendString

		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar

		LDAX	#text_ident_pltfrm
		JSR	strsAppendString

		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar

		LDAX	#text_ident_verlbl
		JSR	strsAppendString
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS


;-------------------------------------------------------------------------------
clientSendUser:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		LDA	#MSG_CATG_CNCT
		ORA	#$01

		JSR	strsAppendChar

		LDAX	#edit_cnct_user_buf
		JSR	strsAppendString

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS


;-------------------------------------------------------------------------------
clientSendGetSysInfo:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		LDA	#MSG_CATG_TEXT
		ORA	#$00

		JSR	strsAppendChar

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS


;-------------------------------------------------------------------------------
clientProcSysMsg:
;-------------------------------------------------------------------------------
		RTS


;-------------------------------------------------------------------------------
clientProcTextMsgWhich:
;-------------------------------------------------------------------------------
		LDY	readparm1
		LDA	readmsg0, Y
		
		CMP	#'l'
		BNE	@tstplay
		
		LDA	#$0A
		JMP	@exit
		
@tstplay:
		CMP	#'p'
		BNE	@other
		
		LDA	#$14
		JMP	@exit
		
@other:
		LDA	#$00
		
@exit:
		STA	tempvar_z
		RTS


;-------------------------------------------------------------------------------
clientProcTextMsgClear:
;-------------------------------------------------------------------------------
		LDA	#$00
		TAX
@loop:
		STA	msglstsysid, Y
		STA	msglstsysloc, Y
		
		INY
		INX
		
		CPX	#$0A
		BNE	@loop

		RTS
		
		
;-------------------------------------------------------------------------------
clientProcTextMsgCopyID:
;-------------------------------------------------------------------------------
		LDY	readparm0
		LDX	#$00
@loop0:
		LDA	readmsg0, Y
		CMP	#KEY_ASC_SPACE
		BEQ	@store0
		
		STA	msglstid, X
		INX
		INY
		JMP	@loop0
		
@store0:
		INX
		STX	tempvar_y

		LDA	#$00
	
@loop1:
		CPX	#$0A
		BEQ	@exit

		STA	msglstid, X
		INX
		JMP	@loop1

@exit:
		RTS
		
	
;-------------------------------------------------------------------------------
clientProcTextMsgFind:
;-------------------------------------------------------------------------------
		LDX	#$09
		LDY	#$09
		
@loop0:
		LDA	msglstid, X
		STA	tempvar_z
		LDA	msglstsysid, Y
		
		DEY
		DEX
		BMI	@found0
		
		CMP	tempvar_z
		BEQ	@loop0

@tst1:
		LDX	#$09
		LDY	#$13
		
@loop1:
		LDA	msglstid, X
		STA	tempvar_z
		LDA	msglstsysid, Y
		
		DEY
		DEX
		BMI	@found1
		
		CMP	tempvar_z
		BEQ	@loop1
		
@tst2:
		LDX	#$09
		LDY	#$1D
		
@loop2:
		LDA	msglstid, X
		STA	tempvar_z
		LDA	msglstsysid, Y
		
		DEY
		DEX
		BMI	@found2
		
		CMP	tempvar_z
		BEQ	@loop2

		LDA	#$FF
		JMP	@exit
		
@found0:
		LDA	#$00
		JMP	@exit

@found1:
		LDA	#$0A
		JMP	@exit
		
@found2:
		LDA	#$14
		
@exit:
		STA	tempvar_z
		RTS
		

;-------------------------------------------------------------------------------
clientProcTextMsgBegin:
;-------------------------------------------------------------------------------
		JSR	clientProcTextMsgWhich
		TAY
		JSR	clientProcTextMsgClear
		
		JSR	clientProcTextMsgCopyID

		LDY	tempvar_z
		LDX	#$00
		
@loop1:
		LDA	msglstid, X
		STA	msglstsysid, Y
		
		INY
		INX
		CPX	tempvar_y
		BNE	@loop1

		LDA	readparmcnt
		CMP	#$03
		BNE	@finish
		
		LDA	readmsg0
		TAY
		INY
		STY	tempvar_x

		LDY	readparm2
		LDX	#$00
@loop2:
		LDA	readmsg0, Y
		CMP	#KEY_ASC_SPACE
		BEQ	@store1
		
		STA	msglstid, X
		INX
		INY
		
		CPY	tempvar_x
		BEQ	@store1
		
		JMP	@loop2
		
@store1:
		INX
		STX	tempvar_y
		
		LDY	tempvar_z
		LDX	#$00
		
@loop3:
		LDA	msglstid, X
		STA	msglstsysloc, Y
		
		INY
		INX
		CPX	tempvar_y
		BNE	@loop3

@finish:
		LDA	tempvar_z

		CMP	#$FF
		BEQ	@exit
	
		CMP	#$14
		BEQ	@play
		
		CMP	#$0A
		BEQ	@lobby
		
@system:
		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JMP	@output

@play:
@lobby:
;***TODO:	Load log panel pointer for appropriate log panel
		JMP	@exit

@output:
		JSR	ctrlsLogPanelGetNextLine

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

@exit:
		RTS


;-------------------------------------------------------------------------------
clientProcTextMsgMore:
;-------------------------------------------------------------------------------
;***TODO:	Output more message in appropriate log

		RTS


;-------------------------------------------------------------------------------
clientProcTextMsgData:
;-------------------------------------------------------------------------------
		JSR	clientProcTextMsgCopyID
		JSR	clientProcTextMsgFind
		
		CMP	#$FF
		BEQ	@exit
	
		CMP	#$10
		BEQ	@play
		
		CMP	#$08
		BEQ	@lobby
		
@system:
		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JMP	@output

@play:
;***TODO:	Logic for output list data to play log
		JMP	@exit

@lobby:
;***TODO:	Logic for output list data to lobby log
		JMP	@exit

@output:
		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_list_pref
		JSR	strsAppendString

		LDA	readparm1
		STA	tempdat1

		JSR	strsAppendMessage

		LDA	#$00
		JSR	strsAppendChar
		
		JSR	ctrlsLogPanelUpdate
				
@exit:
		RTS


;-------------------------------------------------------------------------------
clientProcTextMsg:
;-------------------------------------------------------------------------------
		LDA	tempdat2
		CMP	#$04
		BEQ	@whisper

		JSR	inetScanReadParams
		
		LDA	readparmcnt
		CMP	#$02
		BCC	@unknown
		
		LDA	tempdat2
		CMP	#$01
		BEQ	@begin
		
		CMP	#$02
		BEQ	@more
		
		CMP	#$03
		BEQ	@data
		
@unknown:
		JMP	clientProcUnknownMsg
		
@begin:
		JMP	clientProcTextMsgBegin

@more:
		JMP	clientProcTextMsgMore
		
@data:
		JMP	clientProcTextMsgData

@whisper:

;***TODO:	Add message to chat log with whisper notification

		RTS


;-------------------------------------------------------------------------------
clientProcLobbyMsg:
;-------------------------------------------------------------------------------
		RTS


;-------------------------------------------------------------------------------
clientProcConctMsg:
;-------------------------------------------------------------------------------
		LDA	tempdat2
		BNE	@tstnxt0

		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine

		LDAX 	#text_err_pref
		JSR	strsAppendString

		JSR	strsAppendMessage

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		RTS

@tstnxt0:
		CMP	#$01
		BEQ	@ident

		JMP	clientProcUnknownMsg
;		RTS

@ident:
;***TODO:	if there is one parameter, copy to user name string

		RTS


;-------------------------------------------------------------------------------
clientProcClientMsg:
;-------------------------------------------------------------------------------
		RTS


	.export	clientProcServerMsg
;-------------------------------------------------------------------------------
clientProcServerMsg:
;-------------------------------------------------------------------------------
		LDA	tempdat2
		BNE	@tstnxt0

		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_syserr_pref
		JSR	strsAppendString

		JSR	strsAppendMessage

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		RTS

@tstnxt0:
		CMP	#$01
		BEQ	@ident

		JMP	clientProcUnknownMsg
;		RTS

@ident:
;***TODO:	Fetch three strings from message and store as host info
		
		JSR	clientSendIdent
		JSR	clientSendUser
		JSR	clientSendGetSysInfo

		RTS


;-------------------------------------------------------------------------------
clientProcPlayMsg:
;-------------------------------------------------------------------------------
		RTS


	.export	clientHandleReadMsg
;-------------------------------------------------------------------------------
clientHandleReadMsg:
;-------------------------------------------------------------------------------
		JSR	ctrlsLockAcquire

		LDY	#$01
		LDA	readmsg0, Y

		AND	#$0F
		STA	tempdat2

		LDA	readmsg0, Y
		AND	#$F0
		LSR
		LSR
		LSR

		TAY

		LDA	clientMsgProcs, Y
		STA	@branch + 1
		LDA	clientMsgProcs + 1, Y
		STA	@branch + 2

		LDY	#$02
		STY	tempdat1	
		
@branch:
		JSR	clientHandleReadMsg

@exit:
		JSR	ctrlsLockRelease

		RTS


;-------------------------------------------------------------------------------
clientOutputInetConfig:
;-------------------------------------------------------------------------------
		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine
		LDAX	#text_trace_init
		JSR	strsAppendString

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_driver_pref
		JSR	strsAppendString

		LDAX 	#eth_driver_name
		JSR	strsAppendString

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelGetNextLine
		
		LDAX 	#text_iobase_pref
		JSR	strsAppendString
		
		LDA 	eth_driver_io_base + 1
		JSR 	strsAppendHex
		
		LDA 	eth_driver_io_base
		JSR 	strsAppendHex

		LDA	#$00
		JSR	strsAppendChar
		
		JSR	ctrlsLogPanelGetNextLine

		LDAX 	#text_ipcfg_pref
		JSR	strsAppendString

		LDAX 	#cfg_ip
		JSR 	strsAppendDottedQuad

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		RTS


;-------------------------------------------------------------------------------
clientOutputInetError:
;-------------------------------------------------------------------------------
		LDA	#<lpanel_cnct_log
		STA	tempptr2 
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine

		LDA	ineterrk
		CMP	#INET_ERR_NONE
		BEQ	@none

		CMP	#INET_ERR_INTRF
		BNE	@internal

		LDA	ineterrc
		CMP	#INET_ERROR_INIT
		BNE	@tstnxt0

		LDAX	#text_err_init
		JSR	strsAppendString
		JMP	@exit

@tstnxt0:
		CMP	#INET_ERROR_CNCT
		BNE	@tstnxt1

		LDAX	#text_err_cnct
		JSR	strsAppendString
		JMP	@exit

@tstnxt1:
		LDAX	#text_err_disc
		JSR	strsAppendString
		JMP	@exit

@none:
		LDAX	#text_err_okay
		JSR	strsAppendString
		JMP	@exit

@internal:
		LDA 	ineterrc
		CMP 	#IP65_ERROR_ABORTED_BY_USER
		BNE 	:+
		
		LDAX 	#text_err_abort
		JSR	strsAppendString
		JMP	@exit

: 
		CMP 	#IP65_ERROR_TIMEOUT_ON_RECEIVE
		BNE 	:+
  
		LDAX 	#text_err_timeout
		JSR 	strsAppendString
		JMP	@exit

: 
		LDAX 	#text_err_other
		JSR 	strsAppendString
		
		LDA 	ineterrc
		JSR 	strsAppendHex

@exit:
		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate
		RTS


;-------------------------------------------------------------------------------
clientInitLblPres:
;-------------------------------------------------------------------------------
		JSR	ctrlsControlDefPresent

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_VISIBLE
		BNE	@init

		LDA	#<panel_splsh_foot
		STA	elemptr0
		LDA	#>panel_splsh_foot
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate

		RTS

@init:
		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<button_splsh_cont
		STA	elemptr0
		LDA	#>button_splsh_cont
		STA	elemptr0 + 1
		
		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#INET_PROC_INIT
		STA	inetproc
		
@exit:
		RTS
		

;-------------------------------------------------------------------------------
clientSplshContChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	#<page_connect
		STA	elemptr0
		LDA	#>page_connect
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect

@exit:
		RTS


	.export	clientSplshContKeyPress
;-------------------------------------------------------------------------------
clientSplshContKeyPress:
;-------------------------------------------------------------------------------
		JSR	ctrlsDownCtrl

		RTS
		

	.export	clientCnctCnctChng
;-------------------------------------------------------------------------------
clientCnctCnctChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	inetproc
		BNE	@exit

		LDA	#<lpanel_cnct_log
		STA	tempptr2 
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_trace_cnct
		JSR	strsAppendString
		
		LDA	#$00
		LDY	tempdat0
		STA	(tempptr0), Y
		
		JSR	ctrlsLogPanelUpdate

		LDA	#INET_PROC_PCNT
		STA	inetproc

@exit:
		RTS


;-------------------------------------------------------------------------------
clientCnctDCntChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	inetproc
		CMP	#INET_PROC_EXEC
		BNE	@exit

		LDA	#INET_PROC_DISC
		STA	inetproc

@exit:
		RTS


;-------------------------------------------------------------------------------
clientMainUnsetTabs:
;-------------------------------------------------------------------------------
		LDX	#$05
@loop:
		LDA	tab_main_ctrls, X
		STA	tempptr0 + 1
		DEX
		LDA	tab_main_ctrls, X
		STA	tempptr0

		LDY	#ELEMENT::colour
		LDA	#CLR_FACE
		STA	(tempptr0), Y
		
		LDY	#ELEMENT::options
		LDA	(tempptr0), Y
		AND	#($FF ^ (OPT_NONAVIGATE))
		STA	(tempptr0), Y

		DEX
		BPL	@loop

		RTS

	
;-------------------------------------------------------------------------------
clientMainBeginChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDY	#ELEMENT::options
		LDA	tlabel_main_begin, Y
		AND	#OPT_NONAVIGATE
		BNE	@exit

		JSR	clientMainUnsetTabs

		LDY	#ELEMENT::colour
		LDA	#CLR_FOCUS
		STA	tlabel_main_begin, Y

		LDY	#ELEMENT::options
		LDA	#(OPT_NODOWNACTV | OPT_NONAVIGATE | OPT_TEXTACCEL2X)
		STA	tlabel_main_begin, Y

		SEI

		LDA	#<page_connect
		STA	elemptr0
		LDA	#>page_connect
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect

@exit:
		RTS


;-------------------------------------------------------------------------------
clientMainChatChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDY	#ELEMENT::options
		LDA	tlabel_main_chat, Y
		AND	#OPT_NONAVIGATE
		BNE	@exit

		JSR	clientMainUnsetTabs

		LDY	#ELEMENT::colour
		LDA	#CLR_FOCUS
		STA	tlabel_main_chat, Y

		LDY	#ELEMENT::options
		LDA	#(OPT_NODOWNACTV | OPT_NONAVIGATE | OPT_TEXTACCEL2X)
		STA	tlabel_main_chat, Y

		SEI
		LDA	#<page_room
		STA	elemptr0
		LDA	#>page_room
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect
@exit:

		RTS


;-------------------------------------------------------------------------------
clientRoomMoreChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_DOWN
		BNE	@down

		JSR	ctrlsControlInvalidate
		JMP	@exit
		
@down:
		LDA	(elemptr0), Y
		AND	#($FF ^ (STATE_DOWN | STATE_PICK | STATE_ACTIVE))
		STA	(elemptr0), Y

		LDA	#$00
		STA	downCtrl
		STA	downCtrl + 1

;		JSR	ctrlsControlInvalidate

		LDA	#<panel_room_more
		STA	elemptr0
		LDA	#>panel_room_more
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		
		LDA	#<panel_room_less
		STA	elemptr0
		LDA	#>panel_room_less
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState

;		JSR	userMouseUnPickCtrl
;		JSR	ctrlsDeactivateCtrl
		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1
;		STA	actvCtrl
;		STA	actvCtrl + 1

		LDA	#<edit_room_room
		STA	elemptr0
		LDA	#>edit_room_room
		STA	elemptr0 + 1
		
		JSR	ctrlsActivateCtrl

		LDA	#<panel_room_log
		STA	elemptr0
		LDA	#>panel_room_log
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::posy
		LDA	#$0A
		STA	(elemptr0), Y
		INY
		INY
		LDA	#$0D
		STA	(elemptr0), Y
		
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		
		AND	#STATE_CHANGED
		BNE	@exit

		LDA	(elemptr0), Y
		ORA	#STATE_CHANGED
		STA	(elemptr0), Y

		LDA	#$00
		STA	msgsdat1

		JSR	msgsPushChanging		
		
@exit:
		RTS
		
		
;-------------------------------------------------------------------------------
clientRoomLessChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_DOWN
		BNE	@down

		JSR	ctrlsControlInvalidate
		JMP	@exit
		
@down:
		LDA	(elemptr0), Y
		AND	#($FF ^ (STATE_DOWN | STATE_PICK | STATE_ACTIVE))
		STA	(elemptr0), Y

		LDA	#$00
		STA	downCtrl
		STA	downCtrl + 1
		
;		JSR	ctrlsControlInvalidate

		LDA	#<panel_room_less
		STA	elemptr0
		LDA	#>panel_room_less
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		
		LDA	#<panel_room_more
		STA	elemptr0
		LDA	#>panel_room_more
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState

;		JSR	userMouseUnPickCtrl
;		JSR	ctrlsDeactivateCtrl
		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1
;		STA	actvCtrl
;		STA	actvCtrl + 1

		LDA	#<edit_room_text
		STA	elemptr0
		LDA	#>edit_room_text
		STA	elemptr0 + 1
		
		JSR	ctrlsActivateCtrl

		LDA	#<panel_room_log
		STA	elemptr0
		LDA	#>panel_room_log
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::posy
		LDA	#$06
		STA	(elemptr0), Y
		INY
		INY
		LDA	#$11
		STA	(elemptr0), Y
		
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		
		AND	#STATE_CHANGED
		BNE	@exit

		LDA	(elemptr0), Y
		ORA	#STATE_CHANGED
		STA	(elemptr0), Y

		LDA	#$00
		STA	msgsdat1

		JSR	msgsPushChanging		
		
@exit:
		RTS


	.export	initCore
;-------------------------------------------------------------------------------
initCore:
;-------------------------------------------------------------------------------
		JSR	initMem
		JSR	initSprites
		
		JSR	initUser

		LDA	#INET_PROC_HALT
		STA	inetproc
		LDA	#INET_STATE_NORM
		STA	inetstat
		LDA	#INET_ERR_NONE
		STA	ineterrk
		LDA	#INET_ERROR_NONE
		STA	ineterrc

		RTS
		

;-------------------------------------------------------------------------------
initMem:
;-------------------------------------------------------------------------------
;	Bank out BASIC + Kernal (keep IO).  First, make sure that the IO port
;	is set to output on those lines.
		LDA	$00
		ORA	#$07
		STA	$00
		
;	Now, exclude BASIC + KERNAL from the memory map (include only IO)
;		LDA	$01
;		AND	#$FC
;		ORA	#$01
		LDA	#$1D
		STA	$01		
		
		LDA	#<sprPointer0
		STA	tempptr0
		LDA	#>sprPointer0
		STA	tempptr0 + 1
		
		LDA	#<spriteMem20		
		STA	tempptr1
		LDA	#>spriteMem20
		STA	tempptr1 + 1
		
		LDY	#$0F
@loop5:						;Copy mouse pointer data
		LDA	(tempptr0), Y
		STA	(tempptr1), Y
		
		DEY
		BPL	@loop5

		LDA	#$00

		STA	ctrlsLock
		STA	ctrlsLCnt

		STA	pageptr0
		STA	pageptr0 + 1

		STA	downCtrl
		STA	downCtrl + 1
		STA	pickCtrl
		STA	pickCtrl + 1

		STA	msgs_change_idx
		STA	msgs_dirty_idx

		STA	sendmsgscnt
		STA	readmsglen
		STA	readmsgidx

		STA	keyZPKeyDown
		STA	keyZPKeyCount
		STA	keyZPKeyScan
		STA	keyZPDecodePtr
		STA	keyZPDecodePtr + 1

		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1

		JSR	ctrlsLogPanelInit

		LDA	#$00
		STA	keyRepeatFlag
;		LDA	#$80
;		STA	keyModifierLock
		LDA	#$14
		STA	keyBufferSize
		RTS


;-------------------------------------------------------------------------------
initSprites:
;-------------------------------------------------------------------------------
		LDA	#$20
		STA	spritePtr0
		LDA	#$21
		STA	spritePtr1
		LDA	#$22
		STA	spritePtr2
		LDA	#$23
		STA	spritePtr3

		LDA	#$00			;MCM none
		STA	vicSprCMod
		STA	vicSprExpX		
		STA	vicSprExpY

		LDA	#$0F			;sprites
		STA	vicSprEnab

		RTS

;-------------------------------------------------------------------------------
initUser:
;-------------------------------------------------------------------------------
		JSR	CMOVEX
		JSR	CMOVEY
		
		JSR	userIRQInstall

		RTS
		

screenRowsLo:
			.byte	<$0400, <$0428, <$0450, <$0478, <$04A0
			.byte	<$04C8, <$04F0, <$0518, <$0540, <$0568
			.byte 	<$0590, <$05B8, <$05E0, <$0608, <$0630
			.byte	<$0658, <$0680, <$06A8, <$06D0, <$06F8
			.byte	<$0720, <$0748, <$0770, <$0798, <$07C0

screenRowsHi:
			.byte	>$0400, >$0428, >$0450, >$0478, >$04A0
			.byte	>$04C8, >$04F0, >$0518, >$0540, >$0568
			.byte 	>$0590, >$05B8, >$05E0, >$0608, >$0630
			.byte	>$0658, >$0680, >$06A8, >$06D0, >$06F8
			.byte	>$0720, >$0748, >$0770, >$0798, >$07C0

;colourRowsLo:
;			.byte	<$D800, <$D828, <$D850, <$D878, <$D8A0
;			.byte	<$D8C8, <$D8F0, <$D918, <$D940, <$D968
;			.byte 	<$D990, <$D9B8, <$D9E0, <$DA08, <$DA30
;			.byte	<$DA58, <$DA80, <$DAA8, <$DAD0, <$DAF8
;			.byte	<$DB20, <$DB48, <$DB70, <$DB98, <$DBC0

colourRowsHi:
			.byte	>$D800, >$D828, >$D850, >$D878, >$D8A0
			.byte	>$D8C8, >$D8F0, >$D918, >$D940, >$D968
			.byte 	>$D990, >$D9B8, >$D9E0, >$DA08, >$DA30
			.byte	>$DA58, >$DA80, >$DAA8, >$DAD0, >$DAF8
			.byte	>$DB20, >$DB48, >$DB70, >$DB98, >$DBC0

screenASCIIXLAT:
	.byte	KEY_ASC_BSLASH, KEY_ASC_CARET, KEY_ASC_USCORE, KEY_ASC_BQUOTE
	.byte	KEY_ASC_OCRLYB, KEY_ASC_PIPE, KEY_ASC_CCRLYB, KEY_ASC_TILDE, $00
screenASCIIXLATSub:
	.byte	$4D, $71, $64, $4A ,$55, $5D, $49, $45, $00


	.export	screenIsRevColour
;-------------------------------------------------------------------------------
screenIsRevColour:
;-------------------------------------------------------------------------------
		PHA
		LDA	#$20
		STA	tempbit0
		PLA

		CMP	#$01
		BMI	@text
	
		CMP	#$10
		BMI	@ctrl

		BIT	tempbit0
		BEQ	@text

@ctrl:
		SEC
		RTS
		
@text:
		CLC
		RTS


;-------------------------------------------------------------------------------
screenCtrlToLogClr:
;-------------------------------------------------------------------------------
		PHA
		LDA	#$30
		STA	tempbit0
		PLA

		BIT	tempbit0
		BEQ	@ctrl
		
		AND	#$0F
		RTS
		
@ctrl:
		CMP	#$FD
		BNE	@other
		
		LDA	#$00
		RTS
		
@other:
		TAX
		INX
		INX
		LDA	current_clrs, X
		RTS
		
		
	.export	screenASCIIToScreen
;-------------------------------------------------------------------------------
screenASCIIToScreen:
;-------------------------------------------------------------------------------
		STA	tempvar_z
		LDY	#$07
@loop:
		LDA	screenASCIIXLAT, Y
		CMP	tempvar_z
		BEQ	@subst
		DEY
		BPL	@loop

		LDA	tempvar_z
		
		CMP	#$20
		BCS	@regular

@irregular:
		LDA	#$66
		RTS

@regular:
		CMP	#$7F
		BCS	@irregular

		CMP	#$40
		BCC	@exit
	
		CMP	#$60
		BCC	@upper
	
		SEC
		SBC	#$60
		
		RTS

@upper:
		SEC
		SBC	#$40
		
@exit:
		RTS

@subst:
		LDA	screenASCIIXLATSub, Y
		RTS


;-------------------------------------------------------------------------------
colourSchemeSelect:
;-------------------------------------------------------------------------------
		TAY
		
		LDA	#<clrschme_lst
		STA	tempptr0
		LDA	#>clrschme_lst
		STA	tempptr0 + 1
		
		TYA
		ASL
		ASL
		TAY
		
		LDA	(tempptr0), Y
		STA	tempptr1
		INY
		LDA	(tempptr0), Y
		STA	tempptr1 + 1 
	
		LDY	#$09
@loop:
		LDA	(tempptr1), Y
		STA	current_clrs, Y
		
		DEY
		BPL	@loop
		
		LDA	#$00
		STA	vicBkgdClr
		STA	vicSprClr0
		
		LDY	#$00
		LDA	current_clrs, Y
		STA	vicBrdrClr
		
		INY
		LDA	current_clrs, Y
		STA	vicSprClr3		
		
		LDY	#$03
		LDA	current_clrs, Y
		STA	vicSprClr1

		LDY	#$06
		LDA	current_clrs, Y
		STA	vicSprClr2
		
		RTS


;-------------------------------------------------------------------------------
strsAppendChar:
;-------------------------------------------------------------------------------
		LDY	tempdat0
		STA	(tempptr0), Y

		INC	tempdat0

		RTS


;-------------------------------------------------------------------------------
strsAppendString:
;-------------------------------------------------------------------------------
		STA	tempptr1
		STX	tempptr1 + 1

		LDY	#$00

@loop:
		LDA	(tempptr1), Y
		BEQ	@exit

		INY
		STY	tempdat3

		LDY	tempdat0
		STA	(tempptr0), Y
		INY
		STY	tempdat0

		LDY	tempdat3

		JMP	@loop

@exit:
		RTS


;-------------------------------------------------------------------------------
strsAppendMessage:
;-------------------------------------------------------------------------------
		LDY	tempdat1
@loop:
		LDA 	readmsg0, Y
		INY
		STY	tempdat1
		
		LDY	tempdat0
		STA	(tempptr0), Y
		INY
		STY	tempdat0

		LDY	tempdat1
		CPY	readmsglen
		BNE	@loop

		RTS


;-------------------------------------------------------------------------------
strsAppendInteger:
;-------------------------------------------------------------------------------
                ; print 16 bit number in AX as a decimal number
;hex to bcd routine taken from Andrew Jacob's code at http://www.6502.org/source/integers/hex2dec-more.htm
		STAX 	temp_bin
		SED                           ; Switch to decimal mode
		LDA 	#0                        ; Ensure the result is clear		
		STA 	temp_bcd
		STA 	temp_bcd+1
		STA 	temp_bcd+2
		LDX 	#16                       ; The number of source bits
: 
		ASL 	temp_bin+0                ; Shift out one bit
		ROL 	temp_bin+1
		LDA 	temp_bcd+0                ; And add into result
		ADC 	temp_bcd+0
		STA 	temp_bcd+0
		LDA 	temp_bcd+1                ; propagating any carry
		ADC 	temp_bcd+1
		STA 	temp_bcd+1
		LDA 	temp_bcd+2                ; ... thru whole result
		ADC 	temp_bcd+2
		STA 	temp_bcd+2

		DEX                           ; And repeat for next bit
		BNE 	:-

		STX 	temp_bin+1                ; x is now zero - reuse temp_bin as a count of non-zero digits
		CLD                           ; back to binary
		LDX 	#2
		STX 	temp_bin+1                ; reuse temp_bin+1 as loop counter
@print_one_byte:
		LDX 	temp_bin+1
		LDA 	temp_bcd,x
		PHA
		LSR
		LSR
		LSR
		LSR
		JSR 	@print_one_digit
		PLA
		AND 	#$0F
		JSR 	@print_one_digit
		DEC 	temp_bin+1
		BPL 	@print_one_byte
		RTS

@print_one_digit:
		CMP 	#0
		BEQ 	@this_digit_is_zero
		INC 	temp_bin                  ; increment count of non-zero digits
@ok_to_print:
		CLC
		ADC 	#'0'
		JSR 	strsAppendChar
		RTS
@this_digit_is_zero:
		LDX 	temp_bin                  ; how many non-zero digits have we printed?
		BNE 	@ok_to_print
		LDX 	temp_bin+1                ; how many digits are left to print?
		BNE 	@this_is_not_last_digit
		INC 	temp_bin                  ; to get to this point, this must be the high nibble of the last byte.
                                ; by making 'count of non-zero digits' to be >0, we force printing of the last digit
@this_is_not_last_digit:
		RTS


;-------------------------------------------------------------------------------
strsAppendHex:
;-------------------------------------------------------------------------------
		PHA
		PHA
		LSR
		LSR
		LSR
		LSR
		TAX
		LDA 	hexdigits, X
		JSR 	strsAppendChar
		PLA
		AND 	#$0F
		TAX
		LDA 	hexdigits, X
		JSR 	strsAppendChar
		PLA
		RTS


;-------------------------------------------------------------------------------
strsAppendDottedQuad:
;-------------------------------------------------------------------------------
		STA 	tempptr1
		STX 	tempptr1 + 1
		LDA 	#0
@print_one_byte:
		PHA
		TAY
		LDA 	(tempptr1), Y
		LDX 	#0
		JSR 	strsAppendInteger
		PLA
		CMP 	#3
		BEQ 	@done
		CLC
		ADC 	#1
		PHA
		LDA 	#'.'
		JSR 	strsAppendChar
		PLA
		BNE 	@print_one_byte
@done:
		RTS


	.export	msgsPushChanging
;-------------------------------------------------------------------------------
msgsPushChanging:
;-------------------------------------------------------------------------------
		LDY	msgs_change_idx	

		LDA	elemptr0
		STA	msgs_change, Y
		INY
		LDA	elemptr0 + 1
		STA	msgs_change, Y
		INY
		LDA	msgsdat0
		STA	msgs_change, Y
		INY
		LDA	msgsdat1
		STA	msgs_change, Y
		INY
		
		STY	msgs_change_idx	

	.if	DEBUG_MSGSPUSHSZ
		BNE	@exit
		
		LDA	#$02
		STA	vicBrdrClr
		LDA	#$03
		STA	vicBkgdClr
		
		JMP	mainPanic

@exit:
	.endif

		RTS



	.export	msgsPushChanging
;-------------------------------------------------------------------------------
msgsPushInvalid:
;-------------------------------------------------------------------------------
		LDY	msgs_dirty_idx	

		LDA	elemptr0
		STA	msgs_dirty, Y
		INY
		LDA	elemptr0 + 1
		STA	msgs_dirty, Y
		INY
		LDA	msgsdat0
		STA	msgs_dirty, Y
		INY
		LDA	msgsdat1
		STA	msgs_dirty, Y
		INY
		
		STY	msgs_dirty_idx	

	.if	DEBUG_MSGSPUSHSZ
		BNE	@exit
		
		LDA	#$02
		STA	vicBrdrClr
		LDA	#$04
		STA	vicBkgdClr

		JMP	mainPanic

@exit:
	.endif
		RTS


;-------------------------------------------------------------------------------
ctrlsLockAcquire:
;-------------------------------------------------------------------------------
		SEI
		LDA	#$01
		STA	ctrlsLock

		INC	ctrlsLCnt

		CLI

		RTS


;-------------------------------------------------------------------------------
ctrlsLockRelease:
;-------------------------------------------------------------------------------
		SEI

		DEC	ctrlsLCnt
		LDA	ctrlsLCnt
		BNE	@exit
		
		LDA	#$00
		STA	ctrlsLock

@exit:
		CLI

		RTS


;-------------------------------------------------------------------------------
ctrlsUnDownCtrl:
;-------------------------------------------------------------------------------
		LDA	downCtrl + 1
		BEQ	@exit

		LDA	downCtrl
		STA	elemptr0
		LDA	downCtrl + 1
		STA	elemptr0 + 1

		LDA	#STATE_DOWN
		JSR	ctrlsExcludeState

		LDA	#$00
		STA	downCtrl
		STA	downCtrl + 1

@exit:
		RTS


;-------------------------------------------------------------------------------
ctrlsDownCtrl:
;-------------------------------------------------------------------------------
		LDA	elemptr0
		STA	tempptr0
		LDA	elemptr0 + 1
		STA	tempptr0 + 1

		JSR	ctrlsUnDownCtrl

		LDY	#ELEMENT::options
		LDA	(tempptr0), Y
		AND	#OPT_NONAVIGATE
		BNE	@nodeact

		JSR	ctrlsDeactivateCtrl

@nodeact:
		LDA	tempptr0
		STA	elemptr0
		LDA	tempptr0 + 1
		STA	elemptr0 + 1

		LDA	#STATE_DOWN
		JSR	ctrlsIncludeState

		LDA	elemptr0
		STA	downCtrl
		LDA	elemptr0 + 1
		STA	downCtrl + 1

		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_NONAVIGATE
		BNE	@noact

		JSR	ctrlsActivateCtrl

@noact:
		RTS


;-------------------------------------------------------------------------------
ctrlsDeactivateCtrl:
;-------------------------------------------------------------------------------
		LDA	actvCtrl + 1
		BEQ	@exit

		STA	elemptr0 + 1
		LDA	actvCtrl
		STA	elemptr0

		LDA	#STATE_ACTIVE
		JSR	ctrlsExcludeState

		LDA	#$00
		STA	actvCtrl
		STA	actvCtrl + 1

@exit:
		RTS


;-------------------------------------------------------------------------------
ctrlsActivateCtrlSimple:
;-------------------------------------------------------------------------------
		LDA	elemptr0
		STA	tempptr0
		LDA	elemptr0 + 1
		STA	tempptr0 + 1

		JSR	ctrlsDeactivateCtrl
		
		LDA	tempptr0
		STA	elemptr0
		LDA	tempptr0 + 1
		STA	elemptr0 + 1

		LDA	#STATE_ACTIVE
		JSR	ctrlsIncludeState

		LDA	elemptr0
		STA	actvCtrl
		LDA	elemptr0 + 1
		STA	actvCtrl + 1

		RTS


;-------------------------------------------------------------------------------
ctrlsActivateCtrl:
;-------------------------------------------------------------------------------
		JSR	ctrlsActivateCtrlSimple
		
		LDY	#CONTROL::panel
		LDA	(elemptr0), Y
		STA	tempptr0
		INY
		LDA	(elemptr0), Y
		STA	tempptr0 + 1
		
		LDY	#PANEL::controls
		LDA	(tempptr0), Y
		STA	tempptr1
		INY
		LDA	(tempptr0), Y
		STA	tempptr1 + 1
		
		LDY	#$00
@loopc:
		STY	actvctrlc
		
		LDA	(tempptr1), Y
		INY
		
		CMP	elemptr0
		BNE	@nextc
		
		LDA	(tempptr1), Y
		BEQ	@donec
		
		CMP	elemptr0 + 1
		BEQ	@donec
		
@nextc:
		INY
		JMP	@loopc
		
@donec:
		LDY	#PANEL::page
		LDA	(tempptr0), Y
		STA	tempptr1
		INY
		LDA	(tempptr0), Y
		STA	tempptr1 + 1
		
		LDY	#PAGE::panels
		LDA	(tempptr1), Y
		STA	tempptr2
		INY
		LDA	(tempptr1), Y
		STA	tempptr2 + 1
		
		LDY	#$00
@loopp:
		STY	actvctrlp
		
		LDA	(tempptr2), Y
		INY
		
		CMP	tempptr0
		BNE	@nextp
		
		LDA	(tempptr2), Y
		BEQ	@donep
		
		CMP	tempptr0 + 1
		BEQ	@donep
		
@nextp:
		INY
		JMP	@loopp
		
@donep:
		RTS


	.export	ctrlsControlInvalidate
;-------------------------------------------------------------------------------
ctrlsControlInvalidate:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_DIRTY
		BNE	@exit

		LDA	(elemptr0), Y
		ORA	#STATE_DIRTY
		STA	(elemptr0), Y

		LDA	#$00
		STA	msgsdat0
		STA	msgsdat1

		JSR	msgsPushInvalid
		
@exit:
		RTS


;-------------------------------------------------------------------------------
ctrlsExcludeState:
;-------------------------------------------------------------------------------
		STA	tempdat0
		EOR	#$FF
		STA	tempdat1

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	tempdat0
		BEQ	@exit

		LDA	(elemptr0), Y
		STA	msgsdat0
		AND	tempdat1
		STA	(elemptr0), Y
		
		AND	#STATE_CHANGED
		BNE	@exit

		LDA	(elemptr0), Y
		ORA	#STATE_CHANGED
		STA	(elemptr0), Y

		LDA	#$00
		STA	msgsdat1

		JSR	msgsPushChanging
	
@exit:	
		RTS


;-------------------------------------------------------------------------------
ctrlsIncludeState:
;-------------------------------------------------------------------------------
		STA	tempdat0

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	tempdat0
		BNE	@exit

		LDA	(elemptr0), Y
		STA	msgsdat0
		ORA	tempdat0
		STA	(elemptr0), Y
		
		AND	#STATE_CHANGED
		BNE	@exit

		LDA	(elemptr0), Y
		ORA	#STATE_CHANGED
		STA	(elemptr0), Y

		LDA	#$00
		STA	msgsdat1

		JSR	msgsPushChanging
		
@exit:
		RTS


	.export	ctrlsDrawAccel
;-------------------------------------------------------------------------------
ctrlsDrawAccel:
;-------------------------------------------------------------------------------
		LDY	#CONTROL::textaccel
		LDA	(elemptr0), Y
		CMP	#$FF
		BEQ	@exit

		STA	tempvar_c

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_ENABLED
		BEQ	@exit

		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		
		CLC
		ADC	tempvar_c
		STA	tempvar_a		;x + textaccel
		
		INY
		LDA	(elemptr0), Y
		STA	tempvar_b		;y
		
		LDA	#CLR_FOCUS
		JSR	screenCtrlToLogClr	
		STA	tempvar_e		;logical colour

		LDX	tempvar_b
		LDA	screenRowsLo, X
		STA	tempptr1		;colour ptr
		LDA	colourRowsHi, X
		STA	tempptr1 + 1

		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_TEXTACCEL2X
		STA	tempvar_d

		LDY	tempvar_a
		LDA	tempvar_e
		STA	(tempptr1), Y
		
		LDX	tempvar_d
		BEQ	@exit
		
		INY
		STA	(tempptr1), Y

@exit:
		RTS
		

	.export	ctrlsEraseBkg
;-------------------------------------------------------------------------------
ctrlsEraseBkg:
;-------------------------------------------------------------------------------
		STA	tempvar_e		;colour

		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_a		;x
		INY
		LDA	(elemptr0), Y
		STA	tempvar_b		;y
		INY
		LDA	(elemptr0), Y
		STA	tempvar_c		;w
		INY
		LDA	(elemptr0), Y
		STA	tempvar_d		;h
		
		LDA	tempvar_e
		
		JSR	screenIsRevColour
		BCC	@text
		
		LDA	#$A0
		JMP	@cont
		
@text:
		LDA	#$20
		
@cont:
		STA	tempvar_f		;background char

		LDA	tempvar_e
		JSR	screenCtrlToLogClr	
		STA	tempvar_e		;logical colour

@looph:
		LDX	tempvar_b
		LDA	screenRowsLo, X
		STA	tempptr0		;screen ptr
		STA	tempptr1		;colour ptr
		LDA	screenRowsHi, X
		STA	tempptr0 + 1
		LDA	colourRowsHi, X
		STA	tempptr1 + 1
	
		LDY	tempvar_a
		LDX	tempvar_c
		DEX
		
@loopw:
		LDA	tempvar_f		;char to screen ram
		STA	(tempptr0), Y
		
		LDA	tempvar_e		;colour to colour ram
		STA	(tempptr1), Y
		
		INY
		DEX
		BPL	@loopw
		
		INC	tempvar_b
		DEC	tempvar_d
		LDA	tempvar_d
		BNE	@looph
		
		RTS
		

;-------------------------------------------------------------------------------
ctrlsDrawText:
;	IN	tempdat0	Colour
;	IN	tempdat1	Indent
;	IN	tempdat2	Max width
;	IN	tempdat3	Do cont char if opt
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_a		;x
		INY
		LDA	(elemptr0), Y
		STA	tempvar_b		;y
		INY
		
		LDY	#CONTROL::textptr
		LDA	(elemptr0), Y
		STA	tempptr1		;text lo
		INY
		LDA	(elemptr0), Y
		
		BNE	@calc0
		
;		JMP	@exit
		RTS
		
@calc0:
		STA	tempptr1 + 1		;text hi
		INY
		LDA	(elemptr0), Y		;
		STA	tempvar_d		;text off x


;---	Not doing accelerators here anymore
;		INY
;		LDA	(elemptr0), Y		;text accel
;		
;		CMP	#$FF
;		BEQ	@cont0
;		
;@wantaccel:
;		CLC
;		ADC	tempvar_a
;
;@cont0:
;		STA	tempvar_c		;text accel x/off
;---

;-------------------------------------------------------------------------------
ctrlsDrawTextDirect:
;	IN	tempdat0	Colour
;	IN	tempdat1	Indent
;	IN	tempdat2	Max width
;	IN	tempdat3	Do cont char if opt
;	IN	tempvar_a	x pos
;	IN	tempvar_b	y pos
;	IN	tempvar_d	text off x
;	IN	tempptr1	text pointer
;-------------------------------------------------------------------------------

		CLC
		LDA	tempvar_d
		ADC	tempvar_a
		STA	tempvar_a		;x

		LDA	tempdat0
		JSR	screenIsRevColour
		BCC	@text
		
		LDA	#$80
		JMP	@cont1
		
@text:
		LDA	#$00
		
@cont1:
		STA	tempvar_f		;char or

		LDX	tempvar_b
		LDA	screenRowsLo, X
		STA	tempptr0		;screen ptr
		LDA	screenRowsHi, X
		STA	tempptr0 + 1

		LDA	tempdat3
		BEQ	@cont2
	
		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_TEXTCONTMRK
		BEQ	@cont2

		DEC	tempdat2

@cont2:
		LDA	tempdat1		;text indent
		STA	tempvar_e

		LDX	#$00
	
@loopw:
		LDY	tempvar_e
		LDA	(tempptr1), Y		;char 
		
		BEQ	@exit
		
		JSR	screenASCIIToScreen
		ORA	tempvar_f
		
		LDY	tempvar_a
		STA	(tempptr0), Y
		
		INC	tempvar_a
		INC	tempvar_e

		INX
		CPX	tempdat2
		BCS	@contchk

		JMP	@loopw

@contchk:
		LDA	tempdat3
		BEQ	@exit

		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_TEXTCONTMRK
		BEQ	@exit

		LDA	#'>'
		JSR	screenASCIIToScreen
		ORA	tempvar_f
		
		LDY	tempvar_a
		STA	(tempptr0), Y

@exit:
		RTS
		
		
	.export	ctrlsPageSelect
;-------------------------------------------------------------------------------
ctrlsPageSelect:
;-------------------------------------------------------------------------------
		SEI
		LDA	#$01
		STA	ctrlsPrep
		CLI

		LDA	pageptr0 + 1
		BEQ	@cont0

		LDY	#ELEMENT::state
		LDA	(pageptr0), Y
		AND	#($FF ^ STATE_VISIBLE)
		STA	(pageptr0), Y

@cont0:
		LDA	elemptr0
		STA	pageptr0
		LDA	elemptr0 + 1
		STA	pageptr0 + 1

		LDY	#ELEMENT::state
		LDA	(pageptr0), Y
		ORA	#STATE_VISIBLE
		STA	(pageptr0), Y

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1
		STA	downCtrl 
		STA	downCtrl + 1
		STA	actvCtrl
		STA	actvCtrl + 1

		LDY	#PAGE::textptr
		LDA	(pageptr0), Y
		STA	tempvar_a		;textptr lo
		INY
		LDA	(pageptr0), Y
		STA	tempvar_b		;textptr hi
		INY
		LDA	(pageptr0), Y
		STA	tempvar_c		;textoffx
		
		LDY	#CONTROL::textptr
		LDA	tempvar_a
		STA	hlabel_main_page, Y
		INY
		LDA	tempvar_b
		STA	hlabel_main_page, Y
		INY
		LDA	tempvar_c
		STA	hlabel_main_page, Y
		
		LDY	#PANEL::page
		LDA	pageptr0
		STA	tab_main, Y
		INY
		LDA	pageptr0 + 1
		STA	tab_main, Y

		RTS
	

;-------------------------------------------------------------------------------
ctrlsDisposeMsgs:
;-------------------------------------------------------------------------------
		LDA	msgs_change_idx
		BEQ	@dirty

		LDY	#$00

@loop0:
		LDA	msgs_change, Y
		STA	elemptr0
		INY
		LDA	msgs_change, Y
		STA	elemptr0 + 1
		INY
		INY
		INY
	
		STY	ctrlvar_a

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#($FF ^ STATE_CHANGED)
		STA	(elemptr0), Y

		LDY	ctrlvar_a
		CPY	msgs_change_idx
		BNE	@loop0
		
		LDA	#$00
		STA	msgs_change_idx

@dirty:
		LDA	msgs_dirty_idx
		BEQ	@exit

		LDY	#$00

@loop1:
		LDA	msgs_dirty, Y
		STA	elemptr0
		INY
		LDA	msgs_dirty, Y
		STA	elemptr0 + 1
		INY
		INY
		INY
	
		STY	ctrlvar_a

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#($FF ^ STATE_DIRTY)
		STA	(elemptr0), Y

		LDY	ctrlvar_a
		CPY	msgs_dirty_idx
		BNE	@loop1

		LDA	#$00
		STA	msgs_dirty_idx

@exit:
		RTS


	.export	ctrlsLogPanelInit
;-------------------------------------------------------------------------------
ctrlsLogPanelInit:
;-------------------------------------------------------------------------------
		LDY	#LOGPANEL::lines
		LDA	(tempptr2), Y
		STA	tempptr1
		INY
		LDA	(tempptr2), Y
		STA	tempptr1 + 1

		LDY	#ELEMENT::height
		LDA	(tempptr2), Y
		ASL
		
		TAY
		DEY
@loop:
		LDA	(tempptr1), Y
		STA	tempptr0 + 1
		DEY
		LDA	(tempptr1), Y
		STA	tempptr0
		DEY

		TYA
		TAX

		LDA	#$00
		LDY	#$00
		STA	(tempptr0), Y
		
		TXA
		TAY

		BPL	@loop
		
		RTS


	.export	ctrlsLogPanelGetNextLine
;-------------------------------------------------------------------------------
ctrlsLogPanelGetNextLine:
;-------------------------------------------------------------------------------
		LDY	#LOGPANEL::currln
		LDA	(tempptr2), Y
		STA	tempvar_a

		INC	tempvar_a

		LDY	#LOGPANEL::lines
		LDA	(tempptr2), Y
		STA	tempptr1
		INY
		LDA	(tempptr2), Y
		STA	tempptr1 + 1

		LDY	#ELEMENT::height
		LDA	(tempptr2), Y

		CMP	tempvar_a
		BCS	@havenext

		ASL	
		STA	tempvar_b
		DEC	tempvar_a

		LDY	#$00
		LDA	(tempptr1), Y
		STA	tempptr0
		INY
		LDA	(tempptr1), Y
		STA	tempptr0 + 1

		LDY	#$02
@loop:
		LDA	(tempptr1), Y
		STA	tempvar_c
		INY
		LDA	(tempptr1), Y
		STA	tempvar_d
		
		DEY
		DEY
		DEY
		
		LDA	tempvar_c
		STA	(tempptr1), Y
		INY
		LDA	tempvar_d
		STA	(tempptr1), Y
		
		INY
		INY
		INY

		CPY	tempvar_b
		BNE	@loop
	
		DEY
		DEY

		LDA	tempptr0
		STA	(tempptr1), Y
		INY
		LDA	tempptr0 + 1
		STA	(tempptr1), Y

@havenext:
		DEC	tempvar_a
		LDA	tempvar_a
		ASL	
		TAY

		LDA	(tempptr1), Y
		STA	tempptr0
		INY
 		LDA	(tempptr1), Y
		STA	tempptr0 + 1
		INY

		STY	tempvar_a
		
		LDA	#$00
		STA	tempdat0

		LDY	#LOGPANEL::currln
		LDA	tempvar_a
		LSR
		STA	(tempptr2), Y
		
		RTS

	
	.export	ctrlsLogPanelUpdate
;-------------------------------------------------------------------------------
ctrlsLogPanelUpdate:
;-------------------------------------------------------------------------------
		LDY	#PANEL::page
		LDA	(tempptr2), Y
		STA	tempptr1
		INY
		LDA	(tempptr2), Y
		STA	tempptr1 + 1

;		LDY	#ELEMENT::state
;		LDA	(tempptr1), Y
;		AND	#STATE_VISIBLE
;		BNE	@update

		CMP	pageptr0 + 1
		BNE	@hidden
		
		LDA	tempptr1
		CMP	pageptr0
		BNE	@hidden
		
		JMP	@update

@hidden:
;***TODO:	Signal on tab that there is a message

		RTS

@update:
		JSR	ctrlsLockAcquire

		LDA	tempptr2
		STA	elemptr0
		LDA	tempptr2 + 1
		STA	elemptr0 + 1

;		JSR	ctrlsLPanelDefPresent
		JSR	ctrlsControlInvalidate

		JSR	ctrlsLockRelease

		RTS

;-------------------------------------------------------------------------------
ctrlsPageChanged:
;-------------------------------------------------------------------------------
		LDY	#$00

@loop:
		LDA	msgs_change, Y
		STA	msgsptr0
		STA	elemptr0
		INY
		LDA	msgs_change, Y
		STA	msgsptr0 + 1
		STA	elemptr0 + 1
		INY
		LDA	msgs_change, Y
		STA	msgsdat0
		INY
		LDA	msgs_change, Y
		STA	msgsdat1
		INY
	
		STY	ctrlvar_a
		
		LDY	#ELEMENT::changed
		LDA	(elemptr0), Y
		STA	ctrlptr_a
		INY
		LDA	(elemptr0), Y
		STA	ctrlptr_a + 1
		
		BEQ	@def
		
		JSR	ctrlsProxyA
		JMP	@next
		
@def:
		JSR	ctrlsControlDefChanged
	
@next:	
		LDY	#ELEMENT::state
		LDA	(msgsptr0), Y
		AND	#($FF ^ STATE_CHANGED)
		STA	(msgsptr0), Y

		LDY	ctrlvar_a
		CPY	msgs_change_idx
		BNE	@loop
		
@exit:
		LDA	#$00
		STA	msgs_change_idx

		RTS


	.export	ctrlsPanelDefChanged
;-------------------------------------------------------------------------------
ctrlsPanelDefChanged:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_CHANGED
		BEQ	@exit
		
		LDA	(elemptr0), Y
		AND	#($FF ^ STATE_CHANGED)
		STA	(elemptr0), Y

		LDA	(elemptr0), Y
		AND	#STATE_VISIBLE
		BEQ	@exit

		JSR	ctrlsControlInvalidate

		LDY	#PANEL::ctrlcnt
		LDA	(elemptr0), Y
		BEQ	@exit
		
		ASL	
		TAX
		DEX
		
		LDY	#PANEL::controls
		LDA	(elemptr0) , Y
		STA	tempptr0
		INY
		LDA	(elemptr0) , Y
		STA	tempptr0 + 1
		
		TXA
		TAY

@loop:
		LDA	(tempptr0), Y
		STA	elemptr0 + 1
		DEY
		LDA	(tempptr0), Y
		STA	elemptr0
		
		TYA
		PHA
		
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_VISIBLE
		BEQ	@next
		
		JSR	ctrlsControlInvalidate

@next:
		PLA
		TAY
		DEY
		BPL	@loop

@exit:
		RTS


	.export	ctrlsControlDefChanged
;-------------------------------------------------------------------------------
ctrlsControlDefChanged:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_CHANGED
		BEQ	@exit
		
		LDA	(elemptr0), Y
		AND	#STATE_DOWN
		BEQ	@dirty

		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_DOWNCAPTURE
		BNE	@dirty

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#($FF ^ STATE_DOWN)
		STA	(elemptr0), Y

		LDA	#$00
		STA	downCtrl
		STA	downCtrl + 1

@dirty:
		JSR	ctrlsControlInvalidate
		
@exit:
		RTS


	.export	ctrlsMoveIsTarget
;-------------------------------------------------------------------------------
ctrlsMoveIsTarget:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_NONAVIGATE
		BNE	ctrlsMoveIsTargetNot

ctrlsMoveIsTargetPanel:
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_VISIBLE
		BEQ	ctrlsMoveIsTargetNot

		LDA	(elemptr0), Y
		AND	#STATE_ENABLED
		BEQ	ctrlsMoveIsTargetNot

		SEC
		RTS

ctrlsMoveIsTargetNot:
		CLC
		RTS


	.export	ctrlsMoveActiveControl
;-------------------------------------------------------------------------------
ctrlsMoveActiveControl:
;-------------------------------------------------------------------------------
		LDY	#PAGE::panels
		LDA	(pageptr0), Y
		STA	ctrlptr0
		INY
		LDA	(pageptr0), Y
		STA	ctrlptr0 + 1

		LDY	actvctrlp
		STY	ctrlvar_a

		LDA	(ctrlptr0), Y
		STA	panlptr0
		INY
		LDA	(ctrlptr0), Y
		STA	panlptr0 + 1

		LDY	#PANEL::controls
		LDA	(panlptr0), Y
		STA	ctrlptr1
		INY
		LDA	(panlptr0), Y
		STA	ctrlptr1 + 1

		LDY	actvctrlc
		STY	ctrlvar_b

		LDA	msgsdat0
		CMP	#KEY_C64_CDOWN
		BNE	@moveup

		JMP	@movedown

@moveup:
		LDY	ctrlvar_b
		BEQ	@nextpnlup

		DEY
		LDA	(ctrlptr1), Y
		STA	elemptr0 + 1
		DEY
		LDA	(ctrlptr1), Y
		STA	elemptr0

		STY	ctrlvar_b

		JSR	ctrlsMoveIsTarget
		BCC	@moveup

		JSR	ctrlsActivateCtrlSimple

		LDY	ctrlvar_b
;		INY
;		INY
		STY	actvctrlc

		LDY	ctrlvar_a
;		INY
;		INY
		STY	actvctrlp

		RTS

@nextpnlup:
		LDY	ctrlvar_a
		BEQ	@uploop

		DEY
		LDA	(ctrlptr0), Y
		STA	panlptr0 + 1
		DEY
		LDA	(ctrlptr0), Y
		STA	panlptr0

		STY	ctrlvar_a
		
		LDA	panlptr0 + 1
		STA	elemptr0 + 1
		LDA	panlptr0
		STA	elemptr0

		JSR	ctrlsMoveIsTargetPanel
		BCC	@nextpnlup		
		
		JMP	@uplast

@uploop:
		LDY	#PAGE::panlcnt
		LDA	(pageptr0), Y
		ASL
;		STA	ctrlvar_a

		TAY
		
		DEY
		LDA	(ctrlptr0), Y
		STA	panlptr0 + 1
		STA	elemptr0 + 1
		DEY
		LDA	(ctrlptr0), Y
		STA	panlptr0
		STA	elemptr0

		STY	ctrlvar_a

		JSR	ctrlsMoveIsTargetPanel
		BCC	@nextpnlup		

@uplast:
		LDY	#PANEL::controls
		LDA	(panlptr0), Y
		STA	ctrlptr1
		INY
		LDA	(panlptr0), Y
		STA	ctrlptr1 + 1

		LDY	#PANEL::ctrlcnt
		LDA	(panlptr0), Y
		BEQ	@nextpnlup
		ASL
		STA	ctrlvar_b

		JMP	@moveup
			
@movedown:
		LDY	#PANEL::ctrlcnt
		LDA	(panlptr0), Y
		TAY
		DEY
		TYA
		ASL
		CMP	ctrlvar_b
		BEQ	@nextpnldn

		LDY	ctrlvar_b
		INY
		INY

		STY	ctrlvar_b

@downtest:
		LDA	(ctrlptr1), Y
		STA	elemptr0
		INY
		LDA	(ctrlptr1), Y
		STA	elemptr0 + 1
		
		JSR	ctrlsMoveIsTarget
		BCC	@movedown

		JSR	ctrlsActivateCtrlSimple

		LDY	ctrlvar_b
		STY	actvctrlc

		LDY	ctrlvar_a
		STY	actvctrlp

		RTS

@nextpnldn:
		LDY	#PAGE::panlcnt
		LDA	(pageptr0), Y
		TAY
		DEY
		TYA
		ASL
		CMP	ctrlvar_a
		BEQ	@dnloop

		LDY	ctrlvar_a
		INY
		INY

		STY	ctrlvar_a

		LDA	(ctrlptr0), Y
		STA	panlptr0
		STA	elemptr0
		INY
		LDA	(ctrlptr0), Y
		STA	panlptr0 + 1
		STA	elemptr0 + 1
		
		JSR	ctrlsMoveIsTargetPanel
		BCC	@nextpnldn
		
		JMP	@dnfirst

@dnloop:
		LDA	#$00
		STA	ctrlvar_a

		TAY
		
		LDA	(ctrlptr0), Y
		STA	panlptr0
		STA	elemptr0
		INY
		LDA	(ctrlptr0), Y
		STA	panlptr0 + 1
		STA	elemptr0 + 1

		JSR	ctrlsMoveIsTargetPanel
		BCC	@nextpnldn		
		
@dnfirst:
		LDY	#PANEL::controls
		LDA	(panlptr0), Y
		STA	ctrlptr1
		INY
		LDA	(panlptr0), Y
		STA	ctrlptr1 + 1

		LDA	#$00
		STA	ctrlvar_b

		LDY	#PANEL::ctrlcnt
		LDA	(panlptr0), Y
		BEQ	@nextpnldn

		LDY	ctrlvar_b

		JMP	@downtest


	.export	ctrlsPageKeyPress
;-------------------------------------------------------------------------------
ctrlsPageKeyPress:
;-------------------------------------------------------------------------------
		STA	msgsdat0
		STX	msgsdat1

		TXA
		AND	#keyModSystem
		BNE	@findaccel

		LDA	msgsdat0

		CMP	#KEY_C64_F1
		BCS	@fkey0
			
		JMP	@isdownctrl

@fkey0:
		CMP	#(KEY_C64_F8 + 1)
		BCC	@findaccel

@isdownctrl:
		LDA	downCtrl + 1
		BNE	@downctrl

		LDA	actvCtrl + 1
		BNE	@actvctrl

		RTS				;discard key press

@actvctrl:
		LDA	msgsdat0
		CMP	#KEY_C64_CDOWN
		BEQ	@moveactv

		CMP	#KEY_C64_CUP
		BEQ	@moveactv

		LDA	actvCtrl
		STA	elemptr0
		LDA	actvCtrl + 1
		STA	elemptr0 + 1
		
		LDA	msgsdat0
		CMP	#KEY_ASC_CR
		BNE	@send

		JMP	ctrlsDownCtrl
;		RTS		


@moveactv:
		JMP	ctrlsMoveActiveControl
;		RTS

@downctrl:
		STA	elemptr0 + 1
		LDA	downCtrl
		STA	elemptr0

@send:
		LDY	#ELEMENT::keypress
		LDA	(elemptr0), Y
		STA	ctrlptr_a
		INY
		LDA	(elemptr0), Y
		STA	ctrlptr_a + 1
		
		BEQ	@def
		
		JSR	ctrlsProxyA
		RTS
		
@def:
		JSR	ctrlsControlDefKeyPress
		RTS

@findaccel:
		LDY	#PAGE::panels
		LDA	(pageptr0), Y
		STA	ctrlptr0
		INY
		LDA	(pageptr0), Y
		STA	ctrlptr0 + 1

		LDY	#$00
		
@looppanl:
		LDA	(ctrlptr0), Y
		STA	panlptr0
		INY
		LDA	(ctrlptr0), Y
		BEQ	@exit
		
		STA	panlptr0 + 1
		INY
		
		STY	ctrlvar_a
		
		LDY	#PANEL::controls
		LDA	(panlptr0), Y
		STA	ctrlptr1
		INY
		LDA	(panlptr0), Y
		STA	ctrlptr1 + 1

		LDY	#$00
		
@loopctrl:
		LDA	(ctrlptr1), Y
		STA	elemptr0
		INY
		LDA	(ctrlptr1), Y
		BEQ	@nextpanl
		
		STA	elemptr0 + 1
		INY
		
		STY	ctrlvar_b
		
		LDY	#CONTROL::accelchar
		LDA	(elemptr0), Y
		CMP	msgsdat0

		BNE	@nextctrl

		JSR	ctrlsDownCtrl
		RTS

@nextctrl:	
		LDY	ctrlvar_b
		JMP	@loopctrl

@nextpanl:	
		LDY	ctrlvar_a
		JMP	@looppanl

@exit:
		RTS


	.export	ctrlsEditDefKeyPress
;-------------------------------------------------------------------------------
ctrlsEditDefKeyPress:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_DOWN
		BNE	@downkeys

		RTS

@downkeys:
		LDA	msgsdat0
		CMP	#KEY_ASC_CR
		BNE	@input

		JSR	ctrlsUnDownCtrl
		RTS

@input:
		LDY	#CONTROL::textptr
		LDA	(elemptr0), Y
		STA	tempptr0
		INY
		LDA	(elemptr0), Y
		STA	tempptr0 + 1

		LDY	#EDITCTRL::textsiz
		LDA	(elemptr0), Y
		STA	tempdat0

		LDA	msgsdat0
		CMP	#KEY_ASC_BKSPC
		BEQ	@delete

		LDY	#EDITCTRL::textmaxsz
		LDA	(elemptr0), Y
		CMP	tempdat0
		BEQ	@exit

		LDY	tempdat0

		LDA	msgsdat0
		STA	(tempptr0), Y
		
		INY
		LDA	#$00
		STA	(tempptr0), Y
		TYA

@invalidate:
		LDY	#EDITCTRL::textsiz
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate
		
@exit:
		JMP	ctrlsControlDefKeyPress

@delete:
		LDY	tempdat0
		BEQ	@exit

		DEY

		LDA	#$00
		STA	(tempptr0), Y
		
		TYA
		
		JMP	@invalidate


;-------------------------------------------------------------------------------
ctrlsControlDefKeyPress:
;-------------------------------------------------------------------------------
		RTS


	.export	ctrlsPagePrepare
;-------------------------------------------------------------------------------
ctrlsPagePrepare:
;-------------------------------------------------------------------------------
		LDY	#PAGE::panels
		LDA	(pageptr0), Y
		STA	ctrlptr0
		INY
		LDA	(pageptr0), Y
		STA	ctrlptr0 + 1

		LDY	#$00
		
@loop:
		LDA	(ctrlptr0), Y
		STA	panlptr0
		INY
		LDA	(ctrlptr0), Y
		BEQ	@exit
		
		STA	panlptr0 + 1
		INY
		
		STY	ctrlvar_a
		
		LDY	#ELEMENT::prepare
		LDA	(panlptr0), Y
		STA	ctrlptr_a
		INY
		LDA	(panlptr0), Y
		STA	ctrlptr_a + 1
		
		BEQ	@def
		
		JSR	ctrlsProxyA
		JMP	@next
		
@def:
		JSR	ctrlsPanelDefPrepare
	
@next:	
		LDY	ctrlvar_a
		
		JMP	@loop

@exit:
		RTS


	.export	ctrlsProxyA
;-------------------------------------------------------------------------------
ctrlsProxyA:
;-------------------------------------------------------------------------------
		JMP	(ctrlptr_a)


	.export	ctrlsPanelDefPrepare
;-------------------------------------------------------------------------------
ctrlsPanelDefPrepare:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(panlptr0), Y
		AND	#STATE_VISIBLE
		BEQ	@exit
		
		LDA	panlptr0
		STA	elemptr0
		LDA	panlptr0 + 1
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate
		
		LDY	#PANEL::controls
		LDA	(panlptr0), Y
		STA	ctrlptr1
		INY
		LDA	(panlptr0), Y
		STA	ctrlptr1 + 1

		LDY	#$00
		
@loop:
		LDA	(ctrlptr1), Y
		STA	elemptr0
		INY
		LDA	(ctrlptr1), Y
		BEQ	@exit
		
		STA	elemptr0 + 1
		INY
		
		STY	ctrlvar_b
		
		LDY	#ELEMENT::prepare
		LDA	(elemptr0), Y
		STA	ctrlptr_a
		INY
		LDA	(elemptr0), Y
		STA	ctrlptr_a + 1
		
		BEQ	@def
		
		JSR	ctrlsProxyA
		JMP	@next
		
@def:
		JSR	ctrlsControlDefPrepare
	
@next:	
		LDY	ctrlvar_b
		
		JMP	@loop

@exit:
		RTS
		

;-------------------------------------------------------------------------------
ctrlsControlDefPrepare:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		
		AND	#($FF ^ (STATE_ACTIVE | STATE_PICK | STATE_DOWN))
		STA	(elemptr0), Y

		LDA	actvCtrl + 1
		BNE	@cont

		LDA	panlptr0
		CMP	#<tab_main
		BNE	@begin

		LDA	panlptr0 + 1
		CMP	#>tab_main
		BNE	@begin

		JMP	@cont

@begin:
		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_NONAVIGATE
		BNE	@cont

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		ORA	#STATE_ACTIVE
		STA	(elemptr0), Y
		
		LDA	elemptr0
		STA	actvCtrl 
		LDA	elemptr0 + 1
		STA	actvCtrl + 1

		LDA	ctrlvar_a
		STA	actvctrlp
		DEC	actvctrlp
		DEC	actvctrlp

		LDA	ctrlvar_b
		STA	actvctrlc
		DEC	actvctrlc
		DEC	actvctrlc
		
@cont:
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_VISIBLE
		BEQ	@exit

		JSR	ctrlsControlInvalidate
		
@exit:
		RTS


	.export ctrlsPagePresent
;-------------------------------------------------------------------------------
ctrlsPagePresent:
;-------------------------------------------------------------------------------
		LDY	#$00

@loop:
		LDA	msgs_dirty, Y
		STA	elemptr0
		STA	msgsptr0
		INY
		LDA	msgs_dirty, Y
		STA	elemptr0 + 1
		STA	msgsptr0 + 1
		INY
		LDA	msgs_dirty, Y
		STA	msgsdat0
		INY
		LDA	msgs_dirty, Y
		STA	msgsdat1
		INY
	
		STY	ctrlvar_a
		
		LDY	#ELEMENT::present
		LDA	(elemptr0), Y
		STA	ctrlptr_a
		INY
		LDA	(elemptr0), Y
		STA	ctrlptr_a + 1
		
		BEQ	@def
		
		JSR	ctrlsProxyA
		JMP	@next
		
@def:
		JSR	ctrlsControlDefPresent
	
@next:	
		LDY	#ELEMENT::state
		LDA	(msgsptr0), Y
		AND	#($FF ^ STATE_DIRTY)
		STA	(msgsptr0), Y

		LDY	ctrlvar_a
		CPY	msgs_dirty_idx
		BNE	@loop
		
@exit:
		LDA	#$00
		STA	msgs_dirty_idx

		RTS


	.export	ctrlsLPanelDefPresent
;-------------------------------------------------------------------------------
ctrlsLPanelDefPresent:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y

		AND	#STATE_VISIBLE
		BEQ	@exit

		JSR	ctrlsPanelDefPresent

		LDY	#LOGPANEL::lines
		LDA	(elemptr0), Y
		STA	ctrlptr0
		INY
		LDA	(elemptr0), Y
		STA	ctrlptr0 + 1

		LDY	#ELEMENT::height
		LDA	(elemptr0), Y
		ASL
		STA	tempvar_c

		LDY	#ELEMENT::posy
		LDA	(elemptr0), Y
		STA	tempvar_x

		LDY	#$00
		STY	tempvar_y
		
@loop:
		LDA	(ctrlptr0), Y
		STA	tempptr1 
		INY
		LDA	(ctrlptr0), Y
		STA	tempptr1 + 1
		INY

		STY	tempvar_y

		LDA	#CLR_TEXT
		STA	tempdat0

		LDA	#$00
		STA	tempdat1
		STA	tempvar_a
		STA	tempvar_d

		LDY	#ELEMENT::width
		LDA	(elemptr0), Y
		STA	tempdat2

		LDA	#$01
		STA	tempdat3
		
		LDA	tempvar_x
		STA	tempvar_b

		INC	tempvar_x

		JSR	ctrlsDrawTextDirect
		
		LDY	tempvar_y
		CPY	tempvar_c
		BNE	@loop

@exit:
		RTS


	.export	ctrlsPanelDefPresent
;-------------------------------------------------------------------------------
ctrlsPanelDefPresent:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y

		AND	#STATE_VISIBLE
		BEQ	@exit

		LDA	(elemptr0), Y
		AND	#STATE_DIRTY
		BEQ	@exit

		LDY	#ELEMENT::colour
		LDA	(elemptr0), Y
	
		JSR	ctrlsEraseBkg

@exit:
		RTS


	.export	ctrlsEditDefPresent
;-------------------------------------------------------------------------------
ctrlsEditDefPresent:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_DOWN
		BEQ	@normal

		LDA	#CLR_TEXT
		STA	tempdat0

		JSR	ctrlsEraseBkg

		LDY	#CONTROL::textoffx
		LDA	(elemptr0), Y
		STA	tempdat2

		LDY	#ELEMENT::width
		LDA	(elemptr0), Y
		
		SEC
		SBC	tempdat2
		STA	tempdat2

		DEC	tempdat2

		LDY	#EDITCTRL::textsiz
		LDA	(elemptr0), Y
		STA	tempdat1

		LDA	tempdat2
		CMP	tempdat1
		BCS	@noindent

		SEC
		LDA	tempdat1
		SBC	tempdat2
		STA	tempdat1
	
		JMP	@text

@noindent:
		LDA	#$00
		STA	tempdat1

@text:
		LDA	#$00
		STA	tempdat3

		JSR	ctrlsDrawText
		
		RTS

@normal:
		JMP 	ctrlsControlDefPresent


;-------------------------------------------------------------------------------
ctrlsControlDefPresent:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y

		AND	#STATE_VISIBLE
		BEQ	@exit

		LDA	(elemptr0), Y
		AND	#STATE_DIRTY
		BEQ	@exit

		LDA	(elemptr0), Y
		AND	#STATE_ENABLED
		BNE	@checkpick
		
		LDA	#CLR_SHADOW
		JMP	@draw
		
@checkpick:
		LDA	(elemptr0), Y
		AND	#STATE_PICK
		BEQ	@checkactv
		
;		LDA	pickBlinkState
;		BEQ	@normal

@picked:
		LDA	#CLR_FOCUS
		JMP	@draw

@checkactv:
		LDA	(elemptr0), Y
		AND	#STATE_ACTIVE
		BNE	@picked

@normal:
		LDY	#ELEMENT::colour
		LDA	(elemptr0), Y
		
@draw:
		STA	tempdat0

		JSR	ctrlsEraseBkg

		LDA	#$00
		STA	tempdat1

		LDY	#CONTROL::textoffx
		LDA	(elemptr0), Y
		STA	tempdat2

		LDY	#ELEMENT::width
		LDA	(elemptr0), Y
		
		SEC
		SBC	tempdat2
		STA	tempdat2

		LDA	#$01
		STA	tempdat3

		JSR	ctrlsDrawText

		JSR	ctrlsDrawAccel

@exit:
		RTS


;===============================================================================


;===============================================================================
	.segment 	"INIT"
;===============================================================================


;===============================================================================
	.segment 	"ONCE"
;===============================================================================
sprPointer0:
		.byte	%00000000, %00000000, %00000000
		.byte	%01111111, %10000000, %00000000
		.byte	%01000001, %00000000, %00000000
		.byte	%01000010, %00000000, %00000000
		.byte	%01000001, %00000000, %00000000
		.byte	%01000000
;===============================================================================


	.export	connection_closed
;===============================================================================
	.segment	"BSS"
;===============================================================================
tempvar_a:
			.res 	1
tempvar_b:
			.res	1
tempvar_c:
			.res	1
tempvar_d:
			.res	1
tempvar_e:
			.res	1
tempvar_f:
			.res	1

tempvar_x:
			.res	1
tempvar_y:
			.res	1
tempvar_z:
			.res	1
		
ctrlvar_a:
			.res	1
ctrlvar_b:
			.res	1
ctrlvar_c:
			.res	1
ctrlptr_a:
			.res	2

ctrlsLock:
			.res	1
ctrlsLCnt:
			.res	1
ctrlsPrep:
			.res	1
ctrlsLChg:
			.res	1

actvctrlp:
			.res	1
actvctrlc:
			.res	1

temp_bin: 
			.res 	2
temp_bcd: 
			.res 	3

inet_port:
			.res	2
inet_timeout:
			.res	1
connection_close_requested:     
			.res 	1
connection_closed:              
			.res 	1
data_received:                  
			.res 	1

sendmsgscnt:
			.res 	1
sendmsg0:
			.res	60
sendmsg1:
			.res 	60
sendmsg2:
			.res 	60
readmsgbuflen:
			.res	2
readmsgidx:
			.res	1
readbufidx:
			.res	1
readmsglen:
			.res	1
readmsg0:
			.res	60

readparmcnt:
			.res	1
readparm0:
			.res	1
readparm1:
			.res	1
readparm2:
			.res	1

msglstid:
			.res	10
msglstsysid:
			.res	10
msglstlobid:
			.res	10
msglstplyid:
			.res	10
msglstsysloc:
			.res	10
msglstlobloc:
			.res	10
msglstplyloc:
			.res	10

			
current_clrs:	
			.res	10


cnct_log_line0:
			.res	41
cnct_log_line1:
			.res	41
cnct_log_line2:
			.res	41
cnct_log_line3:
			.res	41
cnct_log_line4:
			.res	41
cnct_log_line5:
			.res	41
cnct_log_line6:
			.res	41
cnct_log_line7:
			.res	41
cnct_log_line8:
			.res	41
cnct_log_line9:
			.res	41
cnct_log_lineA:
			.res	41
cnct_log_lineB:
			.res	41
cnct_log_lineC:
			.res	41


msgs_change_idx:
			.res	1

msgs_change:
			.res	256

msgs_dirty_idx:		
			.res	1

msgs_dirty:
			.res 	256


;===============================================================================


;===============================================================================
	.segment	"RODATA"
;===============================================================================
text_token_null:
			.asciiz	""

text_ident_vernam:
			.asciiz	"alpha"
text_ident_pltfrm:
			.asciiz	"c64"
text_ident_verlbl:
			.asciiz	"0.00.22A"

text_init_text0:
			.asciiz	"INITIALISING..."

text_splsh_title:
			.asciiz	"M3WP YAHTZEE!"
text_splsh_text0:
			.asciiz	"WRITTEN BY:  DANIEL ENGLAND"
text_splsh_text1:
			.asciiz	"FOR ECCLESTIAL SOLUTIONS"
text_splsh_text2:
			.asciiz	"VERSION:  0.00.22A"
text_splsh_text3:
			.asciiz	"COPYRIGHT:  2012, HASBRO"
text_splsh_text4:
			.asciiz	"ALL RIGHTS RESERVED"
text_splsh_cont:
			.asciiz	"[CONTINUE]"

text_main_begin:
			.asciiz	"F1-BEGIN"
text_main_chat:
			.asciiz	"F3-CHAT"
text_main_play:
			.asciiz	"F5-PLAY"
text_page_connect:
			.asciiz	"CONNECT"
text_cnct_host:
			.asciiz "HOST NAME:"
text_cnct_user:
			.asciiz	"USER NAME:"
text_cnct_upd:
			.asciiz	"[UPDATE  ]"
text_cnct_cnct:
			.asciiz "[CONNECT ]"
text_cnct_dcnct:
			.asciiz "[DISCNNCT]"
text_cnct_info:
			.asciiz	"HOST INFO:"
text_page_room:
			.asciiz	"ROOM"
			
text_room_room:
			.asciiz	"ROOM:"
text_room_pwd:
			.asciiz	"PASSWORD:"
text_room_more:	
			.asciiz	"[MORE   >]"
text_room_less:	
			.asciiz	"[LESS   <]"
text_room_list:	
			.asciiz	"[LIST    ]"
text_room_join:	
			.asciiz	"[JOIN    ]"
text_room_part:	
			.asciiz	"[PART    ]"


text_driver_pref:
			.asciiz "= USING DRIVER: "
text_iobase_pref:
			.asciiz	"= DEVICE I/O  : $"
text_ipcfg_pref:
			.asciiz	"= WITH IP ADDR: "

text_trace_init:
			.asciiz	"# INITIALISED!"
text_trace_cnct:
			.asciiz	"# CONNECTING..."
text_trace_unkmsg:
			.asciiz "> UNKNOWN MESSAGE IDENT"

text_syserr_pref:
			.asciiz	"!!"
text_err_pref:
			.asciiz	"! "
text_list_pref:
			.asciiz "* "

text_err_init:
			.asciiz	"!!INITIALISATION ERROR (NO DEVICE?)"
text_err_cnct:
			.asciiz "!!UNSPECIFIED CONNECTION ERROR"
text_err_abort:
			.asciiz	"! ERROR - USER ABORTED"
text_err_timeout:
			.asciiz	"! ERROR - OPERATION TIMEOUT"
text_err_other:
			.asciiz	"! ERROR - SYSTEM ERROR $"
text_err_disc:
			.asciiz "! DISCONNECTED"
text_err_okay:
			.asciiz	"= OKAY"


hexdigits:
			.byte "0123456789ABCDEF"

			
clrschme_cnt	=	$01
clrschme_lst:
			.word	clrschme0
			.word	name_clrschme0
			.word	$0000
			
name_clrschme0:
			.asciiz	"FAMILIAR"
clrschme0:
			.byte	$0E, $06, $01, $01, $0E, $04, $0C, $0F, $03, $01
;===============================================================================