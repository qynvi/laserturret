        NAME  SerialParser

;--------------------------------------------------------------------------------------------------------
; RoboTrike Serial Parsing
;
; Parses commands from the serial port.
;
; Uses the following functions:
;
; InitSP - initializes an initial idle state for the serial parsing routine
; ParseSerialChar - parse the passed character as part of a serial command
;
; In addition, contains the following private function:
;
; GetSPToken - lookup appropriate token for an ASCII value
;
; Also, utilizes the following slave routines;
;
; SRstall - stalls
; SRerror - notify of an error
; SRcommand - queue the current command
; SRdigit - inject a digit onto current value
; SRsign - change sign
; SRmotor - move
; SRlaser - change status of laser
; SRspreset - reset the serial parsing routine
; SRvector - motor velocity
;----------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	- Repackage for final release.
; 04/09/09 William Fan


$INCLUDE(srlprs.inc)


; data segment
DATA    SEGMENT PUBLIC  'DATA'

	CMtrSp		 	DW	?	;current speed of motor0
	CMtrAg			DW	?	;current angle setting of motors
	CMtrOR			DW	?	;current orientation of RoboTrike (controlled by a sign)
	NomMtrCmd		DB	?	;currently parsed motor command tx/rx
	NomVal			DW	?	;current value for whatever command
	CurrentState	DB	?	;current state of the state machine
	Sign			DB	?	;sign indicator

DATA    ENDS


; code segment
CODE	SEGMENT PUBLIC 	'CODE'

        ASSUME	CS:CODE, DS:DATA


; InitSP
;
; Description:
; Resets the serial parsing routines to initial statse. Initializes current value
; and current sign to 0 and 1 (positive) respectively.
;
; Operation:
; Changes CurrentState, then puts the values in NomVal and Sign.
;
; Arguments:			None
; Return Value:     			None
;
; Local Variables:  			None
; Shared Variables:
; Global Variables: 		None
;
; Input:            			None
; Output:           			None
;
; Error Handling:   		None
;
; Algorithms:       			None
; Data Structures:  		None
;
; Registers Changed:   		Flags, AX
; Stack Depth:      			None
;
; Revision History:
; 04/06/2009 William Fan

InitSP		PROC	NEAR
			PUBLIC	InitSP

InitSPVal:
	MOV		CurrentState, ST_MAIN		;set current state to idle
	MOV		CMtrSP, 0					;put initial values in everything
	MOV		CMtrAg, 0
	MOV		CMtrOr,	1

InitSPReset:
	CALL	SRspreset					;reset serial parsing routines

InitSPFin:
	RET

InitSP		ENDP


; ParseSerialChar
;
; Description:
; The function is passed a character which is presumed to be from the serial input.
; This character is parsed as a serial command using a state machine algorithm, and
; any errors are reported.
;
; Operation:
; Character c passed in AL is fed to state machine for parsing. AL is assumed
; to come from serial port. AX is changed to high or low state based on if there
; was an error in serial parsing. Commands must be valid in value and must be
; punctuated by a return character.
;
; Arguments:			[AL] - Character to parse.
; Return Value:    			[AX] - Error status. (0 = good, > 0 = bad)
;
; Local Variables:  			None
; Shared Variables: 		None
; Global Variables:
;
; Input:       				None
; Output:           			None
;
; Error Handling:
; For any error, AX will return a nonzero value so the user will know.
;
; Algorithms:       			State Machine
; Data Structures:  		None
;
; Limitations:			None
;
; Registers Changed:   		Flags, AX, BX, CX, DX, SI, DI
; Stack Depth:      			None
;
; Revision History:
; 04/06/2009 William Fan
; 02/24/2005 Glen George (Originally ParseFP)

ParseSerialChar	PROC	NEAR
				PUBLIC  ParseSerialChar

InitParsing:
	MOV		CL, CurrentState		;recall  current state of state machine

DoNextToken:
	CALL	GetSPToken				;retrieve token
	MOV		DH, AH					;reserve tokens
	MOV		CH, AL

ComputeTransition:
	MOV		AL, NUM_TOKEN_TYPES		;load number of different types of tokens
	MUL		CL						;transform AX into current state
	ADD		AL, DH					;arithmetic for transition
	ADC		AH, 0					;carry into high byte
	;now convert into a table offset
	IMUL	BX, AX, SIZE TRANSITION_ENTRY

DoAction:							;do the action (don't affect regs)
	MOV		AL, CH					;get token value back for actions
	CALL	CS:StateTable[BX].ACTION1
DoTransition:
	;go to next state
	MOV		CL, CS:StateTable[BX].NEXTSTATE
	MOV		CurrentState, CL

	RET

ParseSerialChar		ENDP


; StateTable
;
; Description:
; This is the state transition table for the state machine.
; Each entry consists of the next state and actions for that
; transition.  The rows are associated with the current
; state and the columns with the input type.
;
; Revision History:
; 04/10/2009 William Fan
; - Adapted for my own use from FloatPTD
; 02/24/2005 Glen George
; - Simplified some code in ParseFP.
; - Updated comments.
; 02/26/2003 Glen George

TRANSITION_ENTRY	STRUC       ;structure used to define table
    NEXTSTATE	DB      ?   	;the next state for the transition
    ACTION1		DW      ?    	;first action for the transition
TRANSITION_ENTRY	ENDS

;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act1))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act1)>
)

StateTable	LABEL	TRANSITION_ENTRY

	;Current State = ST_MAIN                   			  	Input Token Type
	%TRANSITION(ST_LASER, SRdigit)				;TKN_LSRCMD
	%TRANSITION(ST_MOVE, SRcommand)				;TKN_MTRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_SIGN
	%TRANSITION(ST_ERROR, SRerror)				;TKN_NUM
	%TRANSITION(ST_ERROR, SRerror)				;TKN_EOC
	%TRANSITION(ST_MAIN, SRstall)				;TKN_STALL
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MISC

	;Current State = ST_MOVE                      				Input Token Type
	%TRANSITION(ST_ERROR, SRerror)				;TKN_LSRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MTRCMD
	%TRANSITION(ST_SIGN, SRsign)				;TKN_SIGN
	%TRANSITION(ST_NUMBER, SRdigit)				;TKN_NUM
	%TRANSITION(ST_ERROR, SRerror)				;TKN_EOC
	%TRANSITION(ST_MOVE, SRstall)				;TKN_STALL
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MISC

	;Current State = ST_SIGN                    				Input Token Type
	%TRANSITION(ST_ERROR, SRerror)				;TKN_LSRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MTRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_SIGN
	%TRANSITION(ST_NUMBER, SRdigit)				;TKN_NUM
	%TRANSITION(ST_ERROR, SRerror)				;TKN_EOC
	%TRANSITION(ST_SIGN, SRstall)				;TKN_STALL
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MISC

	;Current State = ST_NUMBER                    				Input Token Type
	%TRANSITION(ST_ERROR, SRerror)				;TKN_LSRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MTRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_SIGN
	%TRANSITION(ST_NUMBER, SRdigit)				;TKN_NUM
	%TRANSITION(ST_MAIN, SRmotor)				;TKN_EOC
	%TRANSITION(ST_NUMBER, SRstall)				;TKN_STALL
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MISC

	;Current State = ST_LASER		                   			Input Token Type
	%TRANSITION(ST_ERROR, SRerror)				;TKN_LSRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MTRCMD
	%TRANSITION(ST_ERROR, SRerror)				;TKN_SIGN
	%TRANSITION(ST_ERROR, SRerror)				;TKN_NUM
	%TRANSITION(ST_MAIN, SRlaser)				;TKN_EOC
	%TRANSITION(ST_LASER, SRstall)				;TKN_STALL
	%TRANSITION(ST_ERROR, SRerror)				;TKN_MISC

	;Current State = ST_ERROR                    				Input Token Type
	%TRANSITION(ST_ERROR, SRstall)				;TKN_LSRCMD
	%TRANSITION(ST_ERROR, SRstall)				;TKN_MTRCMD
	%TRANSITION(ST_ERROR, SRstall)				;TKN_SIGN
	%TRANSITION(ST_ERROR, SRstall)				;TKN_NUM
	%TRANSITION(ST_ERROR, SRstall)				;TKN_EOC
	%TRANSITION(ST_ERROR, SRstall)				;TKN_STALL
	%TRANSITION(ST_ERROR, SRstall)				;TKN_MISC


; GetSPToken
;
; Description:
; Returns token class and value. Truncate character to 7 bits.
;
; Operation:
; Looks up class in one table and value in another table.
;
; Arguments:			[AL] - Character to lookup.
; Return Value:    			[AL] - Token value.
;					[AH] - Token class.
;
; Local Variables:  			None
; Shared Variables: 		None
; Global Variables:
;
; Input:       				None
; Output:           			None
;
; Error Handling: 			None
;
; Algorithms:       			None
; Data Structures:  		Token value table.
;					Token class table.
;
; Limitations:			None
;
; Registers Changed:   		AX, BX
; Stack Depth:      			None
;
; Revision History:
; 04/06/2009 William Fan
; 02/26/2003 Glen George (Originally GetFPToken)

GetSPToken	PROC    NEAR

InitGetSerialToken:						;setup for lookups
	AND	AL, TOKEN_MASK					;strip unused bits (high bit)
	MOV	AH, AL							;and preserve value in AH

TokenTypeLookup:                        ;get the token type
    MOV     BX, OFFSET(TokenTypeTable) 	;BX points at table
	XLAT	CS:TokenTypeTable			;have token type in AL
	XCHG	AH, AL						;token type in AH, character in AL

TokenValueLookup:						;get the token value
	MOV     BX, OFFSET(TokenValueTable)	;BX points at table
	XLAT	CS:TokenValueTable			;have token value in AL

GetSPTokenFin:            	        	;done looking up type and value
	RET

GetSPToken	ENDP

; Token Tables
;
; Description:
; This creates the tables of token types and token values.
; Each entry corresponds to the token type and the token
; value for a character.  Macros are used to actually build
; two separate tables - TokenTypeTable for token types and
; TokenValueTable for token values.
;
; 04/10/2009 William Fan
; - Adapted for my own use from FloatPTD
; 02/24/2005 Glen George
; - Simplified some code in ParseFP.
; - Updated comments.
; 02/26/2003 Glen George

%*DEFINE(TABLE)  (
        %TABENT(TKN_MISC, 0)			;<null>
        %TABENT(TKN_MISC, 1)			;SOH
        %TABENT(TKN_MISC, 2)			;STX
        %TABENT(TKN_MISC, 3)			;ETX
        %TABENT(TKN_MISC, 4)			;EOT
        %TABENT(TKN_MISC, 5)			;ENQ
        %TABENT(TKN_MISC, 6)			;ACK
        %TABENT(TKN_MISC, 7)			;BEL
        %TABENT(TKN_MISC, 8)			;backspace
        %TABENT(TKN_STALL, 9)			;TAB
        %TABENT(TKN_MISC, 10)			;new line
        %TABENT(TKN_MISC, 11)			;vertical tab
        %TABENT(TKN_MISC, 12)			;form feed
        %TABENT(TKN_EOC, 13)			;carriage return - EOC
        %TABENT(TKN_MISC, 14)			;SO
        %TABENT(TKN_MISC, 15)			;SI
        %TABENT(TKN_MISC, 16)			;DLE
        %TABENT(TKN_MISC, 17)			;DC1
        %TABENT(TKN_MISC, 18)			;DC2
        %TABENT(TKN_MISC, 19)			;DC3
        %TABENT(TKN_MISC, 20)			;DC4
        %TABENT(TKN_MISC, 21)			;NAK
        %TABENT(TKN_MISC, 22)			;SYN
        %TABENT(TKN_MISC, 23)			;ETB
        %TABENT(TKN_MISC, 24)			;CAN
        %TABENT(TKN_MISC, 25)			;EM
        %TABENT(TKN_MISC, 26)			;SUB
        %TABENT(TKN_MISC, 27)			;escape - RESET
        %TABENT(TKN_MISC, 28)			;FS
        %TABENT(TKN_MISC, 29)			;GS
        %TABENT(TKN_MISC, 30)			;AS
        %TABENT(TKN_MISC, 31)			;US
        %TABENT(TKN_STALL, ' ')			;space
        %TABENT(TKN_MISC, '!')			;!
        %TABENT(TKN_MISC, '"')			;"
        %TABENT(TKN_MISC, '#')			;#
        %TABENT(TKN_MISC, '$')			;$
        %TABENT(TKN_MISC, 37)			;percent
        %TABENT(TKN_MISC, '&')			;&
        %TABENT(TKN_MISC, 39)			;'
        %TABENT(TKN_MISC, 40)			;open parentheses
        %TABENT(TKN_MISC, 41)			;close parentheses
        %TABENT(TKN_MISC, '*')			;*
        %TABENT(TKN_SIGN, +1)			;+  (positive sign)
        %TABENT(TKN_MISC, 44)			;,
        %TABENT(TKN_SIGN, -1)			;-  (negative sign)
        %TABENT(TKN_MISC, 0)			;.
        %TABENT(TKN_MISC, '/')			;/
        %TABENT(TKN_NUM, 0)				;0  (digit)
        %TABENT(TKN_NUM, 1)				;1  (digit)
        %TABENT(TKN_NUM, 2)				;2  (digit)
        %TABENT(TKN_NUM, 3)				;3  (digit)
        %TABENT(TKN_NUM, 4)				;4  (digit)
        %TABENT(TKN_NUM, 5)				;5  (digit)
        %TABENT(TKN_NUM, 6)				;6  (digit)
        %TABENT(TKN_NUM, 7)				;7  (digit)
        %TABENT(TKN_NUM, 8)				;8  (digit)
        %TABENT(TKN_NUM, 9)				;9  (digit)
        %TABENT(TKN_MISC, ':')			;:
        %TABENT(TKN_MISC, ';')			;;
        %TABENT(TKN_MISC, '<')			;<
        %TABENT(TKN_MISC, '=')			;=
        %TABENT(TKN_MISC, '>')			;>
        %TABENT(TKN_MISC, '?')			;?
        %TABENT(TKN_MISC, '@')			;@
        %TABENT(TKN_MISC, 'A')			;A
        %TABENT(TKN_MISC, 'B')			;B
        %TABENT(TKN_MISC, 'C')			;C
        %TABENT(TKN_MISC, 'D')			;D
        %TABENT(TKN_MISC, 0)			;E
        %TABENT(TKN_LSRCMD, 1)			;F - LASER ON
        %TABENT(TKN_MISC, 'G')			;G
        %TABENT(TKN_MISC, 'H')			;H
        %TABENT(TKN_MISC, 'I')			;I
        %TABENT(TKN_MISC, 'J')			;J
        %TABENT(TKN_MISC, 'K')			;K
        %TABENT(TKN_MISC, 'L')			;L
        %TABENT(TKN_MISC, 'M')			;M
        %TABENT(TKN_MISC, 'N')			;N
        %TABENT(TKN_LSRCMD, 0)			;O - LASER OFF
        %TABENT(TKN_MISC, 'P')			;P
        %TABENT(TKN_MISC, 'Q')			;Q
        %TABENT(TKN_MTRCMD, CMD_TRT)	;R - ROTATE TURRET
        %TABENT(TKN_MTRCMD, CMD_SPD)	;S - SET SPEED
        %TABENT(TKN_MTRCMD, CMD_TURN)	;T - TURN
        %TABENT(TKN_MISC, 'U')			;U
        %TABENT(TKN_MTRCMD, CMD_RSPD)	;V - SET RELATIVE SPEED
        %TABENT(TKN_MISC, 'W')			;W
        %TABENT(TKN_MISC, 'X')			;X
        %TABENT(TKN_MISC, 'Y')			;Y
        %TABENT(TKN_MISC, 'Z')			;Z
        %TABENT(TKN_MISC, '[')			;[
        %TABENT(TKN_MISC, '\')			;\
        %TABENT(TKN_MISC, ']')			;]
        %TABENT(TKN_MISC, '^')			;^
        %TABENT(TKN_MISC, '_')			;_
        %TABENT(TKN_MISC, '`')			;`
        %TABENT(TKN_MISC, 'a')			;a
        %TABENT(TKN_MISC, 'b')			;b
        %TABENT(TKN_MISC, 'c')			;c
        %TABENT(TKN_MISC, 'd')			;d
        %TABENT(TKN_MISC, 'e') 			;e
        %TABENT(TKN_LSRCMD, 1)			;f - LASER ON
        %TABENT(TKN_MISC, 'g')			;g
        %TABENT(TKN_MISC, 'h')			;h
        %TABENT(TKN_MISC, 'i')			;i
        %TABENT(TKN_MISC, 'j')			;j
        %TABENT(TKN_MISC, 'k')			;k
        %TABENT(TKN_MISC, 'l')			;l
        %TABENT(TKN_MISC, 'm')			;m
        %TABENT(TKN_MISC, 'n')			;n
        %TABENT(TKN_LSRCMD, 0)			;O - LASER OFF
        %TABENT(TKN_MISC, 'p')			;p
        %TABENT(TKN_MISC, 'q')			;q
        %TABENT(TKN_MTRCMD, CMD_TRT)	;r - ROTATE TURRET
        %TABENT(TKN_MTRCMD, CMD_SPD)	;s - SET SPEED
        %TABENT(TKN_MTRCMD, CMD_TURN)	;t - TURN
        %TABENT(TKN_MISC, 'u')			;u
        %TABENT(TKN_MTRCMD, CMD_RSPD)	;v - SET RELATIVE SPEED
        %TABENT(TKN_MISC, 'w')			;w
        %TABENT(TKN_MISC, 'x')			;x
        %TABENT(TKN_MISC, 'y')			;y
        %TABENT(TKN_MISC, 'z')			;z
        %TABENT(TKN_MISC, '{')			;{
        %TABENT(TKN_MISC, '|')			;|
        %TABENT(TKN_MISC, '}')			;}
        %TABENT(TKN_MISC, '~')			;~
        %TABENT(TKN_MISC, 127)			;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE

; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE


; begin secondary functions


; SRspreset
;
; Description:
; Returns serial parser to a default state.
;
; Operation:
; NomVal is zero, sign is 1 (positive).
;
; Revision History:
; 04/01/2009 William Fan

SRspreset	PROC	NEAR
			PUBLIC	SRspreset
	MOV		NomVal, 0
	MOV		Sign, 1
	XOR		AX,	AX	;clear error bytes
	RET
SRspreset	ENDP


; SRstall
;
; Description:
; Has no effect.
;
; Operation:
; Clears error bytes.
;
; Revision History
; 04/01/ 2009 William Fan

SRstall		PROC	NEAR
	XOR		AX,	AX	;clear error bytes
	RET
SRstall		ENDP


; SRerror
;
; Description:
; Tells user that an error of some sort has occurred.
;
; Operation:
; Changes AX to error value.
;
; Revision History
; 04/01/2009 William Fan

SRerror		PROC	NEAR
	MOV		AX,	ErrorWord	;set error bytes
	RET
SRerror		ENDP


; SRcommand
;
; Description:
; Calls motor command based on a lookuped token value.
;
; Operation:
; NomMtrCmd becomes the identified token value.
;
; Revision History
; 04/01/2009 William Fan

SRcommand	PROC	NEAR
	MOV		NomMtrCmd, AL
	XOR		AX,	AX			;clear error bytes
	RET
SRcommand	ENDP


; SRdigit
;
; Description:
; Inject a digit into NomVal by the token.
;
; Operation:
; NomVal x 10, then + token value.
;
; Local Variables:		[AX] - accumulator
;				[CL] - sign
;
; Registers Changed:	Flags, AX, CX, SI
;
; Revision History
; 04/01/2009 William Fan

SRdigit		PROC	NEAR
	MOV		CL, Sign
	IMUL	CL
	CBW
	MOV		CX, AX			;reserve the token and the lookup value in CX
	MOV		AX, NomVal		;now put current value into AX
	MOV		SI, 10
	IMUL	SI				;advance AX by one place value
	JC		SRdigitError 	;carry flag means error because it's too big for some reason
	ADD		AX,	CX			;add token's value to current value
	JO		SRdigitError	;overflow flag means error because token value is too big somehow
	MOV		NomVal,	AX		;store new value
	XOR		AX,	AX			;clear error bytes
	JMP		SRdigitFin
SRdigitError:
	CALL	SRerror			;call error handler
SRdigitFin:
	RET
SRdigit	ENDP


; SRsign
;
; Description:
; Sets the sign.
;
; Operation:
; Token value reveals absolute or relative turret adjustment. This will
; set sign depending on whether the command wants absolute or relative
; positioning.
;
; Arguments:        		[AL] - token value

; Registers Changed:	Flags, AX
;
; Revision History:
; 04/01/2009 William Fan

SRsign		PROC	NEAR
	CMP		NomMtrCmd, CMD_TRT
	JNE		StoreSign				;if absolute, store sign
	MOV		NomMtrCmd, CMD_RTRT		;otherwise, set current command to relative turret angle change
StoreSign:
	MOV		Sign, AL
	XOR		AX,	AX					;clear error bytes
	RET
SRsign		ENDP


;ref external laser setting function from motor.asm
EXTRN	SetLaser:NEAR
; SRlaser
;
; Description:
; Based on command from the token value, sets laser on/off.
;
; Operation:
; Call external function SetLaser then reset state machine.
;
; Registers Changed:	AX
;
; Revision History:
; 04/01/2009 William Fan

SRlaser		PROC	NEAR
	MOV		AX,	NomVal
	CALL	SetLaser		;NomVal = 1 turns laser on, else off
	CALL	SRspreset		;after, need to reset state machine
	RET
SRlaser		ENDP


;ref external motor functions from motor.asm
EXTRN	SetMotorSpeed:NEAR
EXTRN	SetTurretAngle:NEAR
EXTRN	SetRelTurretAngle:NEAR
; SRmotor
;
; Description:
; Takes action depending on NomMtrCmd.
;
; Operation:
; NomMtrCmd calls motor functions based on the command, whether it is relative,
; and if it refers to the PWM motors or the stepper.
;
; Stack Depth:	1 byte
;
; Revision History:
; 04/01/2009 William Fan

SRmotor		PROC	NEAR
	PUSH	BX					;reserve BX
	MOV		AL,	NomMtrCmd		;store nominal command in AL
	CMP		AL,	CMD_SPD
	JNE		RSPD				;if not a speed command, skip
	CALL	SRvector			;else, call vector setting SR
	JMP		SRmotorNE
RSPD:
	CMP		AL,	CMD_RSPD
	JNE		Turn				;if not relative speed command, skip
	MOV		AX,	CMtrSp
	ADD		NomVal, AX
	JO		SRmotorE			;overflow means serious problems
	CALL	SRvector			;set vector
	JMP		SRmotorNE
Turn:
	CMP		AL,	CMD_TURN
	JNE		TRT					;if not a turn command, skip
	MOV		BX,	NomVal
	ADD		BX,	CMtrAg
	JO		SRmotorE			;overflow implies serious problems
	MOV		CMtrAg,	BX			;store the new angle
	MOV		AX,	0FFFFh			;store null speed value in AX (one of the args for SetMotorSpeed)
	CALL	SetMotorSpeed		;set the new motor velocity
	JMP		SRmotorNE
TRT:
	CMP		AL,	CMD_TRT
	JNE		RTRT				;if not a turret setting command, skip
	MOV		AX,	NomVal
	CALL	SetTurretAngle		;call stepper
	JMP		SRmotorNE
RTRT:
	CMP		AL,	CMD_RTRT
	JNE		SRmotorFin			;if not relative turret command, skip
	MOV		AX,	NomVal
	CALL	SetRelTurretAngle	;call relative stepper
	JMP		SRmotorNE
SRmotorNE:						;no errors
	CALL	SRspreset			;reset serial parser to default
	JMP		SRmotorFin
SRmotorE:						;error, bad
	CALL	SRspreset			;reset serial parser to default
	CALL	SRerror
	;JMP		SRmotorFin
SRmotorFin:
	POP		BX					;restore BX
	RET
SRmotor	ENDP


; SRvector
;
; Description:
; NomVal defines RoboTrike vector heading and magnitude.
;
; Operation:
; Calls SetMotorSpeed from external to set speed and heading. If NomVal is
; negative, rotates by 180 first to go backwards from relative position.
;
; Registers Changed:	AX, BX
;
; Revision History:
; 04/02/2009 William Fan

SRvector	PROC	NEAR
	MOV		AX,	NomVal
	MOV		CMtrSp, AX			;load current speed
	MOV		BX,	-32768			;load angle null change value
	IMUL	CMtrOr
	CMP		AX,	0				;do we need to flip the trike?
	JGE		SRvectorSet			;call function to set vector with args
	;JL		SRvectorNEG			;first rotate the heading, then call function to set vector
SRvectorNEG:
	ADD		CMtrAg,	180			;180 flip
	NEG		AX					;remove sign from AX
	NEG		CMtrOr				;reverse the direction
	MOV		BX,	CMtrAg			;store new motor angle
SRvectorSet:
	CALL	SetMotorSpeed		;SetMotorSpeed(NomVal, BX)
	RET
SRvector	ENDP


CODE ENDS



END
