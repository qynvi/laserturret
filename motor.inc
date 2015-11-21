;--------------------------------------------------------------------------------------------------------
; Motor Include File
;
; Includes constants and control values used in the pulsing and muxing of motors on
; the 188 RoboTrike.
;----------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
; - Repackage for final release.
; 04/26/09 William Fan
; - Revised laser and stepper definitions.
; - Moved all 8255 and corresponding ctrl values
;   to this file from general 188 include.
; - Updated comments.
; 04/14/09 William Fan
; - Updated comments.
; 03/06/09 William Fan

;Parallel
ParalellLoc		EQU		0180h				;8255 controller's address location
PrlPrtA			EQU		ParalellLoc + 0		;address of paralell port A
PrlPrtB			EQU		ParalellLoc + 1		;address of paralell port B (MOTOR, LASER)
PrlPrtC			EQU		ParalellLoc + 2 	;address of paralell port C (STEPPER)
PrlPrtCtrl		EQU 	3 + ParalellLoc		;address of 8255 control
PrlPrtCtrlV		EQU		10000000b			;control value on the parallel port
											;1xxxxxxx enable
											;x000xxxx group A/C I/O (reserved)
											;xxxx0000 group B/C I/O (reserved)

;PWM Motors
NUM_MTRS		EQU		3					;number of PWM motors to mux

PWMINCNT		EQU		0					;lower bound of PWM tracking counter
PWMAXCNT		EQU		127					;upper bound of PWM tracking counter

MTRMINSPD		EQU		0					;lower bound of user input for speed
MTRMAXSPD		EQU		65534				;upper bound of user input for speed
MTRNULLSPD		EQU		65535				;user input for canceling speed change
MTRMINANGL		EQU		-32767				;lower bound of user input for angle orientation
MTRMAXANGL		EQU		32767				;upper bound of user input for angle orientation
MTRNULLANGL		EQU		-32768				;user input for canceling angle change
MTRANGLCMP		EQU		360					;motor angle compare value

; Turret Definitions
STPTBL_XDFLT 	EQU 	4					;default position of the index of the stepper table of bits
STPTBL_LEN 		EQU 	8					;length of the stepper control bit table
STP_SCL    		EQU 	9       			;half step to degree ratio, scaler component (9/5)
STP_DVSR    	EQU 	5      			    ;half step to degree ratio, divisor component (9/5)

; Laser Definitions
LaserTRUE		EQU		1					;true state for the laser
LaserFALSE		EQU		0					;false state for the laser
LASERSET		EQU 	80h					;laser state control bit (mask it in)
