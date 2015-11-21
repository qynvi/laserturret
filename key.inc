;--------------------------------------------------------------------------------------------------------
; Keypad Include File
;
; This file contains essential keypad definitions for the RoboTrike 188 4x4 keypad.
;
; Includes the following resources:
;	-Constants for row masking/value manipulation/key scanning/debouncing routines.
;----------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	- Repackage for final release.
; 04/01/09 William Fan
;	- Removed the struc.
;	- Added auto-repeat timer.
;	- Added command board UI elements.
;	- Updated comments.
; 02/25/09 William Fan
;
;Key
KEYCODEDFLT		EQU	0			;default code on null keypress
KEYSPERROW		EQU 4			;number of keys in each row of the keypad
KEYFLAGGER		EQU	80h			;the flag bit that ensures we have a non-null keycode
NOKEY			EQU	0Fh			;constant definition for no keypress read
;
;Row
ROWDFLT			EQU	0			;the row value for no keys pressed, also represents first row on 4x4 keypad
NUMROWS			EQU 4			;the keypad has 4 rows total
;
;Debouncing
DBTHRSHLD		EQU	20			;the time in tmr2 counts from when a key is pressed until when it counts as debounced (here 20 ms)
RPTHRSHLD		EQU 1000		;the time in tmr2 counts from when a key is pressed until it beings auto-repeat (here 1s)
;
; Command
ROWSTRIP      	EQU 00001111b	;masks off the row ID digit from 2 digit keycode
KEYSTRIP       	EQU 00110000b   ;masks off the key ID digit from 2 digit keycode
