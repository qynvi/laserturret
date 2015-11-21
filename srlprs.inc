; srlprs.inc

; Include file for serial parsing functions. Defines states, tokens, and commands as
; used in lookups of parsed serial characters from their corresponding tables.

;Revision History:
; 05/01/2009 William Fan
;	- Repackage for final release.
; 04/01/2009 William Fan

ErrorWord		EQU	0CCH		;the value to return in case of error

NUM_TOKEN_TYPES EQU 7

TOKEN_MASK		EQU	01111111B	;mask to 7 bits

;State List
ST_MAIN			EQU	0			;main state, idle, default, resets to this
ST_MOVE 		EQU	1			;motors
ST_SIGN 		EQU	2			;sign
ST_NUMBER		EQU	3			;value
ST_LASER 		EQU 4			;laser
ST_ERROR		EQU	5			;problem

;Token List
TKN_LSRCMD		EQU	0			;laser
TKN_MTRCMD		EQU 1			;motor
TKN_SIGN		EQU	2			;sign
TKN_NUM			EQU	3			;value
TKN_EOC			EQU	4			;end of command
TKN_STALL		EQU	5			;waste time
TKN_MISC		EQU	6			;other stuff

;Command List
CMD_SPD			EQU	0			;absolute speed
CMD_RSPD		EQU	1			;relative speed
CMD_TURN		EQU	2			;orientation
CMD_TRT			EQU	3			;absolute turret angle
CMD_RTRT		EQU	4			;relative turret angle
