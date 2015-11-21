; display.inc
;
; Description:
; Defines values for constants and addresses related to
; muxing LED segments. Contains default values for
; Disp14's special functions as well as its ability
; to do 14 segment displays.

; Revision History:
; 05/01/09 William Fan
;	- Repackage for final release.
; 03/09/09 William Fan
;	- New version for 14-segment display.

;14 segment address
SEG14LOC   		EQU 8       ;for 14-segment display, the higher
                            ;byte is written to this port instead of LEDLoc

;display buffer constraints
NUM_DIGITS		EQU	8      	;number of digits in the display
DBFFR_MAXLEN    EQU 16		;2x8 = 16 for compatibility with auto-scroll

;default values for display init
NULL_SEG		EQU	0		;blank segment value
BFFR_DFLT_POS 	EQU 0      	;it is the first index of the display

;special abilities

;display brightness adjustment
;these must be power of 2 (values chosen experimentally, may not be optimal)
DMUXFULL   		EQU	32    	;scaler for max brightness
DMUXHALF  		EQU	16    	;scaler for less brightness

;display auto-scroll
DSCROLL_MCNT 	EQU	1000 	;display scroll timer maxcount of 1000 timer 2
							;muxing interrupts before scroll (scroll per 1 sec)
