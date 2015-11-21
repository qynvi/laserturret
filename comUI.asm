        NAME    COMUI


$INCLUDE(ace.inc)
$INCLUDE(serial.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP	DATA, STACK


CODE	SEGMENT PUBLIC 'CODE'


		ASSUME  	CS:CGROUP
        ASSUME      DS:DGROUP


	EXTRN DispInit:NEAR
	EXTRN InitKey:NEAR
	EXTRN InitParallel:NEAR
	EXTRN InitSerial:NEAR

	EXTRN InitCS:NEAR
	EXTRN InitTimer2:NEAR
	EXTRN InitIllegalEvH:NEAR
	EXTRN InitSrlEvH:NEAR
	EXTRN InitIOEvH:NEAR

	EXTRN DebugReset:NEAR
	EXTRN Command:NEAR


START:

MAIN:
	MOV       	AX, DGROUP              ;initialize the stack pointer
    MOV       	SS, AX
    MOV       	SP, OFFSET(DGROUP:TopOfStack)

    MOV       	AX, DGROUP              ;initialize the data segment
    MOV      	DS, AX

	CALL		InitCS					;set up chip selects (does not setup LCS/UCS)
	CALL		InitIllegalEvH			;hook all event handlers
	CALL		InitIOEvH
	CALL		InitSrlEvH
	CALL		InitTimer2
	CALL		DispInit		   		;initialize the display
	CALL		InitKey					;initialize the keypad
	MOV			AX, SERIAL_BR_DFLTDVSR	;set a baud rate
	MOV			BL, ACE_LCR_PAR_OFF		;no parity
	CALL		InitSerial				;initialize the serial port

    STI

loopforever:
	CALL		DebugReset				;serial debug mode off on first-boot
	CALL		Command
	JMP			loopforever

CODE			ENDS



DATA    		SEGMENT PUBLIC  'DATA'
DATA    		ENDS

STACK   		SEGMENT STACK  'STACK'
                DB      80 DUP ('Stack ')       ;240 words
TopOfStack      LABEL   WORD
STACK   		ENDS


				END START
