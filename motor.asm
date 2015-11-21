		NAME  MOTOR

;-----------------------------------------------------------------------------------------------------------------------------------
; RoboTrike Motor Routine

; 	The motor functions for the RoboTrike.

; InitMotor - Initializes motor functions by putting initial values in all variables.
; InitParallel - Initializes parallel interface with initial values.
; SetMotorSpeed(speed,angle) - Sets RoboTrike aboslute speed and orientation.
; GetMotorSpeed - Obtains speed in AX.
; GetMotorDirection - Obtains orientation in angle in AX.
; SetTurretAngle(angle) - Sets RobotTrike laser turret absolute unsigned orientation.
; GetTurretAngle - Obtains laser turret angle orientation in AX.
; SetRelTurretAngle(angle) - Sets RoboTrike laser turret relative unsigned orientation.
; SetLaser(on/off) - Sets control bits to turn RoboTrike turret laser on or off.
; GetLaser - Obtains laser on or off bit status in AX.
;
; 	The lookup tables for RoboTrike motor pulsing routines.
;
; StepMtrBits - Converts stepper motor steps into 4-bit patterns to write to stepper motor control.
; MtrVecDir - Indexes x and y components for each motor.
;
; 	The slave routines for RoboTrike calculations.
;
; SRangleNormS - Normalizes passed signed angle value into value between 0 and 360.
; SRangleNormU - Normalizes passed unsigned angle value into value between 0 and 360.
;-----------------------------------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
; -Repackage for final release.
; 04/26/09 William Fan
; -Revised to work much better.
; -Split InitMotor and InitParallel
; -Simplified convoluted code.
; 04/12/09 William Fan
; -Eliminated SRcalcPW and integrated the function into SetMtrSpd.
; 04/10/09 William Fan
; - Code re-arranging.
; 03/31/09 William Fan
; - PWM implementation #2
; - Code cleanup.
; 03/17/09 William Fan
; - More documentation.
; - PWM implementation #1 (failed)
; 03/06/09 William Fan


$INCLUDE(motor.inc)
$INCLUDE(188val.inc)


CGROUP  GROUP   CODE
DGROUP	GROUP   DATA


;code segment - operational code and slave functions
CODE    SEGMENT PUBLIC	'CODE'


		ASSUME  CS:CGROUP
		ASSUME	DS:DGROUP


; InitMotor
;
; Description:
; Prepares RoboTrike motor routines.

; Operation:
; Writes initial values into all variables. Forces certain functions on/off.
; Writes 8255 control values, and flushes port values.
;
; Arguments:					None
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables:
;	LaserState		- binary definition of laser on/off status in nominal iteration
;	MtrCSpeed		- current speed, constrained between MTRMAXSPD and MTRMINSPD, or MTRNULLSPD
;	MtrCAngle      	- current orientation, constrained between (normalized) 0 and 360 relative to current heading
;	MtrPWval       	- array, motor time on for each motor, signed
;	PWThrshldCnt  	- pulse time limit for motors, constrained between PWMINCNT and PWMAXCNT
;	TrtCAngle     	- current orientation of turret, constrained between (normalized) 0 and 359 relative to current heading
;	TrtNumStp       	- counter tracking remaining number of steps (half-steps) relative to nominal step for stepper motor, signed
;	TrtStpX     		- stepper table lookup index bookmark
;
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, BX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 04/26/09 William Fan
;	- Revised to use an array to track PW for each motor.
;	- Revised to perform fewer calculations.
;	- Revised structures, manipulations to be less convoluted.
; 03/06/09 William Fan

InitMotor	PROC    NEAR
            PUBLIC  InitMotor

    MOV     BX, 0
	MOV     PWThrshldCnt, PWMINCNT	;set starting PW counter threshold to zero

IMInitialValues:
    MOV     MtrCSpd, MTRMINSPD		;set starting speed to zero
    MOV     MtrCAngl, 0				;set starting orientation to forward
    MOV     TrtCAngl, 0				;set starting turret facing to forward
    MOV     LaserState, LaserFALSE	;set starting laser state to off

IMPWPrep:
    CMP     BX, NUM_MTRS 			;instead of usual REPEAT, do a WHILE iteration here for 3 motors
    JE      IMStepPrep
    MOV     MtrPWval[BX], PWMINCNT	;all motors should have no queued pulses
    INC     BX
    JMP     IMPWPrep

IMStepPrep:
    MOV     TrtNumStp, 0			;turret stepper should have no queued steps
    MOV     TrtStpX, STPTBL_XDFLT	;set stepper table lookup to middle of the table

InitMotorFin:
    RET

InitMotor	ENDP


; StepMtrBits
;
; Description:
; Consecutive sequential lookup table for stepper motor. Converts
; nominal step label into 4-bit patterns for stepper in cc direction.
;
; Reference:
;	- InitParallel
;	- TStepper
;
; Revision History:
; 03/12/09 William Fan

StepMtrBits	LABEL   BYTE
    DB 		1010B	;0
    DB      1000B	;1
    DB      1001B	;2
    DB      0001B	;3
    DB      0101B	;4
    DB      0100B	;5
    DB      0110B	;6
    DB      0010B	;7


; InitParallel
;
; Description:
; Prepares RoboTrike parallel port.

; Operation:
; Writes 8255 control values, and flushes port values.
;
; Arguments:					None
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables:
;	TrtStpX     		- stepper table lookup index bookmark
;
; Global Variables: 				None
;
; Input: 						None
;
; Output:
; Writes to 8255 control port and ports A, B, and C with
; the control word and initial values, respectively.
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, DX, DI
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 04/26/09 William Fan
;	- Revised to use an array to track PW for each motor.
;	- Revised to perform fewer calculations.
;	- Revised structures, manipulations to be less convoluted.
; 03/06/09 William Fan

InitParallel	PROC    NEAR
                PUBLIC  InitParallel

IPPrlPrtCtrl:
	MOV 		AL, PrlPrtCtrlV			;load 8255 control value
	MOV 		DX, PrlPrtCtrl			;load address of parallel port
	OUT 		DX,	AL					;write to the control chip

IPPrlPrtA:
    MOV     	AL, 0		       		;blank port A for good measure
    MOV     	DX, PrlPrtA				;load address of parallel port A
    OUT     	DX, AL

IPPrlPrtB:
    MOV     	AL, 0              		;blank port B, turning motors and laser off
    MOV     	DX, PrlPrtB				;load address of parallel port B
    OUT     	DX, AL

IPPrlPrtC:
	XOR     	AX, AX              	;clear AH and AL
    MOV     	AL, TrtStpX				;load step table index into AL (it will point to default position)
    MOV     	DI, AX
    MOV     	AL, CS:StepMtrBits[DI]	;now write back into AL the lookuped value
    MOV     	DX, PrlPrtC				;load address of parallel port C
    OUT     	DX, AL                  ;write it to the stepper motor port

InitParallelFin:
    RET

InitParallel	ENDP


; MtrVecDir
;
; Description:
; Nominal motor direction stratified table of vectors for PW calc lookup.
;
; Reference:
;	- SetMotorSpeed
;
; Revision History:
; 04/20/09 William Fan

MtrVecDir	LABEL   WORD
   DW 		7FFFh   ;Motor = 1, <X>
   DW 		0h      ;Motor = 1, <Y>
   DW 		0C000h  ;Motor = 2, <X>
   DW 		9127h	;Motor = 2, <Y>
   DW 		0C000h  ;Motor = 3, <X>
   DW 		6ED9h   ;Motor = 3, <Y>


; SetMotorSpeed (speed,angle)
;
; Description:
; Sets speed and orientation. FFFEh is full speed while 0 is stop and 65535 indicates
; speed change cancel. Angle is a signed value in degrees with 0 as collinear with
; RoboTrike and -32768 cancels angle change.

; Operation:
; Speed passed in AX. Angle passed in BX. Reads from these two registers. Normalizes
; angle measure and turns the trike by that much when motor is next pulsed. Takes speed
; input and normalizes into pulse width between 0 and the max count.
;
; Arguments:					[AX} - Speed
;							[BX] - Angle
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables:
;	MtrCSpeed		- current speed, constrained between MTRMAXSPD and MTRMINSPD, or MTRNULLSPD
;	MtrCAngle      	- current orientation, constrained between (normalized) 0 and 360 relative to current heading
;	MtrPWval       	- array, motor time on for each motor, signed
;
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling:
; Invalid entries will be wrapped.
;
; Registers Changed: 				Flags, AX, BX, CX, DX, DI, SI
; Stack Depth: 					5 words
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
;
; Limitations:
; Cannot accurately error-handle consecutive invalid inputs in very rapid succession. Conjectured reason
; too many calculations.
;
; Revision History:
; 04/27/09 William Fan
;	- Added new limitation to outline above.
;	- Slightly simplified PW calculations.
;	- Combined X and Y PW ops into the same WHILE loop, under single label.
; 04/26/09 William Fan
;	- Revised code to track PW by array.
; 03/06/09 William Fan

				EXTRN   Sin_Table:WORD	;lookup table for sin functions
				EXTRN   Cos_Table:WORD	;lookup table for cos functions
SetMotorSpeed	PROC    NEAR
                PUBLIC  SetMotorSpeed

SetMtrSpdChk:
	CMP 		AX, MTRNULLSPD			;check if user wants to change speed
	JE 			SetMtrAnglChk			;skip directly to angle checker
	;JNE			SetMtrSpd					;otherwise, update the new speed

SetMtrSpd:
	MOV 		MtrCSpd, AX				;store speed into current speed (to be updated by MMuxer)
	;JMP			SetMtrAnglChk				;now check the angle

SetMtrAnglChk:
	CMP 		BX, MTRNULLANGL			;check if user wants to change angle
	JE			SetMtrPW
	;JE			SetMtrAnglUSign			;if no, skip speed update and go to wrapping
	;JNE		SetMtrAngl					;otherwise, update the new angle

SetMtrAngl:
	MOV			MtrCAngl, BX			;store angle into current angle (to be updated by MMuxer)
	MOV			AX, MtrCAngl			;angle ops require AX (speed is saved)
	;JMP			SetMtrAnglUSign				;make sure angle is wrapped at all times

SetMtrAnglUSign:
	CMP 		AX, 0					;check orientation of the RoboTrike
	JGE 		SetMtrAnglWrap			;if positive, wrap the angle
	NEG 		AX						;if negative, unsign the angle for now

SetMtrAnglWrap:
	CMP 		AX, MTRANGLCMP			;check if angle still requires wrapping
	JL 			SetMtrTrigOps			;if not, go to trig ops
	SUB 		AX, MTRANGLCMP			;else continuously subtract 360 (full rotations)
	JMP 		SetMtrAnglWrap			;iterate until 0 < [AX] < 360.

SetMtrTrigOps:
	MOV 		BP, OFFSET(Cos_Table) 	;point BP to offset of cosine trig table
	MOV 		SI, AX					;load angle into SI
	SHL 		SI, 1					;shift for index (table is full of words)
	MOV 		AX, CS:[BP+SI]	    	;cos(CMtrAngl) = [AX]
    MOV 		CosBuff, AX				;store into cosine buffer
	MOV 		BP, OFFSET(Sin_Table)	;point BP to offset of sine trig table
	MOV 		AX, CS:[BP+SI]			;sin(CMtrAngl) = [AX]

SetMtrSineChk:
	CMP 		MtrCAngl, 0				;check if passed angle was negative
	JGE 		SetMtrSineVal			;if positive, we go to vector ops
	NEG 		AX						;else, sin(-x)=-sin(x) (cosine doesn't have this trait)
	;JMP			SetMtrSineVal

SetMtrSineVal:
	MOV 		SinBuff, AX				;store into sine buffer
	;JMP			SetMtrVecOps

SetMtrVecOps:
	MOV			AX, CosBuff				;load from cosine buffer
	SHR 		MtrCSpd, 1				;shift to prep for multiplication
	IMUL 		MtrCSpd					;(MtrCSpd) * cos(MtrCAngl) = [DX|AX]
	SHL 		DX, 1					;shift to prep for storage
	MOV 		MtrXVec, DX				;store the X direction velocity
	MOV 		AX, SinBuff				;load from sine buffer
	IMUL 		MtrCSpd					;(MtrCSpd) * sin(MtrCAngl) = [DX|AX]
	SHL 		DX, 1					;shift to prep for storage
	MOV 		MtrYVec, DX				;store the Y direction velocity
	SHL 		MtrCSpd, 1				;prep for velocity lookup
	XOR 		SI, SI					;clear SI
	MOV 		BP, OFFSET(MtrVecDir)	;point BP to offset of motor vector table

SetMtrPW:
	CMP 		SI, NUM_MTRS			;use a WHILE loop again
	JGE 		SetMtrFin				;finish when we iterate through each of 3 motors
	SHL 		SI, 2					;shift to prep as index for table lookup
	MOV 		AX, CS:[BP+SI]			;lookup vector at the nominal motor
	SAR 		AX, 1					;arithmetic shift right 1 bit to prevent OF in multiply op (/2)
	IMUL 		MtrXVec					;calculate x velocity
	SAL 		DX, 1					;countershift left 1 bit (it's in DX|AX) (x2)
	MOV 		BX, DX					;store x velocity
	ADD 		SI, 2					;add to prep as index for table lookup
	MOV 		AX, CS:[BP+SI]			;lookup vector at the nominal motor
	SAR 		AX, 1					;arithmetic shift right 1 bit to prevent OF in multiply op (/2)
	IMUL 		MtrYVec					;calculate y velocity
	SAL 		DX, 1					;countershift left 1 bit (it's in DX|AX) (x2)
	ADD 		DX, BX					;add for adjusted speed magnitude
	SAL 		DX, 1
	SUB 		SI, 2					;restore index
	SHR 		SI, 2
	MOV 		MtrPWval[SI], DH		;write PW value into array
	INC 		SI						;index ++
	JMP 		SetMtrPW

SetMtrFin:
	RET

SetMotorSpeed 	ENDP


; GetMotorSpeed
;
; Description:
; This function is called with no arguments and returns speed of the motor.

; Operation:
; Passes speed argument from SetMotorSpeed into AX. Returns.
;
; Arguments:					None
;
; Return Values:					[AX] - Current motor speed.
;
; Local Variables: 					None
;
; Shared Variables:
;	MtrCSpeed		- current motor speed
;
; Global Variables: 				None
;
; Input: 						None
;
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				[AX]
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/06/09 William Fan

GetMotorSpeed	PROC    NEAR
                PUBLIC  GetMotorSpeed

FetchMtrSpd:
    MOV     	AX, MtrCSpd		;move current motor speed into AX

FetchMtrSpdFin:
	RET

GetMotorSpeed   ENDP


; GetMotorDirection
;
; Description:
; This function is called with no arguments and returns angle of the motor.

; Operation:
; Passes angle argument from SetMotorSpeed into BX. Returns.
;
; Arguments:					None
;
; Arguments:					[AX} - Current motor angle.
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables:
;	MtrCAngle		- current motor angle
;
; Global Variables: 				None
;
; Input: 						None
;
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				[AX]
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/06/09 William Fan

GetMotorDirection	PROC	NEAR
					PUBLIC 	GetMotorDirection

FetchMtrAngl:
	MOV				AX,	MtrCAngl 		;move current motor angle into AX

FetchMtrAnglFin:
	RET

GetMotorDirection	ENDP


; SetTurretAngle(angle)
;
; Description:
; Rotating clockwise, the turret will assume the absolute (unsigned) angle
; passed in AX. An angle measure of 0 indicates straight ahead.
;
; Operation:
; Finds absolute difference between <angle> and <TrtCAngl>. Then it calls
; SetRelTurretAngle to handle rotation.
;
; Arguments:			[AX] - <angle> to rotate RoboTrike

; Return Value:      			None
;
; Local Variables:   		None

; Shared Variables:
;	TrtCAngle		- current turret angle
;
; Global Variables:  		None
;
; Input:             			None
; Output:           			None
;
; Error Handling:    		None
;
; Algorithms:        			None
; Data Structures:   		None
;
; Registers Changed: 		Flags, AX, BX
;
; Stack Depth:       			None
;
; Revision History:
; 04/26/09 William Fan

SetTurretAngle	PROC    NEAR
                PUBLIC  SetTurretAngle

SetAbsTrtAnglNorm:
    MOV     	BX, AX					;load passed angle into BX for normalization
    CALL    	SRangleNormU			;normalize the angle but leave unsigned
    MOV     	AX, BX					;SRangleNormU returns into BX, pass into AX

SetAbsTrtAnglRel:
    SUB     	AX, TrtCAngl			;subtract current angle from absolute angle for relative angle

SetAbsTrtAnglCall:
    CALL    	SetRelTurretAngle		;call relative angle setting routine

SetAbsTrtAnglFin:
    RET

SetTurretAngle	ENDP


; SetRelTurretAngle(angle)
;
; Description:
; Rotates the RoboTrike turret by an amount equal to the value passed in AX.
; The rotation is relative to the turret's current angular position, and is
; performed via the shortest possible number of steps.
;
; Operation:
; Normalizes the passed angle to a value between 0 and 360. Next, it will decide
; whether to rotate clockwise if less than 180 degrees or counterclockwise if greater
; than 180 degrees. This is then converted in terms of half-steps of the stepper motor
; via (STP_DVSR / STP_SCL) and queued in TrtNumStp.
;
; Arguments:        			[AX] - Relative angle to turn the turret.
;
; Return Value:      			None
;
; Local Variables:   		None
;
; Shared Variables:
;	TrtCAngle     	- current orientation of turret, constrained between (normalized) 0 and 359 relative to current heading
;	TrtNumStp       	- counter tracking remaining number of steps (half-steps) relative to nominal step for stepper motor, signed
;
; Global Variables:  		None
;
; Input:            			None
; Output:            			None
;
; Error Handling:    		None
;
; Algorithms:        			None
; Data Structures:   		None
;
; Registers Changed: 		Flags, AX, BX
;
; Stack Depth:       			1 word
;
; Revision History:
; 04/26/09 William Fan

SetRelTurretAngle	PROC    NEAR
                    PUBLIC  SetRelTurretAngle

SetRelTApos:
    MOV     BX, AX              ;temporarily move passed angle AX into BX for SRangleNormS
    CALL    SRangleNormS 		;call signed angle normalizer
    ADD     TrtCAngl, BX     	;update TrtCAngl

SetRTARsvReg:
    PUSH    BX                  ;reserve the relative angle

SetRTAUpate:
    MOV     BX, TrtCAngl     	;temporarily move relative angle for SRangleNormU
    CALL    SRangleNormU		;call unsigned angle normalizer
    MOV     TrtCAngl, BX      	;update TrtCAngl
    POP     AX                  ;restore the relative angle

SetRTARotChk:
    CMP     AX, 180    			;check which direction to turn
    JBE     SetRTASteps			;if less than or equal 180, turn clockwise
    SUB     AX, 360             ;if more than 180, convert to counterclockwise

SetRTASteps:
    MOV     BX, STP_DVSR		;load the divisor
    IMUL    BX					;multiply
    MOV     BX, STP_SCL    		;now load the scaler
    IDIV    BX                  ;divide
    ADD     TrtNumStp, AX       ;add the new steps into TrtNumStps

SetRTAFin:
    RET

SetRelTurretAngle   ENDP


; GetTurretAngle
;
; Description:
; Returns the turret's current angle (absolute) in AX. The angle is unsigned,
; normalized to a value between 0 and 360.
;
; Operation:
; Returns TrtCAngl in AX.
;
; Arguments:        			None

; Return Value: 			[AX] - Absolute angle of the RoboTrike.
;
; Local Variables:   		None
;
; Shared Variables:
;	TrtCAngle		- current turret angle
;
; Global Variables:  		None
;
; Input:             			None
; Output:            			None
;
; Error Handling:    		None
;
; Algorithms:       	 		None
; Data Structures:   		None
;
; Registers Changed: 		[AX]
;
; Stack Depth:       			None
;
; Revision History:
; 04/26/09 William Fan

GetTurretAngle	PROC    NEAR
                PUBLIC  GetTurretAngle

FetchTrtAngl:
    MOV     	AX, TrtCAngl	;load current turret angle into AX

FetchTrtAnglFin:
    RET

GetTurretAngle  ENDP


; SetLaser(true/false)
;
; Description:
; Binary function which controls the on/off state of the turret mounted laser.
; LASER_FALSE turns the laser off, while LASER_TRUE turns it on.
;
; Operation:
; Sets the LaserState shared variable to be updated in the next motor muxing when
; motor bits are written to port B.
;
; Arguments:         				[AX] - Desired state of the laser.
;
; Return Value:      				None
;
; Local Variables:   			None
;
; Shared Variables:
;	LaserState		- binary definition of laser on/off status in nominal iteration
;
; Global Variables:  			None.
;
; Input:             				None
; Output:            				None
;
; Error Handling:   		 	None
;
; Algorithms:        				None
; Data Structures:   			None
;
; Registers Changed: 			Flags, AX
; Stack Depth:      				None
;
; Revision History:
; 04/26/09 William Fan

SetLaser    PROC    NEAR
            PUBLIC  SetLaser

SetLaserChk:
    CMP     AX, LaserFALSE		;check if the value passed is the true or false value
    JE      SetLaserState		;if it's false, put it directly into LaserState
    MOV     AL, LaserTRUE		;if turning it on, change the value to LaserTRUE

SetLaserState:
    MOV     LaserState, AL

SetLaserFin:
    RET

SetLaser    ENDP


; GetLaser
;
; Description:
; Returns the on/off state of the laser.
;
; Operation:
; Returns LaserState in AX.
;
; Arguments:         			None
;
; Return Value:    			LaserState - LaserTRUE or LaserFALSE
;
; Local Variables:   		None

; Shared Variables:
;	LaserState		- binary definition of laser on/off status in nominal iteration
;
; Global Variables:  		None
;
; Input:             			None
; Output:            			None
;
; Error Handling:    		None
;
; Algorithms:        			None
; Data Structures:   		None
;
; Registers Changed: 		[AX]
; Stack Depth:       			None
;
; Revision History:
; 04/26/09 William Fan

GetLaser    PROC    NEAR
            PUBLIC  GetLaser

    MOV     AH, 0             ;clear AH in case it has corruption
    MOV     AL, LaserState	  ;write LaserState into AL

GetLaserFin:
    RET

GetLaser    ENDP


; MMuxer
;
; Description:
; Muxes the 3 motors and laser under timer 0 interrupt control.

; Operation:
; Write new values of laser state, motor speed, motor direction per timer interrupt calling
; this event handler.
;
; Arguments:					None
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables:
;	LaserState		- binary definition of laser on/off status in nominal iteration
;	MtrCSpeed		- current speed, constrained between MTRMAXSPD and MTRMINSPD, or MTRNULLSPD
;	MtrCAngle      	- current orientation, constrained between (normalized) 0 and 360 relative to current heading
;	MtrPWval       	- array, motor time on for each motor, signed
;	PWThrshldCnt  	- pulse time limit for motors, constrained between PWMINCNT and PWMAXCNT
;
; Global Variables: 				None
;
; Input: 						None
;
; Output:
; Writes commands bits to parallel port B to control laser and all PWM motors.
;
; Error Handling: 					None
;
; Registers Changed: 				Flags
;
; Stack Depth: 					5 bytes
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 04/27/09 William Fan
;	- Added true ability to move backwards.
; 03/06/09 William Fan

MMuxer 		PROC   	NEAR
			PUBLIC 	MMuxer

MMuxerPWChk:
	XOR 	SI, SI						;clear both the string index and AL
	XOR 	AL, AL
	INC 	PWThrshldCnt				;every iteration, inc the PW count
	AND 	PWThrshldCnt, PWMAXCNT 		;but if it exceeds the max count, wrap

MMuxerMChk:
	CMP 	SI, NUM_MTRS				;check how many motors pulsed
	JNL 	MMuxerLsrChk				;if done pulsing motors, check laser
	MOV 	BL, MtrPWval[SI]			;retrive the pulse width for the nominal motor
	MOV 	CX, SI
	SHL 	CL, 1
	CMP 	BL, 0						;compare to query the direction we'll be moving in
	JL 		MMuxerBWDir					;go here if it's going to be backwards
	XOR 	AH, AH						;clear AH because we update it
	JGE		MMuxerDirWRITE				;go directly to direction queueing

MMuxerBWDir:
	MOV 	AH, 1						;create a backwards direction bit
	SHL 	AH, CL						;shift into proper place for nominal motor
	NEG 	BL

MMuxerDirWRITE:
	OR 		AL, AH						;save the bit
	CMP 	PWThrshldCnt, BL			;check if motors have pulse time left on them
	JB 		MMuxerMON					;if so, begin pulsing the motors for this iteration
	;JAE		MMuxerMOFF					;otherwise, turn them off and finish

MMuxerMOFF:
	XOR 	AH, AH						;reset AH
	JMP 	MMuxerWRITE					;go to next motor

MMuxerMON:
	INC 	CL
	MOV 	AH, 1						;turn motor bit on
	SHL 	AH, CL

MMuxerWRITE:
	INC 	SI							;go to the next motor
	OR 		AL, AH						;save the bit
	JMP 	MMuxerMChk					;repeat this entire process for the next motor

MMuxerLsrChk:
	CMP 	LaserState, LaserTRUE		;check laser status
	JNE 	MMuxerLsrSend				;if FALSE, then update the LaserState
	OR 		AL, LASERSET				;mask in laser control bit before sending

MMuxerLsrSend:
	MOV 	DX, PrlPrtB					;load address of parallel B
	OUT 	DX, AL						;send laser status

MMuxerFin:
	RET

MMuxer		ENDP


; TStepper
;
; Description:
; Muxes the turret stepper half-steps under timer 1 interrupt control.

; Operation:
; Counts TrtNumStp (> 0) to zero in either direction and correspondingly
; translates TrtStpX index to xlat 4-bit pattern to write to stepper to
; rotate the turret.
;
; Arguments:					None
;
; Return Values:					None
;
; Local Variables: 					None
;
; Shared Variables:
;	TrtNumStp       	- counter tracking remaining number of steps (half-steps) relative to nominal step for stepper motor, signed
;	TrtStpX     		- stepper table lookup index bookmark
;
; Global Variables: 				None
;
; Input: 						None
;
; Output:
; Writes command bits to parallel port C to control stepper motor of turret.
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, DX, DI
; Stack Depth: 					3 words
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/06/09 William Fan

TStepper	PROC    NEAR
			PUBLIC  TStepper

TStpprChkStp:
	CMP     TrtNumStp, 0				;check if there are outstanding steps
	JL   	TStpprStpN					;negative
    JE      TStepperFin					;none so finish instantly
    ;JG      	TStpprStpP						;positive

TStpprStpP:                             ;rotate clockwise
    DEC     TrtNumStp					;dec number of steps (by 1)
    DEC     TrtStpX       				;dec step index
    AND     TrtStpX, STPTBL_LEN - 1    	;wrap TrtStpX if too small (only if both STPTBL_LEN and TrtStpX are 2^n form)
    JMP  	TStpprOUT                 	;write to the step motor

TStpprStpN:                             ;rotate counter-clockwise
    INC     TrtNumStp					;since negative, inc number of steps (to zero)
    INC     TrtStpX     				;inc step index
    CMP     TrtStpX, STPTBL_LEN			;check if TrtStpX hits edge of step table
    JNE     TStpprOUT      				;if not, step the turret
    MOV     TrtStpX, 0       			;if so, reset the step index to zero
    ;JMP     	TStpprOUT

TStpprOUT:
    MOV     AH, 0
    MOV     AL, TrtStpX
    MOV     DI, AX                  	;store table offset
    MOV     AL, CS:StepMtrBits[DI]     	;retrieve step bit pattern by offset DI from step table
    MOV     DX, PrlPrtC         		;load address of parallel C
    OUT     DX, AL                  	;write to port C

TStepperFin:
	RET

TStepper	ENDP


; SRangleNormS(angle)
;
; Description:
; Normalizes an angle to a measure between 0 and 359. Signed version.

; Operation:
; Wraps by 360 until between 0 and 360 from either direction.
;
; Arguments;				[BX] - Signed angle.
;
; Return Value:				[BX] - Converted angle.
;
; Revision History:
; 03/06/09 William Fan

SRangleNormS	PROC    NEAR
                PUBLIC  SRangleNormS

SRANSMin:							;checks minimum of passed angle (0)
        CMP     BX, 0
        JL      SRANSRotC

SRANSMax:							;checks maximum of passed angle (359)
        CMP     BX, 359
        JG      SRANSRotCC
        JMP     SRangleNormSFin

SRANSRotC:                     		;if too low, add 360 and repeat until good
        ADD     BX, 360
        JMP     SRANSMin

SRANSRotCC:                     	;if too high, sub 360 and repeat until good
        SUB     BX, 360
        JMP     SRANSMax

SRangleNormSFin:
        RET

SRangleNormS	ENDP


; SRangleNormU(angle)
;
; Description:
; Normalizes an angle to a measure between 0 and 359. Unsigned version.

; Operation:
; Wraps by 360 until between 0 and 360 from either direction.
;
; Arguments;				[BX] - Unsigned angle.
;
; Return Value:				[BX] - Converted angle.
;
; Revision History:
; 03/06/09 William Fan

SRangleNormU	PROC    NEAR
                PUBLIC  SRangleNormU

SRANUMax:					;check maximum of passed angle (359)
        CMP     BX, 359
        JA      SRANURotC
        JMP     SRANUFin

SRANURotC:              	;if too large, sub 360 until good
        SUB     BX, 360
        JMP     SRANUMax

SRANUFin:
        RET

SRangleNormU	ENDP


CODE    		ENDS


;data segment - declare shared variables
DATA    SEGMENT PUBLIC	'DATA'


	LaserState		DB ?				;laser on/off condition indicator
	MtrCSpd			DW ?     			;current unified speed of PWM motors
	MtrCAngl      	DW ?     			;current equivalent angle of PWM motors

	SinBuff			DW ?				;current sine
	CosBuff			DW ?				;current cosine
	MtrXVec			DW ?				;x vector magnitude
	MtrYVec			DW ?				;y vector magnitude

	MtrPWval       	DB NUM_MTRS DUP (?)	;array of pulse widths for number of motors
	PWThrshldCnt  	DB ?             	;pulsing width on/off limit counter

	TrtCAngl     	DW ?     			;current equivalent angle of stepper-driven turret
	TrtNumStp       DW ?	    		;number of steps remaining from nominal step for turret orientation
	TrtStpX     	DB ?				;stepper table lookup index bookmark


DATA				ENDS


					END
