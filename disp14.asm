	NAME	DISPLAY14

;--------------------------------------------------------------------------------------------------------------------------------------------
; RoboTrike 14 Segment Display Routine
;
; The display functions for the RoboTrike.
;
; Contains the initialization function for the display buffer, mux scaling, and scroll loops.
; DispInit - Initializes display buffer to all null, resets the position of display buffer index, and loads default values.
;
; Contains routines to buffer input as a 14-segment pattern into display buffer.
; Display - Buffers a null terminated string in ES:SI into display buffer as 14-segment LED pattern.
; DisplayNum - Buffers a signed (5 digits and sign) 16-bit decimal into display buffer by Dec2String.
; DisplayHex - Buffers an unsigned (4 digits no sign) 16-bit hexadecimal into display buffer by Hex2String.
;
; Contains event handler driven multiplexing code for the physical LED segments.
; DMuxer - Displays digits; event handler muxes LED segments every 2304 timer 2 (1 KHz) counts.
; DMuxUp - Absolute upscale muxing rate to 100 percent. Has the effect of making the display appear brightest.
; DMuxDwn - Absolute downscale muxing rate to 50 percent. Has the effect of making the display appear less bright.
;----------------------------------------------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/26/09 William Fan
;	-Updated for command board main loop.
; 04/01/09 William Fan
;	-Updated comments.
; 03/04/09 William Fan
;	-Made 14 segment compatible.
; 02/16/09 William Fan
;	-One additional include file.
;	-Code/comment formatting.
; 02/14/09 William Fan


$INCLUDE(disp.inc)
$INCLUDE(constant.inc)
$INCLUDE(188val.inc)


CGROUP	GROUP   CODE

DGROUP	GROUP   DATA


CODE	SEGMENT	PUBLIC	'CODE'


        ASSUME 	CS:CGROUP
		ASSUME	DS:DGROUP

		;external public function declarations
		EXTRN   Dec2String:NEAR		;string output routines
		EXTRN   Hex2String:NEAR

		EXTRN   ASCIISegTable:BYTE	;ASCII and digit segment maps
		EXTRN   DigitSegTable:BYTE


; DispInit
;
; Description:
; Initializes the display routines by blanking every entry of the display buffer and resetting
; the display buffer tracking pointer to its default position.
;
; Operation:
; Loops through every entry of DBuffer with nulls. Then sets NomDigit to 0.
;
; Arguments:       					None
;
; Return Values:					None
;
; Local Variables: 					[AX] - iteration counter

; Shared Variables:
;	DBuffer - native, word - segment buffer, nominal digit's entry is shown on LED
;	NomDigit - native, word - index of DBuffer
;	DScrollPos - native, word - tracks position of muxed LED segments with regard to 1 Hz auto-scroll
;	DScrollTmr - native, word - software loop timer to 500 counts before DScrollPos is incremented
;	DMuxBase - native, byte - denominator of muxing "duty cycle" ratio
;	DMuxScale - native, byte - numerator of muxing "duty cycle" ratio

; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				AX, BX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/04/09 William Fan

DispInit	PROC	NEAR
			PUBLIC	DispInit

DBufferInit:
	MOV 	AX, 0 					;initialize an iteration counter to 0
    MOV  	NomDigit, BFFR_DFLT_POS	;buffer's nominal digit index starts at 0

DBufferIterate:
	;must use WHILE loop instead of REPEAT for more accurate value in DBFFR_MAXLEN, less redundancy
	CMP		AX, DBFFR_MAXLEN		;check if we've iterated every entry
	JGE		DSpecialInit			;if less, then repeat until we've nulled every digit
    MOV 	BX, AX                  ;move the AX count into BX for multiplication
    SHL 	BX, 1                  	;correct index is x2 because DBuffer will have words
    MOV 	DBuffer[BX], NULL_SEG 	;move a null segment into the nominal DBuffer digit entry
    INC 	AX                     	;increment the iteration counter
	JMP		DBufferIterate			;reiterate the WHILE condition

DSpecialInit:
	;initialize special functions of the display - autoscroll and brightness adjustment
	MOV 	DScrollPos, 0			;reset position offset for scroll (digits should first light at default location)
	MOV 	DScrollTmr, 0			;reset scroll timer counter
	MOV 	DMuxBase, 0	       		;reset muxing duty cycle counter
	MOV 	DMuxScale, DMUXFULL		;we should mux at 100 percent to appear at maximum brightness default

DispInitFin:
    RET

DispInit	ENDP


; Display(str)
;
; Description:
; Buffers a null terminated string as a segment pattern.
;
; Operation:
; Adds each character of a string into DBuffer by xlating it from a segment table.
;
; Arguments:
; str - string passed by reference in ES:SI
;
; Return Values:					None
;
; Local Variables: 					[AX] - accumulator
;							[BX] - DBuffer custom index
;
; Shared Variables:
;	DBuffer - native, word - segment buffer, nominal digit's entry is shown on LED
;
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, BX, CX, DI, SI
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations:
;	- The string's representation may not be too long for DBuffer. All outstanding characters are truncated.
;
; Revision History:
; 04/27/09 William Fan
;	- Fixed possible bug in messing up the DBuffer with trash data.
;	- Updated comments.
; 03/04/09 William Fan

Display		PROC	NEAR
			PUBLIC  Display

	MOV		BX, 0							;reset length tracker of accumulated data in DBuffer

DXlatChk:
	MOV 	AX, 0             				;reset the accumulator before reiterating addition ops
	MOV 	AL, ES:[SI]						;store current digit in AL so we can compare
	CMP 	AL, NULL                       	;digit ?= NULL (Hex/Dec2Str should be null terminated)
	JE  	DXlatFin   						;IF it's null, put a null there and kill the process
											;ELSE, translate the digit
	CMP 	BX, DBFFR_MAXLEN               	;truncate any digit exceeding length of the DBuffer itself
	JGE 	DXlatFin						;truncate by just terminating the translation routine
	;JMP		DDigitXlat							;if pass these checks, convert str to pattern

DDigitXlat:
	XOR 	CH, CH                 			;clear CX
	MOV 	CL, ES:[SI]						;lower byte of CX holds ES:SI
	SHL 	CX, 1                        	;x2 since words are 2 bytes to compensate the index
	MOV 	DI, CX                         	;index of segtable into DI, then xlat into DX since AX is accumulator right now
	MOV 	DX, WORD PTR CS:ASCIISegTable[DI]
   SHL 		BX, 1
   MOV  	DBuffer[BX], DX              	;store the retrieved pattern in DBuffer corresponding entry
   SHR 		BX, 1                       	;"unmultiply" BX
   INC 		BX                         		;grow the length tracker
   INC 		SI                              ;move index to next char
   JMP 		DXlatChk						;reiterate the WHILE loop

DXlatFin:
   CMP 		BX, DBFFR_MAXLEN				;we are done xlating, but check if we are on null digits
   JGE  	DispFin							;if not, return so we don't destroy the DBuffer
   MOV 		AX, BX
   SHL 		BX, 1							;x2 since words are 2 bytes to compensate the index
   MOV 		DBuffer[BX], NULL_SEG       	;put a null segment into this digit in the display buffer
   MOV 		BX, AX                      	;restore BX to track the length
   INC 		BX                             	;increment BX to the next char
   JMP 		DXlatFin						;reiterate the WHILE loop

DispFin:
   RET

Display   	ENDP


; DisplayNum(n)
;
; Description:
; Buffers 16-bit signed decimal for display into 5 digits plus sign.
;
; Operation:
; Adds each character of a string converted by Dec2String
; into SBuffer natively, then into DBuffer using Disp().
;
; Arguments:
; 	n - 16bit decimal (signed) passed in AX to be displayed
;
; Return Values:
; Segment pattern to LED display (5 digits plus sign) of passed decimal (n).
;
; Local Variables: 					None
;
; Shared Variables:
;	SBuffer - native, byte - string holding buffer
;
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, DS, ES, SI
; Stack Depth: 					1 word
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/04/09 William Fan

DisplayNum	PROC	NEAR
			PUBLIC 	DisplayNum

DispDPrep:
	MOV  	SI, OFFSET(SBuffer)
	CALL 	Dec2String         	;use Dec2String to convert 16-bit (+/-) dec num into string

DispDStr:
	PUSH 	DS               	;recall that Disp's str is passed by reference in ES:SI
	POP  	ES					;much smarter way of doing this than in Disp7
	MOV  	SI, OFFSET(SBuffer)
	CALL 	Display           	;use Disp to buffer the resulting string for DMuxer

DispNumFin:
	RET

DisplayNum 	ENDP


; DisplayHex(n)
;
; Description:
; Buffers 16-bit hexadecimal for display into 4 hex digits unsigned.
;
; Operation:
; Adds each character of a string converted by Hex2String
; into SBuffer natively, then into DBuffer using Disp().
;
; Arguments:
; 	n - 16bit hexadecimal (unsigned) passed in AX to be displayed
;
; Return Values:
; Segment pattern to LED display (4 digits) of passed hexadecimal (n).
;
; Local Variables: 					None
;
; Shared Variables:
;	SBuffer - native, byte - string holding buffer
;
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, DS, ES, SI
; Stack Depth: 					1 word
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/04/09 William Fan

DisplayHex	PROC	NEAR
			PUBLIC 	DisplayHex

DispHPrep:
	MOV 	SI, OFFSET(SBuffer)
	CALL 	Hex2String 			;use Hex2String to convert 16-bit hex num into string

DispHStr:
	PUSH 	DS               	;recall that Disp's str is passed by reference in ES:SI
	POP  	ES					;much smarter way of doing this than in Disp7
	MOV  	SI, OFFSET(SBuffer)
	CALL	Display           	;use Disp to buffer the resulting string

DispHFin:
	RET

DisplayHex	ENDP


; DMuxer
;
; Description:
; Multiplexes the LED display under interrupt control. Displays the segments.
;
; Operation:
; Translates digits sequentially from the segtable by entries in DBuffer pointed to by NomDigit.
; It will wrap around if it sees a null. The high byte of the seg pattern is written to the address in
; SEG14LOC, which represents the additional diagonal segments in 14-segment displays. The remaining
; byte is written to the usual location of LEDLoc incremented by NomDigit.
;
; Arguments:       					None
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables:
;	DBuffer - native, word - segment buffer, nominal digit's entry is shown on LED
;	NomDigit - native, word - index of DBuffer
;	DScrollPos - native, word - tracks position of muxed LED segments with regard to 1 Hz auto-scroll
;	DScrollTmr - native, word - software loop timer to 500 counts before DScrollPos is incremented
;	DMuxBase - native, byte - denominator of muxing "duty cycle" ratio
;	DMuxScale - native, byte - numerator of muxing "duty cycle" ratio
;
; Global Variables: 				None
;
; Input: 						None
;
; Output:
; Writes to the LED display and additional segments on the 14-segment display.
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, BX, CX, DX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations:
; For the display to work, NUM_DIGITS must be a power of 2, otherwise the display will not wrap after NomDigit exceeds the entire display.
; For scrolling to work, DBFFR_MAXLEN must be a power of 2, otherwise it will scroll off the screen and not wrap.
; For brightness to work, DMUXFULL must be a power of 2, otherwise brightness will stop changing.
;
; Revision History:
; 04/29/09 William Fan
;	- Fixed problems with auto-scroll.
;	- Updated comments.
; 03/04/09 William Fan

DMuxer	PROC	NEAR
		PUBLIC 	DMuxer

DMuxScrollChk:
	INC 	DScrollTmr   						;when called per tmr2 IRQ, inc scroll timer towards DSCROLL_MCNT
	CMP 	DScrollTmr, DSCROLL_MCNT         	;check if we are at the max count
	JNE 	DMuxBrightChk                   	;if not, keep all digits in their place
	;JE		DMuxScroll							;if so, scroll everything to the left

DMuxScrollDo:
	MOV 	DScrollTmr, 0                    	;first reset the scroll timer before we scroll
	ADD 	DScrollPos, 2						;move everything by a word (because word not byte, needs 2)
	AND 	DScrollPos, (2 * DBFFR_MAXLEN - 1)	;wrap when we scroll to the left edge (only works when DBFFR_MAXLEN is ^2)

DMuxBrightChk:
   	INC 	DMuxBase               				;inc the mux ratio base count (see how we do PWM for motors)
    AND 	DMuxBase, DMUXFULL - 1				;wrap with respect to the max brightness scaler

DMuxBrightDo:
	;This brightness changing implementation is based on the physical phenomenon of persistence of vision.
	;By natively downscaling muxing frequency we can be made to perceive a lower relative contrast, which makes
	;the digit appear less bright
    MOV 	AL, DMuxScale                 		;load the mux scaler for comparison step
	CMP 	DMuxBase, AL               			;check if DMuxBase is below DMuxScale
	JL 		GetSeg                    			;if it's less, we mux the digit, otherwise, we don't
	JGE 	WrapDisplay          				;if it's more or equal, skip muxing this digit this cycle

GetSeg:
    MOV     DX, LEDLoc           				;load the address of the LED display
    ADD     DX, NomDigit                		;inc by offset of current digit
    MOV     BX, NomDigit						;store current digit for multiplication
    SHL     BX, 1                  				; BX = BX * 2 (DBuffer is words)
	ADD     BX, DScrollPos						;inc by the scroll position if we have scrolled the digits
	AND     BX, (2 * DBFFR_MAXLEN - 1)			;wrap by the display buffer max length if this exceeds
    MOV     AX, DBuffer[BX]      				;retrieve corresponding segment from DBuffer by BX into AX

DisplaySeg:
    MOV     CX, DX               				;DX contains address - store into CX before OUT
    XCHG    AL, AH                  			;AX contains seg, swap high byte to light first
    MOV     DX, SEG14LOC     					;load the address of the 14 segment segments
    OUT     DX, AL								;write to 14 segment segments
    MOV     DX, CX                  			;restore DX to the usual value we write segs to
    XCHG    AL, AH                				;now swap in low byte to light
    OUT     DX, AL              				;write to 7 segment segments

WrapDisplay:
    INC     NomDigit                   			;point to the next digit in DBuffer
    AND     NomDigit, (DBFFR_MAXLEN - 1) 		;wrap nominal digit to point back to first if neccessary

DMuxerFin:
    RET

DMuxer   ENDP


;DMuxUp
;
;Description:
; Upscales muxing duty cycle. This has the effect of making the digits appear
; bright.
;
;Operation:
; Moves value into DMuxScale to mux at 100 percent. All digits should appear at
; max brightness.
;
;Shared Variables:
;	DMuxScale - native, byte - numerator of muxing "duty cycle" ratio
;
; Revision History:
; 03/04/09 William Fan

DMuxUp		PROC NEAR
			PUBLIC DMuxUp

	MOV		DMuxScale, DMUXFULL
	RET

DMuxUp  	ENDP


;DMuxDwn
;
;Description:
; Upscales muxing duty cycle. This has the effect of making the digits appear
; bright.
;
;Operation:
; Moves value into DMuxScale to mux at 100 percent. All digits should appear at
; max brightness.
;
;Shared Variables:
;	DMuxScale - native, byte - numerator of muxing "duty cycle" ratio
;
; Revision History:
; 03/04/09 William Fan

DMuxDwn		PROC NEAR
			PUBLIC DMuxDwn

    MOV  	DMuxScale, DMUXHALF
	RET

DMuxDwn		ENDP


CODE 	ENDS


;the data segment
DATA	SEGMENT PUBLIC	'DATA'

	;display routine temporary storage buffers
	SBuffer   	DB NUM_DIGITS	 DUP (?) ;string buffer (stores strings)
	DBuffer		DW DBFFR_MAXLEN  DUP (?) ;display buffer (stores patterns)

	;display routine variables
	NomDigit   	DW ?                     ;the nominal digit (poss. values per entry of DBuffer, 0-8)
	DMuxBase   	DB ?                     ;denominator of muxing "duty cycle" ratio

	;special function (extra credit 4) variables
	DMuxScale 	DB ?                     ;numerator of muxing "duty cycle" ratio
	DScrollPos	DW ?    				 ;tracks position of muxed LED segments with regard to 1 Hz auto-scroll
	DScrollTmr	DW ?      				 ;software loop driven timer to 500 counts before DScrollPos is incremented thus scrolling all digits

DATA    ENDS


		END
