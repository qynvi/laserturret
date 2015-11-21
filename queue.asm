        NAME    QUEUE

;--------------------------------------------------------------------------------------------------------
; RoboTrike Queue Routines
;
; The queue functions for the RoboTrike.
;
; QueueInit - Initializes queue of size s at address a.
; QueueEmpty - Checks if the queue is empty.
; QeueFull - Checks if the queue is full.
; Dequeue - Removes a value from the qhead of the queue. Blocking function.
; Enqueue - Adds a value b to queue at address a. Blocking function.
;----------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/28/09 William Fan
;	- Revised code for simplicity and readibility.
; 02/08/09	William Fan

;declares the QSTRUC structure
$INCLUDE(queue.inc)


CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP


; QueueInit(a,s)
;
; Description:
; Prepare a queue located at passed argument a of size s. Sets qhead and q tail
; qtail pointers to default positions at beginning and end of the valid dequeue
; and enqueue addresses.

; Operation:
; (a) is passed in SI by value and (s) is passed by value in AX. Sets qhead and
; qtail to default 0, creates a queue modulated by QSTRUC in the include of
; size (s) or Q_MAX_LEN.
;
; Arguments:
; 'a' (SI) - Address of the queue (queue starts at DS:SI).
; 's' (AX) - Size of the queue.
;
; Input:            		None
; Output:           		None
;
; Return Values: 		None
;
; Local Variables:  		None
; Shared Variables: 	None
; Global Variables:  	None
;
; Registers Changed: 	Flags, AX, SI
; Stack Depth:		None
;
; Algorithms:		None
; Data Structures: 	QSTRUC (queue.inc)
;
; Error Handling:
; If (s) exceeds Q_MAX_LEN, will wrap to Q_MAX_LEN.
;
; Known Bugs: 		None
;
; Limitations:
; Queue size must be > 0.
;
; Revision History:
; 04/27/09 William Fan
;	- Added error handling.
; 02/08/09	William Fan

QueueInit   PROC        NEAR
            PUBLIC      QueueInit

QueueInitPointers:
    MOV     [SI].qhead, 0			;qHead starts at 0, pointing to first byte
    MOV     [SI].qtail, 0     		;qTail starts at 0, since we haven't done anything yet

QueueInitChk:
    CMP		AX, Q_MAX_LEN       	;check if queue is of invalid length
    JG      QueueInitWrap			;if so, wrap the length automatically
	;JLE		QueueInitSet				;if not, set the length

QueueInitSet:
    MOV         [SI].qlen, AX 		;size passed in AX - write into queue length term
    JMP         QueueInitFin

QueueInitWrap:
    MOV		[SI].qlen, Q_MAX_LEN	;when passed size is too large, wrap to a reasonable max length

QueueInitFin:
    RET

QueueInit		ENDP


; QueueEmpty(a)
;
; Description:
; Check if queue at address 'a' is empty. If so, it sets the zero flag. Otherwise,
; it resets the zero flag. It checks by comparing the queue head and tail pointers.
; If the pointers are equal to each other, the queue must be empty.
;
; Arguments:
; 'a' (SI) - Address of the queue (queue starts at DS:SI).
;
; Input:            		None
; Output:           		None
;
; Return Values:
; If queue is empty	[ZF] = 1
; If queue is not empty	[ZF] = 0
;
; Local Variables:  		None
; Shared Variables: 	None
; Global Variables:  	None
;
; Registers Changed:	Flags, [AX]
; Stack Depth:		None
;
; Algorithms:		None
; Data Structures: 	QSTRUC (queue.inc)
;
; Error Handling:		None
;
; Known Bugs: 		None
; Limitations:		None
;
; Revision History:
; 02/08/09	William Fan

QueueEmpty  PROC        NEAR
            PUBLIC      QueueEmpty

QueueKill:
	MOV		AX, [SI].qHead
	CMP		AX, [SI].qTail  ;if qHead ?= qTail, then set the ZF flag

QueueKillFin:
    RET

QueueEmpty	    ENDP


; QueueFull(a)
;
; Description:
; Check if queue at address 'a' is full. If so, it sets the zero flag. Otherwise,
; it resets the zero flag.
;
; Operation:
; It checks by comparing the qhead pointer to the qtail
; pointer. If the latter is 1 byte before the former, then the queue must be full.
;
; Arguments:
; 'a' (SI) - Address of the queue (queue starts at DS:SI).
;
; Input:            		None
; Output:           		None
;
; Return Values:
; If queue is full		[ZF] = 1
; If queue is not full	[ZF] = 0
;
; Local Variables:  		[AX]
; Shared Variables: 	None
; Global Variables:  	None
;
; Registers Changed:	Flags, [AX]
; Stack Depth:		None
;
; Algorithms:		None
; Data Structures: 	QSTRUC (queue.inc)
;
; Error Handling:
; If the qhead pointer is zero, then the queue is full when the qtail pointer is
; located at qSize. We check for this with a jump instruction.
;
; Known Bugs: 		None
; Limitations:		None
;
; Revision History:
; 02/08/09	William Fan

QueueFull   PROC        NEAR
            PUBLIC      QueueFull

QueueFullInit:
    MOV     AX, [SI].qtail		;store location of tail pointer in AX
    MOV     BX, [SI].qlen   	;store length of the current queue in BX
    CMP     AX, BX				;compare the tail pointer with length to determine size
    JE      QueueFullWrap     	;if tail is at the end, reset to zero
    ;JNE       	QueueFullInc      			;else, increment the address of the tail pointer

QueueFullInc:
    MOV     AX, [SI].qtail		;load the address of the tail into AX
    INC     AX                  ;qtail address increase by one
    JMP     QueueFullChk        ;now compare if the queue is full by checking qhead and qtail

QueueFullWrap:
    MOV     AX, 0               ;return qtail to one
	;JMP      	QueueFullChk

QueueFullChk:
    CMP     AX, [SI].qhead       ;this checks if qhead = qtail + 1 and sets the zero flag accordingly

QueueFullFin:
    RET

QueueFull       ENDP


; Dequeue(a)
;
; Description:
; Remove an 8-bit value from the qHead of the queue located at address �a�
; and returns it in AL. Blocking function is in effect until the queue has something
; to be removed.
;
; Operation:
; The blocking function calls QueueEmpty and stalls until ZF = 0
; (ie the queue is not empty). Then it returns whatever entry is at the qhead pointer.
;
; Arguments:
; 'a' (SI) - Address of the queue (queue starts at DS:SI).
;
; Input:            		None
; Output:           		None
;
; Return Values:
; Value removed from the queue is returned in [AL].
;
; Local Variables:  		[BX]
; Shared Variables: 	None
; Global Variables:  	None
;
; Registers Changed:	Flags, [AX], [BX]
; Stack Depth:		None
;
; Algorithms:		None
; Data Structures: 	QSTRUC (queue.inc)
;
; Error Handling:
;
; Known Bugs: 		None
; Limitations:		None
;
; Revision History:
; 02/08/09	William Fan

Dequeue         PROC        NEAR
                PUBLIC      Dequeue

DQBlock:
    CALL        QueueEmpty                  ;check if the queue is empty
    JE          DQBlock             	  	;if empty, block by looping
    ;JNE      		DQTake                  				;if not empty, continue to dequeue

DQTake:
    MOV         BX, [SI].qhead              ;store qhead address in BX
    MOV         AL, [SI].queue_data[BX]     ;remove data at qhead into AL
    CMP         BX, [SI].qlen
    JE          DQWrapper               	;if qhead is the length, then it's full and we need to wrap

	;JNE      		DQNext

DQNext:
    INC         [SI].qhead					;now increment qhead pointer by 1
    JMP         DQFin

DQWrapper:
    MOV         [SI].qhead, 0				;restore qhead to 0
	;JMP      		DQFin

DQFin:
    RET

Dequeue         ENDP


; Enqueue(a)
;
; Description:
; Adds an 8-bit value 'b' to qTail of the queue located at address �a�. The blocking
; function calls QueueFull and stalls until ZF = 0 (ie the queue is not full). Then it adds
; the value 'b' stored in AL to the location pointed to by qTail.
;
; Arguments:
; 'a' (SI) - Address of the queue (queue starts at DS:SI).
; 'b' (AL) - 8 bit value we want to add to qTail pointer's location.
;
; Input:            		None
; Output:           		None
;
; Return Values: 		None
;
; Local Variables:  		[BX] - Address of qtail.
; Shared Variables: 	None
; Global Variables:  	None
;
; Registers Changed:	Flags, AX, BX
; Stack Depth:		1 byte
;
; Algorithms:		None
; Data Structures: 	QSTRUC (queue.inc)
;
; Error Handling:
;
; Known Bugs: 		None
; Limitations:		None
;
; Revision History:
; 02/08/09	William Fan

Enqueue     PROC        NEAR
            PUBLIC      Enqueue

	PUSH    AX							;reserve AX because we call QueueFull

EnQBlock:
    CALL    QueueFull					;call QueueFull to check if queue is full
    JE      EnQBlock        			;if it is full, block by looping
    ;JNE             EnQPutChar  					;if it has room to accept an Enqueue, put something there

    POP     AX                 			;we can restore AX now for other uses

EnQPutChar:
    MOV     BX, [SI].qtail           	;load address of qtail into BX
    MOV     [SI].queue_data[BX], AL 	;add the data in AL to the queue
    CMP     BX, [SI].qlen				;check if queue is full
    JE      EnQWrap           			;if qtail is the length, then queue is full and we need to wrap
    ;JNE             EnQNext

EnQNext:
    INC		[SI].qtail              	;otherwise, move the pointer to the next position
    JMP 	EnQFin

EnQWrap:
    MOV 	[SI].qtail, 0           	;wrap qtail's address to zero
    ;JMP 		EnQFin

EnQFin:
    RET

Enqueue     ENDP


CODE    	ENDS


			END
