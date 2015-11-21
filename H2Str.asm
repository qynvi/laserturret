		NAME	HEX2STRING

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP

$INCLUDE(constant.inc)

; Numeric Conversion Functions
; Hex2String
;
; Description:
; This function accepts input as a 16-bit unsigned hexadecimal value as �n�,
; then converts this input into a string storing four digits maximum. The output,
; a string, should contain the <null> terminated hexadecimal representation of the
; input value in ASCII.
;
; Operation:
; The function shifts each digit left and writes it to string.
;
; Arguments:
; 'n' (AX) - 16 bit decimal to be converted.
; 'a' (SI) - Offset in SI to store the string result.
;
; Return Values: Offset in SI
;
; Local Variables:
; 	digit placeholder - BX(BL)
;	shift and loop indicies - CX(CL)
; Shared Variables:
; Global Variables:
;
; Input:
; Output:
;
; Error Handling:
;
; Registers Changed: Flags, AX, BX, CX
; Stack Depth: 2 bytes
;
; Algorithms:
; Data Structures:
;
; Known Bugs:
; Limitations:
;
; Revision History:
; 05/01/09 William Fan
;	Repackage for final release.
; 02/15/09 William Fan
;	Added include file.
;	Shortened comments.
; 01/31/09   William Fan

Hex2String      PROC        NEAR
                PUBLIC      Hex2String

StrIndexInit:
	PUSH	SI					;address of the start of the string

LoopInit:
	MOV	CL,	12					;for the first digit, we want to shift down by 12.
	;JMP LoopCheck					;go into the loop

LoopCheck:
	CMP	CL,	0					;check if the shift index is less than 0
	JL	Break					;we're done
	;JGE	HexIteration				;if not, we should continue

HexIteration:
	MOV	BX, AX
	SHR	BX,	CL					;shift right by the shift index in CL
	AND	BX,	SIXTEEN_MASK		;use hex mask with AND to remove 3 digits
	CMP	BX,	10					;need to wrap around if >=10
	JL	DigitNineMinus
	;JGE	DigitTenPlus

DigitTenPlus:
	ADD	BL,	('A' - 10)			;convert to ASCII and add to string
	MOV	[SI], BL
	JMP	LoopUpdate

DigitNineMinus:
	ADD	BL, '0'					;convert the digit to ASCII and add to string
	MOV	BYTE PTR [SI],	BL
	;JMP	LoopUpdate

LoopUpdate:
	INC	SI						;string index moves forward
	SUB	CL,	4					;shift index-4 so we can get the next digit
	JMP	LoopCheck				;check conditions then keep iterating

Break:
	MOV	BYTE PTR [SI],	NULL	;null termination of the output string
	POP	SI						;string index back to start of the string

	RET

Hex2String	ENDP

CODE    	ENDS

			END
