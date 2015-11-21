		NAME	SERIAL

;--------------------------------------------------------------------------------------------------------
; RoboTrike Serial IO Routine

; The serial rx/tx ops functions for the RoboTrike.

; SerialInit - Sets up serial rx/tx queues and turns on interrupts.
; SerialSetBaud - Sets the serial baud rate.
; SerialSetPar - Sets the serial parity.
; InitSerialEvH - Installs serial event handler into vector table.
; SerialInRdy - Sets ZF based on if serial port is ready for input (rx).
; SerialOutRdy - Sets ZF based on if serial port is ready for output (tx).
; SerialGetChar - Dequeue a character from the serial RX queue.
; SerialPutChar - Enqueue a character to the serial TX queue.
; SerialStatus - Returns with error status on the serial port.
; SerialEventHandler - 16C450 serial functions under INT2 interrupt control.
;----------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/28/09 William Fan
;	-Rewrote serial event handler to comply with restructured timer/event routines.
; 04/14/09 William Fan
;	-Code simplification.
;	-Comments updated.
; 03/08/09 William Fan

; local include files
$INCLUDE(188val.inc)
$INCLUDE(serial.inc)
$INCLUDE(queue.inc)
$INCLUDE(ace.inc)
$INCLUDE(constant.inc)

CGROUP  GROUP   CODE

DGROUP  GROUP   DATA


CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP
		ASSUME	DS:DGROUP


		;reference external queue routines
		EXTRN	QueueInit:NEAR		;write initial queue defintions
		EXTRN	QueueEmpty:NEAR		;checks if the queue is empty
		EXTRN	QueueFull:NEAR		;checks if the queue is full
		EXTRN	Dequeue:NEAR		;remove a char from the queue
		EXTRN	Enqueue:NEAR		;add a char to the queue


; SerialInit
;
; Description:
; Sets up the serial port by prepping the rx/tx queues and turns on
; serial interrupts. Sets default baud rate and parity values for the
; serial channels.
;
; Operation:
; Sets IER bit 0, 1, and 2 to enable ERBF, ETBE, and ELSI, then sets
; LCR bit 7 to enable access to divisor latches. Calls NEAR routines
; SerialSetBaud and SerialSetPar to calculate and set the baud rate
; and serial port parity defaults.
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
;
; Output:
; Writes enabling IER and MCR values to 16C450 registers. Writes default
; values of baud rate and parity to the 16C450.
;
; Error Handling: 					None
;
; Registers Changed: 				Flags
; Stack Depth: 					3 Words
;
; Algorithms: 					None
; Data Structures: 				QSTRUC (queue.inc)
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/08/09 William Fan

InitSerial      PROC    NEAR
                PUBLIC  InitSerial

SrlInitSetBR:
    CALL    SerialSetBaud

SrlInitSetPar:
    CALL    SerialSetPar

SrlInitCtrlVal:
    MOV     DX, ACE_IER_LOC             	;load address of IER register
    MOV     AL, ACE_IER_ETBE				;load interrupt control bits for serial interrupts
    OUT     DX, AL							;write to serial controller

    MOV     DX, ACE_MCR_LOC                 ;load address of MCR
    MOV     AL, ACE_MCR_DTR + ACE_MCR_RTS 	;load DTR and RTS bits
    OUT     DX, AL							;write to serial controller

InitErrorStatus:
    MOV     SerialError, SERIAL_ERROR_NULL	;begin with no serial errors

InitQueues:
    MOV     AX, RX_SIZE						;prepare to make an Rx queue of size RX_SIZE
    LEA     SI, RxQueue						;prepare the address of that queue
    CALL    QueueInit						;call queue routines to make a receive queue

    MOV     AX, TX_SIZE						;prepare to make a Tx queue of size TX_SIZE
    LEA     SI, TxQueue						;prepare the address of that queue
    CALL    QueueInit						;call queue routines to make a transmit queue

SrlInitINT2ON:
    MOV     AL, Int2CtrlV   				;start INT2 and turn on its interrupts
    MOV     DX, Int2Ctrl
    OUT     DX, AL

SrlInitINT2Flush:
    MOV     AX, Int2EOI	  					;flush INT2 EOI by sending an EOI
    MOV     DX, EOI
    OUT     DX, AL

SrlInitFin:
    RET

InitSerial     	ENDP


; SerialSetBaud
;
; Description:
; Changes the value of the 16C450 baud rate into the value passed in BX.
;
; Operation:
; Baud Rate Divisor = XTAL_FREQ / (4 * BX)
; Baud rate divisor is written to divisor latch registers.
;
; Arguments:					[BX] - Baud Rate
;
; Return Values:
; None
;
; Local Variables: 					None
; Shared Variables: 				None
; Global Variables: 				None
;
; Input: 						None
;
; Output:
; Baud rate divisor is sent to 16C450 divisor latch registers.
;
; Error Handling:
; If user... has poor judgement... and tries to make BR too small,
; it will automatically be increased to a minimum default value.
;
; Registers Changed: 				Flags, AX, BX, CX, DX
; Stack Depth: 					5 Words
;
; Algorithms:
; Baud Rate Divisor = XTAL_FREQ / (4 * BX)
;
; Data Structures: 				QSTRUC (queue.inc)
;
; Known Bugs: 					None
;
; Limitations:
; Converted baud rate cannot overflow the register.
; i.e. it must fit in 16 bits.
;
; Revision History:
; 03/08/09 William Fan

SerialSetBaud   PROC    NEAR
				PUBLIC  SerialSetBaud

SerialSBRsvRegs:
    PUSH    AX					;reserve AX because we need to set DLAB

SerialSBDLAB:
    MOV     DX, ACE_LCR_LOC		;set DLAB bits
    MOV     AL, ACE_LCR_DLAB
    OUT     DX, AL				;write to the serial controller

SerialSBRstrRegs:
    POP     AX                	;restore AX, with the BR input

SerialSBWrite:
    MOV     DX, ACE_DLL_LOC		;load the baud rate divisor
    OUT     DX, AL              ;write to the serial controller
    INC     DX					;increment to the next byte
    MOV     AL, AH				;load the next byte
    OUT     DX, AL				;write to the serial controller

SerialSBFin:
    RET

SerialSetBaud	ENDP


; SerialSetPar
;
; Description:
; Sets ACE parity based on AL.
;
; Operation:
; Masks passed argument AL with word length mask, then
; writes the parity setting to ACE_LCR.
;
; Arguments:					[AX] - Parity Setting
;							bit 0 - Reserved
;							bit 1 - Reserved
;							bit 2 - Reserved
;							bit 3 - set to enable parity
;							bit 4 - set for even parity
;								clear for odd parity
;							bit 5 - set for stick parity
;							bit 6 - Reserved
;							bit 7 - Reserved

; Return Values:					None
;
; Local Variables: 					None
; Shared Variables: 				None
; Global Variables: 				None
;
; Input: 						None
;
; Output:
; Parity is sent to 16C450 line control register.
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, BX, DX
; Stack Depth: 					4 Words
;
; Algorithms: 					None
;
; Data Structures: 				QSTRUC (queue.inc)
;
; Known Bugs: 					None
;
; Limitations: 					None
;
; Revision History:
; 03/08/09 William Fan

SerialSetPar   	PROC    NEAR
				PUBLIC  SerialSetPar

SerialSPWrite:
	MOV     DX, ACE_LCR_LOC			;load address of LCR register
    OR      BL, SERIAL_DFLT			;OR in the other default settings
    MOV     AL, BL					;move into AX for OUTing
    OUT     DX, AL                	;write to the serial controller

SerialSPFin:
    RET

SerialSetPar  	ENDP


; SerialInRdy
;
; Description:
; Sets ZF based on Rx readiness.
;
; Operation:
; Calls external function QueueEmpty to check Rx queue.
;
; Arguments:       					None
;
; Return Values:					[ZF] - Clear if Rx queue is not full.
;
; Local Variables: 					None
; Shared Variables: 				RxQueue(QSTRUC)
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, BX
; Stack Depth: 					1 word
;
; Algorithms: 					None
; Data Structures: 				QSTRUC (queue.inc)
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/08/09 William Fan

SerialInRdy     PROC    NEAR
                PUBLIC  SerialInRdy

		LEA		SI, RxQueue		;load location of the receive queue
		CALL	QueueEmpty		;call QueueEmpty to check if it's empty

SerialIRFin:
        RET

SerialInRdy     ENDP


; SerialGetChar
;
; Description:
; Dequeue a character from the serial Rx queue. Blocking function
; prevents return until something is dequeued.
;
; Operation:
; Calls external routine Dequeue with blocking function to dequeue
; from passed Rx queue and place the character in AL. SerialStatus
; checks for error.
;
; Arguments:       					None
;
; Return Values:					[AL] - Dequeued character.
;							[CF] - Set if SerialStatus reports error.
;
; Local Variables: 					None
; Shared Variables: 				RxQueue(QSTRUC)
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling:
; If SerialStatus reports an error for some reason the CF is set so user
; is notified to deal with it.
;
; Registers Changed: 				Flags, BX
; Stack Depth: 					1 word
;
; Algorithms: 					None
; Data Structures: 				QSTRUC (queue.inc)
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/08/09 William Fan

SerialGetChar   PROC    NEAR
                PUBLIC  SerialGetChar

CheckInReady:
	CALL	SerialInRdy
	JZ		CheckInReady

SerialGCDQ:
	LEA		SI, RxQueue						;load address of the receive queue
	CALL	Dequeue							;call Dequeue to remove from it

SerialGCChk:
	CMP		SerialError, SERIAL_ERROR_NULL	;check if a serial error has occurred
	JNE		SerialGCErr						;if so set CF and let user take care of it
	;JE		SerialGCNoErr						;if not, clear CF and return

SerialGCNoErr:
	CLC										;no error, so clear carry flag
	JMP 	SerialGCFin

SerialGCErr:
	STC										;error, so set carry flag
	;JMP 		SerialGCFin

SerialGCFin:
    RET

SerialGetChar   ENDP


; SerialOutRdy
;
; Description:
; Sets ZF based on Tx readiness.
;
; Operation:
; Calls external function QueueFull to check Tx queue.
;
; Arguments:       					None
;
; Return Values:					[ZF] - Clear if Rx queue is full.
;
; Local Variables: 					None
; Shared Variables: 				TxQueue(QSTRUC)
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, BX
; Stack Depth: 					1 word
;
; Algorithms: 					None
; Data Structures: 				QSTRUC (queue.inc)
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/08/09 William Fan

SerialOutRdy   	PROC    NEAR
                PUBLIC  SerialOutRdy

	LEA		SI, TxQueue		;load address of transmit queue
	CALL	QueueFull		;call external QueueFull to check if it's full

SerialORFin:
    RET

SerialOutRdy   	ENDP


; SerialPutChar
;
; Description:
; Enqueue a character from the serial Tx queue. Blocking function
; prevents return until something is enqueued
;
; Operation:
; Calls external routine Enqueue with blocking function to Enqueue
; a char into transmit queue. Clears Transmit Holding Register Empty
; in ACE(IER).
;
; Arguments:       					None
;
; Return Values:					[AL] - Character to enqueue.
;
; Local Variables: 					None
; Shared Variables: 				TxQueue(QSTRUC)
; Global Variables: 				None
;
; Input: 						None
; Output:
; Writes 0 to ACE(IER) THRE interrupt enable bit.
;
; Error Handling: 					None
;
; Registers Changed: 				Flags, AX, BX, CX, DX
; Stack Depth: 					4 word
;
; Algorithms: 					None
; Data Structures: 				QSTRUC (queue.inc)
;
; Known Bugs: 					None
; Limitations: 					None
;
; Revision History:
; 03/08/09 William Fan

SerialPutChar   PROC    NEAR
                PUBLIC  SerialPutChar

SerialPCRsvRegs:
	PUSH    AX					;save the character to Enqueue, in AX

SerialPCBlock:
	CALL	SerialOutRdy		;check if queue is ready to accept
	JZ		SerialPCBlock		;if not, block

SerialPCIRQ:
	MOV     AL, SERIAL_IRQ		;load transmit interrupt
    MOV     DX, ACE_IER_LOC		;load address of IER register
    OUT     DX, AL				;write the control bits

SerialPCRstrRegs:
    POP     AX               	;restore the character we want to Enqueue

SerialPCEQ:
	LEA		SI, TxQueue			;load address of transmit register
	CALL	Enqueue				;call Enqueue on it

SerialPCFin:
    RET

SerialPutChar   ENDP


; SerialStatus
;
; Description:
; Sets CF based on (generic) errors in serial Rx/Tx.
;
; Operation:
; If SerialErrorFlag is TRUEBIT, sets CF. Else, clears CF. After it
; does that, it resets SerialErrorFlag.
;
; Arguments:       					None
;
; Return Values:					[CF] - Set if there's an error.
;
; Local Variables: 					None
; Shared Variables: 				SerialErrorFlag
; Global Variables: 				None
;
; Input: 						None
; Output: 						None
;
; Error Handling: 					None
;
; Registers Changed: 				Flags
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

SerialStatus    PROC    NEAR
                PUBLIC  SerialStatus

    MOV     AL, SERIAL_ERROR_NULL	;load up a no-error byte
    XCHG    AL, SerialError			;exchange into SerialError, while retrieving any errors it had

SerialStatFin:
    RET

SerialStatus   ENDP


; SerialEventHandler
;
; Description:
; IRQ handler for the 16C450. Based on the type of interrupt received in interrupt ID register,
; it takes action.
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
;							SerialErrorFlag
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

SerialEvH    PROC    NEAR
             PUBLIC  SerialEvH

SerialEvHChk:
        MOV     DX, ACE_IIR_LOC			;load address of interrupt indentification register
        IN      AL, DX					;read the interrupt
        AND     AL, ACE_IIR_MASK   		;using the mask, isolate the interrupt ID

SerialEvHELSI:
        CMP     AL, ACE_IIR_IRQ_RLS		;compare to check what kind of interrupt it is
        JNE     SerialEvHETBE			;right now, assume line segment, but if not then go to the next choice

SerialEvHELSIH:
        MOV     DX, ACE_LSR_LOC			;load the address of LSR
        IN      AL, DX					;read the line segment register
        AND     AL, SERIAL_TX_MASK  	;mask off transmit errors
        OR      SerialError, AL     	;OR in any errors to SerialError
        JMP     SerialEvHFin			;go directly to the end

SerialEvHETBE:
        CMP     AL, ACE_IIR_IRQ_THRE	;now check if it's transmit holding interrupt
        JNE     SerialEvHERBFH			;if still not, then can only be receiver interrupt

SerialEvHETBEH:
        LEA     SI, TxQueue				;load address of transmit queue
        CALL    QueueEmpty				;check status of queue
        JZ      SerialEvHETBEI         	;if empty, just handle the interrupt
        CALL    Dequeue             	;otherwise, call DQ to remove from Tx queue
        MOV     DX, ACE_THR_LOC			;load THR again
        OUT     DX, AL             	 	;write DQed thing from Tx to THR
        JMP     SerialEvHFin

SerialEvHETBEI:
        MOV     AL, ACE_IER_ETBE		;load ETBE control bits
		MOV     DX, ACE_IER_LOC			;load address of IER again
        OUT     DX, AL					;turn off ETBE interrupts
        JMP     SerialEvHFin

SerialEvHERBFH:
        MOV     DX, ACE_RBR_LOC			;load address of RBR
        IN      AL, DX            		;read whatever is there
		PUSH	AX						;save AX temporarily for QueueFull
        LEA     SI, RxQueue				;load address of receive queue
        CALL    QueueFull				;check if queue is full
		POP		AX						;restore AX
        JZ      SerialBufferOVF     	;if the queue is full call overflow error
        CALL    Enqueue            		;otherwise, call Enqueue to write into it
        JMP		SerialEvHFin

SerialBufferOVF:
        OR      SerialError, SERIAL_ERROR_TRUE

SerialEvHFin:
        RET

SerialEvH    	ENDP


CODE    		ENDS


;the data segment
DATA    SEGMENT PUBLIC  'DATA'

SerialError		DB      ?       ;store serial errors from LCR
RxQueue			QSTRUC <>  		;defines a receive queue to store Rx bytes
TxQueue       	QSTRUC <> 		;defines a transmit queue to store Tx bytes

DATA    		ENDS


				END
