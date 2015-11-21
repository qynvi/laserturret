		NAME	InitTimers

;----------------------------------------------------------------------------------------------------------------------------------------
; 80188 Timer Initialization
;
; Writes various initial values into the control and count registers of the 188 timers.
;
; InitTimer - Writes to control and count registers in timers 0, 1, and 2 to start them in continuous mode,
;		 enable interrupts, and flush EOI.
;
; Timer 0 - Continuous mode, controls the drive motor, IRQ per (Tmr0CntV / 2304) ms.
; Timer 1 - Continous mode, controls the turret stepper, IRQ per (Tmr1CntV / 2304) ms.
; Timer 2 - Continous mode, controls the interface devices, IRQ per 1 ms.
;------------------------------------------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/01/09 William Fan

$INCLUDE(188val.inc)


CGROUP  GROUP   	CODE

CODE	SEGMENT 	PUBLIC 'CODE'

        ASSUME  	CS:CGROUP


; InitTimer
;
; Description:
; Initializes timers 0, 1, and 2 based on values defined in 188val.inc.
;
; Operation:
; Sets timer control registers to relevant values.
;
; Arguments:
; None
;
; Return Values:
; None
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
; Registers Changed: 				Flags, AX, DX, ES
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
;	-Seperated from 188tievh.asm.
; 02/18/09 William Fan

InitTimer0	PROC	NEAR
			PUBLIC	InitTimer0

ResetTmr0Cnt:
	XOR		AX,	AX				;reset timer 0 counter
	MOV		DX,	Tmr0CCnt
	OUT		DX,	AL
	MOV		DX,	Tmr0MCnt
	MOV		AX,	Tmr0CntV
	OUT		DX,	AL
	MOV		DX,	Tmr0Ctrl
	MOV		AX,	Tmr0CtrlV		;start timer 0 in continuous mode
	OUT 	DX,	AL

IntEnable0:
	MOV		DX, IntIRQCtrl
	MOV		AX, IntIRQCtrlV		;enable timer interrupts
	OUT		DX, AL

Tmr0EOI:
	MOV     DX, EOI				;initialize port for EOI
	MOV     AX, TmrEOIVal		;initialize AX to store EOI command
	OUT     DX, AL				;flush timer EOI

InitTimer0Fin:
	RET

InitTimer0	ENDP


InitTimer1	PROC	NEAR
			PUBLIC	InitTimer1

ResetTmr1Cnt:
	XOR		AX,	AX				;reset timer 1 counter
	MOV		DX,	Tmr1CCnt
	OUT		DX,	AL
	MOV		DX,	Tmr1MCnt
	MOV		AX,	Tmr1CntV		;init tmr1 to IRQ every 25ms
	OUT		DX,	AL
	MOV		DX,	Tmr1Ctrl
	MOV		AX,	Tmr1CtrlV		;init tmr1 to IRQ continuously
	OUT 	DX,	AL

IntEnable1:
	MOV		DX, IntIRQCtrl
	MOV		AX, IntIRQCtrlV		;enable timer interrupts
	OUT		DX, AL

Tmr1EOI:
	MOV     DX, EOI				;initialize port for EOI
	MOV     AX, TmrEOIVal		;initialize AX to store EOI command
	OUT     DX, AL				;flush timer EOI

InitTimer1Fin:
	RET

InitTimer1	ENDP


InitTimer2	PROC	NEAR
			PUBLIC	InitTimer2

ResetTmr2Cnt:
	XOR		AX,	AX				;clear AX
	MOV		DX,	Tmr2CCnt		;reset timer 2 count
	OUT		DX,	AL				;send to the control block

SetTmr2Interrupt:
	MOV		DX,	Tmr2MCnt
	MOV		AX,	TmrCntValue		;initialize timer 2 clocking for 1 KHz interrupts
	OUT		DX,	AL				;send to the control block

InitTmr2Interrupt:
	MOV		DX,	Tmr2Ctrl
	MOV		AX,	Tmr2CtrlV		;set the control register for timer2 to interrupt continuously
	OUT 	DX,	AL				;write to the control block

IntEnable2:
	MOV		DX, IntIRQCtrl
	MOV		AX, IntIRQCtrlV		;enable timer interrupts
	OUT		DX, AL

Tmr2EOI:
	MOV     DX, EOI				;initialize port for EOI
	MOV     AX, TmrEOIVal		;initialize AX to store EOI command
	OUT     DX, AL				;flush timer EOI

InitTimer2Fin:
	RET

InitTimer2	ENDP


CODE		ENDS


			END
