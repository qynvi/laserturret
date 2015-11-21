		NAME	InitCS


$INCLUDE(188val.inc)


CGROUP  GROUP   	CODE

CODE	SEGMENT 	PUBLIC 'CODE'

        ASSUME  	CS:CGROUP


; InitCS
;
; Description:
; Initializes chip selects for the 80188.
;
; Operation:
; Writes control value bits to the addresses of the PACS and MPCS registers.
;
; Arguments:       					None
;
; Return Values:					None
;
; Local Variables: 					None
; Shared Variables: 				None
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, DX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/26/09 William Fan
;	-Seperated from 188tievh.asm.
; 03/04/09 William Fan
;	-Updated comments.
; 03/03/09 William Fan
;	-Chip select.
;	-Updated comments to match changes.

InitCS	PROC 	NEAR
		PUBLIC	InitCS

WritePACSreg:
	XOR			AX, AX			;clear AX
	MOV			AX, PACSctrlV	;store control value
	MOV			DX,	PACSregLoc	;store address of the PACS register
	OUT			DX, AL			;write the bit to the register of PACS

WriteMPCSreg:
	XOR 		AX, AX			;clear AX
	MOV			AX, MPCSctrlV	;store control value
	MOV			DX, MPCSregLoc	;store address of the MPCS register
	OUT 		DX, AL			;write the bit to the register of MPCS

WriteCSRegFin:
	RET

InitCS			ENDP


CODE			ENDS


				END
