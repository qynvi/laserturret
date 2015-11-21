;-----------------------------------------------------------------------------------------------------------
; Command Include File
;
; This file contains essential definitions for translating, parsing, and executing command board commands.
;
; Includes the following resources:
;	-Constants for brightness, the default error code, and the maximum length of error/command strings.
;-----------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	- Repackage for final release.
; 04/01/09 William Fan

BRIGHTNESS_LO 		EQU 3Bh  ;decrease brightness (exact key on keypad)
BRIGHTNESS_HI      	EQU 37h  ;increase brightness (exact key on keypad)
; Serial parsing does not work for this command, so these are
; the actual keycodes for the keys labeled with these
; commands, and I use CMP to branch off the handling
; of these independently from the normal parsing routine

COMM_MAX_LEN   		EQU 7  	;maximum length of command

ERROR_MAX_LEN  		EQU 12 	;maximum length of error

SERIAL_ERROR_CODE 	EQU -1 	;serial default error
