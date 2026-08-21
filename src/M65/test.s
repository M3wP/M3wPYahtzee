;	TODO:
;
;	LIMITATIONS:
;		- Making controls invisible requires some effort to redisplay 
;		  properly
;		- Beware overlapping controls
;
;	BUGS:
;		- Edit controls with a captured (down) blinking cursor get
;		  "picked" and change presentation if the mouse moves over
;		  them while typing - probably the mouse hover/pick logic
;		  not checking downCtrl before restyling. Minor, not fixed
;		  yet.
;

	.setcpu		"4510"

;	LDAX/STAX (16-bit load/store via A/X) and the three IP65_ERROR_*
;	codes below were pulled in from ip65's common.inc/error.inc -
;	copied in directly since that was all that was actually used out
;	of them (net.inc was entirely dead and dropped outright). Original
;	source: ip65 (https://github.com/cc65/ip65), MPL 1.1.
;	common.inc - Per Olofsson, MagerValp@gmail.com, Copyright (C) 2009.
;	error.inc  - Jonno Downes, jonno@jamtronix.com, Copyright (C) 2009.
.macro ldax arg
.if (.match (.left (1, arg), #))      ; immediate mode
    lda #<(.right (.tcount (arg)-1, arg))
    ldx #>(.right (.tcount (arg)-1, arg))
.else                                 ; assume absolute or zero page
    lda arg
    ldx 1+(arg)
.endif
.endmacro

.define LDAX ldax

.macro stax arg
  sta arg
  stx 1+(arg)
.endmacro

.define STAX stax

IP65_ERROR_TIMEOUT_ON_RECEIVE = $81
IP65_ERROR_ABORTED_BY_USER    = $86
IP65_ERROR_CONNECTION_CLOSED  = $8A


;	Debugging - show raster time usage on border
	.define	DEBUG_RASTERTIME	0
	
;	Debugging - check message limits and panic if borked
	.define	DEBUG_MSGSPUSHSZ	1

;	Debugging - log each RECV_DATA poll's byte count to the connect log
	.define	DEBUG_RXSIZE	0

;	Debugging - log every keypress's raw ASCIIKEY ($D610) and MODKEY
;	($D60A[0:6]) byte to the connect log, to nail down real MEGA65
;	keyboard-manual values by hand
	.define	DEBUG_KEYSCAN	0

;	Debugging - sleep when internet is idle
	.define DEBUG_INETDOSLEEP	0


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

;	Matches $D60A[0:6] (MODKEY) exactly, so the byte read there can be
;	used as-is - bit 7 (KEYQUEUE, queue-non-empty) is masked off
;	before storage, see userKeyScanKey.
keyModNone	=	$00
keyModShiftL	=	$01
keyModShiftR	=	$02
keyModControl	=	$04
keyModSystem	=	$08		;MEGA key
keyModAlt	=	$10
keyModNoScroll	=	$20
keyModCapsLock	=	$40

buttonLeft	=	$10
buttonRight	=	$01

spriteMem20	= 	$0800

spritePtr0	=	$07F8
spritePtr1	=	$07F9
spritePtr2	=	$07FA
spritePtr3	=	$07FB



FRAMECOUNT          = $d7fa




offsX		=	24
offsY		=	50

;	Locate our game data at a fixed address (before screen RAM, after stack)
gameData	= 	$0200


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



; C65/MEGA65 JSRFAR workspace
FAR_BANK            = $02
FAR_ADDR_HI         = $03
FAR_ADDR_LO         = $04
FAR_STATUS          = $05
FAR_ARG_A           = $06
FAR_ARG_X           = $07
FAR_ARG_Y           = $08

; 28-bit indirect pointer for staging calls into bank 4.
PTR_LO              = $fb
PTR_HI              = $fc
PTR_BANK            = $fd
PTR_TOP             = $fe

; Mega-IP public jump table, as seen inside bank 4.
MIP_INIT            = $2000
MIP_SET_GATEWAY     = $2003
MIP_SET_LOCAL_IP    = $2006
MIP_SET_LOCAL_PORT  = $2009
MIP_SET_REMOTE_IP   = $200c
MIP_SET_REMOTE_PORT = $200f
MIP_SET_SUBNET      = $2012
MIP_SET_XLATE       = $2015
MIP_DISCONNECT      = $2021
MIP_STATUS_POLL     = $2024
MIP_CONNECT_START   = $2027
MIP_CONNECT_POLL    = $202a
MIP_GET_DNS_RESULT  = $2033
MIP_GET_DNS_STATE   = $2036
MIP_DHCP_START      = $2042
MIP_DHCP_POLL       = $2045
MIP_SET_DNS         = $204b
MIP_GET_LOCAL_IP    = $204e
MIP_GET_GATEWAY     = $2051
MIP_GET_SUBNET      = $2054
MIP_GET_DNS         = $2057
MIP_GET_REMOTE_IP   = $205a
MIP_FORCE_CLOSE     = $205d
MIP_TCP_TX_IDLE     = $2066

; Mega-IP ML extension table.
MIP_ML_SEND_BYTE    = $7600
MIP_DNS_START_BUF   = $760f
MIP_DNS_START_BUF_Y = $7618
MIP_ML_CALL_STAGED  = $761b
MIP_ML_RECV_BYTE    = $761e
MIP_ML_RECV_BLOCK   = $7621

; Staging block at physical bank-4 $77c0.
ML_STAGE_LO         = $77c0
ML_STAGE_HI         = $77
ML_STAGE_BANK       = $04
ML_STAGE_TARGET_LO  = 0
ML_STAGE_TARGET_HI  = 1
ML_STAGE_ARG_A      = 2
ML_STAGE_ARG_X      = 3
ML_STAGE_ARG_Y      = 4
ML_STAGE_ARG_Z      = 5



	.define	KEY_ASC_BKSPC	$14
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
;	HARDWARE LIMITATION - confirmed on real hardware, not just here in
;	software: '^' is doubly unsupported on the MEGA65.
;	  1. No physical key, alone or with MEGA held, reports ASCIIKEY
;	     $5E - unlike the other 7 "needs screen code xlat" characters
;	     around here, which all trace to a real key (BSLASH=MEGA+/,
;	     BQUOTE=MEGA+left-arrow, OCRLYB=MEGA+:, PIPE=MEGA+., CCRLYB=
;	     MEGA+;, TILDE=MEGA+,, USCORE=left-arrow alone). There is no
;	     way to type '^' on this keyboard via $D610, at least via any
;	     modifier combo tried so far (alone, MEGA - Shift/Ctrl untested).
;	  2. Even if $5E is produced some other way (pasted in, injected
;	     programmatically, etc.), the active charset's glyph at that
;	     screen-code position renders as '~' (tilde), not a caret -
;	     screenASCIIXLAT has no entry for $5E, so it falls through
;	     screenASCIIToScreen's generic conversion into whatever the
;	     ROM font actually has there, which isn't a caret glyph.
;	Matters because Pascal source (^ for pointer types) is exactly
;	the kind of text this client might need to display correctly one
;	day - flagging clearly rather than leaving it as a vague "needs
;	xlat" note, since unlike its neighbours this one may not be fixable
;	by adding a screenASCIIXLAT entry alone (there's no key to type it
;	with in the first place, and no glyph to draw even if there were).
	.define KEY_ASC_CARET	$5E		;!!See HARDWARE LIMITATION note above - unreachable via keyboard, no glyph either
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
	.define	KEY_C64_CRIGHT 	$1D
	.define	KEY_C64_CDOWN 	$11		;Could be ascii line feed? $0A
	.define KEY_C64_HOME	$13
	.define KEY_C64_TAB	$09		;Confirmed on hardware - MEGA65 has no C64 equivalent
	.define KEY_C64_STAB	$0F		;TAB + SHIFT (either) - confirmed on hardware
	.define KEY_C64_POUND	$5C
	.define KEY_C64_ARRUP	$5E
	.define KEY_C64_ARRLEFT	$5F
	.define KEY_C64_SHSTOP	$83
	.define	KEY_C64_F1 	$F1
	.define	KEY_C64_F3 	$F3
	.define	KEY_C64_F5 	$F5
	.define	KEY_C64_F7 	$F7
	.define KEY_C64_F2	$F2
	.define KEY_C64_F4	$F4
	.define KEY_C64_F6	$F6
	.define KEY_C64_F8	$F8
	.define	KEY_C64_F9 	$F9
;	F10/F12/F14 aren't separate physical keys - they're MEGA65's own
;	continuation of the C64 odd/even F-key convention (odd = key
;	pressed alone, even = same key + shift or MEGA - confirmed on
;	real hardware that MEGA and shift report the same code here,
;	e.g. F7 alone $F7, F7+shift or F7+MEGA both $F8).
	.define	KEY_C64_F10	$FA
	.define	KEY_C64_F11	$FB
	.define	KEY_C64_F12	$FC
	.define	KEY_C64_F13	$FD
	.define	KEY_C64_F14	$FE
	.define	KEY_C64_HELP	$1F
	.define KEY_C64_SHRET	$8D		;Not mapped
	.define KEY_C64_CUP	$91
	.define KEY_C64_CLEAR	$93
	.define KEY_C64_INS	$94		;Could be ascii shift in? $0F
	.define KEY_C64_CLEFT	$9D		

	.define KEY_C64_INVALID	$FF


;	Game definitions

	.define	SLOT_ST_NONE	$00
	.define SLOT_ST_IDLE	$01
	.define SLOT_ST_READY	$02
	.define SLOT_ST_PREP	$03
	.define SLOT_ST_WAIT	$04
	.define SLOT_ST_PLAY	$05
	.define SLOT_ST_FINISH	$06
	.define SLOT_ST_WIN	$07
	
	.define GAME_ST_WAIT	$00
	.define GAME_ST_PREP	$01
	.define GAME_ST_PLAY	$02
	.define GAME_ST_PAUSE	$03
	.define GAME_ST_FINISH	$04
	
	.define	DIE_0		$01
	.define	DIE_1		$02
	.define DIE_2		$04
	.define DIE_3		$08
	.define DIE_4		$10
	.define DIE_5		$20
	.define DIE_ALL		$3F

	.define	SCRSHT_LABELS	$01
	.define	SCRSHT_SCORES	$02
	.define SCRSHT_INDCTR	$04
	.define	SCRSHT_ALL	$07
	
	.define PAGE_PLYOVRVW	$01
	.define PAGE_PLYDETAIL	$02


;	Controls definitions

	.define	CLR_BACK	$FD		;System - always black
	.define	CLR_EMPTY	$FE		;Border on C64
	.define	CLR_CURSOR	$FF		
	.define	CLR_TEXT	$00
	.define	CLR_FOCUS	$01
	.define	CLR_INSET	$02
	.define	CLR_FACE	$03
	.define CLR_SHADOW	$04
	.define CLR_PAPER	$05
	.define CLR_MONEY	$06
	.define CLR_DIE		$07
	.define CLR_SPEC_TEXT	$10		;Specific system text colour
	.define CLR_SPEC_CTRL	$20		;Specific system control colour 
						;(reversed on C64)

;	.define TYPE_ELEMENT	$00
;	.define TYPE_PAGE	$10
;	.define TYPE_PANEL	$20
;	.define TYPE_TABPANEL	TYPE_PANEL | $01
;	.define TYPE_CONTROL	$30
;	.define TYPE_LABEL	TYPE_CONTROL | $01

	.define STATE_CHANGED	$80		;System - don't use directly
	.define STATE_DIRTY	$40		;System - don't use directly
	.define STATE_PREPARED	$20		;System - for optimisations
	.define STATE_VISIBLE	$01
	.define STATE_ENABLED	$02
	.define STATE_PICK	$04
	.define STATE_ACTIVE	$08
	.define STATE_DOWN	$10

	.define	OPT_NOAUTOINVL	$01
	.define	OPT_NONAVIGATE	$02
	.define OPT_NODOWNACTV	$04
	.define OPT_CAPTURECRSR $08
	.define OPT_DOWNCAPTURE $10
	.define	OPT_AUTOCHECK	$20
	.define OPT_TEXTACCEL2X	$40
	.define OPT_TEXTCONTMRK $80
	

;	Game structures

	.struct	IDENT
		_0	.byte
		_1	.byte
		_2	.byte
		_3	.byte
		_4	.byte
		_5	.byte
		_6	.byte
		_7	.byte
		_8	.byte
	.endstruct				;9 bytes

	.struct SCRSHEET			;I'm making these byte sized
		aces	.byte			;even though I will get word
		twos	.byte			;sized values because it saves
		threes	.byte			;memory and I won't need larger
		fours	.byte
		fives	.byte
		sixes	.byte
		uprbnus	.byte
		thkind	.byte
		frkind	.byte
		flhse	.byte
		sstrt	.byte
		lstrt	.byte
		yahtz	.byte
		chnce	.byte
		ybnus1	.byte
		ybnus2	.byte
		ybnus3	.byte
	.endstruct				;17 bytes
	
	.struct	DICE
		_0	.byte
		_1	.byte
		_2	.byte
		_3	.byte
		_4	.byte
	.endstruct				;5 bytes

	.struct GAMESLOT
		sheet	.tag	SCRSHEET
		name	.tag	IDENT
		state	.byte
		score	.word
		dice	.tag	DICE
		fstrl	.byte
		keepers	.byte
		roll	.byte
	.endstruct				;37 bytes
	
	.struct	GAME
		slot0	.tag	GAMESLOT
		slot1	.tag	GAMESLOT
		slot2	.tag	GAMESLOT
		slot3	.tag	GAMESLOT
		slot4	.tag	GAMESLOT
		slot5	.tag	GAMESLOT	;222 bytes
		state	.byte
		round	.word
		ourslt	.byte
		detslt	.byte			
		plyslt	.byte			;228 bytes
	.endstruct

	.assert .sizeof(GAME) < $0100, error, "GameData would exceed bounds!"


;	Controls structures

	.struct	ELEMENT
;		prepare	.word
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
		nxtpage	.word
		bakpage	.word
		textptr	.word
		textoffx .byte
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
		linecnt .byte
		currln	.byte
		offsy	.byte
	.endstruct

	.struct	SCRSHTPANEL
		_panel	.tag	PANEL
		lastind	.byte
		hveprvw	.byte
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
	
	.struct	DIECTRL
		_control .tag	CONTROL
		value	.byte
	.endstruct



;===============================================================================
;	.segment  "ZEROPAGE": zeropage
;===============================================================================
;	.exportzp inetproc
	
;pageptr0:
;			.res	2
pageptr0 = $10

;panlptr0:
;			.res	2
panlptr0 = $12

;elemptr0:
;			.res	2
elemptr0 = $14

;ctrlptr0:
;			.res	2
ctrlptr0 = $16

;ctrlptr1:
;			.res	2
ctrlptr1 = $18


;tempptr0:		
;			.res 	2
tempptr0 = $1A

;tempptr1:		
;			.res 	2
tempptr1 = $1C


;tempptr2:		
;			.res 	2
tempptr2 = $1E


;tempptr3:		
;			.res 	2
tempptr3 = $20

;tempdat0:
;			.res	1
tempdat0  = $22

;tempdat1:
;			.res	1
tempdat1 = $23

;tempdat2:
;			.res 	1
tempdat2 = $24

;tempdat3:
;			.res	1
tempdat3 = $25

;imsgdat1:
;			.res	1
imsgdat1 = $26

;imsgdat2:
;			.res	1
imsgdat2 = $27

;tempbit0:
;			.res	1
tempbit0 = $28

;msgsptr0:
;			.res	2
msgsptr0 = $29

;msgsdat0:
;			.res	1
msgsdat0 = $2B

;msgsdat1:
;			.res	1
msgsdat1 = $2C

;senddat0:
;			.res	1
senddat0 = $2D

;sendptr0:
;			.res	2
sendptr0 = $2E

;pickCtrl:
;			.res	2
pickCtrl = $30

;downCtrl:
;			.res	2
downCtrl = $32

;actvCtrl:
;			.res	2
actvCtrl = $34
			
;inetproc:
;			.res	1
inetproc = $36

;inetstat:
;			.res	1
inetstat = $37

;ineterrk:
;			.res	1
ineterrk = $38

;ineterrc:
;			.res	1
ineterrc = $39

;inetread:
;			.res	2
inetread = $3A

;inetcalc:
;			.res	2
inetcalc = $3C


;keyZPKeyDown:
;			.res	1
keyZPKeyDown = $3E

;keyZPKeyCount:
;			.res	1
keyZPKeyCount = $3F

;keyZPKeyScan:
;			.res	1
keyZPKeyScan = $40

;keyZPDecodePtr:
;			.res	2
keyZPDecodePtr = $41

;keyZPAbort:
;			.res	1
keyZPAbort = $43

;===============================================================================


;===============================================================================
;	.segment 	"STARTUP"
;===============================================================================
;	Ends up at $080D
;-----------------------------------------------------------
;BASIC interface
;-----------------------------------------------------------
.segment "CODE"
;start 2 before load address so
;we can inject it into the binary
	.org		$07FF			
						
	.byte		$01, $08		;load address
	
;BASIC next addr and this line #
	.word		_basNext, $000A		
	.byte		$9E			;SYS command
	.asciiz		"2061"			;2061 and line end
_basNext:
	.word		$0000			;BASIC prog terminator
	.assert		* = $080D, error, "BASIC Loader incorrect!"
;-----------------------------------------------------------
  JMP init

;	* = $0810
.res  $0810 - *, 0

;	.assert * = $0810, error, "Mouse pointer data location incorrect!"
	
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


  ; 16-colour sprite pointer data for busy
  ; 1 = FG
  ; 2 = black
  ; 3 = grey
  ; 4 = white
		;.byte		$00, $03, $33, $33, $33, $33, $00, $00
		;.byte		$00, $32, $22, $22, $22, $23, $30, $00
		;.byte		$03, $24, $44, $44, $44, $42, $23, $00
		;.byte		$32, $33, $11, $11, $11, $14, $23, $00
		;.byte		$32, $31, $11, $11, $11, $14, $23, $00
		;.byte		$32, $31, $11, $11, $11, $14, $23, $00
		;.byte		$32, $31, $11, $11, $11, $14, $23, $00
		;.byte		$32, $33, $11, $11, $11, $42, $33, $00
		;.byte		$03, $23, $32, $34, $44, $22, $30, $00
		;.byte		$00, $32, $23, $31, $11, $42, $30, $00
		;.byte		$03, $24, $43, $11, $14, $23, $00, $00
		;.byte		$32, $31, $14, $23, $32, $30, $00, $00
		;.byte		$32, $33, $32, $32, $23, $00, $00, $00
		;.byte		$03, $22, $23, $33, $30, $00, $00, $00
		;.byte		$00, $33, $30, $00, $00, $00, $00, $00
		;.byte		$00, $00, $00, $00, $00, $00, $00, $00
		;.byte		$00, $00, $00, $00, $00, $00, $00, $00
		;.byte		$00, $00, $00, $00, $00, $00, $00, $00
		;.byte		$00, $00, $00, $00, $00, $00, $00, $00
		;.byte		$00, $00, $00, $00, $00, $00, $00, $00
		;.byte		$00, $00, $00, $00, $00, $00, $00, $00

  ; Mono colour black (2)
		.byte	%00000000, %00000000, %00000000
		.byte	%00011111, %11100000, %00000000
		.byte	%00100000, %00011000, %00000000
		.byte	%01000000, %00001000, %00000000
		.byte	%01000000, %00001000, %00000000
		.byte	%01000000, %00001000, %00000000
		.byte	%01000000, %00001000, %00000000
		.byte	%01000000, %00010000, %00000000
		.byte	%00100100, %00110000, %00000000
		.byte	%00011000, %00010000, %00000000
		.byte	%00100000, %00100000, %00000000
		.byte	%01000010, %01000000, %00000000
		.byte	%01000101, %10000000, %00000000
		.byte	%00111000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	$00

  ; White (4)
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00011111, %11100000, %00000000
		.byte	%00000000, %00010000, %00000000
		.byte	%00000000, %00010000, %00000000
		.byte	%00000000, %00010000, %00000000
		.byte	%00000000, %00010000, %00000000
		.byte	%00000000, %00100000, %00000000
		.byte	%00000001, %11000000, %00000000
		.byte	%00000000, %00100000, %00000000
		.byte	%00011000, %01000000, %00000000
		.byte	%00000100, %00000000, %00000000
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

  ; Grey (3)
		.byte	%00011111, %11110000, %00000000
		.byte	%00100000, %00011000, %00000000
		.byte	%01000000, %00000100, %00000000
		.byte	%10110000, %00000100, %00000000
		.byte	%10100000, %00000100, %00000000
		.byte	%10100000, %00000100, %00000000
		.byte	%10100000, %00000100, %00000000
		.byte	%10110000, %00001100, %00000000
		.byte	%01011010, %00001000, %00000000
		.byte	%00100110, %00001000, %00000000
		.byte	%01000100, %00010000, %00000000
		.byte	%10100001, %10100000, %00000000
		.byte	%10111010, %01000000, %00000000
		.byte	%01000111, %10000000, %00000000
		.byte	%00111000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	$00

  ; FG (1)
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00001111, %11100000, %00000000
		.byte	%00011111, %11100000, %00000000
		.byte	%00011111, %11100000, %00000000
		.byte	%00011111, %11100000, %00000000
		.byte	%00001111, %11000000, %00000000
		.byte	%00000000, %00000000, %00000000
		.byte	%00000001, %11000000, %00000000
		.byte	%00000011, %10000000, %00000000
		.byte	%00011000, %00000000, %00000000
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

init:
		;LDA	#$8E			;go to uppercase characters
		;JSR	krnlOutChr
		;LDA	#$08			;disable change character case
		;JSR	krnlOutChr
	
		SEI
		CLD

		LDA	#$00
		STA	$00
		LDA	#$37
		STA	$01

		LDA	#$00
		LDX	#$0F
		LDY	#$00
		LDZ	#$0F
		MAP

		LDA	#0
		TAX
		TAY
		TAZ
		MAP
		EOM

		LDA	#$00
		STA	$D02F

		LDA	#$7F			;disable standard CIA irqs
		STA	cia1IRQCtl

    JSR initROM
    JSR initM65IOFast
    JSR initHiVars
    JSR initMem
		JSR	initCore

;	Reset the stack pointer

		LDX	#$FF
		TXS

		JMP 	main

;-------------------------------------------------------------------------------
initROM:
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

    RTS


;-------------------------------------------------------------------------------
;	High memory ($E000-$FFF9, see m65.cfg's HIMEM/HIVARS) is bss - it
;	costs nothing in the .prg, but that also means it's genuine
;	garbage until cleared here, once, at startup (initROM must run
;	first so it's actually RAM under the banked-out KERNAL). Inline
;	enhanced DMA fill job rather than a CPU loop.
	.import	__HIMEM_START__
	.import	__HIMEM_SIZE__
initHiVars:
;-------------------------------------------------------------------------------
		STA	$D707
		.byte	$00			;end of job options
		.byte	$03			;fill
		.word	__HIMEM_SIZE__		;count
		.word	$0000			;value (fill byte in low byte)
		.byte	$00			;src bank
		.word	__HIMEM_START__		;dst
		.byte	$00			;dst bank
		.byte	$00			;cmd hi
		.word	$0000			;modulo/ignored

		RTS


;-------------------------------------------------------------------------------
initMem:
;-------------------------------------------------------------------------------

;	Init mouse pointer RAM from ONCE segment 
		
		LDA	#<sprPointer0
		STA	tempptr0
		LDA	#>sprPointer0
		STA	tempptr0 + 1
		
		LDA	#<spriteMem20		
		STA	tempptr1
		LDA	#>spriteMem20
		STA	tempptr1 + 1
		
		LDY	#$0F
@loop5:						
		LDA	(tempptr0), Y
		STA	(tempptr1), Y
		
		DEY
		BPL	@loop5

;	Initialise state

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
		
		STA	uiflshcnt
		STA	room_log_notify_cnt
		STA	crsr_active
		STA	crsr_on

;	Initialise logs

		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1

		JSR	ctrlsLogPanelInit

		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1

		JSR	ctrlsLogPanelInit
		
		LDA	#$01
		STA	room_haveblank
		LDA	#$00
		STA	room_lastuser
		
		
;	Intialise keyboard handler

		LDA	#$00
		STA	keyRepeatFlag
;		LDA	#$80
;		STA	keyModifierLock
		LDA	#$14
		STA	keyBufferSize

		RTS


;-----------------------------------------------------------
initM65IOFast:
;-----------------------------------------------------------
;	Go fast, first attempt
		LDA	#65
		STA	$00

;	Enable M65 enhanced registers
		LDA	#$47
		STA	$D02F
		LDA	#$53
		STA	$D02F
;	Switch to fast mode, be sure
; 	1. C65 fast-mode enable
		LDA	$D031
		ORA	#$40
		STA	$D031
; 	2. MEGA65 40.5MHz enable (requires C65 or C128 fast mode to truly enable, 
;	hence the above)
;		LDA	#$40
		LDA	#$C0
		TSB	$D054
		
		RTS


;-------------------------------------------------------------------------------
initGameData:
;-------------------------------------------------------------------------------
		LDA	#$FF
		LDX	#GAME::ourslt
		STA	gameData, X
		INX
		STA	gameData, X		;detslt
		INX
		STA	gameData, X		;plyslt

		LDX	#$05
@loop0:
		LDA	game_slot_lo, X
		STA	tempptr0
		LDA	#>gameData
		STA	tempptr0 + 1
		
		LDA	#$FF
		LDY	#.sizeof(SCRSHEET) - 1
@loop1:
		STA	(tempptr0), Y
		DEY
		BPL	@loop1
		
		LDA	#$00
		LDY	#.sizeof(SCRSHEET)
@loop2:
		STA	(tempptr0), Y
		INY
		CPY	#.sizeof(GAMESLOT)
		BNE	@loop2

		DEX
		BPL	@loop0

		LDA	#$00
		LDX	#GAME::state
		STA	gameData, X
		INX
		STA	gameData, X
		INX
		STA	gameData, X

		RTS


	.export	initCore
;-------------------------------------------------------------------------------
initCore:
;-------------------------------------------------------------------------------
		;JSR	initMem
		
    JSR initScreen
    JSR	initSprites
		
		JSR	initGameData
		
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
initScreen:
;-------------------------------------------------------------------------------
;	D018 charset nibble = 2 ($1000) - lowercase/symbol charset
		LDA	#$24
		STA	$D018

;	D054 = $80 (FCLRHI only) - clears the 40.5MHz-fast bit that
;	initM65IOFast just set via TSB; overwritten again further down anyway
		LDA	#$80
		STA	$D054

;	Clears D05D bit 7 - exact documented meaning not confirmed, verify
;	before trusting the old "prevent VIC-II compatibility changes" claim
		LDA	#$80
		TRB	$D05D

		LDA	#$00
		STA	$D020		;border colour
		LDA	#$00
		STA	$D021		;background colour

;	32-bit screen RAM address (D060-D063) = $00000400
		LDA	#<$0400
		STA	$D060
		LDA	#>$0400
		STA	$D061
		LDA	#$00
		STA	$D062
		STA	$D063

;	D030 bit 2 set - use palette RAM entries for colours 0-15
		LDA	$D030
		ORA	#$04
		STA	$D030

;	D031 = $40 (FAST bit only - H640/V400/BPM/ATTR all clear, so this is
;	still classic 40-column addressing, not 80-column)
		LDA	#$40
		STA	$D031

;	D058/D059 = 40 - text row stride in bytes (one byte per character,
;	40 columns, NOT the 160/80-column figure the old comment claimed)
		LDA #<$28
		STA $D058
		LDA #>$28
		STA $D059

;	D05E = 40 - characters per row (again 40, not 80)
		LDA	#$28
		STA	$D05E

;	D054 = $40 (FAST bit only, FCLRHI cleared) - overwrites the $80
;	written above; net effect of the two D054 writes is just FAST set
		LDA	#$40
		STA	$D054

;	D064/D065 - documented meaning not confirmed
		LDA	#$00
		STA	$D064
		LDA	#$00
		STA	$D065

;	Clears D051 bit 7 - exact documented meaning not confirmed, verify
;	before trusting the old "FCM double-buffering" claim
		LDA #$00
		TRB $D051

;	D04C (text X position) = $50
		LDA	#$50
		STA	$D04C

;	Clears the low nibble of D04D, leaves the high nibble untouched
		LDA	$D04D
		AND	#$F0
		STA	$D04D

    RTS



;-------------------------------------------------------------------------------
initSprites:
;-------------------------------------------------------------------------------
;	Init location of sprite pointers
    LDA #<spritePtr0
    STA $D06C
    LDA #>spritePtr0
    STA $D06D

; Init y position offset
    LDA #$18
    STA $D072

;	Init sprite RAM locations - busy sprite by default, via the push/pop
;	mechanism below so it plays nicely with anything else that pushes.
		JSR	userCursorPushBusy

;	Turn off MCM and expansion

		LDA	#$00			;MCM none
		STA	vicSprCMod
		STA	vicSprExpX
		STA	vicSprExpY

;	Enable all of the sprites required

		LDA	#$0F			;sprites
		STA	vicSprEnab

		RTS


;-------------------------------------------------------------------------------
;	Cursor busy/pointer sprite switching, nested via cursorBusyCnt so
;	several overlapping "this will take a while" operations don't let
;	one finishing early flip back to the pointer while another is still
;	in flight - only the pop that brings the counter back to 0 actually
;	restores the pointer sprite.
;-------------------------------------------------------------------------------

	.export	userCursorSetBusy
;-------------------------------------------------------------------------------
userCursorSetBusy:
;-------------------------------------------------------------------------------
		LDA	#$24
		STA	spritePtr0
		LDA	#$25
		STA	spritePtr1
		LDA	#$26
		STA	spritePtr2
		LDA	#$27
		STA	spritePtr3

		RTS


	.export	userCursorSetPointer
;-------------------------------------------------------------------------------
userCursorSetPointer:
;-------------------------------------------------------------------------------
		LDA	#$20
		STA	spritePtr0
		LDA	#$21
		STA	spritePtr1
		LDA	#$22
		STA	spritePtr2
		LDA	#$23
		STA	spritePtr3

		RTS


	.export	userCursorPushBusy
;-------------------------------------------------------------------------------
userCursorPushBusy:
;-------------------------------------------------------------------------------
		LDA	cursorBusyCnt
		BNE	@nested

		JSR	userCursorSetBusy

@nested:
		INC	cursorBusyCnt

		RTS


	.export	userCursorPopBusy
;-------------------------------------------------------------------------------
userCursorPopBusy:
;-------------------------------------------------------------------------------
		LDA	cursorBusyCnt
		BEQ	@exit			;already at rest - underflow guard

		DEC	cursorBusyCnt
		BNE	@exit

		JSR	userCursorSetPointer

@exit:
		RTS


cursorBusyCnt:
		.byte	$00


;-------------------------------------------------------------------------------
initUser:
;-------------------------------------------------------------------------------
;	Update the mouse pointer position

		JSR	CMOVEX
		JSR	CMOVEY

;	Install the UI IRQ handler

		JSR	userIRQInstall

		RTS



;===============================================================================
;USER INTERFACE DEFINITIONS
;===============================================================================

.out .sprintf("UI control definitions start: * = $%04X", *)

	.export	page_splsh
;-------------------------------------------------------------------------------
page_splsh:
;			.word	$0000		;prepare
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
			.word	$0000		;nxtpage
			.word	$0000		;bakpage
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_TAB
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00 		;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$00		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$03		;height	.byte
			.byte	$00		;tag	.byte
			.word	$0000
			.word	tab_main_ctrls	;controls .word
			.byte	$07
			.word	$0000		;page	.word
			
tab_main_ctrls:
			.word	tlabel_main_begin
			.word	tlabel_main_chat
			.word	tlabel_main_play
			.word	tlabel_main_prefs
			.word	hlabel_main_page
			.word 	button_main_back
			.word 	button_main_next
			.word	$0000

tlabel_main_begin:
;			.word	$0000		;prepare
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
			.byte	$00		;textoffx .byte
			.byte	$00		;textaccel .byte
			.byte	KEY_C64_F1	;accelchar .byte
			.word	$0000		;actvctrl .word
			
tlabel_main_chat:
;			.word	$0000		;prepare
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
			.byte	$01		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	KEY_C64_F3		;accelchar .byte
			.word	$0000		;actvctrl .word
		
tlabel_main_play:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientMainPlayChng	;changed .word
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
			.byte	$01		;textoffx .byte
			.byte	$01		;teXtaccel .byte
			.byte	KEY_C64_F5		;accelchar .byte
			.word	$0000		;actvctrl .word

tlabel_main_prefs:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientMainPrefsChng	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NODOWNACTV | OPT_TEXTACCEL2X
			.byte	CLR_FACE	;colour	.byte
			.byte	$1B		;posx	.byte
			.byte	$00		;posy	.byte
			.byte	$09		;width	.byte
			.byte	$02		;height	.byte
			.byte	$00		;tag	.byte
			.word	tab_main	;panel	.word
			.word	text_main_prefs ;textptr	.word
			.byte	$01		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	KEY_C64_F9		;accelchar .byte
			.word	$0000		;actvctrl .word

hlabel_main_page:
;			.word	$0000		;prepare
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
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.word	$0000		;actvctrl .word

button_main_back:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientMainBackChng
			.word	$0000		;keypress .word
			.byte	$00 
			.byte	OPT_TEXTACCEL2X	;options	.byte
			.byte	CLR_FOCUS	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$02		;posy	.byte
			.byte	$0A		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	tab_main	;panel	.word
			.word	text_main_back	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	KEY_C64_F8	;accelchar .byte
			
button_main_next:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientMainNextChng
			.word	$0000		;keypress .word
			.byte	$00
			.byte	OPT_TEXTACCEL2X	;options	.byte
			.byte	CLR_FOCUS	;colour	.byte
			.byte	$1E		;posx	.byte
			.byte	$02		;posy	.byte
			.byte	$0A		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	tab_main	;panel	.word
			.word	text_main_next	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	KEY_C64_F7	;accelchar .byte


page_config:
;			.word	$0000		;prepare
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
			.word	$0000		;nxtpage
			.word	$0000		;bakpage
			.word	text_page_config;textptr	.word
			.byte	$10		;textoffx .byte
			.word	page_config_pnls;panels	.word
			.byte	$03

page_config_pnls:
			.word	tab_main
			.word	panel_config_mouse
			.word	panel_config_theme
			.word	$0000

panel_config_mouse:
;			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_PANEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$14		;width	.byte
			.byte	$16		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_config
			.word	panel_config_mouse_ctrls;controls .word
			.byte	$04

panel_config_mouse_ctrls:
			.word	label_config_mouse
			.word	checkbx_config_mouse_slow
			.word	checkbx_config_mouse_medium
			.word	checkbx_config_mouse_fast
			.word	$0000

label_config_mouse:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$01		;posx	.byte
			.byte	$04		;posy	.byte
			.byte	$12		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_config_mouse	;panel	.word
			.word	text_config_mouse;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.word	$0000		;actvctrl .word

checkbx_config_mouse_slow:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	clientConfigSpeedSlowChng	;changed
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_AUTOCHECK		;options
			.byte	CLR_FACE		;colour
			.byte	$02			;posx
			.byte	$06			;posy
			.byte	$10			;width
			.byte	$01			;height
			.byte	$00			;tag	- unchecked
			.word	panel_config_mouse	;panel
			.word	text_config_mouse_slow	;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	KEY_ASC_L_S	;accelchar

checkbx_config_mouse_medium:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	clientConfigSpeedMediumChng	;changed
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_AUTOCHECK		;options
			.byte	CLR_FACE		;colour
			.byte	$02			;posx
			.byte	$08			;posy
			.byte	$10			;width
			.byte	$01			;height
			.byte	$01			;tag	- checked (default speed)
			.word	panel_config_mouse	;panel
			.word	text_config_mouse_medium	;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	KEY_ASC_L_M			;accelchar

checkbx_config_mouse_fast:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	clientConfigSpeedFastChng	;changed
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_AUTOCHECK		;options
			.byte	CLR_FACE		;colour
			.byte	$02			;posx
			.byte	$0A			;posy
			.byte	$10			;width
			.byte	$01			;height
			.byte	$00			;tag	- unchecked
			.word	panel_config_mouse	;panel
			.word	text_config_mouse_fast	;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	KEY_ASC_L_F		;accelchar


panel_config_theme:
;			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_PANEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$14		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$14		;width	.byte
			.byte	$16		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_config
			.word	panel_config_theme_ctrls;controls .word
			.byte	$06

panel_config_theme_ctrls:
			.word	label_config_theme
			.word	button_config_theme_prv
			.word	button_config_theme_nxt
			.word	label_config_theme_name
			.word	label_config_interface
			.word	checkbx_config_flashchat
			.word	$0000

label_config_theme:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$15		;posx	.byte
			.byte	$04		;posy	.byte
			.byte	$12		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_config_theme	;panel	.word
			.word	text_config_theme;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.word	$0000		;actvctrl .word

button_config_theme_prv:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientConfigThemePrvChng	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00		;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$16		;posx	.byte
			.byte	$06		;posy	.byte
			.byte	$07		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_config_theme	;panel	.word
			.word	text_config_theme_prv	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$03		;textaccel .byte
			.byte	KEY_ASC_L_P		;accelchar .byte

button_config_theme_nxt:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientConfigThemeNxtChng	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00		;options	.byte
			.byte	CLR_FACE	;colour	.byte
			.byte	$1F		;posx	.byte
			.byte	$06		;posy	.byte
			.byte	$07		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_config_theme	;panel	.word
			.word	text_config_theme_nxt	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$01		;textaccel .byte
			.byte	KEY_ASC_L_N		;accelchar .byte

label_config_theme_name:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	.byte
			.byte	$16		;posx	.byte
			.byte	$08		;posy	.byte
			.byte	$10		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_config_theme	;panel	.word
			.word	name_clrschme0	;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.word	$0000		;actvctrl .word

label_config_interface:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$15		;posx	.byte
			.byte	$0B		;posy	.byte
			.byte	$12		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_config_theme	;panel	.word
			.word	text_config_interface;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.word	$0000		;actvctrl .word

checkbx_config_flashchat:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	ctrlsControlDefChanged	;changed - plain toggle, roomLogNotifyUpdate reads the tag directly
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_AUTOCHECK		;options
			.byte	CLR_FACE		;colour
			.byte	$15			;posx
			.byte	$0D			;posy
			.byte	$13			;width
			.byte	$01			;height
			.byte	$01			;tag	- checked (default on)
			.word	panel_config_theme	;panel
			.word	text_config_flashchat	;textptr
			.byte	$00			;textoffx
			.byte	$03			;textaccel
			.byte	KEY_ASC_L_A			;accelchar


page_connect:
;			.word	$0000		;prepare
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
			.word	$0000		;nxtpage
			.word	$0000		;bakpage
			.word	text_page_connect;textptr	.word
			.byte	$10		;textoffx .byte
			.word	page_connect_pnls;panels	.word
			.byte	$03

page_connect_pnls:
			.word	tab_main
			.word	panel_cnct_data
			.word	lpanel_cnct_log
			.word	$0000
			
panel_cnct_data:
;			.word	$0000		;prepare
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
			.word	edit_cnct_info
			.word	$0000

label_cnct_host:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	ctrlsLabelDefChanged	;changed
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
			.byte	$00		;textoffx .byte
			.byte	$00		;textaccel .byte
			.byte	'h'		;accelchar .byte
			.word	edit_cnct_host	;actvctrl .word
			
edit_cnct_host:
;			.word	$0000		;prepare
			.word	ctrlsEditDefPresent
			.word	$0000		;changed .word
			.word	ctrlsEditDefKeyPress
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_TEXTCONTMRK | OPT_CAPTURECRSR
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
			.byte	$0D		;textsiz
			.byte	$3C		;textmaxsz
			

edit_cnct_host_buf:
			.asciiz "192.168.137.1"
	.repeat	48	
			.byte	$00
	.endrep

label_cnct_user:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	ctrlsLabelDefChanged	;changed
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
			.byte	$00		;textoffx .byte
			.byte	$00		;textaccel .byte
			.byte	'u'		;accelchar .byte
			.word	edit_cnct_user	;actvctrl .word
			
edit_cnct_user:
;			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	$0000			;changed
			.word	ctrlsEditDefKeyPress
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_CAPTURECRSR
			.byte	CLR_PAPER		;colour	
			.byte	$0B			;posx	
			.byte	$06			;posy	
			.byte	$09			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_cnct_data		;panel	
			.word	edit_cnct_user_buf
			.byte	$00			;textoffx 
			.byte	$FF			;textaccel 
			.byte	$00			;accelchar 
			.byte	$00			;textsiz
			.byte	$08			;textmaxsz

edit_cnct_user_buf:
	.repeat	9
			.byte	$00
	.endrep

;	Set once the server has echoed our username back as accepted
;	(clientProcConctMsg's @ident case) - the server only accepts one
;	clientSendUser per connection, so button_cnct_upd gets disabled
;	once this is set.
userNameAccepted:
			.byte	$00


button_cnct_upd:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	clientCnctUpdChng	;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
;	Always visible (looked wrong toggling with the connect state) -
;	enabled once connected, disabled again once the server accepts
;	our username (it only accepts one clientSendUser per connection).
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
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
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000		;keypress .word
;			.byte	TYPE_LABEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$0A		;posy	.byte
			.byte	$0B		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	text_cnct_info  ;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.word	edit_cnct_info	;actvctrl .word


edit_cnct_info:
;			.word	$0000		;prepare
			.word	ctrlsEditDefPresent		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE		;options	.byte
			.byte	CLR_TEXT	;colour	.byte
			.byte	$0B		;posx	.byte
			.byte	$0A		;posy	.byte
			.byte	$1D		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_cnct_data	;panel	.word
			.word	edit_cnct_info_buf ;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte
			.byte	$00			;textsiz
			.byte	$2A			;textmaxsz

edit_cnct_info_buf:
	.repeat	43	
			.byte	$00
	.endrep


lpanel_cnct_log:
;			.word	$0000			;prepare
			.word	ctrlsLPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT		;colour	
			.byte	$00			;posx	
			.byte	$0C			;posy	
			.byte	$28			;width	
			.byte	$0D			;height	
			.byte	$00			;tag	
			.word	page_connect
			.word	lpanel_cnct_log_ctrls	;controls
			.byte	$00
			.word	lpanel_cnct_log_lines
			.byte	$0D
			.byte	$00
			.byte	$00			;offsy

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
;			.word	$0000		;prepare
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
			.word	$0000		;nxtpage
			.word	$0000		;bakpage
			.word	text_page_room	;textptr	.word
			.byte	$12		;textoffx .byte
			.word	page_room_pnls	;panels	.word
			.byte	$05

page_room_pnls:
			.word	tab_main
			.word	panel_room_more
			.word	lpanel_room_log
			.word	panel_room_data
			.word 	panel_room_less
			.word	$0000
			
panel_room_less:
;			.word	$0000			;prepare
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
;			.word	$0000			;prepare
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
;			.word	$0000			;prepare
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
			.byte	$08
			
panel_room_more_ctrls:
			.word	label_room_room
			.word	edit_room_room
			.word	button_room_list
			.word	label_room_pwd
			.word	edit_room_pwd
			.word	button_room_join
			.word	button_room_part
			.word	button_room_less
			.word	$0000

label_room_room:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	ctrlsLabelDefChanged	;changed
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
			.byte	$00			;textoffx .byte
			.byte	$00			;textaccel .byte
			.byte	'r'			;accelchar .byte
			.word	edit_room_room		;actvctrl .word

edit_room_room:
;			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	$0000			;changed .word
			.word	ctrlsEditDefKeyPress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_CAPTURECRSR
			.byte	CLR_PAPER		;colour	.byte
			.byte	$0C			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$09			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	edit_room_room_buf
			.byte	$00			;textoffx .byte
			.byte	$FF			;textaccel .byte
			.byte	$00			;accelchar .byte
			.byte	$00			;textsiz
			.byte	$08			;textmaxsz

edit_room_room_buf:
	.repeat	9	
			.byte	$00
	.endrep

button_room_list:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	clientRoomListChng
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
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$06			;posy	
			.byte	$0C			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_room_more		;panel	
			.word	text_room_pwd	  	;textptr
			.byte	$00			;textoffx 
			.byte	$02			;textaccel
			.byte	's'			;accelchar
			.word	edit_room_pwd		;actvctrl 

edit_room_pwd:
;			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	$0000			;changed .word
			.word	ctrlsEditDefKeyPress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_CAPTURECRSR
			.byte	CLR_PAPER		;colour	.byte
			.byte	$0C			;posx	.byte
			.byte	$06			;posy	.byte
			.byte	$09			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_room_more		;panel	.word
			.word	edit_room_pwd_buf
			.byte	$00			;textoffx .byte
			.byte	$FF			;textaccel .byte
			.byte	$00			;accelchar .byte
			.byte	$00			;textsiz
			.byte	$08			;textmaxsz

edit_room_pwd_buf:
	.repeat	9	
			.byte	$00
	.endrep

button_room_join:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientRoomJoinChng
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$1E			;posx	
			.byte	$06			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_room_more		;panel	
			.word	text_room_join		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'j'			;accelchar

button_room_part:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientRoomPartChng
			.word	$0000			;keypress 
			.byte	$00
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$1E			;posx	
			.byte	$06			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_room_more		;panel	
			.word	text_room_part		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'p'			;accelchar

button_room_less:
;			.word	$0000			;prepare
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

lpanel_room_log:
;			.word	$0000			;prepare
			.word	ctrlsLPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
;			.byte	TYPE_PANEL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT		;colour	
			.byte	$00			;posx	
			.byte	$0A			;posy	
			.byte	$28			;width	
			.byte	$0D			;height	
			.byte	$00			;tag	
			.word	page_room
			.word	panel_room_log_ctrls	;controls 
			.byte	$00
			.word	lpanel_room_log_lines
			.byte	$11
			.byte	$10
			.byte	$04			;offsy

lpanel_room_log_lines:
			.word	room_log_line0
			.word	room_log_line1
			.word	room_log_line2
			.word	room_log_line3
			.word	room_log_line4
			.word	room_log_line5
			.word	room_log_line6
			.word	room_log_line7
			.word	room_log_line8
			.word	room_log_line9
			.word	room_log_lineA
			.word	room_log_lineB
			.word	room_log_lineC
			.word	room_log_lineD
			.word	room_log_lineE
			.word	room_log_lineF
			.word	room_log_line10

panel_room_log_ctrls:
			.word	$0000

panel_room_data:
;			.word	$0000		;prepare
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
;			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	ctrlsRoomTextChng	;changed
			.word	ctrlsEditDefKeyPress
;			.byte	TYPE_CONTROL
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_CAPTURECRSR
			.byte	CLR_PAPER		;colour	
			.byte	$00			;posx	
			.byte	$18			;posy	
			.byte	$28			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_room_data		;panel	
			.word	edit_room_text_buf	;textptr	
			.byte	$00			;textoffx 
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			.byte	$00			;textsiz
			.byte	$28			;textmaxsz
			
edit_room_text_buf:
	.repeat	41
			.byte	$00
	.endrep


page_play:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00 		;options	.byte
			.byte	CLR_TEXT	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$16		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_ovrvw	;nxtpage
			.word	$0000		;bakpage
			.word	text_page_play	;textptr	.word
			.byte	$12		;textoffx .byte
			.word	page_play_pnls	;panels	.word
			.byte	$05

page_play_pnls:
			.word	tab_main
			.word	panel_play_more
			.word	lpanel_play_log
			.word	panel_play_data
			.word 	panel_play_less
			.word	$0000
			
panel_play_less:
;			.word	$0000			;prepare
			.word	ctrlsPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
			.byte	$00
			.byte	$00
			.byte	CLR_INSET		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$03			;posy	.byte
			.byte	$28			;width	.byte
			.byte	$02			;height	.byte
			.byte	$00			;tag	.byte
			.word	page_play
			.word	panel_play_less_ctrls	;controls 
			.byte	$01
			
panel_play_less_ctrls:
			.word	button_play_more
			.word	$0000
			
button_play_more:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientPlayMoreChng
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_less		;panel	.word
			.word	text_room_more		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$08			;textaccel .byte
			.byte	'>'			;accelchar .byte			

panel_play_more:
;			.word	$0000			;prepare
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
			.word	page_play
			.word	panel_play_more_ctrls	;controls 
			.byte	$08
			
panel_play_more_ctrls:
			.word	label_play_game
			.word	edit_play_game
			.word	button_play_list
			.word	label_play_pwd
			.word	edit_play_pwd
			.word	button_play_join
			.word	button_play_part
			.word	button_play_less
			.word	$0000

label_play_game:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$0C			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_more		;panel	.word
			.word	text_play_game  	;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$00			;textaccel .byte
			.byte	'g'			;accelchar .byte
			.word	edit_play_game		;actvctrl .word

edit_play_game:
;			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	$0000			;changed .word
			.word	ctrlsEditDefKeyPress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_CAPTURECRSR
			.byte	CLR_PAPER		;colour	.byte
			.byte	$0C			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$09			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_more		;panel	.word
			.word	edit_play_game_buf
			.byte	$00			;textoffx .byte
			.byte	$FF			;textaccel .byte
			.byte	$00			;accelchar .byte
			.byte	$00			;textsiz
			.byte	$08			;textmaxsz

edit_play_game_buf:
	.repeat	9	
			.byte	$00
	.endrep

button_play_list:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	clientPlayListChng
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$04			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_more		;panel	.word
			.word	text_room_list		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$01			;textaccel .byte
			.byte	'l'			;accelchar .byte			

label_play_pwd:
;			.word	$0000			;prepare
			.word	$0000			;present
			.word	ctrlsLabelDefChanged	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$06			;posy	
			.byte	$0C			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_play_more		;panel	
			.word	text_room_pwd	  	;textptr
			.byte	$00			;textoffx 
			.byte	$02			;textaccel
			.byte	's'			;accelchar
			.word	edit_play_pwd		;actvctrl 

edit_play_pwd:
;			.word	$0000			;prepare
			.word	ctrlsEditDefPresent
			.word	$0000			;changed .word
			.word	ctrlsEditDefKeyPress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE | OPT_CAPTURECRSR
			.byte	CLR_PAPER		;colour	.byte
			.byte	$0C			;posx	.byte
			.byte	$06			;posy	.byte
			.byte	$09			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_more		;panel	.word
			.word	edit_play_pwd_buf
			.byte	$00			;textoffx .byte
			.byte	$FF			;textaccel .byte
			.byte	$00			;accelchar .byte
			.byte	$00			;textsiz
			.byte	$08			;textmaxsz

edit_play_pwd_buf:
	.repeat	9	
			.byte	$00
	.endrep

button_play_join:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientPlayJoinChng
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$06			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_more		;panel	.word
			.word	text_room_join		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$01			;textaccel .byte
			.byte	'j'			;accelchar .byte			

button_play_part:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientPlayPartChng
			.word	$0000			;keypress 
			.byte	$00
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$06			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_more		;panel	.word
			.word	text_room_part		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$01			;textaccel .byte
			.byte	'p'			;accelchar .byte

button_play_less:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientPlayLessChng
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options	.byte
			.byte	CLR_FACE		;colour	.byte
			.byte	$1E			;posx	.byte
			.byte	$08			;posy	.byte
			.byte	$0A			;width	.byte
			.byte	$01			;height	.byte
			.byte	$00			;tag	.byte
			.word	panel_play_more		;panel	.word
			.word	text_room_less		;textptr	.word
			.byte	$00			;textoffx .byte
			.byte	$08			;textaccel .byte
			.byte	'<'			;accelchar .byte			

lpanel_play_log:
;			.word	$0000			;prepare
			.word	ctrlsLPanelDefPresent	;present
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
			.word	page_play
			.word	panel_play_log_ctrls	;controls .word
			.byte	$00
			.word	lpanel_play_log_lines
			.byte	$11
			.byte	$10
			.byte	$04			;offsy

lpanel_play_log_lines:
			.word	play_log_line0
			.word	play_log_line1
			.word	play_log_line2
			.word	play_log_line3
			.word	play_log_line4
			.word	play_log_line5
			.word	play_log_line6
			.word	play_log_line7
			.word	play_log_line8
			.word	play_log_line9
			.word	play_log_lineA
			.word	play_log_lineB
			.word	play_log_lineC
			.word	play_log_lineD
			.word	play_log_lineE
			.word	play_log_lineF
			.word	play_log_line10

panel_play_log_ctrls:
			.word	$0000

panel_play_data:
;			.word	$0000		;prepare
			.word	ctrlsPanelDefPresent	;present	.word
			.word	ctrlsPanelDefChanged	;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00	 	;options	.byte
			.byte	CLR_INSET	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$17		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$02		;height	.byte
			.byte	$00		;tag	.byte
			.word	page_play
			.word	panel_play_data_ctrls	;controls .word
			.byte	$01

panel_play_data_ctrls:
			.word	edit_play_text
			.word	$0000

edit_play_text:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_DOWNCAPTURE
			.byte	CLR_PAPER	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$18		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$01		;height	.byte
			.byte	$00		;tag	.byte
			.word	panel_play_data	;panel	.word
			.word	$0000 		;textptr	.word
			.byte	$00		;textoffx .byte
			.byte	$FF		;textaccel .byte
			.byte	$00		;accelchar .byte

page_ovrvw:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00 		;options	.byte
			.byte	CLR_TEXT	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$16		;height	.byte
			.byte	PAGE_PLYOVRVW	;tag	.byte
			.word	$0000		;nxtpage
			.word	page_play	;bakpage
			.word	text_page_ovrvw	;textptr	.word
			.byte	$10		;textoffx .byte
			.word	page_ovrvw_pnls	;panels	.word
			.byte	$02

page_ovrvw_pnls:
			.word	tab_main
			.word	panel_ovrvw_ovrvw
			.word	$0000

panel_ovrvw_ovrvw:
;			.word	$0000			;prepare
			.word	ctrlsPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00
			.byte	CLR_INSET		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$03			;posy	.byte
			.byte	$28			;width	.byte
			.byte	$16			;height	.byte
			.byte	$00			;tag	.byte
			.word	page_ovrvw
			.word	panel_ovrvw_ovrvw_ctrls	;controls 
			.byte	$1C
			
panel_ovrvw_ovrvw_ctrls:
			.word	label_ovrvw_cntrl
			.word	button_ovrvw_cntrl
			.word	button_ovrvw_1p_det
			.word	label_ovrvw_1p_name
			.word	label_ovrvw_1p_stat
			.word	label_ovrvw_1p_score
			.word	button_ovrvw_2p_det
			.word	label_ovrvw_2p_name
			.word	label_ovrvw_2p_stat
			.word	label_ovrvw_2p_score
			.word	button_ovrvw_3p_det
			.word	label_ovrvw_3p_name
			.word	label_ovrvw_3p_stat
			.word	label_ovrvw_3p_score
			.word	button_ovrvw_4p_det
			.word	label_ovrvw_4p_name
			.word	label_ovrvw_4p_stat
			.word	label_ovrvw_4p_score
			.word	button_ovrvw_5p_det
			.word	label_ovrvw_5p_name
			.word	label_ovrvw_5p_stat
			.word	label_ovrvw_5p_score
			.word	button_ovrvw_6p_det
			.word	label_ovrvw_6p_name
			.word	label_ovrvw_6p_stat
			.word	label_ovrvw_6p_score
			.word	label_ovrvw_round
			.word	label_ovrwv_round_det
			.word	$0000

label_ovrvw_cntrl:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE	;colour	
			.byte	$00		;posx	
			.byte	$04		;posy	
			.byte	$0D		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_cntrl  ;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

button_ovrvw_cntrl:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientOvrvwCntrlChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE 
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$1E			;posx	
			.byte	$04			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_ready	;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'r'			;accelchar

button_ovrvw_1p_det:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientOvrvwDetChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE 
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$07			;posy	
			.byte	$04			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_1p		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'1'			;accelchar

label_ovrvw_1p_name:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	
			.byte	$04		;posx	
			.byte	$07		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	gameData + GAMESLOT::name
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_1p_stat:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	
			.byte	$04		;posx	
			.byte	$08		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	$0000		;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_1p_stat_buf:
	.repeat 9
			.byte	$00
	.endrep
	
label_ovrvw_1p_score:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_MONEY	;colour	
			.byte	$04		;posx	
			.byte	$09		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	label_ovrvw_1p_score_buf	;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_1p_score_buf:
	.repeat 9
			.byte	$00
	.endrep

button_ovrvw_2p_det:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientOvrvwDetChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE 
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$0D			;posx	
			.byte	$07			;posy	
			.byte	$04			;width	
			.byte	$01			;height	
			.byte	$01			;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_2p		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'2'			;accelchar

label_ovrvw_2p_name:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	
			.byte	$11		;posx	
			.byte	$07		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	gameData + .sizeof(GAMESLOT) + GAMESLOT::name
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_2p_stat:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	
			.byte	$11		;posx	
			.byte	$08		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	$0000		;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_2p_stat_buf:
	.repeat 9
			.byte	$00
	.endrep
	
label_ovrvw_2p_score:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE	;options
			.byte	CLR_MONEY	;colour	
			.byte	$11		;posx	
			.byte	$09		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	label_ovrvw_2p_score_buf;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_2p_score_buf:
	.repeat 9
			.byte	$00
	.endrep
	
button_ovrvw_3p_det:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientOvrvwDetChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE 
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$1A			;posx	
			.byte	$07			;posy	
			.byte	$04			;width	
			.byte	$01			;height	
			.byte	$02			;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_3p		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'3'			;accelchar

label_ovrvw_3p_name:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	
			.byte	$1E		;posx	
			.byte	$07		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	gameData + (.sizeof(GAMESLOT)*2) + GAMESLOT::name
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_3p_stat:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	
			.byte	$1E		;posx	
			.byte	$08		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	$0000		;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_3p_stat_buf:
	.repeat 9
			.byte	$00
	.endrep
	
label_ovrvw_3p_score:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE	;options
			.byte	CLR_MONEY	;colour	
			.byte	$1E		;posx	
			.byte	$09		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	label_ovrvw_3p_score_buf ;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_3p_score_buf:
	.repeat 9
			.byte	$00
	.endrep
	
button_ovrvw_4p_det:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientOvrvwDetChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE 
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$0B			;posy	
			.byte	$04			;width	
			.byte	$01			;height	
			.byte	$03			;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_4p		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'4'			;accelchar

label_ovrvw_4p_name:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	
			.byte	$04		;posx	
			.byte	$0B		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	gameData + (.sizeof(GAMESLOT)*3) + GAMESLOT::name
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_4p_stat:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	
			.byte	$04		;posx	
			.byte	$0C		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	$0000		;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_4p_stat_buf:
	.repeat 9
			.byte	$00
	.endrep
	
label_ovrvw_4p_score:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_MONEY	;colour	
			.byte	$04		;posx	
			.byte	$0D		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	label_ovrvw_4p_score_buf ;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_4p_score_buf:
	.repeat 9
			.byte	$00
	.endrep
	
button_ovrvw_5p_det:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientOvrvwDetChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE 
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$0D			;posx	
			.byte	$0B			;posy	
			.byte	$04			;width	
			.byte	$01			;height	
			.byte	$04			;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_5p		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'5'			;accelchar

label_ovrvw_5p_name:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	
			.byte	$11		;posx	
			.byte	$0B		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	gameData + (.sizeof(GAMESLOT)*4) + GAMESLOT::name
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_5p_stat:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	
			.byte	$11		;posx	
			.byte	$0C		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	$0000		;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_5p_stat_buf:
	.repeat 9
			.byte	$00
	.endrep
	
label_ovrvw_5p_score:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE	;options
			.byte	CLR_MONEY	;colour	
			.byte	$11		;posx	
			.byte	$0D		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	label_ovrvw_5p_score_buf ;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_5p_score_buf:
	.repeat 9
			.byte	$00
	.endrep
	
button_ovrvw_6p_det:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientOvrvwDetChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE 
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$1A			;posx	
			.byte	$0B			;posy	
			.byte	$04			;width	
			.byte	$01			;height	
			.byte	$05			;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_6p		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'6'			;accelchar

label_ovrvw_6p_name:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER	;colour	
			.byte	$1E		;posx	
			.byte	$0B		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	gameData + (.sizeof(GAMESLOT)*5) + GAMESLOT::name
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_6p_stat:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT	;colour	
			.byte	$1E		;posx	
			.byte	$0C		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	$0000		;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_6p_stat_buf:
	.repeat 9
			.byte	$00
	.endrep
	
label_ovrvw_6p_score:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE	;options
			.byte	CLR_MONEY	;colour	
			.byte	$1E		;posx	
			.byte	$0D		;posy	
			.byte	$08		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	label_ovrvw_6p_score_buf ;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrvw_6p_score_buf:
	.repeat 9
			.byte	$00
	.endrep
	
label_ovrvw_round:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE	;options
			.byte	CLR_FACE	;colour	
			.byte	$00		;posx	
			.byte	$11		;posy	
			.byte	$0D		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	text_ovrvw_round	;textptr
			.byte	$00		;textoffx
			.byte	$FF		;textaccel
			.byte	$00		;accelchar
			.word	$0000		;actvctrl 

label_ovrwv_round_det:
;			.word	$0000		;prepare
			.word	$0000		;present
			.word	$0000		;changed
			.word	$0000		;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE	;options
			.byte	CLR_TEXT	;colour	
			.byte	$0D		;posx	
			.byte	$11		;posy	
			.byte	$1B		;width	
			.byte	$01		;height	
			.byte	$00		;tag	
			.word	panel_ovrvw_ovrvw	;panel	
			.word	$0000		;textptr
			.byte	$00		;textoffx
			.byte	$00		;textaccel
			.byte	$FF		;accelchar
			.word	$0000		;actvctrl 

page_detail:
;			.word	$0000		;prepare
			.word	$0000		;present	.word
			.word	$0000		;changed .word
			.word	$0000		;keypress .word
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00 		;options	.byte
			.byte	CLR_TEXT	;colour	.byte
			.byte	$00		;posx	.byte
			.byte	$03		;posy	.byte
			.byte	$28		;width	.byte
			.byte	$16		;height	.byte
			.byte	PAGE_PLYDETAIL	;tag	.byte
			.word	$0000		;nxtpage
			.word	page_ovrvw	;bakpage
			.word	text_page_detail ;textptr	.word
			.byte	$10		;textoffx .byte
			.word	page_detail_pnls ;panels	.word
			.byte	$04

page_detail_pnls:
			.word	tab_main
			.word	panel_detail_top
			.word	panel_detail_bleft
			.word	spanel_detail_sheet
			.word	$0000

panel_detail_top:
;			.word	$0000			;prepare
			.word	ctrlsPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00
			.byte	CLR_INSET		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$03			;posy	.byte
			.byte	$28			;width	.byte
			.byte	$0B			;height	.byte
			.byte	$00			;tag	.byte
			.word	page_detail
			.word	panel_detail_top_ctrls	;controls 
			.byte	$11
			
panel_detail_top_ctrls:
			.word	static_det_ident
			.word	checkbx_det_flwactv
			.word	button_det_roll
			.word	button_det_keep1
			.word	button_det_keep2
			.word	button_det_keep3
			.word	button_det_keep4
			.word	button_det_keep5
			.word	die_det_0
			.word	die_det_1
			.word	die_det_2
			.word	die_det_3
			.word	die_det_4
			.word	static_det_yourlbl
			.word	static_det_yourscr
			.word	static_det_theirlbl
			.word	static_det_theirscr
			.word	$0000

static_det_ident:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_TEXT		;colour	
			.byte	$00			;posx	
			.byte	$04			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	$0000			;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			
checkbx_det_flwactv:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000			;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE |STATE_ENABLED
			.byte	OPT_AUTOCHECK		;options
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$06			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_flwactv	;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'f'			;accelchar

button_det_roll:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetRollChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$08			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_roll0		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'r'			;accelchar
			
button_det_keep1:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetKeepChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$0E			;posx	
			.byte	$04			;posy	
			.byte	$03			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_keep1		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'1'			;accelchar

button_det_keep2:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetKeepChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$13			;posx	
			.byte	$04			;posy	
			.byte	$03			;width	
			.byte	$01			;height	
			.byte	$01			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_keep2		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'2'			;accelchar

button_det_keep3:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetKeepChng 	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$18			;posx	
			.byte	$04			;posy	
			.byte	$03			;width	
			.byte	$01			;height	
			.byte	$02			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_keep3		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'3'			;accelchar

button_det_keep4:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetKeepChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$1D			;posx	
			.byte	$04			;posy	
			.byte	$03			;width	
			.byte	$01			;height	
			.byte	$03			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_keep4		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'4'			;accelchar

button_det_keep5:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetKeepChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$22			;posx	
			.byte	$04			;posy	
			.byte	$03			;width	
			.byte	$01			;height	
			.byte	$04			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_keep5		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'5'			;accelchar

die_det_0:
;			.word	$0000			;prepare
			.word	ctrlsDieDefPresent	;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_DIE			;colour	
			.byte	$0E			;posx	
			.byte	$06			;posy	
			.byte	$03			;width	
			.byte	$05			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	$0000			;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			.byte	$01			;value

die_det_1:
;			.word	$0000			;prepare
			.word	ctrlsDieDefPresent	;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_DIE			;colour	
			.byte	$13			;posx	
			.byte	$06			;posy	
			.byte	$03			;width	
			.byte	$05			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	$0000			;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			.byte	$02			;value

die_det_2:
;			.word	$0000			;prepare
			.word	ctrlsDieDefPresent	;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_DIE			;colour	
			.byte	$18			;posx	
			.byte	$06			;posy	
			.byte	$03			;width	
			.byte	$05			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	$0000			;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			.byte	$03			;value

die_det_3:
;			.word	$0000			;prepare
			.word	ctrlsDieDefPresent	;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_DIE			;colour	
			.byte	$1D			;posx	
			.byte	$06			;posy	
			.byte	$03			;width	
			.byte	$05			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	$0000			;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			.byte	$04			;value

die_det_4:
;			.word	$0000			;prepare
			.word	ctrlsDieDefPresent	;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_DIE			;colour	
			.byte	$22			;posx	
			.byte	$06			;posy	
			.byte	$03			;width	
			.byte	$05			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	$0000			;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			.byte	$05			;value

static_det_yourlbl:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$0C			;posy	
			.byte	$0C			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_your		;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			
static_det_yourscr:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER		;colour	
			.byte	$0C			;posx	
			.byte	$0C			;posy	
			.byte	$05			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_yourscr_buf	;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			
text_det_yourscr_buf:
	.repeat	6
			.byte	$00
	.endrep
			
static_det_theirlbl:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_FACE		;colour	
			.byte	$13			;posx	
			.byte	$0C			;posy	
			.byte	$0D			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_their		;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			
static_det_theirscr:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	$0000			;changed 
			.word	$0000			;keypress
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NONAVIGATE
			.byte	CLR_PAPER		;colour	
			.byte	$20			;posx	
			.byte	$0C			;posy	
			.byte	$05			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_top	;panel	
			.word	text_det_theirscr_buf	;textptr	
			.byte	$00			;textoffx
			.byte	$FF			;textaccel
			.byte	$00			;accelchar
			
text_det_theirscr_buf:
	.repeat	6
			.byte	$00
	.endrep
			
panel_detail_bleft:
;			.word	$0000			;prepare
			.word	ctrlsPanelDefPresent	;present
			.word	ctrlsPanelDefChanged	;changed 
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00
			.byte	CLR_INSET		;colour	.byte
			.byte	$00			;posx	.byte
			.byte	$0E			;posy	.byte
			.byte	$28			;width	.byte
			.byte	$0B			;height	.byte
			.byte	$00			;tag	.byte
			.word	page_detail
			.word	panel_detail_bleft_ctrls	;controls 
			.byte	$02

panel_detail_bleft_ctrls:
			.word	button_det_select
			.word	button_det_confirm
			.word	$0000
			
button_det_select:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetSelectChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$0E			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_bleft	;panel	
			.word	text_det_select		;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	's'			;accelchar

button_det_confirm:
;			.word	$0000			;prepare
			.word	$0000			;present	
			.word	clientDetConfirmChng	;changed
			.word	$0000			;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	$00			;options
			.byte	CLR_FACE		;colour	
			.byte	$00			;posx	
			.byte	$10			;posy	
			.byte	$0A			;width	
			.byte	$01			;height	
			.byte	$00			;tag	
			.word	panel_detail_bleft	;panel	
			.word	text_det_confirm	;textptr
			.byte	$00			;textoffx
			.byte	$01			;textaccel
			.byte	'c'			;accelchar

spanel_detail_sheet:
;			.word	$0000			;prepare
			.word	ctrlsSPanelDefPresent	;present
			.word	ctrlsSPanelDefChanged	;changed 
			.word	ctrlsSPanelDefKeyPress	;keypress 
			.byte	STATE_VISIBLE | STATE_ENABLED
			.byte	OPT_NOAUTOINVL | OPT_NONAVIGATE | OPT_DOWNCAPTURE
			.byte	CLR_TEXT		;colour	
			.byte	$0C			;posx	
			.byte	$0E			;posy	
			.byte	$1C			;width	
			.byte	$0B			;height	
			.byte	$FF			;tag	
			.word	page_detail		;page
			.word	spanel_detail_sheet_ctrls ;controls 
			.byte	$00
			.byte	$FF			;lastind
			.byte	$00			;hveprvw

spanel_detail_sheet_ctrls:
			.word	$0000

.out .sprintf("UI control definitions end: * = $%04X", *)

.out .sprintf("Before eth.bin pad: * = $%04X, room until $2000 = %d bytes", *, $2000 - *)

.res    $2000 - *, 0

.assert * = $2000, error, "eth.bin must load at $2000 - mega-ip's own jump table (MIP_INIT etc.) is hardcoded to that address, layout above no longer adds up"

.incbin "eth.bin"


;===============================================================================

;===============================================================================
;	.segment	"CODE"
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

mouseCapture:
			.byte	0
mouseCapCtrl:
			.word	$0000
mouseCapMove:
			.word	$0000
mouseCapClick:
			.word	$0000


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
;	Cursor blink delay, in frames - 10 on NTSC, 8 on PAL, so the
;	blink period comes out close to the same wall-clock time on both
;	(NTSC's ~16.7ms/frame vs PAL's ~20ms/frame).
;	OUT	.A		frame delay
;-------------------------------------------------------------------------------
crsrBlinkDelay:
;-------------------------------------------------------------------------------
		LDA	sys_ntsc_flag
		BEQ	@pal

		LDA	#10
		RTS

@pal:
		LDA	#8
		RTS


;-------------------------------------------------------------------------------
userIRQHandler:
;-------------------------------------------------------------------------------
	.if	DEBUG_RASTERTIME
		LDA	#$00
		STA	vicBrdrClr
	.endif


;	UI notify with flash?
		LDA	uiflshcnt
		BEQ	@flshfin
		
		LDA	uiflshdly
		BEQ	@flash
		
		DEC	uiflshdly
		JMP	@flshfin
		
@flash:
		LDA	uiflshcnt
		
		AND	#$01
		BNE	@flshoff
		
		LDA	#$01
		STA	vicBrdrClr
		
		JMP	@flshdone
		
@flshoff:
		LDA	current_clrs
		STA	vicBrdrClr
		
		
@flshdone:
		LDA	#$08
		STA	uiflshdly
		
		DEC	uiflshcnt

@flshfin:
;	Blinking text-entry cursor - every crsrBlinkDelay frames (10 on
;	NTSC, 8 on PAL), XOR $80 (reverse video) into whatever character
;	is currently at crsr_col/crsr_row. crsr_on tracks which phase
;	we're in so ctrlsUnDownCtrl knows whether a matching XOR is
;	needed to restore the cell on release.
		LDA	crsr_active
		BEQ	@crsrfin

		LDA	crsr_dly
		BEQ	@crsrflash

		DEC	crsr_dly
		JMP	@crsrfin

@crsrflash:
		LDA	crsr_on
		EOR	#$01
		STA	crsr_on

		LDY	crsr_row
		LDA	screenRowsLo, Y
		STA	tempptr1
		LDA	screenRowsHi, Y
		STA	tempptr1 + 1

		LDY	crsr_col
		LDA	(tempptr1), Y
		EOR	#$80
		STA	(tempptr1), Y

		JSR	crsrBlinkDelay
		STA	crsr_dly

@crsrfin:
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
;	MODKEY ($D60A[0:6]) for the event currently at the head of the
;	queue - read before popping ASCIIKEY below, so it can't end up
;	describing a different (later) keypress. Bit 7 (KEYQUEUE) is
;	masked off; the remaining 7 bits match the keyMod* defines above
;	exactly, so no translation is needed.
    LDA $D60A
    AND #$7F
    TAY

    LDA $D610
    BEQ @done

    STA $D610

    LDX keyZPKeyCount
    CPX keyBufferSize
    BCS @done

    STA keyBuffer0, X
    INX
    TYA
    STA keyBuffer0, X
    INX

    STX keyZPKeyCount

@done:
    RTS

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

		LDA	mouseCapture
		BEQ	@tstpick

		RTS

@tstpick:
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

		LDA	mouseCapture
		BEQ	@findctrl
		
		JMP	(mouseCapMove)

;	Find last panel on page
@findctrl:		
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
;	for each panel on page rev
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

;	find coord in panel

		LDA	panlptr0
		STA	elemptr0
		LDA	panlptr0 + 1
		STA	elemptr0 + 1

		JSR	userMouseInCtrl
		BCC	@panelnext

;	for each elem in panel 

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

;	find coord in elem on panel
		
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

;	find coord in elem

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

		LDA	mouseCapture
		BEQ	@norm
		
		JMP	(mouseCapClick)

@norm:
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
userCaptureMouse:
;-------------------------------------------------------------------------------
		SEI
		
		LDA	mouseCapture
		BNE	@exit
		
		LDA	#$01
		STA	mouseCapture
		
@exit:
		CLI
		
		RTS


;-------------------------------------------------------------------------------
userReleaseMouse:
;-------------------------------------------------------------------------------
		SEI
		
		LDA	mouseCapture
		BEQ	@exit
		
		LDA	#$00
		STA	mouseCapture
		
@exit:
		CLI
		
		RTS


;-------------------------------------------------------------------------------
;	userProcessMouse/MoveCheck moved to mouse.inc (proportional mouse
;	with acceleration + joystick fire button). Original kept at
;	src/backup/userProcessMouse_old.s.
;-------------------------------------------------------------------------------
	.include "mouse.inc"


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
;MAIN PROGRAM CODE STARTS HERE
;===============================================================================



	.export main
;-------------------------------------------------------------------------------
main:
;-------------------------------------------------------------------------------
;	Initialise the screen

;	Bit 7 of $D06F is set on an NTSC machine, clear on PAL. It can change
;	dynamically, but we only care about it once at startup for now.
		LDA	$D06F
		AND	#$80
		STA	sys_ntsc_flag

		LDA	#$00
		JSR	colourSchemeSelect
		
		LDA	#<page_splsh
		STA	elemptr0
		LDA	#>page_splsh
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect

	
@loop:						
		CLI
						;This is where we do our timer
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
		JSR	userCursorPushBusy
		JSR	inetConnect
		JSR	userCursorPopBusy
		JMP	@lock

@inetinit:
		JSR	inetInitialise
		JSR	userCursorPopBusy


@lock:						;We need to lock here for reads...
		SEI
		LDA	ctrlsLock		;If already locked (eeii!) then skip
		BNE	@loop
		
		CLI
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


eth_init_value:
			.byte eth_init_default


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

;		LDA 	#$00
;		JSR 	drv_init

		LDA	eth_init_value
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
;	This is a whole lot of nothing to do - sleep
;	Can probably be stubbed out once things are settled
	.if	DEBUG_INETDOSLEEP
		LDX	$7F
@sleep0:
		LDY	#$FF
@sleep1:
		DEY
		BNE	@sleep1
		DEX
		BPL	@sleep0
	.endif

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

;	ip65_error is dead (never written anywhere), so it was always $00
;	here regardless of which of the 3 stages below actually failed -
;	every connect failure looked identical. Each stage now sets
;	ineterrc to its own code before jumping here instead.
		LDA	#$01
		STA	ineterrc
		JMP	@haveerror

@haveerror:
		LDA	#INET_ERR_INTRN
		STA	ineterrk

		JSR	clientOutputInetError
		RTS

; 	resolve host name
:
		LDA 	dns_hostname_is_dotted_quad
		BNE 	:+

		JSR 	dns_resolve
		BCC 	:+

		LDA	#$02
		STA	ineterrc
		JMP	@haveerror

:
		LDAX 	#7632
		STAX 	inet_port

; 	connect
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

		LDA	#$03
		LDX	TCP_CONNECT_FAIL_WAS_RST
		BEQ 	@tcpfail_chk_synack
		LDA	#$05		;peer actively refused (RST) rather than a plain timeout
		JMP	@tcpfail_have_code
@tcpfail_chk_synack:
		LDX	TCP_CONNECT_FAIL_BAD_SYNACK
		BEQ 	@tcpfail_have_code
		LDA	#$06		;a SYN+ACK arrived but got dropped (ACK mismatch)
@tcpfail_have_code:
		STA	ineterrc
		JMP	@haveerror

; 	connected
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
		LDA	#$00
		STA	userNameAccepted

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
;	tcp_close only sends the FIN; the retry/ack handshake behind it is
;	driven entirely by continued ETH_STATUS_POLL calls, which we stop
;	making the instant inetproc leaves INET_PROC_EXEC. Wait here (with
;	the busy cursor up) until the close actually completes or a
;	generous timeout elapses, instead of abandoning it mid-handshake.
		JSR	userCursorPushBusy

		JSR 	tcp_close

		LDA	#<DISCONNECT_TIMEOUT_FRAMES
		STA	TIMEOUT_LO
		LDA	#>DISCONNECT_TIMEOUT_FRAMES
		STA	TIMEOUT_HI
		JSR	RESET_TIMEOUT_FRAME

@wait:
		LDA	#$00
		STA	TERMINAL_EVENT

		JSR	TERMINAL_POLL_STATUS

		LDA	TERMINAL_EVENT
		BNE	@waitdone		;server acked the close (or reset)

		JSR	DEC_TIMEOUT_FRAME
		BCC	@wait			;still within budget, keep polling

@waitdone:
		JSR	userCursorPopBusy

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
		BNE	@done

		LDA	#>button_cnct_dcnt
		CMP	pickCtrl + 1
		BNE	@done

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1

@done:
		LDA	#<button_cnct_upd
		STA	elemptr0
		LDA	#>button_cnct_upd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

;	Clear the game data if we have a slot

		LDA	gameData + GAME::ourslt
		BMI	@exit
		
		JSR	initGameData
		JSR	clientInitGameOvrvw
		
		JSR	clientResetPlayGame

@exit:
		LDA	#$00
		STA	sendmsgscnt
		STA	readbufidx
		STA	readmsglen
		
		JSR	ctrlsLockRelease

		RTS


;-------------------------------------------------------------------------------
inetExecute:
;-------------------------------------------------------------------------------
;		LDA	inetstat
;		CMP	#INET_STATE_TICK
;		BEQ	@check_timeout
;
;		JSR 	timer_read
;		
;		TXA                           ; 1/1000 * 256 = ~ 1/4 seconds
;		ADC 	#$20                  ; 32 x 1/4 = ~ 8 seconds
;		
;		STA 	inet_timeout
;
;		LDA	#INET_STATE_TICK
;		STA	inetstat
;		
;@check_timeout:
;		LDA 	data_received
;		BNE 	:+
; 
;		JSR 	timer_read
;		CPX 	inet_timeout		
;		BNE 	:+			;	should sleep?
; 
;		JSR 	tcp_send_keep_alive
;		
;		LDA	#INET_STATE_NORM
;		STA	inetstat
;		RTS
;		
;: 
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
		.word	sendmsg3
		.word	sendmsg4
		.word	sendmsg5


;-------------------------------------------------------------------------------
inetGetNextSend:
;-------------------------------------------------------------------------------
		LDA	inetproc
		CMP	#INET_PROC_EXEC
		BNE	@fail
				
		LDY	sendmsgscnt

;	.if	DEBUG_MSGSPUSHSZ
		CPY	#$0C
		BNE	@cont
		
@fail:
;		LDA	#$02
;		STA	vicBrdrClr
;		LDA	#$05
;		STA	vicBkgdClr
;		
;		JMP	mainPanic

		CLC
		RTS

@cont:
;	.endif

		LDA	sendmsgtable, Y
		STA	tempptr0
		INY
		LDA	sendmsgtable, Y
		STA	tempptr0 + 1
		INY

		STY	sendmsgscnt

		LDA	#$01
		STA	tempdat0

		SEC
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
		JSR tcp_send
		BCS @error

		JSR	inetWaitTxIdle

		JSR	clientDispInetHealth

		LDY	senddat0
		CPY	sendmsgscnt
		BNE	@loop

		JMP	@exit


@error:
		LDA 	ip65_error
		CMP 	#IP65_ERROR_CONNECTION_CLOSED
		BNE 	@errother

		JSR	inetRecordDiscEvent

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


;-------------------------------------------------------------------------------
; The mega-ip TCP stack is stop-and-wait (one unacked segment in flight at a
; time); anything enqueued while a segment is outstanding just sits in the TX
; queue until a later poll notices the ACK. Block here until that queue has
; actually drained before letting the caller enqueue the next message, so
; back-to-back sends don't pile up unsent (or get silently coalesced together
; whenever the queue finally does flush).
;-------------------------------------------------------------------------------
;	Stashes TERMINAL_EVENT (TCP_EVENT_FLAG's sticky-OR'd EV_* bits, see
;	the mirrored defines near tcp_connect) into discEventFlags, so
;	clientOutputInetError can show *why* a connection ended instead of
;	just that it did. Call right before setting connection_closed - not
;	after, since some callers (tcp_send, tcp_send_keep_alive,
;	ETH_PROCESS_DEFERRED) reset TERMINAL_EVENT again on their own next
;	poll.
;-------------------------------------------------------------------------------
inetRecordDiscEvent:
;-------------------------------------------------------------------------------
		LDA	TERMINAL_EVENT
		STA	discEventFlags

		RTS


;-------------------------------------------------------------------------------
inetWaitTxIdle:
;-------------------------------------------------------------------------------
		LDA	#$00
		STA	TERMINAL_EVENT

		JSR	TERMINAL_POLL_STATUS

		LDA	TERMINAL_EVENT
		BNE	@closed

		JSR	MIP_TCP_TX_IDLE
		CMP	#$01
		BNE	inetWaitTxIdle

		RTS

@closed:
		JSR	inetRecordDiscEvent

		LDA	#$01
		STA	connection_close_requested
		STA	connection_closed

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

;	Not a TCP_EVENT_FLAG signal - this is MIP_ML_RECV_BYTE's own
;	inbound-EOF sentinel, so there's nothing meaningful to show beyond
;	"unknown" ($00 - see discEventFlags).
		LDX	#$00
		STX	discEventFlags

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

		LDA	readmsgbuflen
		BNE	@readmsg
		LDA	readmsgbuflen + 1
		BEQ	@exit

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

;	Advance by readbufidx (bytes of THIS batch actually consumed),
;	not readmsglen (the message's full size) - they're only the same
;	when a message is entirely contained in one batch. For a message
;	that started in a PREVIOUS batch and only finishes here, inetread
;	was reset to this batch's own base (not the message's true start),
;	so advancing by the full message size overshoots by however many
;	bytes came from the earlier batch, landing partway into the next
;	message and desyncing everything after it in this batch.
		CLC
		LDA	inetread
		ADC	readbufidx
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
		BNE	@cont
		
		JMP	@newmsg
		
@cont:
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
	

	.export	clientNotifyFail
;-------------------------------------------------------------------------------
clientNotifyFail:
;-------------------------------------------------------------------------------
		SEI
		LDA	#$06
		STA	uiflshcnt
		
		LDA	#$08
		STA	uiflshdly
		
		LDA	current_clrs
		STA	vicBrdrClr

		CLI

		RTS


	.export	roomLogNotifyUpdate
;-------------------------------------------------------------------------------
;	Drop-in replacement for ctrlsLogPanelUpdate - identical for any
;	other panel, but if tempptr2 is the room/chat log and the Room
;	page isn't the active one (pageptr0), counts the update and
;	flashes the border every 5th one so an idle player notices new
;	chat. Counter resets whenever an update lands while the page IS
;	active, so counting restarts fresh after the player's caught up.
roomLogNotifyUpdate:
;-------------------------------------------------------------------------------
		JSR	ctrlsLogPanelUpdate

		LDA	tempptr2
		CMP	#<lpanel_room_log
		BNE	@exit
		LDA	tempptr2 + 1
		CMP	#>lpanel_room_log
		BNE	@exit

		LDA	checkbx_config_flashchat + ELEMENT::tag
		BEQ	@exit

		LDA	pageptr0
		CMP	#<page_room
		BNE	@away
		LDA	pageptr0 + 1
		CMP	#>page_room
		BNE	@away

		LDA	#$00
		STA	room_log_notify_cnt

@exit:
		RTS

@away:
		INC	room_log_notify_cnt
		LDA	room_log_notify_cnt
		CMP	#$05
		BCC	@exit

		LDA	#$00
		STA	room_log_notify_cnt

		SEI
		LDA	#$06
		STA	uiflshcnt
		LDA	#$08
		STA	uiflshdly
		LDA	current_clrs
		STA	vicBrdrClr
		CLI

		RTS

;-------------------------------------------------------------------------------
clientDispInetHealth:
;-------------------------------------------------------------------------------
		LDA	inetproc
		CMP	#INET_PROC_EXEC
		LBNE	@exit

;	Temporary diagnostic: log inet_last_rtt/inet_last_retries to the
;	connect log panel whenever either one actually changes, so we can
;	see the raw numbers behind the bar instead of guessing.
;	Disabled for now - remove this BRA to bring it back.
		BRA	@dbgdone

		LDA	inet_last_rtt
		CMP	dbg_last_rtt_logged
		BNE	@dbglog
		LDA	inet_last_retries
		CMP	dbg_last_retries_logged
		BEQ	@dbgdone

@dbglog:
		LDA	inet_last_rtt
		STA	dbg_last_rtt_logged
		LDA	inet_last_retries
		STA	dbg_last_retries_logged

		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_debug_rtt
		JSR	strsAppendString

		LDA	inet_last_rtt
		LDX	#$00
		JSR	strsAppendHex

		LDAX	#text_debug_retry
		JSR	strsAppendString

		LDA	inet_last_retries
		LDX	#$00
		JSR	strsAppendHex

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

@dbgdone:
;	healthbars/healthclrs run best(0) to worst(8); inet_last_rtt is in
;	~20ms frame-ticks. With the keepalive-reply/Nagle fixes, steady-state
;	is now ~18 ticks (~360ms), so >>3 spreads a ~0-1.3s range across the
;	bar (18 ticks lands around index 2, still green) instead of pinning
;	every normal reading at worst.
		LDA	inet_last_rtt
		LSR
		LSR
		;LSR
		CMP	#$12
		BCC	:+
		LDA	#$12
:
    PHA
		ASL
    TAX

		LDA	screenRowsLo
		STA	inetcalc
		LDA	screenRowsHi
		STA	inetcalc + 1
		
		LDY	#$27
		LDA	healthbars, X
		STA	(inetcalc), Y
    INX
		LDY	#$4F
		LDA	healthbars, X
		STA	(inetcalc), Y

		LDA	colourRowsHi
		STA	inetcalc + 1
		
    PLX
		LDY	#$27
		LDA	healthclrs, X
		STA	(inetcalc), Y
		LDY	#$4F
		LDA	healthclrs, X
		STA	(inetcalc), Y
		
@exit:
		RTS


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
		
		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar
		
		LDA	readmsg0 + 1
		LDX	#$00
		JSR	strsAppendHex

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		RTS


;-------------------------------------------------------------------------------
clientSendIdent:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		BCC	@failed

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
		
@failed:
		JSR	clientNotifyFail

		LDA	#INET_PROC_DISC
		STA	inetproc
		
		RTS


;-------------------------------------------------------------------------------
clientSendUser:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		BCC	@failed

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
		
@failed:
		JSR	clientNotifyFail
		
		RTS



;-------------------------------------------------------------------------------
clientSendGetSysInfo:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed

		LDA	#MSG_CATG_TEXT
		ORA	#$00

		JSR	strsAppendChar

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS
		
@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendKeepAlive:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		BCC	@failed

		LDA	#MSG_CATG_CLNT
		ORA	#$02

		JSR	strsAppendChar

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
;		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendRoomJoin:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_LOBY
		ORA	#$01
		
		JSR	strsAppendChar
		
		LDAX	#edit_room_room_buf
		JSR	strsAppendString
		
		LDA	edit_room_pwd_buf
		BEQ	@complete
		
		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar
		
		LDAX	#edit_room_pwd_buf
		JSR	strsAppendString
		
@complete:
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS

;-------------------------------------------------------------------------------
clientSendRoomPart:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_LOBY
		ORA	#$02
		
		JSR	strsAppendChar
		
		LDAX	#edit_room_room_buf
		JSR	strsAppendString
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendRoomPeer:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_LOBY
		ORA	#$04
		
		JSR	strsAppendChar
		
		LDAX	#edit_room_room_buf
		JSR	strsAppendString
		
		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar

		LDAX	#edit_cnct_user_buf
		JSR	strsAppendString

		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar
		
		LDAX	#edit_room_text_buf
		JSR	strsAppendString

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendPlayJoin:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$01
		
		JSR	strsAppendChar
		
		LDAX	#edit_play_game_buf
		JSR	strsAppendString
		
		LDA	edit_play_pwd_buf
		BEQ	@complete
		
		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar
		
		LDAX	#edit_play_pwd_buf
		JSR	strsAppendString
		
@complete:
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientResetPlayGame:
;-------------------------------------------------------------------------------
		JSR	ctrlsLockAcquire

		LDA	#<button_play_part
		STA	elemptr0
		LDA	#>button_play_part
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<button_play_join
		STA	elemptr0
		LDA	#>button_play_join
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		LDA	#<button_play_part
		CMP	actvCtrl
		BNE	@tstpick

		LDA	#>button_play_part
		CMP	actvCtrl + 1
		BNE	@tstpick

		JSR	ctrlsActivateCtrl

@tstpick:
		LDA	#<button_play_part
		CMP	pickCtrl
		BNE	@exit

		LDA	#>button_play_part
		CMP	pickCtrl + 1
		BNE	@exit

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1

@exit:
		LDA	#<edit_play_game
		STA	elemptr0
		LDA	#>edit_play_game
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		LDA	#<edit_play_pwd
		STA	elemptr0
		LDA	#>edit_play_pwd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		JSR	ctrlsLockRelease
		
		RTS


;-------------------------------------------------------------------------------
clientSendPlayPart:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$02
		
		JSR	strsAppendChar
		
		LDAX	#edit_play_game_buf
		JSR	strsAppendString
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		JMP	clientResetPlayGame
;		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
clientRoomListChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		JSR	clientSendRoomListNames

@exit:
		RTS


;-------------------------------------------------------------------------------
clientPlayListChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		JSR	clientSendPlayListGames

@exit:
		RTS


;-------------------------------------------------------------------------------
clientSendRoomListNames:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		BCC	@failed

		LDA	#MSG_CATG_LOBY
		ORA	#$03

		JSR	strsAppendChar

;	Only ask for a specific room's player list if we're actually in one
;	(Part button visible) - otherwise send no room name, which asks the
;	server for the list of all public rooms instead.
		LDA	button_room_part + ELEMENT::state
		AND	#STATE_VISIBLE
		BEQ	@send

		LDAX	#edit_room_room_buf
		JSR	strsAppendString

@send:
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		LDA	#INET_PROC_DISC
		STA	inetproc

		JSR	clientNotifyFail

		RTS


;	Unlike the room list, the play list is only ever "list all games" -
;	players in a game are already visible on the overview page, so this
;	never asks for a specific game's player list. clientSendPlayListNames
;	below is separate and still does that, for the join-confirmation flow.
clientSendPlayListGames:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		BCC	@failed

		LDA	#MSG_CATG_PLAY
		ORA	#$03

		JSR	strsAppendChar

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		LDA	#INET_PROC_DISC
		STA	inetproc

		JSR	clientNotifyFail

		RTS


clientSendPlayListNames:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		BCC	@failed

		LDA	#MSG_CATG_PLAY
		ORA	#$03

		JSR	strsAppendChar

		LDAX	#edit_play_game_buf
		JSR	strsAppendString

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y
		
		RTS

@failed:
		LDA	#INET_PROC_DISC
		STA	inetproc

		JSR	clientNotifyFail
		
		RTS
		

;-------------------------------------------------------------------------------
clientSendPlayStatPeerReady:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$07
		
		JSR	strsAppendChar
		
		LDA	gameData + GAME::ourslt
		JSR	strsAppendChar
		
		LDA	#SLOT_ST_READY
		JSR	strsAppendChar
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendPlayStatPeerNtRdy:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$07
		
		JSR	strsAppendChar
		
		LDA	gameData + GAME::ourslt
		JSR	strsAppendChar
		
		LDA	#SLOT_ST_IDLE
		JSR	strsAppendChar
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendPlayRollPeerFirst:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$08
		
		JSR	strsAppendChar
		
		LDA	gameData + GAME::ourslt
		JSR	strsAppendChar
		
		LDA	#DIE_ALL
		JSR	strsAppendChar
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendPlayRoll:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$08
		
		JSR	strsAppendChar
		
		LDA	gameData + GAME::ourslt
		JSR	strsAppendChar
		
		LDX	gameData + GAME::ourslt
		LDA	game_slot_lo, X
		STA	tempptr2
		LDA	#>gameData
		STA	tempptr2 + 1
		
		LDY	#GAMESLOT::keepers
		LDA	#DIE_ALL
		EOR	(tempptr2), Y
		
		JSR	strsAppendChar
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendPlayKeepersPeer:
;	IN	tempvar_a	Die to update
;	IN	tempvar_b	Flag
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$09
		
		JSR	strsAppendChar
		
		LDA	gameData + GAME::ourslt
		JSR	strsAppendChar
		
		LDY	tempvar_a
		INY
		TYA
		JSR	strsAppendChar
		
		LDA	tempvar_b
		JSR	strsAppendChar
		
		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@failed:
		JSR	clientNotifyFail
		
		RTS


;-------------------------------------------------------------------------------
clientSendPlayScoreQuery:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend
		
		BCC	@failed
		
		LDA	#MSG_CATG_PLAY
		ORA	#$0A
		
		JMP	clientSendPlayScoreDirect

@failed:
		JSR	clientNotifyFail
		
		RTS


	.export	clientSendPlayScorePeer
;-------------------------------------------------------------------------------
clientSendPlayScorePeer:
;-------------------------------------------------------------------------------
		JSR	inetGetNextSend

		BCS	@cont

@failed:
		JSR	clientNotifyFail
		RTS

@cont:
		LDA	#MSG_CATG_PLAY
		ORA	#$0B
		
clientSendPlayScoreDirect:
		JSR	strsAppendChar
		
		LDA	gameData + GAME::ourslt
		JSR	strsAppendChar
		
		LDA	#<spanel_detail_sheet
		STA	elemptr0
		LDA	#>spanel_detail_sheet
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		
;	We need to skip over the upper bonus score which can't be selected

		CMP	#$06
		BCC	@append
		
		TAY
		INY
		TYA
		
@append:
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

;	A real list is starting (matching pop is in clientProcTextMsgMore,
;	once the "0 remaining" completion notice comes in for it). Reload
;	tempvar_z after the call since it clobbers A.
		JSR	userCursorPushBusy
		LDA	tempvar_z

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
		LDA	#<lpanel_play_log
		STA	tempptr2
		LDA	#>lpanel_play_log
		STA	tempptr2 + 1

		JMP	@output

@lobby:
		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1

		JMP	@output

@output:
		JSR	ctrlsLogPanelGetNextLine

		LDA	#$00
		JSR	strsAppendChar

		JSR	roomLogNotifyUpdate

@exit:
		RTS


;-------------------------------------------------------------------------------
clientProcTextMsgMore:
;-------------------------------------------------------------------------------
		LDY	readparm1
		LDA	readmsg0, Y
		CMP	#KEY_ASC_0
		BNE	@more

		JSR	clientProcTextMsgFind
		TAY
		JSR	clientProcTextMsgClear

		JSR	userCursorPopBusy

		RTS

@more:
;	List isn't finished - echo the list name back as our own method 2
;	so the server's ProcessPlayerMessage sets ml.Process:=True and
;	sends the next batch (TMessageList.ProcessList caps each batch at
;	15 entries; without this request, anything past the first batch
;	was silently dropped).
		JSR	inetGetNextSend

		BCC	@sendfail

		LDA	#MSG_CATG_TEXT
		ORA	#$02

		JSR	strsAppendChar

		LDA	readparm0
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam

		DEC	tempdat0
		LDA	tempdat0
		LDY	#$00
		STA	(tempptr0), Y

		RTS

@sendfail:
		JSR	clientNotifyFail

		RTS


;-------------------------------------------------------------------------------
clientProcTextMsgPlaySlts:
;-------------------------------------------------------------------------------
		LDY	readparm2
		LDA	readmsg0, Y
		SEC
		SBC	#KEY_ASC_0
		TAY
		PHA
		
		LDA	game_slot_lo, Y
		STA	tempptr2
		LDA	#>gameData
		STA	tempptr2 + 1
		
		LDY	#GAMESLOT::name
		LDX	readparm1

@loop:
		LDA	readmsg0, X
		STA	(tempptr2), Y
		
		INX
		INY
		
		CMP	#KEY_ASC_SPACE
		BNE	@loop
		
		LDA	#$00
		STA	(tempptr2), Y
		
		PLA
		ASL
		TAX
		
		JSR	ctrlsLockAcquire

		LDA	label_ovrvw_names, X
		STA	elemptr0
		INX
		LDA	label_ovrvw_names, X
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		JSR	ctrlsLockRelease
		
		RTS
		

	.export	clientProcTextMsgData
;-------------------------------------------------------------------------------
clientProcTextMsgData:
;-------------------------------------------------------------------------------
		JSR	clientProcTextMsgCopyID
		JSR	clientProcTextMsgFind
		
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
		JSR	inetScanReadParams
		
		LDA	readparmcnt
		CMP	#$02
		BEQ	@playlst
		
		JMP	clientProcTextMsgPlaySlts

@playlst:
		LDA	#<lpanel_play_log
		STA	tempptr2
		LDA	#>lpanel_play_log
		STA	tempptr2 + 1

		JMP	@output

@lobby:
		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1

		JMP	@output

@output:
		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_list_pref
		JSR	strsAppendString

		LDA	readparm1
		STA	tempdat1

		JSR	strsAppendMessage

		LDA	#$00
		JSR	strsAppendChar

		JSR	roomLogNotifyUpdate

@exit:
		RTS


;-------------------------------------------------------------------------------
clientProcTextMsg:
;-------------------------------------------------------------------------------
		LDA	imsgdat2
		CMP	#$04
		BEQ	@whisper

		JSR	inetScanReadParams
		
		LDA	readparmcnt
		CMP	#$02
		BCC	@unknown
		
		LDA	imsgdat2
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
;	Private "whisper" text from another player - wire format is
;	"user text" (mcText method 4, no room field), unlike the room-wide
;	peer chat's "room user text" (mcLobby method 4, clientProcRoomPeerMsg).
;	Dispatched here before inetScanReadParams runs, so scan params
;	ourselves. Always shows the sender header (no continuation-folding
;	against room_lastuser) and clears room_lastuser afterward so the
;	next ordinary room message reprints its own header too.
		JSR	inetScanReadParams
		LDA	readparmcnt
		CMP	#$02
		BCS	@dowhisper

		RTS

@dowhisper:
		JSR	ctrlsLockAcquire

		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1

		LDA	room_haveblank
		BNE	@wskip0

		JSR	ctrlsLogPanelGetNextLine

		LDA	#$00
		JSR	strsAppendChar

@wskip0:
		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_msg_pref
		JSR	strsAppendString

		LDA	readparm0
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam

		LDAX	#text_room_uwhisp
		JSR	strsAppendString

		LDA	#$00
		JSR	strsAppendChar

		LDY	readmsg0
		INY

		LDA	#$00
		STA	readmsg0, Y

		JSR	ctrlsLogPanelGetNextLine

		CLC
		LDA	#<readmsg0
		ADC	readparm1
		STA	tempptr3
		LDA	#>readmsg0
		ADC	#$00
		STA	tempptr3 + 1

		LDAX	tempptr3
		JSR	strsAppendWrapped

		LDA	#$00
		JSR	strsAppendChar

		LDA	#$00
		STA	room_haveblank
		STA	room_lastuser

		JSR	roomLogNotifyUpdate

		JSR	ctrlsLockRelease

		RTS


;-------------------------------------------------------------------------------
clientProcRoomJoinMsg:
;-------------------------------------------------------------------------------
		JSR	inetScanReadParams
		
		LDA	readparmcnt
		CMP	#$02
		BEQ	@join
		
		JMP	@unknown

@join:
		LDY	readmsg0
		INY
		LDA	#KEY_ASC_SPACE
		STA	readmsg0, Y

;	Update edit_room_room_buf with the room actually joined - may
;	differ slightly from what was typed/requested (server-side
;	normalisation, or joining by clicking a room in the list rather
;	than typing one in).
		LDY	readparm0
		LDX	#$00

@roombufloop:
		LDA	readmsg0, Y
		CMP	#KEY_ASC_SPACE
		BEQ	@roombufdone

		CPX	#$08
		BCS	@roombufdone

		STA	edit_room_room_buf, X
		INX
		INY
		JMP	@roombufloop

@roombufdone:
		LDA	#$00
		STA	edit_room_room_buf, X

		LDA	#<edit_room_room
		STA	elemptr0
		LDA	#>edit_room_room
		STA	elemptr0 + 1

		LDY	#EDITCTRL::textsiz
		TXA
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate

		JSR	ctrlsLockAcquire
		
		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1 
		
		LDA	room_haveblank
		BNE	@skip0
		
		JSR	ctrlsLogPanelGetNextLine
		
		LDA	#$00
		JSR	strsAppendChar
		
@skip0:		
		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_indent_pref
		JSR	strsAppendString

		LDA	readparm1
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam
		
		LDAX	#text_room_ujoins
		JSR	strsAppendString

		LDA	readparm0
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam

		LDA	#$00
		JSR	strsAppendChar
		
		JSR	ctrlsLogPanelGetNextLine
		
		LDA	#$00
		JSR	strsAppendChar

		LDA	#$01
		STA	room_haveblank

		LDA	#$00
		STA	room_lastuser

		JSR	roomLogNotifyUpdate

;	Change Game Join button to Part
		LDA	#<button_room_join
		STA	elemptr0
		LDA	#>button_room_join
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<button_room_part
		STA	elemptr0
		LDA	#>button_room_part
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		LDA	#<button_room_join
		CMP	actvCtrl
		BNE	@tstpick

		LDA	#>button_room_join
		CMP	actvCtrl + 1
		BNE	@tstpick

		JSR	ctrlsActivateCtrl

@tstpick:
		LDA	#<button_room_join
		CMP	pickCtrl
		BNE	@cont

		LDA	#>button_room_join
		CMP	pickCtrl + 1
		BNE	@cont

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1


;	Disable Game Name and Password edits
@cont:
		LDA	#<edit_room_room
		STA	elemptr0
		LDA	#>edit_room_room
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<edit_room_pwd
		STA	elemptr0
		LDA	#>edit_room_pwd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		JSR	ctrlsLockRelease

		RTS
		
@unknown:
		JMP	clientProcUnknownMsg
;		RTS



;-------------------------------------------------------------------------------
clientProcRoomPartMsg:
;-------------------------------------------------------------------------------
		JSR	inetScanReadParams
		
		LDA	readparmcnt
		CMP	#$02
		BEQ	@part
		
		JMP	@unknown

@part:
		LDY	readmsg0
		INY
		LDA	#KEY_ASC_SPACE
		STA	readmsg0, Y
		
		JSR	ctrlsLockAcquire
		
		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1 
		
		LDA	room_haveblank
		BNE	@skip0
		
		JSR	ctrlsLogPanelGetNextLine
		
		LDA	#$00
		JSR	strsAppendChar
		
@skip0:		
		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_outdent_pref
		JSR	strsAppendString
		
		LDA	readparm1
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam
		
		LDAX	#text_room_uparts
		JSR	strsAppendString

		LDA	readparm0
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam

		LDA	#$00
		JSR	strsAppendChar
		
		JSR	ctrlsLogPanelGetNextLine
		
		LDA	#$00
		JSR	strsAppendChar

		LDA	#$01
		STA	room_haveblank
		LDA	#$00
		STA	room_lastuser

		JSR	roomLogNotifyUpdate

;	Check that the user was us before updating the ui
		LDX	readparm1
		LDY	#$00
		
@loop0:
		LDA	readmsg0, X
		CMP	#KEY_ASC_SPACE
		BEQ	@found0
		
		CMP	edit_cnct_user_buf, Y
		BEQ	@next0
		
		JMP	@done

@next0:
		INX
		INY
		JMP	@loop0
		
@found0:
;	Change Game Part button to Join
		LDA	#<button_room_part
		STA	elemptr0
		LDA	#>button_room_part
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<button_room_join
		STA	elemptr0
		LDA	#>button_room_join
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

;	Check the room more panel is visible before changing the active control

		LDA	#<panel_room_more
		STA	tempptr0
		LDA	#>panel_room_more
		STA	tempptr0 + 1
		
		LDY	#ELEMENT::state
		LDA	(tempptr0), Y
		AND	#STATE_VISIBLE
		BEQ	@cont
		
;	Update the active control

		LDA	#<button_room_part
		CMP	actvCtrl
		BNE	@tstpick

		LDA	#>button_room_part
		CMP	actvCtrl + 1
		BNE	@tstpick

		JSR	ctrlsActivateCtrl

@tstpick:
		LDA	#<button_room_part
		CMP	pickCtrl
		BNE	@cont

		LDA	#>button_room_part
		CMP	pickCtrl + 1
		BNE	@cont

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1


;	Enable Game Name and Password edits
@cont:
		LDA	#<edit_room_room
		STA	elemptr0
		LDA	#>edit_room_room
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		LDA	#<edit_room_pwd
		STA	elemptr0
		LDA	#>edit_room_pwd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

@done:
		JSR	ctrlsLockRelease

		RTS
		
@unknown:
		JMP	clientProcUnknownMsg
;		RTS


	.export	clientProcRoomPeerMsg
;-------------------------------------------------------------------------------
clientProcRoomPeerMsg:
;-------------------------------------------------------------------------------
		JSR	inetScanReadParams
		LDA	readparmcnt
		CMP	#$02
		BCS	@peer
		
		JMP	@unknown

@peer:
		JSR	ctrlsLockAcquire
		
		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1 

;	Compare user in message with the last one

		LDA	#$00
;		STA	tempvar_a		;Found?
		STA	tempvar_b		;lastuser idx
		
		LDAX	#readmsg0
		STAX	tempptr0
		
		LDAX	#room_lastuser
		STAX	tempptr1
		
		LDA	readparm1
		STA	tempvar_c		;message idx
		
@loop0:
		LDY	tempvar_c
		LDA	(tempptr0), Y
		CMP	#KEY_ASC_SPACE
		BEQ	@found0
		
		LDY	tempvar_b
		CMP	(tempptr1), Y
		BEQ	@next0
		
		LDA	#$00
		JMP	@done0
	
@next0:
		INC	tempvar_c
		INC	tempvar_b
		
		JMP	@loop0
		
@found0:
		LDA	#$01
;		STA	tempvar_a
		
@done0:
		BNE	@havelast

		LDA	room_haveblank
		BNE	@skip0
		
		JSR	ctrlsLogPanelGetNextLine
		
		LDA	#$00
		JSR	strsAppendChar
		
@skip0:		
		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_msg_pref
		JSR	strsAppendString

		LDA	readparm1
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam

		LDAX	#text_room_usays
		JSR	strsAppendString

		LDA	#$00
		JSR	strsAppendChar
		
@havelast:
		LDY	readmsg0
		INY

		LDA	#$00
		STA	readmsg0, Y

		JSR	ctrlsLogPanelGetNextLine

		CLC
		LDA	#<readmsg0
		ADC	readparm2
		STA	tempptr3
		LDA	#>readmsg0
		ADC	#$00
		STA	tempptr3 + 1

		LDAX	tempptr3
		JSR	strsAppendWrapped
		
		LDA	#$00
		JSR	strsAppendChar
		
		LDA	#$00
		STA	room_haveblank

		LDY	readparm1
		LDX	#$00
		
@loop1:
		LDA	readmsg0, Y
		CMP	#KEY_ASC_SPACE
		BEQ	@done1
		
		STA	room_lastuser, X
		
		INY
		INX
		
		JMP	@loop1
		
@done1:
		LDA	#$00
		STA	room_lastuser, X

		JSR	roomLogNotifyUpdate

		JSR	ctrlsLockRelease

		RTS
		
@unknown:
		JMP	clientProcUnknownMsg
;		RTS


;-------------------------------------------------------------------------------
clientProcLobbyMsg:
;-------------------------------------------------------------------------------
		LDA	imsgdat2
		BNE	@tstfirst
		
;	Error message
		LDA	#<lpanel_room_log
		STA	tempptr2
		LDA	#>lpanel_room_log
		STA	tempptr2 + 1 

		LDA	room_haveblank
		BNE	@skip0

		JSR	ctrlsLogPanelGetNextLine
		
		LDA	#$00
		JSR	strsAppendChar

@skip0:
		JSR	ctrlsLogPanelGetNextLine

		LDAX 	#text_err_pref
		JSR	strsAppendString

		LDA	#$02
		STA	tempdat1

		JSR	strsAppendMessage

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelGetNextLine
		
		LDA	#$00
		JSR	strsAppendChar
		
		LDA	#$01
		STA	room_haveblank

		JSR	roomLogNotifyUpdate

		RTS

@tstfirst:
		CMP	#$01
		BNE	@tstnxt0
		
		JMP	clientProcRoomJoinMsg
;		RTS
		
@tstnxt0:
		CMP	#$02
		BNE	@tstnxt1
		
		JMP	clientProcRoomPartMsg
;		RTS


@tstnxt1:
		CMP	#$04
		BNE	@tstnxt2
		
		JMP	clientProcRoomPeerMsg
;		RTS

@tstnxt2:
		JMP	clientProcUnknownMsg
;		RTS


;-------------------------------------------------------------------------------
clientProcConctMsg:
;-------------------------------------------------------------------------------
		LDA	imsgdat2
		BNE	@tstnxt0

		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine

		LDAX 	#text_err_pref
		JSR	strsAppendString

		LDA	#$02
		STA	tempdat1

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
;	Server echoes mcConnect/1 back once it accepts our clientSendUser -
;	it only accepts one per connection, so disable the Update button
;	(button_cnct_upd) rather than let further clicks just collect
;	"Invalid connect ident" errors.
		LDA	#$01
		STA	userNameAccepted

		JSR	ctrlsLockAcquire

		LDA	#<button_cnct_upd
		STA	elemptr0
		LDA	#>button_cnct_upd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		JSR	ctrlsLockRelease

		RTS


;-------------------------------------------------------------------------------
clientProcClientMsg:
;-------------------------------------------------------------------------------
		RTS


	.export	clientProcServerMsg
;-------------------------------------------------------------------------------
clientProcServerMsg:
;-------------------------------------------------------------------------------
		LDA	imsgdat2
		BNE	@tstnxt0

		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1 

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_syserr_pref
		JSR	strsAppendString

		LDA	#$02
		STA	tempdat1
		
		JSR	strsAppendMessage

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		RTS

@tstnxt0:
		CMP	#$01
		BEQ	@ident

@tstnxt1:
		CMP	#$02
		BEQ	@chlng

		JMP	clientProcUnknownMsg
;		RTS

@ident:
;	Copy up to 42 characters of the message string into edit_cnct_info_buf
;	and mark the control dirty so it gets redrawn.

		LDA	readmsglen
		SEC
		SBC	#$02

		CMP	#43
		BCC	:+
		LDA	#42
:
		STA	tempdat0

		LDY	#$00
@infoloop:
		CPY	tempdat0
		BEQ	@infodone

		LDA	readmsg0 + 2, Y
		STA	edit_cnct_info_buf, Y

		INY
		BNE	@infoloop

@infodone:
		LDA	#$00
		STA	edit_cnct_info_buf, Y

		LDA	#<edit_cnct_info
		STA	elemptr0
		LDA	#>edit_cnct_info
		STA	elemptr0 + 1

		LDY	#EDITCTRL::textsiz
		LDA	tempdat0
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate

		JSR	clientSendIdent
		JSR	clientSendUser
		JSR	clientSendGetSysInfo

		RTS

@chlng:
		JMP	clientSendKeepAlive
;		RTS


	.export	clientProcPlayJoinMsg
;-------------------------------------------------------------------------------
clientProcPlayJoinMsg:
;-------------------------------------------------------------------------------
		JSR	inetScanReadParams
		
		LDA	readparmcnt
		CMP	#$03
		BEQ	@join
		
		JMP	@unknown

@join:
;	Get the slot number the message refers to
		LDY	readparm2
		LDA	readmsg0, Y
		SEC
		SBC	#KEY_ASC_0	
		PHA

;	Start updating user interface
		JSR	ctrlsLockAcquire
		
;	Check if we have our slot number already (have done this before)
		LDA	gameData + GAME::ourslt
		BMI	@wejoined
		
		JMP	@complete
			
@wejoined:
;	Confirm this Join is actually reporting our own join, not another
;	player's arriving before our own confirmation does - a real race,
;	not just theoretical, since ourslt only stops looking negative
;	once we get here. Compares the player name given (readparm1)
;	against our own name (edit_cnct_user_buf) all the way to both
;	terminators, same style as clientProcPlayPartMsg's game-name
;	guard, so a name that's just a prefix of the other doesn't
;	false-match. Not us - treat it like any other player's join
;	(@complete already handles that generically).
		LDX	#$00
		LDY	readparm1

@wenamecmp:
		LDA	readmsg0, Y
		CMP	#KEY_ASC_SPACE
		BEQ	@wenameend

		CMP	edit_cnct_user_buf, X
		LBNE	@complete

		INX
		INY
		JMP	@wenamecmp

@wenameend:
		LDA	edit_cnct_user_buf, X
		LBNE	@complete

;	Update edit_play_game_buf with the game actually joined - may
;	differ slightly from what was typed/requested, same reasoning as
;	clientProcRoomJoinMsg's edit_room_room_buf update.
		LDY	readparm0
		LDX	#$00

@gamebufloop:
		LDA	readmsg0, Y
		CMP	#KEY_ASC_SPACE
		BEQ	@gamebufdone

		CPX	#$08
		BCS	@gamebufdone

		STA	edit_play_game_buf, X
		INX
		INY
		JMP	@gamebufloop

@gamebufdone:
		LDA	#$00
		STA	edit_play_game_buf, X

		LDA	#<edit_play_game
		STA	elemptr0
		LDA	#>edit_play_game
		STA	elemptr0 + 1

		LDY	#EDITCTRL::textsiz
		TXA
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate

;	Init game state to waiting - only need overview string
		LDA	#<label_ovrwv_round_det
		STA	elemptr0
		LDA	#>label_ovrwv_round_det
		STA	elemptr0 + 1
		
		LDY	#CONTROL::textptr
		LDA	#<text_ovrvw_wait
		STA	(elemptr0), Y
		INY
		LDA	#>text_ovrvw_wait
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate		
		
;	Remember our slot
		PLA
		STA	gameData + GAME::ourslt
		PHA

;	Enable Ready button 
		LDA	#<button_ovrvw_cntrl
		STA	elemptr0
		LDA	#>button_ovrvw_cntrl
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

;	Set detail slot to none - no need is initialised this way
;		LDA	#$FF
;		STA	gameData + GAME::detslt

;	Change Game Join button to Part 
		LDA	#<button_play_join
		STA	elemptr0
		LDA	#>button_play_join
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsExcludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<button_play_part
		STA	elemptr0
		LDA	#>button_play_part
		STA	elemptr0 + 1

		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		LDA	#<button_play_join
		CMP	actvCtrl
		BNE	@tstpick

		LDA	#>button_play_join
		CMP	actvCtrl + 1
		BNE	@tstpick

		JSR	ctrlsActivateCtrl

@tstpick:
		LDA	#<button_play_join
		CMP	pickCtrl
		BNE	@cont

		LDA	#>button_play_join
		CMP	pickCtrl + 1
		BNE	@cont

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1


;	Disable Game Name and Password edits
@cont:
		LDA	#<edit_play_game
		STA	elemptr0
		LDA	#>edit_play_game
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<edit_play_pwd
		STA	elemptr0
		LDA	#>edit_play_pwd
		STA	elemptr0 + 1

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
				
;	Respond with Play 3 to get other player names
		JSR 	clientSendPlayListNames
		
@complete:
;	Set slot name to <player name>
		PLA
		TAX
		PHA
		
		LDA	game_slot_lo, X
		STA	tempptr0
		LDA	#>gameData
		STA	tempptr0 + 1
		
		LDY	#GAMESLOT::name
		LDX	readparm1
		
@loop:
		LDA	readmsg0, X
		STA	(tempptr0), Y
		INY
		INX

		CMP	#KEY_ASC_SPACE
		BNE	@loop

		LDA	#$00
		STA	(tempptr0), Y
		
		PLA
		ASL
		TAX
		LDA	label_ovrvw_names, X
		STA	elemptr0
		INX
		LDA	label_ovrvw_names, X
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		LDA	#<lpanel_play_log
		STA	tempptr2
		LDA	#>lpanel_play_log
		STA	tempptr2 + 1

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_indent_pref
		JSR	strsAppendString

		LDA	readparm1
		STA	tempdat3

		LDAX	#readmsg0
		JSR	strsAppendParam

		LDAX	#text_play_ujoins
		JSR	strsAppendString

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		JSR	ctrlsLockRelease

		RTS

@unknown:
		JMP	clientProcUnknownMsg
;		RTS


	.export	clientProcPlayPartMsg
;-------------------------------------------------------------------------------
clientProcPlayPartMsg:
;-------------------------------------------------------------------------------
		JSR	inetScanReadParams
		
		LDA	readparmcnt
		CMP	#$03
		BEQ	@part
		
		JMP	@unknown
		
@part:
;	Ignore Part broadcasts for a game that isn't the one we're in -
;	edit_play_game_buf holds the name we joined/created with (it's
;	what clientSendPlayJoin sends), and readparm0 is the game name
;	this Part is for. Guards against a stale in-flight message from a
;	game we've already left landing after gameData has been reused
;	for a new one, which could otherwise false-match on slot number
;	alone.
		LDX	#$00
		LDY	readparm0

@gmcmp:
		LDA	readmsg0, Y
		CMP	#KEY_ASC_SPACE
		BEQ	@gmmsgend

		CMP	edit_play_game_buf, X
		BNE	@gmmismatch

		INX
		INY
		JMP	@gmcmp

@gmmsgend:
		LDA	edit_play_game_buf, X
		BNE	@gmmismatch

;	Get the slot number the message refers to
		LDY	readparm2
		LDA	readmsg0, Y
		SEC
		SBC	#KEY_ASC_0
		PHA

;	Start updating user interface
		JSR	ctrlsLockAcquire

;	Check if we have our slot number still
		PLA
		PHA
		CMP	gameData + GAME::ourslt
		BEQ	@weparted
		
		JMP	@complete
		
@weparted:
;	We were ejected from the game somehow?

		JSR	initGameData
		JSR	clientInitGameOvrvw

		JSR	clientResetPlayGame

;	No longer in any game - if we're sat on the overview or detail
;	page, kick back to the game list page.
		LDA	currpgtag
		CMP	#PAGE_PLYOVRVW
		BEQ	@weppage
		CMP	#PAGE_PLYDETAIL
		BNE	@wepdone

@weppage:
		LDA	#<page_play
		STA	elemptr0
		LDA	#>page_play
		STA	elemptr0 + 1

		JSR	ctrlsPageSelect

@wepdone:
		PLA
		JMP	@exit

@complete:
		PLA
		ASL
		TAX
		LDA	clientInitGameOvrvws, X
		STA	@update + 1
		LDA	clientInitGameOvrvws + 1, X
		STA	@update + 2
		
@update:
		JSR	clientInitGameOvrvw1P

@exit:
		JSR	ctrlsLockRelease
		RTS

@gmmismatch:
		RTS

@unknown:
		JMP	clientProcUnknownMsg
;		RTS


	.export	clientProcPlayStatGameMsg
;-------------------------------------------------------------------------------
clientProcPlayStatGameMsg:
;-------------------------------------------------------------------------------
		LDA	readmsg0
		CMP	#$04
		BEQ	@statgame

		JMP	@unknown
		
@statgame:
		LDA	readmsg0 + 2
		STA	gameData + GAME::state
		
;	Get game round from network byte order (hi, lo)
		LDA	readmsg0 + 3
		STA	gameData + GAME::round + 1
		LDA	readmsg0 + 4
		STA	gameData + GAME::round
		
		JSR	ctrlsLockAcquire
		
;	Check given game state
		LDA	readmsg0 + 2
		CMP	#GAME_ST_PREP

;	If less than GAME_ST_PREP then jump to @cont0
		BCS	@tstprep
		JMP	@cont0

@tstprep:
;	If something other than _PREP, jump to @tstplay
		BNE	@tstplay

;	At this point, game cannot be entered.  Disable any empty slot.
		LDX	#$00
		STX	tempvar_s
		STX	tempvar_q
@loop:
		LDY	tempvar_q
		
		LDA	game_slot_lo, Y
		STA	tempptr0
		LDA	#>gameData
		STA	tempptr0 + 1
		
		LDX	tempvar_s
		
		LDY	#GAMESLOT::state
		LDA	(tempptr0), Y
		BNE	@btn

		LDA	label_ovrvw_stats, X
		STA	elemptr0
		INX
		LDA	label_ovrvw_stats, X
		STA	elemptr0 + 1
		INX
		
		STX	tempvar_s
		
		LDY	#CONTROL::textptr
		LDA	#$00
		STA	(elemptr0), Y
		INY
		STA	(elemptr0), Y
		
		JSR	ctrlsControlInvalidate

		JMP	@next
		
@btn:
		LDA	button_ovrvw_dets, X
		STA	elemptr0
		INX
		LDA	button_ovrvw_dets, X
		STA	elemptr0 + 1
		INX
		
		STX	tempvar_s
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
@next:
		INC	tempvar_q

		LDX	tempvar_s
		CPX	#$0C
		BNE	@loop
		
;		JMP	@cont0
		
		LDA	readmsg0 + 2
		
@tstplay:
;FIXME
;	Test if game is paused for specific message?

		CMP	#GAME_ST_FINISH
		BCS	@gmfinish
		
		LDY	#$00
		STY	tempvar_q
		
@loop1:
		LDY	tempvar_q
		LDA	game_slot_lo, Y
		STA	tempptr3
		LDA	#>gameData
		STA	tempptr3 + 1
		
		JSR	ctrlsLockAcquire
		JSR	clientUpdateSlotState
		
		INC	tempvar_q
		LDA	tempvar_q
		CMP	#$06
		BNE	@loop1
		
		
;	Update label_ovrvw_round_det for state/round
		LDA	#<label_ovrwv_round_det
		STA	elemptr0
		LDA	#>label_ovrwv_round_det
		STA	elemptr0 + 1
		
		LDY	#CONTROL::textptr
		LDA	#<game_round
		STA	(elemptr0), Y
		STA	tempptr0
		INY
		LDA	#>game_round
		STA	(elemptr0), Y
		STA	tempptr0 + 1
		
		LDA	#$00
		STA	tempdat0
		
		LDA	gameData + GAME::round
		LDX	gameData + GAME::round + 1

		JSR	strsAppendInteger
		
		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsControlInvalidate
		
		JMP	@cont0


@gmfinish:
;	Update detail page disable buttons when game over
		LDA	#<label_ovrwv_round_det
		STA	elemptr0
		LDA	#>label_ovrwv_round_det
		STA	elemptr0 + 1

		LDY	#CONTROL::textptr
		LDA	#<text_ovrvw_finish
		STA	(elemptr0), Y
		INY
		LDA	#>text_ovrvw_finish
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate

;	Game's over - if we're sat on the detail page, kick back to the
;	overview so the result is visible right away instead of a dead
;	detail view.
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@cont0

		LDA	#<page_ovrvw
		STA	elemptr0
		LDA	#>page_ovrvw
		STA	elemptr0 + 1

		JSR	ctrlsPageSelect

@cont0:
		JSR	ctrlsLockRelease
		RTS
		
@unknown:
		JMP	clientProcUnknownMsg
;		RTS


	.export	clientProcPlayStatPeerMsg
;-------------------------------------------------------------------------------
clientProcPlayStatPeerMsg:
;-------------------------------------------------------------------------------
		LDA	readmsg0
		CMP	#$05
		BEQ	@statpeer
		
		JMP	clientProcPlayStatPeerMsgUnk
		
@statpeer:
;	Get the slot
		LDA	readmsg0 + 2
		STA	tempvar_q		;Slot number
		
		TAX
		LDA	game_slot_lo, X
		STA	tempptr3
		LDA	#>gameData
		STA	tempptr3 + 1
		
;	Store state and score in slot game data
		
		LDY	#GAMESLOT::state
		LDA	readmsg0 + 3
		STA	(tempptr3), Y
		
		CMP	#SLOT_ST_PLAY
		BNE	@notplay
		
		LDA	readmsg0 + 2
		STA	gameData + GAME::plyslt
		
;	Yes, set roll number to -1 (will get a roll of blank soon?)
		LDY	#GAMESLOT::roll
		LDA	#$FF
		STA	(tempptr3), Y
		
		LDY	#GAMESLOT::state	;Restore value
		
@notplay:
		INY
		LDA	readmsg0 + 5
		STA	(tempptr3), Y
		INY
		LDA	readmsg0 + 4
		STA	(tempptr3), Y
		
;	Start updating user interface

		JSR	ctrlsLockAcquire

;	Check if displaying Play|Detail page
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@notdetail

;	Yes, so clear any selected score slot
		LDA	#<spanel_detail_sheet
		STA	elemptr0
		LDA	#>spanel_detail_sheet
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::tag
		LDA	#$FF
		STA	(elemptr0), Y

;	Check we do have a playing player
		LDA	gameData + GAME::plyslt
		BMI	@nochgdet

;	Yes, so check if following active
		LDA	#<checkbx_det_flwactv
		STA	elemptr0
		LDA	#>checkbx_det_flwactv
		STA	elemptr0 + 1

		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		BEQ	@nochgdet
	
;	Yes, update the detail page
		LDA	tempvar_q
		STA	gameData + GAME::detslt
		
		LDX	#$00
		JSR	clientDetailUpdateAll
		JMP	@notdetail
		
@nochgdet:
;	Update whether we can follow active player or not
		JSR	clientDetailUpdateFollow
		
@notdetail:
;	Check if status update was our status 
		LDA	tempvar_q
		CMP	gameData + GAME::ourslt
		BEQ	@ourslt
		
;	No, skip update game control button
		JMP	@cont1
		
@ourslt:
;	Update Play|Overview game control button
		LDA	#<button_ovrvw_cntrl
		STA	elemptr0
		LDA	#>button_ovrvw_cntrl
		STA	elemptr0 + 1
	
		LDA	readmsg0 + 3
		CMP	#SLOT_ST_READY
		BCS 	@tstrdy

		LDY	#ELEMENT::tag
		LDA	#$00
		STA	(elemptr0), Y

		LDY	#CONTROL::textptr
		LDA	#<text_ovrvw_ready
		STA	(elemptr0), Y
		INY
		LDA	#>text_ovrvw_ready
		STA	(elemptr0), Y
		
		LDY	#CONTROL::accelchar
		LDA	#'r'
		STA	(elemptr0), Y
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		JMP	@cont0
		
@tstrdy:
		BNE	@tstprep
		
		LDY	#ELEMENT::tag
		LDA	#$01
		STA	(elemptr0), Y
		
		LDY	#CONTROL::textptr
		LDA	#<text_ovrvw_ntrdy
		STA	(elemptr0), Y
		INY
		LDA	#>text_ovrvw_ntrdy
		STA	(elemptr0), Y
		
		LDY	#CONTROL::accelchar
		LDA	#'n'
		STA	(elemptr0), Y

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		JMP	@cont0

@tstprep:
		CMP	#SLOT_ST_PREP
		BNE	@ouringame
		
		LDY	#ELEMENT::tag
		LDA	#$02
		STA	(elemptr0), Y
		
		LDY	#CONTROL::textptr
		LDA	#<text_ovrvw_rl4frst
		STA	(elemptr0), Y
		INY
		LDA	#>text_ovrvw_rl4frst
		STA	(elemptr0), Y
		
		LDY	#CONTROL::accelchar
		LDA	#'r'
		STA	(elemptr0), Y

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		JMP	@cont0

@ouringame:
		LDY	#ELEMENT::tag
		LDA	#$03
		STA	(elemptr0), Y
		
		LDY	#CONTROL::textptr
		LDA	#<text_ovrvw_play
		STA	(elemptr0), Y
		INY
		LDA	#>text_ovrvw_play
		STA	(elemptr0), Y
		
		LDY	#CONTROL::accelchar
		LDA	#$FF
		STA	(elemptr0), Y

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

@cont0:
;	If the button was already enabled, it won't have invalidated
		JSR	ctrlsControlInvalidate

@cont1:
	
clientUpdateSlotState:
;	Update Play|Overview player slot info
		LDA	tempvar_q
		ASL
		STA	tempvar_r		;Slot no * 2
		TAX
		
		LDA	label_ovrvw_stats, X
		STA	elemptr0
		LDA	label_ovrvw_stats + 1, X
		STA	elemptr0 + 1
		
		LDY	#GAMESLOT::state
		LDA	(tempptr3), Y

		LDX	gameData + GAME::state
		
		CMP	#SLOT_ST_IDLE
		BCS	@updtst0
		
		CPX	#GAME_ST_PREP
		BCS	@updtst0

;	If game state is play or higher and the slot state is less than ready, 
;	there is no player
		LDY	#CONTROL::textptr
		LDA	#<text_token_null
		STA	(elemptr0), Y
		INY
		LDA	#>text_token_null
		STA	(elemptr0), Y
		
		JMP	@done

@updtst0:
		CMP	#SLOT_ST_WAIT
		BNE	@updconst
		
;		CPX	#GAME_ST_PLAY
;		BCS	@updconst

		LDX 	gameData + GAME::round
		BNE	@updconst
		
;	Display the slot's first roll if the game isn't playing (or greater) and the slot
;	is waiting 
		LDX	tempvar_r
		
		LDY	#CONTROL::textptr
		LDA	label_ovrvw_statbufs, X
		STA	(elemptr0), Y
		STA	tempptr0
		INY
		LDA	label_ovrvw_statbufs + 1, X
		STA	(elemptr0), Y
		STA	tempptr0 + 1
		
		LDA	#$00
		STA	tempdat0
		
		LDAX	#text_slotst_waitf
		JSR	strsAppendString

		LDY	#GAMESLOT::fstrl
		LDA	(tempptr3), Y
		
		LDX	#$00
		
		JSR	strsAppendInteger
		
		LDA	#$00
		JSR	strsAppendChar		
		
		JMP	@done
	
@updconst:
		ASL				;Has slot state in .A
		TAX
		
		LDY	#CONTROL::textptr
		LDA	text_slotsts, X
		STA	(elemptr0), Y
		INY
		LDA	text_slotsts + 1, X
		STA	(elemptr0), Y

@done:
		JSR	ctrlsControlInvalidate
		
;	Display slot score 
		LDY	#GAMESLOT::state
		LDA	(tempptr3), Y
		CMP	#SLOT_ST_WAIT
		BCC	@finish

		LDA	tempvar_r
;		ASL
		TAX
		LDA	label_ovrvw_scorebufs, X
		STA	tempptr0
		LDA	label_ovrvw_scorebufs + 1, X
		STA	tempptr0 + 1
		
		LDA	label_ovrvw_scores, X
		STA	elemptr0
		LDA	label_ovrvw_scores + 1, X
		STA	elemptr0 + 1
 		
		LDA	#$00
		STA	tempdat0
		
		LDY	#GAMESLOT::score + 1
		LDA	(tempptr3), Y
		TAX
		DEY
		LDA	(tempptr3), Y
		
		JSR	strsAppendInteger
		
		LDA	#$00
		JSR	strsAppendChar		
		
		JSR	ctrlsControlInvalidate
		
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@finish
		
		LDA	tempvar_q
		CMP	gameData + GAME::detslt
		BNE	@tstour
		
		JMP	@updscr

@tstour:
		CMP	gameData + GAME::ourslt
		BNE	@finish
		
@updscr:
		JSR	clientDetailUpdateScores
		
@finish:
		JSR	ctrlsLockRelease

		RTS

clientProcPlayStatPeerMsgUnk:
		JMP	clientProcUnknownMsg
;		RTS


;-------------------------------------------------------------------------------
clientProcPlayRollMsg:
;-------------------------------------------------------------------------------
		LDA	readmsg0
		CMP	#$07
		BEQ	@roll
		
		JMP	@unknown
		
@roll:
;	Get the message slot 
		LDX	readmsg0 + 2
		
		LDA	game_slot_lo, X
		STA	tempptr0
		LDA	#>gameData
		STA	tempptr0 + 1

;	Get the dice rolled
		LDY	#GAMESLOT::dice
		LDX	#$00
@loop0:
		LDA	readmsg0 + 3, X
		STA	(tempptr0), Y
		INY
		INX

		CPX 	#$05
		BNE	@loop0

;	If we're rolling for first, calculate
		LDY	#GAMESLOT::state
		LDA	(tempptr0), Y
		CMP	#SLOT_ST_PREP
		BEQ	@firstrl
		
;	Increment roll
		LDY	#GAMESLOT::roll
		LDA	(tempptr0), Y
		
		TAX
		INX
		TXA
		STA	(tempptr0), Y

		JMP	@cont0
		
		
@firstrl:
		LDX	#$00
		LDA	#$00
		CLC
@loop1:
		ADC	readmsg0 + 3, X
		INX
		
		CPX	#$05
		BNE	@loop1

		LDY	#GAMESLOT::fstrl
		STA	(tempptr0), Y

@cont0:
;	Update detail view if showing the current slot and the game state is
;	PREP or higher
		LDA	gameData + GAME::state
		CMP	#GAME_ST_PREP
		BCC	@exit
		
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@exit
		
		LDA	gameData + GAME::detslt
		CMP	readmsg0 + 2
		BNE	@exit
		
		JSR	ctrlsLockAcquire

		JSR	clientDetailUpdateRoll

		JSR	clientDetailUpdateDice

		JSR	ctrlsLockRelease

@exit:
		RTS

@unknown:
		JMP	clientProcUnknownMsg
;		RTS


	.export	clientProcPlayKeepPeerMsg
;-------------------------------------------------------------------------------
clientProcPlayKeepPeerMsg:
;-------------------------------------------------------------------------------
		LDA	readmsg0
		CMP	#$04
		BEQ	@keeper
		
		JMP	@unknown

@keeper:
;	Get the message slot 
		LDX	readmsg0 + 2
		
		LDA	game_slot_lo, X
		STA	tempptr0
		LDA	#>gameData
		STA	tempptr0 + 1

;	Get the die number and flag
		LDX	readmsg0 + 3
		DEX
		
		LDA	die_flags, X
		LDY	#GAMESLOT::keepers
		
		LDX	readmsg0 + 4
		BEQ	@clear
		
		ORA	(tempptr0), Y
		STA	(tempptr0), Y
		
		JMP	@update
		
@clear:
		EOR	#$FF
		AND	(tempptr0), Y
		STA	(tempptr0), Y

@update:
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@exit

		LDA	readmsg0 + 2
		CMP	gameData + GAME::detslt
		BNE	@exit

		JSR	ctrlsLockAcquire
		
		JSR	clientDetailUpdateDice
		
		JSR	ctrlsLockRelease
		
@exit:
		RTS

@unknown:
		JMP	clientProcUnknownMsg
;		RTS


;-------------------------------------------------------------------------------
clientProcPlayScoreQueryMsg:
;-------------------------------------------------------------------------------
		LDA	readmsg0
		CMP	#$05
		BEQ	@scrquery
		
		JMP	@unknown

@scrquery:
		LDX	readmsg0 + 2

;	Update the visible details?
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@exit
		
		CPX	gameData + GAME::detslt
		BNE	@exit
		
		JSR	ctrlsLockAcquire

		LDA	readmsg0 + 3
		STA	tempdat0
		
		LDA	readmsg0 + 5
		STA	tempdat1
		
		JSR	clientDetailUpdatePreview

		JSR	ctrlsLockRelease
		
@exit:
		RTS

@unknown:
		JMP	clientProcUnknownMsg
;		RTS


;-------------------------------------------------------------------------------
clientProcPlayScorePeerMsg:
;-------------------------------------------------------------------------------
		LDA	readmsg0
		CMP	#$05
		BEQ	@keeper
		
		JMP	@unknown

@keeper:
;	Get the message slot 
		LDX	readmsg0 + 2
		
		LDA	game_slot_lo, X
		STA	tempptr0
		LDA	#>gameData
		STA	tempptr0 + 1

;	Score location
		LDY	readmsg0 + 3
		
;	Only low byte because the high byte will always be zero
		LDA	readmsg0 + 5
		
		STA	(tempptr0), Y
		
;	Update the visible details?
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@exit
		
		CPX	gameData + GAME::detslt
		BNE	@exit
		
		JSR	ctrlsLockAcquire
		
		LDA	#SCRSHT_SCORES
		STA	tempvar_t
		
		LDA	#<spanel_detail_sheet
		STA	elemptr0
		LDA	#>spanel_detail_sheet
		STA	elemptr0 + 1
		
		JSR	ctrlsSPanelDefPresDirect
		
		JSR	ctrlsLockRelease

@exit:
		RTS
		
@unknown:
		JMP	clientProcUnknownMsg
;		RTS
		

	.export	clientProcPlayMsg
;-------------------------------------------------------------------------------
clientProcPlayMsg:
;-------------------------------------------------------------------------------
		LDA	imsgdat2
		BNE	@tstfirst
		
;	Error message

		LDA	#<lpanel_play_log
		STA	tempptr2
		LDA	#>lpanel_play_log
		STA	tempptr2 + 1

		JSR	ctrlsLogPanelGetNextLine

		LDAX 	#text_err_pref
		JSR	strsAppendString

		LDA	#$02
		STA	tempdat1

		JSR	strsAppendMessage

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate

		RTS

@tstfirst:
		CMP	#$01
		BNE	@tstnxt0
		
		JMP	clientProcPlayJoinMsg
;		RTS
		
@tstnxt0:
		CMP	#$02
		BNE	@tstnxt1
		
		JMP	clientProcPlayPartMsg
;		RTS

@tstnxt1:
		CMP	#$06
		BNE	@tstnxt2

		JMP	clientProcPlayStatGameMsg
;		RTS

@tstnxt2:
		CMP	#$07
		BNE	@tstnxt3

		JMP	clientProcPlayStatPeerMsg
;		RTS

@tstnxt3:
		CMP	#$08
		BNE	@tstnxt4

		JMP	clientProcPlayRollMsg
;		RTS

@tstnxt4:
		CMP	#$09
		BNE	@tstnxt5
	
		JMP	clientProcPlayKeepPeerMsg
;		RTS

@tstnxt5:
		CMP	#$0A
		BNE	@tstnxt6
		
		JMP	clientProcPlayScoreQueryMsg
;		RTS

@tstnxt6:
		CMP	#$0B
		BNE	@unknown
		
		JMP	clientProcPlayScorePeerMsg
		RTS

@unknown:
		JMP	clientProcUnknownMsg
;		RTS


	.export	clientHandleReadMsg
;-------------------------------------------------------------------------------
clientHandleReadMsg:
;-------------------------------------------------------------------------------
		JSR	ctrlsLockAcquire

		LDY	#$01
		LDA	readmsg0, Y

		AND	#$0F
		STA	imsgdat2

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
		STY	imsgdat1	
		
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

		LDAX 	#eth_name
		JSR	strsAppendString

		LDA	#$00
		JSR	strsAppendChar
;
;		JSR	ctrlsLogPanelGetNextLine
;		
;		LDAX 	#text_iobase_pref
;		JSR	strsAppendString
;		
;		LDA 	eth_driver_io_base + 1
;		JSR 	strsAppendHex
;		
;		LDA 	eth_driver_io_base
;		JSR 	strsAppendHex
;
;		LDA	#$00
;		JSR	strsAppendChar
		
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

;	discEventFlags - TCP_EVENT_FLAG's EV_* bits at the moment the
;	disconnect was noticed (see inetRecordDiscEvent): bit0 RST,
;	bit1 peer FIN, bit2 our FIN completed, bit3 TIME_WAIT done,
;	bit4 connect failed, bit5 TX retries exhausted, bit6 bad SYN+ACK.
;	$00 means it was detected via the inbound-EOF sentinel instead,
;	with no TCP_EVENT_FLAG bits available.
		LDAX	#text_err_disc_evt
		JSR	strsAppendString

		LDA	discEventFlags
		JSR	strsAppendHex

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
		
		JSR	ctrlsActivateCtrl
		
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
	

;-------------------------------------------------------------------------------
clientInitGameOvrvws:
			.word	clientInitGameOvrvw1P
			.word	clientInitGameOvrvw2P
			.word	clientInitGameOvrvw3P
			.word	clientInitGameOvrvw4P
			.word	clientInitGameOvrvw5P
			.word	clientInitGameOvrvw6P

;-------------------------------------------------------------------------------
clientInitGameOvrvw1P:
;-------------------------------------------------------------------------------
		LDA	#<button_ovrvw_1p_det
		STA	elemptr0
		LDA	#>button_ovrvw_1p_det
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#$00
		STA	gameData + GAMESLOT::name

		LDA	#<label_ovrvw_1p_name
		STA	elemptr0
		LDA	#>label_ovrvw_1p_name
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		LDA	#<label_ovrvw_1p_stat
		STA	elemptr0
		LDA	#>label_ovrvw_1p_stat
		STA	elemptr0 + 1

		LDY	#CONTROL::textptr
		LDA	#<text_slotst_none
		STA	(elemptr0), Y
		INY
		LDA	#>text_slotst_none
		STA	(elemptr0), Y
		
		JSR	ctrlsControlInvalidate

		LDA	#$00
		STA	label_ovrvw_1p_score_buf

		LDA	#<label_ovrvw_1p_score
		STA	elemptr0
		LDA	#>label_ovrvw_1p_score
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate

		RTS


;-------------------------------------------------------------------------------
clientInitGameOvrvw2P:
;-------------------------------------------------------------------------------
		LDA	#<button_ovrvw_2p_det
		STA	elemptr0
		LDA	#>button_ovrvw_2p_det
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#$00
		STA	gameData + .sizeof(GAMESLOT) + GAMESLOT::name

		LDA	#<label_ovrvw_2p_name
		STA	elemptr0
		LDA	#>label_ovrvw_2p_name
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		LDA	#<label_ovrvw_2p_stat
		STA	elemptr0
		LDA	#>label_ovrvw_2p_stat
		STA	elemptr0 + 1

		LDY	#CONTROL::textptr
		LDA	#<text_slotst_none
		STA	(elemptr0), Y
		INY
		LDA	#>text_slotst_none
		STA	(elemptr0), Y
		
		JSR	ctrlsControlInvalidate

		LDA	#$00
		STA	label_ovrvw_2p_score_buf

		LDA	#<label_ovrvw_2p_score
		STA	elemptr0
		LDA	#>label_ovrvw_2p_score
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate

		RTS


;-------------------------------------------------------------------------------
clientInitGameOvrvw3P:
;-------------------------------------------------------------------------------
		LDA	#<button_ovrvw_3p_det
		STA	elemptr0
		LDA	#>button_ovrvw_3p_det
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#$00
		STA	gameData + (.sizeof(GAMESLOT)*2) + GAMESLOT::name

		LDA	#<label_ovrvw_3p_name
		STA	elemptr0
		LDA	#>label_ovrvw_3p_name
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		LDA	#<label_ovrvw_3p_stat
		STA	elemptr0
		LDA	#>label_ovrvw_3p_stat
		STA	elemptr0 + 1

		LDY	#CONTROL::textptr
		LDA	#<text_slotst_none
		STA	(elemptr0), Y
		INY
		LDA	#>text_slotst_none
		STA	(elemptr0), Y
		
		JSR	ctrlsControlInvalidate

		LDA	#$00
		STA	label_ovrvw_3p_score_buf

		LDA	#<label_ovrvw_3p_score
		STA	elemptr0
		LDA	#>label_ovrvw_3p_score
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate

		RTS


;-------------------------------------------------------------------------------
clientInitGameOvrvw4P:
;-------------------------------------------------------------------------------
		LDA	#<button_ovrvw_4p_det
		STA	elemptr0
		LDA	#>button_ovrvw_4p_det
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#$00
		STA	gameData + (.sizeof(GAMESLOT)*3) + GAMESLOT::name

		LDA	#<label_ovrvw_4p_name
		STA	elemptr0
		LDA	#>label_ovrvw_4p_name
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		LDA	#<label_ovrvw_4p_stat
		STA	elemptr0
		LDA	#>label_ovrvw_4p_stat
		STA	elemptr0 + 1

		LDY	#CONTROL::textptr
		LDA	#<text_slotst_none
		STA	(elemptr0), Y
		INY
		LDA	#>text_slotst_none
		STA	(elemptr0), Y
		
		JSR	ctrlsControlInvalidate

		LDA	#$00
		STA	label_ovrvw_4p_score_buf

		LDA	#<label_ovrvw_4p_score
		STA	elemptr0
		LDA	#>label_ovrvw_4p_score
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate

		RTS


;-------------------------------------------------------------------------------
clientInitGameOvrvw5P:
;-------------------------------------------------------------------------------
		LDA	#<button_ovrvw_5p_det
		STA	elemptr0
		LDA	#>button_ovrvw_5p_det
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#$00
		STA	gameData + (.sizeof(GAMESLOT)*4) + GAMESLOT::name

		LDA	#<label_ovrvw_5p_name
		STA	elemptr0
		LDA	#>label_ovrvw_5p_name
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		LDA	#<label_ovrvw_5p_stat
		STA	elemptr0
		LDA	#>label_ovrvw_5p_stat
		STA	elemptr0 + 1

		LDY	#CONTROL::textptr
		LDA	#<text_slotst_none
		STA	(elemptr0), Y
		INY
		LDA	#>text_slotst_none
		STA	(elemptr0), Y
		
		JSR	ctrlsControlInvalidate

		LDA	#$00
		STA	label_ovrvw_5p_score_buf

		LDA	#<label_ovrvw_5p_score
		STA	elemptr0
		LDA	#>label_ovrvw_5p_score
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate

		RTS


;-------------------------------------------------------------------------------
clientInitGameOvrvw6P:
;-------------------------------------------------------------------------------
		LDA	#<button_ovrvw_6p_det
		STA	elemptr0
		LDA	#>button_ovrvw_6p_det
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#$00
		STA	gameData + (.sizeof(GAMESLOT)*5) + GAMESLOT::name

		LDA	#<label_ovrvw_6p_name
		STA	elemptr0
		LDA	#>label_ovrvw_6p_name
		STA	elemptr0 + 1
		
		JSR	ctrlsControlInvalidate

		LDA	#<label_ovrvw_6p_stat
		STA	elemptr0
		LDA	#>label_ovrvw_6p_stat
		STA	elemptr0 + 1

		LDY	#CONTROL::textptr
		LDA	#<text_slotst_none
		STA	(elemptr0), Y
		INY
		LDA	#>text_slotst_none
		STA	(elemptr0), Y
		
		JSR	ctrlsControlInvalidate

		LDA	#$00
		STA	label_ovrvw_6p_score_buf

		LDA	#<label_ovrvw_6p_score
		STA	elemptr0
		LDA	#>label_ovrvw_6p_score
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate

		RTS


;-------------------------------------------------------------------------------
clientInitGameOvrvw:
;-------------------------------------------------------------------------------
		LDA	#<button_ovrvw_cntrl
		STA	elemptr0
		LDA	#>button_ovrvw_cntrl
		STA	elemptr0 + 1
		
		LDY	#CONTROL::textptr
		LDA	#<text_ovrvw_ready
		STA	(elemptr0), Y
		INY
		LDA	#>text_ovrvw_ready
		STA	(elemptr0), Y
		
		LDY	#ELEMENT::tag
		LDA	#$00
		STA	(elemptr0), Y
		
		LDY	#CONTROL::textaccel
		LDA	#$01
		STA	(elemptr0), Y

		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		LDA	#<label_ovrwv_round_det
		STA	elemptr0
		LDA	#>label_ovrwv_round_det
		STA	elemptr0 + 1
		
		LDY	#CONTROL::textptr
		LDA	#$00
		STA	(elemptr0), Y
		INY
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate
		
		JSR	clientInitGameOvrvw1P
		JSR	clientInitGameOvrvw2P
		JSR	clientInitGameOvrvw3P
		JSR	clientInitGameOvrvw4P
		JSR	clientInitGameOvrvw5P
		JSR	clientInitGameOvrvw6P

		RTS
	

	.export	clientPlayJoinChng
;-------------------------------------------------------------------------------
clientPlayJoinChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	inetstat
		CMP	#INET_STATE_ERR
		BEQ	@exit

		LDA	edit_play_game_buf
		BEQ	@exit

		JSR	clientSendPlayJoin

		JSR	initGameData
		JSR	clientInitGameOvrvw
		
@exit:
		RTS


	.export	clientPlayPartChng
;-------------------------------------------------------------------------------
clientPlayPartChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	inetstat
		CMP	#INET_STATE_ERR
		BEQ	@exit

		LDA	edit_play_game_buf
		BEQ	@exit

		JSR	clientSendPlayPart

		JSR	initGameData
		JSR	clientInitGameOvrvw
		
@exit:
		RTS


	.export	clientRoomJoinChng
;-------------------------------------------------------------------------------
clientRoomJoinChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	inetstat
		CMP	#INET_STATE_ERR
		BEQ	@exit

		LDA	edit_room_room_buf
		BEQ	@exit

		JSR	clientSendRoomJoin

@exit:
		RTS


	.export	clientRoomPartChng
;-------------------------------------------------------------------------------
clientRoomPartChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	inetstat
		CMP	#INET_STATE_ERR
		BEQ	@exit

		LDA	edit_room_room_buf
		BEQ	@exit

		JSR	clientSendRoomPart
		
@exit:
		RTS


;-------------------------------------------------------------------------------
clientCnctUpdChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	userNameAccepted
		BNE	@exit			;already accepted - button should be disabled, but don't re-send if clicked anyway

		JSR	clientSendUser

@exit:
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
		CMP	#INET_PROC_EXEC
		BCS	@exit

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
		LDX	#$07
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
clientMainNextChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		SEI

		LDA	pageNext
		STA	elemptr0
		LDA	pageNext + 1
		STA	elemptr0 + 1

		JSR	ctrlsPageSelect

@exit:
		RTS


;-------------------------------------------------------------------------------
clientMainBackChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		SEI

		LDA	pageBack
		STA	elemptr0
		LDA	pageBack + 1
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

		LDA	#<lpanel_room_log
		STA	elemptr0
		LDA	#>lpanel_room_log
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::posy
		LDA	#$0A
		STA	(elemptr0), Y
		INY
		INY
		LDA	#$0D
		STA	(elemptr0), Y
		
		LDY	#LOGPANEL::offsy
		LDA	#$04
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

		LDA	#<lpanel_room_log
		STA	elemptr0
		LDA	#>lpanel_room_log
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::posy
		LDA	#$06
		STA	(elemptr0), Y
		INY
		INY
		LDA	#$11
		STA	(elemptr0), Y
		
		LDY	#LOGPANEL::offsy
		LDA	#$00
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
ctrlsRoomTextChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsPanelDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BNE	@exit

		LDA	edit_room_text_buf
		BEQ	@exit
		
		JSR	clientSendRoomPeer
		
		LDA	#$00
		STA	edit_room_text_buf
		LDY	#EDITCTRL::textsiz
		STA	(elemptr0), Y		
		
		JSR	ctrlsControlInvalidate

@exit:
		RTS

;-------------------------------------------------------------------------------
clientMainPlayChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDY	#ELEMENT::options
		LDA	tlabel_main_play, Y
		AND	#OPT_NONAVIGATE
		BNE	@exit

		JSR	clientMainUnsetTabs

		LDY	#ELEMENT::colour
		LDA	#CLR_FOCUS
		STA	tlabel_main_play, Y

		LDY	#ELEMENT::options
		LDA	#(OPT_NODOWNACTV | OPT_NONAVIGATE | OPT_TEXTACCEL2X)
		STA	tlabel_main_play, Y

		SEI
		LDA	#<page_play
		STA	elemptr0
		LDA	#>page_play
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect
@exit:

		RTS


;-------------------------------------------------------------------------------
clientMainPrefsChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDY	#ELEMENT::options
		LDA	tlabel_main_prefs, Y
		AND	#OPT_NONAVIGATE
		BNE	@exit

		JSR	clientMainUnsetTabs

		LDY	#ELEMENT::colour
		LDA	#CLR_FOCUS
		STA	tlabel_main_prefs, Y

		LDY	#ELEMENT::options
		LDA	#(OPT_NODOWNACTV | OPT_NONAVIGATE | OPT_TEXTACCEL2X)
		STA	tlabel_main_prefs, Y

		SEI
		LDA	#<page_config
		STA	elemptr0
		LDA	#>page_config
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect
@exit:

		RTS


;-------------------------------------------------------------------------------
clientConfigThemeNxtChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	clrschme_idx
		CMP	#(clrschme_cnt - 1)
		BCS	@exit			;already at the last scheme

		INC	clrschme_idx

		JSR	clientConfigThemeApply

@exit:
		RTS


;-------------------------------------------------------------------------------
clientConfigThemePrvChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	clrschme_idx
		BEQ	@exit			;already at the first scheme

		DEC	clrschme_idx

		JSR	clientConfigThemeApply

@exit:
		RTS


;-------------------------------------------------------------------------------
;	clientConfigThemeApply - point label_config_theme_name at the name
;	for clrschme_idx, apply that scheme's colours, then re-select
;	page_config (via the same pageptr0 short-circuit as before) so the
;	panels redraw with the new colours and label text.
;-------------------------------------------------------------------------------
clientConfigThemeApply:
		LDA	#<clrschme_lst
		STA	tempptr0
		LDA	#>clrschme_lst
		STA	tempptr0 + 1

		LDA	clrschme_idx
		ASL
		ASL
		CLC
		ADC	#$02			;skip the scheme-data word, land
		TAY				;	on the name-pointer word

		LDA	(tempptr0), Y
		STA	label_config_theme_name + CONTROL::textptr
		INY
		LDA	(tempptr0), Y
		STA	label_config_theme_name + CONTROL::textptr + 1

		LDA	clrschme_idx
		JSR	colourSchemeSelect

		LDA	#$00
		STA	pageptr0 + 1

		LDA	#<page_config
		STA	elemptr0
		LDA	#>page_config
		STA	elemptr0 + 1
		JSR	ctrlsPageSelect

		RTS


;-------------------------------------------------------------------------------
;	The three speed checkboxes below are coerced into acting like a
;	real radio group: each one is a normal OPT_AUTOCHECK checkbox (so
;	ctrlsControlDefChanged still handles the redraw), but its changed
;	handler forces its own tag back to checked (undoing a toggle-off
;	click on the already-checked box) and forces the other two to
;	unchecked. No toggle-off limitation - clicking the checked box is
;	a no-op, clicking either other box switches selection.
;-------------------------------------------------------------------------------
clientConfigSpeedSlowChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

    LDA #$01
    STA checkbx_config_mouse_slow + ELEMENT::tag

		LDA	#<checkbx_config_mouse_medium
		STA	elemptr0
		LDA	#>checkbx_config_mouse_medium
		STA	elemptr0 + 1
		JSR	clientConfigSpeedUncheck

		LDA	#<checkbx_config_mouse_fast
		STA	elemptr0
		LDA	#>checkbx_config_mouse_fast
		STA	elemptr0 + 1
		JSR	clientConfigSpeedUncheck

		LDA	#MOUSE_SPEED_SLOW
		STA	mouseAccelSpeed

@exit:
		RTS


;-------------------------------------------------------------------------------
clientConfigSpeedMediumChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

    LDA #$01
    STA checkbx_config_mouse_medium + ELEMENT::tag

		LDA	#<checkbx_config_mouse_slow
		STA	elemptr0
		LDA	#>checkbx_config_mouse_slow
		STA	elemptr0 + 1
		JSR	clientConfigSpeedUncheck

		LDA	#<checkbx_config_mouse_fast
		STA	elemptr0
		LDA	#>checkbx_config_mouse_fast
		STA	elemptr0 + 1
		JSR	clientConfigSpeedUncheck

		LDA	#MOUSE_SPEED_MEDIUM
		STA	mouseAccelSpeed

@exit:
		RTS


;-------------------------------------------------------------------------------
clientConfigSpeedFastChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

    LDA #$01
    STA checkbx_config_mouse_fast + ELEMENT::tag

		LDA	#<checkbx_config_mouse_slow
		STA	elemptr0
		LDA	#>checkbx_config_mouse_slow
		STA	elemptr0 + 1
		JSR	clientConfigSpeedUncheck

		LDA	#<checkbx_config_mouse_medium
		STA	elemptr0
		LDA	#>checkbx_config_mouse_medium
		STA	elemptr0 + 1
		JSR	clientConfigSpeedUncheck

		LDA	#MOUSE_SPEED_FAST
		STA	mouseAccelSpeed

@exit:
		RTS


;-------------------------------------------------------------------------------
;	clientConfigSpeedUncheck - force the checkbox pointed to by elemptr0
;	back to unchecked (tag = 0) and redraw it.
;-------------------------------------------------------------------------------
clientConfigSpeedUncheck:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::tag
		LDA	#$00
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate

		RTS


;-------------------------------------------------------------------------------
clientPlayMoreChng:
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

		LDA	#<panel_play_more
		STA	elemptr0
		LDA	#>panel_play_more
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		
		LDA	#<panel_play_less
		STA	elemptr0
		LDA	#>panel_play_less
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

		LDA	#<edit_play_game
		STA	elemptr0
		LDA	#>edit_play_game
		STA	elemptr0 + 1
		
		JSR	ctrlsActivateCtrl

		LDA	#<lpanel_play_log
		STA	elemptr0
		LDA	#>lpanel_play_log
		STA	elemptr0 + 1

;!!TODO: Change an offset parameter to hide/show top lines

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
clientPlayLessChng:
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

		LDA	#<panel_play_less
		STA	elemptr0
		LDA	#>panel_play_less
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		LDA	#STATE_VISIBLE
		JSR	ctrlsIncludeState
		
		LDA	#<panel_play_more
		STA	elemptr0
		LDA	#>panel_play_more
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

		LDA	#<edit_play_text
		STA	elemptr0
		LDA	#>edit_play_text
		STA	elemptr0 + 1
		
		JSR	ctrlsActivateCtrl

		LDA	#<lpanel_play_log
		STA	elemptr0
		LDA	#>lpanel_play_log
		STA	elemptr0 + 1

;!!TODO: Change an offset parameter to hide/show top lines

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


;-------------------------------------------------------------------------------
clientOvrvwCntrlChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		BEQ	@doready
		
		CMP	#$01
		BEQ	@dontrdy
		
		JMP	clientSendPlayRollPeerFirst
;		RTS
		
@doready:
		JMP	clientSendPlayStatPeerReady
;		RTS

@dontrdy:
		JMP	clientSendPlayStatPeerNtRdy
;		RTS
		
@exit:
		RTS


;-------------------------------------------------------------------------------
clientDetailUpdatePreview:
;	IN	tempdat0	score slot
;	IN	tempdat1	score value
;-------------------------------------------------------------------------------
		LDA	tempdat1
		STA	tempvar_h
		
		LDA	#<spanel_detail_sheet
		STA	elemptr0
		LDA	#>spanel_detail_sheet
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_r		;x
		INY
		LDA	(elemptr0), Y
		STA	tempvar_s		;y
		
;	Prepare the index for the score slot
		LDY	tempdat0
		CPY	#$06
		BNE	@prepscr
		
;!!FIXME
;	Can't do a upper bonus preview!?!?
		RTS
		
@prepscr:
		BCS	@lower

;	Prepare for "upper" area
		LDA	tempvar_r
		CLC
		ADC	#$08
		STA	tempvar_r
		
		INY
		TYA
		CLC
		ADC	tempvar_s
		STA	tempvar_s
		
		JMP	@presscr

@lower:
		DEY
		
		LDA	tempvar_r
		CLC
		ADC	#$16
		STA	tempvar_r
		
		TYA	
		SEC
		SBC	#$05
		
		CLC
		ADC	tempvar_s
		STA	tempvar_s
		
		CPY	#$0D
		BCC	@presscr
		
		JMP	@lbonus
		
@presscr:
		LDY	#SCRSHTPANEL::hveprvw
		LDA	#$01
		STA	(elemptr0), Y
		
		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		LDA	#$05
		STA	tempvar_c
		LDA	#$01
		STA	tempvar_d
	
		LDA	#CLR_TEXT
		JSR	screenRectSetColour

		LDA	#$00
		STA	tempdat1
		STA	tempvar_d

		LDA	#$05
		STA	tempdat2

		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
;	Get the score value and convert to string

		LDA	#<temp_num
		STA	tempptr0
		LDA	#>temp_num
		STA	tempptr0 + 1
		
		LDA	#$00
		STA	tempdat0

		LDAX	#text_scrsht_bscr
		
		JSR	strsAppendString
		
		LDA	#$00
		STA	tempdat0

		LDA	tempvar_h
		LDX	#$00
		
		JSR	strsAppendInteger
		
		LDA	#<temp_num
		STA	tempptr1
		LDA	#>temp_num
		STA	tempptr1 + 1
		
		LDA	#CLR_TEXT
		STA	tempdat0
		
		LDA	#$00
		STA	tempdat3

		JSR	ctrlsDrawTextDirect

		RTS

@lbonus:
;!!TODO
;	Preview lower (yahtzee) bonuses

		RTS
		

	.export	clientDetailUpdateRoll
;-------------------------------------------------------------------------------
clientDetailUpdateRoll:
;-------------------------------------------------------------------------------
		LDY	#GAMESLOT::roll
		LDA	(tempptr0), Y
		
		BPL	@normal
	
		LDA	#$03
		
@normal:
		ASL
		TAX
		
		LDA	#<button_det_roll
		STA	elemptr0
		LDA	#>button_det_roll
		STA	elemptr0 + 1
		
		LDY	#CONTROL::textptr
		LDA	text_det_rolls, X
		STA	(elemptr0), Y
		INY
		LDA	text_det_rolls + 1, X
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate

;	Disable Roll once all 3 rolls are used, even if this is our own
;	slot being viewed - clientDetailUpdateEnable doesn't know about
;	roll count, so this is the only place that can gate it.
		CPX	#$06
		BCS	@exhausted

		LDA	gameData + GAME::ourslt
		CMP	gameData + GAME::detslt
		BNE	@exhausted

		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState

		RTS

@exhausted:
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		RTS


;-------------------------------------------------------------------------------
clientDetailUpdateDice:
;-------------------------------------------------------------------------------
		LDY	#GAMESLOT::dice
		STY	tempvar_b
		LDX	#$00
@loop0:
		LDA	die_det_dice, X
		STA	elemptr0
		INX
		LDA	die_det_dice, X
		STA	elemptr0 + 1
		INX
				
		LDY	tempvar_b
		LDA	(tempptr0), Y
		INC	tempvar_b
		
		LDY	#DIECTRL::value
		STA	(elemptr0), Y
		
		CPX	#$0A
		BNE	@loop0
		
		LDY	#GAMESLOT::keepers
		LDA	(tempptr0), Y
		STA	tempvar_b
		LDX	#$00
@loop1:
		TXA
		ASL
		TAY

		LDA	die_det_dice, Y
		STA	elemptr0
		LDA	die_det_dice + 1, Y
		STA	elemptr0 + 1

		LDA	die_flags, X
		AND	tempvar_b
		BEQ	@notkeep
		
		LDA	#$01
		JMP	@updkeep
		
@notkeep:
		LDA	#$00
		
@updkeep:
		LDY	#ELEMENT::tag
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate

		INX
		CPX	#$05
		BNE	@loop1

		RTS
		

;-------------------------------------------------------------------------------
clientDetailUpdateEnable:
;-------------------------------------------------------------------------------
		LDA	gameData + GAME::ourslt
		CMP	gameData + GAME::detslt
		BEQ	@enable
		
		JMP	@disable
		
@enable:
		LDA	#<button_det_roll
		STA	elemptr0
		LDA	#>button_det_roll
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<button_det_keep1
		STA	elemptr0
		LDA	#>button_det_keep1
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<button_det_keep2
		STA	elemptr0
		LDA	#>button_det_keep2
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<button_det_keep3
		STA	elemptr0
		LDA	#>button_det_keep3
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<button_det_keep4
		STA	elemptr0
		LDA	#>button_det_keep4
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<button_det_keep5
		STA	elemptr0
		LDA	#>button_det_keep5
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<die_det_0
		STA	elemptr0
		LDA	#>die_det_0
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<die_det_1
		STA	elemptr0
		LDA	#>die_det_1
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<die_det_2
		STA	elemptr0
		LDA	#>die_det_2
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<die_det_3
		STA	elemptr0
		LDA	#>die_det_3
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<die_det_4
		STA	elemptr0
		LDA	#>die_det_4
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<button_det_select
		STA	elemptr0
		LDA	#>button_det_select
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		LDA	#<button_det_confirm
		STA	elemptr0
		LDA	#>button_det_confirm
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
		RTS
		
@disable:
		LDA	#<button_det_roll
		STA	elemptr0
		LDA	#>button_det_roll
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<button_det_keep1
		STA	elemptr0
		LDA	#>button_det_keep1
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<button_det_keep2
		STA	elemptr0
		LDA	#>button_det_keep2
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<button_det_keep3
		STA	elemptr0
		LDA	#>button_det_keep3
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<button_det_keep4
		STA	elemptr0
		LDA	#>button_det_keep4
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<button_det_keep5
		STA	elemptr0
		LDA	#>button_det_keep5
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<die_det_0
		STA	elemptr0
		LDA	#>die_det_0
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<die_det_1
		STA	elemptr0
		LDA	#>die_det_1
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<die_det_2
		STA	elemptr0
		LDA	#>die_det_2
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<die_det_3
		STA	elemptr0
		LDA	#>die_det_3
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<die_det_4
		STA	elemptr0
		LDA	#>die_det_4
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<button_det_select
		STA	elemptr0
		LDA	#>button_det_select
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		LDA	#<button_det_confirm
		STA	elemptr0
		LDA	#>button_det_confirm
		STA	elemptr0 + 1
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState

		RTS


;-------------------------------------------------------------------------------
clientDetailUpdateScores:
;-------------------------------------------------------------------------------
;	Update "our score"
		LDA	#<static_det_yourscr
		STA	elemptr0
		LDA	#>static_det_yourscr
		STA	elemptr0 + 1
		
		LDX	gameData + GAME::ourslt
		LDA	game_slot_lo, X
		STA	tempptr3
		LDA	#>gameData
		STA	tempptr3 + 1
		
		LDA	#<text_det_yourscr_buf
		STA	tempptr0
		LDA	#>text_det_yourscr_buf
		STA	tempptr0 + 1
		
		LDA	#$00
		STA	tempdat0
		
		LDY	#GAMESLOT::score + 1
		LDA	(tempptr3), Y
		TAX
		DEY
		LDA	(tempptr3), Y
		
		JSR	strsAppendInteger
		
		LDA	#$00
		JSR	strsAppendChar
		
		JSR	ctrlsControlInvalidate
		
;	Update "their score" if the detail view isn't for us (or blank)

		LDA	#<static_det_theirscr
		STA	elemptr0
		LDA	#>static_det_theirscr
		STA	elemptr0 + 1

		LDA	#<text_det_theirscr_buf
		STA	tempptr0
		LDA	#>text_det_theirscr_buf
		STA	tempptr0 + 1
		
		LDX	gameData + GAME::detslt
		CPX	gameData + GAME::ourslt
		BNE	@score

		LDA	#$00
		LDY	#$00
		STA	(tempptr0), Y
		
		JMP	@done

@score:
		LDA	game_slot_lo, X
		STA	tempptr3
		LDA	#>gameData
		STA	tempptr3 + 1
		
		LDA	#$00
		STA	tempdat0
		
		LDY	#GAMESLOT::score + 1
		LDA	(tempptr3), Y
		TAX
		DEY
		LDA	(tempptr3), Y
		
		JSR	strsAppendInteger
		
		LDA	#$00
		JSR	strsAppendChar
		
@done:
		JSR	ctrlsControlInvalidate

@exit:
		RTS


;-------------------------------------------------------------------------------
clientDetailUpdateFollow:
;-------------------------------------------------------------------------------
		LDA	#<checkbx_det_flwactv
		STA	elemptr0
		LDA	#>checkbx_det_flwactv
		STA	elemptr0 + 1
		
		LDA	currpgtag
		CMP	#PAGE_PLYDETAIL
		BNE	@clear
		
		LDA	gameData + GAME::plyslt
		CMP	gameData + GAME::detslt
		BNE	@clear
		
		LDA	#STATE_ENABLED
		JSR	ctrlsIncludeState
		
;	Update active control to roll button
		LDA	#<button_det_roll
		STA	elemptr0
		LDA	#>button_det_roll
		STA	elemptr0 + 1

		JSR	ctrlsActivateCtrl

		RTS
		
@clear:
		LDY	#ELEMENT::tag
		LDA	#$00
		STA	(elemptr0), Y
		
		LDA	#STATE_ENABLED
		JSR	ctrlsExcludeState
		
		JSR	ctrlsControlInvalidate
		
		RTS


;-------------------------------------------------------------------------------
clientDetailUpdateAll:
;-------------------------------------------------------------------------------
		TXA
		PHA
		
		LDA	gameData + GAME::detslt
		ASL
		STA	tempvar_a

;	Copy the slot's ident
		TAX
		LDA	label_ovrvw_names, X
		STA	tempptr0
		LDA	label_ovrvw_names + 1, X
		STA	tempptr0 + 1
		
		LDA	#<static_det_ident
		STA	elemptr0
		LDA	#>static_det_ident
		STA	elemptr0 + 1
		
		LDY	#CONTROL::textptr
		LDA	(tempptr0), Y
		STA	(elemptr0), Y
		INY
		LDA	(tempptr0), Y
		STA	(elemptr0), Y

		JSR	ctrlsControlInvalidate
		
		LDX	gameData + GAME::detslt
		LDA	game_slot_lo, X
		STA	tempptr0
		LDA	#>gameData
		STA	tempptr0 + 1
		
		JSR	clientDetailUpdateRoll
		
		JSR	clientDetailUpdateDice
		
		JSR	clientDetailUpdateEnable
		
		JSR	clientDetailUpdateFollow
		
		JSR	clientDetailUpdateScores
		
		PLA
		BMI	@exit
		
		LDA	#SCRSHT_SCORES
		STA	tempvar_t
		
		LDA	#<spanel_detail_sheet
		STA	elemptr0
		LDA	#>spanel_detail_sheet
		STA	elemptr0 + 1
		
		JSR	ctrlsSPanelDefPresDirect
		
@exit:
		RTS


;-------------------------------------------------------------------------------
clientOvrvwDetChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit
	
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		
		STA	gameData + GAME::detslt
		
		LDA	#<page_detail
		STA	elemptr0
		LDA	#>page_detail
		STA	elemptr0 + 1
		
		JSR	ctrlsPageSelect

		LDA	#<spanel_detail_sheet
		STA	elemptr0
		LDA	#>spanel_detail_sheet
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::tag
		LDA	#$FF
		STA	(elemptr0), Y
		
;		LDY	#SCRSHTPANEL::lastind
;		STA	(elemptr0), Y

		LDX	#$FF
		JSR	clientDetailUpdateAll
@exit:
		RTS


;-------------------------------------------------------------------------------
clientDetRollChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit
		
		LDA	gameData + GAME::ourslt
		CMP	gameData + GAME::detslt
		BNE	@exit
		
		JSR	clientSendPlayRoll 

@exit:
		RTS
		

	.export	clientDetKeepChng
;-------------------------------------------------------------------------------
clientDetKeepChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

;	Send the keeper peer message

		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		
		STA	tempvar_a
		ASL
		TAX
		LDA	die_det_dice, X
		STA	elemptr0
		LDA	die_det_dice + 1, X
		STA	elemptr0 + 1
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		EOR 	#$01
		STA	tempvar_b

		JSR	clientSendPlayKeepersPeer

@exit:
		RTS


;-------------------------------------------------------------------------------
clientDetSelectChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit

		LDA	#<spanel_detail_sheet
		STA	elemptr0
		LDA	#>spanel_detail_sheet
		STA	elemptr0 + 1
		
		JSR	ctrlsDownCtrl

@exit:
		RTS


;-------------------------------------------------------------------------------
clientDetConfirmChng:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit
		
		JSR	clientSendPlayScorePeer
		
@exit:
		RTS
		




;-------------------------------------------------------------------------------
;	Fills dmaCnt bytes of screen/colour RAM starting at dmaDst with the
;	byte in .A, via an inline enhanced DMA job (same 12-byte layout
;	proven working in initHiVars - just the count/value/dst fields
;	self-modified per call instead of being link-time constants)
;	rather than a per-byte CPU loop. Used for row fills only (dmaCnt
;	is a single byte, so max 255 bytes/call), by ctrlsEraseBkg and
;	screenRectSetColour.
;	IN	.A		fill byte
;	IN	dmaDst		destination address
;	IN	dmaDstBank	destination bank (bits 16-23 of a 24-bit
;				address - $00 for screen/chip RAM, $01 for
;				colour RAM's real physical address $01F800,
;				see colourRowsHiPhys)
;	IN	dmaCnt		byte count (1-255)
;	USED	.A
;-------------------------------------------------------------------------------
dmaFillRow:
;-------------------------------------------------------------------------------
		STA	@val

		LDA	dmaCnt
		STA	@cnt
		LDA	dmaDst
		STA	@dst
		LDA	dmaDst + 1
		STA	@dst + 1
		LDA	dmaDstBank
		STA	@dstbank

		STA	$D707
		.byte	$00		;end of job options
		.byte	$03		;fill
@cnt:		
    .byte	$00
		.byte	$00		;count hi (row fills are always < 256 bytes)
@val:		
    .byte	$00
		.byte	$00		;value hi (unused - fill byte is the low byte)
		.byte	$00		;src bank
@dst:		
    .word	$0000
@dstbank:	
    .byte	$00		;dst bank
		.byte	$00		;cmd hi
		.word	$0000		;modulo/ignored

		RTS


;-------------------------------------------------------------------------------
;	Copies dmaCnt bytes from dmaSrc to dmaDst via an inline enhanced
;	DMA job - same layout as dmaFillRow, but cmd $00 (copy) instead of
;	$03 (fill), so the word field after the command bytes is read as
;	a source address instead of a fill value.
;	IN	dmaSrc		source address
;	IN	dmaDst		destination address
;	IN	dmaCnt		byte count (1-255)
;	USED	.A
;-------------------------------------------------------------------------------
dmaCopyRow:
;-------------------------------------------------------------------------------
		LDA	dmaCnt
		STA	@cnt
		LDA	dmaSrc
		STA	@src
		LDA	dmaSrc + 1
		STA	@src + 1
		LDA	dmaDst
		STA	@dst
		LDA	dmaDst + 1
		STA	@dst + 1

		STA	$D707
		.byte	$00		;end of job options
		.byte	$00		;copy
@cnt:		
    .byte	$00
		.byte	$00		;count hi (row copies are always < 256 bytes)
@src:		
    .word	$0000
		.byte	$00		;src bank
@dst:		
    .word	$0000
		.byte	$00		;dst bank
		.byte	$00		;cmd hi
		.word	$0000		;modulo/ignored

		RTS


;-------------------------------------------------------------------------------
screenRectSetColour:
;	IN	.A		Colour ident
;	IN	tempvar_a	x pos
;	IN	tempvar_b	y pos
;	IN	tempvar_c	width
;	IN	tempvar_d	height
;	USED	.A
;	USED	.X
;	USED	.Y
;	USED	tempvar_e
;	USED	tempptr1
;-------------------------------------------------------------------------------
		JSR	screenCtrlToLogClr	
		STA	tempvar_e		;logical colour

@looph:
		LDX	tempvar_b
		LDA	screenRowsLo, X
		CLC
		ADC	tempvar_a
		STA	dmaDst
		LDA	colourRowsHiPhys, X
		ADC	#$00
		STA	dmaDst + 1

		LDA	#$01			;colour RAM's real physical
		STA	dmaDstBank		;address is $01F800, not $D800

		LDA	tempvar_c
		STA	dmaCnt

		LDA	tempvar_e		;colour to colour ram
		JSR	dmaFillRow

		INC	tempvar_b
		DEC	tempvar_d
		LDA	tempvar_d
		BNE	@looph

		RTS


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
		CMP	#CLR_BACK
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
strsAppendParam:
;-------------------------------------------------------------------------------
		STA	tempptr1
		STX	tempptr1 + 1

		LDY	tempdat3

@loop:
		LDA	(tempptr1), Y
		CMP	#KEY_ASC_SPACE
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
;	Every caller of strsAppendMessage fills a fixed-size log-panel line
;	buffer (.res 41 - 40 visible columns + 1 null terminator, e.g.
;	cnct_log_line0). Stopping the copy once tempdat0 reaches this
;	leaves exactly the 1 byte callers need for their own trailing
;	strsAppendChar #$00 - without it, a line too long (a long poem
;	verse, chat message, etc) silently overruns into the NEXT line's
;	buffer with no warning at all.
LOGLINE_MAX = 40

strsAppendMessage:
;-------------------------------------------------------------------------------
;	Bound checked BEFORE each copy (not just via an exact-match exit)
;	so an empty tail - tempdat1 already at or past readmsglen, e.g. a
;	Data message whose text param is empty - can't make Y overshoot
;	readmsglen and run away copying garbage for up to 256 bytes before
;	accidentally landing back on an exact match. Also capped against
;	LOGLINE_MAX so an over-length message can't overrun the
;	destination buffer either.
		LDY	tempdat1
		CPY	readmsglen
		BCS	@done

		LDY	tempdat0
		CPY	#LOGLINE_MAX
		BCS	@done

;	count = min(bytes of room left in the destination line,
;	bytes remaining unread in readmsg0) - both are >= 1 here, so the
;	DMA job below never runs with a zero count.
		LDA	readmsglen
		SEC
		SBC	tempdat1
		STA	dmaCnt

		LDA	#LOGLINE_MAX
		SEC
		SBC	tempdat0
		CMP	dmaCnt
		BCS	@havecnt

		STA	dmaCnt

@havecnt:
		LDA	tempptr0
		CLC
		ADC	tempdat0
		STA	dmaDst
		LDA	tempptr0 + 1
		ADC	#$00
		STA	dmaDst + 1

		LDA	#<readmsg0
		CLC
		ADC	tempdat1
		STA	dmaSrc
		LDA	#>readmsg0
		ADC	#$00
		STA	dmaSrc + 1

		JSR	dmaCopyRow

		LDA	dmaCnt
		CLC
		ADC	tempdat0
		STA	tempdat0
		LDA	dmaCnt
		CLC
		ADC	tempdat1
		STA	tempdat1

@done:
		RTS


;-------------------------------------------------------------------------------
;	Wraps an arbitrary-length null-terminated string (AX) across the
;	current log line and, if it doesn't fit, additional lines obtained
;	via ctrlsLogPanelGetNextLine - each continuation line is prefixed
;	"/ " to match the motd/README.txt convention. Unlike the poem text
;	(pre-wrapped by hand at file-authoring time), chat text arrives at
;	whatever length another client sent (up to readmsg0's 100 bytes),
;	so the client has to wrap it itself. Caller must still close out
;	the final line with its own trailing strsAppendChar #$00, same as
;	after strsAppendString/strsAppendMessage.
strsAppendWrapped:
;-------------------------------------------------------------------------------
		STA	tempptr3
		STX	tempptr3 + 1

@loop:
		LDY	#$00
		LDA	(tempptr3), Y
		BEQ	@done

		LDA	tempdat0
		CMP	#LOGLINE_MAX
		BCC	@haveroom

;	Current line full - close it out and continue on a new one
		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_wrap_pref
		JSR	strsAppendString

@haveroom:
		LDY	#$00
		LDA	(tempptr3), Y

		LDY	tempdat0
		STA	(tempptr0), Y
		INY
		STY	tempdat0

		INW	tempptr3
		JMP	@loop

@done:
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


	.export	msgsPushInvalid
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

;	Stop the blinking cursor. If it's currently sitting reversed
;	(crsr_on), one more XOR $80 undoes the last one and leaves the
;	cell normal; if it's already normal, nothing to touch.
		LDA	crsr_active
		BEQ	@exit

		LDA	#$00
		STA	crsr_active

		LDA	crsr_on
		BEQ	@exit

		LDY	crsr_row
		LDA	screenRowsLo, Y
		STA	tempptr1
		LDA	screenRowsHi, Y
		STA	tempptr1 + 1

		LDY	crsr_col
		LDA	(tempptr1), Y
		EOR	#$80
		STA	(tempptr1), Y

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
;	Only invalidate elements NOT already STATE_DIRTY

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_DIRTY
		BNE	@exit

;	Only invalidate elements with STATE_PREPARED

		LDA	(elemptr0), Y
		AND	#STATE_PREPARED
		BEQ	@exit

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
		STA	tempvar_g		;low byte shared by screen & colour rows
		CLC
		ADC	tempvar_a
		STA	dmaDst
		LDA	screenRowsHi, X
		ADC	#$00
		STA	dmaDst + 1

		LDA	#$00
		STA	dmaDstBank

		LDA	tempvar_c
		STA	dmaCnt

		LDA	tempvar_f		;char to screen ram
		JSR	dmaFillRow

		LDA	tempvar_g
		CLC
		ADC	tempvar_a
		STA	dmaDst
		LDA	colourRowsHiPhys, X
		ADC	#$00
		STA	dmaDst + 1

		LDA	#$01			;colour RAM's real physical
		STA	dmaDstBank		;address is $01F800, not $D800

		LDA	tempvar_c
		STA	dmaCnt

		LDA	tempvar_e		;colour to colour ram
		JSR	dmaFillRow

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

;	Got a current page?

		LDA	pageptr0 + 1
		BEQ	@cont0

;	Hide the current page

		LDY	#ELEMENT::state
		LDA	(pageptr0), Y
		AND	#($FF ^ (STATE_VISIBLE | STATE_PREPARED))
		STA	(pageptr0), Y

;	Remove STATE_PREPARED from all page elements

;	Find last panel on page
		LDY	#PAGE::panels
		LDA	(pageptr0), Y
		STA	tempptr0
		INY
		LDA	(pageptr0), Y
		STA	tempptr0 + 1

		LDY	#PAGE::panlcnt
		LDA	(pageptr0), Y
		ASL
		STA	tempvar_a
		DEC	tempvar_a

@panel0:
;	for each panel on page rev
		LDY	tempvar_a

		LDA	(tempptr0), Y
		STA	tempptr1 + 1
		DEY
		LDA	(tempptr0), Y
		STA	tempptr1
		DEY
		
		STY	tempvar_a

		LDY	#ELEMENT::state
		LDA	(tempptr1), Y
		AND	#$FF ^ STATE_PREPARED
		STA	(tempptr1), Y
		
;	for each elem in panel 

		LDY	#PANEL::controls
		LDA	(tempptr1), Y
		STA	tempptr2
		INY
		LDA	(tempptr1), Y
		STA	tempptr2 + 1

		LDY	#$00
		
@elem0:
		LDA	(tempptr2), Y
		STA	tempptr3
		INY
		LDA	(tempptr2), Y
		BEQ	@panelnext
		
		STA	tempptr3 + 1
		INY
		
		STY	tempvar_b

		LDY	#ELEMENT::state
		LDA	(tempptr3), Y
		AND	#$FF ^ STATE_PREPARED
		STA	(tempptr3), Y

@elemnext:
		LDY	tempvar_b
		JMP	@elem0

@panelnext:
		LDY	tempvar_a
		BMI	@cont0
		
		JMP	@panel0

@cont0:
;	Set the current page

		LDA	elemptr0
		STA	pageptr0
		LDA	elemptr0 + 1
		STA	pageptr0 + 1

		LDY	#ELEMENT::state
		LDA	(pageptr0), Y
		ORA	#STATE_VISIBLE | STATE_PREPARED
		STA	(pageptr0), Y

		LDY	#ELEMENT::tag
		LDA	(pageptr0), Y
		STA	currpgtag

;	Clear picked, down and active controls

		LDA	#$00
		STA	pickCtrl
		STA	pickCtrl + 1
		STA	downCtrl 
		STA	downCtrl + 1
		STA	actvCtrl
		STA	actvCtrl + 1

;	Copy header text

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
		
;	Set-up the back and next buttons

		LDA	#$00
		STA	button_main_next + ELEMENT::state
		STA	button_main_back + ELEMENT::state

		LDY	#PAGE::nxtpage + 1
		LDA	(pageptr0), Y
		BEQ	@chkback
		
		STA	pageNext + 1
		DEY
		LDA	(pageptr0), Y
		STA	pageNext
		
		LDA	#STATE_VISIBLE | STATE_ENABLED
		STA	button_main_next + ELEMENT::state

@chkback:
		LDY	#PAGE::bakpage + 1
		LDA	(pageptr0), Y
		BEQ	@tabhdr
		
		STA	pageBack + 1
		DEY
		LDA	(pageptr0), Y
		STA	pageBack
		
		LDA	#STATE_VISIBLE | STATE_ENABLED
		STA	button_main_back + ELEMENT::state

@tabhdr:
		
;	Put tab header on page
		
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

		INY
		LDA	(tempptr2), Y		;linecnt
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

		INY
		LDA	(tempptr2), Y		;linecnt

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
		RTS

@update:
		JSR	ctrlsLockAcquire

		LDA	tempptr2
		STA	elemptr0
		LDA	tempptr2 + 1
		STA	elemptr0 + 1

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


;-------------------------------------------------------------------------------
ctrlsSPanelMouseMove:
;-------------------------------------------------------------------------------
		JSR	ctrlsLockAcquire
		
		LDA	mouseCapCtrl
		STA	elemptr0
		LDA	mouseCapCtrl + 1
		STA	elemptr0 + 1
		
		JSR	userMouseInCtrl
		BCC	@exit
		
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_a
		INY
		LDA	(elemptr0), Y
		STA	tempvar_b
		
		LDA	mouseYRow
		SEC
		SBC	tempvar_b
		STA	tempvar_b
		
		LDA	mouseXCol
		SEC
		SBC	tempvar_a
		STA	tempvar_a
		
		CMP	#$0E
		BCS	@lower
		
		LDA	tempvar_b
		BEQ	@exit
		
		CMP	#$07
		BCS	@exit
		
		TAX
		DEX
		STX	tempdat0
		
		JMP	@updind
	
@lower:
		LDA	tempvar_b
		BEQ	@exit
		
		CMP	#$08
		BCS	@exit
		
		TAX
		DEX
		TXA
		
		CLC
		ADC	#$06
		STA	tempdat0
		
@updind:
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		LDX	#$00
		JSR	ctrlsSPanelPresSelect

		LDA	tempdat0
		LDY	#ELEMENT::tag
		STA	(elemptr0), Y
		
		LDY	#SCRSHTPANEL::lastind
		STA	(elemptr0), Y
		
		LDX	#$01
		JSR	ctrlsSPanelPresSelect		
		
@exit:
		JSR	ctrlsLockRelease
		
		RTS
		

;-------------------------------------------------------------------------------
ctrlsSPanelMouseClick:
;-------------------------------------------------------------------------------
		JSR	ctrlsLockAcquire

		LDA	mouseCapCtrl
		STA	elemptr0
		LDA	mouseCapCtrl + 1
		STA	elemptr0 + 1

		JSR	userMouseInCtrl
		BCC	@exit
		
		JSR	ctrlsUnDownCtrl
		
		LDA	#<button_det_confirm
		STA	elemptr0
		LDA	#>button_det_confirm
		STA	elemptr0 + 1
		
		JSR	ctrlsActivateCtrl
		
@exit:
		JSR	ctrlsLockRelease
		
		RTS
		

;-------------------------------------------------------------------------------
ctrlsSPanelDefChanged:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsPanelDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@release

;	Check if we need to represent the scores
		LDY	#SCRSHTPANEL::hveprvw
		LDA	(elemptr0), Y
		BEQ	@capture

		LDA	#SCRSHT_SCORES
		STA	tempvar_t
		
		JSR	ctrlsSPanelDefPresDirect

@capture:
		LDA	mouseCapture		;Sanity check mouse capture
		BNE	@cont0			;Should check control...

		LDA	elemptr0
		STA	mouseCapCtrl
		LDA	elemptr0 + 1
		STA	mouseCapCtrl + 1

		LDA	#<ctrlsSPanelMouseMove
		STA	mouseCapMove
		LDA	#>ctrlsSPanelMouseMove
		STA	mouseCapMove + 1

		LDA	#<ctrlsSPanelMouseClick
		STA	mouseCapClick
		LDA	#>ctrlsSPanelMouseClick
		STA	mouseCapClick + 1
		
		JSR	userCaptureMouse
		
@cont0:
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		BPL	@exit

		LDA	#$00
		STA	(elemptr0), Y
		
		LDY	#SCRSHTPANEL::lastind
		STA	(elemptr0), Y
		
		JMP	@exit

@release:

		JSR	clientSendPlayScoreQuery

		LDA	mouseCapture		;Sanity check mouse capture
		BEQ	@exit			;Should check control...

		JSR	userReleaseMouse

		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
@exit:
		LDX	#$01
		JSR	ctrlsSPanelPresSelect

		RTS


;-------------------------------------------------------------------------------
ctrlsLabelDefChanged:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		STA	tempdat0

		JSR	ctrlsControlDefChanged

		LDA	tempdat0
		AND	#STATE_DOWN
		BEQ	@exit
		
		LDY	#LABELCTRL::actvctrl
		LDA	(elemptr0), Y
		STA	tempptr0
		INY
		LDA	(elemptr0), Y
		STA	tempptr0 + 1
		
		LDA	tempptr0
		STA	elemptr0
		LDA	tempptr0 + 1
		STA	elemptr0 + 1
		
;		JSR	ctrlsActivateCtrl
		JSR	ctrlsDownCtrl

@exit:
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

		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_NOAUTOINVL
		BNE	@cont0

		JSR	ctrlsControlInvalidate

@cont0:
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

		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_NOAUTOINVL
		BNE	@next

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

		LDA	#$00
		STA	tempvar_a

		LDA	(elemptr0), Y
		AND	#STATE_DOWN
		BEQ	@dirty

		LDA	#$01
		STA	tempvar_a
		
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
		LDY	#ELEMENT::options
		
		LDA	tempvar_a
		BEQ	@cont1

		LDA	(elemptr0), Y
		AND	#OPT_AUTOCHECK
		BEQ	@cont1
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		BEQ	@check
		
		LDA	#$00
		JMP	@cont0

@check:
		LDA	#$01
		
@cont0:
		STA	(elemptr0), Y
		
		LDY	#ELEMENT::options
@cont1:
		LDA	(elemptr0), Y
		AND	#OPT_NOAUTOINVL
		BNE	@exit

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


;-------------------------------------------------------------------------------
;	Hand-catalogued from the MEGA65 keyboard manual plus live
;	DEBUG_KEYSCAN testing on real hardware (several manual entries
;	turned out wrong, e.g. MEGA+up-arrow is $FF not the manual's $00,
;	and MEGA+0/MEGA+1 both genuinely report $81, not distinct codes).
;	Paired tables covering only the letters/digits controls actually
;	use as accelerators: keyMegaAccelTbl[i] is the raw ASCIIKEY byte
;	reported with MEGA held; keyMegaAccelBase[i] is that same key's
;	plain (no-modifier) character - what's stored in accelchar. Uses
;	the KEY_ASC_* defines rather than quoted char literals, since
;	ca65's own charmap (not necessarily plain ASCII) applies to those.
;-------------------------------------------------------------------------------
keyMegaAccelTbl:
		.byte	$C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA	;a-j
		.byte	$CB, $CC, $CD, $CE, $CF, $D0, $D1, $D2, $D3, $D4	;k-t
		.byte	$D5, $D6, $D7, $D8, $D9, $DA				;u-z
		.byte	$81, $95, $96, $97, $98, $99, $9A, $9B, $92		;1-9 (0 shares 1's $81 - no control uses '0')
keyMegaAccelTblEnd:

keyMegaAccelBase:
		.byte	KEY_ASC_L_A, KEY_ASC_L_B, KEY_ASC_L_C, KEY_ASC_L_D, KEY_ASC_L_E
		.byte	KEY_ASC_L_F, KEY_ASC_L_G, KEY_ASC_L_H, KEY_ASC_L_I, KEY_ASC_L_J
		.byte	KEY_ASC_L_K, KEY_ASC_L_L, KEY_ASC_L_M, KEY_ASC_L_N, KEY_ASC_L_O
		.byte	KEY_ASC_L_P, KEY_ASC_L_Q, KEY_ASC_L_R, KEY_ASC_L_S, KEY_ASC_L_T
		.byte	KEY_ASC_L_U, KEY_ASC_L_V, KEY_ASC_L_W, KEY_ASC_L_X, KEY_ASC_L_Y
		.byte	KEY_ASC_L_Z
		.byte	KEY_ASC_1, KEY_ASC_2, KEY_ASC_3, KEY_ASC_4, KEY_ASC_5
		.byte	KEY_ASC_6, KEY_ASC_7, KEY_ASC_8, KEY_ASC_9


;-------------------------------------------------------------------------------
;	Translates a MEGA-modified ASCIIKEY byte back to the plain
;	character the same key reports alone, via keyMegaAccelTbl/
;	keyMegaAccelBase above, so it can be matched against accelchar.
;	IN	.A		raw ASCIIKEY byte (MEGA held)
;	OUT	.A		base character, or $00 if no accelerator uses that key
;	USED	.X
;-------------------------------------------------------------------------------
keyMegaToBase:
;-------------------------------------------------------------------------------
		LDX	#$00
@loop:
		CPX	#(keyMegaAccelTblEnd - keyMegaAccelTbl)
		BCS	@notfound

		CMP	keyMegaAccelTbl, X
		BEQ	@found

		INX
		JMP	@loop

@found:
		LDA	keyMegaAccelBase, X
		RTS

@notfound:
		LDA	#$00
		RTS


	.export	ctrlsPageKeyPress
;-------------------------------------------------------------------------------
ctrlsPageKeyPress:
;-------------------------------------------------------------------------------
		STA	msgsdat0
		STX	msgsdat1

	.if	DEBUG_KEYSCAN
		LDA	#<lpanel_cnct_log
		STA	tempptr2
		LDA	#>lpanel_cnct_log
		STA	tempptr2 + 1

		JSR	ctrlsLogPanelGetNextLine

		LDAX	#text_dbg_key_pref
		JSR	strsAppendString

		LDA	msgsdat0
		JSR	strsAppendHex

		LDAX	#text_dbg_key_mid
		JSR	strsAppendString

		LDA	msgsdat1
		JSR	strsAppendHex

		LDA	#$00
		JSR	strsAppendChar

		JSR	ctrlsLogPanelUpdate
	.endif

;	msgsdat1 rather than TXA - X may not have survived the DEBUG_KEYSCAN
;	block above (strsAppendString/ctrlsLogPanelUpdate use X/Y freely)
		LDA	msgsdat1
		AND	#keyModSystem
		BNE	@findaccel

		LDA	msgsdat0

		CMP	#KEY_C64_HELP
		BEQ	@findaccel

		CMP	#KEY_C64_F1
		BCS	@fkey0

		JMP	@isdownctrl

@fkey0:
		CMP	#(KEY_C64_F14 + 1)
		BCC	@findaccel

@isdownctrl:
		LDA	downCtrl + 1
		BNE	@downctrl

		LDA	actvCtrl + 1
		BNE	@actvctrl

		RTS				;discard key press

@actvctrl:
		LDA	msgsdat0
		CMP	#KEY_C64_TAB
		BNE	@nottab

		LDA	#KEY_C64_CDOWN
		STA	msgsdat0
		JMP	@moveactv

@nottab:
		CMP	#KEY_C64_STAB
		BNE	@notstab

		LDA	#KEY_C64_CUP
		STA	msgsdat0
		JMP	@moveactv

@notstab:
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
;	Reached two ways: MEGA held (any key - msgsdat0 is a MEGA-modified
;	code and needs translating back to what accelchar stores), or an
;	F1-F9 key regardless of modifier (msgsdat0 already matches
;	accelchar's KEY_C64_F* values directly - leave it alone).
		LDA	msgsdat1
		AND	#keyModSystem
		BEQ	@noxlat

		LDA	msgsdat0
		JSR	keyMegaToBase
		STA	msgsdat0

@noxlat:
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
		
		LDY	#ELEMENT::state
		LDA	(panlptr0), Y
		AND	#(STATE_VISIBLE | STATE_ENABLED)
		CMP	#(STATE_VISIBLE | STATE_ENABLED)
		BNE	@nextpanl
		
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

;	Check that the control is both enabled and visible!

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		AND	#STATE_VISIBLE | STATE_ENABLED
		CMP	#STATE_VISIBLE | STATE_ENABLED
		BNE	@nextctrl
		
;	Check the control's accelerator
		
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
ctrlsSPanelDefKeyPress:
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
		
		LDA	#<button_det_confirm
		STA	elemptr0
		LDA	#>button_det_confirm
		STA	elemptr0 + 1
		
		JSR	ctrlsActivateCtrl
		
		RTS

@input:		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		STA	tempdat0

		LDA	msgsdat0
		CMP	#KEY_C64_CUP
		BNE	@tstdown

		LDY	tempdat0
		DEY
		TYA
		BPL	@updind
		
		LDA	#$0C
		JMP	@updind
		
@tstdown:
		CMP	#KEY_C64_CDOWN
		BNE	@exit

		LDY	tempdat0
		INY
		TYA
		CMP	#$0D
		BNE	@updind
		
		LDA	#$00
		
@updind:
		STA	tempdat0
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		LDX	#$00
		JSR	ctrlsSPanelPresSelect

		LDA	tempdat0
		LDY	#ELEMENT::tag
		STA	(elemptr0), Y

		LDY	#SCRSHTPANEL::lastind
		STA	(elemptr0), Y

		LDX	#$01
		JSR	ctrlsSPanelPresSelect

@exit:
		RTS
		

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
		
;	Include STATE_PREPARED on panel

		LDY	#ELEMENT::state
		LDA	(panlptr0), Y
		ORA	#STATE_PREPARED
		STA	(panlptr0), Y

;	Stub out prepare override functionality

;		LDY	#ELEMENT::prepare
;		LDA	(panlptr0), Y
;		STA	ctrlptr_a
;		INY
;		LDA	(panlptr0), Y
;		STA	ctrlptr_a + 1
;		
;		BEQ	@def
;		
;		JSR	ctrlsProxyA
;		JMP	@next
;		
;@def:
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
;		BEQ	@exit
		STA	ctrlvar_d
	
		BEQ	@skip0

		LDA	panlptr0
		STA	elemptr0
		LDA	panlptr0 + 1
		STA	elemptr0 + 1

		JSR	ctrlsControlInvalidate
		
@skip0:
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
		
;	Include STATE_PREPARED on element

		LDY	#ELEMENT::state
		LDA	(elemptr0), Y
		ORA	#STATE_PREPARED
		STA	(elemptr0), Y

;	Stub out prepare override functionality

;		LDY	#ELEMENT::prepare
;		LDA	(elemptr0), Y
;		STA	ctrlptr_a
;		INY
;		LDA	(elemptr0), Y
;		STA	ctrlptr_a + 1
;		
;		BEQ	@def
;		
;		JSR	ctrlsProxyA
;		JMP	@next
;		
;@def:
		LDA	ctrlvar_d
		BEQ	@next

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
		AND	#(STATE_VISIBLE | STATE_ENABLED)
		CMP	#(STATE_VISIBLE | STATE_ENABLED)
		BNE	@cont

;	Activate the first visible control
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
		
		JSR	clientDispInetHealth

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

		INY
		LDA	(elemptr0), Y
		ASL
		STA	tempvar_c		;Total count to loop	

;	Fetch offsy for indexing ctrlptr0
		LDY	#LOGPANEL::offsy
		LDA	(elemptr0), Y		
		ASL
		PHA

		LDY	#ELEMENT::posy
		LDA	(elemptr0), Y
		STA	tempvar_x

		PLA
		TAY
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


;-------------------------------------------------------------------------------
ctrlsSPanelPresSelect:
;	IN	.A	Score to select
;	IN	.X	Select or deselect
;-------------------------------------------------------------------------------
		STA	tempvar_a
		STX	tempvar_b

		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_c
		INY
		LDA	(elemptr0), Y
		STA	tempvar_d

		LDA	tempvar_a
		CMP	#$06
		BCS	@lower
		
		INC	tempvar_a
		INC	tempvar_c
		
		LDA	tempvar_d
		CLC
		ADC	tempvar_a
		STA	tempvar_d
		
		JMP	@cont0
		
@lower:
		SEC
		SBC	#$05
		STA	tempvar_a

		LDA	tempvar_c
		CLC
		ADC	#$0F
		STA	tempvar_c
		
		LDA	tempvar_d
		CLC
		ADC	tempvar_a
		STA	tempvar_d

@cont0:
		TAX
		LDA	screenRowsLo, X
		STA	tempptr0
		LDA	colourRowsHi, X
		STA	tempptr0 + 1
		
		LDA	tempvar_b
		BNE	@clrsel
		
		LDA	#CLR_FACE
		JMP	@cont1
		
@clrsel:
		LDA	#CLR_TEXT
		
@cont1:
		JSR	screenCtrlToLogClr
		
		LDY	tempvar_c
		STA	(tempptr0), Y
		
		LDX	tempvar_d
		LDA	screenRowsHi, X
		STA	tempptr0 + 1
		
		LDA	tempvar_b
		BNE	@chrsel
		
		LDA	#$A0
		JMP	@cont2
		
@chrsel:
		LDA	#$51
		
@cont2:
		LDY	tempvar_c
		STA	(tempptr0), Y
		
		RTS


;-------------------------------------------------------------------------------
ctrlsSPanelDefPresent:
;-------------------------------------------------------------------------------
		LDA	#CLR_TEXT
		JSR	ctrlsEraseBkg
		
		LDA	#SCRSHT_ALL
		STA	tempvar_t
		
ctrlsSPanelDefPresDirect:
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_r		;x
		INC	tempvar_r
		
		INY
		LDA	(elemptr0), Y
		STA	tempvar_s		;y
		INC	tempvar_s

		LDY	gameData + GAME::detslt
		LDA	game_slot_lo, Y
		STA	tempptr3
		LDA	#>gameData
		STA	tempptr3 + 1

		LDA	tempvar_t
		AND	#SCRSHT_LABELS
		BNE	@ulbls
		
		JMP	@utstscrs

@ulbls:
;	Do the "upper labels"

		LDY	#SCRSHTPANEL::lastind
		LDA	#$FF
		STA	(elemptr0), Y

		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		LDA	#$07
		STA	tempvar_c
		LDA	#$09
		STA	tempvar_d
		
		LDA	#CLR_FACE
		JSR	screenRectSetColour

		LDA	#$00
		STA	tempvar_h		;text index
				
		LDA	#CLR_FACE
		STA	tempdat0
		
@looplu:
		LDA	#$00
		STA	tempdat1
		STA	tempdat3
		STA	tempvar_d

		LDA	#$09
		STA	tempdat2

		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		INC	tempvar_s
		
		LDX	tempvar_h
		LDA	text_scrsht_upper, X
		STA	tempptr1
		INX
		LDA	text_scrsht_upper, X
		STA	tempptr1 + 1
		INX
		STX	tempvar_h
		
		JSR	ctrlsDrawTextDirect
		
		LDA	tempvar_h
		CMP	#$12
		BNE	@looplu
		
;	Do the "upper" scores	
@utstscrs:
		LDA	tempvar_t
		AND	#SCRSHT_SCORES
		BNE	@uscrs
		
		JMP	@ltstlbls

@uscrs:
;	Reset the "have preview score" flag
		LDY	#SCRSHTPANEL::hveprvw
		LDA	#$00
		STA	(elemptr0), Y

		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		CLC
		ADC	#$08
		STA	tempvar_r
		INY
		LDA	(elemptr0), Y
		STA	tempvar_s		;y
		INC	tempvar_s

		LDA	#$00
		STA	tempvar_h
		
@loopcu:
		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		LDA	#$05
		STA	tempvar_c
		LDA	#$01
		STA	tempvar_d
	
		LDA	tempvar_h
		AND	#$01
		BEQ	@cupaper

		LDA	#CLR_MONEY
		JMP	@contcu
		
@cupaper:
		LDA	#CLR_PAPER
		
@contcu:
		JSR	screenRectSetColour

		INC	tempvar_h
		INC	tempvar_s

		LDA	tempvar_h
		CMP	#$09
		BNE	@loopcu

		LDY	#ELEMENT::posy
		LDA	(elemptr0), Y
		STA	tempvar_s		;y
		INC	tempvar_s
		
		LDA	#$00
		STA	tempvar_h
	
@loopsu:
		LDA	#$00
		STA	tempdat1
;		STA	tempdat3
		STA	tempvar_d

		LDA	#$05
		STA	tempdat2

		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		INC	tempvar_s

		LDA	tempvar_h
		AND	#$01
		BNE	@sumoney
		
		LDA	#CLR_PAPER
		JMP	@contsu
		
@sumoney:
		LDA	#CLR_MONEY

@contsu:
		STA	tempvar_i

;	Get the score value and convert to string

		LDA	#<temp_num
		STA	tempptr0
		LDA	#>temp_num
		STA	tempptr0 + 1
		
		LDA	#$00
		STA	tempdat0

		LDAX	#text_scrsht_bscr
		
		JSR	strsAppendString
		
		LDA	#$00
		LDY	tempdat0
		STA	(tempptr0), Y
		STA	tempdat0

		LDA	tempvar_h
		CMP	#$06
		BCC	@convsu

		CMP	#$08
		BNE	@drawsu
		
		LDA	#$06
		
@convsu:
		TAY
		LDA	(tempptr3), Y
		BMI	@drawsu
		
		LDX	#$00
		
		JSR	strsAppendInteger
		
@drawsu:
		LDA	#<temp_num
		STA	tempptr1
		LDA	#>temp_num
		STA	tempptr1 + 1
		
		LDA	tempvar_i
		STA	tempdat0
		
		LDA	#$00
		STA	tempdat3

		JSR	ctrlsDrawTextDirect
		
		INC	tempvar_h
		
		LDA	tempvar_h
		CMP	#$09
		BNE	@loopsu		

;	Do the "lower labels"
@ltstlbls:
		LDA	tempvar_t
		AND	#SCRSHT_LABELS
		BNE	@llbls
		
		JMP	@ltstscrs

@llbls:
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		CLC
		ADC	#$0F
		STA	tempvar_r
		STA	tempvar_a
		INY
		LDA	(elemptr0), Y
		STA	tempvar_s		;y
		INC	tempvar_s

		LDA	tempvar_s
		STA	tempvar_b
		
		LDA	#$07
		STA	tempvar_c
		LDA	#$09
		STA	tempvar_d
		
		LDA	#CLR_FACE
		JSR	screenRectSetColour

		LDA	#$00
		STA	tempvar_h		;text index
				
		LDA	#CLR_FACE
		STA	tempdat0
		
@loopll:
		LDA	#$00
		STA	tempdat1
		STA	tempdat3
		STA	tempvar_d

		LDA	#$09
		STA	tempdat2
		
		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		INC	tempvar_s
		
		LDX	tempvar_h
		LDA	text_scrsht_lower, X
		STA	tempptr1
		INX
		LDA	text_scrsht_lower, X
		STA	tempptr1 + 1
		INX
		STX	tempvar_h
		
		JSR	ctrlsDrawTextDirect
		
		LDA	tempvar_h
		CMP	#$12
		BNE	@loopll

;	Do the "lower" scores		
@ltstscrs:
		LDA	tempvar_t
		AND	#SCRSHT_SCORES
		BNE	@lscrs
		
		JMP	@tstind

@lscrs:
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		CLC
		ADC	#$16
		STA	tempvar_r
		INY
		LDA	(elemptr0), Y
		STA	tempvar_s		;y
		INC	tempvar_s
	
		LDA	#$00
		STA	tempvar_h
		
@loopcl:
		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		LDA	#$05
		STA	tempvar_c
		LDA	#$01
		STA	tempvar_d
	
		LDA	tempvar_h
		AND	#$01
		BEQ	@clpaper

		LDA	#CLR_MONEY
		JMP	@contcl
		
@clpaper:
		LDA	#CLR_PAPER
		
@contcl:
		JSR	screenRectSetColour

		INC	tempvar_h
		INC	tempvar_s

		LDA	tempvar_h
		CMP	#$09
		BNE	@loopcl

		LDY	#ELEMENT::posy
		LDA	(elemptr0), Y
		STA	tempvar_s		;y
		INC	tempvar_s

		LDA	#$00
		STA	tempvar_h
	
@loopsl:
		LDA	#$00
		STA	tempdat1
		STA	tempvar_d

		LDA	#$05
		STA	tempdat2

		LDA	tempvar_r
		STA	tempvar_a
		LDA	tempvar_s
		STA	tempvar_b
		
		INC	tempvar_s

		LDA	tempvar_h
		AND	#$01
		BNE	@slmoney
		
		LDA	#CLR_PAPER
		JMP	@contsl
		
@slmoney:
		LDA	#CLR_MONEY

@contsl:
		STA	tempvar_i

;	Get the score value and convert to string

		LDA	#<temp_num
		STA	tempptr0
		LDA	#>temp_num
		STA	tempptr0 + 1
		
		LDA	#$00
		STA	tempdat0

		LDAX	#text_scrsht_bscr
		
		JSR	strsAppendString
		
		LDA	#$00
		LDY	tempdat0
		STA	(tempptr0), Y
		STA	tempdat0

		LDA	tempvar_h
		CMP	#$07
		LBCC	@convsl

		BEQ	@bonustally

;	tempvar_h can only be 7 or 8 here (loop runs 0-8) - row 8, the
;	bonus total
;	Sum whichever yahtzee bonus slots are claimed (each slot's own
;	stored value, not a hardcoded 100, in case of future house rules)
;	- leave blank if none claimed, same as an unscored category.
		LDA	#$00
		STA	tempvar_e
		STA	tempvar_f

		LDY	#SCRSHEET::ybnus1
		LDA	(tempptr3), Y
		BMI	@bt2

		CLC
		ADC	tempvar_e
		STA	tempvar_e
		LDA	#$00
		ADC	tempvar_f
		STA	tempvar_f

@bt2:
		LDY	#SCRSHEET::ybnus2
		LDA	(tempptr3), Y
		BMI	@bt3

		CLC
		ADC	tempvar_e
		STA	tempvar_e
		LDA	#$00
		ADC	tempvar_f
		STA	tempvar_f

@bt3:
		LDY	#SCRSHEET::ybnus3
		LDA	(tempptr3), Y
		BMI	@btdone

		CLC
		ADC	tempvar_e
		STA	tempvar_e
		LDA	#$00
		ADC	tempvar_f
		STA	tempvar_f

@btdone:
		LDA	tempvar_e
		ORA	tempvar_f
		BEQ	@drawsl

		LDA	tempvar_e
		LDX	tempvar_f
		JSR	strsAppendInteger

		JMP	@drawsl

@bonustally:
;	Row 7 - one "X " per claimed yahtzee bonus slot, mirroring the two
;	dedicated cells (marks + total) on the official scoresheet and on
;	the Windows client's grid.
		LDY	#SCRSHEET::ybnus1
		LDA	(tempptr3), Y
		BMI	@tly2

		LDA	#'X'
		JSR	strsAppendChar
		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar

@tly2:
		LDY	#SCRSHEET::ybnus2
		LDA	(tempptr3), Y
		BMI	@tly3

		LDA	#'X'
		JSR	strsAppendChar
		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar

@tly3:
		LDY	#SCRSHEET::ybnus3
		LDA	(tempptr3), Y
		BMI	@drawsl

		LDA	#'X'
		JSR	strsAppendChar
		LDA	#KEY_ASC_SPACE
		JSR	strsAppendChar

		JMP	@drawsl

@convsl:
		CLC
		ADC	#$07	
		TAY
		LDA	(tempptr3), Y
		BMI	@drawsl
		
		LDX	#$00
		
		JSR	strsAppendInteger
		
@drawsl:
		LDA	#<temp_num
		STA	tempptr1
		LDA	#>temp_num
		STA	tempptr1 + 1
		
		LDA	tempvar_i
		STA	tempdat0

		LDA	#$00
		STA	tempdat3
		
		JSR	ctrlsDrawTextDirect
		
		INC	tempvar_h
		
		LDA	tempvar_h
		CMP	#$09
		LBNE	@loopsl
		
;	Score select indicator
@tstind:
		LDY	#SCRSHTPANEL::lastind
		LDA	(elemptr0), Y
		BMI	@tstind0
		
		LDX	#$00
		JSR	ctrlsSPanelPresSelect

		LDY	#SCRSHTPANEL::lastind
		LDA	#$FF
		STA	(elemptr0), Y

@tstind0:
		LDA	tempvar_t
		AND	#SCRSHT_INDCTR
		BEQ	@exit

@ind:
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		BMI	@exit
	
		LDY	#SCRSHTPANEL::lastind
		STA	(elemptr0), Y
	
		LDX	#$01
		JSR	ctrlsSPanelPresSelect
				
@exit:
		RTS


;-------------------------------------------------------------------------------
ctrlsDieDefPresent:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_a		;x
		INY
		LDA	(elemptr0), Y
		STA	tempvar_b		;y
;		INY
;		LDA	(elemptr0), Y
		LDA	#$03
		STA	tempvar_c		;w
;		INY
;		LDA	(elemptr0), Y
		LDA	#$05
		STA	tempvar_d		;h
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		
		STA	tempvar_e		;tag
		
		LDA	#$00
		STA	tempvar_h		;output char cnt
		
@cont:
;	Set-up die face ptr
		LDY	#DIECTRL::value
		LDA	(elemptr0), Y
		ASL
		TAY
		LDA	dice, Y
		STA	tempptr2
		LDA	dice + 1, Y
		STA	tempptr2 + 1

;	We're going to assume these are always "control" colours (ie: reversed)

		LDA	#CLR_DIE
		JSR	screenCtrlToLogClr	
		STA	tempvar_f		;logical die colour
		
		LDA	#CLR_INSET
		JSR	screenCtrlToLogClr	
		STA	tempvar_g		;logical bkg colour
		
@looph:
		LDX	tempvar_b		;y pos
		LDA	screenRowsLo, X
		STA	tempptr0		;screen ptr
		STA	tempptr1		;colour ptr
		LDA	screenRowsHi, X
		STA	tempptr0 + 1
		LDA	colourRowsHi, X
		STA	tempptr1 + 1
	
		LDX	tempvar_c		;width
		LDY	tempvar_a		;x pos
		STY	tempvar_i
		DEX
		
@loopw:
		LDA	tempvar_e
		BEQ	@dodie
		
		LDY	tempvar_i
		LDA	#$A0			;blank char to screen ram
		STA	(tempptr0), Y		
		LDA	tempvar_g		;blank colour to colour ram
		STA	(tempptr1), Y
	
		INC	tempvar_h
		LDA	tempvar_h
		CMP	#$06
		BNE	@next
		
		LDA	#$00
		STA	tempvar_e
		STA	tempvar_h
		JMP	@next

@dodie:
		LDY	tempvar_h		;die char to screen ram
		LDA	(tempptr2), Y		
		LDY	tempvar_i
		STA	(tempptr0), Y		
		LDA	tempvar_f		;die colour to colour ram
		STA	(tempptr1), Y
	
		INC	tempvar_h
		LDA	tempvar_h
		CMP	#$09
		BNE	@next
		
		LDA	#$01
		STA	tempvar_e
		LDA	#$00
		STA	tempvar_h
		
@next:
		INC	tempvar_i	
		DEX
		BPL	@loopw
		
		INC	tempvar_b
		DEC	tempvar_d
		LDA	tempvar_d
		BNE	@looph
		
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

;	Stash where the text draw left off (tempvar_a/b are left as the
;	screen column/row right after the last drawn character) for
;	userIRQHandler's blinking cursor - only when this is actually the
;	current down-captured control (downCtrl), since STATE_DOWN alone
;	shouldn't change here - only ctrlsControlDefChanged/ctrlsDownCtrl/
;	ctrlsUnDownCtrl touch that. Cell's just been redrawn plain, so
;	start untouched (crsr_on=0) and let the IRQ handler flip it after
;	its own 6-frame delay, same as it would mid-blink.
		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_CAPTURECRSR
		BEQ	@exit

		LDA	elemptr0
		CMP	downCtrl
		BNE	@exit
		LDA	elemptr0 + 1
		CMP	downCtrl + 1
		BNE	@exit

		LDA	tempvar_a
		STA	crsr_col
		LDA	tempvar_b
		STA	crsr_row

		LDA	#$01
		STA	crsr_active

		LDA	#$00
		STA	crsr_on

		JSR	crsrBlinkDelay
		STA	crsr_dly

@exit:
		RTS

@normal:
		JMP 	ctrlsControlDefPresent


;-------------------------------------------------------------------------------
ctrlsControlDefPresent:
;-------------------------------------------------------------------------------
		LDY	#ELEMENT::state
		LDA	(elemptr0), Y

		AND	#STATE_VISIBLE
		BNE	@present
		
;		JMP	@exit
		RTS

@present:
		LDA	(elemptr0), Y
		AND	#STATE_DIRTY
		BNE	@tstenable

;		JMP	@exit
		RTS

@tstenable:
		LDA	(elemptr0), Y
		AND	#STATE_ENABLED
		BNE	@checkpick
		
		LDA	#CLR_SHADOW
		JMP	@draw
		
@checkpick:
		LDA	(elemptr0), Y
		AND	#STATE_PICK
		BEQ	@checkactv

		LDA	(elemptr0), Y		;Check that its not active
		AND	#STATE_ACTIVE
		BNE	@normal

@picked:
		LDY	#ELEMENT::colour	;Check its not already FOCUS
		LDA	(elemptr0), Y
		CMP	#CLR_FOCUS
		BNE	@pickednrm
		
		LDA	#CLR_FACE
		JMP	@draw

@pickednrm:
		LDA	#CLR_FOCUS
		JMP	@draw

@checkactv:
		LDA	(elemptr0), Y
		AND	#STATE_ACTIVE
		BNE	@picked			;Make it the same as picked
		
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
		
		LDY	#ELEMENT::options
		LDA	(elemptr0), Y
		AND	#OPT_AUTOCHECK
		BEQ	@exit
		
		LDY	#ELEMENT::tag
		LDA	(elemptr0), Y
		BEQ	@exit
		
		LDY	#ELEMENT::posx
		LDA	(elemptr0), Y
		STA	tempvar_a
		INY
		LDA	(elemptr0), Y
		STA	tempvar_b
		INY
		LDA	(elemptr0), Y
		TAX
		DEX
		DEX
		TXA
		STA	tempvar_c
		
		LDA	tempvar_a
		CLC
		ADC	tempvar_c
		STA	tempvar_c
		
		LDY	tempvar_b
		LDA	screenRowsLo, Y
		STA	tempptr0
		STA	tempptr1
		LDA	screenRowsHi, Y
		STA	tempptr0 + 1
		LDA	colourRowsHi, Y
		STA	tempptr1 + 1
		
		LDA	#CLR_TEXT
		JSR	screenCtrlToLogClr
		
		LDY	tempvar_c
		STA	(tempptr1), Y
		
		LDA	#$51
		STA	(tempptr0), Y

@exit:
		RTS


;===============================================================================


;===============================================================================
;	.segment 	"INIT"
;===============================================================================


;===============================================================================
;	.segment 	"ONCE"
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
	.export	readmsg0
	.export tempdat2
	.export	ctrlsLock
	
;===============================================================================
;	.segment	"BSS"
;===============================================================================



;	.import ip65_error
ip65_error:
    .byte $00

;;	.import eth_driver_name
eth_driver_name:
    .asciiz "MEGA65_XLAR54"

;;	.import eth_driver_io_base



;	.import eth_name
eth_name:
    .word $0000

;	.import cfg_ip
cfg_ip:
    .dword $00000000

;;	.import abort_key			;Don't include these from ip65
;;	.importzp abort_key_default		;These will be handled here
;;	.importzp abort_key_disable

;	.importzp eth_init_default
eth_init_default = $50
	
;;	.import drv_init


;	.import dns_hostname_is_dotted_quad
dns_hostname_is_dotted_quad:
    .byte $00

;	.import dns_ip
dns_ip:
    .dword $00000000

;	.import dns_resolve
dns_resolve:
    LDA LINEBUF
    STA STAGE_ARG_A_VAR
    STA count_len_loop + 1
    
    LDA LINEBUF + 1
    STA STAGE_ARG_X_VAR
    STA count_len_loop + 2

    lda #$00
    sta STAGE_ARG_Y_VAR

    LDX #$00
    STX LINE_LEN

count_len_loop:
    LDA LINEBUF, X
    BEQ @count_done

    INC LINE_LEN
    BRA count_len_loop

@count_done:
    LDA LINE_LEN
    STA STAGE_ARG_Z_VAR

    LDA STAGE_ARG_A_VAR
    LDX STAGE_ARG_X_VAR
    LDY STAGE_ARG_Y_VAR
    LDZ STAGE_ARG_Z_VAR

    JSR MIP_DNS_START_BUF

    CMP #1
    BNE @resolve_fail

    JMP DNS_WAIT_START_OK

@resolve_fail:
    SEC
    RTS


DNS_WAIT_START_OK:
    JSR RESET_DNS_TIMEOUT

@DNS_WAIT_LOOP:
    JSR MIP_STATUS_POLL

    JSR MIP_GET_DNS_STATE

    CMP #DNS_STATE_DONE
    BEQ @DNS_DONE

    CMP #DNS_STATE_FAIL
    BEQ @DNS_FAILED

    JSR DEC_TIMEOUT_FRAME
    BCC @DNS_WAIT_LOOP

@DNS_FAILED:
    SEC
    RTS

@DNS_DONE:
    JSR MIP_GET_DNS_RESULT

    STA dns_ip
    STX dns_ip + 1
    STY dns_ip + 2
    STZ dns_ip + 3

    CLC
    RTS


LINEBUF:
    .word $0000
LINE_LEN:
    .byte $00
OCTET_INDEX:
    .byte $00
CUR_VALUE:
    .byte $00
DIGIT_VALUE:            
    .byte 0
DIGIT_SEEN:
    .byte $00




;	.import dns_set_hostname
dns_set_hostname:
    STA PARSE_IP_LOOP + 1
    STA LINEBUF
    STX PARSE_IP_LOOP + 2
    STX LINEBUF + 1

    JSR PARSE_IP
    BCS @_resolve_as_host
    
    JSR SET_REMOTE_FROM_IPBUF

    LDA #$01
    STA dns_hostname_is_dotted_quad

    CLC
    RTS

@_resolve_as_host:
    LDA #$00
    STA dns_hostname_is_dotted_quad

    CLC


    RTS


SET_REMOTE_FROM_IPBUF:
    LDA dns_ip
    LDX dns_ip + 1
    LDY dns_ip + 2
    LDZ dns_ip + 3

    JSR MIP_SET_REMOTE_IP
    
    CLC
    RTS


PARSE_IP:
    LDA #0
    STA dns_ip + 0
    STA dns_ip + 1
    STA dns_ip + 2
    STA dns_ip + 3
    STA OCTET_INDEX
    STA CUR_VALUE
    STA DIGIT_SEEN
    LDX #0    

PARSE_IP_LOOP:
    LDA LINEBUF, X
    BEQ @PARSE_IP_END
 
    CMP #'.'
    BEQ @PARSE_IP_DOT
 
    CMP #'0'
    BCC @PARSE_IP_FAIL
 
    CMP #'9'+1
    BCS @PARSE_IP_FAIL
 
    SEC
    SBC #'0'
    STA DIGIT_VALUE
 
    JSR CUR_MUL10_ADD_DIGIT
    BCS @PARSE_IP_FAIL
 
    LDA #1
    STA DIGIT_SEEN
    INX
 
    BRA PARSE_IP_LOOP

@PARSE_IP_DOT:
    LDA DIGIT_SEEN
    BEQ @PARSE_IP_FAIL

    LDY OCTET_INDEX
    CPY #3
    BCS @PARSE_IP_FAIL

    LDA CUR_VALUE
    STA dns_ip, Y
    INC OCTET_INDEX
    LDA #0
    STA CUR_VALUE
    STA DIGIT_SEEN
    INX
    BRA PARSE_IP_LOOP

@PARSE_IP_END:
    LDA DIGIT_SEEN
    BEQ @PARSE_IP_FAIL

    LDA OCTET_INDEX
    CMP #3
    BNE @PARSE_IP_FAIL

    LDY OCTET_INDEX
    LDA CUR_VALUE
    STA dns_ip,y
    CLC
    RTS

@PARSE_IP_FAIL:
    SEC
    RTS


CUR_MUL10_ADD_DIGIT:
    LDA CUR_VALUE
    ASL
    BCS @_cur_fail
    STA ETH_TEMP_A
    ASL
    BCS @_cur_fail
    ASL
    BCS @_cur_fail
    CLC
    ADC ETH_TEMP_A
    BCS @_cur_fail
    CLC
    ADC DIGIT_VALUE
    BCS @_cur_fail
    STA CUR_VALUE
    CLC
    RTS

@_cur_fail:
    SEC
    RTS



;	.import ip65_init
ip65_init:

    LDA #0
    STA ARG_A_VAR
    STA ARG_X_VAR
    STA ARG_Y_VAR

    JSR MIP_INIT
    CLC

    RTS


;	.import ip65_process
ip65_process:
    LDA #$00
    STA TERMINAL_EVENT

    JSR TERMINAL_POLL_STATUS

    LDA TERMINAL_EVENT
    BNE @TERMINAL_HANDLE_EVENT

    LDA #$00
    STA tcp_inbound_data_length
    STA tcp_inbound_data_length + 1

    ;JSR RECV_BLOCK

    JSR  RECV_DATA

;	Diagnostic: log how many bytes THIS poll's RECV_DATA actually
;	received, whenever it received anything.
    .if	DEBUG_RXSIZE
    LDA tcp_inbound_data_length
    ORA tcp_inbound_data_length + 1
    BEQ @norx

    LDA #<lpanel_cnct_log
    STA tempptr2
    LDA #>lpanel_cnct_log
    STA tempptr2 + 1

    JSR ctrlsLogPanelGetNextLine

    LDAX #text_dbg_rx_pref
    JSR strsAppendString

    LDA tcp_inbound_data_length + 1
    JSR strsAppendHex
    LDA tcp_inbound_data_length
    JSR strsAppendHex

    LDA #$00
    JSR strsAppendChar

    JSR ctrlsLogPanelUpdate

@norx:
    .endif
;	Was checking the low byte alone, which was harmless while
;	tcp_inbound_data_length could never actually exceed 255 (the old,
;	buggy RECV_DATA wrapped there anyway). Now that bursts can
;	genuinely exceed that, a burst landing on an exact multiple of
;	256 would read as "nothing received" here and inet_callback would
;	never run - silently losing data already drained from the ring
;	buffer. ORA both bytes together so either one being nonzero counts.
    LDA tcp_inbound_data_length
    ORA tcp_inbound_data_length + 1

    BNE @TERMINAL_HANDLE_RX

    RTS

@TERMINAL_HANDLE_RX:
    JSR inet_callback
    RTS

@TERMINAL_HANDLE_EVENT:
    JSR inetRecordDiscEvent

    LDA #$01
    STA connection_close_requested
    STA connection_closed

    RTS

TERMINAL_POLL_STATUS:
    JSR MIP_STATUS_POLL
    STX inet_last_rtt
    STY inet_last_retries
    CMP #0
    BEQ @_terminal_poll_done
    ORA TERMINAL_EVENT
    STA TERMINAL_EVENT
    SEC
    RTS
@_terminal_poll_done:
    CLC
    RTS


RECV_DATA:
;	tcp_inbound_data_length is a 16-bit counter, but the old version
;	reloaded Y straight from its low byte each time and INC'd only
;	that byte - past 255 bytes in one burst, Y silently wrapped back
;	to 0 and the loop started overwriting the start of the buffer
;	(including the first message's own length byte) with the tail of
;	the burst, corrupting everything already received. Y now stays 0
;	for the whole loop; inetread itself is walked forward one byte at
;	a time with INW instead, so there's no 255-byte addressing limit.
		LDAX 	tcp_inbound_data_ptr
		STAX 	inetread

    LDA #$00
    STA tcp_inbound_data_length
    STA tcp_inbound_data_length + 1

    LDY #$00
@loop:
;	tcp_inbound_data_ptr points at RX_BLOCK_BUF, a fixed 256-byte
;	buffer - stop once it's full rather than walking inetread past
;	its end into whatever memory follows. Anything not drained here
;	stays safely queued in the ring buffer (MIP_ML_RECV_BYTE only
;	consumes what it actually returns) for the next poll to pick up;
;	inet_callback already handles a message continuing across polls.
    LDA tcp_inbound_data_length + 1
    BNE @done

    JSR MIP_ML_RECV_BYTE
    CPX #$01
    BNE @done

    STA (inetread), Y

    INW inetread

;	tcp_inbound_data_length isn't zero-page, and INW only supports
;	zero-page operands on the 4510, so this stays a manual carry-
;	checked increment.
    INC tcp_inbound_data_length
    BNE @loop
    INC tcp_inbound_data_length + 1

    BRA @loop

@done:
    RTS


;RECV_BLOCK:
;    LDA #<RX_BLOCK_BUF
;    STA STAGE_ARG_A_VAR
;    LDA #>RX_BLOCK_BUF
;    STA STAGE_ARG_X_VAR
;    LDA #0
;    STA STAGE_ARG_Y_VAR
;    LDA #235
;    STA STAGE_ARG_Z_VAR
;    
;    LDA STAGE_ARG_A_VAR
;    LDX STAGE_ARG_X_VAR
;    LDY STAGE_ARG_Y_VAR
;    LDZ STAGE_ARG_Z_VAR
;    
;    JSR MIP_ML_RECV_BLOCK
;    
;    STA tcp_inbound_data_length
;    RTS

TERMINAL_EVENT:
    .byte $00

; Last measured send-to-ack round trip, in frame-ticks (~20ms PAL each),
; returned via X from MIP_STATUS_POLL. Drives clientDispInetHealth.
inet_last_rtt:
    .byte $00

; Retries the most recently completed segment actually needed (0 = acked
; clean), returned via Y from MIP_STATUS_POLL. Diagnostic only for now.
inet_last_retries:
    .byte $00

; Last values written to the connect log by clientDispInetHealth's
; temporary diagnostic - lets it only log on a real change.
dbg_last_rtt_logged:
    .byte $00
dbg_last_retries_logged:
    .byte $00

; Non-zero (bit 7 set) on an NTSC machine, 0 on PAL. Read once at startup
; from $D06F; ~16.7ms/tick on NTSC vs ~20ms/tick on PAL.
sys_ntsc_flag:
    .byte $00

DHCP_STATE_BOUND    = $04
DHCP_STATE_FAILED   = $7f
DNS_STATE_DONE      = $02
DNS_STATE_FAIL      = $03

DHCP_TIMEOUT_FRAMES = 3600
DNS_TIMEOUT_FRAMES  = 3600
;	mega-ip's own FIN retry budget (TCP_TX_MAX_RETRIES x TCP_TX_RETRY_TICKS)
;	force-closes locally within ~1.2s worst case even with zero replies,
;	so 300 frames (~6s) is a generous safety margin above that, not the
;	thing actually expected to fire in normal operation.
DISCONNECT_TIMEOUT_FRAMES = 300

;	Same budget as DHCP/DNS. tcp_connect's own wait loop needs this -
;	it never used to reset the shared timeout itself, just inherited
;	whatever DHCP/DNS (or, now, inetDisconnect) left behind. That was
;	fine by accident on a cold boot (DHCP/DNS leave a huge budget
;	behind) but after a disconnect burns most of its own 300-frame
;	budget, tcp_connect would inherit an already-exhausted countdown
;	and fail almost instantly on the very next connect attempt.
CONNECT_TIMEOUT_FRAMES = 3600

ARG_A_VAR:              
    .byte 0
ARG_X_VAR:              
    .byte 0
ARG_Y_VAR:              
    .byte 0
STAGE_ARG_A_VAR:        
    .byte 0
STAGE_ARG_X_VAR:        
    .byte 0
STAGE_ARG_Y_VAR:        
    .byte 0
STAGE_ARG_Z_VAR:        
    .byte 0

LAST_DHCP_STATE:
    .byte $00
TIMEOUT_LO:             
    .byte 0
TIMEOUT_HI:             
    .byte 0
TIMEOUT_FRAME_LAST:     
    .byte 0

PORT_LO:
    .byte 0
PORT_HI:
    .byte 0

ETH_TEMP_A:
    .byte $00


;	.import dhcp_init
dhcp_init:
    LDA #0
    STA ARG_A_VAR
    STA ARG_X_VAR
    STA ARG_Y_VAR

    JSR MIP_DHCP_START

    LDA #$FF
    STA LAST_DHCP_STATE
    JSR RESET_DHCP_TIMEOUT

@DHCP_LOOP:
    JSR MIP_STATUS_POLL

    JSR MIP_DHCP_POLL
    STA ETH_TEMP_A

    CMP LAST_DHCP_STATE
    BEQ @DHCP_STATE_DONE

    STA LAST_DHCP_STATE
    JSR RESET_DHCP_TIMEOUT

@DHCP_STATE_DONE:
    LDA ETH_TEMP_A
    CMP #DHCP_STATE_BOUND
    BEQ @DHCP_SUCCEED

    CMP #DHCP_STATE_FAILED
    BEQ @DHCP_FAILED

    JSR DEC_TIMEOUT_FRAME
    BCC @DHCP_LOOP

@DHCP_FAILED:
    SEC
    RTS

@DHCP_SUCCEED:
    JSR MIP_FORCE_CLOSE
    ;JSR CLEAR_NETWORK_STATUS_AREA

    LDA #0
    STA STAGE_ARG_A_VAR
    STA STAGE_ARG_X_VAR
    STA STAGE_ARG_Y_VAR
    STA STAGE_ARG_Z_VAR
    JSR MIP_GET_LOCAL_IP

    STA cfg_ip + 0
    STX cfg_ip + 1
    STY cfg_ip + 2
    TZA
    STA cfg_ip + 3

    CLC
    RTS


RESET_DHCP_TIMEOUT:
    LDA #<DHCP_TIMEOUT_FRAMES
    STA TIMEOUT_LO
    LDA #>DHCP_TIMEOUT_FRAMES
    STA TIMEOUT_HI
    BRA RESET_TIMEOUT_FRAME

RESET_DNS_TIMEOUT:
    LDA #<DNS_TIMEOUT_FRAMES
    STA TIMEOUT_LO
    LDA #>DNS_TIMEOUT_FRAMES
    STA TIMEOUT_HI
    BRA RESET_TIMEOUT_FRAME

RESET_TIMEOUT_FRAME:
    LDA FRAMECOUNT
    STA TIMEOUT_FRAME_LAST
    RTS

DEC_TIMEOUT_FRAME:
    LDA FRAMECOUNT
    CMP TIMEOUT_FRAME_LAST
    BEQ @_timeout_frame_same
    
    STA TIMEOUT_FRAME_LAST
    BRA @DEC_TIMEOUT

@_timeout_frame_same:
    CLC
    RTS

@DEC_TIMEOUT:
    LDA TIMEOUT_LO
    BNE @_dec_lo
    
    LDA TIMEOUT_HI
    BEQ @_timeout_done
    
    DEC TIMEOUT_HI

@_dec_lo:
    DEC TIMEOUT_LO
    CLC
    RTS

@_timeout_done:
    SEC
    RTS



;	.import tcp_callback
tcp_callback:
    .word $0000


;	.import tcp_close
tcp_close:
;	Was a no-op - clicking Disconnect only reset local client state,
;	never told the server anything, so the connection sat fully
;	ESTABLISHED on the wire until the server's own (very slow) TCP
;	timeout eventually noticed and released it. Send a real FIN so the
;	server sees the close immediately.
    JSR MIP_DISCONNECT
    RTS


CONN_CONNECTED      = %00000001
CONN_FAILED         = %00000010

;	mirror eth.asm's EV_* bits in TCP_EVENT_FLAG - not otherwise exposed
;	to test.s, so re-declared here. Also used by inetRecordDiscEvent
;	below to decode discEventFlags for clientOutputInetError.
EV_RST              = %00000001	;hard reset seen (peer RST)
EV_PEER_FIN         = %00000010	;peer initiated close (we saw FIN)
EV_LOCAL_CLOSE       = %00000100	;our FIN exchange completed
EV_TIMEWAIT_DONE    = %00001000	;TIME_WAIT expired - CLOSED
EV_CONNECT_FAIL     = %00010000	;SYN handshake failed/timeout
EV_TX_TIMEOUT       = %00100000	;data retransmit retries exhausted
EV_BAD_SYNACK       = %01000000	;SYN-SENT: SYN+ACK arrived but its
					;ACK didn't match - dropped, not a
					;true no-reply

;	non-zero after a failed tcp_connect if the failure was an active
;	peer RST (connection refused) rather than a plain SYN timeout.
TCP_CONNECT_FAIL_WAS_RST:
    .byte $00

;	non-zero after a failed tcp_connect if a SYN+ACK actually arrived
;	but was silently dropped because its ACK didn't match what we
;	expected - a real reply that got rejected, not true silence.
TCP_CONNECT_FAIL_BAD_SYNACK:
    .byte $00


;	.import tcp_connect
tcp_connect:

;  huh?

    STA STAGE_ARG_X_VAR
    STA PORT_HI
    STX STAGE_ARG_A_VAR
    STX PORT_LO

    LDA STAGE_ARG_A_VAR
    LDX STAGE_ARG_X_VAR

    JSR MIP_SET_REMOTE_PORT
    
    LDA PORT_HI
    LDX PORT_LO

    LDY #$00
    LDZ #$00

    JSR MIP_SET_LOCAL_PORT

    LDA #<CONNECT_TIMEOUT_FRAMES
    STA TIMEOUT_LO
    LDA #>CONNECT_TIMEOUT_FRAMES
    STA TIMEOUT_HI
    JSR RESET_TIMEOUT_FRAME

;	Accumulate TCP_EVENT_FLAG bits (via TERMINAL_POLL_STATUS, same
;	sticky-OR pattern inetDisconnect uses) across the whole attempt, so
;	that if it fails we can tell an active refusal (peer RST, EV_RST)
;	apart from nobody answering the SYN at all (plain timeout) - the
;	two have different causes and previously looked identical.
    LDA #$00
    STA TERMINAL_EVENT

    JSR MIP_CONNECT_START

@CONNECT_LOOP:
    JSR TERMINAL_POLL_STATUS

    JSR MIP_CONNECT_POLL

    STA ETH_TEMP_A
    LDA ETH_TEMP_A

    AND #CONN_CONNECTED
    BNE @CONNECTED

    LDA ETH_TEMP_A
    AND #CONN_FAILED
    BNE @CONNECT_FAILED

    JSR DEC_TIMEOUT_FRAME
    BCC @CONNECT_LOOP

@CONNECT_FAILED:
    LDA TERMINAL_EVENT
    AND #EV_RST
    STA TCP_CONNECT_FAIL_WAS_RST
    LDA TERMINAL_EVENT
    AND #EV_BAD_SYNACK
    STA TCP_CONNECT_FAIL_BAD_SYNACK
    SEC
    RTS

@CONNECTED:
    CLC
    RTS

;	.import tcp_connect_ip
tcp_connect_ip:
    .dword  $00000000
    
;	.import tcp_inbound_data_ptr
tcp_inbound_data_ptr:
    .word RX_BLOCK_BUF

;RX_BLOCK_COUNT:
;    .byte 0

;	.import tcp_inbound_data_length
tcp_inbound_data_length:
    .word $0000

;	.import tcp_send
tcp_send:
    ;RTS

    LDY tcp_send_data_len
    LDZ #0

    JSR MIP_ML_SEND_BYTE

    LDA #$00
    STA TERMINAL_EVENT

    JSR TERMINAL_POLL_STATUS

    LDA TERMINAL_EVENT
    BNE @TERMINAL_HANDLE_EVENT

    RTS

@TERMINAL_HANDLE_EVENT:
    JSR inetRecordDiscEvent

    LDA #$01
    STA connection_close_requested
    STA connection_closed

    RTS

;	.import tcp_send_data_len
tcp_send_data_len:
    .word $0000

;	.import tcp_send_keep_alive
tcp_send_keep_alive:
    LDA #$00
    STA TERMINAL_EVENT

    JSR TERMINAL_POLL_STATUS

    LDA TERMINAL_EVENT
    BNE @TERMINAL_HANDLE_EVENT

    RTS

@TERMINAL_HANDLE_EVENT:
    JSR inetRecordDiscEvent

    LDA #$01
    STA connection_close_requested
    STA connection_closed

    RTS

;	.import timer_read
timer_read:
    RTS

;	.export	check_for_abort_key		;Required for ip65 callback
	
;	.import	tcp_loop_count
tcp_loop_count:
    .byte $00

;	.import	tcp_packet_sent_count
tcp_packet_sent_count:
    .byte $00





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
tempvar_g:
			.res 	1
tempvar_h:
			.res 	1
tempvar_i:
			.res 	1
			
tempvar_q:
			.res	1
tempvar_r:
			.res	1
tempvar_s:
			.res 	1
tempvar_t:
			.res	1

tempvar_x:
			.res	1
tempvar_y:
			.res	1
tempvar_z:
			.res	1

;	dmaFillRow/dmaCopyRow's parameters (see below) - a dedicated set
;	rather than reusing tempptr/tempvar since these are called from
;	inside other routines' own tempvar-heavy loops (ctrlsEraseBkg,
;	screenRectSetColour, strsAppendMessage).
dmaSrc:
			.res	2
dmaDst:
			.res	2
dmaDstBank:
			.res	1
dmaCnt:
			.res	1

uiflshcnt:
			.res 	1
uiflshdly:
			.res	1

room_log_notify_cnt:
			.res	1

;	Blinking text-entry cursor (OPT_CAPTURECRSR) - crsr_col/crsr_row
;	are the screen position userIRQHandler XORs $80 (reverse video)
;	into every crsrBlinkDelay frames (see there); crsr_on is the
;	toggle (0=normal, 1=reversed) so ctrlsUnDownCtrl knows whether
;	one more XOR is needed to restore the cell on release;
;	crsr_active gates all of it off when no captured control wants a
;	cursor.
crsr_col:
			.res	1
crsr_row:
			.res	1
crsr_active:
			.res	1
crsr_on:
			.res	1
crsr_dly:
			.res	1

ctrlvar_a:
			.res	1
ctrlvar_b:
			.res	1
ctrlvar_c:
			.res	1
ctrlvar_d:
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

currpgtag:
			.res	1

actvctrlp:
			.res	1
actvctrlc:
			.res	1

pageNext:
			.res	2
pageBack:
			.res 	2
			
temp_num:
			.res 	6
			
game_round:
			.res	6

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

;	Snapshot of TERMINAL_EVENT (TCP_EVENT_FLAG's sticky-OR'd EV_* bits,
;	see above) taken by inetRecordDiscEvent right before connection_closed
;	is set, so clientOutputInetError can show *why* the connection
;	ended instead of just that it did. $00 means connection_closed was
;	set via inet_callback's inbound-EOF sentinel instead (no
;	TCP_EVENT_FLAG bits involved there).
discEventFlags:
			.res	1

sendmsgscnt:
			.res 	1

readmsgbuflen:
			.res	2
readmsgidx:
			.res	1
readbufidx:
			.res	1
readmsglen:
			.res	1

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


room_haveblank:
			.res 	1
room_lastuser:
			.res	11


msgs_change_idx:
			.res	1

msgs_dirty_idx:
			.res	1


;===============================================================================


;===============================================================================
;	.segment	"RODATA"
;===============================================================================
game_slot_lo:
			.byte	<(gameData)
			.byte	<(gameData + .sizeof(GAMESLOT))
			.byte	<(gameData + (.sizeof(GAMESLOT) * 2))
			.byte	<(gameData + (.sizeof(GAMESLOT) * 3))
			.byte	<(gameData + (.sizeof(GAMESLOT) * 4))
			.byte	<(gameData + (.sizeof(GAMESLOT) * 5))

button_ovrvw_dets:
			.word	button_ovrvw_1p_det
			.word	button_ovrvw_2p_det
			.word	button_ovrvw_3p_det
			.word	button_ovrvw_4p_det
			.word	button_ovrvw_5p_det
			.word	button_ovrvw_6p_det

label_ovrvw_names:
			.word	label_ovrvw_1p_name
			.word	label_ovrvw_2p_name
			.word	label_ovrvw_3p_name
			.word	label_ovrvw_4p_name
			.word	label_ovrvw_5p_name
			.word	label_ovrvw_6p_name
			
label_ovrvw_stats:
			.word	label_ovrvw_1p_stat
			.word	label_ovrvw_2p_stat
			.word	label_ovrvw_3p_stat
			.word	label_ovrvw_4p_stat
			.word	label_ovrvw_5p_stat
			.word	label_ovrvw_6p_stat

label_ovrvw_statbufs:
			.word	label_ovrvw_1p_stat_buf
			.word	label_ovrvw_2p_stat_buf
			.word	label_ovrvw_3p_stat_buf
			.word	label_ovrvw_4p_stat_buf
			.word	label_ovrvw_5p_stat_buf
			.word	label_ovrvw_6p_stat_buf

label_ovrvw_scores:
			.word	label_ovrvw_1p_score
			.word	label_ovrvw_2p_score
			.word	label_ovrvw_3p_score
			.word	label_ovrvw_4p_score
			.word	label_ovrvw_5p_score
			.word	label_ovrvw_6p_score
			
label_ovrvw_scorebufs:
			.word	label_ovrvw_1p_score_buf
			.word	label_ovrvw_2p_score_buf
			.word	label_ovrvw_3p_score_buf
			.word	label_ovrvw_4p_score_buf
			.word	label_ovrvw_5p_score_buf
			.word	label_ovrvw_6p_score_buf
			
die_det_dice:
			.word	die_det_0
			.word	die_det_1
			.word	die_det_2
			.word	die_det_3
			.word	die_det_4

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

;	DMA bypasses the CPU's $D800 colour-RAM I/O alias entirely and
;	needs colour RAM's real physical address instead - $01F800
;	(bank $01, addr word high byte per row below). Low byte still
;	matches screenRowsLo row for row, same as colourRowsHi above,
;	since $F800's low byte is $00 just like $0400's and $D800's.
colourRowsHiPhys:
			.byte	>$F800, >$F828, >$F850, >$F878, >$F8A0
			.byte	>$F8C8, >$F8F0, >$F918, >$F940, >$F968
			.byte	>$F990, >$F9B8, >$F9E0, >$FA08, >$FA30
			.byte	>$FA58, >$FA80, >$FAA8, >$FAD0, >$FAF8
			.byte	>$FB20, >$FB48, >$FB70, >$FB98, >$FBC0

screenASCIIXLAT:
	.byte	KEY_ASC_BSLASH, KEY_ASC_CARET, KEY_ASC_USCORE, KEY_ASC_BQUOTE
	.byte	KEY_ASC_OCRLYB, KEY_ASC_PIPE, KEY_ASC_CCRLYB, KEY_ASC_TILDE, $00
screenASCIIXLATSub:
	.byte	$4D, $71, $64, $4A ,$55, $5D, $49, $45, $00


die_flags:
			.byte	DIE_0
			.byte	DIE_1
			.byte	DIE_2
			.byte	DIE_3
			.byte	DIE_4
			.byte	DIE_5


text_token_null:
			.asciiz	""

text_ident_vernam:
			.asciiz	"alpha"
text_ident_pltfrm:
			.asciiz	"M65"
text_ident_verlbl:
			.asciiz	"0.00.91B"

text_init_text0:
			.asciiz	"INITIALISING..."

text_splsh_title:
			.asciiz	"M3WP YAHTZEE!"
text_splsh_text0:
			.asciiz	"WRITTEN BY:  DANIEL ENGLAND"
text_splsh_text1:
			.asciiz	"FOR ECCLESTIAL SOLUTIONS"
text_splsh_text2:
			.asciiz	"VERSION:  0.00.91B"
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
text_main_prefs:
			.asciiz	"F9-PREFS"
			
text_main_back:
			.asciiz	"[F8 <-BAK]"
text_main_next:
			.asciiz	"[F7 NXT->]"
			
			
text_page_connect:
			.asciiz	"CONNECT"
text_page_config:
			.asciiz	"CONFIGURE"
text_config_mouse:
			.asciiz	"MOUSE SETTINGS"
text_config_mouse_slow:
			.asciiz	"[SLOW          ]"
text_config_mouse_medium:
			.asciiz	"[MEDIUM        ]"
text_config_mouse_fast:
			.asciiz	"[FAST          ]"
text_config_theme:
			.asciiz	"THEME SETTINGS"
text_config_theme_prv:
			.asciiz	"[< PRV]"
text_config_theme_nxt:
			.asciiz	"[NXT >]"
text_config_interface:
			.asciiz	"INTERFACE"
text_config_flashchat:
			.asciiz	"[FLASH HIDDN CHAT ]"
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
			
text_room_ujoins:
			.asciiz	" JOINS "
text_play_ujoins:
			.asciiz	" JOINS"
text_room_uparts:
			.asciiz	" PARTS "
text_room_usays:
			.asciiz	" SAYS"
text_room_uwhisp:
			.asciiz	" WHISPERS"

text_page_play:
			.asciiz	"GAME"
			
text_play_game:
			.asciiz	"GAME:"


text_page_ovrvw:
			.asciiz	"OVERVIEW"

text_ovrvw_cntrl:
			.asciiz	"GAME CONTROL:"
text_ovrvw_ready:
			.asciiz	"[READY   ]"
text_ovrvw_ntrdy:
			.asciiz	"[NOT RDY ]"
text_ovrvw_rl4frst:
			.asciiz	"[RL4FIRST]"
text_ovrvw_play:
			.asciiz	"[IN GAME ]"
			
text_ovrvw_1p:
			.asciiz	"[1P]"
text_ovrvw_2p:
			.asciiz	"[2P]"
text_ovrvw_3p:
			.asciiz	"[3P]"
text_ovrvw_4p:
			.asciiz	"[4P]"
text_ovrvw_5p:
			.asciiz	"[5P]"
text_ovrvw_6p:
			.asciiz	"[6P]"
text_ovrvw_round:
			.asciiz	"GAME ROUND  :"
			
text_ovrvw_wait:
			.asciiz	"WAITING..."
			
text_ovrvw_finish:
			.asciiz	"FINISHED!"

text_slotsts:
			.word	text_slotst_none
			.word	text_slotst_idle
			.word	text_slotst_ready
			.word	text_slotst_prep
			.word	text_slotst_wait
			.word	text_slotst_play
			.word	text_slotst_fin
			.word	text_slotst_win
			
text_slotst_none:
			.asciiz	"AVAIL..."
text_slotst_idle:
			.asciiz	"NOT RDY"
text_slotst_ready:
			.asciiz	"WAIT RDY"
text_slotst_prep:
			.asciiz	"WAIT4FST"
text_slotst_wait:
			.asciiz	"WAITING"
text_slotst_play:
			.asciiz	"PLAYING"
text_slotst_fin:
			.asciiz	"DONE"
text_slotst_win:
			.asciiz	"WINNER!"
			
text_slotst_waitf:
			.asciiz	"FSTRL "


text_page_detail:
			.asciiz	"DETAILS"
			
text_det_flwactv:
			.asciiz	"[FL ACTV ]"
			
text_det_roll0:
			.asciiz	"[ROLL 1/3]"
text_det_roll1:
			.asciiz	"[ROLL 2/3]"
text_det_roll2:
			.asciiz	"[ROLL 3/3]"
text_det_roll3:
			.asciiz	"[ROLL FIN]"
			
text_det_rolls:
			.word	text_det_roll0
			.word	text_det_roll1
			.word	text_det_roll2
			.word	text_det_roll3

text_det_keep1:
			.asciiz	"[1]"

text_det_keep2:
			.asciiz	"[2]"

text_det_keep3:
			.asciiz	"[3]"

text_det_keep4:
			.asciiz	"[4]"

text_det_keep5:
			.asciiz	"[5]"

text_det_your:
			.asciiz	"YOUR SCORE:"

text_det_their:
			.asciiz	"THIS SCORE:"
			
text_det_select:
			.asciiz	"[SELECT  ]"
			
text_det_confirm:
			.asciiz	"[CONFIRM ]"

die_0:
			.byte	$A0, $A0, $A0
			.byte	$A0, $BF, $A0
			.byte	$A0, $A0, $A0
die_1:
			.byte	$A0, $A0, $A0
			.byte	$A0, $D1, $A0
			.byte	$A0, $A0, $A0
die_2:
			.byte	$D1, $A0, $A0
			.byte	$A0, $A0, $A0
			.byte	$A0, $A0, $D1
die_3:
			.byte	$D1, $A0, $A0
			.byte	$A0, $D1, $A0
			.byte	$A0, $A0, $D1
die_4:
			.byte	$D1, $A0, $D1
			.byte	$A0, $A0, $A0
			.byte	$D1, $A0, $D1
die_5:
			.byte	$D1, $A0, $D1
			.byte	$A0, $D1, $A0
			.byte	$D1, $A0, $D1
die_6:
			.byte	$D1, $A0, $D1
			.byte	$D1, $A0, $D1
			.byte	$D1, $A0, $D1

dice:
			.word	die_0
			.word	die_1
			.word	die_2
			.word	die_3
			.word	die_4
			.word	die_5
			.word	die_6

text_scrsht_1s:
			.asciiz	" 1's   "
text_scrsht_2s:
			.asciiz	" 2's   "
text_scrsht_3s:
			.asciiz	" 3's   "
text_scrsht_4s:
			.asciiz	" 4's   "
text_scrsht_5s:
			.asciiz	" 5's   "
text_scrsht_6s:
			.asciiz	" 6's   "
text_scrsht_blank:
			.asciiz "       "
text_scrsht_ubnus:
			.asciiz	" U BNUS"
			
text_scrsht_upper:
			.word	text_scrsht_1s
			.word	text_scrsht_2s
			.word	text_scrsht_3s
			.word	text_scrsht_4s
			.word	text_scrsht_5s
			.word	text_scrsht_6s
			.word	text_scrsht_blank
			.word	text_scrsht_blank
			.word	text_scrsht_ubnus
			
text_scrsht_3kind:
			.asciiz	" 3 KIND"
text_scrsht_4kind:
			.asciiz	" 4 KIND"
text_scrsht_flhse:
			.asciiz	" FL HSE"
text_scrsht_smstr:
			.asciiz	" SM STR"
text_scrsht_lgstr:
			.asciiz	" LG STR"
text_scrsht_yhtze:
			.asciiz	" YHTZEE"
text_scrsht_chnce:
			.asciiz	" CHANCE"
text_scrsht_ybnus:
			.asciiz	" Y BNUS"
text_scrsht_lbnus:
			.asciiz	" L BNUS"
			
text_scrsht_lower:
			.word	text_scrsht_3kind
			.word	text_scrsht_4kind
			.word	text_scrsht_flhse
			.word	text_scrsht_smstr
			.word	text_scrsht_lgstr
			.word	text_scrsht_yhtze
			.word	text_scrsht_chnce
			.word	text_scrsht_ybnus
			.word	text_scrsht_lbnus

text_scrsht_bscr:
			.asciiz	"     "


text_driver_pref:
			.asciiz "= USING DRIVER: "
;text_iobase_pref:
;			.asciiz	"= DEVICE I/O  : $"
text_ipcfg_pref:
			.asciiz	"= WITH IP ADDR: "

text_trace_init:
			.asciiz	"# INITIALISED!"
text_trace_cnct:
			.asciiz	"# CONNECTING..."
text_trace_unkmsg:
			.asciiz "- UNKNOWN MESSAGE IDENT"

text_debug_rtt:
			.asciiz "RTT $"
text_debug_retry:
			.asciiz " RETRY $"

text_syserr_pref:
			.asciiz	"!!"
text_err_pref:
			.asciiz	"! "
text_list_pref:
			.asciiz "* "
text_indent_pref:
			.asciiz "> "
text_outdent_pref:
			.asciiz "< "
text_msg_pref:
			.asciiz ": "
text_wrap_pref:
			.asciiz "/ "
text_dbg_rx_pref:
			.asciiz "RX $"
text_dbg_key_pref:
			.asciiz "KEY $"
text_dbg_key_mid:
			.asciiz " MOD $"


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
text_err_disc_evt:
			.asciiz " $"
text_err_okay:
			.asciiz	"= OKAY"


hexdigits:
			.byte "0123456789ABCDEF"
			
healthbars:
			.byte	$A0, $A0
      .byte $E3, $A0
      .byte $F7, $A0
      .byte $F8, $A0
      .byte $62, $A0
      .byte $79, $A0
      .byte $6F, $A0
      .byte $64, $A0
      .byte $20, $A0
			.byte	$20, $A0
      .byte $20, $E3
      .byte $20, $F7
      .byte $20, $F8
      .byte $20, $62
      .byte $20, $79
      .byte $20, $6F
      .byte $20, $64
      .byte $20, $20

healthclrs:
			.byte	$0D, $0D, $05, $05, $05, $05, $07, $07, $07
      .byte $07, $0A, $0A, $0A, $08, $08, $02, $02, $02

			
clrschme_idx:
			.byte	$00
clrschme_cnt	=	$06
clrschme_lst:
			.word	clrschme0
			.word	name_clrschme0
			.word	clrschme1
			.word	name_clrschme1
			.word	clrschme2
			.word	name_clrschme2
			.word	clrschme3
			.word	name_clrschme3
			.word	clrschme4
			.word	name_clrschme4
			.word	clrschme5
			.word	name_clrschme5
			.word	$0000
			
name_clrschme0:
			.asciiz	"CORPORATE"
clrschme0:
			.byte	$06, $02, $0E, $01, $06, $04, $0C, $0F, $03, $01
name_clrschme1:
			.asciiz	"FAMILIAR"
clrschme1:
			.byte	$0E, $0A, $01, $01, $0E, $04, $0C, $0F, $03, $01
name_clrschme2:
      .asciiz "POSTCARD"
clrschme2:
			.byte	$08, $09, $07, $01, $08, $0A, $0C, $0F, $03, $01
name_clrschme3:
      .asciiz "DESTINY"
clrschme3:
			.byte	$05, $0D, $0D, $01, $05, $07, $0C, $0F, $03, $01
name_clrschme4:
      .asciiz "BERRY"
clrschme4:
			.byte	$02, $0A, $0A, $01, $02, $04, $0C, $0F, $03, $01
name_clrschme5:
      .asciiz "PROWL'N"
clrschme5:
			.byte	$0B, $0F, $0F, $01, $0B, $0D, $0C, $0F, $03, $01
;===============================================================================


;CLR_BACK	$FD		;System - always black
;CLR_EMPTY	$FE		;Border on C64
;CLR_CURSOR	$FF		
;CLR_TEXT	$00
;CLR_FOCUS	$01
;CLR_INSET	$02
;CLR_FACE	$03
;CLR_SHADOW	$04
;CLR_PAPER	$05
;CLR_MONEY	$06
;CLR_DIE		$07


;===============================================================================
;	High memory ($E000-$FFF9, KERNAL banked out by initROM) - bss, so
;	none of this costs a byte in the .prg file, but it also means it's
;	genuine garbage until cleared at startup (see initHiVars).
;===============================================================================
.segment "HIVARS"
	.org		$E000

RX_BLOCK_BUF:
			.res	256

sendmsg0:
			.res	100
sendmsg1:
			.res	100
sendmsg2:
			.res	100
sendmsg3:
			.res	100
sendmsg4:
			.res	100
sendmsg5:
			.res	100

readmsg0:
			.res	100

msgs_change:
			.res	256
msgs_dirty:
			.res	256

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


room_log_line0:
			.res	41
room_log_line1:
			.res	41
room_log_line2:
			.res	41
room_log_line3:
			.res	41
room_log_line4:
			.res	41
room_log_line5:
			.res	41
room_log_line6:
			.res	41
room_log_line7:
			.res	41
room_log_line8:
			.res	41
room_log_line9:
			.res	41
room_log_lineA:
			.res	41
room_log_lineB:
			.res	41
room_log_lineC:
			.res	41
room_log_lineD:
			.res	41
room_log_lineE:
			.res	41
room_log_lineF:
			.res	41
room_log_line10:
			.res	41

play_log_line0:
			.res	41
play_log_line1:
			.res	41
play_log_line2:
			.res	41
play_log_line3:
			.res	41
play_log_line4:
			.res	41
play_log_line5:
			.res	41
play_log_line6:
			.res	41
play_log_line7:
			.res	41
play_log_line8:
			.res	41
play_log_line9:
			.res	41
play_log_lineA:
			.res	41
play_log_lineB:
			.res	41
play_log_lineC:
			.res	41
play_log_lineD:
			.res	41
play_log_lineE:
			.res	41
play_log_lineF:
			.res	41
play_log_line10:
			.res	41
