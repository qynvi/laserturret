; constant.inc
;
; Description:
; Defines general logical constants and other useful values.

; Revision History:
; 05/01/9 William Fna
;	-Repackage for final release.
; 04/10/09 William Fan
;	-Updated for parsing.
; 03/08/09 William Fan
;	-Copied for serial IO ops.
;	-Added TRUEBIT
;	-Changed header description.
; 02/28/09 William Fan
;	-Moved NULLSEG to disp.inc
; 02/25/09 William Fan
;	-Revised TRUE/FALSE values.
;	-Added TRUEBYTE for Keypad.
; 02/15/09 William Fan

NULL			EQU	0			;null, can be compared or append/prepend things

TRUEBYTE		EQU	0FFh		;TRUE logical value (byte)

TRUEBIT			EQU 1			;TRUE logical value (bit)

TRUEWORD		EQU	1			;TRUE logical value (word)
FALSEWORD		EQU	0000		;FALSE logical value (word)

TRUE			EQU	0FFFFh		;TRUE logical value (for converts)

TRUCOMM			EQU 1			;TRUE and FALSE logical values for the command routine
FLSCOMM			EQU 0

SIXTEEN_MASK	EQU	0Fh			;hex mask (need this to AND rotated bits)

MAXWVALP		EQU 32767		;define max converted absolute value of signed words
MAXWVALN		EQU 32768
