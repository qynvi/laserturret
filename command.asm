	NAME	COM

;----------------------------------------------------------------------------------------------------------------------------------------
; RokoTrike188 Command Board User Interface

; Contains the routines that are called from the command board main loop in order to
; parse keypresses in serial commands sent to the slave board for execution. It is also
; responsible for feedback of status on 14-segment display and handling of serial/motor
; errors reported by the slave board.
;
; Command - Calls display to feedback the status of the slave board, outputs the current
;		command being executed, if any, and translates debounced keypresses on 4x4
;		keypad into corresponding serial commands to be parsed by the slave board.
;------------------------------------------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/02/09 William Fan
;	- Repackage for final release
; 04/26/09 William Fan
;	- Small problem with SerialPutChar sending garbage serial data.
; 04/15/09 William Fan


$INCLUDE(disp.inc)
$INCLUDE(serial.inc)
$INCLUDE(key.inc)
$INCLUDE(constant.inc)
$INCLUDE(command.inc)


CGROUP	GROUP   CODE

DGROUP  GROUP   DATA

CODE  	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
		ASSUME	DS:DGROUP


		EXTRN DisplayNum:NEAR
        EXTRN DisplayHex:NEAR
        EXTRN Display:NEAR
		EXTRN DMuxUp:NEAR
		EXTRN DMuxDwn:NEAR
        EXTRN IsaKey:NEAR
        EXTRN GetKey:NEAR
        EXTRN SerialInRdy:NEAR
		EXTRN SerialGetChar:NEAR
		EXTRN SerialPutChar:NEAR
		EXTRN SerialStatus:NEAR


;DebugToggle
;
;Description:
; Turns on serial debug mode when command routine is run.
;
; Operation:
; Sets DebugFlag to TRUCOMM.
;
; Shared Variables:
;	DebugFlag - native, byte - set or reset to toggle serial debug mode
;
; Revision History:
; 04/15/09 William Fan

DebugToggle		PROC  NEAR
				PUBLIC DebugToggle

    MOV 		DebugFlag, TRUCOMM
    RET

DebugToggle 	ENDP


;DebugReset
;
;Description:
; Turns off serial debug mode when command routine is run.
;
; Operation:
; Sets DebugFlag to FLSCOMM.
;
; Shared Variables:
;	DebugFlag - native, byte - set or reset to toggle serial debug mode
;
; Revision History:
; 04/15/09 William Fan

DebugReset	PROC  NEAR
			PUBLIC DebugReset

    MOV 	DebugFlag, FLSCOMM
    RET

DebugReset 	ENDP


; ErrorMsg
;
; Description:
; Table of parse error string.
;
; Revision History:
; 04/15/09 William Fan

ErrorMsg	LABEL	Byte

	DB 'PArSE ErrOr',0h


; Key2Comm
;
; Description:
; Table indexing all 16 keys and their corresponding commands when db-keypressed.
;
; Revision History:
; 04/15/09 William Fan

Key2Comm	LABEL  Byte
			PUBLIC Key2Comm

	DB 'T-30  ',13      ;swivel turret counterclockwise 30 deg		row0:col0
    DB 'V+5000',13      ;increase velocity 5000 forward			row0:col1
    DB 'T+30  ',13      ;swivel turret clockwise 30 deg			row0:col2
    DB 'D-180 ',13      ;reverse heading						row0:col3
    DB 'D-45  ',13      ;turn drive angle by 45 deg counterclockwise	row1:col0
    DB 'S0    ',13      ;all stop after finishing current motor operation	row1:col1
    DB 'D+45  ',13      ;turn drive angle by 45 deg clockwise		row1:col2
	DB 'F     ',13      ;turn on laser						row1:col3
	DB 'D-90  ',13      ;turn drive angle by 90 deg counterclockwise	row2:col0
    DB 'V-5000',13      ;decrease velocity 5000 backwards			row2:col1
    DB 'D+90  ',13      ;turn drive angle by 90 deg clockwise		row2:col2
    DB 'O     ',13      ;turn off laser						row2:col3
    DB '      E'        ;NULL							row3:col0
    DB '      E'		;NULL							row3:col1
	DB 'dIM    '        ;set display brightness to low				row3:col2
    DB 'brIgHt '        ;set display brightness to high				row3;col3


; Command
;
; Description:
; Using the keypad routines (HW8), retrieves debounced valid keycodes from
; the keypad and index matches these with the Key2Comm table. The corresponding
; command is sent to the slave board via SerialPutChar (HW10) and fed back to the
; 14-segment display. At a motor muxing rate, it receives status updates from the slave
; board and in the case of an error informs the user.
;
; Operation:
; Runs GetKey continuously to retrieve two digit hex keycodes. Translating this to the
; coordinate of the key on the 4x4 keypad, Key2Comm table lookup returns the appropriate
; serial command. The same serial command is displayed with Disp14. At tmr0 rate, receives
; and displays serial error if one exists.
;
; Input: 					Serial (slave)
;
; Output: 					Serial (command)
;						14-Seg Display
;
; User Interface: 				4x4 Keypad (Key2Comm)
;
; Error Handling:
; Serial errors reported by the motor board are queued to be displayed on the 14 segment
; display, but no further actions are taken.
;
;Shared Variables:			CommStr - native, byte - the nominal command string
;
; Registers Changed: 			Flags, AX, BX, CX, DX, ES, SI
;
; Stack Depth:				None
;
; Revision History:
; 04/15/09 William Fan

Command		PROC	NEAR
			PUBLIC	Command

CommandChk:
    CALL 	SerialStatus		;checks for serial errors
	CMP 	AL, SERIAL_ERROR_NULL
	JE 		CommDbgTggle		;when there is none, continue, else disp error code and terminate
	MOV 	AX, SERIAL_ERROR_CODE
	CALL 	DisplayNum
	JMP 	CommandFin			;serial error, terminate routines

CommDbgTggle:
	;in serial debug mode, external Hyper Terminal on a computer may be used to check serial functionality
    CMP 	DebugFlag, TRUCOMM  ;checks if serial debug is enabled
    JNE 	CommKeyScn     		;if not true, continue without the serial debug steps

CommDbgTrue:
    CALL 	SerialInRdy   		;in this mode, first check if serial is ready
    JZ   	CommDbgBlk			;zero flag set, block keypad
    CALL 	SerialGetChar      	;if Hyper Terminal sends a char, receive it from Rx queue
    CALL 	DisplayHex			;call Disp14 to show it on LED

CommDbgBlk:
    CALL 	IsaKey             	;if any keypad key is pressed (valid, debounced), terminate this mode
    JZ 		CommDbgTrue			;unless IsaKey detects valid keypress, restart serial debug cycle
	;JNZ		CommKeyScn			;if IsaKey sees keypress, unblock from serial debug mode and scan for key command

BRIGHTNESS:

CommKeyScn:
    CALL 	IsaKey             	;begin scanning for valid keypress again
    JZ  	CommErr         	;if none, continue onwards to receive possible errors
	CALL 	GetKey            	;if exists, grab keycode
	CMP 	AL, BRIGHTNESS_HI  	;first check if keycode corresponds to key for brightness adjustment
	JNE 	BrightnessDown     	;if they don't want it bright, they might want it not bright
	CALL 	DMuxUp				;otherwise, call DMuxUp to scale up mux duty cycle and make it seem brighter
	JMP  	CommandFin			;terminate, since we've already handled the keypress

BrightnessDown:
    CMP 	AL, BRIGHTNESS_LO  	;check if the passed value in AL is the low brightness value
	JNE 	CommKeyXlat  		;if not that, then it's a key we use Key2Comm to translate
	CALL 	DMuxDwn				;otherwise, call DMuxDwn to scale down mux duty cycle and make it seem darker
    JMP 	CommandFin			;terminate, since we've already handled the keypress

TRANSLATING:

CommKeyXlat:
	MOV 	BL, AL            	;accumulator is needed for the key masking steps, so move keycode in AL into BX for safekeeping
    MOV 	BH, 0              	;clear high bits so we can IMUL
	AND 	AL, ROWSTRIP      	;with the key mask from key routines, remove the row digit from keycode so we can work the key value
	MOV 	DX, 0     			;DX begins at key 0 and will be inc per test to point to nominal row
	;we will move key by key, using a bit set in in CL and shifted around while ANDing with the key value we have to determine the originating key
	MOV 	CL, 1          		;place a test bit in CL (AX not available, BX not available, DX not available)

CommKeyTest:
	TEST 	AL, CL              ;mask CL's lone bit with the row value extracted by the key mask into AL
	JZ 		CommKeyID           ;when TEST sets zero flag, nominal key has been hit (CL cannot be trashed)
	CMP 	DX, KEYSPERROW		;check the position of DX (it points to rows, inc per iteration of this loop)
	JGE 	CommKeyID         	;when DX is equal to the total number of keys in the row, CL should be done
	INC 	DX               	;otherwise, inc DX to point to next key in the row
	SHL 	CL, 1              	;shift the lone bit in CL left to test next bit of AL key digit
	JMP 	CommKeyTest			;reiterate

CommKeyID:
	AND 	BL, KEYSTRIP      	;this time, strip off the key digits while we work with the row value
	SHR 	BL, KEYSPERROW     	;shift right by 4 to isolate row number in least significant bits
	;in this next part, we want to turn BX into the index of Key2Comm, first scaling BX into the number of characters per command,
	;then repointing it to the nominal row, and finally scaling DX then adding this offset
	IMUL 	BX, BX, COMM_MAX_LEN
	IMUL 	BX, BX, KEYSPERROW
    IMUL 	DX, DX, COMM_MAX_LEN
	ADD 	BX, DX
	MOV 	SI, OFFSET(CommStr)	;point to the command string we have
	MOV 	DI, 0              	;initialize a loop counter so we can iterate the command forming routine

CommForm:
    CMP 	DI, COMM_MAX_LEN	;check if iterator exceed command max length
	JGE 	CommDisp			;if so, terminate this routine
	MOV 	AL, CS:Key2Comm[BX]	;move the command char into AL
    MOV 	BYTE PTR [SI], AL  	;put this AL value into the growing command string
    PUSHA						;reserve everything before we call serial commands
	CALL 	SerialPutChar      	;enqueue AL over serial
    POPA						;restore everything after we call serial commands
	INC 	SI                 	;index++
	INC 	DI                 	;iterator++
	INC 	BX                 	;command char++
	JMP 	CommForm

CommDisp:
	MOV 	BYTE PTR [SI], NULL	;null termination of the command string
	PUSH 	DS               	;the svelte way of forming ES;SI for display14
	POP 	ES
	MOV 	SI, OFFSET(CommStr)	;refresh index
	CALL 	Display          	;display the command we just did (or are doing)

ERRORHANDLING:

CommErr:
    CALL 	SerialInRdy      	;check if serial is ready
    JZ 		CommandFin			;if serial reports ok, terminate
	CALL 	SerialGetChar      	;retrieve the error characters
	CMP 	AL, SERIAL_ERROR_NULL
	JE  	CommandFin			;terminate if there's no significant serial error
	MOV 	BX, 0				;else make another iterator and refresh index to error string
    MOV 	SI, OFFSET(ErrorStr)

CommErrForm:
	CMP 	BX, ERROR_MAX_LEN	;check if iterator exceeds max length of the error message
	JGE 	CommErrDisp        	;if we are done forming the error string, then we display it
    MOV 	AL, ErrorMsg[BX]	;get the char
	MOV 	BYTE PTR [SI], AL
	INC 	SI                 	;index++
	INC 	BX					;iterator++
	JMP 	CommErrForm

CommErrDisp:
	PUSH 	DS  				;the awesome way of forming ES:SI for display14
	POP 	ES
    MOV 	SI, OFFSET(ErrorStr)
	CALL 	Display				;display error
	;JMP 		CommandFin			;terminate

CommandFin:
	RET

Command		ENDP


CODE 		ENDS


;the data segment
DATA	SEGMENT PUBLIC  'DATA'

	DebugFlag 	DB  ?				     ;flag which indicates on/off of serial debug mode
	CommStr		DB	DBFFR_MAXLEN DUP (?) ;the command string, both parsed and displayed (size constrained to display buffer length)
	ErrorStr	DB	DBFFR_MAXLEN DUP (?) ;the error string, sent and displayed (size constrained to display buffer length)

DATA    ENDS


		END
