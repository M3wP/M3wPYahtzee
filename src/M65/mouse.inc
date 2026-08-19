;===============================================================================
;	mouse.inc - proportional-mouse driver + joystick fire button
;-------------------------------------------------------------------------------
;	The movement-tracking and acceleration logic here is ported from
;	MEGASPUTM's input.c/input.h (src/backup/input.c, src/backup/input.h),
;	which is GPLv3-or-later licensed. This is a from-scratch 6502
;	rewrite of the same algorithm (proportional POT-delta tracking with
;	an acceleration curve, plus reading a joystick fire button as an
;	extra left-click source), not a line-by-line translation - but
;	check licence compatibility with this project before it ships.
;
;	This is a DROP-IN REPLACEMENT for userProcessMouse/MoveCheck in
;	test.s. It reuses the existing state (XPos/YPos/XMin/XMax/YMin/
;	YMax/Buttons/ButtonsOld/OldPotX/OldPotY/mouseCheck/OldValue/
;	NewValue) and calls the existing CMOVEX/CMOVEY/ButtonCheck
;	unchanged, so none of the downstream UI layer - capture
;	(mouseCapture/mouseCapMove/mouseCapClick), hit-testing
;	(userMouseInCtrl and friends), or click handling (userHandleMouse/
;	userHandleMouseClick) - needs to change at all.
;
;	Not yet wired in: to merge, delete the existing userProcessMouse
;	and MoveCheck blocks from test.s (ButtonCheck/CMOVEX/CMOVEY stay,
;	they're unchanged) and add ".include "mouse.inc"" alongside the
;	other .include lines near the top of test.s.
;===============================================================================

;-------------------------------------------------------------------------------
userProcessMouse:
;-------------------------------------------------------------------------------
		LDA	mouseCheck
		BEQ	@begin

		INC	mouseCheck

@begin:
		LDY	#%00000000		;Set ports A and B to input
		STY	CIA1_DDRB
		STY	CIA1_DDRA		;Keyboard won't look like mouse
		LDA	CIA1_PRB		;Read Control-Port 1 (mouse)
		LDX	CIA1_PRA		;Read Control-Port 2 (joystick) -
						;	while DDRA is still input
		DEC	CIA1_DDRA		;Set port A back to output

		EOR	#%11111111		;Bit goes up when button goes down
		STA	Buttons

		TXA
		EOR	#%11111111
		AND	#buttonLeft		;Only the joystick fire bit counts
		ORA	Buttons			;	- merge into mouse buttons
		STA	Buttons

		BEQ	@L0
		DEC	CIA1_DDRB		;Mouse won't look like keyboard
		STY	CIA1_PRB		;Set "all keys pushed"

@L0:
		JSR	ButtonCheck

		LDA	SID_ADConv1		;Get mouse X movement
		LDY	OldPotX
		JSR	MouseReadDelta		;Calculate movement vector

; Skip processing if nothing has changed

		BCC	@SkipX
		STY	OldPotX

; Calculate the new X coordinate (--> a/y)

		CLC
		ADC	XPos

		TAY				;Remember low byte
		TXA
		ADC	XPos + 1
		TAX

; Limit the X coordinate to the bounding box

		CPY	XMin
		SBC	XMin + 1
		BPL	@L1
		LDY	XMin
		LDX	XMin + 1
		JMP	@L2
@L1:
		TXA

		CPY	XMax
		SBC	XMax + 1
		BMI	@L2
		LDY	XMax
		LDX	XMax + 1
@L2:
		STY	XPos
		STX	XPos + 1

; Move the mouse pointer to the new X pos

		TYA
		JSR	CMOVEX

		LDA	mouseCheck
		BNE	@SkipX

		LDA	#$01
		STA	mouseCheck

; Calculate the Y movement vector

@SkipX:
		LDA	SID_ADConv2		;Get mouse Y movement
		LDY	OldPotY
		JSR	MouseReadDelta		;Calculate movement

; Skip processing if nothing has changed

		BCC	@SkipY
		STY	OldPotY

; Calculate the new Y coordinate (--> a/y)

		STA	OldValue
		LDA	YPos
		SEC
		SBC	OldValue

		TAY
		STX	OldValue
		LDA	YPos + 1
		SBC	OldValue
		TAX

; Limit the Y coordinate to the bounding box

		CPY	YMin
		SBC	YMin + 1
		BPL	@L3
		LDY	YMin
		LDX	YMin + 1
		JMP	@L4
@L3:
		TXA

		CPY	YMax
		SBC	YMax + 1
		BMI	@L4
		LDY	YMax
		LDX	YMax + 1
@L4:
		STY	YPos
		STX	YPos + 1

; Move the mouse pointer to the new Y pos

		TYA
		JSR	CMOVEY

		LDA	mouseCheck
		BNE	@SkipY

		LDA	#$01
		STA	mouseCheck

; Done

@SkipY:
		CLC				;Interrupt not "handled"

		RTS


;-------------------------------------------------------------------------------
;	MouseReadDelta - ported from input.c's check_mouse_movement(),
;	folding in apply_acceleration() for any non-zero result.
;
;	Entry:	A = current pot reading, Y = old pot reading
;	Exit:	carry set, Y = value to store as the new "old" reading,
;		X:A = signed 16-bit delta (X is A's sign, $00 or $FF),
;		ready to ADC straight into a position word - same
;		contract the old MoveCheck had.
;		carry clear means no movement (X/A/Y not meaningful).
;-------------------------------------------------------------------------------
MouseReadDelta:
		STA	NewValue
		STY	OldValue

		LDX	#$00

		SEC
		LDA	NewValue
		SBC	OldValue
		AND	#$7F			; a = mod128 (new - old)

		CMP	#$40
		BCS	@neg

;	Small (non-negative) delta

		LSR	A
		BEQ	@zero

		JSR	MouseAccelerate

		LDY	NewValue
		SEC
		RTS

@neg:
		ORA	#$C1			; "or" in high-order bits
		CMP	#$FF			; noise floor - treat as no move
		BEQ	@zero

		SEC
		ROR	A			; a /= 2, sign preserved
		DEX				; X = $FF, sign-extend the delta

		JSR	MouseAccelerate

		LDY	NewValue
		SEC
		RTS

@zero:
		LDA	#$00
		CLC
		RTS


;-------------------------------------------------------------------------------
;	MouseAccelerate - ported from input.c's apply_acceleration().
;
;	Entry/exit: A = signed delta, scaled up for larger movements so a
;	fast physical mouse move doesn't feel like it's dragging.
;-------------------------------------------------------------------------------
MouseAccelerate:
		STA	mouseAccelTemp
		BPL	@pos

		EOR	#$FF
		CLC
		ADC	#$01

@pos:
		CMP	#$0B			; abs > 10 ?
		BCC	@tst5

		LDA	mouseAccelTemp
		ASL	A
		ASL	A			; value << 2
		RTS

@tst5:
		CMP	#$06			; abs > 5 ?
		BCC	@none

		LDA	mouseAccelTemp
		ASL	A			; value << 1
		RTS

@none:
		LDA	mouseAccelTemp
		RTS


mouseAccelTemp:
		.byte	$00
