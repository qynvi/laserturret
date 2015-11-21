	NAME	SLV

;----------------------------------------------------------------------------------------------------------------------------------------
; RokoTrike188 Slave Board User Interface

; Contains the routines that are called at the slave board by the command board via serial and parses those
; commands using the serial parser in order to execute the corresponding motor or turret command. It also
; checks and updates the command board on the occurance of serial errors.
;
; Slave - Receives command board SerialPutChar and executing serial parsing. Updates serial error.
;------------------------------------------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/02/09 William Fan
;	- Repackage for final release.
; 04/15/09 William Fan


$INCLUDE(serial.inc)
$INCLUDE(constant.inc)
$INCLUDE(command.inc)


CGROUP		GROUP   CODE

DGROUP  	GROUP   DATA

CODE  		SEGMENT PUBLIC 'CODE'

			ASSUME  CS:CGROUP
			ASSUME	DS:DGROUP


			EXTRN SerialInRdy:NEAR
			EXTRN SerialGetChar:NEAR
			EXTRN SerialPutChar:NEAR
			EXTRN ParseSerialChar:NEAR


; Slave
;
; Description:
; When the command board sends a command over serial upon keypress, this routine is responsible
; for executing that command.
;
; Operation:
; Verifies serial readiness, calls serial routines to get the command char, parse that command, out
; reply to command with SerialPutChar of serial error.
;
; Input: 					Serial (command)
;
; Output: 					Serial (command)
;
; User Interface: 				None
;
; Error Handling:
; Serial errors are reported to the command board for display on its 14-segment display.
;
;Shared Variables: 			None
;
; Registers Changed: 			Flags, AX, BX, CX, DX, ES, SI
;
; Stack Depth:				None
;
; Revision History:
; 04/15/09 William Fan

Slave		PROC 	NEAR
			PUBLIC 	Slave

SlaveSrlGet:
    ;before we do anything else, confirm that serial is ready, since all we do is parse commands
    CALL 	SerialInRdy
    JZ  	SlaveFin		;if serial is not ready, we skip SerialGetChar dequeue from Rx queue
    CALL 	SerialGetChar  	;retrieve serial character from Rx queue
    CALL 	ParseSerialChar	;parse for the corresponding command

SlaveSrlErr:
    CMP 	AL, SERIAL_ERROR_NULL
    JE 		SlaveFin		;when no serial error detected from the previous serial routines, terminate
    MOV 	AL, SERIAL_ERROR_CODE
    CALL 	SerialPutChar	;otherwise, call to display default serial error string

SlaveFin:
	RET

Slave 		ENDP


CODE 		ENDS


;the data segment
DATA    	SEGMENT PUBLIC  'DATA'

DATA    	ENDS


			END
