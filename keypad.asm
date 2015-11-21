	NAME	KEYPAD

;--------------------------------------------------------------------------------------------------------------------------------------------------
; RoboTrike Keypad Routine

; The keypad functions for the RoboTrike.

; InitKey - Sets all keypad shared variables into a default state. False key, no debounce.
; GetKey - Returns the corresponding keycode of a debounced valid keypress into AL. Blocks until a key is available.
; IsAKey - Resets zero flag if a valid keypress is pending. Otherwise sets the flag.
; KMuxer - Scans and debounces 4x4 keypad under timer 2 interrupt control.
;
; The keycodes format is defined as follows.
; XYh
;	X = Row Label
;	Y = Key Label
;
;----------------------------------------------------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/16/09 William Fan
;	-Revised KMuxer to generate more convenient keycodes, now in hex.
;03/02/09 William Fan
;	-Revised KMuxer with working debounce.
; 02/26/09 William Fan
;	-Wrote KMuxer. No debounce functionality.
; 02/22/09 William Fan


$INCLUDE(key.inc)
$INCLUDE(constant.inc)
$INCLUDE(188val.inc)


CGROUP	GROUP   CODE

DGROUP	GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


		ASSUME  CS:CGROUP
		ASSUME	DS:DGROUP


; InitKey
;
; Description:
; Places default (reset) values in all shared variables of the keypad routines.
;
; Operation:
; Sets KeyPress to FALSEWORD (0).
; Sets DBTmr to DBTHRSHLD constant.
; Sets KeyVal to 0.
; Sets KeyTag to 0.
; Sets NomKeyRow to 0 (first).
;
; Arguments:       					None
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables: 				DBTmr - debounce timer
;							KeyVal - keycode for GetKey
;							KeyPress - valid keypress flag
;							KeyTag - label of previously detected key
;							NomKeyRow - nominal keypad row
;
; Global Variables: 				None
;
; Input: 						None
;
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				None
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 02/18/09 William Fan

InitKey		PROC 	NEAR
			PUBLIC 	InitKey

	MOV 	KeyPress, FALSEWORD		;turn off KeyPress flag
	MOV 	KeyVal, KEYCODEDFLT		;put default (blank) keycode into KeyVal
	MOV 	KeyTag, KEYCODEDFLT    	;put default (blank) keycode into KeyTag
	MOV 	NomKeyRow, ROWDFLT 		;initialize row label to the first row (0th row)
    MOV 	DBTmr, DBTHRSHLD      	;initialize debounce timer to the predefined threshold
    RET

InitKey 	ENDP


; GetKey
;
; Description:
; Blocking function until a keypress is verified and debounced, at which
; time the corresponding keycode is returned in AL.
;
; Operation:
; Loops the blocking function until handler returns a keycode which is taken
; from KeyVal and returned in AL.
;
; Arguments: 					None
;
; Return Values: 					[AL] - corresponding keypress' keycode
;
; Local Variables: 					None
;
; Shared Variables: 				KeyVal - keycode for GetKey
;							KeyPress - valid keypress flag
;
; Global Variables: 				None
;
; Input:						None
; Output:						None
;
; Error Handling:					None
;
; Registers Changed:				Flags, AX
; Stack Depth:					None

; Algorithms:					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 02/18/09 William Fan

GetKey		PROC	NEAR
			PUBLIC	GetKey

KeyCheckLoop:					;BLOCKING FUNCTION
	CALL	IsAKey				;check if keypress is true
	JZ		KeyCheckLoop		;if it's false, ZF, so we keep blocking
	;JNZ		KeyCodeGet			;if it's true, return keycode

KeyCodeGet:

	MOV 	AL, KeyVal 			;return keycode in AL
    MOV 	KeyPress, FALSEWORD	;reset the keypress state for next keypress

GetKeyFin:
    RET

GetKey  	ENDP


; InitKey
;
; Description:
; Sets zero flag based on keypress or no keypress.
;
; Operation:
; Compares the state flag of KeyState with a predefined FALSEWORD. This
; will clear ZF if key is pressed and set it if key is not pressed.
;
; Arguments:
; None
;
; Return Values:
; None
;
; Local Variables: 					None
;
; Shared Variables: 				KeyPress - valid keypress flag
;
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 02/18/09 William Fan

IsaKey	PROC	NEAR
		PUBLIC 	IsaKey

		CMP 	KeyPress, FALSEWORD	;check if keypress is true or false (sets ZF flag with compare)
		RET

IsaKey ENDP


; R2Key Table
;
; Description:
; List of keycodes in binary for the 4x4 keypad. When KMuxer scans
; for a valid debounced keypress, this table is used to translate the nominal
; key into a keycode that will eventually be stored in AL.
;
; Revision History:
; 04/16/09 William Fan
;	- Revised table to support two-digit hex keycodes.
; 04/12/09 William Fan
;	- Removed from r2k.asm and incorporated into this file.
; 02/18/09 William Fan

R2Key			LABEL   BYTE
				PUBLIC  R2Key

		DB      00001111B
		DB      00001111B
		DB      00001111B
		DB      00001111B
		DB      00001111B
		DB      00001111B
		DB      00001111B
		DB      00000111B
		DB      00001111B
		DB      00001111B
		DB      00001111B
		DB      00001011B
		DB      00001111B
		DB      00001101B
		DB      00001110B
		DB      00001111B


; KMuxer
;
; Description:
; Scans by row the keypad and debounces keypresses at the rate it is called
; by the timer event handler (1 KHz). Once a keypress is scanned and debounced,
; it forms the keycode retrieved in AL into CL and sets the KeyPress flag to TRUEWORD until
; the keypress is over. At this time, it sets the auto-repeat threshold to reset the scanning
; should the key be depressed long enough to activate auto-repeat.
;
; Operation:
; Read from the keypad I/O by row to determine the keycode of a pressed key in AL. The
; key is tagged by keycode. Whenever KMuxer is called and the pressed key is the same as
; the tagged key, the debounce timer is decremented from a preset threshold. When DB timer
; reaches zero, a row label is added to the keycode and the code is stored in CL. At this time,
; the keypress flag is set. Scanning resolution of the keypad is controlled by timer 2.
;
; Arguments:       					None
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables: 				DBTmr - debounce timer
;							KeyVal - keycode for GetKey
;							KeyPress - valid keypress flag
;							KeyTag - label of previously detected key
;							NomKeyRow - nominal keypad row
;
; Global Variables: 				None
;
; Input: 						[AL] - retrieved keypress data from keypad
;
; Output: 						None
;
; Error Handling:
; If two or more keys are pressed at the same time, the program will write the invalid
; keycode and reset KeyPress if these keys are in the same row.
;
; Registers Changed: 				Flags, AX, CX, DX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 04/16/09 William Fan
;	-Keycodes now in hex.
; 04/12/09 William Fan
; 	-Updated for auto-repeat.
; 03/05/09 William Fan
;	-Updated comments.
; 02/18/09 William Fan

KMuxer   	PROC NEAR
            PUBLIC KMuxer

KMuxerPrep:
    MOV 	DX, KeypadLoc		;load address of the keypad
    ADD 	DL, NomKeyRow       ;modify the address by row

KMuxerScn:
    IN  	AL, DX              ;retrieve the status of the keypad from I/O into AL
    AND  	AL, NOKEY        	;use the NOKEY definition to mask off all non-keycode bits
    MOV 	BX, OFFSET(R2Key)	;prepare table lookup for keycode
    XLAT 	CS:R2Key     		;index translate the keycode into AL
	MOV 	CL, NomKeyRow      	;first form row label in CL
    SHL 	CL, KEYSPERROW		;shift row bits in CL
    ADD 	CL, AL 				;insert AL's keycode into CL
    CMP  	AL, NOKEY        	;check keypress status
    JNE 	KMuxerChk			;if NE, that means there's a keypress - check for DB
    ;JE  		KMuxerPreChk            		;if no keypress yet, do precheck and return until next KMux call

KMuxerPreChk:
    MOV 	KeyTag, CL         	;tag the current key by keycode
    MOV 	DBTmr, DBTHRSHLD 	;reset DBTmr to standard DB threshold
	INC 	NomKeyRow         	;move to the next row, and wrap it (power of 2 only)
    AND 	NomKeyRow, (NUMROWS - 1)
	JMP 	KMuxerFin

KMuxerChk:
    CMP 	CL, KeyTag         	;compare the stored keycode with tagged key - if same, debounce
    JNE 	KMuxerPend			;the keypress was noise, so we reset DB and KeyTag
    ;JE  		KMuxerDB				;if nominal key same as prev. key, then we dec DB counter

KMuxerDB:
	DEC		DBTmr        		;countdown the debounce timer (recall EvH is called per millisecond)
	CMP 	DBTmr, 0        	;if timer hits 0, successful debounce and we flag this keypress as complete
	JNZ 	KMuxerFin        	;return and (possibly) debounce next EvH call, or key is (possibly) not "pressed" by then
    MOV 	KeyPress, TRUEWORD	;set the keypress flag to indicate a debounced keypress
    MOV 	KeyVal, CL         	;move the keycode into KeyVal for retrieval by GetKey
	;JMP		KMuxerRP				;this implementation will incorporate auto-repeat

KMuxerRP:
    MOV 	DBTmr, RPTHRSHLD  	;reset DBTmr to repeat rate to register auto-repeats
	JMP 	KMuxerFin

KMuxerPend:
	MOV		KeyTag, CL			;tag the nominal key in KeyTag to track for next keypress
	MOV		DBTmr, DBTHRSHLD	;reset the DB timer to the pre-defined DB threshold

KMuxerFin:
	RET

KMuxer	ENDP


CODE ENDS


;the data segment
DATA	SEGMENT	PUBLIC	'DATA'

		DBTmr		DW ?	;millisecond decremental counter until nominal pressed key is accepted as debounced

		KeyVal 		DB ? 	;set to the keycode of the current verified debounced keypress
		KeyPress   	DB ? 	;flag set if there is a pending verified debounced keypress, false otherwise
		KeyTag		DB ?  	;tags the nominal pressed key for comparison on the next keypad scan to reset/decrement DBTmr
		NomKeyRow   DB ?	;label of the nominal keypad row on the keypad being scanned

DATA    ENDS


		END
