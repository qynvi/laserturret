        NAME	EvH

;----------------------------------------------------------------------------------------------------------------------------------------
; 80188 Event Handler

; Specifies timer event handlers that control most devices on the RoboTrike 188.

; MtrEvH - References motor muxer when timer 0 interrupts.
; StepEvH - References turret stepper when timer 1 interrupts.
; IOEvH - References display muxer and keypad muxer when a (1 KHz)
;                 timer interrupt occurs once every millisecond.
; IllegalEvH - When an interrupt not specifically accounted for by our current
;                       timer event handler occurs, we save the registers and terminate
;                       interrupt so that the system will not hang or bug.
; SerialEventHandler - IRQ handler for the 16C450. Based on the type of interrupt
;                                      received in interrupt ID register, it takes action and sends an EOI.

; In addition, specifies timer event intallers which hook the handler onto the interrupt
; vector table.

; InitIllegalEvH - Hooks IllegalEvH onto the interrupt of every other non-reserved interrupt in the table.
; InitMtrEvH - Hooks MtrEvH onto the interrupt of timer 0.
; InitStepEvH - Hooks StepEvH onto the interrupt of timer 1.
; InitIOEvH - Hooks TimerEventHandler onto the interrupt of timer2.
; InitSerialEvH - Hooks serial event handler into interrupt vector table.
;------------------------------------------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/27/09 William Fan
;	-Re-added serial event handling compatibility.
; 04/26/09 William Fan
;	-Seperated InitCS into discrete file.
;	-Renamed CSInit into InitCS.
;	-Renamed this file 188EvH.
;	-Restructured event handling: all handlers now called from this file.
;	-Renamed InitEventHandler(DMuxer/KMuxer) to InitIOEvH
;	-Renamed InitEventHandler(IllegalEvH) to InitIllegalEvH
;	-Seperated install "bad event handler" into its own function.
;	-Renamed BadEventHandler into IllegalEvH.
;	-Added Motor event handler installers.
;	-Changed InitTimer to comply with timer 0 no longer one-shot.
;	-Updated comments.
; 04/15/09 William Fan
;	-Added motor timer ctrl values to InitTimer.
;	-Renamed IOEvH to IOEvH (since it contains DMuxer and KMuxer).
; 03/22/09 William Fan
;	-Updated comments.
;	-Restructured code for simplicity.
; 03/08/09 William Fan
;	-Compatibility with serial.
; 03/05/09 William Fan
;	-Added  IllegalEvH.
; 03/04/09 William Fan
;	-Updated comments.
; 03/03/09 William Fan
;	-Compatibility with keypad.
;	-Chip select.
;	-Hooks illegal event handler on every non-reserved vector.
;	-Updated comments to match changes.
; 02/20/09 William Fan
;	-TimerEventHandler is called at correct times.
; 02/16/09 William Fan

$INCLUDE(188val.inc)

CGROUP  GROUP   	CODE

CODE	SEGMENT 	PUBLIC 'CODE'

        ASSUME  	CS:CGROUP


			EXTRN 	DMuxer:NEAR
			EXTRN 	KMuxer:NEAR
			EXTRN	MMuxer:NEAR
			EXTRN 	TStepper:NEAR
			EXTRN	SerialEvH:NEAR


; MtrEvH
;
; Description:
; References motor muxer when timer 0 interrupts.
;
; Operation:
; Saves all registers, calls the event handling public function.
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
; Registers Changed: 				Flags, AX, BX, DX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/03/09 William Fan
;	-Added keypad muxer.
;	-Changed labels.
;	-Updated comments to match changes.
; 02/18/09 William Fan

MtrEvH		PROC	NEAR

CallMtrEvH:
	PUSHA					;save all registers before calling motor muxer
	CALL	MMuxer			;call motor muxer to pulse the three motors

MTmrEvHEOI:
	MOV     AX, TmrEOIVal	;write the EOI command to AX
	MOV     DX, EOI			;EOI after we're done
	OUT     DX, AL			;send the timer EOI

MTmrEvHFin:
	POPA					;restore all registers we may have messed up
	IRET

MtrEvH		ENDP


; StepEvH
;
; Description:
; References turret stepper when timer 1 interrupts.
;
; Operation:
; Saves all registers, calls the event handling public function.
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
; Registers Changed: 				Flags, AX, BX, DX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/03/09 William Fan
;	-Added keypad muxer.
;	-Changed labels.
;	-Updated comments to match changes.
; 02/18/09 William Fan

StepEvH		PROC	NEAR

CallStepEvH:
	PUSHF
	PUSHA					;save all registers and flags before calling stepper
	CALL	TStepper		;call stepper to execute half-steps queued on the turret

STmrEvHEOI:
	MOV     AX, TmrEOIVal	;write the EOI command to AX
	MOV     DX, EOI			;EOI after we're done
	OUT     DX, AL			;send the timer EOI

STmrEvHFin:
	POPA					;restore all registers we may have messed up
	POPF
	IRET

StepEvH		ENDP


; IOEvH
;
; Description:
; References display muxer and keypad muxer when a (1 KHz)
; timer interrupt occurs once every millisecond.
;
; Operation:
; Saves all registers, calls the event handling public function.
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
; Registers Changed: 				Flags, AX, BX, DX
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/03/09 William Fan
;	-Added keypad muxer.
;	-Changed labels.
;	-Updated comments to match changes.
; 02/18/09 William Fan

IOEvH		PROC	NEAR

CallIOEvH:
	PUSHA					;save all registers before calling public function
	CALL	DMuxer
	CALL	KMuxer

IOTmrEvHEOI:
	MOV     AX, TmrEOIVal	;write the EOI command to AX
	MOV     DX, EOI			;EOI after we're done
	OUT     DX, AL			;send the timer EOI

IOTmrEvHFin:
	POPA					;restore all registers we may have messed up
	IRET

IOEvH		ENDP


; IllegalEvH
;
; Description:
; When an interrupt not specifically accounted for by our current
; timer event handler occurs, we save the registers and terminate
; interrupt so that the system will not hang or bug.
;
; Operation:
; Saves all registers for debug/stability, then writes a general EOI
; command which should end the interrupt.
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
; Registers Changed: 				AX, DX (technically does not change them)
; Stack Depth: 					None
;
; Algorithms: 					None
; Data Structures: 				None
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/05/09 William Fan

IllegalEvH		PROC	NEAR

BadEvHResvReg:
	PUSHA						;save registers (for debugging or other purposes)

BadEvHEOI:
	;cannot do anything about this interrupt; just end the interrupt and let user handle it
	MOV     	AX, GenEOIVal	;write EOI command to send it
	MOV     	DX, EOI			;write EOI address to send to
	OUT     	DX, AL			;send the nonspecific EOI command

BadEvHRestoReg:
	POPA						;restore AX and DX and any other pertinent registers

BadEvHFin:
	IRET

IllegalEvH		ENDP


; SerialEventHandler
;
; Description:
; IRQ handler for the 16C450. Based on the type of interrupt received in interrupt ID register,
; it takes action and sends an EOI.
;
; Operation:
; IIR value is returned in BX. BX is compared with an index of possible errors we can handle
; and the routine goes to that routine.
;
; Arguments:       					None
;
; Return Values:					None
;
; Local Variables: 					None
; Shared Variables: 				RxQueue(QSTRUC)
;							TxQueue(QSTRUC)
;							SerialError
;
; Global Variables: 				None
;
; Input:
; Reads control register values from ACE.
;
; Output:
; Writes control register values to ACE.
;
; Error Handling:
; Sets SerialErrorFlag to TRUEBIT and puts line status register into Serial Error.
;
; Registers Changed: 				Flags, BX
; Stack Depth: 					4 words
;
; Algorithms: 					None
; Data Structures: 				QSTRUC (queue.inc)
;							SerialIRQTable(sIRQ.asm)
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/08/09 William Fan

SHandler		PROC    NEAR

    PUSHA                          ;reserve registers

    CALL    SerialEvH

    MOV     AX, Int2EOI
    MOV     DX, EOI         		;send an INT2 EOI
    OUT     DX, AL

	POPA 							;restore the registers

    IRET

SHandler     	ENDP


; InitIllegalEvH
;
; Description:
; Hooks IllegalEvH onto the interrupt of every other non-reserved interrupt in the table.
;
; Operation:
; First, it iterates every interrupt in the interrupt vector table and hooks the illegal
; event handler to all vectors not between FirstResvIRV and FinalResvIRV as constrained
; by the total number of vectors TotalIRV.
;
; Arguments:       					None
;
; Return Values:					None
;
; Local Variables: 					[SI] - Nominal (I)nte(r)rupt (V)ector Address
; Shared Variables: 				None
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, DX, ES, SI
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
;	-Seperated from old installer.

InitIllegalEvH	PROC	NEAR
				PUBLIC	InitIllegalEvH

InitIRVOps:
	MOV				SI, 0					;start pointer at first interrupt
	XOR				AX,	AX					;clear AX
	MOV				ES,	AX					;store ES point to interrupt vec seg 00
	MOV				CX, TotalIRV			;store total number of IRVs

IterateBadEvH:
	;check to avoid first reserved interrupt
	CMP				SI,	FirstResvIRV * 4
	JB				HookIllegalEvH			;if less, then hook illegal event handler onto nominal interrupt vector
	;check to avoid final reserved interrupt
	CMP				SI,	FinalResvIRV * 4
	JBE				HookBadEvHInc			;if less or equal, we ignore vectors reserved for other things
	;JG				HookIllegalEvH				;if greater, past reserved IRVs, so hook illegal event handler onto nominal IRV

HookIllegalEvH:
	;write handler offset to interrupt vector table
	MOV				ES:WORD PTR [SI], OFFSET(IllegalEvH)
	;write handler segment to interrupt vector table
	MOV				ES:WORD PTR [SI + 2], SEG(IllegalEvH)

HookBadEvHInc:
	ADD				SI,	4					;increment pointer to next interrupt vector
	LOOP			IterateBadEvH

InitIllegalEvHFin:
	RET

InitIllegalEvH	ENDP


; InitMtrEvH
;
; Description:
; Hooks MtrEvH onto the interrupt of timer 0.
;
; Operation:
; Hooks the timer event handler that calls motor muxer onto the interrupt of timer 0.
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
; Registers Changed: 				Flags, AX, DX, ES, SI
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
;	-Seperated illegal event handler installer.
; 03/04/09 William Fan
;	-Updated comments.
; 03/03/09 William Fan
;	-Hooks illegal event handler on every non-reserved vector.
;	-Updated comments to match changes.
; 02/18/09 William Fan

InitMtrEvH	PROC	NEAR
			PUBLIC	InitMtrEvH

HookMtrEvH:
	XOR		AX,	AX	;clear AX
	MOV		ES,	AX
	;write handler offset into interrupt vector table
	MOV		ES:WORD PTR (Tmr0Int * 4), OFFSET(MtrEvH)
	;write handler segment into interrupt vector table
	MOV		ES:WORD PTR ((Tmr0Int * 4) + 2), SEG(MtrEvH)

InitMtrEvHFin:
	RET

InitMtrEvH 	ENDP


; InitStepEvH
;
; Description:
; Hooks StepEvH onto the interrupt of timer 1.
;
; Operation:
; Hooks the timer event handler that calls stepper muxer onto the interrupt of timer 1.
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
; Registers Changed: 				Flags, AX, DX, ES, SI
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
;	-Seperated illegal event handler installer.
; 03/04/09 William Fan
;	-Updated comments.
; 03/03/09 William Fan
;	-Hooks illegal event handler on every non-reserved vector.
;	-Updated comments to match changes.
; 02/18/09 William Fan

InitStepEvH			PROC	NEAR
					PUBLIC	InitStepEvH

HookStepEvH:
	XOR		AX,	AX	;clear AX
	MOV		ES,	AX
	;write handler offset into interrupt vector table
	MOV		ES:WORD PTR (Tmr1Int * 4), OFFSET(StepEvH)
	;write handler segment into interrupt vector table
	MOV		ES:WORD PTR ((Tmr1Int * 4) + 2), SEG(StepEvH)

InitStepEvHFin:
	RET

InitStepEvH 		ENDP


; InitIOEvH
;
; Description:
; Hooks TimerEventHandler onto the interrupt of timer2.
;
; Operation:
; Hooks the timer event handler that calls disp and keypad muxers onto the interrupt of timer 2.
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
; Registers Changed: 				Flags, AX, DX, ES, SI
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
;	-Seperated illegal event handler installer.
; 03/04/09 William Fan
;	-Updated comments.
; 03/03/09 William Fan
;	-Hooks illegal event handler on every non-reserved vector.
;	-Updated comments to match changes.
; 02/18/09 William Fan

InitIOEvH	PROC	NEAR
			PUBLIC	InitIOEvH

HookIOEvH:
	XOR		AX,	AX	;clear AX
	MOV		ES,	AX
	;write handler offset into interrupt vector table
	MOV		ES:WORD PTR (Tmr2Int * 4), OFFSET(IOEvH)
	;write handler segment into interrupt vector table
	MOV		ES:WORD PTR ((Tmr2Int * 4) + 2), SEG(IOEvH)

InitIOEvHFin:
	RET

InitIOEvH 	ENDP


; InitSerialEvH
;
; Description:
; Hooks serial event handler into interrupt vector table.
;
; Operation:
; Writes the serial event handler into vector table at the address of serial interrupt.
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
; 03/08/09 William Fan

InitSrlEvH   	PROC    NEAR
                PUBLIC  InitSrlEvH

    ;store ES point to interrupt vec seg 00
    XOR     AX, AX
    MOV     ES, AX

	;write handler offset into interrupt vector table
    MOV     ES: WORD PTR (4 * Int2Int), OFFSET(SHandler)
	;write handler segment into interrupt vector table
    MOV     ES: WORD PTR (4 * Int2Int + 2), SEG(SHandler)

    RET

InitSrlEvH    	ENDP


CODE ENDS

END
