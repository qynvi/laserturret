        NAME    SLVUI

		
$INCLUDE(serial.inc)		
$INCLUDE(motor.inc)
$INCLUDE(ace.inc)
		
		
CGROUP  GROUP   CODE
DGROUP  GROUP	DATA, STACK


CODE	SEGMENT PUBLIC 'CODE'


		ASSUME  	CS:CGROUP
        ASSUME      DS:DGROUP
		

	EXTRN InitMotor:NEAR
	EXTRN InitParallel:NEAR
	EXTRN InitSerial:NEAR
	EXTRN InitSP:NEAR
	EXTRN SRspreset:NEAR

	EXTRN InitCS:NEAR
	EXTRN InitTimer0:NEAR
	EXTRN InitTimer1:NEAR
	
	EXTRN InitIllegalEvH:NEAR
	EXTRN InitMtrEvH:NEAR
	EXTRN InitStepEvH:NEAR
	EXTRN InitSrlEvH:NEAR

	EXTRN Slave:NEAR
	

START:

MAIN:
	MOV       	AX, DGROUP              ;initialize the stack pointer
    MOV       	SS, AX
    MOV       	SP, OFFSET(DGROUP:TopOfStack)

    MOV       	AX, DGROUP              ;initialize the data segment
    MOV      	DS, AX

	CALL		InitCS					;set up chip selects (does not setup LCS/UCS)
	CALL		InitParallel	
	CALL		InitIllegalEvH			;hook all event handlers
	CALL		InitMtrEvH
	CALL		InitStepEvH	
	CALL		InitSrlEvH	
	CALL		InitTimer0				;start the timer and the muxing
	CALL		InitTimer1	
	CALL		InitMotor				;initialize the motors, stepper, and parallel port
	CALL		InitSP
	CALL		SRspreset
	
	MOV			AX, SERIAL_BR_DFLTDVSR	;set a baud rate
	MOV			BL, ACE_LCR_PAR_OFF		;no parity
	CALL		InitSerial				;initialize the serial port	
    
    STI

loopforever:
	CALL		Slave	
	JMP 		loopforever			
	
CODE			ENDS


DATA    		SEGMENT PUBLIC  'DATA'
DATA    		ENDS

STACK   		SEGMENT STACK  'STACK'
                DB      80 DUP ('Stack ')       ;240 words		
TopOfStack      LABEL   WORD
STACK   		ENDS


				END	START