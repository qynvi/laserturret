		NAME	DEC2STRING

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP

$INCLUDE(constant.inc)

; Numeric Conversion Functions
; Dec2String
;
; Description:
; This function accepts input as a 16-bit signed decimal value as �n�,
; then converts this input into a string storing six digits maximum plus
; sign. The output, a string, should contain the <null> terminated decimal
; representation of the input value in ASCII.
;
; Operation:
; Using decimal powers, the function iterates through each digit of the input.
; For each digit that is not a leading zero, it converts and writes that digit into
; string. Finally, it adds a null termination.
;
; Arguments:
; 'n' (AX) - 16 bit decimal to be converted.
; 'a' (SI) - Offset in SI to store the string result.
;
; Return Values: Offset in SI
;
; Local Variables:
; 	pwr10 - BP (we don't have to use 1000 like in the outline)
; 	loop counter - DI
; 	digit - AX
;	boolean - BX (takes values of false or true)
;	number - CX
; Shared Variables:
; Global Variables:
;
; Input:
; Output:
;
; Error Handling:
;
; Registers Changed: Flags, AX, BX, CX, DX, DI
; Stack Depth: 4 bytes
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

Dec2String      PROC        NEAR
                PUBLIC      Dec2String

	PUSH	SI					;SI stores start of the string
	PUSH	BP					;store BP - we'll need this to manipulate digits later
	MOV	BP,	10					;pwr10 becomes BP
	MOV	CX,	AX
	MOV	BX,	FALSEWORD
	CMP	CX, 0					;IF branch check to see if 'n' is negative
	JGE	LoopInit				;IF >= 0, go to the digit interation. (SF = OF)
	;JL	nNegative

nNegative:
	MOV	BYTE PTR [SI],	'-'		;manually append "-" sign to string
	INC	SI						;move the string index to the next byte
	NEG	CX						;if negative, negate so can convert it anyways
	;JMP	LoopInit					;start iterating digits

LoopInit:
	MOV	DI,	10000				;initialize pwr10 to look at first digit
	;JMP	DecIteration

DecIteration:
	CMP	DI,	0					;confirm pwr10 is above 0.
	JE	Break					;if it is not, we are done iterating
	;JMP	MainLoop					;ELSE we need to keep iterating, using the loop

MainLoop:
	MOV	AX,	CX					;number goes to both AX and CX (so we can divide)
	MOV	DX,	0
	DIV	DI						;pwr10 to divide number and isolate digits
	MOV	DX,	0
	DIV	BP						;store the remainder from DX to AX
	MOV	AX,	DX					;current digit
	CMP	BX,	TRUE				;check if we've written a number today
	JE	Write					;write the digit
	CMP	AX,	0
	JE	Update					;leading zeroes - move on to the next digit
	;JNE	Write					;ELSE, we attempt to write the digit

Write:
	ADD	AX,	'0'					;convert the current digit to ASCII
	MOV	[SI], AX				;write the current digit to the string
	MOV	BX,	TRUE
	INC	SI						;move the string index to the next byte
	;JL Update						;update the digit counter

Update:
	MOV	AX,	DI					;update iteration (pwr10) if digit down
	MOV	DX,	0
	DIV	BP
	MOV	DI,	AX					;newly reduced pwr10 (iteration counter)
	JMP DecIteration			;restart iteration from top
	;JL Break						;otherwise, terminate the loop

Break:
	CMP	BX,	TRUE				;confirm BX is nontrivial
	JE	Dec2Stringed
	;JNE	ZeroPadding				;if not, we need to pad zeroes

ZeroPadding:
	MOV	BYTE PTR [SI],	'0'		;force write a zero
	INC	SI						;move the string index to the next character

Dec2Stringed:
	MOV	BYTE PTR [SI],	NULL	;null termination of the output string
	POP	BP
	POP	SI						;string index returns to offset of start of string

	RET

Dec2String	ENDP

CODE    ENDS

        END
